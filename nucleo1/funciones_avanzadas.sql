-- ------------------------------------------------------------
-- ROLLUP: Reporte de ingresos por ciudad y plan de suscripcion
--         con subtotales por ciudad y gran total
-- ------------------------------------------------------------
SELECT
    NVL(u.ciudad, 'TODAS LAS CIUDADES')           AS ciudad,
    NVL(pl.nombre_plan, 'TODOS LOS PLANES')       AS plan_suscripcion,
    COUNT(DISTINCT u.id_usuario)                  AS total_usuarios,
    COUNT(pg.id_pago)                             AS total_pagos,
    SUM(pg.monto)                                 AS ingreso_total,
    ROUND(AVG(pg.monto), 2)                       AS ingreso_promedio
FROM   USUARIOS  u
JOIN   PLANES    pl ON u.id_plan = pl.id_plan
JOIN   PAGOS     pg ON u.id_usuario = pg.id_usuario AND pg.id_plan = pl.id_plan
WHERE  pg.estado = 'exitoso'
GROUP BY ROLLUP(u.ciudad, pl.nombre_plan)
ORDER BY 
    CASE WHEN u.ciudad IS NULL THEN 1 ELSE 0 END,  -- gran total al final
    u.ciudad,
    CASE WHEN pl.nombre_plan IS NULL THEN 1 ELSE 0 END,
    pl.nombre_plan;



-- ------------------------------------------------------------
-- CUBE: Reporte de reproducciones por categoria y dispositivo
--       con todas las combinaciones posibles
-- ------------------------------------------------------------
SELECT
    NVL(cat.nombre_categoria, 'TODAS LAS CATEGORIAS')     AS categoria,
    NVL(r.dispositivo, 'TODOS LOS DISPOSITIVOS')          AS dispositivo,
    COUNT(r.id_reproduccion)                              AS total_reproducciones,
    COUNT(DISTINCT r.id_perfil)                           AS perfiles_unicos,
    ROUND(AVG(r.porcentaje_avance), 2)                    AS avance_promedio_pct,
    SUM(CASE WHEN r.porcentaje_avance >= 90 THEN 1 ELSE 0 END) AS reproducciones_completas
FROM   REPRODUCCIONES  r
JOIN   CONTENIDO       c   ON r.id_contenido = c.id_contenido
JOIN   CATEGORIAS      cat ON c.id_categoria  = cat.id_categoria
WHERE  r.dispositivo IS NOT NULL
GROUP BY CUBE(cat.nombre_categoria, r.dispositivo)
ORDER BY 
    CASE WHEN cat.nombre_categoria IS NULL THEN 1 ELSE 0 END,
    cat.nombre_categoria,
    CASE WHEN r.dispositivo IS NULL THEN 1 ELSE 0 END,
    r.dispositivo;


-- ------------------------------------------------------------
-- CUBE: Reporte de reproducciones por categoria y dispositivo
--       con todas las combinaciones posibles
-- ------------------------------------------------------------
SELECT
    NVL(cat.nombre_categoria, 'TODAS LAS CATEGORIAS')     AS categoria,
    NVL(r.dispositivo, 'TODOS LOS DISPOSITIVOS')          AS dispositivo,
    COUNT(r.id_reproduccion)                              AS total_reproducciones,
    COUNT(DISTINCT r.id_perfil)                           AS perfiles_unicos,
    ROUND(AVG(r.porcentaje_avance), 2)                    AS avance_promedio_pct,
    SUM(CASE WHEN r.porcentaje_avance >= 90 THEN 1 ELSE 0 END) AS reproducciones_completas
FROM   REPRODUCCIONES  r
JOIN   CONTENIDO       c   ON r.id_contenido = c.id_contenido
JOIN   CATEGORIAS      cat ON c.id_categoria  = cat.id_categoria
WHERE  r.dispositivo IS NOT NULL
GROUP BY CUBE(cat.nombre_categoria, r.dispositivo)
ORDER BY 
    CASE WHEN cat.nombre_categoria IS NULL THEN 1 ELSE 0 END,
    cat.nombre_categoria,
    CASE WHEN r.dispositivo IS NULL THEN 1 ELSE 0 END,
    r.dispositivo;


-- ------------------------------------------------------------
-- GROUPING SETS: Reporte que muestre solo los totales por
--                categoria y por ciudad, sin el detalle cruzado
-- ------------------------------------------------------------
SELECT
    CASE 
        WHEN GROUPING(cat.nombre_categoria) = 0 AND GROUPING(u.ciudad) = 1 
            THEN 'TOTAL POR CATEGORIA'
        WHEN GROUPING(cat.nombre_categoria) = 1 AND GROUPING(u.ciudad) = 0 
            THEN 'TOTAL POR CIUDAD'
        ELSE 'OTRO'
    END AS tipo_reporte,
    
    NVL(cat.nombre_categoria, '-- TODAS --')      AS categoria,
    NVL(u.ciudad, '-- TODAS --')                  AS ciudad,
    
    -- Metricas
    COUNT(r.id_reproduccion)                      AS total_reproducciones,
    COUNT(DISTINCT r.id_perfil)                   AS perfiles_unicos,
    COUNT(DISTINCT u.id_usuario)                  AS usuarios_unicos,
    ROUND(AVG(r.porcentaje_avance), 2)            AS avance_promedio_pct,
    
    -- Indicadores de grupo (para debugging)
    GROUPING(cat.nombre_categoria) AS es_total_categoria,
    GROUPING(u.ciudad) AS es_total_ciudad

FROM   REPRODUCCIONES  r
JOIN   PERFILES        p   ON r.id_perfil    = p.id_perfil
JOIN   USUARIOS        u   ON p.id_usuario   = u.id_usuario
JOIN   CONTENIDO       c   ON r.id_contenido = c.id_contenido
JOIN   CATEGORIAS      cat ON c.id_categoria  = cat.id_categoria
WHERE  r.activa = 'N'  -- Solo reproducciones completadas/finalizadas
GROUP BY GROUPING SETS (
    (cat.nombre_categoria),   -- total por categoria
    (u.ciudad)                -- total por ciudad
)
ORDER BY 
    tipo_reporte,
    categoria NULLS LAST,
    ciudad NULLS LAST;
