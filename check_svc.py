import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/services/compra_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find where pagarCuentaPorPagar method starts (to see current state)
for i, line in enumerate(lines, 1):
    if "pagarCuentaPorPagar" in line:
        print(f"Line {i}: {line.rstrip()}")

print("\n---\n")
for i in range(70, min(len(lines), 105)):
    print(f"Line {i+1}: {lines[i].rstrip()}")
