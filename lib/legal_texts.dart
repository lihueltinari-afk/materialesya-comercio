// Textos legales (Términos y Condiciones + Política de Privacidad) para el rol Comercio.
// No modificar el contenido: son los textos provistos por el dueño del proyecto.
const String terminosComercio = '''
1. Objeto: el comercio se registra como vendedor independiente en la plataforma MaterialesYa para ofrecer sus productos a través de la app.

2. Veracidad de la información: el comercio es responsable de la exactitud de los precios, stock, descripciones e imágenes de los productos que publica, así como de sus horarios de atención.

3. Comisión: MaterialesYa cobrará una comisión sobre cada venta realizada a través de la plataforma, según el porcentaje vigente informado en el panel del comercio, descontada automáticamente al momento de la liquidación.

4. Liquidación de pagos: los montos correspondientes a las ventas se transferirán al comercio según la frecuencia de liquidación establecida (diaria o semanal), a la cuenta bancaria/CBU informada por el comercio.

5. Obligación de cumplimiento: el comercio se compromete a aceptar o rechazar los pedidos dentro del tiempo establecido (5 minutos) y a preparar correctamente los pedidos aceptados.

6. Stock: el comercio es responsable de mantener actualizado su stock disponible para evitar la venta de productos inexistentes.

7. Suspensión de cuenta: MaterialesYa podrá suspender temporal o definitivamente la cuenta de un comercio ante reiterados reclamos no resueltos, baja calificación sostenida, o incumplimiento de estos términos.

8. Facturación: el comercio es responsable de cumplir con sus propias obligaciones impositivas y de facturación ante las ventas realizadas a través de la plataforma.

9. Independencia: el comercio actúa como contratante independiente, sin relación de dependencia laboral con MaterialesYa.
''';

const String politicaPrivacidad = '''
1. Datos que recopilamos: nombre, email, teléfono, dirección, ubicación GPS (mientras la app está en uso, y de forma continua para repartidores en servicio activo), datos de pago procesados a través de Mercado Pago (MaterialesYa no almacena números de tarjeta), historial de pedidos, calificaciones.

2. Finalidad: los datos se utilizan para operar el servicio (procesar pedidos, calcular envíos, asignar repartidores, procesar pagos), mejorar la plataforma, y comunicarnos con el usuario sobre el estado de sus pedidos.

3. Compartir información: compartimos los datos estrictamente necesarios entre las partes de una misma transacción (ej: el comercio ve la dirección del cliente que le compró; el repartidor ve los datos de contacto necesarios para realizar la entrega). No vendemos datos personales a terceros.

4. Ubicación: la app solicita acceso a la ubicación para mostrar comercios cercanos (clientes), calcular rutas y tiempos de entrega (repartidores), y verificar zonas de cobertura (comercios). El usuario puede revocar este permiso desde la configuración de su dispositivo, aunque esto puede limitar funcionalidades de la app.

5. Seguridad: implementamos medidas razonables para proteger los datos almacenados, aunque ningún sistema es 100% infalible.

6. Derechos del usuario: el usuario puede solicitar acceso, corrección o eliminación de sus datos personales, así como la baja de su cuenta, escribiendo a través del canal de soporte de la app.

7. Retención de datos: conservamos los datos mientras la cuenta esté activa y por el tiempo adicional necesario para cumplir obligaciones legales o impositivas.

8. Menores de edad: la plataforma está destinada a mayores de 18 años.

9. Cambios en esta política: cualquier modificación será notificada a través de la app.
''';

// ---------------------------------------------------------------------------
// Versiones vigentes de los documentos que requieren aceptación explícita.
// Subir el número cuando se actualice el texto correspondiente (se guarda en la
// base al registrarse, junto con la fecha y la IP).
const String kTcVersion = '1.0';
const String kPrivacidadVersion = '1.0';
const String kComisionesVersion = '1.0';

