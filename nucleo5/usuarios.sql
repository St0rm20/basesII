-- ============================================================
-- QUINDIOFLIX — Nucleo 4: Seguridad (Usuarios, Roles, Privilegios)
-- Base de Datos II — Universidad del Quindio
-- Semestre 2026-1
-- ============================================================

-- ============================================================
-- 3.5.1 CREACIÓN DE ROLES
-- ============================================================

-- Rol 1: Administrador de la plataforma (CRUD total)
CREATE ROLE ROL_ADMIN;

-- Rol 2: Analista de datos / Gerencia (solo lectura)
CREATE ROLE ROL_ANALISTA;

-- Rol 3: Soporte al cliente (consulta usuarios/perfiles/pagos + cambiar plan)
CREATE ROLE ROL_SOPORTE;

-- Rol 4: Gestor de catálogo (CRUD en contenido, temporadas, episodios, géneros)
CREATE ROLE ROL_CONTENIDO;


-- ============================================================
-- 3.5.1.a ASIGNACIÓN DE PRIVILEGIOS A CADA ROL
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- ROL_ADMIN: CRUD en todas las tablas + administración de usuarios
-- ────────────────────────────────────────────────────────────
GRANT CREATE SESSION TO ROL_ADMIN;
GRANT CREATE USER, ALTER USER, DROP USER TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON PLANES TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON ROLES_USUARIO TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON ROLES TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON DEPARTAMENTOS TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON EMPLEADOS TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON USUARIOS TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON REFERIDOS TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON BENEFICIOS_REFERIDOS TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON PERFILES TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON PAGOS TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON HISTORIAL_PLANES TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON CATEGORIAS TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON GENEROS TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON CONTENIDO TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON CONTENIDO_GENEROS TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON CONTENIDO_RELACIONADO TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON TEMPORADAS TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON EPISODIOS TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON REPRODUCCIONES TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON CALIFICACIONES TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON FAVORITOS TO ROL_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON REPORTES_INAPROPIADO TO ROL_ADMIN;
-- Ejecutar procedimientos
GRANT EXECUTE ON SP_REGISTRAR_USUARIO TO ROL_ADMIN;
GRANT EXECUTE ON SP_CAMBIAR_PLAN TO ROL_ADMIN;
GRANT EXECUTE ON SP_REPORTE_CONSUMO TO ROL_ADMIN;
GRANT EXECUTE ON FN_CALCULAR_MONTO TO ROL_ADMIN;
GRANT EXECUTE ON FN_CONTENIDO_RECOMENDADO TO ROL_ADMIN;

-- ────────────────────────────────────────────────────────────
-- ROL_ANALISTA: SELECT en todas las tablas + reportes + vistas materializadas
-- ────────────────────────────────────────────────────────────
GRANT CREATE SESSION TO ROL_ANALISTA;
GRANT SELECT ON PLANES TO ROL_ANALISTA;
GRANT SELECT ON ROLES_USUARIO TO ROL_ANALISTA;
GRANT SELECT ON DEPARTAMENTOS TO ROL_ANALISTA;
GRANT SELECT ON EMPLEADOS TO ROL_ANALISTA;
GRANT SELECT ON USUARIOS TO ROL_ANALISTA;
GRANT SELECT ON REFERIDOS TO ROL_ANALISTA;
GRANT SELECT ON BENEFICIOS_REFERIDOS TO ROL_ANALISTA;
GRANT SELECT ON PERFILES TO ROL_ANALISTA;
GRANT SELECT ON PAGOS TO ROL_ANALISTA;
GRANT SELECT ON HISTORIAL_PLANES TO ROL_ANALISTA;
GRANT SELECT ON CATEGORIAS TO ROL_ANALISTA;
GRANT SELECT ON GENEROS TO ROL_ANALISTA;
GRANT SELECT ON CONTENIDO TO ROL_ANALISTA;
GRANT SELECT ON CONTENIDO_GENEROS TO ROL_ANALISTA;
GRANT SELECT ON CONTENIDO_RELACIONADO TO ROL_ANALISTA;
GRANT SELECT ON TEMPORADAS TO ROL_ANALISTA;
GRANT SELECT ON EPISODIOS TO ROL_ANALISTA;
GRANT SELECT ON REPRODUCCIONES TO ROL_ANALISTA;
GRANT SELECT ON CALIFICACIONES TO ROL_ANALISTA;
GRANT SELECT ON FAVORITOS TO ROL_ANALISTA;
GRANT SELECT ON REPORTES_INAPROPIADO TO ROL_ANALISTA;
-- Vistas materializadas
GRANT SELECT ON MV_POPULARIDAD_CONTENIDO TO ROL_ANALISTA;
GRANT SELECT ON MV_INGRESOS_MENSUALES TO ROL_ANALISTA;
-- Procedimientos de reportes
GRANT EXECUTE ON SP_REPORTE_CONSUMO TO ROL_ANALISTA;
GRANT EXECUTE ON FN_CALCULAR_MONTO TO ROL_ANALISTA;

