-- ============================================================
-- QUINDIOFLIX — Script de Población de Datos (v2 CORREGIDA)
-- Base de Datos II — Universidad del Quindio
-- Semestre 2026-1
--
-- Correcciones respecto a v1:
--   1. Se agrega población de ROLES_USUARIO antes de USUARIOS
--   2. Se agregan bloques BEGIN/END a todos los DBMS_OUTPUT
--   3. El orden de DELETE respeta las FK (hijos antes que padres)
--   4. FAVORITOS: se corrige el cursor inválido
--   5. CALIFICACIONES y FAVORITOS: se evitan duplicados con
--      control de pares ya insertados
--   6. REPRODUCCIONES: se usa un cursor sobre IDs reales de PERFILES
--   7. Se agrega población básica de ROLES y EMPLEADOS para FK
-- ============================================================

SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO POBLACION DE DATOS v2 ===');
END;
/

-- ============================================================
-- 0. DELETE EN ORDEN INVERSO A LAS DEPENDENCIAS (hijos primero)
-- ============================================================
BEGIN
EXECUTE IMMEDIATE 'DELETE FROM FAVORITOS';
EXECUTE IMMEDIATE 'DELETE FROM CALIFICACIONES';
EXECUTE IMMEDIATE 'DELETE FROM REPRODUCCIONES';
EXECUTE IMMEDIATE 'DELETE FROM EPISODIOS';
EXECUTE IMMEDIATE 'DELETE FROM TEMPORADAS';
EXECUTE IMMEDIATE 'DELETE FROM CONTENIDO_GENEROS';
EXECUTE IMMEDIATE 'DELETE FROM CONTENIDO_RELACIONADO';
EXECUTE IMMEDIATE 'DELETE FROM CONTENIDO';
EXECUTE IMMEDIATE 'DELETE FROM PAGOS';
EXECUTE IMMEDIATE 'DELETE FROM HISTORIAL_PLANES';
EXECUTE IMMEDIATE 'DELETE FROM BENEFICIOS_REFERIDOS';
EXECUTE IMMEDIATE 'DELETE FROM REFERIDOS';
EXECUTE IMMEDIATE 'DELETE FROM PERFILES';
EXECUTE IMMEDIATE 'DELETE FROM REPORTES_INAPROPIADO';
EXECUTE IMMEDIATE 'DELETE FROM USUARIOS';
EXECUTE IMMEDIATE 'DELETE FROM GENEROS';
EXECUTE IMMEDIATE 'DELETE FROM CATEGORIAS';
EXECUTE IMMEDIATE 'DELETE FROM EMPLEADOS';
EXECUTE IMMEDIATE 'DELETE FROM DEPARTAMENTOS';
EXECUTE IMMEDIATE 'DELETE FROM ROLES';
EXECUTE IMMEDIATE 'DELETE FROM ROLES_USUARIO';
EXECUTE IMMEDIATE 'DELETE FROM PLANES';
COMMIT;
DBMS_OUTPUT.PUT_LINE('✓ Tablas limpiadas en orden correcto');
END;
/


-- ============================================================
-- 1. PLANES (3 registros)
-- ============================================================
INSERT INTO PLANES (id_plan, nombre_plan, max_pantallas, max_perfiles, precio, duracion_dias, calidad_video)
VALUES (1, 'Básico', 1, 2, 9.99, 30, 'SD');

INSERT INTO PLANES (id_plan, nombre_plan, max_pantallas, max_perfiles, precio, duracion_dias, calidad_video)
VALUES (2, 'Estándar', 2, 3, 14.99, 30, 'HD');

INSERT INTO PLANES (id_plan, nombre_plan, max_pantallas, max_perfiles, precio, duracion_dias, calidad_video)
VALUES (3, 'Premium', 4, 5, 19.99, 30, '4K');

COMMIT;

BEGIN
    DBMS_OUTPUT.PUT_LINE('✓ PLANES: 3 registros insertados');
END;
/


-- ============================================================
-- 2. ROLES_USUARIO (NUEVO — requerido por FK en USUARIOS)
-- ============================================================
INSERT INTO ROLES_USUARIO (id_rol_usuario, nombre_rol) VALUES (1, 'suscriptor');
INSERT INTO ROLES_USUARIO (id_rol_usuario, nombre_rol) VALUES (2, 'moderador');

COMMIT;

BEGIN
    DBMS_OUTPUT.PUT_LINE('✓ ROLES_USUARIO: 2 registros insertados');
END;
/


-- ============================================================
-- 3. ROLES de empleados (requerido por FK en EMPLEADOS)
-- ============================================================
INSERT INTO ROLES (id_rol, nombre) VALUES (1, 'Publicador de Contenido');
INSERT INTO ROLES (id_rol, nombre) VALUES (2, 'Soporte Técnico');
INSERT INTO ROLES (id_rol, nombre) VALUES (3, 'Administrador');

COMMIT;

BEGIN
    DBMS_OUTPUT.PUT_LINE('✓ ROLES: 3 registros insertados');
END;
/


