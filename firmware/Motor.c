/* ****************************************************************************
   Motor.c

	 X and Y are steppers. The stubs for Theta and Phi assume they're steppers,
	 but once implemented they'll probably actualy be servos instead.
***************************************************************************** */

#include "stdbool.h"
#include <util/delay.h>
#include <avr/io.h>
#include "Move.h"
#include "Motor.h"

#define X_DIR_REVERSE 0
#define Y_DIR_REVERSE 0
#define THETA_DIR_REVERSE 0
#define PHI_DIR_REVERSE 0

// Pins
#define X_DIR_PIN 0
#define X_DIR_PORT PORTB
#define X_DIR_DDR DDRB
#define Y_DIR_PIN 0
#define Y_DIR_PORT PORTB
#define Y_DIR_DDR DDRB
#define X_STEP_PIN 0
#define X_STEP_PORT PORTB
#define X_STEP_DDR DDRB
#define Y_STEP_PIN 0
#define Y_STEP_PORT PORTB
#define Y_STEP_DDR DDRB


static volatile bool X_IN_STEP = false;
static volatile bool Y_IN_STEP = false;

void MotorInit(void) {
	// Set all our driver pins to be outputs, and pull them high initially
	X_DIR_DDR |= _BV(X_DIR_PIN);
	Y_DIR_DDR |= _BV(Y_DIR_PIN);
	X_STEP_DDR |= _BV(X_STEP_PIN);
	Y_STEP_DDR |= _BV(Y_STEP_PIN);
	X_DIR_PORT |= _BV(X_DIR_PIN);
	Y_DIR_PORT |= _BV(Y_DIR_PIN);
	X_STEP_PORT |= _BV(X_STEP_PIN);
	Y_STEP_PORT |= _BV(Y_STEP_PIN);

	MotorStart();
}

void MotorStart(void) {
	// At the moment, we don't actually do anything here because
	// VMOT on the driver is always powered. In the future, 
	// use a FET to drive VMOT and we'll then switch the FET
	// on/off in MotorStart and MotorStop
}

void MotorStop(void) {
	MoveAbort();
	// If we had a FET controlling VMOT, we'd want to turn that
	// off as well
}

void MotorXSetDirection(bool dir) {
#if(X_DIR_REVERSE == 1)
	dir = !dir;
#endif
	if (dir) {
		// Pull dir high
		X_DIR_PORT |= _BV(X_DIR_PIN);
	} else {
		// Pull dir low
		X_DIR_PORT &= ~_BV(X_DIR_PIN);
	}
}

void MotorYSetDirection(bool dir) {
#if(Y_DIR_REVERSE == 1)
	dir = !dir;
#endif
	if (dir) {
		// Pull dir high
		Y_DIR_PORT |= _BV(Y_DIR_PIN);
	} else {
		// Pull dir low
		Y_DIR_PORT &= ~_BV(Y_DIR_PIN);
	}
}

void MotorXSetStep(void) { X_IN_STEP = true; }
void MotorYSetStep(void) { Y_IN_STEP = true; }

void MotorStep(void) {
	// Step start by pulling low
	if (X_IN_STEP) { X_STEP_PORT &= ~_BV(X_STEP_PIN); }
	if (Y_IN_STEP) { Y_STEP_PORT &= ~_BV(Y_STEP_PIN); }

	// Delay
	_delay_us(2);

	// Step stop by pulling back high
	if (X_IN_STEP) { X_STEP_PORT |= _BV(X_STEP_PIN); }
	if (Y_IN_STEP) { Y_STEP_PORT |= _BV(Y_STEP_PIN); }
	X_IN_STEP = false;
	Y_IN_STEP = false;
}
