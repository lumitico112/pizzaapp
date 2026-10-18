import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:pizzaapp/core/database/database_helper.dart';
import 'package:pizzaapp/core/database/db_seeder.dart';

/// Handles portable, password-protected backups and device-local recovery copies.
/// The live SQLCipher key never leaves the device in plaintext.
class BackupService {
  BackupService({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const _magic = <int>[0x4B, 0x50, 0x5A, 0x42, 0x01]; // KPZB v1
  static const _formatVersion = 1;
  static const _maxBackupBytes = 512 * 1024 * 1024;
  static const _autoBackupKeyName = 'local_backup_encryption_key_v1';

  Future<void> exportPortableBackup(String password) async {
    _validatePassword(password);
    final bytes = await _createEncryptedBackup(password);
    final date = DateTime.now().toIso8601String().split('T').first;
    final result = await FilePicker.saveFile(
      dialogTitle: 'Guardar copia cifrada de Kimi Pizza',
      fileName: 'kimi_pizza_$date.kpzbackup',
      type: FileType.custom,
      allowedExtensions: const ['kpzbackup'],
      bytes: bytes,
    );
    if (result == null) throw const BackupCancelledException();
  }

  Future<void> restorePortableBackup(Uint8List bytes, String password) async {
    if (bytes.length > _maxBackupBytes) {
      throw const BackupFormatException('La copia supera el tamaño permitido.');
    }
    final payload = await _decryptAndReadBackup(bytes, password);
    await _restorePayload(payload);
  }

  @visibleForTesting
  Future<Uint8List> createEncryptedBackupForTesting(String password) =>
      _createEncryptedBackup(password);

  @visibleForTesting
  Future<Map<String, Object?>> decryptAndReadBackupForTesting(
    Uint8List bytes,
    String password,
  ) =>
      _decryptAndReadBackup(bytes, password);

  Future<bool> createDailyLocalBackupIfDue() async {
    final db = await _databaseHelper.database;
    final admins = await db.query(
      'Usuarios',
      columns: const ['id'],
      where: "rol = 'admin' AND activo = 1",
      limit: 1,
    );
    if (admins.isEmpty) return false;

    final directory = await _localBackupDirectory();
    if (!await directory.exists()) await directory.create(recursive: true);
    final latest =
        (await directory
                .list()
                .where(
                  (entity) =>
                      entity is File && entity.path.endsWith('.kpzlocal'),
                )
                .cast<File>()
                .toList())
            .fold<File?>(
              null,
              (current, file) =>
                  current == null ||
                      file.lastModifiedSync().isAfter(
                        current.lastModifiedSync(),
                      )
                  ? file
                  : current,
            );
    if (latest != null) {
      final latestDate = await latest.lastModified();
      final now = DateTime.now();
      if (latestDate.year == now.year &&
          latestDate.month == now.month &&
          latestDate.day == now.day) {
        return false;
      }
    }

    final key = await _getLocalBackupKey();
    final encrypted = await _createEncryptedBackup(key);
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    await File(path.join(directory.path, 'auto_$stamp.kpzlocal'))
        .writeAsBytes(encrypted, flush: true);
    await _pruneLocalBackups(directory);
    return true;
  }

  Future<void> restoreLatestLocalBackup() async {
    final directory = await _localBackupDirectory();
    if (!await directory.exists()) {
      throw const BackupNotFoundException();
    }
    final backups =
        (await directory
              .list()
              .where(
                (entity) => entity is File && entity.path.endsWith('.kpzlocal'),
              )
              .cast<File>()
              .toList())
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );
    if (backups.isEmpty) throw const BackupNotFoundException();
    final key = await _getLocalBackupKey();
    final bytes = await backups.first.readAsBytes();
    final payload = await _decryptAndReadBackup(bytes, key);
    await _restorePayload(payload);
  }

  Future<Uint8List> readPickedBackup() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['kpzbackup'],
    );
    if (files.isEmpty) {
      throw const BackupCancelledException();
    }
    final length = await files.single.length();
    if (length != null && length > _maxBackupBytes) {
      throw const BackupFormatException('La copia supera el tamaño permitido.');
    }
    final bytes = await files.single.readAsBytes();
    if (bytes.isEmpty) {
      throw const BackupFormatException(
        'No se pudo leer el archivo seleccionado.',
      );
    }
    return bytes;
  }

  Future<Uint8List> _createEncryptedBackup(String password) async {
    final db = await _databaseHelper.database;
    final tableRows = <String, List<Map<String, Object?>>>{};
    final assetEntries = <String, String>{};
    final archive = Archive();

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );
    for (final tableRecord in tables) {
      final tableName = tableRecord['name'] as String;
      final rows = await db.query(tableName);
      tableRows[tableName] = rows;
      for (final row in rows) {
        for (final entry in row.entries) {
          final isPathField = RegExp(
            r'(ruta|path)$',
            caseSensitive: false,
          ).hasMatch(entry.key);
          if (isPathField && entry.value is String) {
            await _addAssetIfPresent(
              entry.value! as String,
              archive,
              assetEntries,
            );
          }
          if (tableName == 'Configuracion' &&
              row['clave'] is String &&
              RegExp(
                r'(ruta|path)$',
                caseSensitive: false,
              ).hasMatch(row['clave']! as String) &&
              row['valor'] is String) {
            await _addAssetIfPresent(
              row['valor']! as String,
              archive,
              assetEntries,
            );
          }
        }
      }
    }

    final manifest = <String, Object?>{
      'formatVersion': _formatVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'databaseVersion': DatabaseHelper.databaseVersion,
      'tables': tableRows,
      'assetEntries': assetEntries,
    };
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes.length > _maxBackupBytes) {
      throw const BackupFormatException(
        'La copia es demasiado grande para exportar.',
      );
    }
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);

    // C-17: Cifrado PBKDF2 (310k iteraciones) + AES-GCM ejecutado en Isolate para no congelar la UI.
    return await Isolate.run(() async {
      final kdf = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: 310000,
        bits: 256,
      );
      final cipher = AesGcm.with256bits();
      final encryptionKey = await kdf.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: salt,
      );
      final box = await cipher.encrypt(
        zipBytes,
        secretKey: encryptionKey,
        nonce: nonce,
      );
      final header = utf8.encode(
        jsonEncode({
          'formatVersion': _formatVersion,
          'salt': base64UrlEncode(salt),
          'nonce': base64UrlEncode(nonce),
        }),
      );
      final output = BytesBuilder(copy: false)
        ..add(_magic)
        ..addByte((header.length >> 24) & 0xff)
        ..addByte((header.length >> 16) & 0xff)
        ..addByte((header.length >> 8) & 0xff)
        ..addByte(header.length & 0xff)
        ..add(header)
        ..add(box.cipherText)
        ..add(box.mac.bytes);
      return output.takeBytes();
    });
  }

  Future<Map<String, Object?>> _decryptAndReadBackup(
    Uint8List bytes,
    String password,
  ) async {
    if (bytes.length < _magic.length + 4 + 16 ||
        bytes.length > _maxBackupBytes) {
      throw const BackupFormatException(
        'El archivo no parece una copia válida.',
      );
    }
    for (var i = 0; i < _magic.length; i++) {
      if (bytes[i] != _magic[i]) {
        throw const BackupFormatException(
          'El archivo no parece una copia de Kimi Pizza.',
        );
      }
    }
    final headerLength =
        (bytes[5] << 24) | (bytes[6] << 16) | (bytes[7] << 8) | bytes[8];
    final headerStart = _magic.length + 4;
    final cipherStart = headerStart + headerLength;
    if (headerLength <= 0 || cipherStart >= bytes.length - 16) {
      throw const BackupFormatException(
        'El encabezado de la copia está dañado.',
      );
    }
    try {
      final header = jsonDecode(
        utf8.decode(bytes.sublist(headerStart, cipherStart)),
      ) as Map<String, dynamic>;
      if (header['formatVersion'] != _formatVersion) {
        throw const BackupFormatException(
          'Esta versión de copia no es compatible.',
        );
      }
      final salt = base64Url.decode(header['salt'] as String);
      final nonce = base64Url.decode(header['nonce'] as String);
      final cipherAndMac = bytes.sublist(cipherStart);
      final cipherText = cipherAndMac.sublist(0, cipherAndMac.length - 16);
      final macBytes = cipherAndMac.sublist(cipherAndMac.length - 16);

      // C-17: PBKDF2 (310k iteraciones) + descifrado AES-GCM ejecutado en Isolate.
      final zipBytes = await Isolate.run(() async {
        final kdf = Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: 310000,
          bits: 256,
        );
        final cipher = AesGcm.with256bits();
        final box = SecretBox(
          cipherText,
          nonce: nonce,
          mac: Mac(macBytes),
        );
        final key = await kdf.deriveKey(
          secretKey: SecretKey(utf8.encode(password)),
          nonce: salt,
        );
        return Uint8List.fromList(await cipher.decrypt(box, secretKey: key));
      });
      final decodedArchive = ZipDecoder().decodeBytes(zipBytes);
      final manifestFile = decodedArchive.findFile('manifest.json');
      if (manifestFile == null) {
        throw const BackupFormatException(
          'La copia no contiene sus datos principales.',
        );
      }
      final manifest = jsonDecode(
        utf8.decode(manifestFile.content as List<int>),
      ) as Map<String, dynamic>;
      if (manifest['formatVersion'] != _formatVersion ||
          manifest['tables'] is! Map<String, dynamic> ||
          manifest['assetEntries'] is! Map<String, dynamic>) {
        throw const BackupFormatException(
          'La estructura de la copia no es compatible.',
        );
      }
      final sourceDatabaseVersion = manifest['databaseVersion'];
      if (sourceDatabaseVersion is int &&
          sourceDatabaseVersion > DatabaseHelper.databaseVersion) {
        throw const BackupFormatException(
          'La copia fue creada con una versión más reciente de la app.',
        );
      }
      manifest['_decodedArchive'] = decodedArchive;
      return manifest.cast<String, Object?>();
    } on BackupFormatException {
      rethrow;
    } on SecretBoxAuthenticationError {
      throw const BackupPasswordException();
    } catch (_) {
      throw const BackupFormatException(
        'No se pudo abrir la copia. Revisa la contraseña y que el archivo esté completo.',
      );
    }
  }

  Future<void> _restorePayload(Map<String, Object?> payload) async {
    final archived = payload['_decodedArchive'] as Archive;
    final assetEntries = (payload['assetEntries'] as Map)
        .cast<String, String>();
    final backupTables = (payload['tables'] as Map).map(
      (key, value) => MapEntry(key.toString(), value as List),
    );
    final hasActiveOwner = (backupTables['Usuarios'] ?? const []).any((row) {
      final user = row as Map;
      return user['rol'] == 'admin' && user['activo'] == 1;
    });
    if (!hasActiveOwner) {
      throw const BackupFormatException(
        'La copia no contiene una cuenta propietaria activa; no se modificaron los datos.',
      );
    }
    final db = await _databaseHelper.database;

    // Keep a same-device recovery point before replacing business data.
    await _createLocalBackupNow();
    final restoredAssets = await _restoreAssets(archived, assetEntries);

    final existingTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );
    final tableNames = existingTables
        .map((row) => row['name'] as String)
        .toList();
    final columnsByTable = <String, Set<String>>{};
    for (final table in tableNames) {
      final columns = await db.rawQuery(
        'PRAGMA table_info("${_quoteIdentifier(table)}")',
      );
      columnsByTable[table] = columns
          .map((column) => column['name'] as String)
          .toSet();
    }

    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.transaction((transaction) async {
        for (final table in tableNames) {
          await transaction.delete(table);
        }
        for (final table in tableNames) {
          final savedRows = backupTables[table];
          if (savedRows == null) continue;
          final availableColumns = columnsByTable[table]!;
          for (final savedRow in savedRows) {
            final sourceRow = (savedRow as Map).cast<String, Object?>();
            final configurationPath =
                table == 'Configuracion' &&
                sourceRow['clave'] is String &&
                RegExp(
                  r'(ruta|path)$',
                  caseSensitive: false,
                ).hasMatch(sourceRow['clave']! as String);
            final row = sourceRow.map(
              (key, value) => MapEntry(
                key,
                configurationPath && key == 'valor' && value is String
                    ? restoredAssets[value] ?? value
                    : _rewriteAssetReference(table, key, value, restoredAssets),
              ),
            );
            row.removeWhere((key, _) => !availableColumns.contains(key));
            if (row.isNotEmpty) {
              await transaction.insert(
                table,
                row,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
      });
      try {
        await DbSeeder(db).seedAll();
      } catch (_) {
        // Existing restored records stay valid if a newer seed cannot be added.
      }
      await _databaseHelper.cleanOrphanForeignKeys(db);
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Future<Map<String, String>> _restoreAssets(
    Archive archive,
    Map<String, String> assetEntries,
  ) async {
    final baseDirectory = await getApplicationSupportDirectory();
    final assetDirectory = Directory(
      path.join(baseDirectory.path, 'business_files'),
    );
    await assetDirectory.create(recursive: true);
    final restored = <String, String>{};
    for (final entry in assetEntries.entries) {
      final archiveFile = archive.findFile(entry.value);
      if (archiveFile == null || !entry.value.startsWith('assets/')) continue;
      final extension = path.extension(entry.key);
      final nameHash = _sha256(entry.key);
      final outputPath = path.join(assetDirectory.path, '$nameHash$extension');
      await File(outputPath)
          .writeAsBytes(archiveFile.content as List<int>, flush: true);
      restored[entry.key] = outputPath;
    }
    return restored;
  }

  Future<void> _addAssetIfPresent(
    String sourcePath,
    Archive archive,
    Map<String, String> assetEntries,
  ) async {
    if (sourcePath.isEmpty || assetEntries.containsKey(sourcePath)) return;
    final file = File(sourcePath);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return;
    final entryName = 'assets/${_sha256(sourcePath)}';
    archive.addFile(ArchiveFile(entryName, bytes.length, bytes));
    assetEntries[sourcePath] = entryName;
  }

  Object? _rewriteAssetReference(
    String table,
    String column,
    Object? value,
    Map<String, String> restoredAssets,
  ) {
    if (value is! String) return value;
    final isPathField = RegExp(
      r'(ruta|path)$',
      caseSensitive: false,
    ).hasMatch(column);
    if (isPathField) return restoredAssets[value] ?? value;
    return value;
  }

  Future<String> _getLocalBackupKey() async {
    final existing = await _secureStorage.read(key: _autoBackupKeyName);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = base64UrlEncode(_randomBytes(32));
    await _secureStorage.write(key: _autoBackupKeyName, value: generated);
    return generated;
  }

  Future<Directory> _localBackupDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(path.join(support.path, 'backups'));
  }

  Future<void> _pruneLocalBackups(Directory directory) async {
    final backups =
        (await directory
              .list()
              .where(
                (entity) => entity is File && entity.path.endsWith('.kpzlocal'),
              )
              .cast<File>()
              .toList())
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );
    for (final oldBackup in backups.skip(7)) {
      await oldBackup.delete();
    }
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  String _sha256(String value) =>
      crypto.sha256.convert(utf8.encode(value)).toString();

  Future<void> _createLocalBackupNow() async {
    final directory = await _localBackupDirectory();
    if (!await directory.exists()) await directory.create(recursive: true);
    final key = await _getLocalBackupKey();
    final encrypted = await _createEncryptedBackup(key);
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    await File(path.join(directory.path, 'auto_$stamp.kpzlocal'))
        .writeAsBytes(encrypted, flush: true);
    await _pruneLocalBackups(directory);
  }

  String _quoteIdentifier(String identifier) =>
      identifier.replaceAll('"', '""');

  void _validatePassword(String password) {
    if (password.runes.length < 12) {
      throw const BackupPasswordPolicyException();
    }
  }
}

class BackupCancelledException implements Exception {
  const BackupCancelledException();
}

class BackupNotFoundException implements Exception {
  const BackupNotFoundException();
}

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;
}

class BackupPasswordException implements Exception {
  const BackupPasswordException();
}

class BackupPasswordPolicyException implements Exception {
  const BackupPasswordPolicyException();
}
