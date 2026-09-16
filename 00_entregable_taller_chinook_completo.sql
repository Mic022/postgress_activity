/* ENTREGABLE ÚNICO - TALLER CHINOOK (Etapas 1 a 5) - Michael Santos */


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


/* =====================================================================
   TALLER CHINOOK - ETAPA 2: CONSULTAS BÁSICAS (Ejercicios 1 a 6)
   ===================================================================== */

-- ---------------------------------------------------------------------
-- Ejercicio 1: Filtros y ordenamiento
-- Canciones con precio >= 1.00, de la más costosa a la más barata.
-- ---------------------------------------------------------------------
SELECT
    "TrackId",
    "Name",
    "UnitPrice"
FROM public."Track"
WHERE "UnitPrice" >= 1.00
ORDER BY "UnitPrice" DESC;

-- ---------------------------------------------------------------------
-- Ejercicio 2: Búsqueda de clientes
-- Clientes de Brasil, Canadá o Estados Unidos usando IN.
-- En Chinook los países se guardan en inglés: 'Brazil', 'Canada', 'USA'.
-- ---------------------------------------------------------------------
SELECT
    "FirstName" || ' ' || "LastName" AS nombre_completo,
    "Country"                        AS pais,
    "City"                           AS ciudad,
    "Email"                          AS correo
FROM public."Customer"
WHERE "Country" IN ('Brazil', 'Canada', 'USA')
ORDER BY "Country", "City", nombre_completo;

-- ---------------------------------------------------------------------
-- Ejercicio 3: Búsqueda de canciones
-- Nombre que contenga "love" sin distinguir mayúsculas/minúsculas.
-- ILIKE es la versión insensible a mayúsculas de LIKE en PostgreSQL.
-- ---------------------------------------------------------------------
SELECT
    "TrackId",
    "Name",
    "Composer",
    "UnitPrice"
FROM public."Track"
WHERE "Name" ILIKE '%love%'
ORDER BY "Name";

-- ---------------------------------------------------------------------
-- Ejercicio 4: Funciones de agregación en una sola consulta
-- ---------------------------------------------------------------------
SELECT
    COUNT(*)                          AS total_canciones,
    ROUND(AVG("UnitPrice"), 2)        AS precio_promedio,
    MIN("UnitPrice")                  AS precio_minimo,
    MAX("UnitPrice")                  AS precio_maximo,
    ROUND(AVG("Milliseconds"), 2)     AS duracion_promedio_ms
FROM public."Track";

-- ---------------------------------------------------------------------
-- Ejercicio 5: Agrupación
-- Cantidad de clientes por país, del país con más clientes al de menos.
-- ---------------------------------------------------------------------
SELECT
    "Country" AS pais,
    COUNT(*)  AS cantidad_clientes
FROM public."Customer"
GROUP BY "Country"
ORDER BY cantidad_clientes DESC, pais;

-- ---------------------------------------------------------------------
-- Ejercicio 6: Condición sobre agrupaciones
-- Igual al anterior, pero solo países con al menos dos clientes.
-- HAVING filtra grupos (después del GROUP BY); WHERE filtra filas.
-- ---------------------------------------------------------------------
SELECT
    "Country" AS pais,
    COUNT(*)  AS cantidad_clientes
FROM public."Customer"
GROUP BY "Country"
HAVING COUNT(*) >= 2
ORDER BY cantidad_clientes DESC, pais;


/* =====================================================================
   TALLER CHINOOK - ETAPA 3: CONSULTAS CON JOIN (Ejercicios 7 a 12)
   ===================================================================== */

-- ---------------------------------------------------------------------
-- Ejercicio 7: Álbumes y artistas
-- ---------------------------------------------------------------------
SELECT
    ar."Name"  AS artista,
    al."Title" AS album
FROM public."Artist" AS ar
INNER JOIN public."Album" AS al
    ON ar."ArtistId" = al."ArtistId"
ORDER BY ar."Name", al."Title";

