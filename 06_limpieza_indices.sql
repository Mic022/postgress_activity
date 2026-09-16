/* =====================================================================
   TALLER CHINOOK - ANEXO: CONSULTA DE LIMPIEZA
   Retira únicamente los índices creados durante el taller.
   ===================================================================== */

DROP INDEX IF EXISTS public.idx_track_composer;
DROP INDEX IF EXISTS public.idx_track_genre_price;

ANALYZE public."Track";

-- Verificación: ya no deben aparecer los índices del taller
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename  = 'Track';

/* Idea clave: la existencia de un índice no obliga a PostgreSQL a
   utilizarlo. En tablas pequeñas o consultas que recuperan muchas filas,
   un recorrido secuencial puede ser la decisión más económica. */