// ---------------------------------------------------------------------------
// DOCUMENTOS ADICIONALES
const String politicaCookies = '''
POLÍTICA DE COOKIES — MaterialesYa
Última actualización: julio de 2025

MaterialesYa utiliza tecnologías de almacenamiento local (cookies y equivalentes) para que la app funcione correctamente y para mejorar tu experiencia. A continuación te explicamos qué almacenamos y por qué.

1. ¿QUÉ SON LAS COOKIES?
Son pequeños archivos de texto o registros de datos que se guardan en tu dispositivo cuando usás la app o el sitio web de MaterialesYa. Nos permiten recordar tu sesión iniciada, tus preferencias y ciertos datos de uso.

2. TIPOS DE ALMACENAMIENTO QUE USAMOS

a) Almacenamiento técnico esencial: necesario para que la app funcione. Incluye el token de autenticación que mantiene tu sesión iniciada, preferencias de configuración del panel, y datos temporales de operación. No podés desactivarlo sin afectar el funcionamiento de la app.

b) Almacenamiento de sesión: datos que se borran cuando cerrás la app. Se usan para recordar el estado de acciones en curso (edición de productos, carga de precios).

c) Almacenamiento analítico y de rendimiento: usamos datos anonimizados para entender cómo se usa la app y poder mejorarla. Estos datos no te identifican personalmente.

d) Notificaciones push: si aceptás las notificaciones, guardamos un identificador de dispositivo (FCM token) para enviarte alertas sobre nuevos pedidos y actualizaciones de estado.

3. DATOS QUE NO ALMACENAMOS LOCALMENTE
No guardamos en tu dispositivo datos bancarios ni contraseñas en texto plano. Las liquidaciones son procesadas por Mercado Pago.

4. CÓMO GESTIONAR EL ALMACENAMIENTO
Podés eliminar los datos locales de la app desde Configuración → Aplicaciones → MaterialesYa → Borrar datos. Esto cerrará tu sesión y podrías perder preferencias guardadas.

5. CAMBIOS EN ESTA POLÍTICA
Cualquier modificación relevante será notificada a través de la app. El uso continuado implica la aceptación de la política actualizada.

6. CONTACTO
Para consultas sobre privacidad o cookies, escribinos a través del canal de soporte disponible en la app.
''';

const String politicaCancelaciones = '''
POLÍTICA DE CANCELACIONES — MaterialesYa (Panel Comercio)
Última actualización: julio de 2025

1. RECHAZO DE PEDIDOS POR EL COMERCIO
El comercio tiene 5 minutos para aceptar o rechazar cada pedido entrante. Si no responde en ese plazo, el pedido se cancela automáticamente sin cargo para el comercio, pero una tasa alta de vencimientos puede afectar la visibilidad del comercio en la plataforma.

El comercio puede rechazar un pedido por: falta de stock, cierre imprevisto, u otras causas justificadas. En todos los casos el reembolso al cliente es total y automático.

2. CANCELACIÓN POR EL CLIENTE
El cliente puede cancelar sin costo para el comercio en los estados "Pendiente" o "En preparación". Si el comercio ya incurrió en costos de preparación puede indicarlo; MaterialesYa evaluará el caso y podrá retener hasta un 20 % del valor como compensación, que se acreditará al comercio.

3. PEDIDOS CON ENTREGA PROGRAMADA
Si el cliente cancela un pedido programado con menos de 2 horas de anticipación, el comercio puede solicitar una compensación a través del canal de soporte. MaterialesYa evaluará cada caso.

4. RECLAMOS DE CLIENTES POST-ENTREGA
El cliente tiene 24 horas para reportar disconformidades (artículo incorrecto, faltante, daño). El comercio será notificado y tendrá 48 horas para responder. MaterialesYa puede mediar y resolver la disputa, pudiendo retener fondos de la liquidación para cubrir reembolsos validados.

5. IMPACTO EN LIQUIDACIONES
Las cancelaciones aceptadas y los reembolsos validados por reclamos se descuentan de la liquidación del período correspondiente.

6. MODIFICACIONES
MaterialesYa notificará cualquier cambio a través de la app con al menos 15 días de anticipación.
''';