-- ---------------------------------------------------------------------
-- Ejercicio 8: Canciones, álbumes y artistas
-- Track -> Album (AlbumId) -> Artist (ArtistId)
-- Se divide entre 60000.0 (decimal) para evitar la división entera.
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- Ejercicio 9: Clientes y facturas
-- Desde la factura más reciente.
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- Ejercicio 10: Detalle completo de ventas
-- Customer -> Invoice -> InvoiceLine -> Track
-- El precio se toma de InvoiceLine (precio al momento de la venta),
-- no de Track (precio actual del catálogo).
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- Ejercicio 11: Ventas por país
-- Se usa el país de facturación (BillingCountry) de la tabla Invoice.
-- Aquí no hace falta JOIN: Invoice ya tiene el país y el total.
-- ---------------------------------------------------------------------
SELECT
    i."BillingCountry"   AS pais_facturacion,
    COUNT(*)             AS cantidad_facturas,
    SUM(i."Total")       AS total_vendido
FROM public."Invoice" AS i
GROUP BY i."BillingCountry"
ORDER BY total_vendido DESC;

-- ---------------------------------------------------------------------
-- Ejercicio 12: Cinco artistas con mayores ventas
-- Artist -> Album -> Track -> InvoiceLine
-- Se agrupa también por ArtistId para no mezclar artistas homónimos.
-- ---------------------------------------------------------------------
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
   TALLER CHINOOK - ETAPA 4: ANÁLISIS Y OPTIMIZACIÓN (Ejercicios 13 a 16)

   IMPORTANTE:
   - Ejecuta este archivo POR BLOQUES, en orden, y copia los resultados
     reales de TU equipo en las tablas de comentarios (donde dice ____).
   - Los tiempos cambian en cada ejecución y en cada equipo; los
     comentarios de "resultado esperado" describen el comportamiento
     típico, no valores exactos.
   ===================================================================== */

-- Punto de partida limpio: asegura que el "antes" sea realmente sin índices
DROP INDEX IF EXISTS public.idx_track_composer;
DROP INDEX IF EXISTS public.idx_track_genre_price;
ANALYZE public."Track";

-- Índices que ya existen en Track (claves primarias y foráneas del script)
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename  = 'Track';

-- ---------------------------------------------------------------------
-- Ejemplo de lectura de plan
-- ---------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT *
FROM public."Customer"
WHERE "Country" = 'Brazil';


/* =====================================================================
   EJERCICIO 13: PLAN INICIAL (sin índice sobre Composer)
   ===================================================================== */
EXPLAIN ANALYZE
SELECT
    "TrackId",
    "Name",
    "Composer"
FROM public."Track"
WHERE "Composer" = 'Steve Harris';

/* Resultado ANTES del índice
   +---------------------------+-----------------------------+
   | Elemento                  | Resultado antes del índice  |
   +---------------------------+-----------------------------+
   | Tipo de recorrido         | Seq Scan on "Track"         |
   | Filas estimadas           | ____                        |
   | Filas reales              | ____                        |
   | Costo estimado            | 0.00..____                  |
   | Tiempo de planificación   | ____ ms                     |
   | Tiempo de ejecución       | ____ ms                     |
   +---------------------------+-----------------------------+
   Resultado esperado: Seq Scan que recorre toda la tabla y descarta
   con el filtro ("Rows Removed by Filter") la gran mayoría de filas.
*/


/* =====================================================================
   EJERCICIO 14: CREAR Y EVALUAR UN ÍNDICE
   ===================================================================== */
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

/* Resultado DESPUÉS del índice
   +---------------------------+-------------------------------------------+
   | Elemento                  | Resultado después del índice              |
   +---------------------------+-------------------------------------------+
   | Tipo de recorrido         | ____ (Bitmap Heap Scan + Bitmap Index Scan|
   |                           |  on idx_track_composer, o Index Scan)     |
   | Filas estimadas           | ____                                      |
   | Filas reales              | ____                                      |
   | Costo estimado            | ____                                      |
   | Tiempo de planificación   | ____ ms                                   |
   | Tiempo de ejecución       | ____ ms                                   |
   +---------------------------+-------------------------------------------+

   ANÁLISIS
   5. ¿Cambió el plan de ejecución?
      Sí, normalmente pasa de Seq Scan a un recorrido que usa
      idx_track_composer, porque 'Steve Harris' corresponde a una fracción
      pequeña de las filas de Track (filtro selectivo).

   6. ¿Utilizó Index Scan o Bitmap Index Scan?
      (Anota lo que viste.) Lo habitual aquí es Bitmap Index Scan +
      Bitmap Heap Scan: el índice encuentra decenas de filas y PostgreSQL
      prefiere marcarlas en un mapa de bits y leer las páginas de la tabla
      en orden físico. Si las filas coincidentes fueran muy pocas, elegiría
      un Index Scan directo.

   7. ¿Se redujeron el costo estimado y el tiempo real?
      El costo estimado baja porque ya no se leen todas las páginas.
      El tiempo de ejecución suele bajar, pero como la tabla es pequeña la
      diferencia es de fracciones de milisegundo y puede variar entre
      ejecuciones (caché). El tiempo de planificación puede subir un poco,
      porque el planificador ahora evalúa más alternativas.

   8. ¿Por qué PostgreSQL podría seguir usando Seq Scan con el índice?
      - La tabla es pequeña (pocas páginas): leerla completa es barato.
      - El filtro devuelve muchas filas (baja selectividad): saltar entre
        índice y tabla cuesta más que un recorrido secuencial.
      - Estadísticas desactualizadas (no se ejecutó ANALYZE).
      - La condición no coincide con el índice (p. ej. usar
        LOWER("Composer") o ILIKE '%...%' sobre un índice B-tree normal).
      El planificador elige por costo estimado; un índice es una opción,
      no una obligación.
*/


