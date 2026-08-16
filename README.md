# CONVOKI · versión RSVP

Esta versión agrega invitaciones por WhatsApp con:

- texto personalizado;
- link único por invitado para aceptar o rechazar;
- link para agregar el evento a Google Calendar;
- actualización automática del estado en el panel del organizador;
- sincronización de respuestas mediante Supabase.

## Activación de la sincronización

1. Crea un proyecto en Supabase.
2. Abre SQL Editor y ejecuta `supabase.sql`.
3. Copia la Project URL y la anon/publishable key.
4. Pégalas en `config.js`.
5. En `PUBLIC_BASE_URL`, escribe la URL pública donde desplegaste CONVOKI, por ejemplo:
   `https://convoki.vercel.app`
6. Publica `index.html`, `rsvp.html` y `config.js` juntos en la misma carpeta.

## Flujo

El organizador agrega una persona y toca WhatsApp. CONVOKI guarda la invitación online y genera un enlace único:

`https://tu-dominio/rsvp.html?token=...`

El invitado abre el enlace, pulsa **Sí, voy** o **No puedo** y el panel del organizador actualiza el estado automáticamente mientras está abierto.

## Seguridad MVP

La tabla queda protegida con Row Level Security y sin acceso directo para `anon`.
Las operaciones públicas se realizan mediante funciones SQL que exponen solamente los datos necesarios.
Para una versión comercial se recomienda sumar autenticación real del organizador, controles antiabuso y políticas más estrictas.

## Mensaje de WhatsApp simplificado

La invitación ahora envía **un solo enlace**: el enlace personal a CONVOKI.

Dentro de esa página el invitado puede:
- aceptar;
- rechazar;
- agregar el evento al calendario.

Esto evita enviar también el enlace largo de Google Calendar.

> Nota: los mensajes normales abiertos mediante `wa.me` no permiten ocultar una URL detrás de texto personalizado. Para mostrar un botón de WhatsApp sin URL visible se requiere WhatsApp Business / Cloud API con un botón CTA.