const String codigoConducta = '''
CÓDIGO DE CONDUCTA — MaterialesYa
Última actualización: julio de 2025

MaterialesYa es una comunidad formada por clientes, comercios y repartidores. Para que la experiencia sea buena para todos, pedimos que se respeten las siguientes normas.

1. RESPETO ENTRE USUARIOS
Todos los participantes deben tratarse con respeto y cortesía. No se toleran insultos, amenazas, discriminación por ninguna causa ni acoso de ningún tipo.

2. INFORMACIÓN VERAZ
Publicá precios, stock y descripciones reales y actualizadas. La publicación de información engañosa (precios incorrectos, fotos de otros productos, stocks inflados) está prohibida y puede derivar en la baja de la cuenta y responsabilidad frente a los clientes afectados.

3. CUMPLIMIENTO FISCAL
El comercio es responsable de emitir las facturas o comprobantes que correspondan según su actividad y de cumplir sus obligaciones ante AFIP y la ARBA (o el organismo tributario provincial que corresponda). MaterialesYa no actúa como agente de retención impositiva salvo en los casos establecidos por la normativa vigente.

4. USO HONESTO DE LA PLATAFORMA
No está permitido manipular calificaciones, crear cuentas falsas, acordar precios con otros comercios de manera anticompetitiva, ni intentar eludir las comisiones u otros mecanismos establecidos.

5. RECLAMOS Y CONFLICTOS
Los desacuerdos deben canalizarse a través de los mecanismos de reclamo disponibles en la app. MaterialesYa se reserva el derecho de mediar y tomar decisiones vinculantes sobre disputas entre partes.

6. CONSECUENCIAS DEL INCUMPLIMIENTO
El incumplimiento puede derivar en advertencias, suspensión temporal o baja definitiva de la cuenta, según la gravedad y reiteración de la conducta. En casos de fraude confirmado, MaterialesYa puede iniciar acciones legales.

7. MODIFICACIONES
MaterialesYa puede actualizar este código notificando a los comercios a través de la app.
''';

const String politicaComisiones = '''
POLÍTICA DE COMISIONES — MaterialesYa
Última actualización: julio de 2025
Versión vigente: 1.0

1. COMISIÓN DE LA PLATAFORMA
MaterialesYa cobra una comisión del 8 % (ocho por ciento) sobre el valor total de cada pedido gestionado a través de la plataforma, excluido el costo de envío. Esta comisión cubre el acceso a la tecnología, la gestión de pagos, el soporte y la visibilidad en la app.

Ejemplo: pedido con productos por \$ 10.000 → comisión MaterialesYa = \$ 800.

2. BASE DE CÁLCULO
La comisión se aplica sobre el subtotal de productos (precio de lista publicado por el comercio × cantidad), sin incluir el costo de envío ni impuestos adicionales.

3. MECANISMO DE COBRO
La comisión se descuenta automáticamente en el momento de la liquidación. MaterialesYa opera como marketplace a través de Mercado Pago: al realizarse el pago, el monto de la comisión se retiene directamente y el saldo neto se transfiere al comercio.

4. LIQUIDACIÓN
Las liquidaciones se realizan según la frecuencia configurada en el panel del comercio (diaria o semanal), a la cuenta bancaria / CBU / CVU informada. Las transferencias pueden demorar entre 1 y 3 días hábiles adicionales dependiendo de la entidad bancaria.

5. PEDIDOS CANCELADOS
No se cobra comisión sobre pedidos que el comercio rechazó o que se cancelaron antes de que el repartidor retirara la mercadería. Si el reembolso al cliente ocurre después del cobro, la comisión se devuelve en la liquidación siguiente.

6. ACTUALIZACIONES DE COMISIÓN
MaterialesYa podrá revisar el porcentaje de comisión notificando a los comercios activos con al menos 30 días de anticipación a través de la app y por email. La operación continuada en la plataforma luego del vencimiento del plazo implica la aceptación del nuevo porcentaje.

7. CONSULTAS
Para consultas sobre liquidaciones o comisiones, utilizá el canal de soporte disponible en la app o escribinos a soporte@materialesya.com.ar.
''';
