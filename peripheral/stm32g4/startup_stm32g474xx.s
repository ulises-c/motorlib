/**
  ******************************************************************************
  * @file      startup_stm32g474xx.s
  * @author    MCD Application Team
  * @brief     STM32G474xx devices vector table GCC toolchain.
  *            This module performs:
  *                - Set the initial SP
  *                - Set the initial PC == Reset_Handler,
  *                - Set the vector table entries with the exceptions ISR address,
  *                - Configure the clock system
  *                - Branches to main in the C library (which eventually
  *                  calls main()).
  *            After Reset the Cortex-M4 processor is in Thread mode,
  *            priority is Privileged, and the Stack is set to Main.
  ******************************************************************************
  * @attention
  *
  * <h2><center>&copy; Copyright (c) 2019 STMicroelectronics.
  * All rights reserved.</center></h2>
  *
  * This software component is licensed by ST under BSD 3-Clause license,
  * the "License"; You may not use this file except in compliance with the
  * License. You may obtain a copy of the License at:
  *                        opensource.org/licenses/BSD-3-Clause
  *
  ******************************************************************************
  */

  .syntax unified
	.cpu cortex-m4
	.fpu softvfp
	.thumb

.global	g_pfnVectors
.global	Default_Handler

/* start address for the initialization values of the .data section.
defined in linker script */
.word	_sidata
/* start address for the .data section. defined in linker script */
.word	_sdata
/* end address for the .data section. defined in linker script */
.word	_edata
/* start address for the .bss section. defined in linker script */
.word	_sbss
/* end address for the .bss section. defined in linker script */
.word	_ebss

.equ  BootRAM,        0xF1E0F85F
/**
 * @brief  This is the code that gets called when the processor first
 *          starts execution following a reset event. Only the absolutely
 *          necessary set is performed, after which the application
 *          supplied main() routine is called.
 * @param  None
 * @retval : None
*/

.set RCC_BASE,        0x40021000
.set RCC_CSR_OFFSET,  0x94
.set RCC_CSR_SFTRSTF_POS, 28
.set RCC_CSR_RMVF_POS,    23
.set RCC_CSR_IWDGRSTF_POS, 29
.set RCC_CSR_PINRSTF_POS,    26

.set RCC_APB2SMENR,         0x40021080
.set RCC_SYSCFGEN_POS,    0
.set SYSCFG_MEMRMP,	      0x40010000

.set IWDG_KR,		0x40003000

    .section	.text.Reset_Handler
	.weak	Reset_Handler
	.type	Reset_Handler, %function
