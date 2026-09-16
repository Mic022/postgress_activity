/* =====================================================================
   TALLER CHINOOK - ETAPA 4: ANÁLISIS Y OPTIMIZACIÓN (Ejercicios 13 a 16)
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
