/* =====================================================================
   TALLER CHINOOK - ETAPA 1: RECONOCIMIENTO DE LA BASE DE DATOS
   Autor: Sergio Velasco
   ===================================================================== */

-- Actividad 1: primeras 10 filas de cada tabla
SELECT * FROM public."Artist"      LIMIT 10;
SELECT * FROM public."Album"       LIMIT 10;
SELECT * FROM public."Track"       LIMIT 10;
SELECT * FROM public."Customer"    LIMIT 10;
SELECT * FROM public."Invoice"     LIMIT 10;
SELECT * FROM public."InvoiceLine" LIMIT 10;

-- Actividad 2: conteo de registros por tabla
SELECT COUNT(*) AS cantidad_artistas       FROM public."Artist";
SELECT COUNT(*) AS cantidad_albumes        FROM public."Album";
SELECT COUNT(*) AS cantidad_canciones      FROM public."Track";
SELECT COUNT(*) AS cantidad_clientes       FROM public."Customer";
SELECT COUNT(*) AS cantidad_facturas       FROM public."Invoice";
SELECT COUNT(*) AS cantidad_lineas_factura FROM public."InvoiceLine";

-- Mismo conteo en una sola consulta, para comparar de un vistazo
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

/* PREGUNTAS DE RECONOCIMIENTO
   1. Tabla con más registros: Track.
   2. Columna que relaciona Album con Artist: "ArtistId".
   3. Tablas para ver canciones compradas en una factura:
      Invoice -> InvoiceLine (por "InvoiceId") -> Track (por "TrackId").
   4. Invoice = encabezado de la factura (una fila por compra).
      InvoiceLine = detalle (una fila por canción incluida en la factura). */