-- ────────────────────────────────────────────────────────────
-- ROL_SOPORTE: SELECT en USUARIOS, PERFILES, PAGOS, HISTORIAL_PLANES
--              INSERT/UPDATE en PAGOS. Ejecutar SP_CAMBIAR_PLAN
-- ────────────────────────────────────────────────────────────
GRANT CREATE SESSION TO ROL_SOPORTE;
GRANT SELECT ON USUARIOS TO ROL_SOPORTE;
GRANT SELECT ON PERFILES TO ROL_SOPORTE;
GRANT SELECT ON PAGOS TO ROL_SOPORTE;
GRANT SELECT ON HISTORIAL_PLANES TO ROL_SOPORTE;
GRANT SELECT ON PLANES TO ROL_SOPORTE;
GRANT INSERT, UPDATE ON PAGOS TO ROL_SOPORTE;
GRANT EXECUTE ON SP_CAMBIAR_PLAN TO ROL_SOPORTE;

-- ────────────────────────────────────────────────────────────
-- ROL_CONTENIDO: CRUD en CONTENIDO, TEMPORADAS, EPISODIOS, GENEROS
--                SELECT en REPRODUCCIONES y CALIFICACIONES
-- ────────────────────────────────────────────────────────────
GRANT CREATE SESSION TO ROL_CONTENIDO;
GRANT SELECT, INSERT, UPDATE, DELETE ON CONTENIDO TO ROL_CONTENIDO;
GRANT SELECT, INSERT, UPDATE, DELETE ON CONTENIDO_GENEROS TO ROL_CONTENIDO;
GRANT SELECT, INSERT, UPDATE, DELETE ON CONTENIDO_RELACIONADO TO ROL_CONTENIDO;
GRANT SELECT, INSERT, UPDATE, DELETE ON TEMPORADAS TO ROL_CONTENIDO;
GRANT SELECT, INSERT, UPDATE, DELETE ON EPISODIOS TO ROL_CONTENIDO;
GRANT SELECT, INSERT, UPDATE, DELETE ON GENEROS TO ROL_CONTENIDO;
GRANT SELECT, INSERT, UPDATE, DELETE ON CATEGORIAS TO ROL_CONTENIDO;
GRANT SELECT ON REPRODUCCIONES TO ROL_CONTENIDO;
GRANT SELECT ON CALIFICACIONES TO ROL_CONTENIDO;


-- ============================================================
-- 3.5.1.b PERFIL DE RECURSOS (PROFILE)
-- ============================================================

-- Crear perfil con límites de recursos
CREATE PROFILE PERFIL_QUINDIOFLIX LIMIT
    SESSIONS_PER_USER         3        -- Máximo 3 sesiones concurrentes por usuario
    IDLE_TIME                 30       -- 30 minutos de inactividad antes de desconectar
    CONNECT_TIME              480      -- 8 horas máximo de conexión
    FAILED_LOGIN_ATTEMPTS     5        -- 5 intentos fallidos antes de bloquear
    PASSWORD_LOCK_TIME        1        -- 1 día bloqueado tras fallos
    PASSWORD_LIFE_TIME        90       -- Contraseña expira cada 90 días
    PASSWORD_GRACE_TIME       7        -- 7 días de gracia para cambiar contraseña
    PASSWORD_REUSE_TIME       365      -- No reutilizar contraseñas en 365 días
    PASSWORD_REUSE_MAX        5        -- Máximo 5 reutilizaciones históricas
    CPU_PER_SESSION           1000     -- 1000 centésimas de segundo (10 seg) CPU por sesión
    LOGICAL_READS_PER_SESSION 1000000  -- 1M bloques lógicos por sesión
    PRIVATE_SGA               50M;     -- 50MB de SGA privada


