/* =====================================================================
   TALLER CHINOOK - ETAPA 5: RETO FINAL
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
