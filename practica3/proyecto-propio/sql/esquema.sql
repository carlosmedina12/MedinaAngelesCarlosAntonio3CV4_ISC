-- =====================================================================
-- esquema.sql  |  Práctica 3: Transformación EER -> relacional
-- Proyecto propio: AeroDatos (reservaciones y operación de vuelos)
-- Gestor: PostgreSQL 16 (contenedor Docker)
-- Cada bloque indica la regla de transformación (R1..R9) que lo origina.
-- =====================================================================

-- Limpieza para poder ejecutar el script varias veces
DROP VIEW  IF EXISTS vw_horas_tripulante, vw_pasajero_edad;
DROP TABLE IF EXISTS equipaje, check_in, boleto, reservacion,
                     pasajero_telefono, pasajero,
                     asignacion_tripulacion, sobrecargo_idioma, sobrecargo, piloto, tripulante,
                     asiento, escala, vuelo, ruta, aeronave, aeropuerto CASCADE;

-- ---------------------------------------------------------------------
-- R1: entidades fuertes
-- ---------------------------------------------------------------------
CREATE TABLE aeropuerto (
    codigo_iata CHAR(3)      NOT NULL,
    nombre      VARCHAR(100) NOT NULL,
    ciudad      VARCHAR(80)  NOT NULL,
    pais        VARCHAR(60)  NOT NULL DEFAULT 'México',
    CONSTRAINT pk_aeropuerto PRIMARY KEY (codigo_iata),
    CONSTRAINT ck_aeropuerto_iata CHECK (codigo_iata::text ~ '^[A-Z]{3}$')
);

CREATE TABLE aeronave (
    matricula       VARCHAR(10) NOT NULL,
    modelo          VARCHAR(50) NOT NULL,
    fabricante      VARCHAR(50) NOT NULL,
    capacidad_total SMALLINT    NOT NULL,
    CONSTRAINT pk_aeronave PRIMARY KEY (matricula),
    CONSTRAINT ck_aeronave_capacidad CHECK (capacidad_total > 0)
);

