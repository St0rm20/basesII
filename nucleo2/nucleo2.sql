-- ============================================================
-- QUINDIOFLIX — Nucleo 2: PL/SQL
-- Base de Datos II — Universidad del Quindio
-- Semestre 2026-1
--
-- Contenido:
--   3.2.1  Cursores (2)
--   3.2.2  Procedimientos almacenados (3)
--   3.2.3  Funciones (2)
--   3.2.4  Excepciones personalizadas (dentro de SP)
--   3.2.5  Disparadores (5: 4 requeridos + 1 adicional
--           que cubre RN no implementadas en el DDL)
-- ============================================================


-- ============================================================
-- 3.2.1  CURSORES
-- ============================================================

-- ------------------------------------------------------------
-- CUR-01: Usuarios con suscripcion vencida (mora > 30 dias)
--
-- Logica (RN-01): si un usuario no registra un pago exitoso
-- en los ultimos 30 dias, la cuenta debe pasar a INACTIVO.
-- Este cursor recorre todos los usuarios en esa situacion,
-- calcula los dias de mora y el monto adeudado, y emite el
-- reporte. Ademas actualiza el estado a INACTIVO para los
-- que aun aparezcan como ACTIVO.
--
-- Se usa un cursor explicito con INTO para tener control total
-- sobre el ciclo OPEN-FETCH-CLOSE, lo que permite acumular
-- contadores y totales mientras se recorre el resultado.
-- ------------------------------------------------------------
DECLARE
    -- Tipo registro que coincide con las columnas del cursor
    TYPE t_mora_rec IS RECORD (
        id_usuario        USUARIOS.id_usuario%TYPE,
        nombre            USUARIOS.nombre%TYPE,
        email             USUARIOS.email%TYPE,
        nombre_plan       PLANES.nombre_plan%TYPE,
        precio_plan       PLANES.precio%TYPE,
        fecha_ultimo_pago USUARIOS.fecha_ultimo_pago%TYPE,
        dias_mora         NUMBER,
        estado_actual     USUARIOS.estado%TYPE
    );

    v_reg          t_mora_rec;
    v_total_users  NUMBER := 0;
    v_total_deuda  NUMBER := 0;

    CURSOR cur_morosos IS
        SELECT
            u.id_usuario,
            u.nombre,
            u.email,
            pl.nombre_plan,
            pl.precio                                       AS precio_plan,
            u.fecha_ultimo_pago,
            TRUNC(SYSDATE) - TRUNC(u.fecha_ultimo_pago)    AS dias_mora,
            u.estado
        FROM   USUARIOS  u
        JOIN   PLANES    pl ON u.id_plan = pl.id_plan
        WHERE  (
                   u.fecha_ultimo_pago IS NULL
               OR  TRUNC(SYSDATE) - TRUNC(u.fecha_ultimo_pago) > 30
               )
          AND  u.id_plan IS NOT NULL
        ORDER BY dias_mora DESC;

BEGIN
    DBMS_OUTPUT.PUT_LINE('==============================================');
    DBMS_OUTPUT.PUT_LINE('  REPORTE DE USUARIOS EN MORA — ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY'));
    DBMS_OUTPUT.PUT_LINE('==============================================');
    DBMS_OUTPUT.PUT_LINE(
        RPAD('NOMBRE',            25) || ' ' ||
        RPAD('EMAIL',             30) || ' ' ||
        RPAD('PLAN',              12) || ' ' ||
        LPAD('DIAS MORA', 10)    || ' ' ||
        LPAD('MONTO USD', 10)
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 90, '-'));

    OPEN cur_morosos;
    LOOP
        FETCH cur_morosos INTO v_reg;
        EXIT WHEN cur_morosos%NOTFOUND;

        -- Imprimir linea del reporte
        DBMS_OUTPUT.PUT_LINE(
            RPAD(v_reg.nombre,      25) || ' ' ||
            RPAD(v_reg.email,       30) || ' ' ||
            RPAD(v_reg.nombre_plan, 12) || ' ' ||
            LPAD(v_reg.dias_mora,   10) || ' ' ||
            LPAD(v_reg.precio_plan, 10)
        );

        -- Acumular totales
        v_total_users := v_total_users + 1;
        v_total_deuda := v_total_deuda + v_reg.precio_plan;

        -- Aplicar RN-01: marcar INACTIVO si aun aparece ACTIVO
        IF v_reg.estado_actual = 'ACTIVO' THEN
            UPDATE USUARIOS
               SET estado = 'INACTIVO'
             WHERE id_usuario = v_reg.id_usuario;
        END IF;
    END LOOP;
    CLOSE cur_morosos;

    DBMS_OUTPUT.PUT_LINE(RPAD('-', 90, '-'));
    DBMS_OUTPUT.PUT_LINE('Total de usuarios en mora : ' || v_total_users);
    DBMS_OUTPUT.PUT_LINE('Monto total adeudado (USD): ' || v_total_deuda);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/


