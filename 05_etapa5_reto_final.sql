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