-- ============================================================
-- 4. DEPARTAMENTOS y EMPLEADOS (mínimo para FK de CONTENIDO)
-- Se insertan sin jefe primero; luego se actualiza el jefe.
-- ============================================================
INSERT INTO DEPARTAMENTOS (id_departamento, nombre_departamento, id_empleado_jefe)
VALUES (1, 'Contenido', NULL);

INSERT INTO DEPARTAMENTOS (id_departamento, nombre_departamento, id_empleado_jefe)
VALUES (2, 'Soporte', NULL);

INSERT INTO DEPARTAMENTOS (id_departamento, nombre_departamento, id_empleado_jefe)
VALUES (3, 'Tecnología', NULL);

COMMIT;

INSERT INTO EMPLEADOS (id_empleado, nombre, cargo, id_departamento, id_supervisor, id_rol)
VALUES (1, 'Laura Ospina', 'Jefe de Contenido', 1, NULL, 1);

INSERT INTO EMPLEADOS (id_empleado, nombre, cargo, id_departamento, id_supervisor, id_rol)
VALUES (2, 'Carlos Ruiz', 'Publicador', 1, 1, 1);

INSERT INTO EMPLEADOS (id_empleado, nombre, cargo, id_departamento, id_supervisor, id_rol)
VALUES (3, 'Ana Gómez', 'Jefe de Soporte', 2, NULL, 2);

INSERT INTO EMPLEADOS (id_empleado, nombre, cargo, id_departamento, id_supervisor, id_rol)
VALUES (4, 'Pedro Salazar', 'Administrador', 3, NULL, 3);

COMMIT;

-- Ahora se asignan los jefes de departamento
UPDATE DEPARTAMENTOS SET id_empleado_jefe = 1 WHERE id_departamento = 1;
UPDATE DEPARTAMENTOS SET id_empleado_jefe = 3 WHERE id_departamento = 2;
UPDATE DEPARTAMENTOS SET id_empleado_jefe = 4 WHERE id_departamento = 3;

COMMIT;

BEGIN
    DBMS_OUTPUT.PUT_LINE('✓ DEPARTAMENTOS y EMPLEADOS: registros insertados');
END;
/


-- ============================================================
-- 5. CATEGORIAS (5 registros)
-- ============================================================
INSERT INTO CATEGORIAS (id_categoria, nombre_categoria) VALUES (1, 'Películas');
INSERT INTO CATEGORIAS (id_categoria, nombre_categoria) VALUES (2, 'Series');
INSERT INTO CATEGORIAS (id_categoria, nombre_categoria) VALUES (3, 'Documentales');
INSERT INTO CATEGORIAS (id_categoria, nombre_categoria) VALUES (4, 'Música');
INSERT INTO CATEGORIAS (id_categoria, nombre_categoria) VALUES (5, 'Podcasts');

COMMIT;

BEGIN
    DBMS_OUTPUT.PUT_LINE('✓ CATEGORIAS: 5 registros insertados');
END;
/


-- ============================================================
-- 6. GENEROS (8 registros)
-- ============================================================
INSERT INTO GENEROS (id_genero, nombre_genero) VALUES (1, 'Acción');
INSERT INTO GENEROS (id_genero, nombre_genero) VALUES (2, 'Comedia');
INSERT INTO GENEROS (id_genero, nombre_genero) VALUES (3, 'Drama');
INSERT INTO GENEROS (id_genero, nombre_genero) VALUES (4, 'Suspenso');
INSERT INTO GENEROS (id_genero, nombre_genero) VALUES (5, 'Romance');
INSERT INTO GENEROS (id_genero, nombre_genero) VALUES (6, 'Ciencia Ficción');
INSERT INTO GENEROS (id_genero, nombre_genero) VALUES (7, 'Terror');
INSERT INTO GENEROS (id_genero, nombre_genero) VALUES (8, 'Infantil');

COMMIT;

BEGIN
    DBMS_OUTPUT.PUT_LINE('✓ GENEROS: 8 registros insertados');
END;
/


-- ============================================================
-- 7. USUARIOS (30 registros)
-- Ciudades: Armenia, Pereira, Manizales
-- Planes: 1=Básico, 2=Estándar, 3=Premium (cíclico)
-- id_rol_usuario = 1 (suscriptor) para todos, excepto
-- usuarios 1 y 15 que serán moderadores (rol = 2)
-- ============================================================
DECLARE
TYPE t_str IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;
    v_nombres  t_str;
    v_apellidos t_str;
    v_ciudades  t_str;
    v_fecha_reg DATE;
    v_rol       NUMBER;
