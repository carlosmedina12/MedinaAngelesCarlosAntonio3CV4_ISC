# Pruebas de Violación de Restricciones de Dominio (Parte 1.5)

A continuación se documentan **10 casos de prueba** diseñados para verificar que las restricciones (`CHECK`, `NOT NULL`, `UNIQUE`) definidas en el esquema y en `001-dominios.sql` rechazan datos inválidos.

---

### Prueba 1: Formato inválido en matrícula de aeronave (`ck_aeronave_matricula_formato`)
* **Sentencia SQL:**
  ```sql
  INSERT INTO aeronave (matricula, modelo, fabricante, capacidad_total)
  VALUES ('xa_12', 'Boeing 737', 'Boeing', 180);
INSERT INTO aeronave (matricula, modelo, fabricante, capacidad_total)
VALUES ('XA-MAX', 'Airbus A380-Plus', 'Airbus', 950);
