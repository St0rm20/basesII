-- ------------------------------------------------------------
-- PV-01 (PIVOT): Usuarios activos por ciudad y plan
--
-- Logica: primero se genera el conjunto de datos base con
-- ciudad, nombre del plan y conteo de usuarios. Luego PIVOT
-- gira los valores del plan a columnas. Los planes fijos son
-- los tres definidos en el enunciado: Basico, Estandar, Premium.
-- ------------------------------------------------------------
SELECT *
FROM (
    SELECT
        u.ciudad,
        pl.nombre_plan,
        u.id_usuario
    FROM   USUARIOS  u
    JOIN   PLANES    pl ON u.id_plan = pl.id_plan
    WHERE  u.estado = 'ACTIVO'
)
PIVOT (
    COUNT(id_usuario)
    FOR nombre_plan IN (
        'Basico'    AS basico,
        'Estandar'  AS estandar,
        'Premium'   AS premium
    )
)
ORDER BY ciudad;


-- ------------------------------------------------------------
-- PV-02 (PIVOT): Reproducciones por categoria y dispositivo
--
-- Logica: el conjunto base cruza categorias con dispositivos.
-- PIVOT gira los cuatro dispositivos posibles (definidos con
-- CHECK en el DDL) en columnas independientes. Esto permite
-- identificar, por ejemplo, si las series se ven mas en TV
-- y la musica mas en celular.
-- ------------------------------------------------------------
SELECT *
FROM (
    SELECT
        cat.nombre_categoria,
        r.dispositivo,
        r.id_reproduccion
    FROM   REPRODUCCIONES  r
    JOIN   CONTENIDO       c   ON r.id_contenido = c.id_contenido
    JOIN   CATEGORIAS      cat ON c.id_categoria  = cat.id_categoria
    WHERE  r.dispositivo IS NOT NULL
)
PIVOT (
    COUNT(id_reproduccion)
    FOR dispositivo IN (
        'celular'     AS celular,
        'tablet'      AS tablet,
        'TV'          AS television,
        'computador'  AS computador
    )
)
ORDER BY nombre_categoria;

-- ------------------------------------------------------------
-- UP-01 (UNPIVOT): Despivotar el reporte de usuarios por plan
--
-- Logica: se parte del resultado de PV-01 guardado en una CTE
-- y se aplica UNPIVOT para volver a tener una fila por cada
-- combinacion ciudad-plan. INCLUDE NULLS garantiza que se
-- conserven las ciudades que no tienen usuarios en algun plan,
-- lo que es util para detectar brechas en la distribucion.
-- ------------------------------------------------------------
SELECT
    ciudad,
    plan_suscripcion,
    cantidad_usuarios
FROM (
    SELECT *
    FROM (
        SELECT
            u.ciudad,
            pl.nombre_plan,
            u.id_usuario
        FROM   USUARIOS  u
        JOIN   PLANES    pl ON u.id_plan = pl.id_plan
        WHERE  u.estado = 'ACTIVO'
          AND  UPPER(u.ciudad) = UPPER('&ciudad')
    )
    PIVOT (
        COUNT(id_usuario)
        FOR nombre_plan IN (
            'Basico'    AS basico,
            'Estandar'  AS estandar,
            'Premium'   AS premium
        )
    )
) 
UNPIVOT INCLUDE NULLS (
    cantidad_usuarios
    FOR plan_suscripcion IN (
        basico    AS "Basico",
        estandar  AS "Estandar",
        premium   AS "Premium"
    )
)
ORDER BY ciudad, plan_suscripcion;
