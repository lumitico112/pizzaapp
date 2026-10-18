import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizzaapp/controllers/onboarding_controller.dart';
import 'package:pizzaapp/core/theme/app_colors.dart';
import 'package:pizzaapp/core/theme/app_radius.dart';
import 'package:pizzaapp/core/theme/app_spacing.dart';
import 'package:pizzaapp/core/theme/app_text_styles.dart';
import 'package:pizzaapp/features/backup/presentation/backup_screen.dart';
import 'package:pizzaapp/screens/auth/login_screen.dart';
import 'package:pizzaapp/services/image_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _businessFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();
  final _imageService = ImageService();

  final _nombreNegocioController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminUsernameController = TextEditingController(text: 'admin');
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminConfirmPasswordController = TextEditingController();

  int _step = 0;
  String _monedaSeleccionada = 'PEN';
  String? _logoRuta;
  String? _fondoRuta;
  String? _fotoAdminRuta;
  bool _mostrarPassword = false;
  bool _mostrarConfirmacion = false;
  String? _submitError;

  Future<void> _pickImage(String type, {required bool useCamera}) async {
    final path = useCamera
        ? await _imageService.pickImageFromCamera()
        : await _imageService.pickImageFromGallery();
    if (!mounted || path == null) return;

    setState(() {
      switch (type) {
        case 'logo':
          _logoRuta = path;
        case 'fondo':
          _fondoRuta = path;
        case 'admin':
          _fotoAdminRuta = path;
      }
    });
  }

  void _continue() {
    final form = _businessFormKey.currentState;
    if (form == null || !form.validate()) {
      setState(() => _submitError = 'Revisa los datos del negocio marcados.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _submitError = null;
      _step = 1;
    });
  }

  Future<void> _restoreBackup() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const BackupScreen(restorationOnly: true),
      ),
    );
  }

  Future<void> _saveConfiguration() async {
    final form = _adminFormKey.currentState;
    if (form == null || !form.validate()) {
      setState(
        () => _submitError = 'Revisa los campos marcados. La contraseña debe tener al menos 8 caracteres.',
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Revisa los campos marcados antes de continuar.'),
          ),
        );
      return;
    }
    if (_adminPasswordController.text != _adminConfirmPasswordController.text) {
      setState(() => _submitError = 'Las contraseñas no coinciden.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() => _submitError = null);
    FocusScope.of(context).unfocus();
    final controller = context.read<OnboardingController>();
    final success = await controller.setupSystem(
      nombreNegocio: _nombreNegocioController.text,
      moneda: _monedaSeleccionada,
      adminNombre: _adminNameController.text,
      adminUsername: _adminUsernameController.text,
      adminEmail: _adminEmailController.text,
      adminPassword: _adminPasswordController.text,
      logoRuta: _logoRuta,
      fondoRuta: _fondoRuta,
      fotoAdminRuta: _fotoAdminRuta,
    );

    if (!mounted) return;
    if (!success) {
      setState(
        () => _submitError =
            controller.error ?? 'No se pudo guardar la configuración.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? 'No se pudo configurar la app.'),
        ),
      );
      return;
    }

    final recoveryCode = controller.takeRecoveryCode();
    if (recoveryCode != null) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.lock_reset, color: AppColors.primary),
          title: const Text('Guarda tu clave de rescate'),
          content: SelectableText(
            '$recoveryCode\n\nAnótala y guárdala fuera del teléfono. Se muestra una sola vez y la necesitarás si olvidas tu contraseña.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ya la guardé'),
            ),
          ],
        ),
      );
    }

    if (!mounted) return;
    await Navigator.pushReplacement<void, void>(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(.04, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  @override
  void dispose() {
    _nombreNegocioController.dispose();
    _adminNameController.dispose();
    _adminUsernameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _adminConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<OnboardingController>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_step == 1) _buildStepTwoHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(_step == 0 ? .035 : -.035, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _step == 0
                    ? _buildBusinessStep(key: const ValueKey('business'))
                    : _buildAdminStep(key: const ValueKey('administrator')),
              ),
            ),
            _buildFooter(isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessStep({required Key key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      child: Form(
        key: _businessFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeHero(),
            const SizedBox(height: AppSpacing.md),
            _OnboardingCard(
              title: 'Datos del negocio',
              icon: Icons.storefront_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ImageSetupRow(
                    title: 'Logo de la empresa',
                    path: _logoRuta,
                    icon: Icons.add_photo_alternate_outlined,
                    onGallery: () => _pickImage('logo', useCamera: false),
                    onCamera: () => _pickImage('logo', useCamera: true),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ImageSetupRow(
                    title: 'Fondo de inicio de sesión',
                    path: _fondoRuta,
                    icon: Icons.wallpaper_outlined,
                    onGallery: () => _pickImage('fondo', useCamera: false),
                    onCamera: () => _pickImage('fondo', useCamera: true),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _nombreNegocioController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la pizzería',
                      prefixIcon: Icon(Icons.store_mall_directory_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Escribe el nombre del negocio.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _monedaSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Moneda principal',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'PEN',
                        child: Text('Soles (PEN)'),
                      ),
                      DropdownMenuItem(
                        value: 'USD',
                        child: Text('Dólares (USD)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _monedaSeleccionada = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminStep({required Key key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      child: Form(
        key: _adminFormKey,
        child: _OnboardingCard(
          title: 'Usuario administrador',
          subtitle: 'Crea el acceso privado para gestionar tu negocio.',
          icon: Icons.person_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfilePhotoPicker(
                path: _fotoAdminRuta,
                onGallery: () => _pickImage('admin', useCamera: false),
                onCamera: () => _pickImage('admin', useCamera: true),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _adminNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'Ej. Juan Pérez',
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _adminUsernameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Usuario para la app',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _adminEmailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Escribe un correo electrónico.';
                  }
                  if (!value.contains('@')) return 'Revisa el correo.';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _adminPasswordController,
                obscureText: !_mostrarPassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  helperText: 'Mínimo 8 caracteres',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _mostrarPassword ? 'Ocultar' : 'Mostrar',
                    onPressed: () =>
                        setState(() => _mostrarPassword = !_mostrarPassword),
                    icon: Icon(
                      _mostrarPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.length < 8
                    ? 'Usa al menos 8 caracteres.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _adminConfirmPasswordController,
                obscureText: !_mostrarConfirmacion,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveConfiguration(),
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: const Icon(Icons.verified_user_outlined),
                  suffixIcon: IconButton(
                    tooltip: _mostrarConfirmacion ? 'Ocultar' : 'Mostrar',
                    onPressed: () => setState(
                      () => _mostrarConfirmacion = !_mostrarConfirmacion,
                    ),
                    icon: Icon(
                      _mostrarConfirmacion
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirma tu contraseña.';
                  }
                  if (value != _adminPasswordController.text) {
                    return 'Las contraseñas no coinciden.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Text(
                  'Al terminar, guarda la clave de rescate que aparecerá en pantalla.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio.'
      : null;

  Widget _buildWelcomeHero() {
    return Container(
      height: 174,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A00), Color(0xFFFFB000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.xlAll,
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -35,
            top: -65,
            child: _DecorativeCircle(size: 180, opacity: .13),
          ),
          Positioned(
            right: 12,
            bottom: -58,
            child: Icon(
              Icons.local_pizza_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: .13),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 35,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Bienvenido a PizzaApp',
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Configura tu negocio y comienza a recibir pedidos.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: .92),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepTwoHeader() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF8A00), Color(0xFFFFB000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            bottom: -55,
            child: Icon(
              Icons.local_pizza_rounded,
              size: 145,
              color: Colors.white.withValues(alpha: .12),
            ),
          ),
          Row(
            children: [
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Volver',
                  onPressed: () => setState(() => _step = 0),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                '¡Vamos a\ncomenzar!',
                textAlign: TextAlign.right,
                style: AppTextStyles.heading2.copyWith(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isLoading) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      color: AppColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_submitError != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: AppRadius.mdAll,
              ),
              child: Text(
                _submitError!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7900), Color(0xFFFFB000)],
                ),
                borderRadius: AppRadius.lgAll,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .18),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: isLoading
                    ? null
                    : _step == 0
                    ? _continue
                    : _saveConfiguration,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
                ),
                icon: isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _step == 0
                            ? Icons.arrow_forward_rounded
                            : Icons.check_circle_outline_rounded,
                      ),
                label: Text(
                  _step == 0 ? 'CONTINUAR' : 'FINALIZAR Y ENTRAR',
                  style: AppTextStyles.buttonLarge,
                ),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: isLoading ? null : _restoreBackup,
            icon: const Icon(Icons.info_outline_rounded, size: 18),
            label: const Text('Ya tengo una copia para restaurar'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              final active = index == _step;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: active ? 20 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.cardBorder,
                  borderRadius: AppRadius.roundAll,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.xlAll,
      border: Border.all(color: AppColors.cardBorder.withValues(alpha: .7)),
      boxShadow: [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: .045),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: .18),
                borderRadius: AppRadius.mdAll,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading3),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    ),
  );
}

class _ImageSetupRow extends StatelessWidget {
  const _ImageSetupRow({
    required this.title,
    required this.path,
    required this.icon,
    required this.onGallery,
    required this.onCamera,
  });

  final String title;
  final String? path;
  final IconData icon;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyles.labelBold),
      const SizedBox(height: AppSpacing.xs),
      Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.mdAll,
            child: Container(
              width: 72,
              height: 72,
              color: AppColors.surfaceVariant,
              child: path == null
                  ? Icon(icon, color: AppColors.textSecondary, size: 30)
                  : Image.file(
                      File(path!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Icon(icon, color: AppColors.textSecondary, size: 30),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              children: [
                _ImageChoiceButton(
                  icon: Icons.photo_library_outlined,
                  title: 'Galería',
                  onPressed: onGallery,
                ),
                const SizedBox(height: AppSpacing.xs),
                _ImageChoiceButton(
                  icon: Icons.photo_camera_outlined,
                  title: 'Cámara',
                  onPressed: onCamera,
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

class _ProfilePhotoPicker extends StatelessWidget {
  const _ProfilePhotoPicker({
    required this.path,
    required this.onGallery,
    required this.onCamera,
  });

  final String? path;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.max,
    children: [
      Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: AppColors.surfaceVariant,
            foregroundImage: path == null ? null : FileImage(File(path!)),
            child: path == null
                ? const Icon(
                    Icons.person_outline_rounded,
                    size: 45,
                    color: AppColors.textHint,
                  )
                : null,
          ),
          Positioned(
            right: -2,
            bottom: 0,
            child: CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          children: [
            _ImageChoiceButton(
              icon: Icons.photo_library_outlined,
              title: 'Galería',
              onPressed: onGallery,
            ),
            const SizedBox(height: AppSpacing.xs),
            _ImageChoiceButton(
              icon: Icons.photo_camera_outlined,
              title: 'Cámara',
              onPressed: onCamera,
            ),
          ],
        ),
      ),
    ],
  );
}

class _ImageChoiceButton extends StatelessWidget {
  const _ImageChoiceButton({
    required this.icon,
    required this.title,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 40,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(title),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primaryLight.withValues(alpha: .5)),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundAll),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
    ),
  );
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withValues(alpha: opacity),
        width: 22,
      ),
    ),
  );
}