/* =====================================================================
   EJERCICIO 15: ÍNDICE COMPUESTO
   ===================================================================== */

-- 15.a) ANTES del índice compuesto
EXPLAIN ANALYZE
SELECT
    "TrackId",
    "Name",
    "UnitPrice"
FROM public."Track"
WHERE "GenreId" = 1
  AND "UnitPrice" = 0.99;

-- 15.b) Crear el índice y actualizar estadísticas
CREATE INDEX idx_track_genre_price
    ON public."Track" ("GenreId", "UnitPrice");

ANALYZE public."Track";

-- 15.c) DESPUÉS del índice compuesto
EXPLAIN ANALYZE
SELECT
    "TrackId",
    "Name",
    "UnitPrice"
FROM public."Track"
WHERE "GenreId" = 1
  AND "UnitPrice" = 0.99;

/* Comparación
   +---------------------+------------------+------------------+
   | Métrica             | Antes            | Después          |
   +---------------------+------------------+------------------+
   | Tipo de recorrido   | ____             | ____             |
   | Costo estimado      | ____             | ____             |
   | Filas reales        | ____             | ____             |
   | Tiempo de ejecución | ____ ms          | ____ ms          |
   +---------------------+------------------+------------------+

   Nota para el análisis: GenreId = 1 es "Rock", el género con más
   canciones de Chinook, y casi todas cuestan 0.99. La consulta devuelve
   una parte grande de la tabla, así que es muy posible que el plan
   "Antes" y "Después" sea el mismo (Seq Scan) o que el cambio sea mínimo.
   Ese resultado NO es un error: demuestra la idea clave del taller.

   PREGUNTAS SOBRE EL ÍNDICE COMPUESTO
   9.  ¿En qué orden están las columnas?
       Primero "GenreId" y después "UnitPrice". El índice está ordenado
       por GenreId y, dentro de cada GenreId, por UnitPrice.

   10. ¿Por qué puede ser útil un índice compuesto?
       Porque resuelve varias condiciones del WHERE con un solo recorrido
       del índice, sin combinar dos índices separados, y también puede
       servir para ORDER BY que siga el mismo orden de columnas.
       Es más útil cuanto más selectiva sea la combinación de filtros.

   11. ¿Ayuda si se filtra únicamente por GenreId?
       Sí. GenreId es la columna inicial (prefijo izquierdo) del índice,
       así que el B-tree puede ubicar directamente las entradas de ese
       género. (Ojo: ya existe un índice de clave foránea sobre GenreId,
       así que el planificador podría preferir ese.)

   12. ¿Sería igual de útil si se filtra solo por UnitPrice?
       No. UnitPrice es la segunda columna; sin una condición sobre
       GenreId los valores de UnitPrice están repartidos dentro de cada
       género, por lo que el índice no permite saltar directamente a
       ellos. PostgreSQL tendría que recorrer todo el índice (o, más
       probablemente, haría un Seq Scan). Para filtrar solo por UnitPrice
       conviene un índice cuya primera columna sea "UnitPrice".
*/


/* =====================================================================
   EJERCICIO 16: SELECCIONAR SOLO LO NECESARIO
   ===================================================================== */

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

