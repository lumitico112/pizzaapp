# Add gastos loading to ComprasController
path = "C:/D/ProyectoPizza/pizzaapp/lib/controllers/compras_controller.dart"
with open(path, "r", encoding="utf-8") as f:
    text = f.read()

old_class_fields = """  List<Compra> _historial = [];
  bool _isLoading = false;
  String? _error;

  List<Compra> get historial => _historial;
  bool get isLoading => _isLoading;
  String? get error => _error;"""

new_class_fields = """  List<Compra> _historial = [];
  List<Map<String, dynamic>> _gastos = [];
  bool _isLoading = false;
  String? _error;

  List<Compra> get historial => _historial;
  List<Map<String, dynamic>> get gastos => _gastos;
  bool get isLoading => _isLoading;
  String? get error => _error;"""

text = text.replace(old_class_fields, new_class_fields)

old_load = """  Future<void> loadHistorial() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _historial = await _service.obtenerHistorialCompras();
    } catch (e) {
      _error = 'Error al cargar compras: \\$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }"""

new_load = """  Future<void> loadHistorial() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _historial = await _service.obtenerHistorialCompras();
      _gastos = await _service.obtenerGastosRaw();
    } catch (e) {
      _error = 'Error al cargar: \\$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }"""

text = text.replace(old_load, new_load)

with open(path, "w", encoding="utf-8") as f:
    f.write(text)
print("Done")
