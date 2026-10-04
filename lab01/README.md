# Laboratorio 01 - Lógica Combinacional, Almacenamiento Temporal y ALU en FPGA

## NOMBRES PARTICIPANTES
Jhohan Stiven Rodriguez Rodriguez
Alejandro Brandon Prieto Leon


## Comandos para la simulación

En este caso solo en necesario usar en consola el comando make sim, se recominda tener instalado make file si no no funcionara.
En su defecto se puede ejecutar con los comandos que usualmente se usan.


======== SIMULACIÓN CON ICARUS VERILOG ========


## Descripción general

En este laboratorio se implementó una Unidad Aritmético-Lógica (ALU) básica de 4 bits en la tarjeta FPGA Zybo Z7 (Rev. B). El sistema combina lógica combinacional pura para la ejecución de operaciones matemáticas/lógicas y lógica secuencial para el almacenamiento temporal de datos..

El repositorio incluye:
- Un módulo de diseño (Top Module).
- Un testbench para verificar su funcionamiento.
- Un archivo de restricciones (`.xdc`) para la asignación de pines físicos.
- Evidencia de la simulación en GTKWave.

---

# Desarrollo del Sistema - ALU de 4 Bits

## Descripción

El diseño permite ingresar 2 operandos A y B mediante los interruptores propios de la FPGA Zybo Z7 (`SW[3:0]`). 

El sistema cuenta con las siguientes características:
- **Operando B:** Se guarda en una memoria interna utilizando el botón externo `BTN[5]`, primero se acomodan los valores de los Switches que deseamos y despues su le damos al boton `BTN[5]`.
- **Operando A:** Se lee en tiempo real de los interruptores, dejandolos acomodados.
- **Operaciones:** Mediante los botones `BTN[4:0]` se selecciona la operación a realizar (AND, OR, XOR, Suma, morgan)., distribuyendose de la siguiente manera:
    * BTN[0] validacion de la compuerta XOR --> RGB = cyan
    * BTN[1] Validacion de morgan (NAND) --> RGB = magenta
    * BTN[2] Validacion del AND logico --> RGB =
    * BTN[3] validacion del OR logico --> RGB = verde
    * BTN[4] Validacion de la operacion suma -->RGB = rojo

- **Visualización:** El resultado se muestra en cuatro LEDs verdes (`LED[3:0]`) y la operación seleccionada se indica cromáticamente mediante un LED RGB (`LED6`).

### Aclaración sobre la expansión de botones (BTN[4] y BTN[5])

La tarjeta Zybo Z7 cuenta únicamente con cuatro pulsadores de propósito general (GPIO) conectados directamente a la Lógica Programable (PL), correspondientes a `BTN[0]` hasta `BTN[3]`. Aunque la placa física posee botones adicionales, estos están reservados por hardware para funciones críticas del Sistema de Procesamiento (PS) y el control general de la tarjeta (como el botón de reinicio *SRST* o el botón *PROG*), por lo que no pueden ser reasignados libremente como entradas del usuario.

Dado que la arquitectura de este diseño requería seis botones independientes en total, fue necesario expandir la interfaz. Para resolver esta limitante de hardware, se implementaron dos botones físicos externos montados en una protoboard, mapeando sus señales de entrada hacia la FPGA a través de los pines del puerto de expansión **Pmod JC**.

## Planteamiento de diseño

Para implementar este sistema, se dividió la arquitectura en dos bloques principales:

1. **Memoria Temporal (Datapath Secuencial):** Como la FPGA solo tiene un banco de 4 interruptores, no es posible ingresar un número de 8 bits al mismo tiempo. Se utiliza un registro basado en Flip-Flops sincronizado por el reloj del sistema (`clk`). Al presionar `BTN[5]`, el flanco de subida del reloj "congela" y guarda el estado actual de los switches en el operando B. Esto permite mover los switches libremente después para configurar el operando A sin perder el primer dato.

2. **Unidad ALU (Lógica Combinacional):** La unidad toma el valor en tiempo real de los switches (A) y el valor almacenado en los Flip-Flops (B), ejecutando la operación aritmética o lógica correspondiente al botón que el usuario mantenga presionado.

## Descripción del HDL

El módulo `top_lab01.v` implementa los requerimientos físicos del diseño en dos bloques de comportamiento:

1. **Bloque Secuencial `always @(posedge clk)`:** Monitorea la señal del botón de carga. Si `BTN[5] == 1`, en el siguiente flanco de reloj, el valor `SW[3:0]` se transfiere al registro `B`. Esto asegura el funcionamiento síncrono de la memoria.

2. **Bloque Combinacional `always @(*)`:** Utiliza una estructura `case (1'b1)` para evaluar qué botón está activo en tiempo real. Esta estructura actúa como una cadena condicional de prioridad, evitando la necesidad de múltiples sentencias `if-else` anidadas. Además, asigna un estado por defecto (reposo) en el que todos los LEDs y el LED RGB se mantienen apagados (`0000`) si ningún botón de operación es presionado.

## Modos de operación y Tabla de Funciones

La decodificación de las operaciones y colores se rige por la siguiente tabla:

