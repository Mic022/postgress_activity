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
