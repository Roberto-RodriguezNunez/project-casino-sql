/* ARCHIVO: sql/03_indices.sql
   DESCRIPCIÓN: Creación de índices para optimización de consultas.
   PROYECTO: Casino DB
*/

-- Índice para búsquedas por fecha en juegos
CREATE INDEX IDX_FECHA ON JUEGO(FECHA);

-- Índice para búsquedas por tipo de deporte
CREATE INDEX IDX_DEPORTE ON MAQUINA_DEPORTIVA(DEPORTE);

