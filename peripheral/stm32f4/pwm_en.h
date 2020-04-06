#pragma once

#include "../pwm.h"
#include <cstdint>
#include "../../../st_device.h"

class GPIO;

class PWM_EN final : public PWM {
 public:
    PWM_EN(int32_t frequency_hz, uint32_t &pwm_a, uint32_t &pwm_b, 
         uint32_t &pwm_c, TIM_TypeDef &regs, GPIO &enable, float pwm_min_off_ns=0) : 
         pwm_a_(pwm_a), pwm_b_(pwm_b), pwm_c_(pwm_c),
         regs_(regs), enable_(enable) {
      set_frequency_hz(frequency_hz);
      set_pwm_min(pwm_min_off_ns);
      set_vbus(12);
   } 
   void set_voltage(float v_abc[3])  __attribute__((section (".ccmram")));
   void set_vbus(float vbus);
   void open_mode();
   void brake_mode();
   void voltage_mode();
   void set_frequency_hz(uint32_t frequency_hz);
   void set_pwm_min(float pwm_min_off_ns);
 private:
   uint16_t period_, half_period_;
   uint32_t &pwm_a_, &pwm_b_, &pwm_c_;
   TIM_TypeDef &regs_;
   GPIO &enable_;
   float v_to_pwm_;
   uint16_t pwm_max_ = 65535;
   uint16_t pwm_min_ = 0;
};
