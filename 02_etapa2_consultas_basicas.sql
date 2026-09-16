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
