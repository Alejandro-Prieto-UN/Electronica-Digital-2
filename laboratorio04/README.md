# Laboratorio 04 - SoC Zynq-7000

### NOMBRES PARTICIPANTES

- Jhohan Stiven Rodríguez Rodríguez
- Alejandro Brandon Prieto León
- Ángel Alirio Rivera Amortegui

---

## 1. Descripción del Proyecto
Se implementó un sistema embebido sobre el SoC **Zynq-7000** (tarjeta **Digilent Zybo Z7**) integrando el sistema de procesamiento (PS) con lógica programable (PL) mediante el bus **AXI**. El objetivo es controlar el parpadeo de 4 LEDs y superponer en tiempo real la lectura de 4 botones físicos mediante acceso directo a memoria en C.

---

## 2. Diseño de Hardware (Vivado)
Se construyó el diagrama de bloques (`bloque1lab04`) conectando el procesador `ZYNQ7 Processing System` a través de `AXI Interconnect` hacia un controlador de memoria BRAM (`axi_bram_ctrl_0`) y un periférico `AXI GPIO` configurado con dos canales:
- **Canal 1 (`GPIO`):** Entrada de 4 bits conectada a los botones (`btns_4bits`).
- **Canal 2 (`GPIO2`):** Salida de 4 bits conectada a los LEDs (`leds_4bits`).

Tras validar el diseño, se ejecutó la síntesis, implementación y generación del bitstream (`bloque1lab04_wrapper.bit`), exportando posteriormente la plataforma de hardware (`bloque1lab04_wrapper.xsa`).

![Diagrama de Bloques en Vivado](block%20desing.png)

---

## 3. Desarrollo de Software (Vitis)
A partir del archivo `.xsa` exportado, se creó la plataforma (`Plataforma_Practica4`) y la aplicación (`Componente_app_Practica4`) en **Vitis Unified IDE 2025.2**.

### Lógica del Código (`main.c`)
El programa accede directamente a los registros del periférico AXI GPIO mapeados en la dirección base `0x41200000`:
- **Registro de LEDs (`GPIO_BASE + 0x00`):** Controla el estado lógico de los 4 LEDs[cite: 4].
- **Registro de Botones (`GPIO_BASE + 0x08`):** Lee el estado de los 4 pulsadores aplicando la máscara `0xF`.

En cada ciclo, se alterna el parpadeo base entre encendido (`0xF`) y apagado (`0x0`), realizando una operación lógica **OR (`|`)** con el estado de los botones (`LED_REG = blink_state | buttons`) mediante encuestamiento (*polling*) continuo.

```c
#define GPIO_BASE 0x41200000

#define LED_REG    *(volatile unsigned int *)(GPIO_BASE + 0x00)
#define BUTTON_REG *(volatile unsigned int *)(GPIO_BASE + 0x08)

#define DELAY         100000000
#define POLL_INTERVAL 100000

void delay_with_buttons(unsigned int blink_state)
{
    for (unsigned int elapsed = 0;
         elapsed < DELAY;
         elapsed += POLL_INTERVAL)
    {
        // Leer los cuatro botones
        unsigned int buttons = BUTTON_REG & 0xF;

        // Combinar el estado del parpadeo con los botones
        LED_REG = blink_state | buttons;

        // Pequeño intervalo antes de volver a consultar botones
        for (volatile int i = 0; i < POLL_INTERVAL; i++);
    }
}

int main()
{
    while(1)
    {
        // Fase ON
        delay_with_buttons(0xF);

        // Fase OFF
        delay_with_buttons(0x0);
    }

    return 0;
}

```

### Evidencia de Compilación y Despliegue
Se compiló el proyecto generando el ejecutable `Componente_app_Practica4.elf`, se programó la FPGA de la tarjeta **Zybo Z7** y se lanzó la ejecución sobre el núcleo **ARM Cortex-A9** (`target 2`).

![Compilación y Ejecución en Vitis](build.jfif)

* **Archivos de respaldo incluidos:** `main.c`, `log_vitis.txt.txt` y `bloque1lab04_wrapper.xsa`.

---

## 4. Evidencia de Funcionamiento Físico
En el siguiente video se comprueba la ejecución del sistema en tiempo real sobre la tarjeta **Digilent Zybo Z7**: los 4 LEDs verdes parpadean periódicamente y, al presionar secuencialmente cada uno de los 4 pulsadores (`BTN0` a `BTN3`), su LED asociado se mantiene encendido de forma independiente durante la fase apagada gracias a la operación lógica `OR`.

* 🎥 **Demostración en hardware:** [Ver Video01](Video01.mp4)

## 5. Referencias
1. **AMD / Xilinx.** *AXI GPIO v2.0 LogiCORE IP Product Guide (PG144).* Documentación oficial de arquitectura, mapa de registros (`GPIO_DATA` en offset `0x00` y `GPIO2_DATA` en offset `0x08`) y configuración de canales de entrada/salida sobre el bus AXI4-Lite. Disponible en: [AMD Technical Information Portal - PG144](https://docs.amd.com/r/en-US/pg144-axi-gpio)
2. **Digilent.** *Zybo Z7 Reference Manual.* Manual oficial de hardware de la tarjeta de desarrollo basada en Zynq-7000, especificaciones de interconexión entre el sistema de procesamiento (PS) y la lógica programable (PL), y asignación física de periféricos de usuario (`BTN0–BTN3` y `LD0–LD3`). Disponible en: [Digilent Reference - Zybo Z7](https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual)

---