-- ------------------------------------------------------------
-- CUR-02: Actualizar popularidad del catalogo (RN-11)
--
-- Logica: recorre cada contenido del catalogo, cuenta cuantas
-- reproducciones completas (porcentaje_avance >= 90 %) tiene
-- y actualiza el campo popularidad. Se usa un cursor FOR para
-- simplificar el ciclo; Oracle lo abre, hace fetch y lo cierra
-- automaticamente.
--
-- El puntaje de popularidad se calcula como:
--   popularidad = reproducciones_completas * 10
--               + reproducciones_parciales * 2
-- Esto premia mas las reproducciones completas pero no ignora
-- las parciales (indican interes aunque no finalizacion).
-- ------------------------------------------------------------
DECLARE
    v_completas  NUMBER;
    v_parciales  NUMBER;
    v_puntaje    NUMBER;
    v_actualizados NUMBER := 0;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Iniciando actualizacion de popularidad — ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI'));

    FOR rec IN (
        SELECT id_contenido, titulo
        FROM   CONTENIDO
        ORDER BY id_contenido
    ) LOOP
        -- Reproducciones completas de este contenido
        SELECT COUNT(*)
          INTO v_completas
          FROM REPRODUCCIONES
         WHERE id_contenido      = rec.id_contenido
           AND activa            = 'N'
           AND porcentaje_avance >= 90;

        -- Reproducciones parciales (iniciadas pero < 90 %)
        SELECT COUNT(*)
          INTO v_parciales
          FROM REPRODUCCIONES
         WHERE id_contenido      = rec.id_contenido
           AND activa            = 'N'
           AND porcentaje_avance < 90
           AND porcentaje_avance > 0;

        -- Formula de popularidad
        v_puntaje := (v_completas * 10) + (v_parciales * 2);

        -- Actualizar el campo en CONTENIDO
        UPDATE CONTENIDO
           SET popularidad = v_puntaje
         WHERE id_contenido = rec.id_contenido;

        v_actualizados := v_actualizados + 1;

        -- Reporte de contenido con alta popularidad
        IF v_puntaje > 100 THEN
            DBMS_OUTPUT.PUT_LINE(
                '  [DESTACADO] ' || RPAD(rec.titulo, 40) ||
                ' — Puntaje: ' || v_puntaje
            );
        END IF;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Contenidos actualizados: ' || v_actualizados);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/


-- ============================================================
-- 3.2.2  PROCEDIMIENTOS ALMACENADOS
-- ============================================================

-- ------------------------------------------------------------
-- SP_REGISTRAR_USUARIO
--
-- Recibe los datos del usuario y el plan elegido; valida que
-- el email no exista; crea la cuenta; crea un perfil adulto
-- predeterminado; registra el primer pago.
--
-- Excepciones manejadas (3.2.4):
--   EX_EMAIL_DUPLICADO : el email ya existe en USUARIOS.
--   NO_DATA_FOUND      : el id_plan no existe en PLANES.
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE SP_REGISTRAR_USUARIO (
    p_nombre          IN USUARIOS.nombre%TYPE,
    p_email           IN USUARIOS.email%TYPE,
    p_telefono        IN USUARIOS.telefono%TYPE,
    p_fecha_nac       IN USUARIOS.fecha_nacimiento%TYPE,
    p_ciudad          IN USUARIOS.ciudad%TYPE,
    p_password_hash   IN USUARIOS.password_hash%TYPE,
    p_id_plan         IN PLANES.id_plan%TYPE,
    p_metodo_pago     IN PAGOS.metodo_pago%TYPE,
    p_id_referidor    IN USUARIOS.id_usuario%TYPE DEFAULT NULL
)
AS
    -- Excepcion personalizada: email ya registrado
    EX_EMAIL_DUPLICADO EXCEPTION;
    PRAGMA EXCEPTION_INIT(EX_EMAIL_DUPLICADO, -20001);

    v_count         NUMBER;
    v_precio_plan   PLANES.precio%TYPE;
    v_dur_dias      PLANES.duracion_dias%TYPE;
    v_id_usuario    USUARIOS.id_usuario%TYPE;
    v_id_pago       PAGOS.id_pago%TYPE;
    v_id_perfil     PERFILES.id_perfil%TYPE;
    v_id_referido   REFERIDOS.id_referido%TYPE;

