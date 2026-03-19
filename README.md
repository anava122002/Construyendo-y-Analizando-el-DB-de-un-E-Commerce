# SQL PROJECT: building and analysing an online supermarket's dataset

Este proyecto simula la base de datos de una plataforma de e-commerce que opera en tres países: Reino Unido, Irlanda y Canadá. El objetivo es analizar su contenido para obtener insights sobre rendimiento del negocio en base a una serie de preguntas preestablecidas.

## Estructura del Proyecto
```text
f1_showcase_project/
    data/
        base_data/
            basket_products.csv
            nyc_marathon_results.csv
        raw_data/
            br_data.csv
            ca_data.csv
            cu_data.csv
            de_data.csv
            in_data.csv
            or_data.csv
            pr_data.csv
            wo_data.csv
    sql/
        01_schema.sql
        02_load_staging.sql
        03_transform_core.sql
        04_quality_checks.sql
        05_semantic_queries.sql
        06_analysis_queries.sql
    src/
        __init__.py
        data_creation.py
        data_validation.py
        io.py
        utils.py
    main.py
    README.md
    PYTHON_EXPLAINED.md
    requirements.txt
```

## Dataset
Trabajaremos con un dataset sintético que simula la evolución de un e-commerce. Está diseñado de forma que refleje el crecimiento del negocio desde su apertura en UK en 2015, pasando por su expansión a Irlanda (2017) y Canadá (2020), hasta la fecha actual. 

Contiene datos dimensionales tanto de productos y marcas como de clientes y trabajadores de cada país, además de datos transaccionales de las reposiciones de inventario, pedidos y detalles sobre los productos comprados en cada pedido. 

Una descripción detallada de su creación se encuentra en [PYTHON_EXPLAINED.md](PYTHON_EXPLAINED.md).

Los datos a partir de los cuales se ha construido el dataset provienen de:

