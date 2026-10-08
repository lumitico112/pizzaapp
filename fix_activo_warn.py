import sys
path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/activo_fijo_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("final id = await _repository.insert(activo);", "await _repository.insert(activo);")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
