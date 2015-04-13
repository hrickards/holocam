/* ****************************************************************************
   Move.c

	 Handles movements (stored in a FIFO implemented as a ring buffer), and then
	 steps them (very rudimentarily at the moment --- no speed control)

	 All position in here stored as an integer (of type position, defined in
	 Move.h, at the moment as a signed int8)
***************************************************************************** */

#include "stdbool.h"
#include <avr/interrupt.h>
#include "Move.h"
#include "Motor.h"

// Current position. Should be updated by the thing that is calling RingRemove,
// not RingRemove itself
static volatile position CurrentX, CurrentY, CurrentTheta, CurrentPhi;
// Target position: the position at the end of the movement we're currently 
// completing. Again, should be updated by the thing calling RingRemove, not
// RingRemove itself. After a movement has been completed, these target
// variables should not be modified until the start of a new movement.
static position TargetX, TargetY, TargetTheta, TargetPhi;
// Endgoal position: the element at tail in the ring
static void ReadEndgoalPosition(position *x, position *y, position *theta, position *phi);

// Three ring buffers to store (x,y,theta,phi) in. However we only keep one]
// head/tail, because all are updated/read simultaneously
#define RING_SIZE 64 // Make a power of 2 to make modular arithmetic a lot faster
// Ring buffer code based on that from
// http://www.downtowndougbrown.com/2014/08/microcontrollers-uarts/
static byte RingHead;
static byte RingTail;
static position RingDataX[RING_SIZE];
static position RingDataY[RING_SIZE];
static position RingDataTheta[RING_SIZE];
static position RingDataPhi[RING_SIZE];
static int RingAdd(position x, position y, position theta, position phi);
static int RingRemove(position *x, position *y, position *theta, position *phi);
inline static bool BufferFull(void);
inline static bool BufferEmpty(void);

// Safely add two positions avoiding integer overflow
static position SafeAdd(position a, position b);

// Whether there is currently a movement in progress. If there isn't, we don't
// need to start one in MoveSpin
static volatile bool CurrentMovement;

// Which direction each axis needs to move in
static bool XDir, YDir, ThetaDir, PhiDir;

// Each motor step
static void MoveStep(void);
// Calculations before the first MoveStep of each movement
static void PrecalculateMovement(void);
// When movement is finished
static void FinishMovement(void);

void MoveInit(void) {
	// Setup ring buffer
	RingHead = 0;
	RingTail = 0;

	// Disable timer til we need it later
	TIMSK2 &= ~_BV(TOIE2);
	// Configure timer in normal mode (no CTC)
	TCCR2A &= ~(_BV(WGM21) | _BV(WGM20));
  TCCR2B &= ~_BV(WGM22);
	// Use system clock for timer
	ASSR &= ~_BV(AS2);
	// Enable overflow interrupt only, no compare interrupt
  TIMSK2 &= ~_BV(OCIE2A);
	// 1024 prescaler
	TCCR2B |= _BV(CS22) | _BV(CS21) | _BV(CS20);

	// We start off stationary!
	CurrentMovement = false;

	CurrentX = 0;
	CurrentY = 0;
	CurrentTheta = 0;
	CurrentPhi = 0;
	TargetX = 0;
	TargetY = 0;
	TargetTheta = 0;
	TargetPhi = 0;
	MoveHomeX();
	MoveHomeY();
}

// Called on each iteration of the main loop (NOT via interrupts)
void MoveSpin(void) {
	// If there are movements we can make in the buffer, and we're currently not moving,
	// make them
	if (!CurrentMovement && !BufferEmpty()) {
		RingRemove(&TargetX, &TargetY, &TargetTheta, &TargetPhi);
		PrecalculateMovement();
		MoveStep();
	}
}

// Called before the start of each movement.
// Calculates anything we need to calculate or set before beginning a movement
void PrecalculateMovement(void) {
	CurrentMovement = true;
	XDir = (CurrentX < TargetX);
	YDir = (CurrentY < TargetY);
	ThetaDir = (CurrentTheta < TargetTheta);
	PhiDir = (CurrentPhi < TargetPhi);
}

// Perform one step in the movement, and set MoveStep to be called again
// via a timer
void MoveStep(void) {
	// Increment each stepper in the direction required, if it needs to be moved
	// Sets direction pin, pulls step pin low, waits 2us, then pulls step pin high
	if (CurrentX != TargetX) {
		MotorXSetDirection(XDir);
		MotorXSetStep();
		if (XDir) { CurrentX++; } else { CurrentX--; }
	}
	if (CurrentY != TargetY) {
		MotorYSetDirection(YDir);
		MotorYSetStep();
		if (YDir) { CurrentY++; } else { CurrentY--; }
	}
	MotorStep();

	// TODO: Make theta, phi motors move
	if (CurrentTheta != TargetTheta) { CurrentTheta++; }
	if (CurrentPhi != TargetPhi) { CurrentPhi++; }

	if ((CurrentX != TargetX) || (CurrentY != TargetY) || (CurrentTheta != TargetTheta) || (CurrentPhi != TargetPhi)) {
		// TODO: Change this based on a desired velocity based on Bresenham
		// IMPORTANT: Things will get weird if this delay is less than the delay used in Motor.c of ~2us
		TCNT2 = 0;
		TIMSK2 |= _BV(TOIE2);
	} else {
		FinishMovement();
	}
}
// Called when our timer overflows
ISR(TIMER2_OVF_vect) {
	// Disable timer
	TIMSK2 &= ~_BV(TOIE2);

	// Move another step
	MoveStep();
}