-- Comparación objetiva: mismas filas, distinto ancho promedio (width)
SELECT COUNT(*) AS filas_retornadas
FROM public."Track"
WHERE "Milliseconds" > 300000;

/* Compara en los planes el valor "width" (bytes promedio por fila):
   la versión A tiene un width mayor que la versión B.

   13. ¿Retornan las mismas filas?
       Sí. El WHERE es idéntico, así que devuelven exactamente las mismas
       filas (misma cantidad).

   14. ¿Retornan la misma cantidad de información?
       No. La versión A trae las 9 columnas de Track (incluidas Composer,
       Bytes, etc.); la B solo 3. A transfiere más bytes al cliente.

   15. ¿Por qué evitar SELECT *?
       - Transfiere y procesa datos que no se usan (red, memoria, pgAdmin).
       - Impide aprovechar "Index Only Scan" con índices que cubran solo
         las columnas necesarias.
       - Hace el código frágil: si la tabla cambia (se agregan o reordenan
         columnas), el resultado cambia sin aviso.
       - Es menos claro: no documenta qué datos necesita la consulta.

   16. ¿Cuándo mejora el rendimiento seleccionar solo las columnas?
       - Cuando la tabla tiene columnas anchas (textos largos, JSON, BYTEA)
         o se devuelven muchas filas.
       - Cuando hay un índice que contiene todas las columnas pedidas y se
         puede hacer Index Only Scan sin leer la tabla.
       - Cuando el resultado viaja por red o alimenta ordenamientos y
         agrupaciones que usan memoria.
       En Track, con pocas filas y columnas cortas, la diferencia de
       tiempo es pequeña, pero el "width" del plan ya muestra el ahorro.
*/


/* =====================================================================
   TALLER CHINOOK - ETAPA 5: RETO FINAL
   Informe de géneros musicales con mejor desempeño
   ===================================================================== */

-- ---------------------------------------------------------------------
-- Consulta del reto
-- Cumple: INNER JOIN Genre-Track-InvoiceLine, COUNT/SUM/AVG,
-- GROUP BY género, HAVING > 50 unidades, orden por ingresos, TOP 5.
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- Análisis del plan de la consulta del reto
-- ---------------------------------------------------------------------
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

/* ---------------------------------------------------------------------
   CONCLUSIÓN TÉCNICA
   (Completa con los nodos y números reales de TU plan)
   ---------------------------------------------------------------------
   17. ¿Cuál fue la operación con mayor costo dentro del plan?
       ____________________________________________
       Cómo identificarla: el costo de cada nodo es acumulado (incluye a
       sus hijos), así que busca el nodo cuyo costo propio (su costo
       menos el de sus hijos) y cuyo "actual time" sean mayores.
       Lo típico en esta consulta: el GroupAggregate/HashAggregate con
       el Sort previo (COUNT(DISTINCT ...) obliga a ordenar), seguido del
       Hash Join entre InvoiceLine y Track, que es donde se procesan
       todas las líneas de factura.

   18. ¿Qué índices existentes fueron utilizados?
       ____________________________________________
       Lo típico: ninguno. Con tablas de este tamaño y una consulta que
       lee TODAS las líneas de factura, PostgreSQL prefiere Seq Scan en
       InvoiceLine, Track y Genre y unirlas con Hash Join. Los índices de
       clave primaria/foránea existen, pero no convienen cuando se procesa
       casi el 100 % de las filas.

   19. ¿Propondrías un índice adicional?
       Para ESTA consulta no: agrega sobre todas las ventas, así que un
       índice no evitaría leer las tablas completas y solo sumaría costo
       de mantenimiento.
       Un índice que sí tendría sentido, por ejemplo:
           CREATE INDEX idx_invoiceline_track_qty_price
               ON public."InvoiceLine" ("TrackId")
               INCLUDE ("Quantity", "UnitPrice");
       Beneficiaría consultas que filtran ventas de pocas canciones
       (p. ej. "ventas de las canciones de un álbum o género concreto"),
       porque permitiría un Index Only Scan sin leer la tabla.
       Costo de mantenimiento: más espacio en disco, y cada INSERT,
       UPDATE o DELETE en InvoiceLine (tabla que crece con cada venta)
       debe actualizar también el índice, lo que hace más lentas las
       escrituras. Solo compensa si esas consultas de lectura son
       frecuentes.
   --------------------------------------------------------------------- */