-- ============================================================
-- 3.5.2.a CREACIÓN DE USUARIOS (uno por rol)
-- ============================================================

-- Usuario Administrador
CREATE USER admin_quindio IDENTIFIED BY Admin2026!
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    PROFILE PERFIL_QUINDIOFLIX
    QUOTA UNLIMITED ON USERS;

-- Usuario Analista
CREATE USER analista_quindio IDENTIFIED BY Analista2026!
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    PROFILE PERFIL_QUINDIOFLIX
    QUOTA 100M ON USERS;

-- Usuario Soporte
CREATE USER soporte_quindio IDENTIFIED BY Soporte2026!
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    PROFILE PERFIL_QUINDIOFLIX
    QUOTA 50M ON USERS;

-- Usuario Gestor de Contenido
CREATE USER contenido_quindio IDENTIFIED BY Contenido2026!
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    PROFILE PERFIL_QUINDIOFLIX
    QUOTA 200M ON USERS;


-- ============================================================
-- 3.5.2.b ASIGNACIÓN DE ROLES A USUARIOS
-- ============================================================

GRANT ROL_ADMIN TO admin_quindio;
GRANT ROL_ANALISTA TO analista_quindio;
GRANT ROL_SOPORTE TO soporte_quindio;
GRANT ROL_CONTENIDO TO contenido_quindio;

COMMIT;


-- ============================================================
-- 3.5.2.c DEMOSTRACIÓN DE PRIVILEGIOS (Pruebas)
-- ============================================================

-- CONECTARSE COMO admin_quindio y probar:
-- INSERT INTO USUARIOS ... (debe funcionar)
-- SELECT * FROM PLANES; (debe funcionar)
-- DELETE FROM GENEROS WHERE id_genero = 99; (debe funcionar)

-- CONECTARSE COMO analista_quindio y probar:
-- SELECT * FROM USUARIOS; (debe funcionar)
-- INSERT INTO USUARIOS ... (debe fallar con ORA-01031: privileges insufficient)

-- CONECTARSE COMO soporte_quindio y probar:
-- SELECT * FROM USUARIOS; (debe funcionar)
-- SELECT * FROM CONTENIDO; (debe fallar — no tiene permiso)
-- EXEC SP_CAMBIAR_PLAN(1, 3); (debe funcionar)

-- CONECTARSE COMO contenido_quindio y probar:
-- INSERT INTO CONTENIDO ... (debe funcionar)
-- SELECT * FROM USUARIOS; (debe fallar — no tiene permiso)


-- ============================================================
-- 3.5.2.d DEMOSTRACIÓN DE ERROR (operación no permitida)
-- ============================================================

-- Ejemplo: Usuario soporte_quindio intenta eliminar un usuario
-- (Ejecutar conectado como soporte_quindio)

-- DELETE FROM USUARIOS WHERE id_usuario = 1;
-- Resultado esperado: ORA-01031: insufficient privileges


-- ============================================================
-- CONSULTAS DE VERIFICACIÓN
-- ============================================================

-- Ver los roles creados
SELECT role FROM dba_roles WHERE role LIKE 'ROL_%' ORDER BY role;

-- Ver qué privilegios tiene cada rol
SELECT grantee, privilege, table_name 
FROM dba_tab_privs 
WHERE grantee IN ('ROL_ADMIN', 'ROL_ANALISTA', 'ROL_SOPORTE', 'ROL_CONTENIDO')
ORDER BY grantee, table_name;

-- Ver los usuarios creados
SELECT username, account_status, profile, default_tablespace
FROM dba_users 
WHERE username IN ('ADMIN_QUINDIO', 'ANALISTA_QUINDIO', 'SOPORTE_QUINDIO', 'CONTENIDO_QUINDIO');

-- Ver el perfil y sus límites
SELECT profile, resource_name, limit 
FROM dba_profiles 
WHERE profile = 'PERFIL_QUINDIOFLIX'
ORDER BY resource_name;
