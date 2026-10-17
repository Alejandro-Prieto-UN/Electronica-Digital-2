# Laboratorio 02 - Diseño, simulación e implementación de una ALU de 4 bits

### NOMBRES PARTICIPANTES

- Jhohan Stiven Rodríguez Rodríguez
- Alejandro Brandon Prieto León
- Ángel Alirio Rivera Amortegui
# Informe de Práctica de Laboratorio - Electrónica Digital II

## 1. Explicación general del funcionamiento del sistema

El sistema desarrollado corresponde a una **Unidad Aritmético Lógica (ALU) de 4 bits** implementada sobre la tarjeta de desarrollo **Zybo Z7-20** (FPGA Zynq-7000). El objetivo principal del sistema es procesar dos operandos de 4 bits (`A` y `B`) mediante cuatro operaciones distintas (Suma, Resta, AND y OR), mostrando el resultado en un conjunto de LEDs y el estado de la operación mediante un LED RGB.

El funcionamiento general del sistema se divide en tres etapas principales:

1. **Captura y Almacenamiento de Datos (Entradas):**
   * El sistema utiliza los 4 conmutadores de la tarjeta (`SW0` a `SW3`) como un bus de entrada de datos común.
   * Los operandos `A` y `B` se capturan en registros internos mediante sincronización por reloj (125 MHz). Al presionar el botón `BTN0`, el valor actual de los switches se almacena en el registro `A`. Al presionar el botón `BTN1`, el valor se almacena en el registro `B`.
   * El código de operación (`opcode` de 2 bits) se gestiona de forma persistente a través de los botones `BTN2` y `BTN3`, los cuales alternan los bits individualmente mediante detectores de flanco de subida.

## 2. **Procesamiento de Datos (ALU):**
   * Los registros de los operandos `A` y `B`, junto con el registro de `opcode`, se entregan al módulo combinacional de la ALU (`alu.v`).
   * La ALU ejecuta la operación seleccionada de forma instantánea según el `opcode`:
     * `00`: Suma (`A + B`)
     * `01`: Resta (`A - B`)
     * `10`: Operación lógica AND bit a bit (`A & B`)
     * `11`: Operación lógica OR bit a bit (`A | B`)

# 3. **Visualización de Resultados (Salidas):**
   * **LEDs Verdes (`LED0` - `LED3`):** Muestran directamente el resultado de 4 bits calculado por la ALU.
   * **LED RGB (`RGB_R`, `RGB_G`, `RGB_B`):** Codifica visualmente la operación seleccionada en la ALU para facilitar la identificación del estado actual del sistema (Verde = Suma, Rojo = Resta, Azul = AND, Amarillo = OR).
## 4. Tabla de operaciones implementadas

La Unidad Aritmético Lógica (`alu.v`) evalúa los operandos de 4 bits `A` y `B` mediante lógica combinacional simple pura, guiada por un código de operación (`opcode`) de 2 bits[cite: 2]. A continuación se detallan las operaciones implementadas[cite: 2]:

| Operación | Código de Operación (`opcode`) | Expresión Verilog | Descripción |
| :---: | :---: | :---: | :--- |
| **Suma** | `00` | `result = A + B;` | Realiza la adición aritmética entre `A` y `B`. |
| **Resta** | `01` | `result = A - B;` | Realiza la sustracción aritmética de `A` menos `B`. |
| **AND** | `10` | `result = A & B;` | Realiza una operación lógica AND bit a bit. |
| **OR** | `11` | `result = A | B;` | Realiza una operación lógica OR bit a bit. |

---

## 5. Explicación de la forma en que se almacenan los operandos

El almacenamiento de los operandos se realiza mediante un esquema de **bus compartido de entrada de datos** conectado a **Flip-Flops de tipo D con habilitador**, los cuales operan de forma síncrona con el flanco de subida del reloj del sistema (`clk` a 125 MHz)[cite: 4].

1. **Multiplexión mediante Bus Único:** Se utilizan únicamente 4 conmutadores físicos (`SW[3:0]`) para ingresar los datos tanto de `A` como de `B`[cite: 4].
2. **Lógica de Carga (Enable):** 
   * Al presionar el botón **BTN0** (`if (BTN[0])`), en el siguiente flanco activo del reloj el valor presente en la entrada `SW` se transfiere al registro interno `reg [3:0] A`[cite: 4].
   * Al presionar el botón **BTN1** (`if (BTN[1])`), el valor de `SW` se transfiere al registro interno `reg [3:0] B`[cite: 4].
3. **Persistencia:** Una vez liberado el botón correspondiente, las asignaciones no entran en sus bloques de actualización, reteniendo el valor capturado en los Flip-Flops hasta una nueva captura, sin importar si la posición de los conmutadores `SW` cambia posteriormente[cite: 3, 4].

---

## 6. Explicación de la forma en que se conserva el código de operación

Para mantener y seleccionar el código de operación (`reg [1:0] opcode`) de 2 bits sin necesidad de conmutadores dedicados, se implementó un mecanismo de **conmutación de estado persistente por detección de flanco de subida** sobre los botones `BTN2` y `BTN3`[cite: 4]:

1. **Registros Auxiliares para Flanco:** Se emplean las señales auxiliares `btn2_prev` y `btn3_prev` para registrar en cada ciclo de reloj el estado previo de los botones[cite: 4].
2. **Detección de Flanco de Subida:** En el bloque secuencial controlado por `posedge clk`, la condición `BTN[2] && !btn2_prev` identifica de manera precisa el momento exacto en el que el botón pasa de un estado bajo (`0`) a un estado alto (`1`)[cite: 4].
3. **Alternancia de Bits (Toggle):** 
   * Cada pulso detectado en **BTN2** invierte el bit menos significativo: `opcode[0] <= ~opcode[0]`[cite: 4].
   * Cada pulso detectado en **BTN3** invierte el bit más significativo: `opcode[1] <= ~opcode[1]`[cite: 4].
4. **Persistencia:** Puesto que las asignaciones solo ocurren durante el ciclo exacto del flanco ascendente, el registro `opcode` mantiene intacto su valor de 2 bits entre pulsaciones, asegurando que la operación seleccionada se conserve estable mientras la ALU opera[cite: 4].
## 7. Tabla con los colores utilizados para identificar cada operación mediante el LED RGB

| Operación | Código (Opcode) | Color del LED RGB | R | G | B |
| :---: | :---: | :---: | :---: | :---: | :---: |
|           |     `000`       |                   |   |   |   |
|           |     `001`       |                   |   |   |   |

## 8. Capturas de GTKWave

### 8.1. Simulación General
![Simulación GTKWave Generales](ruta/a/tu/imagen_gtkwave_1.png)

### 8.2. Casos de Prueba Especificos
![Casos de Prueba](ruta/a/tu/imagen_gtkwave_2.png)

## 9. Explicación del comportamiento observado durante la simulación

<!-- Analiza los resultados vistos en las señales de GTKWave para justificar el correcto funcionamiento -->

## 10. Evidencia de la implementación funcional en FPGA

![Foto o GIF de la FPGA funcionando](ruta/a/tu/imagen_fpga.jpg)

<!-- Agrega una breve explicación o descripción de la prueba sobre la tarjeta FPGA -->