Reset_Handler:
	ldr r0, =RCC_BASE
	ldr r1, [r0, #RCC_CSR_OFFSET]
	orr r1, #(1<<RCC_CSR_RMVF_POS)
	str r1, [r0, #RCC_CSR_OFFSET]			// clear reset flags

	tst r1, #(1<<RCC_CSR_IWDGRSTF_POS)		// watchdog reset
	bne Reboot_Loader
	tst r1, #(1<<RCC_CSR_SFTRSTF_POS)		// software reset
	beq Original_Reset_Handler
	ldr r0, =go_to_bootloader
	ldr r1, [r0]
	ldr r2, =0xB007
	cmp r1, r2
	mov r1, #0
	str r1, [r0]
	bne Original_Reset_Handler

Reboot_Loader:
    ldr     r0, =RCC_APB2SMENR 
    ldr     r1, =#(1<<RCC_SYSCFGEN_POS) 
    str     r1, [r0]
	nop		/* found experimentally that this is needed */
    ldr     r0, =#SYSCFG_MEMRMP /* SYSCFG_MEMRMP */
    ldr     r1, =0x00000001 /* MAP ROM AT ZERO */
    str     r1, [r0]
    ldr     r0, =0x1FFF0000 /* ROM BASE */
    ldr     SP,[r0]     /* SP @ +0 */
    ldr     r0,[r0, #4]     /* PC @ +4 */
    bx      r0

Original_Reset_Handler:
  // start watchdog IWDG->KR = 0xCCCC;
#ifndef NO_WATCHDOG
  ldr	r0, =(1<<12)
  ldr	r1, =0xE0042008
  str   r0, [r1]		// IWDG stop on debug
  ldr	r0, =0xCCCC
  ldr	r1, =IWDG_KR
  str	r0, [r1]		// start watchdog
  ldr	r0, =0x5555		// access IWDG_PR key
  str	r0, [r1]
  // wait for IWDR_SR PVU to be 0
pvu_zero_wait:
  ldr	r0, [r1, #12]
  cmp	r0, #1
  beq	pvu_zero_wait
  
  ldr	r0, =0
  str	r0, [r1, #4]	// Set PR to 0 (default but bootloader sets to 6)
#endif

  ldr   r0, =_estack
  mov   sp, r0          /* set stack pointer */

/* Copy the data segment initializers from flash to SRAM */
  ldr r0, =_sdata
  ldr r1, =_edata
  ldr r2, =_sidata
  movs r3, #0
  b	LoopCopyDataInit

CopyDataInit:
  ldr r4, [r2, r3]
  str r4, [r0, r3]
  adds r3, r3, #4

LoopCopyDataInit:
  adds r4, r0, r3
  cmp r4, r1
  bcc CopyDataInit

  /* CCM RAM init */
  movs r1, #0
  b LoopCopyDataInit1
CopyDataInit1:
  ldr r3, =_siccmram
  ldr r3, [r3, r1]
  str r3, [r0, r1]
  adds r1, r1, #4
LoopCopyDataInit1:
  ldr r0, =_sccmram
  ldr r3, =_eccmram
  adds r2, r0, r1
  cmp r2, r3
  bcc CopyDataInit1
  
/* Zero fill the bss segment. */
  ldr r2, =_sbss
  ldr r4, =_estack
  movs r3, #0x0
  b LoopFillZerobss

FillZerobss:
  str  r3, [r2], #4

LoopFillZerobss:
  cmp r2, r4
  bcc FillZerobss

/* Call the clock system intitialization function.*/
    bl  SystemInit
	bl  board_init
/* Call static constructors */
    bl __libc_init_array
/* Call the application's entry point.*/
	bl	main

LoopForever:
    b LoopForever

.size	Reset_Handler, .-Reset_Handler

/**
 * @brief  This is the code that gets called when the processor receives an
 *         unexpected interrupt.  This simply enters an infinite loop, preserving
 *         the system state for examination by a debugger.
 *
 * @param  None
 * @retval : None
*/
    .section	.text.Default_Handler,"ax",%progbits
Default_Handler:
Infinite_Loop:
	b	Infinite_Loop
Infinite_Loop1:
	b	Infinite_Loop1
Infinite_Loop2:
	b	Infinite_Loop2
Infinite_Loop3:
	b	Infinite_Loop3
Infinite_Loop4:
	b	Infinite_Loop4
Infinite_Loop5:
	b	Infinite_Loop5
	.size	Default_Handler, .-Default_Handler
/******************************************************************************
*
* The minimal vector table for a Cortex-M4.  Note that the proper constructs
* must be placed on this to ensure that it ends up at physical address
* 0x0000.0000.
*
******************************************************************************/
 	.section	.isr_vector,"a",%progbits
	.type	g_pfnVectors, %object
	.size	g_pfnVectors, .-g_pfnVectors


g_pfnVectors:
	.word	_estack
	.word	Reset_Handler
	.word	NMI_Handler
	.word	HardFault_Handler
	.word	MemManage_Handler
	.word	BusFault_Handler
	.word	UsageFault_Handler
	.word	0
	.word	0
	.word	0
	.word	0
	.word	SVC_Handler
	.word	DebugMon_Handler
	.word	0
	.word	PendSV_Handler
	.word	SysTick_Handler
	.word	WWDG_IRQHandler
	.word	PVD_PVM_IRQHandler
	.word	RTC_TAMP_LSECSS_IRQHandler
	.word	RTC_WKUP_IRQHandler
	.word	FLASH_IRQHandler
	.word	RCC_IRQHandler
	.word	EXTI0_IRQHandler
	.word	EXTI1_IRQHandler
	.word	EXTI2_IRQHandler
	.word	EXTI3_IRQHandler
	.word	EXTI4_IRQHandler
	.word	DMA1_Channel1_IRQHandler
	.word	DMA1_Channel2_IRQHandler
	.word	DMA1_Channel3_IRQHandler
	.word	DMA1_Channel4_IRQHandler
	.word	DMA1_Channel5_IRQHandler
	.word	DMA1_Channel6_IRQHandler
	.word	DMA1_Channel7_IRQHandler
	.word	ADC1_2_IRQHandler
	.word	USB_HP_IRQHandler
	.word	USB_LP_IRQHandler
	.word	FDCAN1_IT0_IRQHandler
	.word	FDCAN1_IT1_IRQHandler
	.word	EXTI9_5_IRQHandler
	.word	TIM1_BRK_TIM15_IRQHandler
	.word	TIM1_UP_TIM16_IRQHandler
	.word	TIM1_TRG_COM_TIM17_IRQHandler
	.word	TIM1_CC_IRQHandler
	.word	TIM2_IRQHandler
	.word	TIM3_IRQHandler
	.word	TIM4_IRQHandler
	.word	I2C1_EV_IRQHandler
	.word	I2C1_ER_IRQHandler
	.word	I2C2_EV_IRQHandler
	.word	I2C2_ER_IRQHandler
	.word	SPI1_IRQHandler
	.word	SPI2_IRQHandler
	.word	USART1_IRQHandler
	.word	USART2_IRQHandler
	.word	USART3_IRQHandler
	.word	EXTI15_10_IRQHandler
	.word	RTC_Alarm_IRQHandler
	.word	USBWakeUp_IRQHandler
	.word	TIM8_BRK_IRQHandler
	.word	TIM8_UP_IRQHandler
	.word	TIM8_TRG_COM_IRQHandler
	.word	TIM8_CC_IRQHandler
	.word	ADC3_IRQHandler
	.word	FMC_IRQHandler
	.word	LPTIM1_IRQHandler
	.word	TIM5_IRQHandler
	.word	SPI3_IRQHandler
	.word	UART4_IRQHandler
	.word	UART5_IRQHandler
	.word	TIM6_DAC_IRQHandler
	.word	TIM7_DAC_IRQHandler
	.word	DMA2_Channel1_IRQHandler
	.word	DMA2_Channel2_IRQHandler
	.word	DMA2_Channel3_IRQHandler
	.word	DMA2_Channel4_IRQHandler
	.word	DMA2_Channel5_IRQHandler
	.word	ADC4_IRQHandler
	.word	ADC5_IRQHandler
	.word	UCPD1_IRQHandler
	.word	COMP1_2_3_IRQHandler
	.word	COMP4_5_6_IRQHandler
	.word	COMP7_IRQHandler
	.word	HRTIM1_Master_IRQHandler
	.word	HRTIM1_TIMA_IRQHandler
	.word	HRTIM1_TIMB_IRQHandler
	.word	HRTIM1_TIMC_IRQHandler
	.word	HRTIM1_TIMD_IRQHandler
	.word	HRTIM1_TIME_IRQHandler
	.word	HRTIM1_FLT_IRQHandler
	.word	HRTIM1_TIMF_IRQHandler
	.word	CRS_IRQHandler
	.word	SAI1_IRQHandler
	.word	TIM20_BRK_IRQHandler
	.word	TIM20_UP_IRQHandler
	.word	TIM20_TRG_COM_IRQHandler
	.word	TIM20_CC_IRQHandler
	.word	FPU_IRQHandler
	.word	I2C4_EV_IRQHandler
	.word	I2C4_ER_IRQHandler
	.word	SPI4_IRQHandler
	.word	0
	.word	FDCAN2_IT0_IRQHandler
	.word	FDCAN2_IT1_IRQHandler
	.word	FDCAN3_IT0_IRQHandler
	.word	FDCAN3_IT1_IRQHandler
	.word	RNG_IRQHandler
	.word	LPUART1_IRQHandler
	.word	I2C3_EV_IRQHandler
	.word	I2C3_ER_IRQHandler
	.word	DMAMUX_OVR_IRQHandler
	.word	QUADSPI_IRQHandler
	.word	DMA1_Channel8_IRQHandler
	.word	DMA2_Channel6_IRQHandler
	.word	DMA2_Channel7_IRQHandler
	.word	DMA2_Channel8_IRQHandler
	.word	CORDIC_IRQHandler
	.word	FMAC_IRQHandler

/*******************************************************************************
*
* Provide weak aliases for each Exception handler to the Default_Handler.
* As they are weak aliases, any function with the same name will override
* this definition.
*
*******************************************************************************/

//	.weak	NMI_Handler
//	.thumb_set NMI_Handler,Infinite_Loop1

//	.weak	HardFault_Handler
//	.thumb_set HardFault_Handler,Infinite_Loop2

//	.weak	MemManage_Handler
//	.thumb_set MemManage_Handler,Default_Handler

//	.weak	BusFault_Handler
//	.thumb_set BusFault_Handler,Default_Handler

//	.weak	UsageFault_Handler
//	.thumb_set UsageFault_Handler,Default_Handler

//	.weak	SVC_Handler
//	.thumb_set SVC_Handler,Default_Handler

//	.weak	DebugMon_Handler
//	.thumb_set DebugMon_Handler,Default_Handler

	.weak	PendSV_Handler
	.thumb_set PendSV_Handler,Default_Handler

//	.weak	SysTick_Handler
//	.thumb_set SysTick_Handler,Default_Handler*/

	.weak	WWDG_IRQHandler
	.thumb_set WWDG_IRQHandler,Infinite_Loop5

	.weak	PVD_PVM_IRQHandler
	.thumb_set PVD_PVM_IRQHandler,Default_Handler

	.weak	RTC_TAMP_LSECSS_IRQHandler
	.thumb_set RTC_TAMP_LSECSS_IRQHandler,Default_Handler

	.weak	RTC_WKUP_IRQHandler
	.thumb_set RTC_WKUP_IRQHandler,Default_Handler

	.weak	FLASH_IRQHandler
	.thumb_set FLASH_IRQHandler,Default_Handler

	.weak	RCC_IRQHandler
	.thumb_set RCC_IRQHandler,Default_Handler

	.weak	EXTI0_IRQHandler
	.thumb_set EXTI0_IRQHandler,Default_Handler

	.weak	EXTI1_IRQHandler
	.thumb_set EXTI1_IRQHandler,Default_Handler

	.weak	EXTI2_IRQHandler
	.thumb_set EXTI2_IRQHandler,Default_Handler

	.weak	EXTI3_IRQHandler
	.thumb_set EXTI3_IRQHandler,Default_Handler

	.weak	EXTI4_IRQHandler
	.thumb_set EXTI4_IRQHandler,Default_Handler

	.weak	DMA1_Channel1_IRQHandler
	.thumb_set DMA1_Channel1_IRQHandler,Default_Handler

	.weak	DMA1_Channel2_IRQHandler
	.thumb_set DMA1_Channel2_IRQHandler,Default_Handler

	.weak	DMA1_Channel3_IRQHandler
	.thumb_set DMA1_Channel3_IRQHandler,Default_Handler

	.weak	DMA1_Channel4_IRQHandler
	.thumb_set DMA1_Channel4_IRQHandler,Default_Handler

	.weak	DMA1_Channel5_IRQHandler
	.thumb_set DMA1_Channel5_IRQHandler,Default_Handler

	.weak	DMA1_Channel6_IRQHandler
	.thumb_set DMA1_Channel6_IRQHandler,Default_Handler

	.weak	DMA1_Channel7_IRQHandler
	.thumb_set DMA1_Channel7_IRQHandler,Default_Handler

	.weak	ADC1_2_IRQHandler
	.thumb_set ADC1_2_IRQHandler,Infinite_Loop3

	.weak	USB_HP_IRQHandler
	.thumb_set USB_HP_IRQHandler,Default_Handler
/*
//	.weak	USB_LP_IRQHandler
//	.thumb_set USB_LP_IRQHandler,Default_Handler
*/
	.weak	FDCAN1_IT0_IRQHandler
	.thumb_set FDCAN1_IT0_IRQHandler,Default_Handler

	.weak	FDCAN1_IT1_IRQHandler
	.thumb_set FDCAN1_IT1_IRQHandler,Default_Handler

	.weak	EXTI9_5_IRQHandler
	.thumb_set EXTI9_5_IRQHandler,Default_Handler

	.weak	TIM1_BRK_TIM15_IRQHandler
	.thumb_set TIM1_BRK_TIM15_IRQHandler,Default_Handler

	.weak	TIM1_UP_TIM16_IRQHandler
	.thumb_set TIM1_UP_TIM16_IRQHandler,Default_Handler

	.weak	TIM1_TRG_COM_TIM17_IRQHandler
	.thumb_set TIM1_TRG_COM_TIM17_IRQHandler,Default_Handler

	.weak	TIM1_CC_IRQHandler
	.thumb_set TIM1_CC_IRQHandler,Default_Handler

	.weak	TIM2_IRQHandler
	.thumb_set TIM2_IRQHandler,Default_Handler

	.weak	TIM3_IRQHandler
	.thumb_set TIM3_IRQHandler,Default_Handler

	.weak	TIM4_IRQHandler
	.thumb_set TIM4_IRQHandler,Default_Handler

	.weak	I2C1_EV_IRQHandler
	.thumb_set I2C1_EV_IRQHandler,Default_Handler

	.weak	I2C1_ER_IRQHandler
	.thumb_set I2C1_ER_IRQHandler,Default_Handler

	.weak	I2C2_EV_IRQHandler
	.thumb_set I2C2_EV_IRQHandler,Default_Handler

	.weak	I2C2_ER_IRQHandler
	.thumb_set I2C2_ER_IRQHandler,Default_Handler

	.weak	SPI1_IRQHandler
	.thumb_set SPI1_IRQHandler,Default_Handler

	.weak	SPI2_IRQHandler
	.thumb_set SPI2_IRQHandler,Infinite_Loop4

	.weak	USART1_IRQHandler
	.thumb_set USART1_IRQHandler,Default_Handler

	.weak	USART2_IRQHandler
	.thumb_set USART2_IRQHandler,Default_Handler

	.weak	USART3_IRQHandler
	.thumb_set USART3_IRQHandler,Default_Handler

	.weak	EXTI15_10_IRQHandler
	.thumb_set EXTI15_10_IRQHandler,Default_Handler

	.weak	RTC_Alarm_IRQHandler
	.thumb_set RTC_Alarm_IRQHandler,Default_Handler

	.weak	USBWakeUp_IRQHandler
	.thumb_set USBWakeUp_IRQHandler,Default_Handler

	.weak	TIM8_BRK_IRQHandler
	.thumb_set TIM8_BRK_IRQHandler,Default_Handler

	.weak	TIM8_UP_IRQHandler
	.thumb_set TIM8_UP_IRQHandler,Default_Handler

	.weak	TIM8_TRG_COM_IRQHandler
	.thumb_set TIM8_TRG_COM_IRQHandler,Default_Handler

	.weak	TIM8_CC_IRQHandler
	.thumb_set TIM8_CC_IRQHandler,Default_Handler

	.weak	ADC3_IRQHandler
	.thumb_set ADC3_IRQHandler,Default_Handler

	.weak	FMC_IRQHandler
	.thumb_set FMC_IRQHandler,Default_Handler

	.weak	LPTIM1_IRQHandler
	.thumb_set LPTIM1_IRQHandler,Default_Handler

	.weak	TIM5_IRQHandler
	.thumb_set TIM5_IRQHandler,Default_Handler

	.weak	SPI3_IRQHandler
	.thumb_set SPI3_IRQHandler,Default_Handler

	.weak	UART4_IRQHandler
	.thumb_set UART4_IRQHandler,Default_Handler

	.weak	UART5_IRQHandler
	.thumb_set UART5_IRQHandler,Default_Handler

	.weak	TIM6_DAC_IRQHandler
	.thumb_set TIM6_DAC_IRQHandler,Default_Handler

	.weak	TIM7_DAC_IRQHandler
	.thumb_set TIM7_DAC_IRQHandler,Default_Handler

	//.weak	DMA2_Channel1_IRQHandler
	//.thumb_set DMA2_Channel1_IRQHandler,Default_Handler

	//.weak	DMA2_Channel2_IRQHandler
	//.thumb_set DMA2_Channel2_IRQHandler,Default_Handler

	.weak	DMA2_Channel3_IRQHandler
	.thumb_set DMA2_Channel3_IRQHandler,Default_Handler

	.weak	DMA2_Channel4_IRQHandler
	.thumb_set DMA2_Channel4_IRQHandler,Default_Handler

	.weak	DMA2_Channel5_IRQHandler
	.thumb_set DMA2_Channel5_IRQHandler,Default_Handler

	.weak	ADC4_IRQHandler
	.thumb_set ADC4_IRQHandler,Default_Handler

//	.weak	ADC5_IRQHandler
//	.thumb_set ADC5_IRQHandler,Default_Handler

	.weak	UCPD1_IRQHandler
	.thumb_set UCPD1_IRQHandler,Default_Handler

	.weak	COMP1_2_3_IRQHandler
	.thumb_set COMP1_2_3_IRQHandler,Default_Handler

	.weak	COMP4_5_6_IRQHandler
	.thumb_set COMP4_5_6_IRQHandler,Default_Handler

	.weak	COMP7_IRQHandler
	.thumb_set COMP7_IRQHandler,Default_Handler

	.weak	HRTIM1_Master_IRQHandler
	.thumb_set HRTIM1_Master_IRQHandler,Default_Handler

	.weak	HRTIM1_TIMA_IRQHandler
	.thumb_set HRTIM1_TIMA_IRQHandler,Default_Handler

	.weak	HRTIM1_TIMB_IRQHandler
	.thumb_set HRTIM1_TIMB_IRQHandler,Default_Handler

	.weak	HRTIM1_TIMC_IRQHandler
	.thumb_set HRTIM1_TIMC_IRQHandler,Default_Handler

	.weak	HRTIM1_TIMD_IRQHandler
	.thumb_set HRTIM1_TIMD_IRQHandler,Default_Handler

	.weak	HRTIM1_TIME_IRQHandler
	.thumb_set HRTIM1_TIME_IRQHandler,Default_Handler

	.weak	HRTIM1_FLT_IRQHandler
	.thumb_set HRTIM1_FLT_IRQHandler,Default_Handler

	.weak	HRTIM1_TIMF_IRQHandler
	.thumb_set HRTIM1_TIMF_IRQHandler,Default_Handler

	.weak	CRS_IRQHandler
	.thumb_set CRS_IRQHandler,Default_Handler

	.weak	SAI1_IRQHandler
	.thumb_set SAI1_IRQHandler,Default_Handler

	.weak	TIM20_BRK_IRQHandler
	.thumb_set TIM20_BRK_IRQHandler,Default_Handler

	.weak	TIM20_UP_IRQHandler
	.thumb_set TIM20_UP_IRQHandler,Default_Handler

	.weak	TIM20_TRG_COM_IRQHandler
	.thumb_set TIM20_TRG_COM_IRQHandler,Default_Handler

	.weak	TIM20_CC_IRQHandler
	.thumb_set TIM20_CC_IRQHandler,Default_Handler

	.weak	FPU_IRQHandler
	.thumb_set FPU_IRQHandler,Default_Handler

	.weak	I2C4_EV_IRQHandler
	.thumb_set I2C4_EV_IRQHandler,Default_Handler

	.weak	I2C4_ER_IRQHandler
	.thumb_set I2C4_ER_IRQHandler,Default_Handler

	.weak	SPI4_IRQHandler
	.thumb_set SPI4_IRQHandler,Default_Handler

	.weak	FDCAN2_IT0_IRQHandler
	.thumb_set FDCAN2_IT0_IRQHandler,Default_Handler

	.weak	FDCAN2_IT1_IRQHandler
	.thumb_set FDCAN2_IT1_IRQHandler,Default_Handler

	.weak	FDCAN3_IT0_IRQHandler
	.thumb_set FDCAN3_IT0_IRQHandler,Default_Handler

	.weak	FDCAN3_IT1_IRQHandler
	.thumb_set FDCAN3_IT1_IRQHandler,Default_Handler

	.weak	RNG_IRQHandler
	.thumb_set RNG_IRQHandler,Default_Handler

	.weak	LPUART1_IRQHandler
	.thumb_set LPUART1_IRQHandler,Default_Handler

	.weak	I2C3_EV_IRQHandler
	.thumb_set I2C3_EV_IRQHandler,Default_Handler

	.weak	I2C3_ER_IRQHandler
	.thumb_set I2C3_ER_IRQHandler,Default_Handler

	.weak	DMAMUX_OVR_IRQHandler
	.thumb_set DMAMUX_OVR_IRQHandler,Default_Handler

	.weak	QUADSPI_IRQHandler
	.thumb_set QUADSPI_IRQHandler,Default_Handler

	.weak	DMA1_Channel8_IRQHandler
	.thumb_set DMA1_Channel8_IRQHandler,Default_Handler

	.weak	DMA2_Channel6_IRQHandler
	.thumb_set DMA2_Channel6_IRQHandler,Default_Handler

	.weak	DMA2_Channel7_IRQHandler
	.thumb_set DMA2_Channel7_IRQHandler,Default_Handler

	.weak	DMA2_Channel8_IRQHandler
	.thumb_set DMA2_Channel8_IRQHandler,Default_Handler

	.weak	CORDIC_IRQHandler
	.thumb_set CORDIC_IRQHandler,Default_Handler

	.weak	FMAC_IRQHandler
	.thumb_set FMAC_IRQHandler,Default_Handler

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
