/* ENTREGABLE ÚNICO - TALLER CHINOOK (Etapas 1 a 5)
   Autor: Sergio Velasco */


/* =====================================================================
   ETAPA 1: RECONOCIMIENTO DE LA BASE DE DATOS
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
SELECT  'Artist'      AS tabla, COUNT(*) AS registros FROM public."Artist"
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


/* =====================================================================
   ETAPA 2: CONSULTAS BÁSICAS (Ejercicios 1 a 6)
   ===================================================================== */

-- Ejercicio 1: canciones con precio >= 1.00, de la más cara a la más barata
SELECT
    "TrackId",
    "Name",
    "UnitPrice"
FROM public."Track"
WHERE "UnitPrice" >= 1.00
ORDER BY "UnitPrice" DESC;

-- Ejercicio 2: clientes de Brasil, Canadá o Estados Unidos
SELECT
    "FirstName" || ' ' || "LastName" AS nombre_completo,
    "Country"                        AS pais,
    "City"                           AS ciudad,
    "Email"                          AS correo
FROM public."Customer"
WHERE "Country" IN ('Brazil', 'Canada', 'USA')
ORDER BY "Country", "City", nombre_completo;

-- Ejercicio 3: canciones cuyo nombre contiene "love" (ILIKE = LIKE sin distinguir mayúsculas)
SELECT
    "TrackId",
    "Name",
    "Composer",
    "UnitPrice"
FROM public."Track"
WHERE "Name" ILIKE '%love%'
ORDER BY "Name";

-- Ejercicio 4: agregaciones sobre Track en una sola consulta
SELECT
    COUNT(*)                          AS total_canciones,
    ROUND(AVG("UnitPrice"), 2)        AS precio_promedio,
    MIN("UnitPrice")                  AS precio_minimo,
    MAX("UnitPrice")                  AS precio_maximo,
    ROUND(AVG("Milliseconds"), 2)     AS duracion_promedio_ms
FROM public."Track";

-- Ejercicio 5: cantidad de clientes por país
SELECT
    "Country" AS pais,
    COUNT(*)  AS cantidad_clientes
FROM public."Customer"
GROUP BY "Country"
ORDER BY cantidad_clientes DESC, pais;

-- Ejercicio 6: igual al anterior, solo países con al menos 2 clientes (HAVING filtra grupos)
SELECT
    "Country" AS pais,
    COUNT(*)  AS cantidad_clientes
FROM public."Customer"
GROUP BY "Country"
HAVING COUNT(*) >= 2
ORDER BY cantidad_clientes DESC, pais;


/* =====================================================================
   ETAPA 3: CONSULTAS CON JOIN (Ejercicios 7 a 12)
   ===================================================================== */

-- Ejercicio 7: álbumes con el nombre de su artista
SELECT
    ar."Name"  AS artista,
    al."Title" AS album
FROM public."Artist" AS ar
INNER JOIN public."Album" AS al
    ON ar."ArtistId" = al."ArtistId"
ORDER BY ar."Name", al."Title";

-- Ejercicio 8: canción, álbum, artista, precio y duración en minutos
SELECT
    t."Name"                                          AS cancion,
    al."Title"                                        AS album,
    ar."Name"                                         AS artista,
    t."UnitPrice"                                     AS precio,
    ROUND((t."Milliseconds" / 60000.0)::numeric, 2)   AS duracion_minutos
FROM public."Track" AS t
INNER JOIN public."Album" AS al
    ON t."AlbumId" = al."AlbumId"
INNER JOIN public."Artist" AS ar
    ON al."ArtistId" = ar."ArtistId"
ORDER BY ar."Name", al."Title", t."Name";

-- Ejercicio 9: facturas con datos del cliente, desde la más reciente
SELECT
    i."InvoiceId"                          AS numero_factura,
    c."FirstName" || ' ' || c."LastName"   AS nombre_completo,
    c."Country"                            AS pais,
    i."InvoiceDate"                        AS fecha,
    i."Total"                              AS total
FROM public."Invoice" AS i
INNER JOIN public."Customer" AS c
    ON i."CustomerId" = c."CustomerId"
ORDER BY i."InvoiceDate" DESC, i."InvoiceId" DESC;

-- Ejercicio 10: detalle de ventas (Customer -> Invoice -> InvoiceLine -> Track)
SELECT
    c."FirstName" || ' ' || c."LastName"   AS cliente,
    i."InvoiceId"                          AS numero_factura,
    t."Name"                               AS cancion,
    il."UnitPrice"                         AS precio_unitario,
    il."Quantity"                          AS cantidad,
    il."UnitPrice" * il."Quantity"         AS subtotal
