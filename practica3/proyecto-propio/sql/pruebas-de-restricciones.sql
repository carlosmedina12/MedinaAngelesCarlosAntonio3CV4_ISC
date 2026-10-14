-- =====================================================================
-- pruebas-de-restricciones.sql  |  Práctica 3, ejercicio 6.2
-- Ejecutar DESPUÉS de esquema.sql, sobre la base de datos vacía.
-- Parte 1: datos válidos (deben insertarse sin error).
-- Parte 2: inserciones inválidas (el gestor DEBE rechazarlas).
-- =====================================================================

-- ------------------------- PARTE 1: DATOS VÁLIDOS --------------------
INSERT INTO aeropuerto (codigo_iata, nombre, ciudad) VALUES
 ('MEX', 'Aeropuerto Internacional Benito Juárez', 'Ciudad de México'),
 ('CUN', 'Aeropuerto Internacional de Cancún', 'Cancún'),
 ('GDL', 'Aeropuerto Internacional de Guadalajara', 'Guadalajara');

INSERT INTO aeronave (matricula, modelo, fabricante, capacidad_total) VALUES
 ('XA-AAA', 'A320', 'Airbus', 180),
 ('XA-BBB', 'B737', 'Boeing', 160);

INSERT INTO asiento (matricula_aeronave, numero_asiento, clase, ubicacion) VALUES
 ('XA-AAA', '1A',  'EJECUTIVA', 'VENTANA'),
 ('XA-AAA', '1B',  'EJECUTIVA', 'PASILLO'),
 ('XA-AAA', '12C', 'ECONOMICA', 'PASILLO'),
 ('XA-BBB', '2A',  'ECONOMICA', 'VENTANA');

INSERT INTO ruta (codigo_origen, codigo_destino, distancia_km) VALUES ('MEX', 'CUN', 1280);

INSERT INTO vuelo (numero_vuelo, id_ruta, matricula_aeronave, salida_programada, llegada_estimada)
VALUES ('AD101',
        (SELECT id_ruta FROM ruta WHERE codigo_origen = 'MEX' AND codigo_destino = 'CUN'),
        'XA-AAA', '2026-10-20 08:00', '2026-10-20 10:15');

INSERT INTO escala (id_vuelo, numero_secuencia, codigo_aeropuerto, duracion_min)
VALUES ((SELECT id_vuelo FROM vuelo WHERE numero_vuelo = 'AD101'), 1, 'GDL', 45);

INSERT INTO tripulante (nombre, apellido_paterno, apellido_materno, numero_licencia, tipo) VALUES
 ('Juan', 'Pérez', 'López', 'LIC-001', 'PILOTO'),
 ('Ana',  'García', NULL,  'LIC-002', 'SOBRECARGO');

INSERT INTO piloto (id_tripulante, tipo_licencia, horas_vuelo_comando)
VALUES ((SELECT id_tripulante FROM tripulante WHERE numero_licencia = 'LIC-001'), 'TRANSPORTE', 3500);

INSERT INTO sobrecargo (id_tripulante, categoria, certificacion_primeros_auxilios)
VALUES ((SELECT id_tripulante FROM tripulante WHERE numero_licencia = 'LIC-002'), 'JEFE', TRUE);

INSERT INTO sobrecargo_idioma (id_tripulante, idioma) VALUES
 ((SELECT id_tripulante FROM tripulante WHERE numero_licencia = 'LIC-002'), 'Español'),
 ((SELECT id_tripulante FROM tripulante WHERE numero_licencia = 'LIC-002'), 'Inglés');

INSERT INTO asignacion_tripulacion (id_vuelo, id_tripulante, rol_en_vuelo) VALUES
 ((SELECT id_vuelo FROM vuelo WHERE numero_vuelo = 'AD101'),
  (SELECT id_tripulante FROM tripulante WHERE numero_licencia = 'LIC-001'), 'CAPITAN'),
 ((SELECT id_vuelo FROM vuelo WHERE numero_vuelo = 'AD101'),
  (SELECT id_tripulante FROM tripulante WHERE numero_licencia = 'LIC-002'), 'JEFE_CABINA');

INSERT INTO pasajero (nombre, apellido_paterno, apellido_materno, numero_pasaporte, fecha_nacimiento, nacionalidad) VALUES
 ('María', 'Hernández', 'Ruiz', 'G12345678', '1995-03-14', 'Mexicana'),
 ('Luis',  'Ramírez',   NULL,   'G87654321', '1988-11-02', 'Mexicana');

INSERT INTO pasajero_telefono (id_pasajero, telefono) VALUES
 ((SELECT id_pasajero FROM pasajero WHERE numero_pasaporte = 'G12345678'), '5512345678'),
 ((SELECT id_pasajero FROM pasajero WHERE numero_pasaporte = 'G12345678'), '+52 55 8765 4321');

