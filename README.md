# motorlib

Motorlib is a library for embedded motor control. It is designed to run an actuator from a host pc in a realtime manner, where realtime refers to low latency communication to and from the actuator. The actuator runs using a fielded oriented control (FOC) fast loop that can operate in current or voltage mode, and a slower main loop that runs position, torque or other controllers. The loops are intended to be able to run at speeds up to 100 kHz fast loop and 10 kHz main loop when run on a 170 MHz CortexM4F microcontroller. The loops are intended to be interrupt driven such that jitter is minimized. The default communication method with the host PC is USB which has been tested to speeds up to 10 kHz. A high speed USB hub (480 Mbps) allows for 10 kHz communication to many actuators by multiplexing the data to the full speed USB (12 Mbps) microcontrollers. A diagram of the loops is shown below.
![loop diagram](doc/motor_loop_diagram.svg#gh-light-mode-only)
![loop diagram](doc/motor_loop_diagram_dark.svg#gh-dark-mode-only)

The main loop is intended to run several different several different options for main loop controllers that are identified by different modes. There is a minimal amount of state related to switching controllers and the controller mode is set in the realtime packet. That is that the controller can generally be switched instanenously with no intermediate state machine transition steps. The expection is when a fault occurs. A fault will cause the library to be forced into `safe_mode` which is configurable to any of the controller mode options. In order to exit the chosen safe mode first the host must explicitly send a command requesting that safe mode. This will clear the fault bits and then as long as faults remain cleared, the host can then transition to any other mode. A diagram of this logic is shown below.
![state diagram](doc/obot_controller_state_diagram.svg#gh-light-mode-only)
![state diagram](doc/obot_controller_state_diagram_dark.svg#gh-dark-mode-only)

Motorlib has support for several different sensors and driver configurations. It is designed to be statically compiled for the specific hardware configuration including microcontroller, sensors, driver, and communication method. It is configured by means of the headers that you include and by typedefs. For example the `MainLoop` requires a `MotorEncoder` to operate. If your motor encoder is of type `MA732Encoder` you would configure as follows:
```c
#include "ma732_encoder.h"
using MotorEncoder = MA732Encoder;
#include "main_loop.h"
```
Prior to settling on static/typedef configuration I considered several means for configuration including virtual functions and templates. Virtual functions tended to cause difficulty with execution speed and also added difficulty to optimization. A key embedded optimization is to place the fast loop is a specific place in memory called CCM_RAM. By using headers to configure, only one memory section statement is required. Templates can also solve the problem but they lead to more difficult to read, debug, and configure code. So the static/typedef approach currently seems to be the best method for easy configurability and maintainability.

Examples using this library are found in the adjacent `obot-controller` repository.
