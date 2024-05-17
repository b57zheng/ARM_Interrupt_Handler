# Interrupt Handler System with LPC1768

## Overview
This project demonstrates interrupt handling techniques using the LPC1768 microprocessor. It showcases how to effectively manage external interrupts triggered by a button press, utilizing these events to control LED patterns based on a pseudo-randomly generated delay.

## Features
- **GPIO Interrupts**: Configures GPIO pin P2.10 to trigger interrupts on a falling edge.
- **Random Delay Generation**: Leverages a random number generator to set delays, showcasing the microcontroller's capability to handle time-sensitive tasks.
- **Dynamic LED Control**: LEDs flash at variable rates and display countdowns based on the interrupt-generated random delays.

## Getting Started
These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites
- Keil µVision5 IDE
- LPC1768 MCU on Keil MCB1700 board

### Installation
1. Clone the repository to your local machine.
2. Open the project in Keil µVision5.
3. Compile the project and load the binary onto your LPC1768 board.

### Running the Project
After deployment, the system will immediately start with all LEDs off. Pressing the INT0 button will initiate the interrupt handling sequence, generating a new random delay and updating the LED display accordingly.

## Built With
- **Assembly Language**: All system functionalities are implemented in assembly, providing precise control over hardware.
- **LPC1768 Microprocessor**: Utilizes specific features like GPIO interrupts and timers.

## Contributing
Contributions to the Interrupt Handler are welcome. Please feel free to fork the repository, make changes, and submit pull requests.
