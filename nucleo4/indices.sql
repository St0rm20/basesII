-- a) Índice compuesto en REPRODUCCIONES (perfil + fecha)
CREATE INDEX idx_reprod_perfil_fecha ON REPRODUCCIONES(id_perfil, fecha_hora_inicio);

-- b) Índice único en USUARIOS (email para login)
CREATE UNIQUE INDEX idx_usuarios_email ON USUARIOS(email);

-- c) Índice compuesto en CONTENIDO (categoría + año)
CREATE INDEX idx_contenido_categoria_anio ON CONTENIDO(id_categoria, anio_lanzamiento);

-- d) Índice adicional en REPRODUCCIONES (activa + fecha)
CREATE INDEX idx_reprod_activa_fecha ON REPRODUCCIONES(activa, fecha_hora_inicio);

-- Verificar que se crearon
SELECT index_name, table_name FROM user_indexes WHERE table_name IN ('REPRODUCCIONES', 'USUARIOS', 'CONTENIDO');