| Botón Presionado      | Operación | Expresión Lógica | Salida en LEDs | Color LED RGB |
|-----------------------|-----------|------------------|----------------|---------------|
| **`BTN[0]`** | AND    | `A & B`   | `LED = A & B`    | Azul           | `RGB_B`       |
| **`BTN[1]`** | OR     | `A \| B`  | `LED = A \| B`   | Amarillo       | `RGB_R` + `RGB_G`|
| **`BTN[2]`** | XOR    | `A ^ B`   | `LED = A ^ B`    | Magenta        | `RGB_R` + `RGB_B`|
| **`BTN[3]`** | Suma   | `A + B`   | `LED = A + B`    | Verde          | `RGB_G`       |
| **`BTN[4]`** | Resta  | `A - B`   | `LED = A - B`    | Rojo           | `RGB_R`       |
| *Ninguno*    | Reposo | N/A       | `LED = 0000`     | Apagado        | Ninguno       |

### Diagrama de Bloques

![Diagrama de bloques del sistema](evidencias/diagrama_bloques.png)
*(Nota: Añade aquí la ruta a tu propio diagrama si hicieron uno en draw.io o similar, o simplemente borra esta línea)*

## Implementación Física (Hardware)

El mapeo de pines se realizó en el archivo `Zybo-Z7-Master.xdc` para adaptar las variables del módulo a los puertos físicos LVCMOS33 de la FPGA:

- `clk` mapeado al pin K17 (reloj integrado de 125 MHz).
- Operandos de entrada `SW[3:0]` mapeados a los 4 interruptores mecánicos.
- Operaciones `BTN[3:0]` mapeadas a los botones integrados de la placa.
- **Expansión Pmod:** Para compensar la falta de botones integrados suficientes, `BTN[4]` (Resta) y `BTN[5]` (Guardar B) se asignaron a los pines V15 y W15 correspondientes al conector Pmod JC, para su uso con botones externos en protoboard.
- Visualización de datos asíncrona enviada a los pines M14, M15, G14, D18 (LEDs verdes) y V16, F17, M17 (LED RGB 6).

## Resultados y análisis

La simulación permitió validar matemáticamente y temporalmente cada operación. 

Se analizó el comportamiento de inicialización: durante los primeros 30 ns de la simulación, el registro `B` presenta un estado de color rojo (`x`), lo cual es el comportamiento físico real esperado de un Flip-Flop no inicializado. Al transcurrir el primer pulso de reloj con `BTN[5]` activo, la señal se estabiliza.

Para los estímulos de prueba se utilizaron los operandos $A = 5$ y $B = 3$. Las validaciones de salida en la onda fueron:
- AND: 5 & 3 = 1 (`0001`)
- OR: 5 | 3 = 7 (`0111`)
- XOR: 5 ^ 3 = 6 (`0110`)
- SUMA: 5 + 3 = 8 (`1000`)
- RESTA: 5 - 3 = 2 (`0010`)

Se comprobó adicionalmente que la señal RGB reacciona simultáneamente y de manera independiente activando los pines correctos para conformar los colores compuestos (Ej: Activando Rojo y Azul para formar el color Magenta de la operación XOR).

## Archivos

- `src/top_lab01.v`
- `src/tb_top_lab01.v`
- `constraints/Zybo-Z7-Master.xdc`
- `sim/waveform.vcd`

### Testbench

El testbench `tb_top_lab01.v` verifica el flujo completo del sistema simulando la interacción

- **Generación de reloj:** Se genera una señal de reloj mediante `always #4 clk = ~clk;`, simulando un periodo de 8 ns.
- **Estímulos Secuenciales (Operando B):** Se configura `SW = 4'b0011` (3) y posteriormente se eleva la señal de `BTN[5]` durante 10 ns, cruzando intencionalmente un flanco de subida de reloj para forzar la escritura en los Flip-Flops.
- **Estímulos Combinacionales (Operando A):** Se configura `SW = 4'b0101` (5). Se verifica que el registro interno `B` no se altere ante este cambio.
- **Ejecución de ALU:** Se emulan pulsos de 20 ns sobre los botones individuales `BTN[0]` hasta `BTN[4]`, dejando un lapso en nivel bajo (`0`) entre cada pulsación para verificar que el sistema regresa a su estado de reposo (LEDs apagados).

## Simulación

La simulación permite comprobar las capacidades de memoria del sistema y su capacidad de responder asíncronamente a los botones de funciones, visualizando tanto el resultado numérico hexadecimal/binario como los canales rojo, verde y azul individuales del indicador RGB.

### Evidencia

![Simulación de GTKWave](evidencias/gtkwave_sim.png)

![Pasos de sistesis, implementacion y bitstream de vivado](evidencias/prueba_vivado.png)

## Evidencia del funcionamiento en la FPGA

# A=3=0011

![Almacenamiento del Operando B](evidencias/B.png)

![Operación Suma](evidencias/suma.png)

![Operación OR](evidencias/OR.png)

![Operación AND](evidencias/AND.png)

![Validación De Morgan (NAND)](evidencias/morgan.png)

![Operación XOR](evidencias/XOR.png)

---

# Conclusiones

La implementación de este laboratorio demuestra la diferencia práctica entre la lógica combinacional y la secuencial dentro del ecosistema de una FPGA. Mientras que la unidad ALU responde de manera inmediata e independiente a los cambios externos en los interruptores (sin importar el reloj del sistema), el almacenamiento del operando B dependió enteramente de la sincronización con el reloj y la instanciación de memorias internas. 

Adicionalmente, se logró integrar hardware externo (botones en protoboard) haciendo un correcto mapeo de pines a través de los puertos Pmod, validando no solo el diseño en software sino superando las limitantes de hardware que la placa Zybo Z7 presenta en su interfaz de usuario nativa.
