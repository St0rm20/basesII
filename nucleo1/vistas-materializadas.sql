-- Crear tabla con nombre diferente (recomendado)
CREATE TABLE REPRODUCCIONES_PART (
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

-- Migrar datos de la tabla original a la nueva
INSERT INTO REPRODUCCIONES_PART SELECT * FROM REPRODUCCIONES;
COMMIT;

-- Agregar constraints
ALTER TABLE REPRODUCCIONES_PART
    ADD CONSTRAINT fk_reprod_part_perfil
        FOREIGN KEY (id_perfil) REFERENCES PERFILES(id_perfil);

ALTER TABLE REPRODUCCIONES_PART
    ADD CONSTRAINT fk_reprod_part_contenido
        FOREIGN KEY (id_contenido) REFERENCES CONTENIDO(id_contenido);

ALTER TABLE REPRODUCCIONES_PART
    ADD CONSTRAINT fk_reprod_part_episodio
        FOREIGN KEY (id_episodio) REFERENCES EPISODIOS(id_episodio);

ALTER TABLE REPRODUCCIONES_PART
    ADD CONSTRAINT chk_reprod_part_avance
        CHECK (porcentaje_avance BETWEEN 0 AND 100);

ALTER TABLE REPRODUCCIONES_PART
    ADD CONSTRAINT chk_reprod_part_activa
        CHECK (activa IN ('S', 'N'));