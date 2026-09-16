/* =====================================================================
   TALLER CHINOOK - ETAPA 1: RECONOCIMIENTO DE LA BASE DE DATOS
   Autor: Michael Santos
   Motor: PostgreSQL (pgAdmin Query Tool)
   ===================================================================== */

-- ---------------------------------------------------------------------
-- Actividad 1: Explorar las tablas (primeras 10 filas de cada una)
-- ---------------------------------------------------------------------
SELECT * FROM public."Artist"      LIMIT 10;
SELECT * FROM public."Album"       LIMIT 10;
SELECT * FROM public."Track"       LIMIT 10;
SELECT * FROM public."Customer"    LIMIT 10;
SELECT * FROM public."Invoice"     LIMIT 10;
SELECT * FROM public."InvoiceLine" LIMIT 10;

-- ---------------------------------------------------------------------
-- Actividad 2: Contar registros
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS cantidad_artistas      FROM public."Artist";
SELECT COUNT(*) AS cantidad_albumes       FROM public."Album";
SELECT COUNT(*) AS cantidad_canciones     FROM public."Track";
SELECT COUNT(*) AS cantidad_clientes      FROM public."Customer";
SELECT COUNT(*) AS cantidad_facturas      FROM public."Invoice";
SELECT COUNT(*) AS cantidad_lineas_factura FROM public."InvoiceLine";

-- Versión en una sola consulta (útil para comparar de un vistazo)
SELECT 'Artist'      AS tabla, COUNT(*) AS registros FROM public."Artist"
UNION ALL
SELECT 'Album',       COUNT(*) FROM public."Album"
UNION ALL
SELECT 'Track',       COUNT(*) FROM public."Track"
UNION ALL
SELECT 'Customer',    COUNT(*) FROM public."Customer"
UNION ALL
SELECT 'Invoice',     COUNT(*) FROM public."Invoice"
UNION ALL
SELECT 'InvoiceLine', COUNT(*) FROM public."InvoiceLine"
ORDER BY registros DESC;

/* ---------------------------------------------------------------------
   PREGUNTAS DE RECONOCIMIENTO
   (Valores de la versión estándar de Chinook; confírmalos con tus conteos)
   ---------------------------------------------------------------------
   1. ¿Cuál es la tabla con más registros?
      Track, con 3503 filas en la versión estándar de Chinook
      (InvoiceLine le sigue con 2240, Invoice 412, Album 347,
      Artist 275, Customer 59).

   2. ¿Qué columna relaciona Album con Artist?
      "ArtistId": es clave primaria en Artist y clave foránea en Album.

   3. ¿Qué tablas permiten conocer las canciones compradas en una factura?
      Invoice -> InvoiceLine (por "InvoiceId") -> Track (por "TrackId").
      Si además se quiere saber quién compró, se agrega Customer
      (Invoice."CustomerId").

   4. ¿Cuál es la diferencia entre Invoice e InvoiceLine?
      Invoice es el encabezado de la factura: una fila por compra, con
      cliente, fecha, dirección de facturación y total.
      InvoiceLine es el detalle: una fila por cada canción incluida en
      la factura, con su precio unitario y cantidad. Una factura tiene
      muchas líneas (relación 1:N).
   --------------------------------------------------------------------- */