BEGIN
    -- 1. Validar que el email no exista
    SELECT COUNT(*)
      INTO v_count
      FROM USUARIOS
     WHERE UPPER(email) = UPPER(p_email);

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001,
            'El email ' || p_email || ' ya esta registrado en la plataforma.');
    END IF;

    -- 2. Validar que el plan exista y obtener su precio
    --    Si no existe, Oracle lanza NO_DATA_FOUND automaticamente
    SELECT precio, duracion_dias
      INTO v_precio_plan, v_dur_dias
      FROM PLANES
     WHERE id_plan = p_id_plan;

    -- 3. Generar el id del nuevo usuario con secuencia
    SELECT NVL(MAX(id_usuario), 0) + 1
      INTO v_id_usuario
      FROM USUARIOS;

    -- 4. Insertar el usuario
    INSERT INTO USUARIOS (
        id_usuario, nombre, email, telefono, fecha_nacimiento,
        ciudad, password_hash, id_plan, estado,
        fecha_vencimiento, fecha_registro, fecha_ultimo_pago,
        saldo_a_favor, id_rol_usuario
    ) VALUES (
        v_id_usuario, p_nombre, p_email, p_telefono, p_fecha_nac,
        p_ciudad, p_password_hash, p_id_plan, 'ACTIVO',
        SYSDATE + v_dur_dias, SYSDATE, SYSDATE,
        0, 1   -- rol 1 = suscriptor
    );

    -- 5. Crear perfil predeterminado (adulto)
    SELECT NVL(MAX(id_perfil), 0) + 1
      INTO v_id_perfil
      FROM PERFILES;

    INSERT INTO PERFILES (id_perfil, id_usuario, nombre, tipo)
    VALUES (v_id_perfil, v_id_usuario, 'Mi perfil', 'adulto');

    -- 6. Registrar el primer pago
    SELECT NVL(MAX(id_pago), 0) + 1
      INTO v_id_pago
      FROM PAGOS;

    INSERT INTO PAGOS (
        id_pago, id_usuario, id_plan, fecha_pago,
        monto, metodo_pago, estado
    ) VALUES (
        v_id_pago, v_id_usuario, p_id_plan, SYSDATE,
        v_precio_plan, p_metodo_pago, 'exitoso'
    );

    -- 7. Registrar referido si se proporciono (RN-08)
    IF p_id_referidor IS NOT NULL THEN
        -- Validar que el referidor exista y sea distinto
        SELECT COUNT(*) INTO v_count
          FROM USUARIOS WHERE id_usuario = p_id_referidor;

        IF v_count > 0 AND p_id_referidor <> v_id_usuario THEN
            SELECT NVL(MAX(id_referido), 0) + 1
              INTO v_id_referido
              FROM REFERIDOS;

            INSERT INTO REFERIDOS (
                id_referido, id_usuario_referidor,
                id_usuario_referido, fecha_referido
            ) VALUES (
                v_id_referido, p_id_referidor,
                v_id_usuario, SYSDATE
            );

            -- Beneficio para el referidor
            INSERT INTO BENEFICIOS_REFERIDOS (
                id_beneficio, id_referido, id_usuario,
                tipo_beneficio, valor_descuento, estado, fecha_otorgado
            ) VALUES (
                (SELECT NVL(MAX(id_beneficio), 0) + 1 FROM BENEFICIOS_REFERIDOS),
                v_id_referido, p_id_referidor,
                'descuento_mes', 10, 'pendiente', SYSDATE
            );

            -- Beneficio para el nuevo usuario (referido)
            INSERT INTO BENEFICIOS_REFERIDOS (
                id_beneficio, id_referido, id_usuario,
                tipo_beneficio, valor_descuento, estado, fecha_otorgado
            ) VALUES (
                (SELECT NVL(MAX(id_beneficio), 0) + 1 FROM BENEFICIOS_REFERIDOS),
                v_id_referido, v_id_usuario,
                'descuento_mes', 10, 'pendiente', SYSDATE
            );
        END IF;
    END IF;

    -- 8. Registrar en historial de planes
    INSERT INTO HISTORIAL_PLANES (
        id_historial, id_usuario, id_plan, fecha_inicio, fecha_fin
    ) VALUES (
        (SELECT NVL(MAX(id_historial), 0) + 1 FROM HISTORIAL_PLANES),
        v_id_usuario, p_id_plan, SYSDATE, NULL
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Usuario registrado con exito. ID: ' || v_id_usuario);

EXCEPTION
    WHEN EX_EMAIL_DUPLICADO THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR (RN): ' || SQLERRM);
        RAISE;
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: El plan con ID ' || p_id_plan || ' no existe.');
        RAISE;
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR inesperado: ' || SQLERRM);
        RAISE;
END SP_REGISTRAR_USUARIO;
/


-- ------------------------------------------------------------
-- SP_CAMBIAR_PLAN
--
-- Recibe el id del usuario y el nuevo plan; valida que el
-- cambio sea posible; actualiza el plan; registra el cambio
-- en HISTORIAL_PLANES.
--
-- Excepcion personalizada (3.2.4):
--   EX_PERFILES_EXCEDEN: el usuario tiene mas perfiles de los
--   que permite el nuevo plan (RN-03).
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE SP_CAMBIAR_PLAN (
    p_id_usuario  IN USUARIOS.id_usuario%TYPE,
    p_id_plan_nuevo IN PLANES.id_plan%TYPE
)
AS
    EX_PERFILES_EXCEDEN EXCEPTION;
    PRAGMA EXCEPTION_INIT(EX_PERFILES_EXCEDEN, -20002);

    v_plan_actual     USUARIOS.id_plan%TYPE;
    v_max_perfiles    PLANES.max_perfiles%TYPE;
    v_perfiles_activos NUMBER;
    v_precio_nuevo    PLANES.precio%TYPE;
    v_dur_dias        PLANES.duracion_dias%TYPE;

BEGIN
    -- 1. Obtener el plan actual del usuario
    SELECT id_plan
      INTO v_plan_actual
      FROM USUARIOS
     WHERE id_usuario = p_id_usuario;

    -- 2. Validar que el nuevo plan exista
    SELECT max_perfiles, precio, duracion_dias
      INTO v_max_perfiles, v_precio_nuevo, v_dur_dias
      FROM PLANES
     WHERE id_plan = p_id_plan_nuevo;

    -- 3. Contar perfiles activos del usuario (RN-03)
    SELECT COUNT(*)
      INTO v_perfiles_activos
      FROM PERFILES
     WHERE id_usuario = p_id_usuario;

    IF v_perfiles_activos > v_max_perfiles THEN
        RAISE_APPLICATION_ERROR(-20002,
            'El usuario tiene ' || v_perfiles_activos ||
            ' perfiles; el nuevo plan permite maximo ' || v_max_perfiles ||
            '. Elimine ' || (v_perfiles_activos - v_max_perfiles) ||
            ' perfil(es) antes de cambiar al plan.');
    END IF;

    -- 4. Cerrar el registro vigente en HISTORIAL_PLANES
    UPDATE HISTORIAL_PLANES
       SET fecha_fin = TRUNC(SYSDATE)
     WHERE id_usuario = p_id_usuario
       AND fecha_fin  IS NULL;

    -- 5. Actualizar el plan en USUARIOS
    UPDATE USUARIOS
       SET id_plan          = p_id_plan_nuevo,
           fecha_vencimiento = SYSDATE + v_dur_dias
     WHERE id_usuario = p_id_usuario;

    -- 6. Abrir nuevo registro en HISTORIAL_PLANES
    INSERT INTO HISTORIAL_PLANES (
        id_historial, id_usuario, id_plan, fecha_inicio, fecha_fin
    ) VALUES (
        (SELECT NVL(MAX(id_historial), 0) + 1 FROM HISTORIAL_PLANES),
        p_id_usuario, p_id_plan_nuevo, SYSDATE, NULL
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Plan actualizado correctamente. '
     || 'Plan anterior: ' || v_plan_actual
     || ' → Nuevo plan: ' || p_id_plan_nuevo
    );

EXCEPTION
    WHEN EX_PERFILES_EXCEDEN THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR (RN-03): ' || SQLERRM);
        RAISE;
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Usuario o plan no encontrado.');
        RAISE;
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR inesperado: ' || SQLERRM);
        RAISE;
END SP_CAMBIAR_PLAN;
/


-- ------------------------------------------------------------
-- SP_REPORTE_CONSUMO
--
-- Recibe un id de usuario y un rango de fechas; genera un
-- reporte detallado de reproducciones por perfil agrupadas
-- por categoria con totales de tiempo consumido.
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE SP_REPORTE_CONSUMO (
    p_id_usuario   IN USUARIOS.id_usuario%TYPE,
    p_fecha_inicio IN DATE,
    p_fecha_fin    IN DATE
)
AS
    v_nombre_usuario  USUARIOS.nombre%TYPE;
    v_total_min_user  NUMBER := 0;
    v_total_repro_user NUMBER := 0;

    -- Cursor de perfiles del usuario
    CURSOR cur_perfiles IS
        SELECT id_perfil, nombre, tipo
          FROM PERFILES
         WHERE id_usuario = p_id_usuario
         ORDER BY nombre;

    -- Cursor de consumo por categoria para un perfil dado
    CURSOR cur_consumo (p_perfil NUMBER) IS
        SELECT
            cat.nombre_categoria,
            COUNT(r.id_reproduccion)        AS total_reproducciones,
            SUM(
                CASE
                    WHEN r.fecha_hora_fin IS NOT NULL
                    THEN (CAST(r.fecha_hora_fin AS DATE) -
                          CAST(r.fecha_hora_inicio AS DATE)) * 1440
                    ELSE 0
                END
            )                               AS minutos_totales,
            SUM(CASE WHEN r.porcentaje_avance >= 90 THEN 1 ELSE 0 END)
                                            AS completas,
            ROUND(AVG(r.porcentaje_avance), 1) AS avance_promedio
        FROM   REPRODUCCIONES  r
        JOIN   CONTENIDO       c   ON r.id_contenido = c.id_contenido
        JOIN   CATEGORIAS      cat ON c.id_categoria  = cat.id_categoria
        WHERE  r.id_perfil        = p_perfil
          AND  r.fecha_hora_inicio >= CAST(p_fecha_inicio AS TIMESTAMP)
          AND  r.fecha_hora_inicio <  CAST(p_fecha_fin + 1 AS TIMESTAMP)
        GROUP BY cat.nombre_categoria
        ORDER BY minutos_totales DESC;

    v_total_min_perfil   NUMBER;
    v_total_repro_perfil NUMBER;

BEGIN
    -- Validar que el usuario exista
    SELECT nombre INTO v_nombre_usuario
      FROM USUARIOS WHERE id_usuario = p_id_usuario;

    DBMS_OUTPUT.PUT_LINE(
        CHR(10) || '=========================================='
    );
    DBMS_OUTPUT.PUT_LINE(
        'REPORTE DE CONSUMO — ' || v_nombre_usuario
    );
    DBMS_OUTPUT.PUT_LINE(
        'Periodo: ' || TO_CHAR(p_fecha_inicio, 'DD/MM/YYYY') ||
        ' al '      || TO_CHAR(p_fecha_fin,    'DD/MM/YYYY')
    );
    DBMS_OUTPUT.PUT_LINE('==========================================');

    FOR perf IN cur_perfiles LOOP
        v_total_min_perfil   := 0;
        v_total_repro_perfil := 0;

        DBMS_OUTPUT.PUT_LINE(
            CHR(10) || '  PERFIL: ' || perf.nombre ||
            ' (' || perf.tipo || ')'
        );
        DBMS_OUTPUT.PUT_LINE(
            '  ' || RPAD('CATEGORIA', 20) ||
            LPAD('REPRODUC.', 12) ||
            LPAD('MINUTOS',   10) ||
            LPAD('COMPLETAS',  11) ||
            LPAD('AVG %',       8)
        );
        DBMS_OUTPUT.PUT_LINE('  ' || RPAD('-', 61, '-'));

        FOR cons IN cur_consumo(perf.id_perfil) LOOP
            DBMS_OUTPUT.PUT_LINE(
                '  ' || RPAD(cons.nombre_categoria, 20) ||
                LPAD(cons.total_reproducciones,  12) ||
                LPAD(ROUND(cons.minutos_totales), 10) ||
                LPAD(cons.completas,              11) ||
                LPAD(cons.avance_promedio,         8)
            );
            v_total_min_perfil   := v_total_min_perfil + cons.minutos_totales;
            v_total_repro_perfil := v_total_repro_perfil + cons.total_reproducciones;
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('  ' || RPAD('-', 61, '-'));
        DBMS_OUTPUT.PUT_LINE(
            '  TOTAL PERFIL' ||
            LPAD(v_total_repro_perfil, 19) ||
            LPAD(ROUND(v_total_min_perfil), 10)
        );

        v_total_min_user  := v_total_min_user  + v_total_min_perfil;
        v_total_repro_user := v_total_repro_user + v_total_repro_perfil;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || '==========================================');
    DBMS_OUTPUT.PUT_LINE(
        'TOTAL USUARIO — Reproducciones: ' || v_total_repro_user ||
        ' | Minutos: ' || ROUND(v_total_min_user) ||
        ' (' || ROUND(v_total_min_user / 60, 1) || ' horas)'
    );

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Usuario con ID ' || p_id_usuario || ' no encontrado.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END SP_REPORTE_CONSUMO;
/


