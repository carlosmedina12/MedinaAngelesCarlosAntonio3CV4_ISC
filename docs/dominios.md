# Documentación de Dominios y Tipos de Datos (Parte 1.1 y 1.2)

## 1. Justificación de Tipos de Datos por Tabla

| Tabla | Columna | Tipo de Dato | Justificación del Tipo de Dato |
| :--- | :--- | :--- | :--- |
| **aeropuerto** | `codigo_iata` | `CHAR(3)` | Los códigos IATA internacionales tienen exactamente 3 caracteres fijos. |
| **aeropuerto** | `nombre`, `ciudad`, `pais` | `VARCHAR(100/80/60)` | Longitud variable para optimizar almacenamiento según la extensión esperada de nombres geográficos. |
| **aeronave** | `matricula` | `VARCHAR(10)` | Identificador alfanumérico corto de longitud variable según el país de registro. |
| **aeronave** | `capacidad_total` | `SMALLINT` | Entero de 2 bytes (hasta 32,767), suficiente y eficiente para la capacidad de asientos de cualquier avión. |
| **ruta** | `id_ruta` | `INTEGER` | Clave subrogada autoincremental (`IDENTITY`) estándar para catálogos de rutas. |
| **ruta** | `distancia_km` | `INTEGER` | Entero suficiente para representar distancias terrestres/aéreas en kilómetros sin decimales innecesarios. |
| **vuelo** | `salida_programada`, `llegada_estimada` | `TIMESTAMP` | Almacena fecha y hora exacta de operación del vuelo para calcular duraciones y retrasos. |
| **vuelo** | `estado` | `VARCHAR(12)` | Cadena corta para estados controlados (`PROGRAMADO`, `RETRASADO`, `CANCELADO`, `COMPLETADO`). |
| **escala** | `numero_secuencia`, `duracion_min` | `SMALLINT` | Valores pequeños positivos (orden de escala y minutos de espera) que ahorran espacio frente a `INTEGER`. |
| **asiento** | `numero_asiento` | `VARCHAR(4)` | Combinación corta de número de fila (1-3 dígitos) y letra de columna (ej. `12A`). |
| **tripulante** | `nombre`, `apellido_paterno`, `apellido_materno` | `VARCHAR(60)` | Permite nombres compuestos; `apellido_materno` acepta `NULL` por estándares internacionales. |
| **piloto** | `horas_vuelo_comando` | `INTEGER` | Contador acumulativo de horas enteras de vuelo que puede superar el rango de `SMALLINT`. |
| **sobrecargo** | `certificacion_primeros_auxilios` | `BOOLEAN` | Tipo lógico nativo (`TRUE`/`FALSE`) para indicar cumplimiento de certificación. |
| **pasajero** | `fecha_nacimiento` | `DATE` | Solo requiere año, mes y día para validar mayoría de edad o rangos históricos. |
| **boleto** | `precio` | `NUMERIC(10,2)` | Tipo decimal exacto indispensable para montos monetarios, evitando errores de redondeo de punto flotante. |
| **equipaje** | `peso_kg` | `NUMERIC(5,2)` | Precisión decimal exacta de hasta 999.99 kg con dos decimales para control de báscula. |

---

## 2. Nuevas Restricciones de Dominio Agregadas (`001-dominios.sql`)

| Tabla | Restricción | Tipo | Regla Aplicada |
| :--- | :--- | :--- | :--- |
| `aeronave` | `ck_aeronave_matricula_formato` | `CHECK` | `matricula ~ '^[A-Z0-9-]{4,10}$'` |
| `aeronave` | `ck_aeronave_capacidad_max` | `CHECK` | `capacidad_total <= 850` |
| `ruta` | `ck_ruta_distancia_max` | `CHECK` | `distancia_km <= 20000` |
| `vuelo` | `ck_vuelo_numero_formato` | `CHECK` | `numero_vuelo ~ '^[A-Z0-9]{2,3}[0-9]{1,4}$'` |
| `asiento` | `ck_asiento_numero_formato` | `CHECK` | `numero_asiento ~ '^[0-9]{1,3}[A-Z]$'` |
| `tripulante` | `ck_tripulante_nombre_valido` | `CHECK` | `nombre !~ '[0-9]' AND apellido_paterno !~ '[0-9]'` |
| `tripulante` | `ck_tripulante_licencia_formato` | `CHECK` | `numero_licencia ~ '^[A-Z0-9-]{5,20}$'` |
| `piloto` | `ck_piloto_horas_max` | `CHECK` | `horas_vuelo_comando <= 50000` |
| `sobrecargo_idioma` | `ck_sobrecargo_idioma_formato` | `CHECK` | `idioma ~ '^[A-Za-zÁÉÍÓÚáéíóúÑñ ]{3,30}$'` |
| `pasajero` | `ck_pasajero_pasaporte_formato` | `CHECK` | `numero_pasaporte ~ '^[A-Z0-9]{6,20}$'` |
| `pasajero` | `ck_pasajero_nacimiento_pasado` | `CHECK` | `fecha_nacimiento <= CURRENT_DATE` |
| `check_in` | `ck_checkin_puerta_formato` | `CHECK` | `puerta_abordaje IS NULL OR puerta_abordaje ~ '^[A-Z0-9]{1,5}$'` |
| `boleto` | `ck_boleto_precio_max` | `CHECK` | `precio <= 500000.00` |
| `aeropuerto` | `ck_aeropuerto_texto_no_vacio` | `CHECK` | `length(trim(ciudad)) > 0 AND length(trim(pais)) > 0` |
