import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/categoria_activo_controller.dart';
import 'package:pizzaapp/models/categoria_activo.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';

/// Pantalla rediseñada de Categorías de Activos bajo Material Design 3,
/// con paleta cálida (#FF6A00, #D62828, #FBF9F5), microinteracciones fluidas
/// y modal emergente con backdrop blur y animación scale + fade.
class CategoriasActivoScreen extends StatefulWidget {
  const CategoriasActivoScreen({super.key});

  @override
  State<CategoriasActivoScreen> createState() => _CategoriasActivoScreenState();
}

class _CategoriasActivoScreenState extends State<CategoriasActivoScreen> {
  // Paleta de colores cálida de la aplicación
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _primaryRed = Color(0xFFD62828);
  static const Color _accentOrange = Color(0xFFFF6A00);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _textPlaceholder = Color(0xFF9CA3AF);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _iconBg = Color(0xFFFFF1ED);
  static const Color _editBtnBg = Color(0xFFEFF6FF);
  static const Color _editIcon = Color(0xFF2563EB);
  static const Color _deleteBtnBg = Color(0xFFFEF2F2);
  static const Color _deleteIcon = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaActivoController>().loadCategorias();
    });
  }

  /// Retorna un icono temático descriptivo según el nombre de la categoría
  IconData _getIconForCategory(String nombre) {
    final n = nombre.toLowerCase().trim();
    if (n.contains('maquin') ||
        n.contains('horno') ||
        n.contains('amasador') ||
        n.contains('industrial') ||
        n.contains('cocina')) {
      return Icons.precision_manufacturing_outlined;
    }
    if (n.contains('mueble') ||
        n.contains('mesa') ||
        n.contains('silla') ||
        n.contains('estant') ||
        n.contains('vitrina') ||
        n.contains('mostrador')) {
      return Icons.chair_outlined;
    }
    if (n.contains('tecno') ||
        n.contains('comput') ||
        n.contains('laptop') ||
        n.contains('pc') ||
        n.contains('impresor') ||
        n.contains('tablet') ||
        n.contains('celular') ||
        n.contains('pantalla')) {
      return Icons.devices_outlined;
    }
    if (n.contains('vehic') ||
        n.contains('moto') ||
        n.contains('auto') ||
        n.contains('carro') ||
        n.contains('camion') ||
        n.contains('delivery') ||
        n.contains('transporte')) {
      return Icons.local_shipping_outlined;
    }
    if (n.contains('electro') ||
        n.contains('microond') ||
        n.contains('licuad') ||
        n.contains('refriger') ||
        n.contains('congel') ||
        n.contains('batidor') ||
        n.contains('cafeter')) {
      return Icons.blender_outlined;
    }
    return Icons.category_outlined;
  }

  /// Modal con Backdrop Blur y animación de entrada elástica (scale + fade)
  void _mostrarFormulario([CategoriaActivo? categoria]) {
    final nombreCtrl = TextEditingController(text: categoria?.nombre);
    final isEditing = categoria != null;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ModalCategoria',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogCtx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (dialogCtx, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        );

        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 4 * anim1.value,
            sigmaY: 4 * anim1.value,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
              child: Center(
                child: SingleChildScrollView(
                  child: Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Encabezado del Modal con icono decorativo
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _iconBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.create_new_folder_outlined,
                                  color: _primaryRed,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  isEditing
                                      ? 'Editar Categoría'
                                      : 'Nueva Categoría',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Campo de Formulario (Input)
                          TextFormField(
                            controller: nombreCtrl,
                            autofocus: true,
                            textCapitalization: TextCapitalization.sentences,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _textDark,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.label_outline,
                                color: _textMuted,
                                size: 20,
                              ),
                              hintText: 'Nombre de la categoría',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: _textPlaceholder,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: _cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: _cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _accentOrange,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Botones de Acción (Fila Inferior)
                          Row(
                            children: [
                              // Botón Cancelar
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(46),
                                    side: const BorderSide(color: _cardBorder),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    foregroundColor: _textMuted,
                                  ),
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: Text(
                                    'Cancelar',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Botón Guardar con degradado naranja-rojo
                              Expanded(
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_accentOrange, _primaryRed],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryRed.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () async {
                                      final nombre = nombreCtrl.text.trim();
                                      if (nombre.isEmpty) return;

                                      final cat = CategoriaActivo(
                                        id: categoria?.id,
                                        nombre: nombre,
                                      );
                                      final catCtrl = context.read<CategoriaActivoController>();
                                      final messenger = ScaffoldMessenger.of(context);
                                      Navigator.pop(dialogCtx);

                                      final res = await catCtrl.guardarCategoria(cat);

                                      if (!res && mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              catCtrl.error ??
                                                  'Error al guardar categoría',
                                            ),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                      }
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Guardar',
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
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Diálogo con confirmación estilizada y Backdrop Blur para eliminar
  Future<void> _eliminar(CategoriaActivo categoria) async {
    final conf = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ModalEliminar',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogCtx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (dialogCtx, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        );

        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 4 * anim1.value,
            sigmaY: 4 * anim1.value,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
              child: Center(
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: _deleteBtnBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: _deleteIcon,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '¿Eliminar Categoría?',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¿Estás seguro de que deseas eliminar la categoría "${categoria.nombre}"? Esta acción no se puede deshacer.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _textMuted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  side: const BorderSide(color: _cardBorder),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(dialogCtx, false),
                                child: Text(
                                  'Cancelar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  backgroundColor: _deleteIcon,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () => Navigator.pop(dialogCtx, true),
                                child: Text(
                                  'Eliminar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (conf == true && mounted) {
      await context
          .read<CategoriaActivoController>()
          .eliminarCategoria(categoria.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgScreen,
      // 1. AppBar con degradado cálido de terracota a naranja
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryRed, _accentOrange],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Categorías de Activos',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: false,
          ),
        ),
      ),
      // Listado de Categorías
      body: Consumer<CategoriaActivoController>(
        builder: (context, ctrl, child) {
          if (ctrl.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _accentOrange),
            );
          }

          if (ctrl.categorias.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: _iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.category_outlined,
                        size: 40,
                        color: _primaryRed,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No hay categorías registradas',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crea tu primera categoría para clasificar los activos del negocio.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_accentOrange, _primaryRed],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryRed.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => _mostrarFormulario(),
                        icon: const Icon(Icons.add, color: Colors.white, size: 20),
                        label: Text(
                          'Nueva Categoría',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
            itemCount: ctrl.categorias.length,
            itemBuilder: (ctx, i) {
              final cat = ctrl.categorias[i];
              return _buildCategoryCard(cat);
            },
          );
        },
      ),
      // Botón Flotante con degradado naranja-rojo y sombra difusa cálida
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_accentOrange, _primaryRed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _primaryRed.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _mostrarFormulario(),
            child: const Center(
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tarjeta de categoría elevada (altura mínima 64px, radio 16px, borde sutil, elevación 2)
  Widget _buildCategoryCard(CategoriaActivo cat) {
    final iconData = _getIconForCategory(cat.nombre);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Icono Descriptivo a la Izquierda (40px x 40px, radio 10px, fondo pastel naranja/rojo)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                iconData,
                color: _primaryRed,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Texto Central: Nombre de la categoría en Poppins SemiBold 15sp
            Expanded(
              child: Text(
                cat.nombre,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),

            // Acciones a la Derecha
            // 1. Botón Editar (36x36, radio 10px, fondo azul claro, icono azul)
            Material(
              color: _editBtnBg,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _mostrarFormulario(cat),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.edit_outlined,
                    color: _editIcon,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 2. Botón Eliminar (36x36, radio 10px, fondo rojo pastel, icono rojo)
            Material(
              color: _deleteBtnBg,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _eliminar(cat),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.delete_outline,
                    color: _deleteIcon,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