BEGIN
    v_nombres(1)  := 'Juan';      v_apellidos(1)  := 'Pérez';
    v_nombres(2)  := 'María';     v_apellidos(2)  := 'González';
    v_nombres(3)  := 'Carlos';    v_apellidos(3)  := 'Rodríguez';
    v_nombres(4)  := 'Ana';       v_apellidos(4)  := 'Martínez';
    v_nombres(5)  := 'Luis';      v_apellidos(5)  := 'López';
    v_nombres(6)  := 'Sofía';     v_apellidos(6)  := 'Díaz';
    v_nombres(7)  := 'Andrés';    v_apellidos(7)  := 'Sánchez';
    v_nombres(8)  := 'Valentina'; v_apellidos(8)  := 'Ramírez';
    v_nombres(9)  := 'David';     v_apellidos(9)  := 'Torres';
    v_nombres(10) := 'Isabella';  v_apellidos(10) := 'Flores';
    v_nombres(11) := 'Jorge';     v_apellidos(11) := 'Vargas';
    v_nombres(12) := 'Camila';    v_apellidos(12) := 'Herrera';
    v_nombres(13) := 'Ricardo';   v_apellidos(13) := 'Mendoza';
    v_nombres(14) := 'Daniela';   v_apellidos(14) := 'Rojas';
    v_nombres(15) := 'Fernando';  v_apellidos(15) := 'Castro';
    v_nombres(16) := 'Gabriela';  v_apellidos(16) := 'Ortiz';
    v_nombres(17) := 'Miguel';    v_apellidos(17) := 'Silva';
    v_nombres(18) := 'Paula';     v_apellidos(18) := 'Muñoz';
    v_nombres(19) := 'Sebastián'; v_apellidos(19) := 'Ríos';
    v_nombres(20) := 'Natalia';   v_apellidos(20) := 'Guzmán';
    v_nombres(21) := 'Diego';     v_apellidos(21) := 'Peña';
    v_nombres(22) := 'Andrea';    v_apellidos(22) := 'Cruz';
    v_nombres(23) := 'Alejandro'; v_apellidos(23) := 'Medina';
    v_nombres(24) := 'Carolina';  v_apellidos(24) := 'Molina';
    v_nombres(25) := 'Pablo';     v_apellidos(25) := 'Suárez';
    v_nombres(26) := 'Laura';     v_apellidos(26) := 'Vega';
    v_nombres(27) := 'Oscar';     v_apellidos(27) := 'Delgado';
    v_nombres(28) := 'Valeria';   v_apellidos(28) := 'Arias';
    v_nombres(29) := 'Héctor';    v_apellidos(29) := 'Cabrera';
    v_nombres(30) := 'Mariana';   v_apellidos(30) := 'Córdoba';

    v_ciudades(1) := 'Armenia';
    v_ciudades(2) := 'Pereira';
    v_ciudades(3) := 'Manizales';

FOR i IN 1..30 LOOP
        v_fecha_reg := SYSDATE - TRUNC(DBMS_RANDOM.VALUE(1, 365));
        -- Usuarios 1 y 15 son moderadores; el resto suscriptores
        v_rol := CASE WHEN i IN (1, 15) THEN 2 ELSE 1 END;

INSERT INTO USUARIOS (
    id_usuario, nombre, email, telefono, fecha_nacimiento,
    ciudad, password_hash, id_plan, estado,
    fecha_vencimiento, fecha_registro, fecha_ultimo_pago,
    saldo_a_favor, id_rol_usuario
) VALUES (
             i,
             v_nombres(i) || ' ' || v_apellidos(i),
             LOWER(v_nombres(i) || '.' || v_apellidos(i) || i || '@ejemplo.com'),
             '300' || LPAD(TRUNC(DBMS_RANDOM.VALUE(1000000, 9999999)), 7, '0'),
             DATE '1980-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, 7300)),
             v_ciudades(MOD(i - 1, 3) + 1),
             'hash_' || DBMS_RANDOM.STRING('X', 8),
             MOD(i - 1, 3) + 1,
             'ACTIVO',
             SYSDATE + TRUNC(DBMS_RANDOM.VALUE(-60, 60)),
             v_fecha_reg,
             v_fecha_reg + TRUNC(DBMS_RANDOM.VALUE(-10, 10)),
             0,
             v_rol
         );
END LOOP;
COMMIT;
DBMS_OUTPUT.PUT_LINE('✓ USUARIOS: 30 registros insertados');
END;
/


-- ============================================================
-- 8. PERFILES (hasta 50 registros, IDs secuenciales y limpios)
-- Se usa un contador controlado para garantizar IDs consecutivos
-- ============================================================
DECLARE
v_id   NUMBER := 1;
    v_tipo VARCHAR2(20);
BEGIN
FOR u IN 1..30 LOOP
        -- Perfil principal: todos los usuarios tienen al menos uno
        INSERT INTO PERFILES (id_perfil, id_usuario, nombre, avatar, tipo)
        VALUES (v_id, u, 'Perfil Principal', NULL, 'adulto');
        v_id := v_id + 1;
        EXIT WHEN v_id > 50;

        -- Segundo perfil para usuarios con plan Estándar o Premium
        IF MOD(u, 3) IN (0, 2) AND v_id <= 50 THEN
            v_tipo := CASE WHEN MOD(u, 7) = 0 THEN 'infantil' ELSE 'adulto' END;
INSERT INTO PERFILES (id_perfil, id_usuario, nombre, avatar, tipo)
VALUES (v_id, u, 'Perfil Secundario', NULL, v_tipo);
v_id := v_id + 1;
            EXIT WHEN v_id > 50;
