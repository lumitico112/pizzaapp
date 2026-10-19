import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/features/assets/domain/entities/asset.dart';
import 'package:pizzaapp/features/assets/presentation/controllers/asset_controller.dart';
import 'package:pizzaapp/features/assets/presentation/screens/asset_form_screen.dart';

/// Pantalla rediseñada de Activos Fijos bajo Material Design 3,
/// con paleta cálida (naranja #FF6A00, rojo #D62828, crema #FBF9F5),
/// filtros segmentados interactivos, tarjetas modernas con borde de acento,
/// animación en cascada (FadeInUp) y FAB animado con degradado.
class ActivosFijosScreen extends StatefulWidget {
  const ActivosFijosScreen({super.key});

  @override
  State<ActivosFijosScreen> createState() => _ActivosFijosScreenState();
}

class _ActivosFijosScreenState extends State<ActivosFijosScreen> {
  // Paleta de colores cálida coherente con la identidad de Kimi Pizza
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _primaryRed = Color(0xFFD62828);
  static const Color _accentOrange = Color(0xFFFF6A00);
  static const Color _chipActiveBg = Color(0xFFFFEBE3);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _textSecondaryDark = Color(0xFF4B5563);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _imageBg = Color(0xFFF9FAFB);

  String _filtroActual = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivoFijoController>().loadActivos();
    });
  }

  void _openForm({ActivoFijo? activo}) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ActivoFijoFormScreen(activoAEditar: activo),
      ),
    );
    if (res == true && mounted) {
      context.read<ActivoFijoController>().loadActivos();
    }
  }

  void _eliminar(ActivoFijo activo) {
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
                'Eliminar Activo',
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
          '¿Estás seguro de que deseas eliminar el activo "${activo.nombre}"? Esta acción no se puede deshacer.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: _textMuted,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              await context.read<ActivoFijoController>().eliminarActivo(activo.id!);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Activo "${activo.nombre}" eliminado',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  backgroundColor: _primaryRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  void _cambiarEstadoDialog(ActivoFijo activo) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Cambiar Estado del Activo',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OpcionEstadoItem(
                activo: activo,
                estado: 'En uso',
                color: const Color(0xFF10B981),
                bg: const Color(0xFFD1FAE5),
                actual: activo.estado,
                ctx: ctx,
              ),
              const SizedBox(height: 8),
              _OpcionEstadoItem(
                activo: activo,
                estado: 'En reparación',
                color: const Color(0xFFF59E0B),
                bg: const Color(0xFFFEF3C7),
                actual: activo.estado,
                ctx: ctx,
              ),
              const SizedBox(height: 8),
              _OpcionEstadoItem(
                activo: activo,
                estado: 'Fuera de servicio',
                color: const Color(0xFFEF4444),
                bg: const Color(0xFFFEE2E2),
                actual: activo.estado,
                ctx: ctx,
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getColorParaEstado(String estado) {
    final e = estado.toLowerCase().trim();
    if (e.contains('uso') || e == 'bueno') {
      return const Color(0xFF10B981); // Verde esmeralda
    }
    if (e.contains('reparación') || e == 'regular' || e.contains('reparaci')) {
      return const Color(0xFFF59E0B); // Ámbar / amarillo
    }
    if (e.contains('fuera') || e == 'malo') {
      return const Color(0xFFEF4444); // Rojo coral
    }
    return const Color(0xFF9CA3AF);
  }

  Color _getBadgeBgParaEstado(String estado) {
    final e = estado.toLowerCase().trim();
    if (e.contains('uso') || e == 'bueno') {
      return const Color(0xFFD1FAE5);
    }
    if (e.contains('reparación') || e == 'regular' || e.contains('reparaci')) {
      return const Color(0xFFFEF3C7);
    }
    if (e.contains('fuera') || e == 'malo') {
      return const Color(0xFFFEE2E2);
    }
    return const Color(0xFFF3F4F6);
  }

  Color _getBadgeTextParaEstado(String estado) {
    final e = estado.toLowerCase().trim();
    if (e.contains('uso') || e == 'bueno') {
      return const Color(0xFF065F46);
    }
    if (e.contains('reparación') || e == 'regular' || e.contains('reparaci')) {
      return const Color(0xFF92400E);
    }
    if (e.contains('fuera') || e == 'malo') {
      return const Color(0xFF991B1B);
    }
    return const Color(0xFF4B5563);
  }

  IconData _getIconForAsset(String nombre, String? categoria) {
    final str = '${nombre.toLowerCase()} ${(categoria ?? "").toLowerCase()}';
    if (str.contains('horno') ||
        str.contains('cocina') ||
        str.contains('amasador') ||
        str.contains('industrial')) {
      return Icons.precision_manufacturing_outlined;
    }
    if (str.contains('carrito') ||
        str.contains('moto') ||
        str.contains('auto') ||
        str.contains('vehic') ||
        str.contains('delivery')) {
      return Icons.local_shipping_outlined;
    }
    if (str.contains('mesa') ||
        str.contains('silla') ||
        str.contains('mueble') ||
        str.contains('mostrador') ||
        str.contains('estante')) {
      return Icons.chair_outlined;
    }
    if (str.contains('refriger') ||
        str.contains('congel') ||
        str.contains('licuad') ||
        str.contains('microond') ||
        str.contains('batidor')) {
      return Icons.kitchen_outlined;
    }
    if (str.contains('pc') ||
        str.contains('comput') ||
        str.contains('laptop') ||
        str.contains('impresor') ||
        str.contains('pantalla')) {
      return Icons.devices_outlined;
    }
    return Icons.inventory_2_outlined;
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return 'Sin fecha';
    try {
      final partes = fecha.split(' ')[0].split('-');
      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }
    } catch (_) {}
    return fecha;
  }

  /// Construye la tarjeta individual de activo fijos (115px a 125px) con borde de acento,
  /// 3 columnas (miniatura, datos detallados, botón de 3 puntos) y microinteracción táctil
  Widget _buildAssetCard(ActivoFijo a, int index) {
    final colorEstado = _getColorParaEstado(a.estado);
    final badgeBg = _getBadgeBgParaEstado(a.estado);
    final badgeText = _getBadgeTextParaEstado(a.estado);

    return _FadeInUpItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: _ScaleCard(
          onTap: () => _openForm(activo: a),
          child: Container(
            constraints: const BoxConstraints(minHeight: 115),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  // Indicador de Estado Izquierdo: Barra vertical de 4px
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: 4,
                    child: Container(color: colorEstado),
                  ),

                  // Contenido interno con InkWell para splash suave
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openForm(activo: a),
                      splashColor: _accentOrange.withValues(alpha: 0.08),
                      highlightColor: _accentOrange.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Miniatura / Imagen (Izquierda): 80px × 80px, radio 12px
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _imageBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF3F4F6)),
                                image: a.fotoRuta != null && a.fotoRuta!.trim().isNotEmpty
                                    ? DecorationImage(
                                        image: FileImage(File(a.fotoRuta!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: a.fotoRuta == null || a.fotoRuta!.trim().isEmpty
                                  ? Center(
                                      child: Icon(
                                        _getIconForAsset(a.nombre, a.categoria),
                                        color: _accentOrange,
                                        size: 34,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),

                            // 2. Información Detallada (Centro)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Título del Activo en Poppins Bold 15sp (#1F2937)
                                  Text(
                                    a.nombre,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _textDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),

                                  // Línea 1 (Metadatos): "Maquinaria · Cant: 1"
                                  Text(
                                    '${a.categoria ?? "Sin categoría"} · Cant: ${a.cantidad}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.normal,
                                      color: _textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),

                                  // Línea 2 (Fecha): con icono pequeño de calendario (11sp)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 11,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Adquirido: ${_formatearFecha(a.fechaAdquisicion)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.normal,
                                          color: _textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),

                                  // Línea 3 (Costo / Tipo): "S/. 0.00 · Prestado"
                                  Text(
                                    'S/ ${a.costo.toStringAsFixed(2)} · ${a.condicion}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _textSecondaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Badge de Estado Inferior: Píldora compacta
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      a.estado,
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: badgeText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 3. Acción Rápida (Derecha): Botón circular de 36px × 36px
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Color(0xFF6B7280),
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                onSelected: (val) {
                                  if (val == 'edit') _openForm(activo: a);
                                  if (val == 'estado') _cambiarEstadoDialog(a);
                                  if (val == 'delete') _eliminar(a);
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Editar Activo',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: _textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'estado',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.sync_alt_rounded,
                                          size: 18,
                                          color: Color(0xFF10B981),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Cambiar Estado',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: _textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: Color(0xFFEF4444),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Eliminar',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFFEF4444),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivoFijoController>(
      builder: (context, controller, child) {
        List<ActivoFijo> activosFiltrados = controller.activos;
        if (_filtroActual != 'Todos') {
          activosFiltrados = activosFiltrados.where((a) {
            String e = a.estado.toLowerCase().trim();
            if (_filtroActual == 'En uso') {
              return e.contains('uso') || e == 'bueno';
            }
            if (_filtroActual == 'En reparación') {
              return e.contains('reparaci') || e == 'regular';
            }
            if (_filtroActual == 'Fuera de servicio') {
              return e.contains('fuera') || e == 'malo';
            }
            return true;
          }).toList();
        }

        final filtros = const [
          'Todos',
          'En uso',
          'En reparación',
          'Fuera de servicio',
        ];

        return Scaffold(
          backgroundColor: _bgScreen,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: _bgScreen,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: _textDark,
                size: 24,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Volver',
            ),
            title: Text(
              'Activos Fijos',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textDark,
                letterSpacing: -0.3,
              ),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),

              // ----------------------------------------------------
              // FILTROS RÁPIDOS SEGMENTADOS (HORIZONTAL SCROLL)
              // ----------------------------------------------------
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: filtros.length,
                  itemBuilder: (context, idx) {
                    final filtro = filtros[idx];
                    final isSelected = _filtroActual == filtro;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChipWidget(
                        label: filtro,
                        isSelected: isSelected,
                        onTap: () {
                          if (!isSelected) {
                            setState(() => _filtroActual = filtro);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // ----------------------------------------------------
              // LISTA DE ACTIVOS
              // ----------------------------------------------------
              Expanded(
                child: controller.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(_accentOrange),
                        ),
                      )
                    : controller.activos.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: _chipActiveBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 48,
                                      color: _accentOrange,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No hay activos registrados',
                                    style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: _textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Registra tu primer activo fijo como hornos, carritos o mobiliario para comenzar.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: _textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () => _openForm(),
                                    icon: const Icon(Icons.add, color: Colors.white),
                                    label: Text(
                                      'Crear mi primer activo',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _accentOrange,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : activosFiltrados.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.filter_list_off_rounded,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'No hay activos en este estado',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'No se encontraron activos con el filtro "$_filtroActual".',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: _textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                color: _accentOrange,
                                onRefresh: () async {
                                  await controller.loadActivos();
                                },
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 4,
                                  ),
                                  itemCount: activosFiltrados.length,
                                  itemBuilder: (ctx, index) {
                                    final a = activosFiltrados[index];
                                    return _buildAssetCard(a, index);
                                  },
                                ),
                              ),
              ),
            ],
          ),

          // ----------------------------------------------------
          // BOTÓN FLOTANTE DE ACCIÓN (FAB - CREAR ACTIVO)
          // ----------------------------------------------------
          floatingActionButton: _AnimatedFab(
            onPressed: () => _openForm(),
          ),
        );
      },
    );
  }
}

