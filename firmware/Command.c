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

// Convert bytes to/from positions containing (large) integers
// position is a signed 16-bit int, and we can't use 0D to
// represent any 8-bit byte of it because that's our newline
// So 3 bytes are required
void PositionToBytes(position pos, byte *b1, byte *b2, byte *b3);
void BytesToPosition(byte b1, byte b2, byte b3, position *pos);

// Initial setup of the command interface
void CommandInit(void) {
	UARTInit();
}

// Parse and act upon a command on each run of the main loop
void CommandSpin(void) {
	if (UARTLineAvailable()) {
		byte command = UARTReadByte();

		// TODO: Code here is very duplicated. Is there a way we can reduce it without losing speed?
		switch (command) {
			case MOVE_ABS: {
				// Read position bytes
				byte x1 = UARTReadByte();
				byte x2 = UARTReadByte();
				byte x3 = UARTReadByte();
				byte y1 = UARTReadByte();
				byte y2 = UARTReadByte();
				byte y3 = UARTReadByte();
				byte theta1 = UARTReadByte();
				byte theta2 = UARTReadByte();
				byte theta3 = UARTReadByte();
				byte phi1 = UARTReadByte();
				byte phi2 = UARTReadByte();
				byte phi3 = UARTReadByte();

				// If any of those bytes are a newline, then something went wrong in transmission
				// and we should ignore that command
				if ((x1 == LINE_END) || (x2 == LINE_END) || (x3 == LINE_END) || (y1 == LINE_END) || (y2 == LINE_END) || (y3 == LINE_END) || (theta1 == LINE_END) || (theta2 == LINE_END) || (theta3 == LINE_END) || (phi1 == LINE_END) || (phi2 == LINE_END) || (phi3 == LINE_END)) {
					// Return an error
					UARTWriteByte(MOVE_ABS_RETURN);
					UARTWriteByte(FAILURE);
					UARTWriteByte(LINE_END);
				}

				// Convert to positions
				position xPos, yPos, thetaPos, phiPos;
				BytesToPosition(x1, x2, x3, &xPos);
				BytesToPosition(y1, y2, y3, &yPos);
				BytesToPosition(theta1, theta2, theta3, &thetaPos);
				BytesToPosition(phi1, phi2, phi3, &phiPos);

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

			case MOVE_REL: {
				// Read position bytes
				byte x1 = UARTReadByte();
				byte x2 = UARTReadByte();
				byte x3 = UARTReadByte();
				byte y1 = UARTReadByte();
				byte y2 = UARTReadByte();
				byte y3 = UARTReadByte();
				byte theta1 = UARTReadByte();
				byte theta2 = UARTReadByte();
				byte theta3 = UARTReadByte();
				byte phi1 = UARTReadByte();
				byte phi2 = UARTReadByte();
				byte phi3 = UARTReadByte();

				// If any of those bytes are a newline, then something went wrong in transmission
				// and we should ignore that command
				if ((x1 == LINE_END) || (x2 == LINE_END) || (x3 == LINE_END) || (y1 == LINE_END) || (y2 == LINE_END) || (y3 == LINE_END) || (theta1 == LINE_END) || (theta2 == LINE_END) || (theta3 == LINE_END) || (phi1 == LINE_END) || (phi2 == LINE_END) || (phi3 == LINE_END)) {
					// Return an error
					UARTWriteByte(MOVE_REL_RETURN);
					UARTWriteByte(FAILURE);
					UARTWriteByte(LINE_END);
				}

				// Convert to positions
				position xPos, yPos, thetaPos, phiPos;
				BytesToPosition(x1, x2, x3, &xPos);
				BytesToPosition(y1, y2, y3, &yPos);
				BytesToPosition(theta1, theta2, theta3, &thetaPos);
				BytesToPosition(phi1, phi2, phi3, &phiPos);

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

			case HOME_X:
				MoveHomeX();
				break;

			case HOME_Y:
				MoveHomeX();
				break;

			case START:
				MotorStart();
				break;

			case STOP:
				MotorStop();
				break;

			case ABORT:
				MoveAbort();
				break;

			case GET_POS: {
				// Get current position
				position xPos, yPos, thetaPos, phiPos;
				MoveGetCurrentPosition(&xPos, &yPos, &thetaPos, &phiPos); 

				// Convert to bytes
				byte x1, x2, x3, y1, y2, y3, theta1, theta2, theta3, phi1, phi2, phi3;
				PositionToBytes(xPos, &x1, &x2, &x3);
				PositionToBytes(yPos, &y1, &y2, &y3);
				PositionToBytes(thetaPos, &theta1, &theta2, &theta3);
				PositionToBytes(phiPos, &phi1, &phi2, &phi3);

				// Output
				UARTWriteByte(POS_RETURN);
				UARTWriteByte(x1);
				UARTWriteByte(x2);
				UARTWriteByte(x3);
				UARTWriteByte(y1);
				UARTWriteByte(y2);
				UARTWriteByte(y3);
				UARTWriteByte(theta1);
				UARTWriteByte(theta2);
				UARTWriteByte(theta3);
				UARTWriteByte(phi1);
				UARTWriteByte(phi2);
				UARTWriteByte(phi3);
				UARTWriteByte(LINE_END);
				break;
			}

			case GET_TARGET: {
				// Get target position
				position xPos, yPos, thetaPos, phiPos;
				MoveGetTargetPosition(&xPos, &yPos, &thetaPos, &phiPos); 

				// Convert to bytes
				byte x1, x2, x3, y1, y2, y3, theta1, theta2, theta3, phi1, phi2, phi3;
				PositionToBytes(xPos, &x1, &x2, &x3);
				PositionToBytes(yPos, &y1, &y2, &y3);
				PositionToBytes(thetaPos, &theta1, &theta2, &theta3);
				PositionToBytes(phiPos, &phi1, &phi2, &phi3);

				// Output
				UARTWriteByte(TARGET_RETURN);
				UARTWriteByte(x1);
				UARTWriteByte(x2);
				UARTWriteByte(x3);
				UARTWriteByte(y1);
				UARTWriteByte(y2);
				UARTWriteByte(y3);
				UARTWriteByte(theta1);
				UARTWriteByte(theta2);
				UARTWriteByte(theta3);
				UARTWriteByte(phi1);
				UARTWriteByte(phi2);
				UARTWriteByte(phi3);
				UARTWriteByte(LINE_END);
				break;
			}
		}

		// Read until the end of line
		byte b = 0x00;
		do {
			b = UARTReadByte();
		} while (b != LINE_END);
	}
}


// Coding scheme:
// p1, p2 = bytes of position (MSB p1 -> LSB p2 = MSB -> LSB)
// b1, b2 = p1, p2 with LSB set to 0 (LSB 0x0D = 1)
// b3 = (?, ?, ?, ?, ?, ?, LSB b1, LSB b2) TODO: Make the other bits parity bits
void PositionToBytes(position pos, byte *b1, byte *b2, byte *b3) {
	*b1 = (byte) ((pos >> 8) & 0xFE);
	*b2 = (byte) (pos & 0xFE);
	*b3 = (byte) ((pos & 0x01) | ((pos >> 7) & 0x02));
}

void BytesToPosition(byte b1, byte b2, byte b3, position *pos) {
	b1 |= ((b3 & 0x02) >> 1);
	b2 |= (b3 & 0x01);
	*pos = (((position) b1) << 8) | b2;
}