END IF;

        -- Tercer perfil para usuarios Premium (plan 3)
        IF MOD(u - 1, 3) = 2 AND u <= 20 AND v_id <= 50 THEN
            INSERT INTO PERFILES (id_perfil, id_usuario, nombre, avatar, tipo)
            VALUES (v_id, u, 'Invitado', NULL, 'adulto');
            v_id := v_id + 1;
            EXIT WHEN v_id > 50;
END IF;

        -- Perfil infantil extra
        IF MOD(u, 6) = 0 AND v_id <= 50 THEN
            INSERT INTO PERFILES (id_perfil, id_usuario, nombre, avatar, tipo)
            VALUES (v_id, u, 'Niños', NULL, 'infantil');
            v_id := v_id + 1;
            EXIT WHEN v_id > 50;
END IF;
END LOOP;

    -- Completar hasta 50 si faltan perfiles
    WHILE v_id <= 50 LOOP
        INSERT INTO PERFILES (id_perfil, id_usuario, nombre, avatar, tipo)
        VALUES (v_id, MOD(v_id - 1, 30) + 1, 'Perfil Extra ' || v_id, NULL, 'adulto');
        v_id := v_id + 1;
END LOOP;

COMMIT;
DBMS_OUTPUT.PUT_LINE('✓ PERFILES: 50 registros insertados');
END;
/


-- ============================================================
-- 9. CONTENIDO (40 registros)
-- ============================================================
DECLARE
TYPE t_vc200 IS TABLE OF VARCHAR2(200) INDEX BY PLS_INTEGER;
    TYPE t_num   IS TABLE OF NUMBER        INDEX BY PLS_INTEGER;
    TYPE t_vc10  IS TABLE OF VARCHAR2(10)  INDEX BY PLS_INTEGER;

    v_titulos        t_vc200;
    v_categorias     t_num;
    v_anios          t_num;
    v_clasificaciones t_vc10;
