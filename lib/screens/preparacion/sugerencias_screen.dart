import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/features/preparation/presentation/controllers/sugerencia_controller.dart';
import 'package:pizzaapp/features/preparation/presentation/controllers/preparacion_controller.dart';
import 'package:pizzaapp/screens/preparacion/registro_preparacion_screen.dart';

/// Pantalla rediseñada de Sugerencias & Preparación bajo Material Design 3,
/// con paleta cálida (naranja #FF6A00, rojo #D62828, crema #FBF9F5, verde #10B981),
/// AppBar con gradiente y pestañas estilizadas, tarjetas de sugerencias con
/// distribución en 3 columnas sin colisión ni superposiciones de texto,
/// animación en cascada FadeInUp y botones inferiores con microinteracciones táctiles.
class SugerenciasScreen extends StatefulWidget {
  const SugerenciasScreen({super.key});

  @override
  State<SugerenciasScreen> createState() => _SugerenciasScreenState();
}

class _SugerenciasScreenState extends State<SugerenciasScreen> {
  // Paleta de colores cálida y coherente con la identidad de Kimi Pizza
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _primaryRed = Color(0xFFD62828);
  static const Color _accentOrange = Color(0xFFFF6A00);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _darkEmerald = Color(0xFF059669);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _boxBg = Color(0xFFFFF5F0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SugerenciaController>().loadSugerencias('hoy');
      context.read<PreparacionController>().loadHistorial();
    });
  }

  void _cambiarFiltro(String filtro) {
    context.read<SugerenciaController>().loadSugerencias(filtro);
  }

  Future<void> _aplicarSugerencias() async {
    final sugerencias = context.read<SugerenciaController>().sugerencias;
    if (sugerencias.isEmpty) return;

    final map = <int, int>{};
    for (var s in sugerencias) {
      if (s.sugerenciaFinal > 0) {
        map[s.varianteId] = s.sugerenciaFinal;
      }
    }

    if (map.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No hay sugerencias mayores a 0 para aplicar.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: _primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroPreparacionScreen(prefilledData: map),
      ),
    );
    if (!mounted) return;
    if (res == true) {
      context.read<PreparacionController>().loadHistorial();
    }
  }

  Future<void> _registrarPreparacion() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegistroPreparacionScreen(),
      ),
    );
    if (!mounted) return;
    if (res == true) {
      context.read<PreparacionController>().loadHistorial();
    }
  }

  /// Construye la tarjeta individual de sugerencia con distribución balanceada en 3 columnas
  Widget _buildSugerenciaCard(dynamic sug, int index) {
    final faltantes = sug.promedioFaltantes;
    final sobrantes = sug.promedioSobrantes;

    return _FadeInUpItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(minHeight: 105),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Icono Descriptivo (Izquierda, ~15%): Contenedor 42px × 42px, radio 12px
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBE3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: _accentOrange,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. Información de Métricas (Centro, ~55%): Amplio y sin colisiones
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Título del Producto: "Pizza Americana - Personal"
                    Text(
                      '${sug.productoNombre} - ${sug.varianteNombre}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Línea de métricas: Promedio de ventas
                    Text(
                      'Promedio ventas: ${sug.promedioVentas.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Badges ordenados para faltantes y sobrantes
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${faltantes.toStringAsFixed(0)} faltantes',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF047857),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${sobrantes.toStringAsFixed(0)} sobrantes',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 3. Valor de Sugerencia (Derecha, ~30%): Mini contenedor 68px × 60px
              Container(
                width: 68,
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: _boxBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _accentOrange.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sugerencia',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _accentOrange,
                      ),
                    ),
                    Text(
                      '${sug.sugerenciaFinal}',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _primaryRed,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SugerenciaController>(
      builder: (context, sugerenciaCtrl, child) {
        final filtroActivo = sugerenciaCtrl.filtroActivo;

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
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Volver',
            ),
            title: Text(
              'Sugerencias & Preparación',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    _PillTab(
                      label: 'Hoy',
                      activo: filtroActivo == 'hoy' && filtroActivo != 'historial',
                      onTap: () => _cambiarFiltro('hoy'),
                    ),
                    const SizedBox(width: 8),
                    _PillTab(
                      label: 'Mañana',
                      activo: filtroActivo == 'manana',
                      onTap: () => _cambiarFiltro('manana'),
                    ),
                    const SizedBox(width: 8),
                    _PillTab(
                      label: 'Semana',
                      activo: filtroActivo == 'semana',
                      onTap: () => _cambiarFiltro('semana'),
                    ),
                    const SizedBox(width: 8),
                    _PillTab(
                      label: 'Historial',
                      activo: filtroActivo == 'historial',
                      onTap: () => _cambiarFiltro('historial'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Vista de Sugerencias o Historial
              Expanded(
                child: filtroActivo == 'historial'
                    ? const _HistorialView()
                    : sugerenciaCtrl.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(_accentOrange),
                            ),
                          )
                        : sugerenciaCtrl.sugerencias.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFEBE3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.insights_rounded,
                                          size: 38,
                                          color: _accentOrange,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Sin sugerencias disponibles',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Se requieren más datos de ventas y preparaciones recientes para generar recomendaciones automáticas.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: _textMuted,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                color: _accentOrange,
                                onRefresh: () async {
                                  _cambiarFiltro(filtroActivo);
                                },
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 16,
                                  ),
                                  itemCount: sugerenciaCtrl.sugerencias.length,
                                  itemBuilder: (context, index) {
                                    final sug =
                                        sugerenciaCtrl.sugerencias[index];
                                    return _buildSugerenciaCard(sug, index);
                                  },
                                ),
                              ),
              ),

              // ----------------------------------------------------
              // 4. ACCIONES INFERIORES (BOTONES DEL PIE ANCLADOS)
              // ----------------------------------------------------
              if (filtroActivo != 'historial')
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(
                      top: BorderSide(color: _cardBorder),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón 1: Aplicar Sugerencias a Preparación Hoy
                        _ScaleButton(
                          onTap: _aplicarSugerencias,
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_accentOrange, _primaryRed],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _accentOrange.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Aplicar Sugerencias a Preparación Hoy',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Botón 2: Registrar Preparación Manual
                        _ScaleButton(
                          onTap: _registrarPreparacion,
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: _darkEmerald,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _emeraldGreen.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '+ Registrar Preparación',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Pestaña superior con animación de selección fluida (200ms)
class _PillTab extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _PillTab({
    required this.label,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 36,
          decoration: BoxDecoration(
            color: activo ? Colors.white : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: activo
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: activo
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: activo ? FontWeight.bold : FontWeight.w500,
                color: activo ? const Color(0xFFD62828) : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vista del Historial de Preparaciones con Material Design 3
class _HistorialView extends StatelessWidget {
  const _HistorialView();

  @override
  Widget build(BuildContext context) {
    return Consumer<PreparacionController>(
      builder: (context, prepCtrl, child) {
        if (prepCtrl.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6A00)),
            ),
          );
        }
        if (prepCtrl.historial.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.history_toggle_off_rounded,
                    size: 48,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aún no hay preparaciones registradas',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Las sesiones de preparación guardadas aparecerán en esta sección.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFFFF6A00),
          onRefresh: () async {
            await prepCtrl.loadHistorial();
          },
          child: ListView.builder(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            itemCount: prepCtrl.historial.length,
            itemBuilder: (ctx, i) {
              final h = prepCtrl.historial[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: Color(0xFF059669),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Fecha: ${h.fecha}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    subtitle: Text(
                      h.nota?.trim().isNotEmpty == true
                          ? h.nota!
                          : 'Preparación completada',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    children: h.items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_pizza_outlined,
                                  size: 16,
                                  color: Color(0xFFFF6A00),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${item.productoNombre} - ${item.varianteNombre}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '+${item.cantidadPreparada}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF059669),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),
        );
      },
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
      duration: const Duration(milliseconds: 340),
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

/// Microinteracción táctil con escalado a 0.98x al pulsar el botón
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
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