* **Productos, categorías, marcas y precios:** [BigBasket Entire Product List](https://www.kaggle.com/datasets/surajjha101/bigbasket-entire-product-list-28k-datapoints)

* **Nombres de clientes y trabajadores:** [NYC Marathon Results](https://www.kaggle.com/datasets/runningwithrock/nyc-marathon-results-all-years)

A continuación se especifican las características de las tablas del dataset final:

* **Products (`pr_data.csv`):** x filas; y columnas. 
    * *Variables clave:* product_id, product_name, product_price.
* **Categories (`ca_data.csv`):** x filas; y columnas. 
    * *Variables clave:* category_id, category.
* **Brands (`br_data.csv`):** x filas; y columnas. 
    * *Variables clave:* brand_id, brand.
* **Inventary (`in_data.csv`):** x filas; y columnas. 
    * *Variables clave:* product_id, stock, last_restock.
* **Customers (`cu_data.csv`):** x filas; y columnas. 
    * *Variables clave:* customer_id, country, subscription_date.
* **Workers (`wo_data.csv`):** x filas; y columnas. 
    * *Variables clave:* worker_id, country, hired_date, hours_day, salary_day.
* **Orders (`or_data.csv`):** x filas; y columnas. 
    * *Variables clave:* order_id, customer_id, worker_id, order_date, total_paid.
* **Order Details (`de_data.csv`):**  x filas; y columnas. 
    * *Variables clave:* detail_id, order_id, product_id, quantity, total_price.  

<br>

```mermaid
flowchart TD

A[PRODUCTS] --> B[CATEGORY]
A --> C[BRANDS]

D[INVENTORY] --> A
D --> B
D --> C

E[ORDERS] --> F[CUSTOMERS]
E --> G[WORKERS]

H[ORDER DETAILS] --> E
H --> A

```

</br>



## Línea de Análisis: Evolución del Comercio por País

El negocio online opera en tres países: Reino Unido, Irlanda y Canadá. Queremos estudiar y comparar su evolución en cada país para buscar similitudes y posibles diferenciaciones.

El análisis se centrará en tres grupos de preguntas:

* **Ventas por país. Evolución y comportamiento:** se pretende analizar cómo se distribuyen las ventas entre los distintos países y cómo evoluciona la actividad comercial en cada mercado. Esto permite identificar mercados más activos, patrones temporales de compra y posibles diferencias en el comportamiento del consumidor. Algunas preguntas clave son:
    * ¿Qué países generan **mayor volumen de ventas** y cuál es su **contribución al total**?
    * ¿Existen **diferencias en el valor medio de los pedidos** entre países?
* **Productos por país. Aceptación del producto y consumo:** se exploran qué productos tienen mayor aceptación en cada mercado y si existen diferencias en las preferencias de consumo entre países. Algunas preguntas claves son:
    * ¿Cuáles son los **productos más vendidos** globalmente?
    * ¿Cambian las **preferencias de producto según el país**?
    * ¿Qué **categorías generan más ingresos**?
* **Factor humano. Clientes y trabajadores:** se analizan los hábitos de consumo de los clientes y la actividad de los trabajadores implicados en la gestión de pedidos. Algunas preguntas claves son:
    * ¿Cuál es la **frecuencia de compra** de los clientes?
    * ¿Existen **clientes con alto volumen de pedidos**?
    * ¿Existen **trabajadores con mayor carga de actividad**?
    * ¿Hay diferencias en la **actividad por país**?


## Arquitectura de datos

El proyecto implementa una arquitectura de datos en tres capas: staging, core y semantic, que permite separar la ingestión de datos, la transformación y el análisis final.

### Staging Layer (`01_schema.sql` y `02_load_staging.sql`)

Se crea la base de datos *sql_project* en MySQL. Posteriormente se eliminan y crean las tablas de staging donde se importarán los datos raw desde los .csv como cadenas de caracteres, además de eliminar y crear las tablas de datos dimensionales y transaccionales.

Antes de pasar a poblar estas tablas se llevan a cabo checks de volumen y parsability para confirmar la integridad de los datos.

### Core Layer (`03_transform_core.sql` y `04_quality_checks.sql`)

Se define un procedure (*sp_refresh_core*) que permite poblar las tablas una a una y guardar el progreso en snapshots que diferencian el almacenado en etapas y funcionan como puntos de control. También guarda sus nuevas dimensiones para presentarlas al final del proceso a modo de sanity check.

A la hora de transformar e insertar los datos desde las tablas de staging se aplica la función NULLIF a los campos que se han definido como NOT NULL para provocar un fallo en caso de que uno de los valores esté vacío.

Se verifica la calidad de los datos mediante la búsqueda de nulos, claves foráneas huérfanas, entradas duplicadas en las tablas transaccionales, rango de fechas (se busca coincidencia con las fechas de ampliación del negocio), métricas no válidas (nulas o negativas) y nombres de países incorrectos.

### Semantic Layer (`05_semantic_views.sql`)

Se amplía la información de las tablas dimensionales principales para el análisis (*dim_products*, *dim_customers* y *dim_workers*):

* *vw_products_enriched*: se añaden nombres de categorías y marcas, stock y fecha de restock desde *fct_inventory*, total de unidades compradas y las ganancias.

* *vw_customers_enriched*: se añade un campo con el nombre completo (que sustituye a *first_name* y *last_name*), edad, total de compras, total de gasto y total de productos comprados.

* *vw_workers_enriched*: se añade un campo con el nombre completo (que sustituye a *first_name* y *last_name*), edad, sueldo mensual y total de pedidos preparados.

Se crean las siguientes KPIs:

* *vw_countries_kpi*: se incluye el total de pedidos, productos comprados, ganancias, total de clientes y trabajadores, media de pedidos por cliente, media de productos comprados por pedido y media de ganancia por pedido por país y año.

* *vw_categories_kpi*: total de productos por categoría, precio medio, stock promedio, total de productos comprados y total de ganancias por categoría.

* *vw_brands_kpi*: similar a *vw_categories_kpi*.

## Análisis 

A continuación se muestran las conclusiones obtenidas de las vistas calculadas en `06_analysis_queries.sql`.

### Ventas por país. Evolución y comportamiento

A nivel general, el comercio cuenta con un total de 423.918 pedidos realizados y las ganancias ascienden a 22.746.691,93€, con una media de 53,66€ ganados por pedido. El mercado canadiense supone el 41,93% del mercado total (177.752 pedidos), sólo un 0,12% por delante de Reino Unido (174.708 pedidos), y un total de ganancias de 9.399.717,55€. El país con menos actividad es Irlanda con un 16,86% del total de pedidos y unas ganancias de 3.823.733€.

Puesto que los mercados no iniciaron su actividad en el mismo año, es interesante estudiar las medias de las métricas por año. Volvemos a ver como Canadá es el mercado líder con una ganancia media de 1.371.388,22€ por año y 25.393 pedidos, seguido de Reino Unido (776.936€) e Irlanda (388.373,69€). Sabiendo que el comercio no empezó a operar en Canadá hasta 2020, podemos asumir que ha sido el que mayor crecimiento ha sufrido desde su inicio, llegando a superar en 6 sólo años a los mercados de Reino Unido e Irlanda de 11 y 9 años respectivamente.

Finalmente, vemos como la diferencia media de ganancias por pedido oscila en los tres casos entre los 45€ y 60€ con una variabilidad de aproximadamente 1,23€ para Irlanda y Canadá, y de casi 2€ para Reino Unido, que además tiene en promedio los pedidos más baratos (de 53,36€ frente a los 53,51€ Irlanda y 54€ de Canadá).

Podemos concluir entonces que el mercado más rentable y con mayor crecimiento actualmente es Canadá, teniendo tanto las mayores ganancias absolutas y medias como el mayor número de pedidos de los tres mercados. 

### Productos por país. Aceptación del producto y consumo

Los productos más populares son todos de la categoría 'Fruits & Vegetables', con precios que no superan los 0,50€ por unidad. El más popular,  'Drumstick - Organically Grown', se ha comprado un total de 5.303 unidades y ha proporcionado una ganancia de 862,49€. Otros productos, como 'Pomegranate - Single Serve', 'Banana - Red' o 'Zucchini - Green', se han vendido en hasta 500 unidades menos pero han aportado unas ganancias de entre 2.000 y 3.000, hasta un 28,75% más.

Las categorías más populares son 'Beauty & Hygiene', 'Kitchen, Garden & Pets' y 'Gourmet & World Food'. Parece que 'Fruits & Vegetables' es una de las menos populares a pesar de tener los productos más comprados. Podemos asumir que el resto de categorías ofertan más productos aunque se compran individualmente mientras que los de 'Fruits & Vegetables' se compran en grupo. Al calcular las mismas métricas para las marcas, vemos que son marcas de 'Fruits & Vegetables', como 'Fresho', 'Sunfeast' o 'Amul', las más populares pero las que más ganancias generan son las de 'Beauty & Hygiene', como 'Ajmul', 'Prestige' o 'Cello', confirmando la hipótesis anterior.

Los 5 productos más populares por país son, en general, los mismos. Vemos como en Reino Unido y especialmente en Irlanda se consume 'Coriander Leaves 100 g + Garlic 250 g + Ginger 250 g + Chilli Green Long 250 g'. 'Drumstick - Organically Grown' se coloca como el favorito en los tres países aunque con una diferencia menor a 100 unidades vendidas con respecto al siguiente producto.

### Factor humano. Clientes y trabajadores

Si agrupamos los clientes por ciudad no vemos diferencias notorias. Todos los clientes tienen una edad entre los 18 y 79 años, con una media que oscila entre los 47 y 50 años. Los pedidos se mueven entre las 33.000 y 40.000, siendo Londres la ciudad con menos pedidos (32.894 pedidos y 1734585.42€) y Dublín la que más (3.6726 pedidos y 1973008.86€). Es notorio ver que el mercado canadiense  se ajusta tanto a los estándares de, por ejemplo, el inglés, teniendo en cuenta que es el último en empezar a operar con diferencia.

La frecuencia de compra de los clientes es una sorpresa. Vemos como hay clientes que llegan a dejar pasar hasta casi 300 días de media sin comprar, casi un año. El mercado más activo vuelve a ser el canadiense, con una media de una compra cada 138 días. El mercado inglés parece ser bastante más lento, llegando a pasar de media 284 días sin compras, habiendo un total de hasta 3.188 días entre compra y compra, más de 1.500 en comparación a Canadá y casi 1.000 en comparación a Irlanda (que tiene una media de 232 días entre compra y compra).

Como podíamos intuir, la mayoría de clientes con mayor volumen de compras son canadienses. El cliente con más compras es Yann Borgne, canadiense, que se suscribió en 2025 y desde entonces ha hecho un total de 144 pedidos con un valor de 8.153,02€.  El segundo en Juan Moyano, también canadiense y cliente desde 2025, que ha hecho 140 pedidos por un total de 8.348,12€, algo más que el cliente anterior. 

Por último, vemos como la carga de trabajo ha aumentado con los años. Concretamente, vemos como los trabajadores contratados más recientemente son los que tienen más carga de trabajo de media por año. El top 10 de trabajadores con mayor carga de trabajo se compone únicamente de canadienses, lo que vuelve a mostrar cómo este mercado es el que mayor subida ha tenido.

## Replicación del proyecto

* Ejecutar archivo `01_schema.sql` e importar los datos manualmente a las tablas de staging usando los .csv de `raw_data`.

* Ejecutar archivo `03_transform_core.sql` para insertar datos en las tablas de dimensión y transacción.

* Por seguridad, ejecutar archivos  `02_load_staging.sql` y `03_quality_checks.sql` después de cada paso para validar datos.