-- ============================================================
-- 3.2.3  FUNCIONES
-- ============================================================

-- ------------------------------------------------------------
-- FN_CALCULAR_MONTO
--
-- Retorna el monto a cobrar en el proximo mes considerando:
--   - Precio base del plan activo
--   - Descuento por antiguedad: >12 meses → 10 %;
--                               >24 meses → 15 %
--   - Descuento por beneficio de referido pendiente
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_CALCULAR_MONTO (
    p_id_usuario IN USUARIOS.id_usuario%TYPE
) RETURN NUMBER
AS
    v_precio_plan     PLANES.precio%TYPE;
    v_fecha_registro  USUARIOS.fecha_registro%TYPE;
    v_meses_antigued  NUMBER;
    v_descuento_pct   NUMBER := 0;
    v_descuento_ref   NUMBER := 0;
    v_monto_final     NUMBER;

BEGIN
    -- Obtener precio del plan y fecha de registro
    SELECT pl.precio, u.fecha_registro
      INTO v_precio_plan, v_fecha_registro
      FROM USUARIOS  u
      JOIN PLANES    pl ON u.id_plan = pl.id_plan
     WHERE u.id_usuario = p_id_usuario;

    -- Calcular meses de antiguedad
    v_meses_antigued := MONTHS_BETWEEN(SYSDATE, v_fecha_registro);

    -- Descuento por antiguedad
    IF v_meses_antigued > 24 THEN
        v_descuento_pct := 15;
    ELSIF v_meses_antigued > 12 THEN
        v_descuento_pct := 10;
    END IF;

    -- Descuento por beneficio de referido pendiente
    BEGIN
        SELECT NVL(valor_descuento, 0)
          INTO v_descuento_ref
          FROM BENEFICIOS_REFERIDOS
         WHERE id_usuario = p_id_usuario
           AND estado     = 'pendiente'
           AND ROWNUM     = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_descuento_ref := 0;
    END;

    -- Aplicar el mayor descuento (no se acumulan)
    v_descuento_pct := GREATEST(v_descuento_pct, v_descuento_ref);

    -- Calcular monto final
    v_monto_final := ROUND(v_precio_plan * (1 - v_descuento_pct / 100), 2);

    RETURN v_monto_final;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN NULL;