/// Chip de filtro segmentado con animación de selección de 200ms
class _FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipWidget({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFEBE3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6A00) : const Color(0xFFE5E7EB),
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6A00).withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check,
                size: 14,
                color: Color(0xFFD62828),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFD62828)
                    : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget envoltorio para animación en cascada suave (FadeInUp) con desfase de 50ms
class _FadeInUpItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _FadeInUpItem({required this.index, required this.child});

  @override
  State<_FadeInUpItem> createState() => _FadeInUpItemState();
}

class _FadeInUpItemState extends State<_FadeInUpItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    ));

    final delay = Duration(milliseconds: (widget.index * 50).clamp(0, 500));
    Future.delayed(delay, () {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}

/// Microinteracción táctil con escalado a 0.98x al pulsar la tarjeta
class _ScaleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleCard({required this.child, required this.onTap});

  @override
  State<_ScaleCard> createState() => _ScaleCardState();
}

class _ScaleCardState extends State<_ScaleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Botón Flotante (FAB) animado de 56x56 con degradado, sombra difusa y rotación sutil al pulsar
class _AnimatedFab extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedFab({required this.onPressed});

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.elasticOut,
    );
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedRotation(
            turns: _isPressed ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6A00), Color(0xFFD62828)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6A00).withValues(alpha: 0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ítem seleccionable dentro del diálogo de cambio de estado
class _OpcionEstadoItem extends StatelessWidget {
  final ActivoFijo activo;
  final String estado;
  final Color color;
  final Color bg;
  final String actual;
  final BuildContext ctx;

  const _OpcionEstadoItem({
    required this.activo,
    required this.estado,
    required this.color,
    required this.bg,
    required this.actual,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = actual.toLowerCase().trim() == estado.toLowerCase().trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          Navigator.pop(ctx);
          if (activo.id != null) {
            await context.read<ActivoFijoController>().cambiarEstado(
                  activo.id!,
                  estado,
                );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? bg : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE5E7EB),
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  estado,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
