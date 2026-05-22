
-- ------------------------------------------------------------
-- MV-01: Vista materializada de popularidad de contenido
-- 
-- Uso: Base para el reporte "Contenido Mas Popular"
-- Calcula: total_reproducciones, promedio_calificacion, 
--          porcentaje_completado, y score_personalizado
--
-- Metodo de refresco: COMPLETE (porque involucra JOINs y agregaciones)
-- Periodicidad sugerida: Cada 30 minutos o 1 hora (dependiendo del trafico)
-- ------------------------------------------------------------

CREATE MATERIALIZED VIEW MV_POPULARIDAD_CONTENIDO
REFRESH COMPLETE ON DEMAND
-- O tambien: REFRESH FAST ON COMMIT (requiere MV Log)
AS
WITH estadisticas_reproduccion AS (
    SELECT
        r.id_contenido,
        COUNT(r.id_reproduccion)                     AS total_reproducciones,
        COUNT(DISTINCT r.id_perfil)                  AS perfiles_unicos,
        ROUND(AVG(r.porcentaje_avance), 2)           AS avance_promedio_pct,
        SUM(CASE WHEN r.porcentaje_avance >= 90 THEN 1 ELSE 0 END) AS completadas,
        SUM(CASE WHEN r.porcentaje_avance < 10 THEN 1 ELSE 0 END)  AS abandonadas_temprano,
        MIN(r.fecha_hora_inicio)                     AS primera_reproduccion,
        MAX(r.fecha_hora_inicio)                     AS ultima_reproduccion
    FROM   REPRODUCCIONES  r
    WHERE  r.activa = 'N'  -- Solo reproducciones finalizadas
    GROUP BY r.id_contenido
),
estadisticas_calificacion AS (
    SELECT
        cal.id_contenido,
        COUNT(cal.id_calificacion)                   AS total_calificaciones,
        ROUND(AVG(cal.estrellas), 2)                 AS promedio_estrellas,
        ROUND(STDDEV(cal.estrellas), 2)              AS desviacion_estrellas,
        SUM(CASE WHEN cal.estrellas >= 4 THEN 1 ELSE 0 END) AS calificaciones_altas
    FROM   CALIFICACIONES  cal
    GROUP BY cal.id_contenido
)

SELECT
    c.id_contenido,
    c.titulo,
    cat.nombre_categoria,
    g.nombre_genero,
    c.anio_lanzamiento,
    c.clasificacion_edad,
    c.es_original,
    c.fecha_agregado,
    
    -- Metricas de reproduccion
    NVL(r.total_reproducciones, 0)                   AS total_reproducciones,
    NVL(r.perfiles_unicos, 0)                        AS perfiles_unicos,
    NVL(r.avance_promedio_pct, 0)                    AS avance_promedio_pct,
    NVL(r.completadas, 0)                            AS reproducciones_completas,
    NVL(r.abandonadas_temprano, 0)                   AS abandonadas_temprano,
    
    -- Metricas de calificacion
    NVL(cal.total_calificaciones, 0)                 AS total_calificaciones,
    NVL(cal.promedio_estrellas, 0)                   AS promedio_calificacion,
    NVL(cal.desviacion_estrellas, 0)                 AS desviacion_calificacion,
    NVL(cal.calificaciones_altas, 0)                 AS calificaciones_altas,
    
    -- Metricas derivadas (score de popularidad)
    ROUND(
        (NVL(r.total_reproducciones, 0) * 0.4) +
        (NVL(cal.promedio_estrellas, 0) * 20) +
        (NVL(r.avance_promedio_pct, 0) * 0.3) +
        (CASE WHEN c.es_original = 'S' THEN 50 ELSE 0 END)
    , 2)                                             AS score_popularidad,
    
    -- Antiguedad en dias (para ponderar frescura)
    ROUND(SYSDATE - NVL(c.fecha_agregado, SYSDATE))  AS dias_antiguedad