BEGIN
    v_titulos(1)  := 'El Renacer del Dragón';
    v_titulos(2)  := 'Secretos del Océano';
    v_titulos(3)  := 'Risas en el Paraíso';
    v_titulos(4)  := 'El Último Guerrero';
    v_titulos(5)  := 'Amor Prohibido';
    v_titulos(6)  := 'Misterio en la Niebla';
    v_titulos(7)  := 'El Viaje Estelar';
    v_titulos(8)  := 'Terror en la Oscuridad';
    v_titulos(9)  := 'El Documental Perdido';
    v_titulos(10) := 'Sinfonía Nocturna';
    v_titulos(11) := 'Historias de Podcast';
    v_titulos(12) := 'La Casa Embrujada';
    v_titulos(13) := 'El Gran Escape';
    v_titulos(14) := 'Código Enigma';
    v_titulos(15) := 'La Isla del Tesoro';
    v_titulos(16) := 'El Legado';
    v_titulos(17) := 'Sombras del Pasado';
    v_titulos(18) := 'El Planeta Azul';
    v_titulos(19) := 'Comedia en Vivo';
    v_titulos(20) := 'El Jardín Secreto';
    v_titulos(21) := 'La Última Frontera';
    v_titulos(22) := 'Cuentos de la Abuela';
    v_titulos(23) := 'El Enigma de la Esfinge';
    v_titulos(24) := 'Ritmo Latino';
    v_titulos(25) := 'Ciencia para Todos';
    v_titulos(26) := 'El Arte de Vivir';
    v_titulos(27) := 'Misterios Antiguos';
    v_titulos(28) := 'El Reino de Hielo';
    v_titulos(29) := 'Aventura Jurásica';
    v_titulos(30) := 'La Llamada';
    v_titulos(31) := 'El Castillo Errante';
    v_titulos(32) := 'Orígenes';
    v_titulos(33) := 'Entre Copas y Risas';
    v_titulos(34) := 'El Eco del Silencio';
    v_titulos(35) := 'Viaje al Centro';
    v_titulos(36) := 'Los Elegidos';
    v_titulos(37) := 'El Mensajero';
    v_titulos(38) := 'Desafío Extremo';
    v_titulos(39) := 'Almas Gemelas';
    v_titulos(40) := 'El Último Día';

    -- Categorías: 1=Películas, 2=Series, 3=Documentales, 4=Música, 5=Podcasts
    v_categorias(1) :=1; v_categorias(2) :=1; v_categorias(3) :=2; v_categorias(4) :=1;
    v_categorias(5) :=1; v_categorias(6) :=2; v_categorias(7) :=1; v_categorias(8) :=1;
    v_categorias(9) :=3; v_categorias(10):=4; v_categorias(11):=5; v_categorias(12):=1;
    v_categorias(13):=2; v_categorias(14):=1; v_categorias(15):=2; v_categorias(16):=2;
    v_categorias(17):=3; v_categorias(18):=3; v_categorias(19):=2; v_categorias(20):=1;
    v_categorias(21):=1; v_categorias(22):=2; v_categorias(23):=3; v_categorias(24):=4;
    v_categorias(25):=3; v_categorias(26):=3; v_categorias(27):=3; v_categorias(28):=1;
    v_categorias(29):=1; v_categorias(30):=1; v_categorias(31):=2; v_categorias(32):=1;
    v_categorias(33):=2; v_categorias(34):=3; v_categorias(35):=1; v_categorias(36):=1;
    v_categorias(37):=2; v_categorias(38):=2; v_categorias(39):=1; v_categorias(40):=1;

    v_anios(1) :=2023; v_anios(2) :=2024; v_anios(3) :=2022; v_anios(4) :=2023;
    v_anios(5) :=2024; v_anios(6) :=2022; v_anios(7) :=2024; v_anios(8) :=2023;
    v_anios(9) :=2021; v_anios(10):=2023; v_anios(11):=2024; v_anios(12):=2022;
    v_anios(13):=2023; v_anios(14):=2024; v_anios(15):=2022; v_anios(16):=2023;
    v_anios(17):=2021; v_anios(18):=2022; v_anios(19):=2024; v_anios(20):=2023;
    v_anios(21):=2024; v_anios(22):=2022; v_anios(23):=2023; v_anios(24):=2023;
    v_anios(25):=2024; v_anios(26):=2022; v_anios(27):=2023; v_anios(28):=2024;
    v_anios(29):=2023; v_anios(30):=2022; v_anios(31):=2024; v_anios(32):=2023;
    v_anios(33):=2022; v_anios(34):=2024; v_anios(35):=2023; v_anios(36):=2022;
    v_anios(37):=2024; v_anios(38):=2023; v_anios(39):=2022; v_anios(40):=2024;

    v_clasificaciones(1) :='TP';  v_clasificaciones(2) :='+13'; v_clasificaciones(3) :='+7';
    v_clasificaciones(4) :='+16'; v_clasificaciones(5) :='+18'; v_clasificaciones(6) :='TP';
    v_clasificaciones(7) :='+13'; v_clasificaciones(8) :='+18'; v_clasificaciones(9) :='TP';
    v_clasificaciones(10):='+7';  v_clasificaciones(11):='TP';  v_clasificaciones(12):='+16';
    v_clasificaciones(13):='+13'; v_clasificaciones(14):='TP';  v_clasificaciones(15):='+7';
    v_clasificaciones(16):='+13'; v_clasificaciones(17):='TP';  v_clasificaciones(18):='+18';
    v_clasificaciones(19):='+7';  v_clasificaciones(20):='TP';  v_clasificaciones(21):='+13';
    v_clasificaciones(22):='+7';  v_clasificaciones(23):='TP';  v_clasificaciones(24):='+13';
    v_clasificaciones(25):='+16'; v_clasificaciones(26):='+18'; v_clasificaciones(27):='TP';
    v_clasificaciones(28):='+7';  v_clasificaciones(29):='+13'; v_clasificaciones(30):='+16';
    v_clasificaciones(31):='TP';  v_clasificaciones(32):='+7';  v_clasificaciones(33):='+13';
    v_clasificaciones(34):='TP';  v_clasificaciones(35):='+18'; v_clasificaciones(36):='+13';
    v_clasificaciones(37):='+7';  v_clasificaciones(38):='+13'; v_clasificaciones(39):='TP';
    v_clasificaciones(40):='+13';

FOR i IN 1..40 LOOP
        INSERT INTO CONTENIDO (
            id_contenido, titulo, anio_lanzamiento, duracion, sinopsis,
            clasificacion_edad, es_original, fecha_agregado, popularidad,
            id_categoria, id_empleado_pub
        ) VALUES (
            i,
            v_titulos(i),
            v_anios(i),
            TRUNC(DBMS_RANDOM.VALUE(45, 180)),
            'Sinopsis de: ' || v_titulos(i),
            v_clasificaciones(i),
            CASE WHEN DBMS_RANDOM.VALUE(0, 1) > 0.7 THEN 'S' ELSE 'N' END,
            SYSDATE - TRUNC(DBMS_RANDOM.VALUE(1, 365)),
            0,
            v_categorias(i),
            -- Se asigna el empleado publicador (solo empleados del depto. Contenido)
            CASE WHEN MOD(i, 2) = 0 THEN 2 ELSE 1 END
        );
END LOOP;
COMMIT;
DBMS_OUTPUT.PUT_LINE('✓ CONTENIDO: 40 registros insertados');
END;
/


-- ============================================================
-- 10. CONTENIDO_GENEROS
-- Asignación determinista para evitar duplicados
-- ============================================================
DECLARE
v_genero NUMBER;
    v_num_generos NUMBER;
BEGIN
FOR c IN 1..40 LOOP
        v_num_generos := TRUNC(DBMS_RANDOM.VALUE(1, 4)); -- entre 1 y 3 géneros
FOR g IN 1..v_num_generos LOOP
            v_genero := MOD(c + g - 1, 8) + 1;
            -- Insertar solo si no existe el par (ignora el error de duplicado)
BEGIN
INSERT INTO CONTENIDO_GENEROS (id_contenido, id_genero)
VALUES (c, v_genero);
EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
END LOOP;
END LOOP;
COMMIT;
DBMS_OUTPUT.PUT_LINE('✓ CONTENIDO_GENEROS: registros insertados');
END;
/