INSERT INTO reservacion (id_pasajero)
VALUES ((SELECT id_pasajero FROM pasajero WHERE numero_pasaporte = 'G12345678'));

INSERT INTO boleto (id_reservacion, id_pasajero, id_vuelo, matricula_aeronave, numero_asiento, precio, clase_tarifa)
VALUES ((SELECT MIN(id_reservacion) FROM reservacion),
        (SELECT id_pasajero FROM pasajero WHERE numero_pasaporte = 'G12345678'),
        (SELECT id_vuelo FROM vuelo WHERE numero_vuelo = 'AD101'),
        'XA-AAA', '1A', 3200.00, 'EJECUTIVA');

INSERT INTO check_in (id_boleto, puerta_abordaje)
VALUES ((SELECT MIN(id_boleto) FROM boleto), 'B12');

INSERT INTO equipaje (id_boleto, numero_etiqueta, tipo, peso_kg)
VALUES ((SELECT MIN(id_boleto) FROM boleto), 1, 'FACTURADO', 23.50);

-- Comprobación de los atributos derivados (no se almacenan)
SELECT * FROM vw_pasajero_edad;
SELECT * FROM vw_horas_tripulante;

-- ------------------- PARTE 2: INSERCIONES INVÁLIDAS ------------------
-- Cada sentencia debe FALLAR. Captura el mensaje de error de cada una.

-- T1. Asiento ya vendido en el mismo vuelo -> uq_boleto_vuelo_asiento
INSERT INTO boleto (id_reservacion, id_pasajero, id_vuelo, matricula_aeronave, numero_asiento, precio, clase_tarifa)
VALUES ((SELECT MIN(id_reservacion) FROM reservacion),
        (SELECT id_pasajero FROM pasajero WHERE numero_pasaporte = 'G87654321'),
        (SELECT id_vuelo FROM vuelo WHERE numero_vuelo = 'AD101'),
        'XA-AAA', '1A', 3200.00, 'EJECUTIVA');

-- T2. Asiento que no existe en la aeronave del vuelo -> fk_boleto_asiento
INSERT INTO boleto (id_reservacion, id_pasajero, id_vuelo, matricula_aeronave, numero_asiento, precio, clase_tarifa)
VALUES ((SELECT MIN(id_reservacion) FROM reservacion),
        (SELECT id_pasajero FROM pasajero WHERE numero_pasaporte = 'G87654321'),
        (SELECT id_vuelo FROM vuelo WHERE numero_vuelo = 'AD101'),
        'XA-AAA', '99Z', 1500.00, 'ECONOMICA');

-- T3. Asiento de otra aeronave distinta a la que opera el vuelo -> fk_boleto_vuelo
INSERT INTO boleto (id_reservacion, id_pasajero, id_vuelo, matricula_aeronave, numero_asiento, precio, clase_tarifa)
VALUES ((SELECT MIN(id_reservacion) FROM reservacion),
        (SELECT id_pasajero FROM pasajero WHERE numero_pasaporte = 'G87654321'),
        (SELECT id_vuelo FROM vuelo WHERE numero_vuelo = 'AD101'),
        'XA-BBB', '2A', 1500.00, 'ECONOMICA');

-- T4. Maleta que excede el peso máximo permitido -> ck_equipaje_peso
INSERT INTO equipaje (id_boleto, numero_etiqueta, tipo, peso_kg)
VALUES ((SELECT MIN(id_boleto) FROM boleto), 2, 'FACTURADO', 45.00);

-- T5. Un sobrecargo registrado también como piloto (viola la disyunción)
--     -> fk_piloto_tripulante
INSERT INTO piloto (id_tripulante, tipo_licencia)
VALUES ((SELECT id_tripulante FROM tripulante WHERE numero_licencia = 'LIC-002'), 'COMERCIAL');

-- T6. Ruta con el mismo aeropuerto de origen y destino -> ck_ruta_origen_destino
INSERT INTO ruta (codigo_origen, codigo_destino, distancia_km) VALUES ('MEX', 'MEX', 100);

-- T7. Código IATA con formato inválido -> ck_aeropuerto_iata
INSERT INTO aeropuerto (codigo_iata, nombre, ciudad) VALUES ('ab1', 'Aeropuerto falso', 'Ninguna');

-- T8. Vuelo que llega antes de salir -> ck_vuelo_horario
INSERT INTO vuelo (numero_vuelo, id_ruta, matricula_aeronave, salida_programada, llegada_estimada)
VALUES ('AD999',
        (SELECT id_ruta FROM ruta WHERE codigo_origen = 'MEX' AND codigo_destino = 'CUN'),
        'XA-AAA', '2026-10-21 10:00', '2026-10-21 08:00');

-- T9. Borrar un aeropuerto que ya tiene rutas -> fk_ruta_origen (RESTRICT)
DELETE FROM aeropuerto WHERE codigo_iata = 'MEX';
