#ifndef UNHUMAN_MOTORLIB_BOARDS_CONFIG_OBOT_G474_MOTOR_TYPES_H_
#define UNHUMAN_MOTORLIB_BOARDS_CONFIG_OBOT_G474_MOTOR_TYPES_H_

// === Necessary for obot_g474_motor. ===
#include "../peripheral/stm32g4/pin_config.h"

#include "../peripheral/stm32g4/drv8323s.h"
#include "../peripheral/stm32g4/hrpwm.h"
#include "../peripheral/usb.h"
#include "../usb_communication.h"

using CommunicationType = USBCommunication<USB1>;
using DriverType = DRV8323S;
using PWMType = HRPWM;

// === Default type definitions. ===
#include "../controller/impedance_controller.h"
#include "../controller/joint_position_controller.h"
#include "../controller/position_controller.h"
#include "../controller/state_controller.h"
#include "../controller/torque_controller.h"
#include "../controller/velocity_controller.h"

using PositionControllerType = PositionController;
using TorqueControllerType = TorqueController;
using ImpedanceControllerType = ImpedanceController;
using VelocityControllerType = VelocityController;
using StateControllerType = StateController;
using JointPositionControllerType = JointPositionController;

#endif // UNHUMAN_MOTORLIB_BOARDS_CONFIG_OBOT_G474_MOTOR_TYPES_H_