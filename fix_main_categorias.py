import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/main.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import_lines = """import 'package:pizzaapp/controllers/activo_fijo_controller.dart';
import 'package:pizzaapp/services/activo_fijo_service.dart';
import 'package:pizzaapp/repositories/activo_fijo_repository.dart';"""

new_import_lines = """import 'package:pizzaapp/controllers/activo_fijo_controller.dart';
import 'package:pizzaapp/services/activo_fijo_service.dart';
import 'package:pizzaapp/repositories/activo_fijo_repository.dart';
import 'package:pizzaapp/repositories/categoria_activo_repository.dart';
import 'package:pizzaapp/services/categoria_activo_service.dart';
import 'package:pizzaapp/controllers/categoria_activo_controller.dart';"""

text = text.replace(import_lines, new_import_lines)

injection_lines = """  final activoFijoRepo = ActivoFijoRepository();
  final activoFijoService = ActivoFijoService(activoFijoRepo, gastoRepo, insumoRepo);"""

new_injection_lines = """  final activoFijoRepo = ActivoFijoRepository();
  final activoFijoService = ActivoFijoService(activoFijoRepo, gastoRepo, insumoRepo);
  final categoriaActivoRepo = CategoriaActivoRepository();
  final categoriaActivoService = CategoriaActivoService(categoriaActivoRepo);"""

text = text.replace(injection_lines, new_injection_lines)

provider_lines = """        ChangeNotifierProvider(create: (_) => ActivoFijoController(activoFijoService)),"""

new_provider_lines = """        ChangeNotifierProvider(create: (_) => ActivoFijoController(activoFijoService)),
        ChangeNotifierProvider(create: (_) => CategoriaActivoController(categoriaActivoService)),"""

text = text.replace(provider_lines, new_provider_lines)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