-- ============================================================
-- 11. TEMPORADAS (hasta 15 registros)
-- Se controla con un contador explícito y se consultan IDs reales
-- ============================================================
DECLARE
v_id      NUMBER := 1;
    v_num_t   NUMBER;
BEGIN
    -- Series (categoría 2)
FOR c IN (SELECT id_contenido FROM CONTENIDO WHERE id_categoria = 2 ORDER BY id_contenido) LOOP
        v_num_t := TRUNC(DBMS_RANDOM.VALUE(1, 4)); -- 1 a 3 temporadas
FOR t IN 1..v_num_t LOOP
            EXIT WHEN v_id > 15;
INSERT INTO TEMPORADAS (id_temporada, id_contenido, numero_temporada)
VALUES (v_id, c.id_contenido, t);
v_id := v_id + 1;
END LOOP;
        EXIT WHEN v_id > 15;
END LOOP;

    -- Podcasts (categoría 5) si aún hay cupo
FOR c IN (SELECT id_contenido FROM CONTENIDO WHERE id_categoria = 5 ORDER BY id_contenido) LOOP
        EXIT WHEN v_id > 15;
        v_num_t := TRUNC(DBMS_RANDOM.VALUE(1, 3));
FOR t IN 1..v_num_t LOOP
            EXIT WHEN v_id > 15;
INSERT INTO TEMPORADAS (id_temporada, id_contenido, numero_temporada)
VALUES (v_id, c.id_contenido, t);
v_id := v_id + 1;
END LOOP;
END LOOP;

COMMIT;
DBMS_OUTPUT.PUT_LINE('✓ TEMPORADAS: ' || (v_id - 1) || ' registros insertados');
END;
/


-- ============================================================
-- 12. EPISODIOS (hasta 50 registros)
-- ============================================================
DECLARE
v_id    NUMBER := 1;
    v_num_e NUMBER;
BEGIN
FOR temp IN (SELECT id_temporada FROM TEMPORADAS ORDER BY id_temporada) LOOP
        EXIT WHEN v_id > 50;
        v_num_e := TRUNC(DBMS_RANDOM.VALUE(3, 10)); -- 3 a 9 episodios
FOR e IN 1..v_num_e LOOP
            EXIT WHEN v_id > 50;
INSERT INTO EPISODIOS (id_episodio, id_temporada, numero_episodio, titulo, duracion_minutos)
VALUES (v_id, temp.id_temporada, e, 'Episodio ' || e, TRUNC(DBMS_RANDOM.VALUE(20, 60)));
v_id := v_id + 1;
END LOOP;
END LOOP;
COMMIT;
DBMS_OUTPUT.PUT_LINE('✓ EPISODIOS: ' || (v_id - 1) || ' registros insertados');
END;
/


-- ============================================================
-- 13. REPRODUCCIONES (200 registros)
-- Se usan cursores sobre IDs reales de PERFILES, CONTENIDO y EPISODIOS
-- para garantizar integridad referencial
-- ============================================================
DECLARE
TYPE t_ids IS TABLE OF NUMBER;

    v_perfiles_ids  t_ids;
    v_contenido_ids t_ids;
    v_episodio_ids  t_ids;
    v_dispositivos  SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('celular','tablet','TV','computador');

    v_id_perfil    NUMBER;
    v_id_contenido NUMBER;
    v_id_episodio  NUMBER;
    v_fecha        TIMESTAMP;
    v_max_ep       NUMBER;
BEGIN
    -- Cargar IDs reales en colecciones
SELECT id_perfil   BULK COLLECT INTO v_perfiles_ids  FROM PERFILES;
SELECT id_contenido BULK COLLECT INTO v_contenido_ids FROM CONTENIDO;
SELECT id_episodio  BULK COLLECT INTO v_episodio_ids  FROM EPISODIOS;

v_max_ep := v_episodio_ids.COUNT;

FOR r IN 1..200 LOOP
        v_fecha        := SYSTIMESTAMP - TRUNC(DBMS_RANDOM.VALUE(0, 90));
        v_id_perfil    := v_perfiles_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_perfiles_ids.COUNT + 1)));
        v_id_contenido := v_contenido_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_contenido_ids.COUNT + 1)));

        -- El 20% de las reproducciones son de episodios
        IF v_max_ep > 0 AND DBMS_RANDOM.VALUE(0, 1) > 0.8 THEN
            v_id_episodio := v_episodio_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_max_ep + 1)));
ELSE
            v_id_episodio := NULL;
END IF;

INSERT INTO REPRODUCCIONES (
    id_reproduccion, id_perfil, id_contenido, id_episodio,
    fecha_hora_inicio, fecha_hora_fin, porcentaje_avance, dispositivo, activa
) VALUES (
             r,
             v_id_perfil,
             v_id_contenido,
             v_id_episodio,
             v_fecha,
             v_fecha + (DBMS_RANDOM.VALUE(5, 120) / 1440),
             TRUNC(DBMS_RANDOM.VALUE(0, 101)),
             v_dispositivos(TRUNC(DBMS_RANDOM.VALUE(1, 5))),
             'N'
         );