// Called after a movement happens
void FinishMovement(void) {
	// We're not moving anymore
	CurrentMovement = false;
}

// Move to a new absolutely specified position
inline int MoveAddAbsolute(position x, position y, position theta, position phi) { return RingAdd(x, y, theta, phi); }

// Move relative to the current endgoal position (the last element in the ring buffer, or the target of
// the current move if the buffer is empty)
int MoveAddRelative(position x, position y, position theta, position phi) {
	// Calculate an absolute position to move to
	position endgoalX = 0, endgoalY = 0, endgoalTheta = 0, endgoalPhi = 0;
	ReadEndgoalPosition(&endgoalX, &endgoalY, &endgoalTheta, &endgoalPhi);

	// SafeAdd ensures we don't have integer overflows
	return MoveAddAbsolute(SafeAdd(endgoalX, x), SafeAdd(endgoalY, y), SafeAdd(endgoalTheta, theta), SafeAdd(endgoalPhi, phi));
}

// Safely add two positions avoiding integer overflow. Just don't add if there would
// be one.
// This is SLOW: don't call it as part of actual movement code
static position SafeAdd(position a, position b) {
	// Detect overflow
	if (a > 0 && b > POSITION_MAX - a) {
		return a;
	} else if (a < 0 && b < POSITION_MIN - a) {
		return a;
	} else {
		return a+b;
	}
}

// Cancel any buffered moves
// TODO: Cancel the current move (interrupt-safely)
void MoveAbort(void) {
	RingHead = RingTail;
}

// Home x and y axes with endstops
void MoveHomeX(void) {
	// TODO
}

void MoveHomeY(void) {
	// TODO
}

// Read the last position tuple in the ring and store it in the passed variables
// If the ring is empty, use Target position variables instead
void ReadEndgoalPosition(position *x, position *y, position *theta, position *phi) {
	if (RingHead != RingTail) {
		// Buffer not empty
		// Find the previous RingHead, without doing modulo of a negative number, because
		// that doesn't return what you might think in C
		byte prev_head = (RingHead + RING_SIZE - 1) % RING_SIZE;
		*x = RingDataX[prev_head];
		*y = RingDataY[prev_head];
		*theta = RingDataTheta[prev_head];
		*phi = RingDataPhi[prev_head];
	} else {
		// Nothing in buffer
		*x = TargetX;
		*y = TargetY;
		*theta = TargetTheta;
		*phi = TargetPhi;
	}
}
inline void MoveGetTargetPosition(position *x, position *y, position *theta, position *phi) { ReadEndgoalPosition(x, y, theta, phi); }
// Get the current position
void MoveGetCurrentPosition(position *x, position *y, position *theta, position *phi) {
	*x = CurrentX;
	*y = CurrentY;
	*theta = CurrentTheta;
	*phi = CurrentPhi;
}

// Raw ring buffer access functions
// If the head and tail are equal, the buffer is empty
bool BufferEmpty(void) { return (RingHead == RingTail); }

// If the head is one slot behind the tail, the buffer is full
bool BufferFull(void) { return ((RingHead + 1) % RING_SIZE) == RingTail; }

// Add a position tuple to the ring
static int RingAdd(position x, position y, position theta, position phi) {
	byte next_head = (RingHead + 1) % RING_SIZE;
	if (next_head != RingTail) {
		// There is room
		RingDataX[RingHead] = x;
		RingDataY[RingHead] = y;
		RingDataTheta[RingHead] = theta;
		RingDataPhi[RingHead] = phi;
		RingHead = next_head;
		return 0;
	} else {
		// No more room
		return -1;
	}
}

// Read the next position tuple from the ring and store it in the passed variables
static int RingRemove(position *x, position *y, position *theta, position *phi) {
	if (RingHead != RingTail) {
		// Buffer not empty
		*x = RingDataX[RingTail];
		*y = RingDataY[RingTail];
		*theta = RingDataTheta[RingTail];
		*phi = RingDataPhi[RingTail];
		RingTail = (RingTail + 1) % RING_SIZE;
		return 0;
	} else {
		// Nothing in buffer
		return -1;
	}
}

