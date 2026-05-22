-- ============================================================
-- 2. CONSULTA PESADA (la misma para ambas pruebas)
-- ============================================================

-- Esta consulta filtra por fecha y activa, y hace JOIN con perfiles y usuarios
SELECT 
    u.ciudad,
    c.titulo,
    COUNT(r.id_reproduccion) AS total_reproducciones
FROM REPRODUCCIONES r
JOIN PERFILES p ON r.id_perfil = p.id_perfil
JOIN USUARIOS u ON p.id_usuario = u.id_usuario
JOIN CONTENIDO c ON r.id_contenido = c.id_contenido
WHERE r.fecha_hora_inicio >= SYSDATE - 30
  AND r.activa = 'N'
GROUP BY u.ciudad, c.titulo;



-- Deshabilitar índices (simula que no existen)
ALTER INDEX idx_reprod_perfil_fecha UNUSABLE;
ALTER INDEX idx_reprod_activa_fecha UNUSABLE;

-- Ver plan de ejecución SIN índices
EXPLAIN PLAN FOR
SELECT u.ciudad, c.titulo, COUNT(r.id_reproduccion) AS total
FROM REPRODUCCIONES r
JOIN PERFILES p ON r.id_perfil = p.id_perfil
JOIN USUARIOS u ON p.id_usuario = u.id_usuario
JOIN CONTENIDO c ON r.id_contenido = c.id_contenido
WHERE r.fecha_hora_inicio >= SYSDATE - 30 AND r.activa = 'N'
GROUP BY u.ciudad, c.titulo;

-- Mostrar plan (anota el COSTO)
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Medir tiempo real SIN índices
SET TIMING ON;
SELECT u.ciudad, c.titulo, COUNT(r.id_reproduccion) AS total
FROM REPRODUCCIONES r
JOIN PERFILES p ON r.id_perfil = p.id_perfil
JOIN USUARIOS u ON p.id_usuario = u.id_usuario
JOIN CONTENIDO c ON r.id_contenido = c.id_contenido
WHERE r.fecha_hora_inicio >= SYSDATE - 30 AND r.activa = 'N'
GROUP BY u.ciudad, c.titulo;
SET TIMING OFF;



-- PASO 3




-- Reconstruir/habilitar índices
ALTER INDEX idx_reprod_perfil_fecha REBUILD;
ALTER INDEX idx_reprod_activa_fecha REBUILD;

-- Ver plan de ejecución CON índices
EXPLAIN PLAN FOR
SELECT u.ciudad, c.titulo, COUNT(r.id_reproduccion) AS total
FROM REPRODUCCIONES r
JOIN PERFILES p ON r.id_perfil = p.id_perfil
JOIN USUARIOS u ON p.id_usuario = u.id_usuario
JOIN CONTENIDO c ON r.id_contenido = c.id_contenido
WHERE r.fecha_hora_inicio >= SYSDATE - 30 AND r.activa = 'N'
GROUP BY u.ciudad, c.titulo;

-- Mostrar plan (anota el COSTO)
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Medir tiempo real CON índices
SET TIMING ON;
SELECT u.ciudad, c.titulo, COUNT(r.id_reproduccion) AS total
FROM REPRODUCCIONES r
JOIN PERFILES p ON r.id_perfil = p.id_perfil
JOIN USUARIOS u ON p.id_usuario = u.id_usuario
JOIN CONTENIDO c ON r.id_contenido = c.id_contenido
WHERE r.fecha_hora_inicio >= SYSDATE - 30 AND r.activa = 'N'
GROUP BY u.ciudad, c.titulo;
SET TIMING OFF;




--Limpiar


-- Reconstruir/habilitar índices
ALTER INDEX idx_reprod_perfil_fecha REBUILD;
ALTER INDEX idx_reprod_activa_fecha REBUILD;

-- Ver plan de ejecución CON índices
EXPLAIN PLAN FOR
SELECT u.ciudad, c.titulo, COUNT(r.id_reproduccion) AS total
FROM REPRODUCCIONES r
JOIN PERFILES p ON r.id_perfil = p.id_perfil
JOIN USUARIOS u ON p.id_usuario = u.id_usuario
JOIN CONTENIDO c ON r.id_contenido = c.id_contenido
WHERE r.fecha_hora_inicio >= SYSDATE - 30 AND r.activa = 'N'
GROUP BY u.ciudad, c.titulo;

-- Mostrar plan (anota el COSTO)
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Medir tiempo real CON índices
SET TIMING ON;
SELECT u.ciudad, c.titulo, COUNT(r.id_reproduccion) AS total
FROM REPRODUCCIONES r
JOIN PERFILES p ON r.id_perfil = p.id_perfil
JOIN USUARIOS u ON p.id_usuario = u.id_usuario
JOIN CONTENIDO c ON r.id_contenido = c.id_contenido
WHERE r.fecha_hora_inicio >= SYSDATE - 30 AND r.activa = 'N'
GROUP BY u.ciudad, c.titulo;
SET TIMING OFF;