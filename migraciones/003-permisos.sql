-- Migración 003: Definición de Roles y Permisos (Principio de Mínimo Privilegio)
-- Práctica 4 (Punto 1.6) - Bases de Datos

BEGIN;

-- Limpieza previa para que el script sea repetible (idempotente)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rol_mostrador') THEN
        CREATE ROLE rol_mostrador NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rol_operaciones') THEN
        CREATE ROLE rol_operaciones NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rol_auditor') THEN
        CREATE ROLE rol_auditor NOLOGIN;
    END IF;
END
$$;

-- Revocar permisos por defecto en el esquema público por seguridad
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;

-- =====================================================================
-- 1. ROL MOSTRADOR (Ventas, Reservaciones y Check-in)
-- =====================================================================
GRANT USAGE ON SCHEMA public TO rol_mostrador;

-- Solo lectura en catálogos operativos para consultar disponibilidad
GRANT SELECT ON aeropuerto, aeronave, ruta, vuelo, escala, asiento TO rol_mostrador;

-- Gestión completa (lectura, inserción y actualización) en flujo de pasajeros
GRANT SELECT, INSERT, UPDATE ON pasajero, pasajero_telefono, reservacion, boleto, check_in, equipaje TO rol_mostrador;

-- Uso de secuencias (IDENTITY) para poder insertar registros nuevos
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_mostrador;

-- Restricción explícita: no puede borrar registros históricos ni tocar tripulación
REVOKE DELETE ON ALL TABLES IN SCHEMA public FROM rol_mostrador;
REVOKE ALL ON tripulante, piloto, sobrecargo, sobrecargo_idioma, asignacion_tripulacion FROM rol_mostrador;

-- =====================================================================
-- 2. ROL OPERACIONES (Logística de Vuelos, Aeronaves y Tripulación)
-- =====================================================================
GRANT USAGE ON SCHEMA public TO rol_operaciones;

-- Control total sobre infraestructura aérea, vuelos y tripulaciones
GRANT SELECT, INSERT, UPDATE, DELETE ON aeropuerto, aeronave, ruta, vuelo, escala, asiento TO rol_operaciones;
GRANT SELECT, INSERT, UPDATE, DELETE ON tripulante, piloto, sobrecargo, sobrecargo_idioma, asignacion_tripulacion TO rol_operaciones;

-- Solo lectura sobre boletos y check-in para validar manifiesto de abordaje y peso de equipaje
GRANT SELECT ON boleto, check_in, equipaje TO rol_operaciones;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_operaciones;

-- Restricción explícita: sin acceso a datos personales/pasaportes de pasajeros ni reservaciones
REVOKE ALL ON pasajero, pasajero_telefono, reservacion FROM rol_operaciones;

-- =====================================================================
-- 3. ROL AUDITOR (Consultas y Reportes - Solo Lectura)
-- =====================================================================
GRANT USAGE ON SCHEMA public TO rol_auditor;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_auditor;

-- Restricción explícita: prohibida cualquier modificación de datos
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA public FROM rol_auditor;

COMMIT;