FROM   CONTENIDO            c
LEFT JOIN estadisticas_reproduccion  r   ON c.id_contenido = r.id_contenido
LEFT JOIN estadisticas_calificacion  cal ON c.id_contenido = cal.id_contenido
LEFT JOIN CATEGORIAS                 cat ON c.id_categoria = cat.id_categoria
LEFT JOIN (
    SELECT id_contenido, LISTAGG(nombre_genero, ', ') WITHIN GROUP (ORDER BY nombre_genero) AS nombre_genero
    FROM CONTENIDO_GENEROS cg
    JOIN GENEROS g ON cg.id_genero = g.id_genero
    GROUP BY id_contenido
) g ON c.id_contenido = g.id_contenido;


-- ------------------------------------------------------------
-- MV-02: Vista materializada de ingresos mensuales
-- 
-- Uso: Base para reporte financiero mensual
-- Calcula: ingresos totales, promedio, numero de suscriptores,
--          retencion, ingresos recurrentes mensuales (MRR)
--
-- Metodo de refresco: COMPLETE ON DEMAND (recomendado refrescar cada 24h)
--                      o despues del cierre de cada mes
-- ------------------------------------------------------------

CREATE MATERIALIZED VIEW MV_INGRESOS_MENSUALES
REFRESH COMPLETE ON DEMAND
AS
WITH pagos_validos AS (
    SELECT
        pg.id_pago,
        pg.id_usuario,
        pg.id_plan,
        pg.fecha_pago,
        pg.monto,
        pg.metodo_pago,
        EXTRACT(YEAR FROM pg.fecha_pago)  AS anio,
        EXTRACT(MONTH FROM pg.fecha_pago) AS mes,
        EXTRACT(DAY FROM pg.fecha_pago)   AS dia,
        TO_CHAR(pg.fecha_pago, 'YYYY-MM') AS anio_mes
    FROM   PAGOS  pg
    WHERE  pg.estado = 'exitoso'
),
usuarios_activos_mes AS (
    SELECT
        u.id_usuario,
        u.ciudad,
        u.id_plan,
        EXTRACT(YEAR FROM u.fecha_registro)   AS anio_registro,
        EXTRACT(MONTH FROM u.fecha_registro)  AS mes_registro
    FROM   USUARIOS  u
    WHERE  u.estado = 'ACTIVO'
),
retencion_mensual AS (
    SELECT
        anio,
        mes,
        id_plan,
        ciudad,
        COUNT(DISTINCT id_usuario) AS total_unicos_mes,
        LAG(COUNT(DISTINCT id_usuario), 1) OVER (
            PARTITION BY id_plan, ciudad 
            ORDER BY anio, mes
        ) AS usuarios_mes_anterior,
        LAG(COUNT(DISTINCT id_usuario), 12) OVER (
            PARTITION BY id_plan, ciudad 
            ORDER BY anio, mes
        ) AS usuarios_mes_anio_anterior
    FROM (
        SELECT DISTINCT
            pv.anio,
            pv.mes,
            pv.id_usuario,
            ua.ciudad,
            ua.id_plan
        FROM pagos_validos pv
        JOIN usuarios_activos_mes ua ON pv.id_usuario = ua.id_usuario
    )
    GROUP BY anio, mes, id_plan, ciudad
)