END FN_CALCULAR_MONTO;
/

-- Ejemplo de uso
SELECT
    u.nombre,
    pl.nombre_plan,
    pl.precio                       AS precio_base,
    FN_CALCULAR_MONTO(u.id_usuario) AS monto_proximo_cobro
FROM USUARIOS u
JOIN PLANES pl ON u.id_plan = pl.id_plan
WHERE u.estado = 'ACTIVO';


-- ------------------------------------------------------------
-- FN_CONTENIDO_RECOMENDADO
--
-- Retorna el titulo del contenido mas afin al perfil,
-- basandose en los generos de lo que mas ha reproducido.
--
-- Algoritmo:
--   1. Identificar el genero mas frecuente en las
--      reproducciones completadas del perfil (>= 90 %).
--   2. Buscar contenido de ese genero que el perfil aun
--      no haya reproducido.
--   3. Ordenar por popularidad y retornar el primero.
--   Se respeta la restriccion de clasificacion de edad
--   para perfiles infantiles (RN-04).
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_CONTENIDO_RECOMENDADO (
    p_id_perfil IN PERFILES.id_perfil%TYPE
) RETURN VARCHAR2
AS
    v_tipo_perfil   PERFILES.tipo%TYPE;
    v_id_genero     GENEROS.id_genero%TYPE;
    v_titulo        CONTENIDO.titulo%TYPE;

