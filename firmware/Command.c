/* ****************************************************************************
   Command.c
***************************************************************************** */

#include <avr/io.h>
#include <avr/interrupt.h>

#include "UART.h"
#include "Move.h"
#include "Motor.h"

#define MOVE_ABS 0x01
#define MOVE_REL 0x02
#define GET_POS 0x03
#define HOME_X 0x04
#define HOME_Y 0x05
#define START 0x06
#define STOP 0x07
#define ABORT 0x08
#define POS_RETURN 0x09
#define TARGET_RETURN 0x0A
#define SUCCESS 0x0B
#define FAILURE 0x0C
#define MOVE_ABS_RETURN 0x0E
#define GET_TARGET 0x0F
#define MOVE_REL_RETURN 0x10

// Initial setup of the command interface
void CommandInit(void) {
	UARTInit();
}

// Parse and act upon a command on each run of the main loop
void CommandSpin(void) {
	// Check we have a sequence of characters available up to the newline,
	// becuase we don't want any of our read operations to block
	if (UARTLineAvailable()) {
		byte command = UARTReadByte();

		// TODO: Code here is very duplicated. Is there a way we can reduce it without losing speed?
		switch (command) {
			// Move to a absolutely-specified position
			case MOVE_ABS: {
				// Read positions
				position xPos = UARTReadPosition();
				position yPos = UARTReadPosition();
				position thetaPos = UARTReadPosition();
				position phiPos = UARTReadPosition();

				// Try and move there
				UARTWriteByte(MOVE_ABS_RETURN);
				if (!MoveAddAbsolute(xPos, yPos, thetaPos, phiPos)) {
					UARTWriteByte(SUCCESS);
				} else {
					UARTWriteByte(FAILURE);
				}
				UARTWriteByte(LINE_END);
				break;
			}

			// move to a position specified relative to the current position
			case MOVE_REL: {
				// Read positions
				position xPos = UARTReadPosition();
				position yPos = UARTReadPosition();
				position thetaPos = UARTReadPosition();
				position phiPos = UARTReadPosition();

				// Try and move there
				UARTWriteByte(MOVE_REL_RETURN);
				if (!MoveAddRelative(xPos, yPos, thetaPos, phiPos)) {
					UARTWriteByte(SUCCESS);
				} else {
					UARTWriteByte(FAILURE);
				}
				UARTWriteByte(LINE_END);
				break;
			}

			// Home (move until the endstop is hit) the X axis
			case HOME_X:
				MoveHomeX();
				break;

			// Home (move until the endstop is hit) the Y axis
			case HOME_Y:
				MoveHomeX();
				break;

			// Power up all motors
			case START:
				MotorStart();
				break;

			// Cancel any future moves, and power down all motors	
			case STOP:
				MotorStop();
				break;

			// Power down all motors
			case ABORT:
				MoveAbort();
				break;

			// Send back the current platform position coordinates
			case GET_POS: {
				// Get current position
				position xPos, yPos, thetaPos, phiPos;
				MoveGetCurrentPosition(&xPos, &yPos, &thetaPos, &phiPos); 

				// Output
				UARTWriteByte(TARGET_RETURN);
				UARTWritePosition(xPos);
				UARTWritePosition(yPos);
				UARTWritePosition(thetaPos);
				UARTWritePosition(phiPos);
				UARTWriteByte(LINE_END);
				break;
			}

			// Send back the coordinates of the position the platform will end up
			// at after all current moves
			case GET_TARGET: {
				// Get target position
				position xPos, yPos, thetaPos, phiPos;
				MoveGetTargetPosition(&xPos, &yPos, &thetaPos, &phiPos); 

				// Output
				UARTWriteByte(TARGET_RETURN);
				UARTWritePosition(xPos);
				UARTWritePosition(yPos);
				UARTWritePosition(thetaPos);
				UARTWritePosition(phiPos);
				UARTWriteByte(LINE_END);
				break;
			}
		}

		// Read until the end of line to ensure we didn't miss any characters
		byte b = 0x00;
		do {
			b = UARTReadByte();
		} while (b != LINE_END);
	}
}
