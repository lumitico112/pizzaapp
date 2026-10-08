import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/caja/cierre_caja_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("if (controller.cierreDiario != null && controller.cierreDiario!.cerrado == 1)", "if (controller.yaEstaCerrado)")
text = text.replace("if (controller.cierreDeHoy != null)", "if (controller.yaEstaCerrado)")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
