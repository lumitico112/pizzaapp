import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/models/promocion.dart';
import 'package:pizzaapp/controllers/promocion_controller.dart';
import 'package:pizzaapp/app/app_router.dart';

/// Pantalla rediseñada de Promociones bajo Material Design 3.
/// Implementa la paleta de la marca (#FF6A00, #D62828, #1F2937, #FBF9F5),
/// tarjetas con iconografía descriptiva, badges semánticos con punto de estado,
/// días de vigencia legibles y animación de entrada en cascada.
class PromocionesScreen extends StatefulWidget {
  const PromocionesScreen({super.key});

  @override
  State<PromocionesScreen> createState() => _PromocionesScreenState();
}

class _PromocionesScreenState extends State<PromocionesScreen> {
  // Paleta de colores corporativa
  static const Color _primaryOrange = Color(0xFFFF6A00);
  static const Color _secondaryRed = Color(0xFFD62828);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _bgScreen = Color(0xFFFBF9F5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromocionController>().loadPromociones();
    });
  }

  void _abrirFormulario({Promocion? promocion}) async {
    final result = await AppRouter.push<bool>(
      context,
      AppRoutes.promocionForm,
      arguments: promocion,
    );
    if (result == true && mounted) {
      context.read<PromocionController>().loadPromociones();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PromocionController>(
      builder: (context, ctrl, _) {
        return Scaffold(
          backgroundColor: _bgScreen,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              tooltip: 'Volver',
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Promociones',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Actualizar',
                onPressed: ctrl.loadPromociones,
              ),
            ],
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_secondaryRed, _primaryOrange],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          body: ctrl.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryOrange),
                  ),
                )
              : ctrl.promociones.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1ED),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.local_offer_outlined,
                                color: _secondaryRed,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Sin promociones activas',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Crea combos y descuentos especiales para impulsar tus ventas.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: _textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
                      itemCount: ctrl.promociones.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _StaggeredPromocionCard(
                        key: ValueKey(ctrl.promociones[i].id ?? i),
                        promocion: ctrl.promociones[i],
                        index: i,
                        onEdit: () =>
                            _abrirFormulario(promocion: ctrl.promociones[i]),
                      ),
                    ),
          floatingActionButton: SafeArea(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryOrange, _secondaryRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryOrange.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
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
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Nueva Promoción',
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
          ),
        );
      },
    );
  }
}

/// Tarjeta individual de Promoción con animación en cascada
class _StaggeredPromocionCard extends StatefulWidget {
  final Promocion promocion;
  final int index;
  final VoidCallback onEdit;

  const _StaggeredPromocionCard({
    super.key,
    required this.promocion,
    required this.index,
    required this.onEdit,
  });

  @override
  State<_StaggeredPromocionCard> createState() =>
      _StaggeredPromocionCardState();
}

class _StaggeredPromocionCardState extends State<_StaggeredPromocionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delay = Duration(milliseconds: (widget.index * 40).clamp(0, 400));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDiasWidget(String? diasRaw) {
    if (diasRaw == null || diasRaw.trim().isEmpty) {
      return Row(
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            size: 14,
            color: Color(0xFF059669),
          ),
          const SizedBox(width: 6),
          Text(
            'Todos los días',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4B5563),
            ),
          ),
        ],
      );
    }

    final diasList = diasRaw.split(',').map((e) => e.trim()).toSet();
    if (diasList.length >= 7) {
      return Row(
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            size: 14,
            color: Color(0xFF059669),
          ),
          const SizedBox(width: 6),
          Text(
            'Todos los días (Lun - Dom)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4B5563),
            ),
          ),
        ],
      );
    }

    // Chips pequeños de días: L, M, M, J, V, S, D
    const diasInfo = [
      {'id': '1', 'letra': 'L'},
      {'id': '2', 'letra': 'M'},
      {'id': '3', 'letra': 'M'},
      {'id': '4', 'letra': 'J'},
      {'id': '5', 'letra': 'V'},
      {'id': '6', 'letra': 'S'},
      {'id': '7', 'letra': 'D'},
    ];

    return Row(
      children: [
        const Icon(
          Icons.calendar_today_rounded,
          size: 14,
          color: Color(0xFF059669),
        ),
        const SizedBox(width: 8),
        Wrap(
          spacing: 4,
          children: diasInfo.map((d) {
            final activo = diasList.contains(d['id']);
            return Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: activo
                    ? const Color(0xFFFFF1ED)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: activo
                      ? const Color(0xFFFFCDD2)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                d['letra']!,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: activo ? FontWeight.bold : FontWeight.w500,
                  color: activo
                      ? const Color(0xFFD62828)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.promocion;
    final isActive = p.activa == 1;

    final tieneHorario = (p.horaInicio != null && p.horaInicio!.isNotEmpty) &&
        (p.horaFin != null && p.horaFin!.isNotEmpty);
    final horarioTexto =
        tieneHorario ? '${p.horaInicio} - ${p.horaFin}' : 'Todo el día';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila Superior: Icono + Título + Badge + Botón Editar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icono Descriptivo (44x44, radio 12)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_offer_outlined,
                        color: Color(0xFFD62828),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Título (Expanded)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nombre,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Badge de Estado con punto indicador
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFFECACA),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFDC2626),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isActive ? 'Activo' : 'Inactivo',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botón Editar Cuadrado Redondeado (36x36, radio 10)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFFEDD5),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: widget.onEdit,
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFF3F4F6), height: 1),
                const SizedBox(height: 10),

                // Bloque de Precio y Condiciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Precio Destacado (en Soles peruanos)
                    Text(
                      'Precio: S/ ${p.precio.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD62828),
                      ),
                    ),
                    // Horario
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          horarioTexto,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Días de Vigencia
                _buildDiasWidget(p.diasSemana),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
