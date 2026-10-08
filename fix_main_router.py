import re

path = 'C:/D/ProyectoPizza/pizzaapp/lib/main.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Add AppRouter import after last import
if "app_router" not in text:
    text = text.replace(
        "import 'package:pizzaapp/core/database/database_helper.dart';",
        "import 'package:pizzaapp/core/database/database_helper.dart';\nimport 'package:pizzaapp/app/app_router.dart';"
    )

# Replace the PizzApp class to use onGenerateRoute
old_app = """class PizzApp extends StatelessWidget {
  final bool hasAdmin;

  const PizzApp({super.key, required this.hasAdmin});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PizzApp',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: hasAdmin ? const LoginScreen() : const OnboardingScreen(),
    );
  }
}"""

new_app = """class PizzApp extends StatelessWidget {
  final bool hasAdmin;

  const PizzApp({super.key, required this.hasAdmin});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PizzApp',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: hasAdmin ? AppRoutes.login : AppRoutes.onboarding,
    );
  }
}"""

text = text.replace(old_app, new_app)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print("Done")
