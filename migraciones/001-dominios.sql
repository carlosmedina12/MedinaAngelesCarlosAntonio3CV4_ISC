-- Migración 001: Restricciones de dominio adicionales (CHECK, UNIQUE, DEFAULT, NOT NULL)
-- Práctica 4 - Bases de Datos

BEGIN;

-- 1. Justificación: Garantiza que el formato de la matrícula de aeronave sea alfanumérico con guion opcional (ej. XA-ABC o N12345).
ALTER TABLE aeronave
    ADD CONSTRAINT ck_aeronave_matricula_formato CHECK (matricula ~ '^[A-Z0-9-]{4,10}$');

-- 2. Justificación: Limita la capacidad máxima de pasajeros de una aeronave comercial a un rango realista (1 a 850).
ALTER TABLE aeronave
    ADD CONSTRAINT ck_aeronave_capacidad_max CHECK (capacidad_total <= 850);

-- 3. Justificación: Establece un límite máximo realista para la distancia de una ruta aérea (máximo 20,000 km).
ALTER TABLE ruta
    ADD CONSTRAINT ck_ruta_distancia_max CHECK (distancia_km <= 20000);

-- 4. Justificación: Valida que el número de vuelo siga el estándar de aerolíneas (2 a 3 letras seguidas de 1 a 4 dígitos, ej. AM123).
ALTER TABLE vuelo
    ADD CONSTRAINT ck_vuelo_numero_formato CHECK (numero_vuelo ~ '^[A-Z0-9]{2,3}[0-9]{1,4}$');

-- 5. Justificación: Valida que el número de asiento tenga el formato estándar de fila y letra (ej. 12A, 1F).
ALTER TABLE asiento
    ADD CONSTRAINT ck_asiento_numero_formato CHECK (numero_asiento ~ '^[0-9]{1,3}[A-Z]$');

-- 6. Justificación: Evita caracteres numéricos o símbolos inválidos en el nombre y apellido paterno del tripulante.
ALTER TABLE tripulante
    ADD CONSTRAINT ck_tripulante_nombre_valido CHECK (nombre !~ '[0-9]' AND apellido_paterno !~ '[0-9]');

-- 7. Justificación: Asegura que el número de licencia de tripulante tenga al menos 5 caracteres alfanuméricos válidos.
ALTER TABLE tripulante
    ADD CONSTRAINT ck_tripulante_licencia_formato CHECK (numero_licencia ~ '^[A-Z0-9-]{5,20}$');

-- 8. Justificación: Limita las horas de vuelo al mando de un piloto a un máximo biológicamente posible (50,000 horas).
ALTER TABLE piloto
    ADD CONSTRAINT ck_piloto_horas_max CHECK (horas_vuelo_comando <= 50000);

-- 9. Justificación: Evita duplicar el mismo idioma registrado para un mismo sobrecargo (ya cubierto por PK, reforzamos formato de texto limpio).
ALTER TABLE sobrecargo_idioma
    ADD CONSTRAINT ck_sobrecargo_idioma_formato CHECK (idioma ~ '^[A-Za-zÁÉÍÓÚáéíóúÑñ ]{3,30}$');

-- 10. Justificación: Garantiza que el número de pasaporte sea alfanumérico en mayúsculas de 6 a 20 caracteres.
ALTER TABLE pasajero
    ADD CONSTRAINT ck_pasajero_pasaporte_formato CHECK (numero_pasaporte ~ '^[A-Z0-9]{6,20}$');

-- 11. Justificación: Asegura que la fecha de nacimiento del pasajero no sea posterior a la fecha actual.
ALTER TABLE pasajero
    ADD CONSTRAINT ck_pasajero_nacimiento_pasado CHECK (fecha_nacimiento <= CURRENT_DATE);

-- 12. Justificación: Valida que la puerta de abordaje en el check-in siga un formato estándar (ej. A12, B4) cuando no sea nula.
ALTER TABLE check_in
    ADD CONSTRAINT ck_checkin_puerta_formato CHECK (puerta_abordaje IS NULL OR puerta_abordaje ~ '^[A-Z0-9]{1,5}$');

-- 13. Justificación: Establece un límite máximo razonable para el precio de un boleto comercial (hasta 500,000.00).
ALTER TABLE boleto
    ADD CONSTRAINT ck_boleto_precio_max CHECK (precio <= 500000.00);

-- 14. Justificación: Evita cadenas vacías o de solo espacios en el nombre de ciudad y país de los aeropuertos.
ALTER TABLE aeropuerto
    ADD CONSTRAINT ck_aeropuerto_texto_no_vacio CHECK (length(trim(ciudad)) > 0 AND length(trim(pais)) > 0);

COMMIT;
