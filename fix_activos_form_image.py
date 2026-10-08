import sys
path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/activos_fijos/activo_fijo_form_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("await _imageService.takePicture()", "await _imageService.pickImageFromCamera()")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
