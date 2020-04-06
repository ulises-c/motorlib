
#include "pwm_en.h"
#include "stm32f446xx.h"
#include "../../gpio.h"

uint16_t u16_sat2(uint16_t val, uint16_t min, uint16_t max) {
    uint16_t b = val>max ? max : val;
    b = b<min ? min : b;
    return b;
}

void PWM_EN::set_voltage(float v_abc[3]) {
    pwm_a_ = u16_sat2(v_abc[0] * v_to_pwm_ + half_period_, pwm_min_, pwm_max_);
    pwm_b_ = u16_sat2(v_abc[1] * v_to_pwm_ + half_period_, pwm_min_, pwm_max_);
    pwm_c_ = u16_sat2(v_abc[2] * v_to_pwm_ + half_period_, pwm_min_, pwm_max_);
}

void PWM_EN::set_vbus(float vbus) {
    v_to_pwm_ = period_/vbus;
}

void PWM_EN::open_mode() {
    enable_.clear();
}

void PWM_EN::brake_mode() {
    enable_.set();
    // CC4E is the driving the interrupt, keep enabled, disable others
    regs_.CCER = TIM_CCER_CC4E;
}

void PWM_EN::voltage_mode() {
    enable_.set();
    regs_.CCER = TIM_CCER_CC1E | TIM_CCER_CC2E | TIM_CCER_CC3E | TIM_CCER_CC4E;
    regs_.BDTR |= TIM_BDTR_MOE;
}

void PWM_EN::set_frequency_hz(uint32_t frequency_hz) {
    regs_.ARR = CPU_FREQUENCY_HZ/2/frequency_hz; // todo not enabled at startup
    period_ = CPU_FREQUENCY_HZ/2/frequency_hz;
    half_period_ = period_/2; 
}

void PWM_EN::set_pwm_min(float pwm_min_off_ns) {
    float ns_per_count = 2*1.0e9/CPU_FREQUENCY_HZ;
    pwm_min_ = pwm_min_off_ns / ns_per_count;
    pwm_max_ = period_ - pwm_min_;
}