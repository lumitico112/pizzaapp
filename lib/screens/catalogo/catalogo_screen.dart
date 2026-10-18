import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/producto.dart';
import 'package:pizzaapp/controllers/producto_controller.dart';
import 'package:pizzaapp/screens/catalogo/producto_form_screen.dart';
import 'package:pizzaapp/screens/catalogo/receta_screen.dart';

/// Pantalla rediseñada de Catálogo de Productos bajo Material Design 3,
/// paleta cálida (naranja #FF6A00, rojo #D62828, crema #FBF9F5),
/// Empty State dinámico animado e interacciones táctiles fluidas.
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen>
    with SingleTickerProviderStateMixin {
  // Constantes de estilo y paleta Kimi Pizza
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _primaryRed = Color(0xFFD62828);
  static const Color _accentOrange = Color(0xFFFF6A00);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _illustrationBg = Color(0xFFFFEBE3);

  late AnimationController _floatAnimController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Animación de respiración/flotación continua para la ilustración del Empty State
    _floatAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(
        parent: _floatAnimController,
        curve: Curves.easeInOutSine,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoController>().loadProductos();
    });
  }

  @override
  void dispose() {
    _floatAnimController.dispose();
    super.dispose();
  }

  Future<void> _showAddProductoModal() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProductoFormScreen()),
    );
    if (result == true && mounted) {
      context.read<ProductoController>().loadProductos();
    }
  }

  Future<void> _editProducto(Producto p) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductoFormScreen(productoAEditar: p)),
    );
    if (result == true && mounted) {
      context.read<ProductoController>().loadProductos();
    }
  }

  void _deleteProducto(Producto prod) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Eliminar Producto',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar "${prod.nombre}"? Se eliminarán todas sus variantes y recetas asociadas.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: _textMuted,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: _textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              await context.read<ProductoController>().eliminarProducto(
                prod.id!,
              );
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Producto "${prod.nombre}" eliminado',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  backgroundColor: _primaryRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _verOpciones(Producto prod) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _illustrationBg,
                        borderRadius: BorderRadius.circular(10),
                        image: prod.fotoRuta != null
                            ? DecorationImage(
                                image: FileImage(File(prod.fotoRuta!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: prod.fotoRuta == null
                          ? const Icon(
                              Icons.local_pizza_outlined,
                              color: _accentOrange,
                              size: 24,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod.nombre,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Opciones del producto',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: _cardBorder),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                ),
                title: Text(
                  'Editar Producto',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                subtitle: Text(
                  'Modificar nombre, variantes, fotos y precios',
                  style: GoogleFonts.poppins(fontSize: 11, color: _textMuted),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _textMuted,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _editProducto(prod);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF059669),
                    size: 22,
                  ),
                ),
                title: Text(
                  'Ficha Técnica (Receta)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                subtitle: Text(
                  'Configurar insumos y costo unitario por variante',
                  style: GoogleFonts.poppins(fontSize: 11, color: _textMuted),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _textMuted,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecetaScreen(producto: prod),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                ),
                title: Text(
                  'Eliminar Producto',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                subtitle: Text(
                  'Borrar permanentemente del catálogo',
                  style: GoogleFonts.poppins(fontSize: 11, color: _textMuted),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _textMuted,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteProducto(prod);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la vista de estado vacío con animación de flotación,
  /// contenedor estilizado en #FFEBE3/#FF6A00 y botón con gradiente + microinteracción.
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ilustración dinámica animada (flotación/respiración suave)
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: child,
                );
              },
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: _illustrationBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _accentOrange.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Círculo decorativo secundario con degradado suave
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _accentOrange.withValues(alpha: 0.25),
                            _primaryRed.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Iconografía estilizada de pizza / caja abierta moderna
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [_accentOrange, _primaryRed],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: _accentOrange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_pizza_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Título del Estado: "No hay productos" en Poppins Bold 18sp
            Text(
              'No hay productos',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Subtexto Descriptivo en Poppins Regular 13sp (#6B7280) en 2 líneas
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                'Comienza agregando tus pizzas, bebidas o complementos para poder registrarlos en tus ventas.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: _textMuted,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón de Acción Principal de 52px con degradado y microinteracción de escala 0.97x
            _ScaleButton(
              onTap: _showAddProductoModal,
              child: Container(
                height: 52,
                constraints: const BoxConstraints(maxWidth: 290),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accentOrange, _primaryRed],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _accentOrange.withValues(alpha: 0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Crear mi primer producto',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta de producto individual moderna Material Design 3
  Widget _buildProductCard(Producto prod) {
    final tipoNombre = prod.tipoPreparacion == 'anticipado'
        ? 'Preparado previo'
        : prod.tipoPreparacion == 'momento'
        ? 'Al momento'
        : 'Mixto (stock + momento)';

    final tipoColor = prod.tipoPreparacion == 'anticipado'
        ? const Color(0xFF0284C7)
        : prod.tipoPreparacion == 'momento'
        ? const Color(0xFFD97706)
        : const Color(0xFF7C3AED);

    final tipoBg = prod.tipoPreparacion == 'anticipado'
        ? const Color(0xFFF0F9FF)
        : prod.tipoPreparacion == 'momento'
        ? const Color(0xFFFFFBEB)
        : const Color(0xFFF5F3FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _verOpciones(prod),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Imagen con bordes redondeados o fallback cálido
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _illustrationBg,
                    borderRadius: BorderRadius.circular(12),
                    image: prod.fotoRuta != null
                        ? DecorationImage(
                            image: FileImage(File(prod.fotoRuta!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: prod.fotoRuta == null
                      ? const Icon(
                          Icons.local_pizza_outlined,
                          color: _accentOrange,
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Información textual del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prod.nombre,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (prod.descripcion != null &&
                          prod.descripcion!.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          prod.descripcion!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),

                      // Los badges saltan de línea dentro del ancho disponible.
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tipoBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 12,
                                  color: tipoColor,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    tipoNombre,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: tipoColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (prod.derivaDeProductoId != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.link_rounded,
                                    size: 12,
                                    color: _textMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Derivado',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: _textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Botón de más opciones
                IconButton(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: _textMuted,
                    size: 20,
                  ),
                  onPressed: () => _verOpciones(prod),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductoController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: _bgScreen,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryRed, _accentOrange],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_outlined,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Volver',
            ),
            title: Text(
              'Catálogo de Productos',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.add_outlined,
                  color: Colors.white,
                  size: 26,
                ),
                tooltip: 'Nuevo Producto',
                onPressed: _showAddProductoModal,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_accentOrange),
                  ),
                )
              : controller.productos.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: _accentOrange,
                  onRefresh: () async {
                    await controller.loadProductos();
                  },
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    itemCount: controller.productos.length,
                    itemBuilder: (context, index) {
                      final prod = controller.productos[index];
                      return _buildProductCard(prod);
                    },
                  ),
                ),
        );
      },
    );
  }
}

/// Widget envoltorio para microinteracción táctil con reducción de escala suave (0.97x) al presionar
class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleButton({required this.child, required this.onTap});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
