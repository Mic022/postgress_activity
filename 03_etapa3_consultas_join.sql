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
