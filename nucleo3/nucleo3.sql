-- ============================================================
-- QUINDIOFLIX — Nucleo 3: Transacciones y Concurrencia
-- Base de Datos II — Universidad del Quindio
-- Semestre 2026-1
-- ============================================================

-- ============================================================
-- 3.3.1.a  TRANSACCIÓN: Registro completo de usuario
-- Politica: todo o nada. Si cualquier paso falla, ROLLBACK.
-- ============================================================
DECLARE
    v_id_usuario    NUMBER;
    v_id_perfil     NUMBER;
    v_id_pago       NUMBER;
    v_precio_plan   PLANES.precio%TYPE;
    v_dur_dias      PLANES.duracion_dias%TYPE;
BEGIN
    -- Obtener datos del plan
    SELECT precio, duracion_dias INTO v_precio_plan, v_dur_dias
    FROM PLANES WHERE id_plan = 2;  -- plan Estandar

    -- Generar IDs
    SELECT NVL(MAX(id_usuario), 0) + 1 INTO v_id_usuario FROM USUARIOS;
    SELECT NVL(MAX(id_perfil), 0) + 1 INTO v_id_perfil FROM PERFILES;
    SELECT NVL(MAX(id_pago), 0) + 1 INTO v_id_pago FROM PAGOS;

    -- Insertar usuario
    INSERT INTO USUARIOS (id_usuario, nombre, email, ciudad, password_hash, 
                          id_plan, estado, fecha_vencimiento, fecha_registro,
                          fecha_ultimo_pago, saldo_a_favor, id_rol_usuario)
    VALUES (v_id_usuario, 'Ana Restrepo', 'ana@ejemplo.com', 'Armenia', 'hash123',
            2, 'ACTIVO', SYSDATE + v_dur_dias, SYSDATE, SYSDATE, 0, 1);

    -- Insertar perfil predeterminado
    INSERT INTO PERFILES (id_perfil, id_usuario, nombre, tipo)
    VALUES (v_id_perfil, v_id_usuario, 'Mi perfil', 'adulto');

    -- Insertar primer pago
    INSERT INTO PAGOS (id_pago, id_usuario, id_plan, fecha_pago, monto, metodo_pago, estado)
    VALUES (v_id_pago, v_id_usuario, 2, SYSDATE, v_precio_plan, 'PSE', 'exitoso');

    -- Insertar historial de plan
    INSERT INTO HISTORIAL_PLANES (id_historial, id_usuario, id_plan, fecha_inicio, fecha_fin)
    VALUES ((SELECT NVL(MAX(id_historial), 0) + 1 FROM HISTORIAL_PLANES),
            v_id_usuario, 2, SYSDATE, NULL);

    COMMIT;  -- Confirma todo

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;  -- Deshace todo
        RAISE;
END;
/


-- ============================================================
-- 3.3.1.b  TRANSACCIÓN: Renovación mensual con SAVEPOINT
-- Politica: SAVEPOINT por usuario. Si uno falla, solo ese se revierte.
-- ============================================================
DECLARE
    v_monto     NUMBER;
    v_id_pago   NUMBER;
    v_sp_name   VARCHAR2(50);
    
    CURSOR cur_renovar IS
        SELECT u.id_usuario, u.nombre, u.id_plan, pl.nombre_plan
        FROM USUARIOS u
        JOIN PLANES pl ON u.id_plan = pl.id_plan
        WHERE u.estado = 'ACTIVO'
          AND (u.fecha_vencimiento IS NULL OR u.fecha_vencimiento <= SYSDATE);
