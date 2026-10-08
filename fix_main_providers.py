import sys
path = 'C:/D/ProyectoPizza/pizzaapp/lib/main.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import_str = "import 'package:pizzaapp/services/usuario_service.dart';\nimport 'package:pizzaapp/controllers/usuario_controller.dart';\n"
if "import 'package:pizzaapp/services/usuario_service.dart';" not in text:
    text = text.replace("import 'package:pizzaapp/services/auth_service.dart';", import_str + "import 'package:pizzaapp/services/auth_service.dart';")

services_old = """    final authService = AuthService(usuarioRepo);"""
services_new = """    final authService = AuthService(usuarioRepo);
    final usuarioService = UsuarioService(usuarioRepo, authService);"""
if "UsuarioService(usuarioRepo, authService)" not in text:
    text = text.replace(services_old, services_new)

provider_old = """        ChangeNotifierProvider(create: (_) => AuthController(authService)),"""
provider_new = """        ChangeNotifierProvider(create: (_) => AuthController(authService)),
        ChangeNotifierProvider(create: (_) => UsuarioController(usuarioService)),"""
if "UsuarioController(usuarioService)" not in text:
    text = text.replace(provider_old, provider_new)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
