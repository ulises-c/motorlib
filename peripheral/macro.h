#pragma once

#ifndef FIGURE_ASSERT
#define FIGURE_ASSERT(x, ...) \
do {                          \
  if (!(x)) {                 \
    while(1);                 \
  }                           \
} while(0)
#endif // #ifndef FIGURE_ASSERT

#ifndef FIGURE_COUNTOF
#define FIGURE_COUNTOF(array) (sizeof(array)/sizeof((array)[0]))
#endif // #ifndef FIGURE_COUNTOF

#ifdef DEBUG_PINS_ENABLE

#define DEBUG_PINS_INIT() do{       \
  RCC->AHB2ENR |= RCC_AHB2ENR_GPIOCEN;  \
  GPIOC->AFR[1] &= ~(GPIO_AFRH_AFSEL10_Msk | GPIO_AFRH_AFSEL11_Msk | GPIO_AFRH_AFSEL12_Msk); /* Set AF to 0 for GPIO mode */ \
  GPIOC->MODER &= ~(GPIO_MODER_MODE10_Msk | GPIO_MODER_MODE11_Msk | GPIO_MODER_MODE12_Msk); \
  GPIOC->MODER |= (GPIO_MODER_MODE10_0 | GPIO_MODER_MODE11_0 | GPIO_MODER_MODE12_0); /* Output mode */ \
  GPIOC->ODR &= ~(GPIO_ODR_OD10 | GPIO_ODR_OD11 | GPIO_ODR_OD12); \
}while(0)

// PC10
#define DEBUG_PIN1_SET()   do{GPIOC->ODR |= GPIO_ODR_OD10;}while(0)
#define DEBUG_PIN1_CLEAR() do{GPIOC->ODR &= ~GPIO_ODR_OD10;}while(0)

// PC12
#define DEBUG_PIN2_SET()   do{GPIOC->ODR |= GPIO_ODR_OD12;}while(0)
#define DEBUG_PIN2_CLEAR() do{GPIOC->ODR &= ~GPIO_ODR_OD12;}while(0)

// PC11
#define DEBUG_PIN3_SET()   do{GPIOC->ODR |= GPIO_ODR_OD11;}while(0)
#define DEBUG_PIN3_CLEAR() do{GPIOC->ODR &= ~GPIO_ODR_OD11;}while(0)

#else

#define DEBUG_PINS_INIT()
#define DEBUG_PIN1_SET()
#define DEBUG_PIN1_CLEAR()

// PC12
#define DEBUG_PIN2_SET()
#define DEBUG_PIN2_CLEAR()

// PC11
#define DEBUG_PIN3_SET()
#define DEBUG_PIN3_CLEAR()

#endif
