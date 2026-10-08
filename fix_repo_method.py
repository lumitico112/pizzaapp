import sys

path1 = 'C:/D/ProyectoPizza/pizzaapp/lib/services/auth_service.dart'
with open(path1, 'r', encoding='utf-8') as f:
    text1 = f.read()
text1 = text1.replace("_repository.insertUser(admin);", "_repository.createUsuario(admin);")
with open(path1, 'w', encoding='utf-8') as f:
    f.write(text1)

path2 = 'C:/D/ProyectoPizza/pizzaapp/lib/services/usuario_service.dart'
with open(path2, 'r', encoding='utf-8') as f:
    text2 = f.read()
text2 = text2.replace("_repository.insertUser(newUser);", "_repository.createUsuario(newUser);")
with open(path2, 'w', encoding='utf-8') as f:
    f.write(text2)
