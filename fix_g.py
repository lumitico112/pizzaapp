import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/gastos/gastos_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace(r'-\${CurrencyFormatter', r'-${CurrencyFormatter')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