BEGIN
    -- Obtener tipo de perfil para aplicar restriccion de edad (RN-04)
    SELECT tipo INTO v_tipo_perfil
      FROM PERFILES WHERE id_perfil = p_id_perfil;

    -- Genero mas reproducido por el perfil (reproducciones completas)
    SELECT id_genero
      INTO v_id_genero
      FROM (
          SELECT
              cg.id_genero,
              COUNT(*) AS frecuencia
          FROM   REPRODUCCIONES  r
          JOIN   CONTENIDO_GENEROS cg ON r.id_contenido = cg.id_contenido
          WHERE  r.id_perfil        = p_id_perfil
            AND  r.porcentaje_avance >= 90
          GROUP BY cg.id_genero
          ORDER BY frecuencia DESC
      )
     WHERE ROWNUM = 1;

    -- Contenido mas popular de ese genero no reproducido por el perfil
    -- Si el perfil es infantil, se filtran clasificaciones +16 y +18
    SELECT titulo
      INTO v_titulo
      FROM (
          SELECT c.titulo
            FROM CONTENIDO         c
            JOIN CONTENIDO_GENEROS cg ON c.id_contenido = cg.id_contenido
           WHERE cg.id_genero = v_id_genero
             AND c.id_contenido NOT IN (
                     SELECT id_contenido
                       FROM REPRODUCCIONES
                      WHERE id_perfil = p_id_perfil
                 )
             AND (
                     v_tipo_perfil = 'adulto'
                  OR c.clasificacion_edad IN ('TP', '+7', '+13')
                 )
           ORDER BY c.popularidad DESC
      )
     WHERE ROWNUM = 1;

    RETURN v_titulo;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Si no hay reproduccion previa o no hay contenido nuevo,
        -- se retorna el mas popular de la plataforma
        BEGIN
            SELECT titulo INTO v_titulo
              FROM (
                  SELECT titulo FROM CONTENIDO
                  ORDER BY popularidad DESC
              )
             WHERE ROWNUM = 1;
            RETURN v_titulo;
        EXCEPTION
            WHEN OTHERS THEN RETURN NULL;
        END;
    WHEN OTHERS THEN
        RETURN NULL;
END FN_CONTENIDO_RECOMENDADO;
/

-- Ejemplo de uso
SELECT
    p.id_perfil,
    p.nombre                                    AS perfil,
    p.tipo,
    FN_CONTENIDO_RECOMENDADO(p.id_perfil)       AS recomendacion
FROM PERFILES p;


-- ============================================================
-- 3.2.5  DISPARADORES
-- ============================================================

