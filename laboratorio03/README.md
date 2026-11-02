# Laboratorio 03 - ALU + Banco de Registros + Diseño Modular

### NOMBRES PARTICIPANTES

- Jhohan Stiven Rodríguez Rodríguez
- Alejandro Brandon Prieto León
- Ángel Alirio Rivera Amortegui

---

## 1. Descripción del Sistema

El presente laboratorio implementa un sistema digital modular en la tarjeta FPGA Digilent Zybo Z7. El sistema integra:
- Un **Banco de Registros** interno de 4 posiciones ($R0$ a $R3$) de 4 bits cada uno, con un indicador dinámico visual a través de un LED RGB.
- Un **Selector Combinacional de Registros** que rota mediante el pulsador `BTN2` entre 6 parejas posibles de operandos ($A$ y $B$), encendiendo los LEDs verdes correspondientes.
- Una **Unidad Aritmético Lógica (ALU)** de 4 bits capaz de realizar 8 operaciones (aritméticas y lógicas) seleccionadas mediante los interruptores `SW[2:0]`.
- Un **Controlador de Visualización TM1637** que retiene (*latch*) y transmite de forma serial síncrona el resultado de la ALU hacia la pantalla tras presionar el pulsador `BTN3`.

---

## 2. Explicación de la Arquitectura Modular

La arquitectura del sistema está organizada en módulos independientes e interconectados descritos en Verilog HDL dentro de la carpeta `src/`.

### 2.1. Código Fuente del Banco de Registros (`src/reg_bank.v`)

Este módulo implementa el almacenamiento secuencial de 4 registros de 4 bits. Al presionar `BTN0` rota el puntero de escritura (`write_ptr`), mientras que `BTN1` guarda el valor de los switches `SW[3:0]` en la posición activa. Posee lectura asíncrona de dos puertos (`data_out_a` y `data_out_b`).
### 2.1. Banco de Registros (`src/reg_bank.v`)


### 2.2. Selector Combinacional de Registros (`src/comb_selector.v`)
