import sys
path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/dashboard/dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import_str = "import 'package:pizzaapp/screens/preparacion/sugerencias_screen.dart';\nimport 'package:pizzaapp/core/utils/formatters.dart';\nimport 'package:pizzaapp/screens/usuarios/user_profile_dialog.dart';\nimport 'package:pizzaapp/controllers/auth_controller.dart';\nimport 'dart:io';"
text = text.replace("import 'package:pizzaapp/screens/preparacion/sugerencias_screen.dart';\nimport 'package:pizzaapp/core/utils/formatters.dart';", import_str)

old_appbar = """          appBar: AppBar(
            title: const Text('PizzApp Dashboard'),
            actions: [
              IconButton(icon: const Icon(Icons.person), onPressed: () {}),
            ],
          ),"""

new_appbar = """          appBar: AppBar(
            title: const Text('PizzApp Dashboard'),
            actions: [
              IconButton(
                icon: Builder(
                  builder: (ctx) {
                    final user = ctx.watch<AuthController>().currentUser;
                    if (user?.fotoRuta != null) {
                      return CircleAvatar(backgroundImage: FileImage(File(user!.fotoRuta!)), radius: 14);
                    }
                    return const Icon(Icons.person);
                  }
                ), 
                onPressed: () {
                  showDialog(context: context, builder: (_) => const UserProfileDialog());
                }
              ),
            ],
          ),"""

text = text.replace(old_appbar, new_appbar)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
