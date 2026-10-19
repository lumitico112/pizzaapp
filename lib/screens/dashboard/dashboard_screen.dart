import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/auth_controller.dart';
import 'package:pizzaapp/controllers/dashboard_controller.dart';
import 'package:pizzaapp/app/app_router.dart';
import 'package:pizzaapp/core/utils/formatters.dart';
import 'package:pizzaapp/services/dashboard_service.dart';
import 'package:pizzaapp/features/assets/presentation/screens/assets_screen.dart';
import 'package:pizzaapp/features/backup/presentation/backup_screen.dart';
import 'package:pizzaapp/screens/caja/caja_screen.dart';
import 'package:pizzaapp/screens/catalogo/catalogo_screen.dart';
import 'package:pizzaapp/screens/compras/compras_screen.dart';
import 'package:pizzaapp/screens/compras/por_pagar_screen.dart';
import 'package:pizzaapp/screens/insumos/insumos_screen.dart';
import 'package:pizzaapp/screens/mermas/mermas_screen.dart';
import 'package:pizzaapp/screens/pos/pos_screen.dart';
import 'package:pizzaapp/screens/preparacion/registro_preparacion_screen.dart';
import 'package:pizzaapp/screens/preparacion/sugerencias_screen.dart';
import 'package:pizzaapp/screens/promociones/promociones_screen.dart';
import 'package:pizzaapp/screens/reportes/reportes_screen.dart';
import 'package:pizzaapp/screens/usuarios/user_profile_screen.dart';
import 'package:pizzaapp/screens/proveedores/proveedores_screen.dart';
import 'package:pizzaapp/screens/configuracion/configuracion_negocio_screen.dart';
import 'package:pizzaapp/screens/usuarios/usuarios_screen.dart';
import 'package:pizzaapp/models/usuario.dart';
import 'package:pizzaapp/repositories/configuracion_repository.dart';
import 'package:pizzaapp/screens/dashboard/daily_financial_breakdown_sheet.dart';

