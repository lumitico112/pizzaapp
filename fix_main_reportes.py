import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/main.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import_str = "import 'package:pizzaapp/services/reporte_service.dart';\nimport 'package:pizzaapp/controllers/reporte_controller.dart';\n"
if "ReporteService" not in text:
    text = text.replace("import 'package:pizzaapp/services/pos_service.dart';", import_str + "import 'package:pizzaapp/services/pos_service.dart';")

services_old = """  final dashboardService = DashboardService(ventaRepo, insumoRepo);"""
services_new = """  final dashboardService = DashboardService(ventaRepo, insumoRepo);
  final reporteService = ReporteService();"""
if "ReporteService()" not in text:
    text = text.replace(services_old, services_new)

provider_old = """        ChangeNotifierProvider(create: (_) => DashboardController(dashboardService)),"""
provider_new = """        ChangeNotifierProvider(create: (_) => DashboardController(dashboardService)),
        ChangeNotifierProvider(create: (_) => ReporteController(reporteService)),"""
if "ReporteController(reporteService)" not in text:
    text = text.replace(provider_old, provider_new)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
