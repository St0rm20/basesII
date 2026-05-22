-- ============================================================
-- 3.1.1  CONSULTAS PARAMETRIZADAS
-- ============================================================

-- ------------------------------------------------------------
-- CP-01: Top 10 contenido mas reproducido en una ciudad
-- ------------------------------------------------------------
SELECT *
FROM (
    SELECT
        c.titulo,
        cat.nombre_categoria         AS categoria,
        COUNT(r.id_reproduccion)     AS total_reproducciones,
        ROUND(AVG(r.porcentaje_avance), 2) AS promedio_avance_pct,
        SUM(CASE WHEN r.porcentaje_avance >= 90 THEN 1 ELSE 0 END)
                                     AS reproducciones_completas,
        RANK() OVER (
            ORDER BY COUNT(r.id_reproduccion) DESC
        )                            AS ranking
    FROM   REPRODUCCIONES  r
    JOIN   PERFILES         p   ON r.id_perfil    = p.id_perfil
    JOIN   USUARIOS         u   ON p.id_usuario   = u.id_usuario
    JOIN   CONTENIDO        c   ON r.id_contenido = c.id_contenido
    JOIN   CATEGORIAS       cat ON c.id_categoria = cat.id_categoria
    WHERE  UPPER(u.ciudad) = UPPER('&ciudad') 
      AND  r.activa        = 'N'       
    GROUP BY c.titulo, cat.nombre_categoria
)
WHERE ranking <= 10
ORDER BY ranking;


-- ------------------------------------------------------------
-- CP-02: Ingresos por plan de suscripcion en un mes y anio
-- ------------------------------------------------------------

SELECT
    pl.nombre_plan,
    COUNT(pg.id_pago)               AS total_pagos,
    SUM(pg.monto)                   AS ingreso_total,
    ROUND(AVG(pg.monto), 2)         AS ingreso_promedio,
    ROUND(MIN(pg.monto), 2)         AS ingreso_minimo,
    ROUND(MAX(pg.monto), 2)         AS ingreso_maximo
FROM   PAGOS   pg
JOIN   PLANES  pl ON pg.id_plan = pl.id_plan
WHERE  pg.estado = 'exitoso'
  AND  EXTRACT(MONTH FROM pg.fecha_pago) = &mes
  AND  EXTRACT(YEAR FROM pg.fecha_pago) = &anio
GROUP BY pl.nombre_plan
ORDER BY ingreso_total DESC;

-- ------------------------------------------------------------
-- CP-03: Calificacion promedio por categoria para un genero
--
-- Logica: se une CALIFICACIONES → CONTENIDO → CATEGORIAS para
-- obtener la categoria, y CONTENIDO → CONTENIDO_GENEROS →
-- GENEROS para filtrar por el genero recibido. Se incluye
-- el numero de calificaciones como medida de confianza del
-- promedio: un promedio basado en pocas muestras es menos
-- representativo.
-- ------------------------------------------------------------

SELECT
    '&genero'                          AS genero_filtrado,
    cat.nombre_categoria,
    g.nombre_genero,
    COUNT(cal.id_calificacion)          AS total_calificaciones,
    ROUND(AVG(cal.estrellas), 2)        AS promedio_estrellas,
    MIN(cal.estrellas)                  AS minimo,
    MAX(cal.estrellas)                  AS maximo,
    ROUND(STDDEV(cal.estrellas), 2)     AS desviacion_estandar
FROM   CALIFICACIONES    cal
JOIN   CONTENIDO         c   ON cal.id_contenido = c.id_contenido
JOIN   CATEGORIAS        cat ON c.id_categoria   = cat.id_categoria
JOIN   CONTENIDO_GENEROS cg  ON c.id_contenido   = cg.id_contenido
JOIN   GENEROS           g   ON cg.id_genero     = g.id_genero
WHERE  UPPER(g.nombre_genero) = UPPER('&genero') 
GROUP BY cat.nombre_categoria, g.nombre_genero
HAVING COUNT(cal.id_calificacion) >= 1   
ORDER BY promedio_estrellas DESC;