/// Pantalla rediseñada del Dashboard Principal bajo Material Design 3,
/// con paleta cálida (#FBF9F5, #D62828, #FF6A00), avatar interactivo integrado,
/// Hero Card con degradado, Acciones Rápidas en cuadrícula de 2 columnas y Módulos desplegables.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  // Paleta de diseño especificada
  static const Color _bgScreen = Color(0xFFFBF9F5);
  static const Color _primaryText = Color(0xFF1F2937);
  static const Color _secondaryText = Color(0xFF6B7280);
  static const Color _bodyMuted = Color(0xFF4B5563);
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _primaryRed = Color(0xFFD62828);
  static const Color _accentOrange = Color(0xFFFF6A00);

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _businessName = 'KIMI PIZZA';
  String? _businessLogoPath;
  bool _modulosExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
      _loadBusinessBrand();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<DashboardController>().refreshDashboard();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadBusinessBrand() async {
    final repository = ConfiguracionRepository();
    final values = await Future.wait([
      repository.getConfig('nombre_negocio'),
      repository.getConfig('logo_ruta'),
    ]);
    if (!mounted) return;
    setState(() {
      if (values[0]?.trim().isNotEmpty == true) {
        _businessName = values[0]!.trim();
      }
      _businessLogoPath = values[1];
    });
  }

  Future<void> _loadStats() =>
      context.read<DashboardController>().loadDashboard();

  Future<T?> _open<T>(Widget screen, {bool refresh = false}) async {
    final result = await Navigator.push<T>(
      context,
      MaterialPageRoute<T>(builder: (_) => screen),
    );
    if (mounted && refresh) await _loadStats();
    return result;
  }

  Future<void> _showConfigurationSaved() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ConfigurationSavedDialog(),
    );
  }

  Future<void> _showDailyBreakdown() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const DailyFinancialBreakdownSheet(),
  );

  Future<void> _navigate(String title) async {
    final user = context.read<AuthController>().currentUser;
    if ((title == 'Configuración del negocio' ||
            title == 'Gestión de usuarios' ||
            title == 'Copias de seguridad') &&
        user?.rol != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta opción está disponible solo para el administrador.',
          ),
        ),
      );
      return;
    }
    switch (title) {
      case 'Ventas':
        await _open(const PosScreen(), refresh: true);
      case 'Caja':
        await _open(const CajaScreen(), refresh: true);
      case 'Preparación':
        await _open(const RegistroPreparacionScreen(), refresh: true);
      case 'Insumos':
        await _open(const InsumosScreen());
      case 'Productos':
        await _open(const CatalogoScreen());
      case 'Compras':
        await _open(const ComprasScreen(), refresh: true);
      case 'Por pagar':
        await _open(const PorPagarScreen(), refresh: true);
      case 'Mermas':
        await _open(const MermasScreen());
      case 'Activos':
        await _open(const ActivosFijosScreen());
      case 'Reportes':
        await _open(const ReportesScreen());
      case 'Promociones':
        await _open(const PromocionesScreen());
      case 'Proveedores':
        await _open(const ProveedoresScreen());
      case 'Sugerencias':
        await _open(const SugerenciasScreen());
      case 'Copias de seguridad':
        await _open(const BackupScreen());
      case 'Configuración del negocio':
        final saved = await _open<bool>(
          const ConfiguracionNegocioScreen(),
          refresh: true,
        );
        if (mounted && saved == true) await _showConfigurationSaved();
      case 'Gestión de usuarios':
        await _open(const UsuariosScreen());
      case 'Mi perfil':
        await _open(const UserProfileScreen());
    }
  }

  Future<void> _navigateFromDrawer(String title) async {
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    await _navigate(title);
    if (!mounted) return;
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        final summary = controller.summary;
        final user = context.watch<AuthController>().currentUser;
        final firstName = user?.nombre.split(' ').first ?? 'Dueña';
        final day = controller.getDiaSemana(DateTime.now().weekday);

        if (controller.isLoading) {
          return const Scaffold(
            backgroundColor: _bgScreen,
            body: Center(
              child: CircularProgressIndicator(color: _accentOrange),
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: _bgScreen,
          drawerScrimColor: Colors.black.withValues(alpha: .30),
          drawer: _buildNavigationDrawer(user),
          body: SafeArea(
            child: RefreshIndicator(
              color: _primaryRed,
              onRefresh: _loadStats,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      14,
                      18,
                      MediaQuery.viewPaddingOf(context).bottom + 32,
                    ),
                    sliver: SliverList.list(
                      children: [
                        // 1. Encabezado de Usuario (Header)
                        _buildHeader(firstName, day, user?.fotoRuta),
                        const SizedBox(height: 20),

                        // 2. Tarjeta de Resumen Financiero (Hero Card)
                        _buildSummaryCard(summary),
                        const SizedBox(height: 24),

                        // 3. Sección: Acciones Rápidas
                        _buildSectionHeader('Acciones rápidas'),
                        const SizedBox(height: 12),
                        _buildQuickActionsGrid(),

                        // Alerta de Cuentas por Pagar (si existen pendientes)
                        if (summary.cuentasPendientes > 0) ...[
                          const SizedBox(height: 18),
                          _buildPayablesNotice(
                            summary.cuentasPendientes,
                            summary.montoPendiente,
                          ),
                        ],

                        const SizedBox(height: 24),

                        // 4. Sección: Módulos (Visualización Previa al Despliegue)
                        _buildModulesHeader(),
                        const SizedBox(height: 12),

                        // Grilla de Módulos (Animación suave al expandir/contraer)
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 360),
                          firstCurve: Curves.easeInOutCubic,
                          secondCurve: Curves.easeInOutCubic,
                          sizeCurve: Curves.easeInOutCubic,
                          crossFadeState: _modulosExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: const SizedBox.shrink(),
                          secondChild: AnimatedSlide(
                            offset: _modulosExpanded
                                ? Offset.zero
                                : const Offset(0, -.06),
                            duration: const Duration(milliseconds: 360),
                            curve: Curves.easeInOutCubic,
                            child: _buildModuleGrid(
                              summary.cuentasPendientes,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Encabezado con Avatar interactivo (que abre el menú), Fecha y Saludo
  Widget _buildHeader(String firstName, String day, String? photoPath) {
    final hasPhoto = photoPath != null && File(photoPath).existsSync();

    return Row(
      children: [
        // Avatar táctil que abre el menú con microinteracción de escala
        _InteractiveAvatar(
          photoPath: photoPath,
          hasPhoto: hasPhoto,
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${DateTime.now().day} · $day',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: _secondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Hola, ${firstName.toUpperCase()}',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _primaryText,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Así va tu negocio hoy',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: _bodyMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tarjeta de Resumen Financiero con Gradiente cálido (#D62828 a #FF6A00)
  Widget _buildSummaryCard(DashboardSummary summary) {
    return _PressableScaleSurface(
      onTap: _showDailyBreakdown,
      radius: 20,
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryRed, _accentOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryRed.withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Métrica Principal: Ventas de hoy
          Text(
            'Ventas de hoy',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          _AnimatedCurrencyAmount(
            amount: summary.ventas,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
              height: 1.1,
            ),
          ),
          Text(
            '${summary.cantidadVentas} ${summary.cantidadVentas == 1 ? 'venta' : 'ventas'} · toca para ver el detalle',
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: .82),
            ),
          ),
          const SizedBox(height: 14),

          // Línea divisoria muy sutil
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.22),
          ),
          const SizedBox(height: 12),

          // Sub-métricas: Gastos y Resultado
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gastos',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    _AnimatedCurrencyAmount(
                      amount: summary.gastos,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${summary.cantidadGastos} ${summary.cantidadGastos == 1 ? 'movimiento' : 'movimientos'}',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        color: Colors.white.withValues(alpha: .78),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 26,
                color: Colors.white.withValues(alpha: 0.22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resultado',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    _AnimatedCurrencyAmount(
                      amount: summary.ganancia,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: _primaryText,
      ),
    );
  }

  /// Cuadrícula de 2 columnas para Acciones Rápidas (72px - 76px de altura)
  Widget _buildQuickActionsGrid() {
    return Column(
      children: [
        Row(
          children: [
            // 1. Nueva venta (Destacada en melocotón pastel)
            Expanded(
              child: _QuickActionCard(
                icon: Icons.shopping_cart_outlined,
                iconColor: _accentOrange,
                title: 'Nueva venta',
                subtitle: 'Registrar pedido',
                isProminent: true,
                onTap: () => _navigate('Ventas'),
              ),
            ),
            const SizedBox(width: 10),
            // 2. Preparación
            Expanded(
              child: _QuickActionCard(
                icon: Icons.restaurant_menu,
                iconColor: _primaryText,
                title: 'Preparación',
                subtitle: 'Organizar el día',
                isProminent: false,
                onTap: () => _open(
                  const RegistroPreparacionScreen(),
                  refresh: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // 3. Registrar compra
            Expanded(
              child: _QuickActionCard(
                icon: Icons.shopping_basket_outlined,
                iconColor: _primaryText,
                title: 'Registrar compra',
                subtitle: 'Ingresar insumos',
                isProminent: false,
                onTap: () => _navigate('Compras'),
              ),
            ),
            const SizedBox(width: 10),
            // 4. Revisar caja
            Expanded(
              child: _QuickActionCard(
                icon: Icons.point_of_sale_outlined,
                iconColor: _primaryText,
                title: 'Revisar caja',
                subtitle: 'Ver sesión operativa',
                isProminent: false,
                onTap: () => _navigate('Caja'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Encabezado de la sección Módulos con botón interactivo de abrir/cerrar
  Widget _buildModulesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionHeader('Módulos'),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() => _modulosExpanded = !_modulosExpanded);
            },
            child: Padding(
              // 15 px vertical + 14 px de línea garantiza un objetivo táctil
              // mínimo de 44 px de alto.
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
              child: Row(
                children: [
                  Text(
                    _modulosExpanded ? 'Toca para cerrar' : 'Toca para abrir',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _modulosExpanded
                          ? _secondaryText
                          : _accentOrange,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _modulosExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: _modulosExpanded
                          ? _secondaryText
                          : _accentOrange,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Grilla de módulos con tarjetas compactas de 56px de altura e iconografía en pastel
  Widget _buildModuleGrid(int payableCount) {
    final modules = <_ModuleCardData>[
      const _ModuleCardData(
        label: 'Sugerencias',
        icon: Icons.lightbulb_outline,
        iconColor: Color(0xFFD97706),
        bgColor: Color(0xFFFEF3C7),
      ),
      const _ModuleCardData(
        label: 'Insumos',
        icon: Icons.inventory_2_outlined,
        iconColor: Color(0xFFEA580C),
        bgColor: Color(0xFFFFEDD5),
      ),
      const _ModuleCardData(
        label: 'Productos',
        icon: Icons.local_pizza_outlined,
        iconColor: Color(0xFFDC2626),
        bgColor: Color(0xFFFEE2E2),
      ),
      const _ModuleCardData(
        label: 'Por pagar',
        icon: Icons.receipt_outlined,
        iconColor: Color(0xFF2563EB),
        bgColor: Color(0xFFDBEAFE),
      ),
      const _ModuleCardData(
        label: 'Activos',
        icon: Icons.devices_outlined,
        iconColor: Color(0xFF7C3AED),
        bgColor: Color(0xFFF3E8FF),
      ),
      const _ModuleCardData(
        label: 'Mermas',
        icon: Icons.delete_outline,
        iconColor: Color(0xFF6B7280),
        bgColor: Color(0xFFF3F4F6),
      ),
      const _ModuleCardData(
        label: 'Reportes',
        icon: Icons.analytics_outlined,
        iconColor: Color(0xFF059669),
        bgColor: Color(0xFFD1FAE5),
      ),
      const _ModuleCardData(
        label: 'Promociones',
        icon: Icons.local_offer_outlined,
        iconColor: Color(0xFFE04F1D),
        bgColor: Color(0xFFFFEBE3),
      ),
      const _ModuleCardData(
        label: 'Proveedores',
        icon: Icons.storefront_outlined,
        iconColor: Color(0xFF166534),
        bgColor: Color(0xFFDCFCE7),
      ),
    ];

    return GridView.builder(
      itemCount: modules.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 56,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final module = modules[index];
        final isPayables = module.label == 'Por pagar';

        return _PressableScaleSurface(
          onTap: () => _navigate(module.label),
          radius: 12,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cardBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icono en contenedor pastel (36px x 36px)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: module.bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    module.icon,
                    color: module.iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),

                // Nombre del módulo
                Expanded(
                  child: Text(
                    module.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _primaryText,
                    ),
                  ),
                ),

                // Badge de cuentas pendientes si aplica
                if (isPayables && payableCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$payableCount',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFD97706),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Aviso de Cuentas por Pagar pendientes
  Widget _buildPayablesNotice(int count, double amount) {
    return Material(
      color: const Color(0xFFFFFBEB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _navigate('Por pagar'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count ${count == 1 ? 'cuenta pendiente' : 'cuentas pendientes'}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _primaryText,
                      ),
                    ),
                    Text(
                      'Saldo total ${CurrencyFormatter.format(amount)}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: _secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFD97706),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menú lateral (Navigation Drawer) estilizado y fluido
  Widget _buildNavigationDrawer(Usuario? user) {
    final isAdmin = user?.rol == 'admin';
    final width = (MediaQuery.sizeOf(context).width * .8)
        .clamp(300.0, 380.0)
        .toDouble();
    final role = isAdmin ? 'Administradora' : 'Personal';
    final photoPath = user?.fotoRuta;
    final hasPhoto = photoPath != null && File(photoPath).existsSync();
    final hasLogo =
        _businessLogoPath != null && File(_businessLogoPath!).existsSync();

    return Drawer(
      width: width,
      backgroundColor: const Color(0xFFFBF9F5),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryRed, _accentOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: hasLogo
                              ? Image.file(
                                  File(_businessLogoPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.local_pizza_rounded,
                                    color: _primaryRed,
                                  ),
                                )
                              : const Icon(
                                  Icons.local_pizza_rounded,
                                  color: _primaryRed,
                                  size: 27,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _businessName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Gestión y Sabor',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: .85),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      _navigateFromDrawer('Mi perfil');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _accentOrange.withValues(alpha: .55),
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 23,
                              backgroundColor: const Color(0xFFFFEBE3),
                              foregroundImage: hasPhoto
                                  ? FileImage(File(photoPath))
                                  : null,
                              child: hasPhoto
                                  ? null
                                  : const Icon(
                                      Icons.person_outline_rounded,
                                      color: _primaryRed,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hola, ${user?.nombre.split(' ').first ?? 'Usuario'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  role,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: _secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: _cardBorder),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isAdmin ? 'Administración' : 'Herramientas',
                      style: GoogleFonts.poppins(
                        color: _secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                children: [
                  if (isAdmin)
                    _DrawerEntry(
                      index: 0,
                      icon: Icons.storefront_outlined,
                      title: 'Configuración del negocio',
                      onTap: () =>
                          _navigateFromDrawer('Configuración del negocio'),
                    ),
                  if (isAdmin)
                    _DrawerEntry(
                      index: 1,
                      icon: Icons.manage_accounts_outlined,
                      title: 'Gestión de usuarios',
                      onTap: () => _navigateFromDrawer('Gestión de usuarios'),
                    ),
                  if (isAdmin)
                    _DrawerEntry(
                      index: 2,
                      icon: Icons.backup_outlined,
                      title: 'Copias de seguridad',
                      onTap: () =>
                          _navigateFromDrawer('Copias de seguridad'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Column(
                children: [
                  const Divider(height: 1, color: _cardBorder),
                  const SizedBox(height: 10),
                  Material(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: () async {
                        final auth = context.read<AuthController>();
                        final navigator = Navigator.of(context)..pop();
                        await auth.logout();
                        navigator.pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (route) => false,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Cerrar sesión',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Versión 1.0.0 · $_businessName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar circular interactivo de 44px x 44px con microinteracción táctil
class _InteractiveAvatar extends StatefulWidget {
  final String? photoPath;
  final bool hasPhoto;
  final VoidCallback onTap;

  const _InteractiveAvatar({
    required this.photoPath,
    required this.hasPhoto,
    required this.onTap,
  });

  @override
  State<_InteractiveAvatar> createState() => _InteractiveAvatarState();
}

class _InteractiveAvatarState extends State<_InteractiveAvatar> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir menú principal',
      child: Tooltip(
        message: 'Menú principal',
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: Container(
              width: 44,
              height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: widget.hasPhoto
                ? Image.file(
                    File(widget.photoPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFFFEBE3),
      child: const Center(
        child: Icon(
          Icons.person_outline_rounded,
          color: Color(0xFFD62828),
          size: 24,
        ),
      ),
    );
  }
}

/// Tarjeta de Acción Rápida con altura de 74px, radio 14px y microinteracción táctil
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isProminent;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isProminent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: _PressableScaleSurface(
        onTap: onTap,
        radius: 14,
        child: Container(
          constraints: const BoxConstraints(minHeight: 74),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isProminent ? const Color(0xFFFFF1ED) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isProminent
                ? const Color(0xFFFFE0D6)
                : const Color(0xFFE5E7EB),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isProminent
                          ? const Color(0xFFD62828)
                          : const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.normal,
                      color: isProminent
                          ? const Color(0xFF4B5563)
                          : const Color(0xFF6B7280),
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
}

/// Contenedor interactivo con microinteracción táctil (escala 0.98x)
class _PressableScaleSurface extends StatefulWidget {
  final VoidCallback onTap;
  final double radius;
  final Widget child;

  const _PressableScaleSurface({
    required this.onTap,
    required this.radius,
    required this.child,
  });

  @override
  State<_PressableScaleSurface> createState() => _PressableScaleSurfaceState();
}

class _PressableScaleSurfaceState extends State<_PressableScaleSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(widget.radius),
    );
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: shape,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          splashColor: const Color(0xFFFF6A00).withValues(alpha: 0.08),
          highlightColor: const Color(0xFFFF6A00).withValues(alpha: 0.04),
          child: widget.child,
        ),
      ),
    );
  }
}

class _AnimatedCurrencyAmount extends StatelessWidget {
  const _AnimatedCurrencyAmount({
    required this.amount,
    required this.style,
    this.maxLines,
    this.overflow,
  });

  final double amount;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: amount),
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeOutCubic,
    builder: (context, value, _) => Text(
      CurrencyFormatter.format(value),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    ),
  );
}

class _ModuleCardData {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _ModuleCardData({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

class _DrawerEntry extends StatelessWidget {
  const _DrawerEntry({
    required this.index,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final int index;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: 280 + (index * 65));
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: delay,
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(-10 * (1 - progress), 0),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            splashColor: const Color(0xFFFFEBE3),
            highlightColor: const Color(0xFFFFEBE3).withValues(alpha: .65),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFFD62828), size: 21),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1F2937),
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 21,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigurationSavedDialog extends StatefulWidget {
  const _ConfigurationSavedDialog();

  @override
  State<_ConfigurationSavedDialog> createState() =>
      _ConfigurationSavedDialogState();
}

class _ConfigurationSavedDialogState extends State<_ConfigurationSavedDialog> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: .35, end: 1),
            duration: const Duration(milliseconds: 480),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: const CircleAvatar(
              radius: 34,
              backgroundColor: Color(0xFFD1FAE5),
              child: Icon(
                Icons.check_rounded,
                size: 42,
                color: Color(0xFF059669),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '¡Configuración guardada!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