-- ------------------------------------------------------------
-- TRG-01: Verificar cuenta activa antes de reproducir (RN-01)
-- Nivel: fila (FOR EACH ROW)
-- Evento: BEFORE INSERT en REPRODUCCIONES
--
-- Logica: obtiene el id_usuario a partir del perfil que inserta
-- la reproduccion y valida que la cuenta este ACTIVA. Si no,
-- lanza un error que Oracle convierte en rollback de la sentencia.
-- ------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_REPRO_CUENTA_ACTIVA
BEFORE INSERT ON REPRODUCCIONES
FOR EACH ROW
DECLARE
    v_estado  USUARIOS.estado%TYPE;
BEGIN
    SELECT u.estado
      INTO v_estado
      FROM USUARIOS  u
      JOIN PERFILES  p ON u.id_usuario = p.id_usuario
     WHERE p.id_perfil = :NEW.id_perfil;

    IF v_estado <> 'ACTIVO' THEN
        RAISE_APPLICATION_ERROR(-20010,
            'La cuenta del usuario no esta ACTIVA. '
         || 'No es posible iniciar una reproduccion.');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20011,
            'El perfil ' || :NEW.id_perfil || ' no existe o no tiene usuario asociado.');
END TRG_REPRO_CUENTA_ACTIVA;
/


-- ------------------------------------------------------------
-- TRG-02: Limite de perfiles por plan (RN-02 / RN-03)
-- Nivel: fila (FOR EACH ROW)
-- Evento: BEFORE INSERT en PERFILES
--
-- Logica: cuenta cuantos perfiles tiene ya el usuario y lo
-- compara con el max_perfiles del plan activo. Si se supera,
-- rechaza la insercion con un mensaje que indica el limite.
-- ------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_PERFIL_LIMITE_PLAN
BEFORE INSERT ON PERFILES
FOR EACH ROW
DECLARE
    v_max_perfiles   PLANES.max_perfiles%TYPE;
    v_count_perfiles NUMBER;
    v_nombre_plan    PLANES.nombre_plan%TYPE;
BEGIN
    -- Obtener el limite del plan activo del usuario
    SELECT pl.max_perfiles, pl.nombre_plan
      INTO v_max_perfiles, v_nombre_plan
      FROM USUARIOS  u
      JOIN PLANES    pl ON u.id_plan = pl.id_plan
     WHERE u.id_usuario = :NEW.id_usuario;

    -- Contar perfiles actuales del usuario
    SELECT COUNT(*)
      INTO v_count_perfiles
      FROM PERFILES
     WHERE id_usuario = :NEW.id_usuario;

    IF v_count_perfiles >= v_max_perfiles THEN
        RAISE_APPLICATION_ERROR(-20020,
            'El plan ' || v_nombre_plan ||
            ' permite maximo ' || v_max_perfiles || ' perfil(es). '
         || 'El usuario ya tiene ' || v_count_perfiles || '.');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20021,
            'El usuario ' || :NEW.id_usuario ||
            ' no tiene un plan activo asignado.');
END TRG_PERFIL_LIMITE_PLAN;
/


-- ------------------------------------------------------------
-- TRG-03: Validar porcentaje de avance antes de calificar (RN-05)
-- Nivel: fila (FOR EACH ROW)
-- Evento: BEFORE INSERT en CALIFICACIONES
--
-- Logica: busca si el perfil tiene al menos una reproduccion
-- con porcentaje_avance >= 50 % para el contenido que intenta
-- calificar. Si no la tiene, rechaza la calificacion.
-- ------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_CALIF_REQUIERE_50PCT
BEFORE INSERT ON CALIFICACIONES
FOR EACH ROW
DECLARE
    v_max_avance NUMBER;
BEGIN
    SELECT NVL(MAX(porcentaje_avance), 0)
      INTO v_max_avance
      FROM REPRODUCCIONES
     WHERE id_perfil    = :NEW.id_perfil
       AND id_contenido = :NEW.id_contenido;

    IF v_max_avance < 50 THEN
        RAISE_APPLICATION_ERROR(-20030,
            'El perfil debe haber reproducido al menos el 50 % '
         || 'del contenido para poder calificarlo. '
         || 'Avance maximo registrado: ' || v_max_avance || ' %.');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20031,
            'No existe ninguna reproduccion de este contenido para el perfil indicado.');
END TRG_CALIF_REQUIERE_50PCT;
/


