-- ============================================================
-- FRAGMENTACION DE TABLA REPRODUCCIONES POR RANGO DE FECHAS
-- ============================================================

-- ------------------------------------------------------------
-- 1. Crear los tablespaces con sus datafiles
-- ------------------------------------------------------------

CREATE TABLESPACE ts_reproducciones_2024
DATAFILE 'C:\Oracle\oradata\QUINDIOFLIX\reproducciones_2024.dbf'
    SIZE 500M
    AUTOEXTEND ON NEXT 100M MAXSIZE 4G;

CREATE TABLESPACE ts_reproducciones_2025
DATAFILE 'C:\Oracle\oradata\QUINDIOFLIX\reproducciones_2025.dbf'
    SIZE 1G
    AUTOEXTEND ON NEXT 200M MAXSIZE 8G;

CREATE TABLESPACE ts_reproducciones_futuro
DATAFILE 'C:\Oracle\oradata\QUINDIOFLIX\reproducciones_futuro.dbf'
    SIZE 1G
    AUTOEXTEND ON NEXT 200M MAXSIZE 8G;

-- ------------------------------------------------------------
-- 2. Crear la tabla fragmentada (particionada por rango)
-- ------------------------------------------------------------

CREATE TABLE REPRODUCCIONES (
    id_reproduccion   NUMBER        PRIMARY KEY,
    id_perfil         NUMBER        NOT NULL,
    id_contenido      NUMBER        NOT NULL,
    id_episodio       NUMBER,
    fecha_hora_inicio TIMESTAMP     NOT NULL,
    fecha_hora_fin    TIMESTAMP,
    porcentaje_avance NUMBER,
    dispositivo       VARCHAR2(50),
    activa            CHAR(1)       DEFAULT 'S'
)
PARTITION BY RANGE (fecha_hora_inicio)
(
    PARTITION p_reproducciones_2024 
        VALUES LESS THAN (TO_DATE('2025-01-01', 'YYYY-MM-DD'))
        TABLESPACE ts_reproducciones_2024,
    
    PARTITION p_reproducciones_2025 
        VALUES LESS THAN (TO_DATE('2026-01-01', 'YYYY-MM-DD'))
        TABLESPACE ts_reproducciones_2025,
    
    PARTITION p_reproducciones_futuro 
        VALUES LESS THAN (MAXVALUE)
        TABLESPACE ts_reproducciones_futuro
);

-- ------------------------------------------------------------
-- 3. Agregar las restricciones de integridad (opcional pero recomendado)
-- ------------------------------------------------------------

ALTER TABLE REPRODUCCIONES
ADD CONSTRAINT fk_reprod_perfil 
    FOREIGN KEY (id_perfil) REFERENCES PERFILES(id_perfil);
    
ALTER TABLE REPRODUCCIONES
ADD CONSTRAINT fk_reprod_contenido 
    FOREIGN KEY (id_contenido) REFERENCES CONTENIDO(id_contenido);
    
ALTER TABLE REPRODUCCIONES
ADD CONSTRAINT fk_reprod_episodio 
    FOREIGN KEY (id_episodio) REFERENCES EPISODIOS(id_episodio);
    
ALTER TABLE REPRODUCCIONES
ADD CONSTRAINT chk_reprod_avance 
    CHECK (porcentaje_avance BETWEEN 0 AND 100);

ALTER TABLE REPRODUCCIONES
ADD CONSTRAINT chk_reprod_activa 
    CHECK (activa IN ('S', 'N'));