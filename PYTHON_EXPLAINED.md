# Generador de Dataset de Comercio Online

Este proyecto tiene como objetivo la generación de un dataset sintético que simula la actividad de un comercio electrónico. A partir de datos reales y técnicas de generación aleatoria, se construyen múltiples tablas relacionadas entre sí, respetando la integridad referencial y manteniendo coherencia en los datos.

El resultado final es un conjunto de **8 tablas** que representan distintas entidades del negocio (productos, clientes, pedidos, etc.), junto con un módulo de validación que permite comprobar la calidad y consistencia de los datos generados.

## Datos usados como base

El dataset se construye a partir de dos fuentes principales en formato .csv:

- **`basket_products.csv`**: contiene información sobre productos, categorías, marcas, precios y valoraciones.
- **`nyc_marathon_results.csv`**: basado en los resultados de la maratón de Nueva York 2024, utilizado para generar clientes y trabajadores.

Estos datos sirven como base para construir entidades más complejas y enriquecerlas con atributos sintéticos como fechas, emails, ubicaciones o métricas de negocio.

## Módulo `src`

El núcleo del proyecto se encuentra en el módulo `src`, donde se implementan todas las funciones necesarias para crear, transformar y validar los datos.

---

### Importación de datos y funciones reutilizables (`io.py` y `utils.py`)

Este submódulo contiene funciones auxiliares clave:

#### `io.py`
- Encargado de la carga y guardado de archivos .csv

#### `utils.py`

Incluye funciones reutilizables para manipulación y generación de datos:

- **Transformación de datos**:
  - *cut_df*: recorta un DataFrame.
  - *create_dict*: crea diccionarios a partir de columnas.
  - *create_df*: construye DataFrames desde diccionarios.

- **Generación sintética**:
  - *create_email*: genera emails realistas con diferentes patrones.
  - *next_restock*: calcula fechas de reposición según el stock.
  - *choose_worker*: asigna trabajadores a pedidos respetando país y fecha de contratación.

Estas funciones permiten mantener el código modular, reutilizable y fácil de escalar.

### Creación del dataset (`data_creation.py`)

Este módulo contiene la lógica principal de generación de datos. Se divide en tres bloques principales:

#### Datos de productos

Función: *create_product_tables*

Genera las siguientes tablas:
- **Categorías**
- **Marcas**
- **Productos**
- **Inventario**

Características:
- Asignación coherente de categorías y marcas.
- Generación de precios y ratings.
- Simulación de stock según categoría.
- Fechas de reposición realistas.

#### Datos de personas

Función: *create_people_tables*

Genera:
- **Clientes**
- **Trabajadores**

Características:
- Nombres extraídos del dataset base.
- Generación de:
  - fechas de nacimiento
  - emails
  - país y ciudad
  - fechas de suscripción o contratación
- Diferencias entre países en:
  - fecha de inicio de actividad
  - salario base


#### Pedidos y detalles

Función: *create_orders_tables*

Genera:
- **Pedidos**
- **Detalles de pedidos**

Características:
- Relación entre clientes, productos y trabajadores.
- Simulación de comportamiento de compra:
  - fechas de pedido coherentes
  - número variable de productos por pedido
  - cantidades dependientes del stock
- Cálculo automático de:
  - precio por producto
  - total por línea
  - total por pedido

### Validación de datos (`data_validation.py`)

Este módulo permite analizar la calidad del dataset generado mediante distintos tipos de comprobaciones:

#### Exploración básica
- *quality_check*: resumen de columnas con:
  - tipo de dato
  - valores únicos
  - nulos
  - duplicados

#### Validaciones específicas

- *check_duplicates*: verifica unicidad de columnas clave.
- *check_orphan_fk*: detecta claves foráneas sin correspondencia.
- *check_dates*: valida coherencia temporal (por país).
- *check_metrics*: detecta valores inválidos en métricas (ej.: precios nulos o cero).

#### Validación completa

- *full_check*: ejecuta todas las validaciones anteriores de forma configurable.

## Problemas durante la creación

El archivo `basket_products.csv` tiene 40.228 filas. Por otra parte, el archivo `nyc_marathon_results.csv` tiene 1.460.287 filas. 

La idea original era construir las tablas del dataset final usando todos los datos disponibles pero a lo largo del proceso surgieron los siguientes problemas:

* **Archivos muy pesados para DBeaver:** originalmente se contemplaba usar 1.000.000 de orders para que cada usuario (se cogieron 100.000 nombres de `nyc_marathon_results.csv`) tuviera la oportunidad de hacer varios pedidos. Igualmente, se pretendía que cada producto apareciera varias veces, lo que llevó a tener casi 5.000.000 de detalles de pedidos. El tiempo de carga de estas tablas al completo (la de detalles dividida en 9 partes) era de más de 30 minutos. Por motivos de reproducibilidad se han reducido a 50.000 orders y 423.919 detalles.

* **Demasiados productos para la cantidad de compras:** al reducir el número de compras, los productos (en general) se compraban entre 40 y 50 veces sólo en 11 años y tres países, teniéndo además stocks 100 más alto de lo que históricamente se ha vendido. Se reducen entonces el total de productos usados de 40.228 a 500.

* **Quality checks desactualizados:** en el archivo `04_quality_checks.sql` hay una sección dedicada a corregir un supuesto error sobre una marca desconocida (producida por un producto cuya marca no estaba registrada) que en lso datos modificados no existe. Esto se debe a que dicho producto tenía un indice superior a 500 y por lo tanto ya no se incluye en los datos. Aún así se ha dejado la corrección del error como ejemplo en el caso de que, si se vuelven a generar datos y se toma el producto, pueda corregirse automáticamente.