FROM public."Customer" AS c
INNER JOIN public."Invoice" AS i
    ON c."CustomerId" = i."CustomerId"
INNER JOIN public."InvoiceLine" AS il
    ON i."InvoiceId" = il."InvoiceId"
INNER JOIN public."Track" AS t
    ON il."TrackId" = t."TrackId"
ORDER BY i."InvoiceId", t."Name";

-- Ejercicio 11: ventas por país de facturación
SELECT
    i."BillingCountry"   AS pais_facturacion,
    COUNT(*)             AS cantidad_facturas,
    SUM(i."Total")       AS total_vendido
FROM public."Invoice" AS i
GROUP BY i."BillingCountry"
ORDER BY total_vendido DESC;

-- Ejercicio 12: top 5 artistas por ingresos (Artist -> Album -> Track -> InvoiceLine)
SELECT
    ar."Name"                               AS artista,
    SUM(il."Quantity")                      AS unidades_vendidas,
    SUM(il."UnitPrice" * il."Quantity")     AS ingresos
FROM public."Artist" AS ar
INNER JOIN public."Album" AS al
    ON ar."ArtistId" = al."ArtistId"
INNER JOIN public."Track" AS t
    ON al."AlbumId" = t."AlbumId"
INNER JOIN public."InvoiceLine" AS il
    ON t."TrackId" = il."TrackId"
GROUP BY ar."ArtistId", ar."Name"
ORDER BY ingresos DESC
LIMIT 5;


/* =====================================================================
   ETAPA 4: ANÁLISIS Y OPTIMIZACIÓN (Ejercicios 13 a 16)
   Ejecutar por bloques y anotar los valores reales donde dice ____.
   ===================================================================== */

-- Punto de partida limpio: que el "antes" sea realmente sin índices
DROP INDEX IF EXISTS public.idx_track_composer;
DROP INDEX IF EXISTS public.idx_track_genre_price;
ANALYZE public."Track";

-- Índices existentes en Track (claves primaria y foráneas)
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename  = 'Track';

-- Ejemplo de lectura de plan
EXPLAIN ANALYZE
SELECT *
FROM public."Customer"
WHERE "Country" = 'Brazil';


/* EJERCICIO 13: plan inicial, sin índice sobre Composer */
EXPLAIN ANALYZE
SELECT
    "TrackId",
    "Name",
    "Composer"
FROM public."Track"
WHERE "Composer" = 'Steve Harris';

/* Resultado antes del índice
   Tipo de recorrido:        Seq Scan on "Track"
   Filas estimadas:          ____
   Filas reales:             ____
   Costo estimado:           0.00..____
   Tiempo de planificación:  ____ ms
   Tiempo de ejecución:      ____ ms */


/* EJERCICIO 14: crear y evaluar un índice */
CREATE INDEX idx_track_composer
    ON public."Track" ("Composer");

ANALYZE public."Track";

EXPLAIN ANALYZE
SELECT
    "TrackId",
    "Name",
    "Composer"
FROM public."Track"
WHERE "Composer" = 'Steve Harris';

/* Resultado después del índice
   Tipo de recorrido:        ____ (Bitmap/Index Scan on idx_track_composer)
   Filas estimadas:          ____
   Filas reales:             ____
   Costo estimado:           ____
   Tiempo de planificación:  ____ ms
   Tiempo de ejecución:      ____ ms

   5. ¿Cambió el plan? Sí: pasa de Seq Scan a un recorrido por el índice,
      porque el filtro es selectivo (pocas filas coinciden).
   6. Index Scan o Bitmap Index Scan: anota el que aparezca en tu plan.
   7. Costo y tiempo bajan porque ya no se leen todas las páginas de la tabla.
   8. PostgreSQL puede seguir usando Seq Scan si la tabla es pequeña, si el
      filtro devuelve muchas filas, o si no se ejecutó ANALYZE. */


/* EJERCICIO 15: índice compuesto */

-- Antes del índice
EXPLAIN ANALYZE
SELECT
    "TrackId",
    "Name",
    "UnitPrice"
FROM public."Track"
WHERE "GenreId" = 1
  AND "UnitPrice" = 0.99;

CREATE INDEX idx_track_genre_price
    ON public."Track" ("GenreId", "UnitPrice");

ANALYZE public."Track";

-- Después del índice
EXPLAIN ANALYZE
SELECT
    "TrackId",
    "Name",
    "UnitPrice"
FROM public."Track"
WHERE "GenreId" = 1
  AND "UnitPrice" = 0.99;