SELECT
    pv.anio,
    pv.mes,
    TO_CHAR(TO_DATE(pv.mes || '/01/' || pv.anio, 'MM/DD/YYYY'), 'Month') AS nombre_mes,
    pv.anio_mes,
    
    -- Dimensiones
    u.ciudad,
    pl.nombre_plan,
    pl.precio AS precio_base_plan,
    
    -- Metricas de ingresos
    COUNT(pv.id_pago)                                AS total_transacciones,
    SUM(pv.monto)                                    AS ingreso_bruto,
    ROUND(AVG(pv.monto), 2)                          AS ticket_promedio,
    MIN(pv.monto)                                    AS ingreso_minimo,
    MAX(pv.monto)                                    AS ingreso_maximo,
    MEDIAN(pv.monto)                                 AS ingreso_mediana,
    
    -- Desglose por metodo de pago
    COUNT(CASE WHEN pv.metodo_pago = 'tarjeta_credito' THEN 1 END) AS transacciones_tc,
    COUNT(CASE WHEN pv.metodo_pago = 'tarjeta_debito' THEN 1 END)  AS transacciones_td,
    COUNT(CASE WHEN pv.metodo_pago = 'PSE' THEN 1 END)              AS transacciones_pse,
    COUNT(CASE WHEN pv.metodo_pago IN ('Nequi', 'Daviplata') THEN 1 END) AS transacciones_billeteras,
    SUM(CASE WHEN pv.metodo_pago = 'tarjeta_credito' THEN pv.monto ELSE 0 END) AS ingreso_tc,
    SUM(CASE WHEN pv.metodo_pago = 'tarjeta_debito' THEN pv.monto ELSE 0 END)  AS ingreso_td,
    SUM(CASE WHEN pv.metodo_pago = 'PSE' THEN pv.monto ELSE 0 END)              AS ingreso_pse,
    SUM(CASE WHEN pv.metodo_pago IN ('Nequi', 'Daviplata') THEN pv.monto ELSE 0 END) AS ingreso_billeteras,
    
    -- Metricas de suscriptores (usuarios unicos que pagaron en el mes)
    COUNT(DISTINCT pv.id_usuario)                    AS suscriptores_unicos_mes,
    
    -- Retencion y crecimiento
    NVL(rt.total_unicos_mes, 0)                      AS total_unicos_validado,
    NVL(rt.usuarios_mes_anterior, 0)                 AS usuarios_mes_anterior,
    NVL(rt.usuarios_mes_anio_anterior, 0)            AS usuarios_mes_anio_anterior,
    
    CASE 
        WHEN NVL(rt.usuarios_mes_anterior, 0) = 0 THEN NULL
        ELSE ROUND(((rt.total_unicos_mes - rt.usuarios_mes_anterior) * 100.0) / rt.usuarios_mes_anterior, 2)
    END AS tasa_crecimiento_mensual_pct,
    
    CASE 
        WHEN NVL(rt.usuarios_mes_anio_anterior, 0) = 0 THEN NULL
        ELSE ROUND(((rt.total_unicos_mes - rt.usuarios_mes_anio_anterior) * 100.0) / rt.usuarios_mes_anio_anterior, 2)
    END AS tasa_crecimiento_anual_pct,
    
    -- MRR (Monthly Recurring Revenue) estimado
    COUNT(DISTINCT pv.id_usuario) * AVG(pl.precio)   AS mrr_estimado,
    
    -- Valor por usuario (ARPU)
    ROUND(SUM(pv.monto) / NULLIF(COUNT(DISTINCT pv.id_usuario), 0), 2) AS arpu

FROM   pagos_validos        pv
JOIN   USUARIOS             u  ON pv.id_usuario = u.id_usuario
JOIN   PLANES               pl ON pv.id_plan    = pl.id_plan
LEFT JOIN retencion_mensual rt ON rt.anio    = pv.anio 
                               AND rt.mes     = pv.mes
                               AND rt.id_plan = pl.id_plan
                               AND rt.ciudad  = u.ciudad

GROUP BY 
    pv.anio,
    pv.mes,
    pv.anio_mes,
    u.ciudad,
    pl.nombre_plan,
    pl.precio,
    rt.total_unicos_mes,
    rt.usuarios_mes_anterior,
    rt.usuarios_mes_anio_anterior

ORDER BY 
    pv.anio DESC,
    pv.mes DESC,
    u.ciudad,
    pl.nombre_plan;


