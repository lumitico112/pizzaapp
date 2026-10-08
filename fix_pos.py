import sys

path = 'C:/D/ProyectoPizza/pizzaapp/lib/screens/pos/pos_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# For the grid view image:
# child: item.producto.fotoRuta != null 
#   ? Image.file(File(item.producto.fotoRuta!), fit: BoxFit.cover)
#   : Container(...)

old_img = """child: item.producto.fotoRuta != null 
                                            ? Image.file(File(item.producto.fotoRuta!), fit: BoxFit.cover)
                                            : Container(color: AppColors.background, child: const Icon(Icons.fastfood, size: 40, color: AppColors.primary)),"""

new_img = """child: (item.variante.imagen != null) 
                                            ? Image.file(File(item.variante.imagen!), fit: BoxFit.cover)
                                            : (item.producto.fotoRuta != null 
                                              ? Image.file(File(item.producto.fotoRuta!), fit: BoxFit.cover)
                                              : Container(color: AppColors.background, child: const Icon(Icons.fastfood, size: 40, color: AppColors.primary))),"""

text = text.replace(old_img, new_img)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
