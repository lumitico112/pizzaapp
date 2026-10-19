# Recuperación de contraseña

La aplicación funciona sin cuentas en línea ni un servidor de correo. Por eso la recuperación no simula el envío de un código por email: utiliza una clave de rescate local.

## Configuración

- Al crear el administrador, la app genera una clave aleatoria y la muestra una sola vez. La dueña debe anotarla y guardarla fuera del teléfono.
- La base de datos guarda únicamente el hash de la clave, no el texto que se muestra.
- Para una instalación que ya existía antes de esta función, inicia sesión, abre el perfil y elige **Configurar recuperación**. Si ya había una clave, la opción permite renovarla; la clave anterior deja de servir.

## Restablecer la contraseña

En la pantalla de inicio de sesión, abre **¿Olvidaste tu contraseña?** y escribe el usuario administrador, la clave de rescate y una contraseña nueva de al menos ocho caracteres. La clave se puede escribir con o sin guiones y no distingue mayúsculas de minúsculas.

La clave de rescate no se envía ni se puede recuperar desde la app. Si la dueña sigue con una sesión abierta, puede renovar la clave desde su perfil. Si perdió tanto la contraseña como la clave de rescate, no existe una identidad externa que permita demostrar que es la propietaria: debe conservar la clave en un lugar seguro y separado del teléfono.

La clave de rescate se incluye en la base local cifrada y en las copias de seguridad, pero las copias no revelan el texto de la clave. La contraseña de una copia portátil es independiente de la contraseña de acceso de la aplicación.