/* Métrica              Antes        Después
   Tipo de recorrido     ____         ____
   Costo estimado        ____         ____
   Filas reales          ____         ____
   Tiempo de ejecución   ____ ms      ____ ms

   9.  Orden de columnas del índice: "GenreId" primero, "UnitPrice" después.
   10. Un índice compuesto resuelve varias condiciones del WHERE en un
       solo recorrido, en vez de combinar índices separados.
   11. Filtrar solo por GenreId sí puede usar el índice (es la columna
       inicial / prefijo izquierdo).
   12. Filtrar solo por UnitPrice no aprovecha el índice, porque no es la
       primera columna; para eso se necesita un índice donde UnitPrice
       vaya primero. */


/* EJERCICIO 16: seleccionar solo lo necesario */

/* Versión A */
EXPLAIN ANALYZE
SELECT *
FROM public."Track"
WHERE "Milliseconds" > 300000;

/* Versión B */
EXPLAIN ANALYZE
SELECT "TrackId", "Name", "Milliseconds"
FROM public."Track"
WHERE "Milliseconds" > 300000;

-- Mismas filas, distinto "width" (bytes por fila) en el plan
SELECT COUNT(*) AS filas_retornadas
FROM public."Track"
WHERE "Milliseconds" > 300000;

/* 13. Mismas filas en A y B (el WHERE es idéntico).
   14. No la misma cantidad de información: A trae todas las columnas de
       Track, B solo 3.
   15. Evitar SELECT * porque transfiere datos que no se usan, impide un
       Index Only Scan y hace el código frágil ante cambios de esquema.
   16. Seleccionar solo columnas mejora el rendimiento con tablas anchas,
       muchas filas, o cuando un índice puede cubrir la consulta. */


/* =====================================================================
   ETAPA 5: RETO FINAL
   Informe de géneros musicales con mejor desempeño.
   ===================================================================== */

-- Genre -> Track -> InvoiceLine, con COUNT/SUM/AVG, GROUP BY género,
-- HAVING > 50 unidades, orden por ingresos, top 5.
SELECT
    g."Name"                                   AS genero,
    COUNT(DISTINCT t."TrackId")                AS canciones_distintas_vendidas,
    SUM(il."Quantity")                         AS unidades_vendidas,
    SUM(il."UnitPrice" * il."Quantity")        AS ingresos,
    ROUND(AVG(il."UnitPrice"), 2)              AS precio_promedio_venta
FROM public."Genre" AS g
INNER JOIN public."Track" AS t
    ON g."GenreId" = t."GenreId"
INNER JOIN public."InvoiceLine" AS il
    ON t."TrackId" = il."TrackId"
GROUP BY g."GenreId", g."Name"
HAVING SUM(il."Quantity") > 50
ORDER BY ingresos DESC
LIMIT 5;

-- Análisis del plan de la misma consulta
EXPLAIN ANALYZE
SELECT
    g."Name"                                   AS genero,
    COUNT(DISTINCT t."TrackId")                AS canciones_distintas_vendidas,
    SUM(il."Quantity")                         AS unidades_vendidas,
    SUM(il."UnitPrice" * il."Quantity")        AS ingresos,
    ROUND(AVG(il."UnitPrice"), 2)              AS precio_promedio_venta
FROM public."Genre" AS g
INNER JOIN public."Track" AS t
    ON g."GenreId" = t."GenreId"
INNER JOIN public."InvoiceLine" AS il
    ON t."TrackId" = il."TrackId"
GROUP BY g."GenreId", g."Name"
HAVING SUM(il."Quantity") > 50
ORDER BY ingresos DESC
LIMIT 5;

/* CONCLUSIÓN TÉCNICA (completar con los nodos y números reales del plan)
   17. Operación con mayor costo: ____ (normalmente el Hash Join entre
       InvoiceLine y Track, o el Sort/Aggregate por el COUNT DISTINCT).
   18. Índices usados: ____ (lo típico es ninguno; al leerse casi toda
       InvoiceLine, PostgreSQL prefiere Seq Scan + Hash Join).
   19. Índice adicional propuesto:
       CREATE INDEX idx_invoiceline_track_qty_price
           ON public."InvoiceLine" ("TrackId")
           INCLUDE ("Quantity", "UnitPrice");
       Beneficiaría consultas que filtran ventas de pocas canciones
       (Index Only Scan). Costo: espacio en disco y escrituras más lentas
       en InvoiceLine, tabla que crece con cada venta. */


/* =====================================================================
   ANEXO: LIMPIEZA DE ÍNDICES
   ===================================================================== */
DROP INDEX IF EXISTS public.idx_track_composer;
DROP INDEX IF EXISTS public.idx_track_genre_price;
ANALYZE public."Track";
