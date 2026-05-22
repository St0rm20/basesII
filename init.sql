CREATE TABLE PLANES (
    id_plan          NUMBER        PRIMARY KEY,
    nombre_plan      VARCHAR2(50)  NOT NULL,
    max_pantallas    NUMBER        NOT NULL,
    max_perfiles     NUMBER        NOT NULL,
    precio           NUMBER        NOT NULL,
    duracion_dias    NUMBER        NOT NULL,
    calidad_video    VARCHAR2(5)   NOT NULL
        CHECK (calidad_video IN ('SD', 'HD', '4K'))
);

CREATE TABLE ROLES_USUARIO (
    id_rol_usuario  NUMBER        PRIMARY KEY,
    nombre_rol      VARCHAR2(50)  NOT NULL
);

CREATE TABLE ROLES (
    id_rol  NUMBER        PRIMARY KEY,
    nombre  VARCHAR2(50)  NOT NULL
);

CREATE TABLE DEPARTAMENTOS (
    id_departamento      NUMBER        PRIMARY KEY,
    nombre_departamento  VARCHAR2(100) NOT NULL,
    id_empleado_jefe     NUMBER
);

CREATE TABLE EMPLEADOS (
    id_empleado     NUMBER        PRIMARY KEY,
    nombre          VARCHAR2(100) NOT NULL,
    cargo           VARCHAR2(50),
    id_departamento NUMBER,
    id_supervisor   NUMBER,
    id_rol          NUMBER,

    FOREIGN KEY (id_departamento) REFERENCES DEPARTAMENTOS(id_departamento),
    FOREIGN KEY (id_supervisor)   REFERENCES EMPLEADOS(id_empleado),
    FOREIGN KEY (id_rol)          REFERENCES ROLES(id_rol)
);

ALTER TABLE DEPARTAMENTOS
ADD CONSTRAINT fk_depto_jefe
FOREIGN KEY (id_empleado_jefe) REFERENCES EMPLEADOS(id_empleado);

CREATE TABLE USUARIOS (
    id_usuario        NUMBER         PRIMARY KEY,
    nombre            VARCHAR2(100)  NOT NULL,
    email             VARCHAR2(150)  NOT NULL UNIQUE,
    telefono          VARCHAR2(20),
    fecha_nacimiento  DATE,
    ciudad            VARCHAR2(100)  NOT NULL,
    password_hash     VARCHAR2(255)  NOT NULL,
    id_plan           NUMBER,
    estado            VARCHAR2(20)   DEFAULT 'ACTIVO'
        CHECK (estado IN ('ACTIVO', 'INACTIVO')),
    fecha_vencimiento DATE,
    fecha_registro    DATE           DEFAULT SYSDATE NOT NULL,
    fecha_ultimo_pago DATE,
    saldo_a_favor     NUMBER         DEFAULT 0,
    id_rol_usuario    NUMBER         DEFAULT 1,

    FOREIGN KEY (id_plan)        REFERENCES PLANES(id_plan),
    FOREIGN KEY (id_rol_usuario) REFERENCES ROLES_USUARIO(id_rol_usuario)
);

CREATE TABLE REFERIDOS (
    id_referido          NUMBER  PRIMARY KEY,
    id_usuario_referidor NUMBER  NOT NULL,
    id_usuario_referido  NUMBER  NOT NULL UNIQUE,
    fecha_referido       DATE    DEFAULT SYSDATE NOT NULL,

    FOREIGN KEY (id_usuario_referidor) REFERENCES USUARIOS(id_usuario),
    FOREIGN KEY (id_usuario_referido)  REFERENCES USUARIOS(id_usuario),
    CHECK (id_usuario_referidor <> id_usuario_referido)
);

CREATE TABLE BENEFICIOS_REFERIDOS (
    id_beneficio     NUMBER         PRIMARY KEY,
    id_referido      NUMBER         NOT NULL,
    id_usuario       NUMBER         NOT NULL,
    tipo_beneficio   VARCHAR2(50)   DEFAULT 'descuento_mes'
        CHECK (tipo_beneficio IN ('descuento_mes', 'mes_gratis', 'otro')),
    valor_descuento  NUMBER         DEFAULT 0,
    estado           VARCHAR2(20)   DEFAULT 'pendiente'
        CHECK (estado IN ('pendiente', 'aplicado', 'vencido')),
    fecha_otorgado   DATE           DEFAULT SYSDATE NOT NULL,
    fecha_aplicado   DATE,

    FOREIGN KEY (id_referido) REFERENCES REFERIDOS(id_referido),
    FOREIGN KEY (id_usuario)  REFERENCES USUARIOS(id_usuario)
);