-- ------------------------------------------------------------
-- TRG-04: Actualizar estado y fecha de pago tras pago exitoso
-- Nivel: sentencia (no FOR EACH ROW)
-- Evento: AFTER INSERT en PAGOS
--
-- Se usa nivel de sentencia porque la actualizacion de USUARIOS
-- aplica para todos los registros insertados en la sentencia.
-- El trigger usa un cursor interno para recorrer los pagos
-- exitosos recien insertados, identificados con ORA_ROWSCN o
-- con una tabla temporal de sesion.
--
-- Nota: en Oracle, un trigger AFTER de sentencia no tiene
-- acceso a :NEW/:OLD. Se consulta PAGOS por estado y fecha
-- del dia actual para identificar los pagos recien procesados.
-- ------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_PAGO_ACTIVAR_CUENTA
AFTER INSERT ON PAGOS
DECLARE
    CURSOR cur_pagos_hoy IS
        SELECT DISTINCT id_usuario
          FROM PAGOS
         WHERE estado     = 'exitoso'
           AND TRUNC(fecha_pago) = TRUNC(SYSDATE);
BEGIN
    FOR rec IN cur_pagos_hoy LOOP
        UPDATE USUARIOS
           SET estado            = 'ACTIVO',
               fecha_ultimo_pago = SYSDATE,
               -- Extender la vigencia segun el plan activo
               fecha_vencimiento = SYSDATE + (
                   SELECT duracion_dias
                     FROM PLANES
                    WHERE id_plan = (
                        SELECT id_plan FROM USUARIOS
                         WHERE id_usuario = rec.id_usuario
                    )
               )
         WHERE id_usuario = rec.id_usuario;
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        -- El trigger no hace ROLLBACK por si solo; Oracle maneja
        -- el rollback de la sentencia original si se re-lanza.
        RAISE_APPLICATION_ERROR(-20040,
            'Error al actualizar estado de cuenta tras pago: ' || SQLERRM);
END TRG_PAGO_ACTIVAR_CUENTA;
/


-- ------------------------------------------------------------
-- TRG-05: Validar rol de moderador en reportes (RN-10)
-- Nivel: fila (FOR EACH ROW)
-- Evento: BEFORE INSERT OR UPDATE en REPORTES_INAPROPIADO
--
-- Logica: si se asigna un moderador al reporte, verifica que
-- el usuario tenga el rol de moderador (id_rol_usuario que
-- corresponda al rol 'moderador' en ROLES_USUARIO). Esto
-- cierra la brecha que existe en el DDL, donde la FK solo
-- garantiza que el usuario exista pero no que sea moderador.
-- ------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_REPORTE_VALIDA_MODERADOR
BEFORE INSERT OR UPDATE OF id_usuario_modera ON REPORTES_INAPROPIADO
FOR EACH ROW
DECLARE
    v_nombre_rol  ROLES_USUARIO.nombre_rol%TYPE;
BEGIN
    -- Solo validar si se esta asignando un moderador
    IF :NEW.id_usuario_modera IS NOT NULL THEN
        SELECT ru.nombre_rol
          INTO v_nombre_rol
          FROM USUARIOS      u
          JOIN ROLES_USUARIO ru ON u.id_rol_usuario = ru.id_rol_usuario
         WHERE u.id_usuario = :NEW.id_usuario_modera;

        IF UPPER(v_nombre_rol) <> 'MODERADOR' THEN
            RAISE_APPLICATION_ERROR(-20050,
                'El usuario ' || :NEW.id_usuario_modera ||
                ' no tiene el rol de moderador. '
             || 'Solo los moderadores pueden gestionar reportes.');
        END IF;
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20051,
            'El usuario asignado como moderador no existe.');
END TRG_REPORTE_VALIDA_MODERADOR;
/


-- ------------------------------------------------------------
-- TRG-06 (adicional): Validar supervisor del mismo departamento
--                     al insertar o actualizar un empleado (RN-12)
-- Nivel: fila (FOR EACH ROW)
-- Evento: BEFORE INSERT OR UPDATE en EMPLEADOS
--
-- El DDL no puede verificar con un CHECK que el supervisor
-- pertenezca al mismo departamento porque eso requiere consultar
-- otra fila de la misma tabla. Este trigger cubre esa brecha.
-- ------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_EMPLEADO_MISMO_DEPTO
BEFORE INSERT OR UPDATE OF id_supervisor ON EMPLEADOS
FOR EACH ROW
DECLARE
    v_depto_supervisor  EMPLEADOS.id_departamento%TYPE;
BEGIN
    IF :NEW.id_supervisor IS NOT NULL THEN
        SELECT id_departamento
          INTO v_depto_supervisor
          FROM EMPLEADOS
         WHERE id_empleado = :NEW.id_supervisor;

        IF v_depto_supervisor <> :NEW.id_departamento THEN
            RAISE_APPLICATION_ERROR(-20060,
                'El supervisor (ID ' || :NEW.id_supervisor ||
                ') pertenece al departamento ' || v_depto_supervisor ||
                '; debe pertenecer al mismo departamento que el empleado (' ||
                :NEW.id_departamento || ').');
        END IF;
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20061,
            'El empleado asignado como supervisor no existe.');
END TRG_EMPLEADO_MISMO_DEPTO;
/


-- ============================================================
-- FIN DEL SCRIPT — Nucleo 2
-- ============================================================