BEGIN
    FOR usr IN cur_renovar LOOP
        v_sp_name := 'SP_USR_' || usr.id_usuario;
        EXECUTE IMMEDIATE 'SAVEPOINT ' || v_sp_name;
        
        BEGIN
            -- Calcular monto (con descuentos por antigüedad)
            v_monto := FN_CALCULAR_MONTO(usr.id_usuario);
            
            SELECT NVL(MAX(id_pago), 0) + 1 INTO v_id_pago FROM PAGOS;
            
            -- Registrar pago
            INSERT INTO PAGOS (id_pago, id_usuario, id_plan, fecha_pago, monto, metodo_pago, estado)
            VALUES (v_id_pago, usr.id_usuario, usr.id_plan, SYSDATE, v_monto, 'tarjeta', 'exitoso');
            
            -- Actualizar fecha vencimiento
            UPDATE USUARIOS
            SET fecha_vencimiento = SYSDATE + 30,
                fecha_ultimo_pago = SYSDATE
            WHERE id_usuario = usr.id_usuario;
            
        EXCEPTION
            WHEN OTHERS THEN
                EXECUTE IMMEDIATE 'ROLLBACK TO ' || v_sp_name;  -- Solo revierte este usuario
        END;
    END LOOP;
    
    COMMIT;  -- Confirma todos los exitosos
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;  -- Error grave, revierte todo
        RAISE;
END;
/


-- ============================================================
-- 3.3.1.c  TRANSACCIÓN: Eliminación completa de cuenta
-- Politica: todo o nada. Orden inverso a las FK.
-- ============================================================
DECLARE
    v_id_usuario CONSTANT NUMBER := 1;  -- Usuario a eliminar
BEGIN
    -- Eliminar datos dependientes (orden inverso a FK)
    DELETE FROM CALIFICACIONES WHERE id_perfil IN (SELECT id_perfil FROM PERFILES WHERE id_usuario = v_id_usuario);
    DELETE FROM FAVORITOS      WHERE id_perfil IN (SELECT id_perfil FROM PERFILES WHERE id_usuario = v_id_usuario);
    DELETE FROM REPRODUCCIONES WHERE id_perfil IN (SELECT id_perfil FROM PERFILES WHERE id_usuario = v_id_usuario);
    DELETE FROM REPORTES_INAPROPIADO WHERE id_perfil_reporta IN (SELECT id_perfil FROM PERFILES WHERE id_usuario = v_id_usuario);
    DELETE FROM PERFILES       WHERE id_usuario = v_id_usuario;
    DELETE FROM BENEFICIOS_REFERIDOS WHERE id_usuario = v_id_usuario;
    DELETE FROM REFERIDOS      WHERE id_usuario_referidor = v_id_usuario OR id_usuario_referido = v_id_usuario;
    DELETE FROM HISTORIAL_PLANES WHERE id_usuario = v_id_usuario;
    DELETE FROM PAGOS          WHERE id_usuario = v_id_usuario;
    DELETE FROM USUARIOS       WHERE id_usuario = v_id_usuario;  -- Registro raíz
    
    COMMIT;  -- Confirma todo
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;  -- Deshace todo
        RAISE;
END;
/


-- ============================================================
-- 3.3.2  ESCENARIO DE CONCURRENCIA
-- Dos sesiones intentan cambiar el plan del mismo usuario.
-- Solución: SELECT FOR UPDATE
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- [SESION A] — Ejecutar en primera ventana
-- ────────────────────────────────────────────────────────────
DECLARE
    v_plan_actual NUMBER;
BEGIN
    SELECT id_plan INTO v_plan_actual
    FROM USUARIOS WHERE id_usuario = 1
    FOR UPDATE;  -- Bloquea la fila
    
    UPDATE USUARIOS SET id_plan = 3 WHERE id_usuario = 1;  -- Cambia a Premium
    
    COMMIT;  -- Libera el bloqueo
END;
/

-- ────────────────────────────────────────────────────────────
-- [SESION B] — Ejecutar en segunda ventana MIENTRAS A está activa
-- ────────────────────────────────────────────────────────────
DECLARE
    v_plan_actual NUMBER;
BEGIN
    -- Espera hasta 10 segundos a que A libere el bloqueo
    SELECT id_plan INTO v_plan_actual
    FROM USUARIOS WHERE id_usuario = 1
    FOR UPDATE WAIT 10;
    
    -- Ahora lee el valor actualizado por A (id_plan = 3)
    UPDATE USUARIOS SET id_plan = 1 WHERE id_usuario = 1;  -- Intenta downgrade
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -30006 THEN  -- Timeout
            DBMS_OUTPUT.PUT_LINE('Recurso ocupado, reintente mas tarde');
        END IF;
        ROLLBACK;
END;
/

-- ============================================================
-- FIN NUCLEO 3
-- ============================================================