-- R4: aeropuerto 1 --- N ruta (dos relaciones: origen y destino)
CREATE TABLE ruta (
    id_ruta        INTEGER GENERATED ALWAYS AS IDENTITY,
    codigo_origen  CHAR(3) NOT NULL,
    codigo_destino CHAR(3) NOT NULL,
    distancia_km   INTEGER NOT NULL,
    CONSTRAINT pk_ruta PRIMARY KEY (id_ruta),
    CONSTRAINT uq_ruta_origen_destino UNIQUE (codigo_origen, codigo_destino),
    CONSTRAINT ck_ruta_distancia CHECK (distancia_km > 0),
    CONSTRAINT ck_ruta_origen_destino CHECK (codigo_origen <> codigo_destino),
    CONSTRAINT fk_ruta_origen FOREIGN KEY (codigo_origen)
        REFERENCES aeropuerto (codigo_iata) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_ruta_destino FOREIGN KEY (codigo_destino)
        REFERENCES aeropuerto (codigo_iata) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- R4: ruta 1 --- N vuelo y aeronave 1 --- N vuelo
-- Clave subrogada id_vuelo: el número de vuelo se repite cada día.
CREATE TABLE vuelo (
    id_vuelo           INTEGER GENERATED ALWAYS AS IDENTITY,
    numero_vuelo       VARCHAR(8)  NOT NULL,
    id_ruta            INTEGER     NOT NULL,
    matricula_aeronave VARCHAR(10) NOT NULL,
    salida_programada  TIMESTAMP   NOT NULL,
    llegada_estimada   TIMESTAMP   NOT NULL,
    estado             VARCHAR(12) NOT NULL DEFAULT 'PROGRAMADO',
    CONSTRAINT pk_vuelo PRIMARY KEY (id_vuelo),
    CONSTRAINT uq_vuelo_numero_salida UNIQUE (numero_vuelo, salida_programada),
    -- Superllave auxiliar: permite que boleto verifique que el asiento
    -- pertenece a la aeronave que opera ese vuelo.
    CONSTRAINT uq_vuelo_aeronave UNIQUE (id_vuelo, matricula_aeronave),
    CONSTRAINT ck_vuelo_horario CHECK (llegada_estimada > salida_programada),
    CONSTRAINT ck_vuelo_estado CHECK (estado IN ('PROGRAMADO','RETRASADO','CANCELADO','COMPLETADO')),
    CONSTRAINT fk_vuelo_ruta FOREIGN KEY (id_ruta)
        REFERENCES ruta (id_ruta) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_vuelo_aeronave FOREIGN KEY (matricula_aeronave)
        REFERENCES aeronave (matricula) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- R8: entidades débiles (dependencia de identificación)
-- PK compuesta = FK del propietario + discriminador; ON DELETE CASCADE
-- ---------------------------------------------------------------------
CREATE TABLE escala (
    id_vuelo          INTEGER  NOT NULL,
    numero_secuencia  SMALLINT NOT NULL,   -- discriminador
    codigo_aeropuerto CHAR(3)  NOT NULL,
    duracion_min      SMALLINT NOT NULL,
    CONSTRAINT pk_escala PRIMARY KEY (id_vuelo, numero_secuencia),
    CONSTRAINT ck_escala_secuencia CHECK (numero_secuencia > 0),
    CONSTRAINT ck_escala_duracion CHECK (duracion_min > 0),
    CONSTRAINT fk_escala_vuelo FOREIGN KEY (id_vuelo)
        REFERENCES vuelo (id_vuelo) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_escala_aeropuerto FOREIGN KEY (codigo_aeropuerto)
        REFERENCES aeropuerto (codigo_iata) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE asiento (
    matricula_aeronave VARCHAR(10) NOT NULL,
    numero_asiento     VARCHAR(4)  NOT NULL,   -- discriminador
    clase              VARCHAR(10) NOT NULL DEFAULT 'ECONOMICA',
    ubicacion          VARCHAR(8)  NOT NULL,
    CONSTRAINT pk_asiento PRIMARY KEY (matricula_aeronave, numero_asiento),
    CONSTRAINT ck_asiento_clase CHECK (clase IN ('ECONOMICA','EJECUTIVA','PRIMERA')),
    CONSTRAINT ck_asiento_ubicacion CHECK (ubicacion IN ('VENTANA','PASILLO','CENTRO')),
    CONSTRAINT fk_asiento_aeronave FOREIGN KEY (matricula_aeronave)
        REFERENCES aeronave (matricula) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- R9 (estrategia A): jerarquía TRIPULANTE -> PILOTO | SOBRECARGO
-- Disjunta y total. R2: nombre compuesto = nombre + apellidos.
-- La columna discriminadora tipo, repetida en el subtipo con CHECK fijo y
-- una FK compuesta (id, tipo), garantiza la disyunción: un tripulante no
-- puede tener fila en piloto y en sobrecargo a la vez.
-- ---------------------------------------------------------------------
CREATE TABLE tripulante (
    id_tripulante    INTEGER GENERATED ALWAYS AS IDENTITY,
    nombre           VARCHAR(60) NOT NULL,
    apellido_paterno VARCHAR(60) NOT NULL,
    apellido_materno VARCHAR(60),
    numero_licencia  VARCHAR(20) NOT NULL,
    tipo             VARCHAR(10) NOT NULL,   -- discriminador
    CONSTRAINT pk_tripulante PRIMARY KEY (id_tripulante),
    CONSTRAINT uq_tripulante_licencia UNIQUE (numero_licencia),
    CONSTRAINT uq_tripulante_id_tipo UNIQUE (id_tripulante, tipo),
    CONSTRAINT ck_tripulante_tipo CHECK (tipo IN ('PILOTO','SOBRECARGO'))
);

CREATE TABLE piloto (
    id_tripulante       INTEGER     NOT NULL,
    tipo                VARCHAR(10) NOT NULL DEFAULT 'PILOTO',
    tipo_licencia       VARCHAR(12) NOT NULL,
    horas_vuelo_comando INTEGER     NOT NULL DEFAULT 0,
    CONSTRAINT pk_piloto PRIMARY KEY (id_tripulante),
    CONSTRAINT ck_piloto_tipo CHECK (tipo = 'PILOTO'),
    CONSTRAINT ck_piloto_licencia CHECK (tipo_licencia IN ('COMERCIAL','TRANSPORTE')),
    CONSTRAINT ck_piloto_horas CHECK (horas_vuelo_comando >= 0),
    CONSTRAINT fk_piloto_tripulante FOREIGN KEY (id_tripulante, tipo)
        REFERENCES tripulante (id_tripulante, tipo) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE sobrecargo (
    id_tripulante                   INTEGER     NOT NULL,
    tipo                            VARCHAR(10) NOT NULL DEFAULT 'SOBRECARGO',
    categoria                       VARCHAR(10) NOT NULL DEFAULT 'AUXILIAR',
    certificacion_primeros_auxilios BOOLEAN     NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_sobrecargo PRIMARY KEY (id_tripulante),
    CONSTRAINT ck_sobrecargo_tipo CHECK (tipo = 'SOBRECARGO'),
    CONSTRAINT ck_sobrecargo_categoria CHECK (categoria IN ('JEFE','AUXILIAR')),
    CONSTRAINT fk_sobrecargo_tripulante FOREIGN KEY (id_tripulante, tipo)
        REFERENCES tripulante (id_tripulante, tipo) ON DELETE CASCADE ON UPDATE CASCADE
);

-- R3: atributo multivaluado idioma (sobrecargo)
CREATE TABLE sobrecargo_idioma (
    id_tripulante INTEGER     NOT NULL,
    idioma        VARCHAR(30) NOT NULL,
    CONSTRAINT pk_sobrecargo_idioma PRIMARY KEY (id_tripulante, idioma),
    CONSTRAINT fk_sobrecargo_idioma FOREIGN KEY (id_tripulante)
        REFERENCES sobrecargo (id_tripulante) ON DELETE CASCADE ON UPDATE CASCADE
);

-- R5: relación N:M vuelo - tripulante, con atributo propio rol_en_vuelo
CREATE TABLE asignacion_tripulacion (
    id_vuelo      INTEGER     NOT NULL,
    id_tripulante INTEGER     NOT NULL,
    rol_en_vuelo  VARCHAR(16) NOT NULL,
    CONSTRAINT pk_asignacion_tripulacion PRIMARY KEY (id_vuelo, id_tripulante),
    CONSTRAINT ck_asignacion_rol CHECK (rol_en_vuelo IN ('CAPITAN','PRIMER_OFICIAL','JEFE_CABINA','SOBRECARGO')),
    CONSTRAINT fk_asignacion_vuelo FOREIGN KEY (id_vuelo)
        REFERENCES vuelo (id_vuelo) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_asignacion_tripulante FOREIGN KEY (id_tripulante)
        REFERENCES tripulante (id_tripulante) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- Pasajeros. R2: nombre compuesto. R3: teléfono multivaluado.
-- El atributo derivado edad no se almacena: ver vw_pasajero_edad.
-- ---------------------------------------------------------------------
CREATE TABLE pasajero (
    id_pasajero      INTEGER GENERATED ALWAYS AS IDENTITY,
    nombre           VARCHAR(60) NOT NULL,
    apellido_paterno VARCHAR(60) NOT NULL,
    apellido_materno VARCHAR(60),
    numero_pasaporte VARCHAR(20) NOT NULL,
    fecha_nacimiento DATE        NOT NULL,
    nacionalidad     VARCHAR(40) NOT NULL,
    CONSTRAINT pk_pasajero PRIMARY KEY (id_pasajero),
    CONSTRAINT uq_pasajero_pasaporte UNIQUE (numero_pasaporte),
    CONSTRAINT ck_pasajero_nacimiento CHECK (fecha_nacimiento >= DATE '1900-01-01')
);

CREATE TABLE pasajero_telefono (
    id_pasajero INTEGER     NOT NULL,
    telefono    VARCHAR(20) NOT NULL,
    CONSTRAINT pk_pasajero_telefono PRIMARY KEY (id_pasajero, telefono),
    CONSTRAINT ck_pasajero_telefono CHECK (telefono ~ '^[0-9+() -]{7,20}$'),
    CONSTRAINT fk_pasajero_telefono FOREIGN KEY (id_pasajero)
        REFERENCES pasajero (id_pasajero) ON DELETE CASCADE ON UPDATE CASCADE
);

-- R4: pasajero (titular) 1 --- N reservación
CREATE TABLE reservacion (
    id_reservacion    INTEGER GENERATED ALWAYS AS IDENTITY,
    id_pasajero       INTEGER     NOT NULL,   -- titular que reserva
    fecha_reservacion TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado            VARCHAR(12) NOT NULL DEFAULT 'CONFIRMADA',
    CONSTRAINT pk_reservacion PRIMARY KEY (id_reservacion),
    CONSTRAINT ck_reservacion_estado CHECK (estado IN ('PENDIENTE','CONFIRMADA','CANCELADA')),
    CONSTRAINT fk_reservacion_pasajero FOREIGN KEY (id_pasajero)
        REFERENCES pasajero (id_pasajero) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- R7: BOLETO integra reservación, pasajero viajero, vuelo y asiento.
-- UNIQUE (id_vuelo, numero_asiento): un asiento no se vende dos veces.
-- FK (id_vuelo, matricula_aeronave): la aeronave del boleto es la del vuelo.
-- FK (matricula_aeronave, numero_asiento): el asiento existe en esa aeronave.
-- ---------------------------------------------------------------------
CREATE TABLE boleto (
    id_boleto          INTEGER GENERATED ALWAYS AS IDENTITY,
    id_reservacion     INTEGER       NOT NULL,
    id_pasajero        INTEGER       NOT NULL,   -- pasajero que viaja
    id_vuelo           INTEGER       NOT NULL,
    matricula_aeronave VARCHAR(10)   NOT NULL,
    numero_asiento     VARCHAR(4)    NOT NULL,
    precio             NUMERIC(10,2) NOT NULL,
    clase_tarifa       VARCHAR(10)   NOT NULL DEFAULT 'ECONOMICA',
    CONSTRAINT pk_boleto PRIMARY KEY (id_boleto),
    CONSTRAINT uq_boleto_vuelo_asiento UNIQUE (id_vuelo, numero_asiento),
    CONSTRAINT uq_boleto_vuelo_pasajero UNIQUE (id_vuelo, id_pasajero),
    CONSTRAINT ck_boleto_precio CHECK (precio >= 0),
    CONSTRAINT ck_boleto_tarifa CHECK (clase_tarifa IN ('ECONOMICA','EJECUTIVA','PRIMERA')),
    CONSTRAINT fk_boleto_reservacion FOREIGN KEY (id_reservacion)
        REFERENCES reservacion (id_reservacion) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_boleto_pasajero FOREIGN KEY (id_pasajero)
        REFERENCES pasajero (id_pasajero) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_boleto_vuelo FOREIGN KEY (id_vuelo, matricula_aeronave)
        REFERENCES vuelo (id_vuelo, matricula_aeronave) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_boleto_asiento FOREIGN KEY (matricula_aeronave, numero_asiento)
        REFERENCES asiento (matricula_aeronave, numero_asiento) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- R6: relación 1:1 boleto (0,1) --- check_in (1,1)
-- Se propaga la clave de boleto a check_in como FK UNIQUE y NOT NULL.
CREATE TABLE check_in (
    id_check_in     INTEGER GENERATED ALWAYS AS IDENTITY,
    id_boleto       INTEGER     NOT NULL,
    fecha_hora      TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    puerta_abordaje VARCHAR(5),
    CONSTRAINT pk_check_in PRIMARY KEY (id_check_in),
    CONSTRAINT uq_check_in_boleto UNIQUE (id_boleto),
    CONSTRAINT fk_check_in_boleto FOREIGN KEY (id_boleto)
        REFERENCES boleto (id_boleto) ON DELETE CASCADE ON UPDATE CASCADE
);

-- R8: entidad débil equipaje (identificación por boleto + número de etiqueta)
CREATE TABLE equipaje (
    id_boleto       INTEGER      NOT NULL,
    numero_etiqueta SMALLINT     NOT NULL,   -- discriminador
    tipo            VARCHAR(10)  NOT NULL DEFAULT 'FACTURADO',
    peso_kg         NUMERIC(5,2) NOT NULL,
    CONSTRAINT pk_equipaje PRIMARY KEY (id_boleto, numero_etiqueta),
    CONSTRAINT ck_equipaje_etiqueta CHECK (numero_etiqueta > 0),
    CONSTRAINT ck_equipaje_tipo CHECK (tipo IN ('FACTURADO','MANO')),
    CONSTRAINT ck_equipaje_peso CHECK (peso_kg > 0 AND peso_kg <= 32),
    CONSTRAINT fk_equipaje_boleto FOREIGN KEY (id_boleto)
        REFERENCES boleto (id_boleto) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- Atributos derivados: se calculan en la consulta, no se almacenan
-- ---------------------------------------------------------------------
CREATE VIEW vw_pasajero_edad AS
SELECT id_pasajero, nombre, apellido_paterno, apellido_materno,
       EXTRACT(YEAR FROM age(CURRENT_DATE, fecha_nacimiento))::INTEGER AS edad
FROM pasajero;

CREATE VIEW vw_horas_tripulante AS
SELECT t.id_tripulante, t.nombre, t.apellido_paterno,
       COALESCE(ROUND(SUM(EXTRACT(EPOCH FROM (v.llegada_estimada - v.salida_programada)) / 3600)::numeric, 2), 0)
           AS horas_vuelo_acumuladas
FROM tripulante t
LEFT JOIN asignacion_tripulacion a ON a.id_tripulante = t.id_tripulante
LEFT JOIN vuelo v ON v.id_vuelo = a.id_vuelo AND v.estado = 'COMPLETADO'
GROUP BY t.id_tripulante, t.nombre, t.apellido_paterno;
