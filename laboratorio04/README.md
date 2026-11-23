# Laboratorio 04 - SoC Zynq-7000

### NOMBRES PARTICIPANTES

- Jhohan Stiven Rodríguez Rodríguez
- Alejandro Brandon Prieto León
- Ángel Alirio Rivera Amortegui

---

## 1. Descripción del Proyecto
Implementación de un sistema embebido sobre el SoC **Zynq-7000** (tarjeta **Digilent Zybo Z7**) integrando el sistema de procesamiento (PS) con lógica programable (PL) mediante el bus **AXI**[cite: 5, 7]. El objetivo es controlar el parpadeo de 4 LEDs y superponer en tiempo real la lectura de 4 botones físicos mediante acceso directo a memoria en C[cite: 4, 5].

---

## 2. Diseño de Hardware (Vivado)
Se construyó el diagrama de bloques (`bloque1lab04`) conectando el procesador `ZYNQ7 Processing System` a través de `AXI Interconnect` hacia un controlador de memoria BRAM (`axi_bram_ctrl_0`) y un periférico `AXI GPIO` configurado con dos canales:
- **Canal 1 (`GPIO`):** Entrada de 4 bits conectada a los botones (`btns_4bits`).
- **Canal 2 (`GPIO2`):** Salida de 4 bits conectada a los LEDs (`leds_4bits`).

Tras validar el diseño, se ejecutó la síntesis, implementación y generación del bitstream (`bloque1lab04_wrapper.bit`), exportando posteriormente la plataforma de hardware (`bloque1lab04_wrapper.xsa`)[cite: 5, 8].

![Diagrama de Bloques en Vivado](block%20desing.png)

---

## 3. Desarrollo de Software (Vitis)
A partir del archivo `.xsa` exportado, se creó la plataforma (`Plataforma_Practica4`) y la aplicación (`Componente_app_Practica4`) en **Vitis Unified IDE 2025.2**[cite: 6, 8].

### Lógica del Código (`main.c`)
El programa accede directamente a los registros del periférico AXI GPIO mapeados en la dirección base `0x41200000`[cite: 4]:
- **Registro de LEDs (`GPIO_BASE + 0x00`):** Controla el estado lógico de los 4 LEDs[cite: 4].
- **Registro de Botones (`GPIO_BASE + 0x08`):** Lee el estado de los 4 pulsadores aplicando la máscara `0xF`[cite: 4].

En cada ciclo, se alterna el parpadeo base entre encendido (`0xF`) y apagado (`0x0`), realizando una operación lógica **OR (`|`)** con el estado de los botones (`LED_REG = blink_state | buttons`) mediante encuestamiento (*polling*) continuo[cite: 4].

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
