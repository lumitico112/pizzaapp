import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/proveedor_controller.dart';
import 'package:pizzaapp/models/proveedor.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/widgets/app_confirm_dialog.dart';
import 'proveedor_form_screen.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  // Paleta corporativa
  static const Color _primaryOrange = Color(0xFFFF6A00);
  static const Color _secondaryRed = Color(0xFFD62828);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _cardBorder = Color(0xFFE5E7EB);

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorController>().loadProveedores();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirFormulario({Proveedor? proveedor}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProveedorFormScreen(proveedor: proveedor),
      ),
    );
    if (result == true && mounted) {
      context.read<ProveedorController>().loadProveedores();
    }
  }

  Future<void> _confirmarEliminar(Proveedor p) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Eliminar proveedor',
      message:
          '¿Eliminar a "${p.nombre}"?\nNo se borrarán sus compras asociadas.',
      confirmLabel: 'Eliminar',
      confirmColor: AppColors.error,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;

    final err =
        await context.read<ProveedorController>().eliminarProveedor(p.id!);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              err == null ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                err ?? 'Proveedor eliminado correctamente',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: err == null ? const Color(0xFF059669) : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  List<Proveedor> _filtrarProveedores(List<Proveedor> proveedores) {
    if (_searchQuery.isEmpty) return proveedores;
    return proveedores.where((p) {
      final nombre = p.nombre.toLowerCase();
      final tel = p.telefono?.toLowerCase() ?? '';
      final dir = p.direccion?.toLowerCase() ?? '';
      final email = p.email?.toLowerCase() ?? '';
      final notas = p.notas?.toLowerCase() ?? '';
      return nombre.contains(_searchQuery) ||
          tel.contains(_searchQuery) ||
          dir.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          notas.contains(_searchQuery);
    }).toList();
  }

  Widget _buildCard(Proveedor p, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + (index * 40).clamp(0, 400)),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar con inicial
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFEBE3), Color(0xFFFFF1ED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD7C7), width: 1),
              ),
              child: Center(
                child: Text(
                  p.nombre.trim().isNotEmpty
                      ? p.nombre.trim()[0].toUpperCase()
                      : 'P',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: _secondaryRed,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Información central
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nombre,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  if (p.telefono != null && p.telefono!.trim().isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_iphone_rounded,
                          size: 13,
                          color: _secondaryRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          p.telefono!.trim(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ] else if (p.direccion != null &&
                      p.direccion!.trim().isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: _textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p.direccion!.trim(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Sin teléfono registrado',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],

                  if (p.email != null && p.email!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p.email!.trim(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Acciones compactas
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón Editar
                Material(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _abrirFormulario(proveedor: p),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Botón Eliminar
                Material(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _confirmarEliminar(p),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD7C7), width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.storefront_outlined,
                  size: 42,
                  color: _secondaryRed,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No hay proveedores registrados',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega a tus proveedores habituales para asociarlos a tus compras e insumos.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryOrange, _secondaryRed],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _secondaryRed.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _abrirFormulario(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_business_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Añadir primer proveedor',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Sin resultados para "$_searchQuery"',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba buscando con otro nombre, teléfono o término.',
              style: GoogleFonts.poppins(fontSize: 12, color: _textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() {});
              },
              child: Text(
                'Limpiar búsqueda',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: _primaryOrange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProveedorController>(
      builder: (context, ctrl, _) {
        final filteredList = _filtrarProveedores(ctrl.proveedores);

        return Scaffold(
          backgroundColor: _bgScreen,
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            leading: Center(
              child: Material(
                color: Colors.white.withValues(alpha: 0.18),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'Proveedores',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_secondaryRed, _primaryOrange],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: ctrl.loadProveedores,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: ctrl.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryOrange),
                  ),
                )
              : ctrl.proveedores.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        // Barra de Búsqueda y Contador
                        Container(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                          child: Column(
                            children: [
                              // Input de búsqueda
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: _cardBorder, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchCtrl,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _textDark,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Buscar proveedor por nombre, teléfono...',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: Color(0xFF9CA3AF),
                                      size: 20,
                                    ),
                                    suffixIcon: _searchCtrl.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                            onPressed: () {
                                              _searchCtrl.clear();
                                              setState(() {});
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            vertical: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Fila de resumen de conteo
                              Row(
                                children: [
                                  Text(
                                    'Proveedores registrados',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF1ED),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${filteredList.length}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _secondaryRed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Lista o Estado sin resultados de búsqueda
                        Expanded(
                          child: filteredList.isEmpty
                              ? _buildEmptySearch()
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                      18, 4, 18, 90),
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) =>
                                      _buildCard(filteredList[index], index),
                                ),
                        ),
                      ],
                    ),
          floatingActionButton: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryOrange, _secondaryRed],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _secondaryRed.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _abrirFormulario(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_business_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Añadir proveedor',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
