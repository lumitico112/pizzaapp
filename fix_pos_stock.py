import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/pos/pos_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_str = """                                            Text(item.producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            Text(item.variante.nombreVariante, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                            const SizedBox(height: 4),
                                            Text('S/ ${item.variante.precioVenta.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 15)),
                                          ],"""

new_str = """                                            Text(item.producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            Text(item.variante.nombreVariante, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('S/ ${item.variante.precioVenta.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 15)),
                                                if (item.producto.tipoPreparacion == 'anticipado')
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: item.variante.stock > 0 ? Colors.green.shade100 : Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                                    child: Text('Stk: ${item.variante.stock}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item.variante.stock > 0 ? Colors.green.shade800 : Colors.red.shade800)),
                                                  ),
                                              ],
                                            ),
                                          ],"""

text = text.replace(old_str, new_str)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
