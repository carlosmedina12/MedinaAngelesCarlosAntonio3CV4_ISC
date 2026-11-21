# Pruebas de Violación de Restricciones de Dominio (Parte 1.5)

A continuación se documentan **10 casos de prueba** diseñados para verificar que las restricciones (`CHECK`, `NOT NULL`, `UNIQUE`) definidas en el esquema y en `001-dominios.sql` rechazan datos inválidos.

---

### Prueba 1: Formato inválido en matrícula de aeronave (`ck_aeronave_matricula_formato`)
* **Sentencia SQL:**

      INSERT INTO aeronave (matricula, modelo, fabricante, capacidad_total)
      VALUES ('xa_12', 'Boeing 737', 'Boeing', 180);

* **Resultado esperado en PostgreSQL:**
  `ERROR: new row for relation "aeronave" violates check constraint "ck_aeronave_matricula_formato"`
* **Explicación:** La matrícula contiene letras minúsculas y guion bajo, violando la expresión regular `^[A-Z0-9-]{4,10}$`.

---

### Prueba 2: Capacidad de aeronave excede el máximo comercial (`ck_aeronave_capacidad_max`)
* **Sentencia SQL:**

      INSERT INTO aeronave (matricula, modelo, fabricante, capacidad_total)
      VALUES ('XA-MAX', 'Airbus A380-Plus', 'Airbus', 950);

* **Resultado esperado en PostgreSQL:**
  `ERROR: new row for relation "aeronave" violates check constraint "ck_aeronave_capacidad_max"`
* **Explicación:** El valor `950` supera el límite máximo permitido de `850` pasajeros.

---

### Prueba 3: Ruta aérea con mismo aeropuerto de origen y destino (`ck_ruta_origen_destino`)
* **Sentencia SQL:**

      INSERT INTO ruta (codigo_origen, codigo_destino, distancia_km)
      VALUES ('MEX', 'MEX', 500);

* **Resultado esperado en PostgreSQL:**
  `ERROR: new row for relation "ruta" violates check constraint "ck_ruta_origen_destino"`
* **Explicación:** No puede existir una ruta comercial donde el origen y el destino sean idénticos (`codigo_origen <> codigo_destino`).

---

### Prueba 4: Distancia de ruta fuera de rango terrestre/aéreo (`ck_ruta_distancia_max`)
* **Sentencia SQL:**

      INSERT INTO ruta (codigo_origen, codigo_destino, distancia_km)
      VALUES ('MEX', 'NRT', 25000);

* **Resultado esperado en PostgreSQL:**
  `ERROR: new row for relation "ruta" violates check constraint "ck_ruta_distancia_max"`
* **Explicación:** `25000` km excede el límite superior de `20000` km establecido para una ruta directa.

---

### Prueba 5: Formato inválido en número de vuelo (`ck_vuelo_numero_formato`)
* **Sentencia SQL:**

      INSERT INTO vuelo (numero_vuelo, id_ruta, matricula_aeronave, salida_programada, llegada_estimada)
      VALUES ('VUELO-X', 1, 'XA-ABC', '2026-11-10 08:00:00', '2026-11-10 10:00:00');

* **Resultado esperado en PostgreSQL:**
  `ERROR: new row for relation "vuelo" violates check constraint "ck_vuelo_numero_formato"`
* **Explicación:** El código de vuelo no cumple el formato estándar de aerolínea (