END LOOP;
COMMIT;
DBMS_OUTPUT.PUT_LINE('✓ REPRODUCCIONES: 200 registros insertados');
END;
/


-- ============================================================
-- 14. CALIFICACIONES (60 registros)
-- Se controla el UNIQUE (id_perfil, id_contenido) con EXCEPTION
-- ============================================================
DECLARE
TYPE t_ids IS TABLE OF NUMBER;
    v_perfiles_ids  t_ids;
    v_contenido_ids t_ids;
    v_id            NUMBER := 1;
    v_id_perfil     NUMBER;
    v_id_contenido  NUMBER;
    v_intentos      NUMBER;
BEGIN
SELECT id_perfil    BULK COLLECT INTO v_perfiles_ids  FROM PERFILES;
SELECT id_contenido BULK COLLECT INTO v_contenido_ids FROM CONTENIDO;

WHILE v_id <= 60 LOOP
        v_id_perfil    := v_perfiles_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_perfiles_ids.COUNT + 1)));
        v_id_contenido := v_contenido_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_contenido_ids.COUNT + 1)));

BEGIN
INSERT INTO CALIFICACIONES (
    id_calificacion, id_perfil, id_contenido,
    estrellas, resena, fecha_calificacion
) VALUES (
             v_id,
             v_id_perfil,
             v_id_contenido,
             TRUNC(DBMS_RANDOM.VALUE(1, 6)),
             CASE WHEN DBMS_RANDOM.VALUE(0, 1) > 0.7 THEN '¡Excelente contenido!' ELSE NULL END,
             SYSDATE - TRUNC(DBMS_RANDOM.VALUE(1, 60))
         );
v_id := v_id + 1; -- Solo avanza si el INSERT fue exitoso
EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN NULL; -- Reintenta con otro par
END;
END LOOP;
COMMIT;
DBMS_OUTPUT.PUT_LINE('✓ CALIFICACIONES: 60 registros insertados');
END;
/


-- ============================================================
-- 15. PAGOS (80 registros)
-- ============================================================
DECLARE
v_id      NUMBER := 1;
    v_estados SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('exitoso','exitoso','exitoso','fallido','pendiente');
    v_metodos SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('tarjeta_credito','tarjeta_debito','PSE','Nequi','Daviplata');
    v_num_p   NUMBER;
BEGIN
FOR u IN 1..30 LOOP
        EXIT WHEN v_id > 80;
        v_num_p := TRUNC(DBMS_RANDOM.VALUE(2, 6)); -- 2 a 5 pagos por usuario
FOR p IN 1..v_num_p LOOP
            EXIT WHEN v_id > 80;
INSERT INTO PAGOS (id_pago, id_usuario, id_plan, fecha_pago, monto, metodo_pago, estado)
VALUES (
           v_id,
           u,
           MOD(u - 1, 3) + 1,
           SYSDATE - TRUNC(DBMS_RANDOM.VALUE(1, 180)),
           CASE MOD(u - 1, 3) + 1 WHEN 1 THEN 9.99 WHEN 2 THEN 14.99 ELSE 19.99 END,
           v_metodos(TRUNC(DBMS_RANDOM.VALUE(1, 6))),
           v_estados(TRUNC(DBMS_RANDOM.VALUE(1, 6)))
       );
v_id := v_id + 1;
END LOOP;
END LOOP;
COMMIT;
DBMS_OUTPUT.PUT_LINE('✓ PAGOS: ' || (v_id - 1) || ' registros insertados');
END;
/


-- ============================================================
-- 16. FAVORITOS (40 registros)
-- Se corrige el cursor inválido y se controla el UNIQUE
-- ============================================================
DECLARE
TYPE t_ids IS TABLE OF NUMBER;
    v_perfiles_ids  t_ids;
    v_contenido_ids t_ids;
    v_id            NUMBER := 1;
    v_id_perfil     NUMBER;
    v_id_contenido  NUMBER;
BEGIN
SELECT id_perfil    BULK COLLECT INTO v_perfiles_ids  FROM PERFILES;
SELECT id_contenido BULK COLLECT INTO v_contenido_ids FROM CONTENIDO;

WHILE v_id <= 40 LOOP
        v_id_perfil    := v_perfiles_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_perfiles_ids.COUNT + 1)));
        v_id_contenido := v_contenido_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_contenido_ids.COUNT + 1)));

BEGIN
INSERT INTO FAVORITOS (id_favorito, id_perfil, id_contenido, fecha_agregado)
VALUES (
           v_id,
           v_id_perfil,
           v_id_contenido,
           SYSDATE - TRUNC(DBMS_RANDOM.VALUE(1, 90))
       );
v_id := v_id + 1; -- Solo avanza si el INSERT fue exitoso
EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN NULL; -- Reintenta con otro par
END;
END LOOP;
COMMIT;
DBMS_OUTPUT.PUT_LINE('✓ FAVORITOS: 40 registros insertados');
END;
/