CREATE TABLE PERFILES (
    id_perfil  NUMBER        PRIMARY KEY,
    id_usuario NUMBER        NOT NULL,
    nombre     VARCHAR2(100) NOT NULL,
    avatar     VARCHAR2(255),
    tipo       VARCHAR2(20)  CHECK (tipo IN ('adulto', 'infantil')),

    FOREIGN KEY (id_usuario) REFERENCES USUARIOS(id_usuario)
);

CREATE TABLE PAGOS (
    id_pago      NUMBER       PRIMARY KEY,
    id_usuario   NUMBER       NOT NULL,
    id_plan      NUMBER       NOT NULL,
    fecha_pago   DATE         NOT NULL,
    monto        NUMBER       NOT NULL,
    metodo_pago  VARCHAR2(50)
        CHECK (metodo_pago IN ('tarjeta_credito','tarjeta_debito','PSE','Nequi','Daviplata')),
    estado       VARCHAR2(20)
        CHECK (estado IN ('exitoso','fallido','pendiente','reembolsado')),

    FOREIGN KEY (id_usuario) REFERENCES USUARIOS(id_usuario),
    FOREIGN KEY (id_plan)    REFERENCES PLANES(id_plan)
);

CREATE TABLE HISTORIAL_PLANES (
    id_historial  NUMBER  PRIMARY KEY,
    id_usuario    NUMBER  NOT NULL,
    id_plan       NUMBER  NOT NULL,
    fecha_inicio  DATE    NOT NULL,
    fecha_fin     DATE,

    FOREIGN KEY (id_usuario) REFERENCES USUARIOS(id_usuario),
    FOREIGN KEY (id_plan)    REFERENCES PLANES(id_plan),
    CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

CREATE TABLE CATEGORIAS (
    id_categoria      NUMBER        PRIMARY KEY,
    nombre_categoria  VARCHAR2(100) NOT NULL
);

CREATE TABLE GENEROS (
    id_genero      NUMBER        PRIMARY KEY,
    nombre_genero  VARCHAR2(100) NOT NULL
);

CREATE TABLE CONTENIDO (
    id_contenido       NUMBER        PRIMARY KEY,
    titulo             VARCHAR2(200) NOT NULL,
    anio_lanzamiento   NUMBER,
    duracion           NUMBER,
    sinopsis           CLOB,
    clasificacion_edad VARCHAR2(10)
        CHECK (clasificacion_edad IN ('TP', '+7', '+13', '+16', '+18')),
    es_original        CHAR(1)
        CHECK (es_original IN ('S', 'N')),
    fecha_agregado     DATE          DEFAULT SYSDATE,
    popularidad        NUMBER        DEFAULT 0,
    id_categoria       NUMBER,
    id_empleado_pub    NUMBER,

    FOREIGN KEY (id_categoria)    REFERENCES CATEGORIAS(id_categoria),
    FOREIGN KEY (id_empleado_pub) REFERENCES EMPLEADOS(id_empleado)
);

CREATE TABLE CONTENIDO_GENEROS (
    id_contenido  NUMBER,
    id_genero     NUMBER,

    PRIMARY KEY (id_contenido, id_genero),
    FOREIGN KEY (id_contenido) REFERENCES CONTENIDO(id_contenido),
    FOREIGN KEY (id_genero)    REFERENCES GENEROS(id_genero)
);

CREATE TABLE CONTENIDO_RELACIONADO (
    id_relacion    NUMBER       PRIMARY KEY,
    id_contenido_1 NUMBER,
    id_contenido_2 NUMBER,
    tipo_relacion  VARCHAR2(50)
        CHECK (tipo_relacion IN ('secuela','precuela','remake','spin-off','version_extendida','relacionado')),

    FOREIGN KEY (id_contenido_1) REFERENCES CONTENIDO(id_contenido),
    FOREIGN KEY (id_contenido_2) REFERENCES CONTENIDO(id_contenido),
    CHECK (id_contenido_1 <> id_contenido_2)
);

CREATE TABLE TEMPORADAS (
    id_temporada     NUMBER  PRIMARY KEY,
    id_contenido     NUMBER  NOT NULL,
    numero_temporada NUMBER  NOT NULL,

    FOREIGN KEY (id_contenido) REFERENCES CONTENIDO(id_contenido),
    UNIQUE (id_contenido, numero_temporada)
);

CREATE TABLE EPISODIOS (
    id_episodio      NUMBER        PRIMARY KEY,
    id_temporada     NUMBER        NOT NULL,
    numero_episodio  NUMBER        NOT NULL,
    titulo           VARCHAR2(200),
    duracion_minutos NUMBER,

    FOREIGN KEY (id_temporada) REFERENCES TEMPORADAS(id_temporada),
    UNIQUE (id_temporada, numero_episodio)
);

CREATE TABLE REPRODUCCIONES (
    id_reproduccion   NUMBER        PRIMARY KEY,
    id_perfil         NUMBER        NOT NULL,
    id_contenido      NUMBER        NOT NULL,
    id_episodio       NUMBER,
    fecha_hora_inicio TIMESTAMP,
    fecha_hora_fin    TIMESTAMP,
    porcentaje_avance NUMBER
        CHECK (porcentaje_avance BETWEEN 0 AND 100),
    dispositivo       VARCHAR2(50)
        CHECK (dispositivo IN ('celular','tablet','TV','computador')),
    activa            CHAR(1)       DEFAULT 'S'
        CHECK (activa IN ('S', 'N')),

    FOREIGN KEY (id_perfil)    REFERENCES PERFILES(id_perfil),
    FOREIGN KEY (id_contenido) REFERENCES CONTENIDO(id_contenido),
    FOREIGN KEY (id_episodio)  REFERENCES EPISODIOS(id_episodio)
);

CREATE TABLE CALIFICACIONES (
    id_calificacion   NUMBER  PRIMARY KEY,
    id_perfil         NUMBER  NOT NULL,
    id_contenido      NUMBER  NOT NULL,
    estrellas         NUMBER  CHECK (estrellas BETWEEN 1 AND 5),
    resena            CLOB,
    fecha_calificacion DATE   DEFAULT SYSDATE NOT NULL,

    FOREIGN KEY (id_perfil)    REFERENCES PERFILES(id_perfil),
    FOREIGN KEY (id_contenido) REFERENCES CONTENIDO(id_contenido),
    UNIQUE (id_perfil, id_contenido)
);

CREATE TABLE FAVORITOS (
    id_favorito   NUMBER  PRIMARY KEY,
    id_perfil     NUMBER  NOT NULL,
    id_contenido  NUMBER  NOT NULL,
    fecha_agregado DATE   DEFAULT SYSDATE NOT NULL,

    FOREIGN KEY (id_perfil)    REFERENCES PERFILES(id_perfil),
    FOREIGN KEY (id_contenido) REFERENCES CONTENIDO(id_contenido),
    UNIQUE (id_perfil, id_contenido)
);

CREATE TABLE REPORTES_INAPROPIADO (
    id_reporte          NUMBER        PRIMARY KEY,
    id_perfil_reporta   NUMBER        NOT NULL,
    id_contenido        NUMBER        NOT NULL,
    id_usuario_modera   NUMBER,
    descripcion         CLOB,
    estado              VARCHAR2(20)
        CHECK (estado IN ('pendiente','en_revision','resuelto','desestimado')),
    fecha_reporte       DATE          NOT NULL,
    fecha_resolucion    DATE,

    FOREIGN KEY (id_perfil_reporta)  REFERENCES PERFILES(id_perfil),
    FOREIGN KEY (id_contenido)       REFERENCES CONTENIDO(id_contenido),
    FOREIGN KEY (id_usuario_modera)  REFERENCES USUARIOS(id_usuario),
    CHECK (fecha_resolucion IS NULL OR fecha_resolucion >= fecha_reporte)
);
