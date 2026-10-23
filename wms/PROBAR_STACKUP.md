# StackUp Prueba · versión reversible

## Ejecutar

Desde la carpeta del proyecto:

```powershell
flutter devices
flutter run -d ID_DEL_DISPOSITIVO
```

Se instala como **StackUp Prueba** (`com.stackup.prototype.trial`). Puede coexistir con StackUp Prototipo. Usa una base SQLite distinta y comienza con datos ficticios; configura un PIN nuevo. Los datos de la app anterior no se modifican.

## Cambios para evaluar

- Trabajador: entra directamente a Rutas; sin Inicio, Consultas globales ni barra inferior. Puede elegir cualquier vehículo.
- Dentro del vehículo: búsqueda solo entre sus pedidos y ubicaciones visibles en las tarjetas.
- Administrador: conserva Inicio, Consultas, Rutas y Admin. Se eliminó Buscar consejera del inicio y el apartado independiente Diferencias y revisión.
- Nueva campaña sustituye a Nueva recepción.
- Consultas: cantidades con indicadores gris (recibidas pendientes), amarillo (revisión) y verde (verificadas). Sin recibir se muestra aparte.
- Revisión es una referencia de ubicación y aviso; no bloquea el cuadre. Con etiquetas idénticas no puede saberse qué caja concreta se retiró: el aviso amarillo se conserva de manera conservadora mientras queden cantidades suficientes pendientes y desaparece al completar el pedido. Las ubicaciones continúan siendo las de recepción.
- Zonas generales: máximo 15 cajas entre ambos lotes. Al aceptar la caja 15, el campo pasa a esperar el código de otra zona. Se permite cambiar de zona antes de llenarla. Una zona llena se rechaza.
- ES-19, ES-22 y REVISION no tienen ese límite.
- Pistola en modo teclado/HID con sufijo Enter: cada lectura se registra sin pulsar botones. Las lecturas se procesan en orden aunque una escritura anterior siga pendiente.
- Sin lista de lecturas en captura: solo zona, contador y última respuesta. El menú de tres puntos permite deshacer, elegir zona manualmente o simular una lectura.

## Prueba rápida

1. Configura el PIN. La demo incluye 350 cajas, 100 pedidos y 10 vehículos. Si ya tenías instalada la prueba, se conservan tus datos: entra en Admin → Demo recibida: probar rutas y cuadre y acepta cargar la nueva demostración. La campaña anterior se archiva localmente.
2. Cambia a Trabajador: abre CAM105 y busca una consejera. Cuadra usando un lector o el menú de tres puntos → Simular una lectura.
3. Para probar recepción, entra como Admin → Demo desde cero. Abre Registrar cajas.
4. En el campo escribe `Z:A-01` y pulsa Enter; luego lee códigos `consejeraFguía`. El menú de simulación permite elegir códigos sin lector.
5. Al llegar a 15 se solicita otra zona. ES-19, ES-22 o REVISION permiten más de 15.

El escaneo con cámara sigue disponible como alternativa de una lectura por apertura. El flujo sin pulsaciones por caja corresponde a la pistola con Enter. El formato de etiqueta real y la compatibilidad física de la pistola siguen pendientes de validación.

## Excel y datos

Importar XLSX por lote: NUMERO GUIA, VEHICULO, CANTIDAD, IDENTIFICADOR CONTACTO y CAMPAÑA son obligatorios; NOMBRE CONTACTO es opcional. CAMPAÑA contiene 16-19 o 16-22. Una fila representa un pedido y CANTIDAD sus cajas. No se puede reemplazar un lote con escaneos sin abrir otra campaña.

Un vehículo solo puede tener pedidos de un lote dentro de la campaña. Si el segundo Excel asigna ese mismo vehículo al otro lote, se rechaza la importación completa con un aviso. No hay un catálogo que restrinja qué vehículo corresponde a cada lote: en otra campaña puede cambiar.

La demo usa 210 cajas del lote 19 y 140 del lote 22. A-01 a A-14 contienen cajas normales del lote 19; A-15 a A-24, del lote 22. Además hay 6 cajas en ES-19, 4 en ES-22 y 1 en REVISION, ya incluidas en los totales. Cada zona general tiene como máximo 15 cajas. Esta distribución es solo el ejemplo: las zonas generales siguen admitiendo ambos lotes para registrar la ubicación real de una caja mal acomodada. Hay pedidos repartidos entre varias ubicaciones.

Se conserva Flutter y la carpeta ios para la futura prueba en Mac. Esta entrega se valida en Android; todavía no se ha compilado ni probado en el simulador de iOS.

Esta prueba es local: todavía no incluye sincronización por Wi-Fi, autenticación de servidor ni confirmación de despacho/devoluciones. Las etiquetas iguales no permiten detectar que una misma caja física se escaneó dos veces dentro de la cantidad esperada.

## Volver a la versión anterior

Antes de ampliar la demo el 22 de octubre se guardaron los seis archivos modificados en `C:\Users\ozoca\Documents\ChatGPT\Bodega\snapshots\stackup-antes-demo350-20261022`, conservando su estructura de carpetas. Para volver únicamente a la demo pequeña se pueden copiar esos archivos sobre los del proyecto con la app detenida; no restaura los datos del teléfono. El script de abajo protege la versión del 20 de octubre y se detendrá ante estos nuevos cambios; no debe forzarse.

Copia anterior, guardada antes de modificar el proyecto:

`C:\Users\ozoca\Documents\ChatGPT\Bodega\snapshots\stackup-antes-limpieza-20261020\proyecto.zip`

Para revisar qué restauraría el script, sin modificar nada:

```powershell
& 'C:\Users\ozoca\Documents\ChatGPT\Bodega\snapshots\stackup-antes-limpieza-20261020\restaurar-anterior.ps1'
```

Para restaurar los archivos cambiados en esta prueba:

```powershell
& 'C:\Users\ozoca\Documents\ChatGPT\Bodega\snapshots\stackup-antes-limpieza-20261020\restaurar-anterior.ps1' -Aplicar
```

Detén `flutter run` antes. El script guarda otra copia de los archivos de prueba antes de restaurar y se detiene si detecta cambios posteriores a esta entrega. No modifica Git ni datos del teléfono. Después ejecuta de nuevo `flutter run`: volverá a abrir StackUp Prototipo con su base anterior.

## Verificar

```powershell
flutter test --no-pub
flutter analyze --no-pub lib/stackup lib/main.dart test
```
