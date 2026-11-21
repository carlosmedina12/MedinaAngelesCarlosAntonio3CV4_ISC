# Roles y Permisos (Principio de Mínimo Privilegio - Parte 1.6)

Para garantizar la seguridad e integridad de la base de datos de la aerolínea, se revocaron los permisos globales de `PUBLIC` y se crearon **3 roles operativos** con permisos estrictamente acotados a sus funciones:

| Rol | Privilegios Otorgados (`GRANT`) | Privilegios Revocados (`REVOKE`) | Justificación (Mínimo Privilegio) |
| :--- | :--- | :--- | :--- |
| **`rol_mostrador`** | `SELECT` en catálogos de vuelos/asientos; `SELECT, INSERT, UPDATE` en `pasajero`, `reservacion`, `boleto`, `check_in` y `equipaje`. | `DELETE` en todas las tablas; `ALL` en tablas de `tripulante`, `piloto` y `sobrecargo`. | El personal de atención al cliente necesita vender boletos y documentar equipaje, pero no debe alterar itinerarios de vuelo, borrar historial financiero ni acceder a datos internos de la tripulación. |
| **`rol_operaciones`** | `SELECT, INSERT, UPDATE, DELETE` en `aeropuerto`, `aeronave`, `ruta`, `vuelo`, `escala`, `asiento` y tablas de tripulación; `SELECT` en `boleto`, `check_in` y `equipaje`. | `ALL` en `pasajero`, `pasajero_telefono` y `reservacion`. | El área de control operativo programa vuelos, asigna pilotos/sobrecargos y revisa el peso total del equipaje abordado, sin requerir acceso a datos personales sensibles (pasaportes, teléfonos) ni pagos de los clientes. |
| **`rol_auditor`** | `SELECT` en todas las tablas del esquema `public`. | `INSERT, UPDATE, DELETE, TRUNCATE` en todas las tablas. | Permite a analistas y auditores generar reportes financieros y operativos sin riesgo de alterar o eliminar registros de producción. |