-- ============================================================
-- 17. ACTUALIZAR POPULARIDAD DEL CONTENIDO
-- ============================================================
BEGIN
FOR rec IN (SELECT id_contenido FROM CONTENIDO) LOOP
UPDATE CONTENIDO
SET popularidad = (
                      SELECT COUNT(*) * 10
                      FROM REPRODUCCIONES
                      WHERE id_contenido = rec.id_contenido
                        AND porcentaje_avance >= 90
                        AND activa = 'N'
                  ) + (
                      SELECT COUNT(*) * 2
                      FROM REPRODUCCIONES
                      WHERE id_contenido = rec.id_contenido
                        AND porcentaje_avance BETWEEN 1 AND 89
                        AND activa = 'N'
                  )
WHERE id_contenido = rec.id_contenido;
END LOOP;
COMMIT;
DBMS_OUTPUT.PUT_LINE('✓ Popularidad del contenido actualizada');
END;
/



-- ============================================================
-- RESUMEN FINAL
-- En Oracle PL/SQL no se puede usar SELECT directamente dentro
-- de PUT_LINE; se requieren variables intermedias con SELECT INTO.
-- ============================================================
DECLARE
v_planes         NUMBER;
    v_roles_usr      NUMBER;
    v_roles          NUMBER;
    v_deptos         NUMBER;
    v_empleados      NUMBER;
    v_usuarios       NUMBER;
    v_perfiles       NUMBER;
    v_categorias     NUMBER;
    v_generos        NUMBER;
    v_contenido      NUMBER;
    v_cont_gen       NUMBER;
    v_temporadas     NUMBER;
    v_episodios      NUMBER;
    v_reproducciones NUMBER;
    v_calificaciones NUMBER;
    v_pagos          NUMBER;
    v_favoritos      NUMBER;
BEGIN
SELECT COUNT(*) INTO v_planes         FROM PLANES;
SELECT COUNT(*) INTO v_roles_usr      FROM ROLES_USUARIO;
SELECT COUNT(*) INTO v_roles          FROM ROLES;
SELECT COUNT(*) INTO v_deptos         FROM DEPARTAMENTOS;
SELECT COUNT(*) INTO v_empleados      FROM EMPLEADOS;
SELECT COUNT(*) INTO v_usuarios       FROM USUARIOS;
SELECT COUNT(*) INTO v_perfiles       FROM PERFILES;
SELECT COUNT(*) INTO v_categorias     FROM CATEGORIAS;
SELECT COUNT(*) INTO v_generos        FROM GENEROS;
SELECT COUNT(*) INTO v_contenido      FROM CONTENIDO;
SELECT COUNT(*) INTO v_cont_gen       FROM CONTENIDO_GENEROS;
SELECT COUNT(*) INTO v_temporadas     FROM TEMPORADAS;
SELECT COUNT(*) INTO v_episodios      FROM EPISODIOS;
SELECT COUNT(*) INTO v_reproducciones FROM REPRODUCCIONES;
SELECT COUNT(*) INTO v_calificaciones FROM CALIFICACIONES;
SELECT COUNT(*) INTO v_pagos          FROM PAGOS;
SELECT COUNT(*) INTO v_favoritos      FROM FAVORITOS;

DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== RESUMEN DE POBLACION ===');
    DBMS_OUTPUT.PUT_LINE('PLANES:              ' || v_planes);
    DBMS_OUTPUT.PUT_LINE('ROLES_USUARIO:       ' || v_roles_usr);
    DBMS_OUTPUT.PUT_LINE('ROLES:               ' || v_roles);
    DBMS_OUTPUT.PUT_LINE('DEPARTAMENTOS:       ' || v_deptos);
    DBMS_OUTPUT.PUT_LINE('EMPLEADOS:           ' || v_empleados);
    DBMS_OUTPUT.PUT_LINE('USUARIOS:            ' || v_usuarios);
    DBMS_OUTPUT.PUT_LINE('PERFILES:            ' || v_perfiles);
    DBMS_OUTPUT.PUT_LINE('CATEGORIAS:          ' || v_categorias);
    DBMS_OUTPUT.PUT_LINE('GENEROS:             ' || v_generos);
    DBMS_OUTPUT.PUT_LINE('CONTENIDO:           ' || v_contenido);
    DBMS_OUTPUT.PUT_LINE('CONTENIDO_GENEROS:   ' || v_cont_gen);
    DBMS_OUTPUT.PUT_LINE('TEMPORADAS:          ' || v_temporadas);
    DBMS_OUTPUT.PUT_LINE('EPISODIOS:           ' || v_episodios);
    DBMS_OUTPUT.PUT_LINE('REPRODUCCIONES:      ' || v_reproducciones);
    DBMS_OUTPUT.PUT_LINE('CALIFICACIONES:      ' || v_calificaciones);
    DBMS_OUTPUT.PUT_LINE('PAGOS:               ' || v_pagos);
    DBMS_OUTPUT.PUT_LINE('FAVORITOS:           ' || v_favoritos);
    DBMS_OUTPUT.PUT_LINE('===============================');
END;
/