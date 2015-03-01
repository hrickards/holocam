/* ****************************************************************************
   holocam.c

	 Essentially split into two phases: init() which runs initial setup code,
	 and then a loop (spin()) which runs repeatedly

	 Compile to a level that expands functions as some functions are only ever
	 called from the context of one place, but are seperated for modularity.
***************************************************************************** */

// Movement is the priority, so that is done with interrupts using timers
// Interrupts are used to store serial data whenever it arrives, and that data is parsed
//     and acted upon in a loop

#include <avr/interrupt.h>

#include "Command.h"
#include "Global.h"
#include "Move.h"
#include "Motor.h"

void init(void);
void spin(void);

// Called on startup. Run init()
int main(void) {
	init();

	// Loop forever
	while (1) {
		spin();
	}
}

// Setup code
void init(void) {
	// Enable interrupts
	sei();

	// Intiial setup for motors (this doesn't turn the drivers on --- we have
	// MotorStart and MotorStop for that)
	MotorInit();

	// Setup the command interface
	CommandInit();

	// Setup ring buffer to store movements in
	MoveInit();
}


// Runs repeatedly forever. Don't do anything too time-sensitive (movements, etc)
// in here: handle those with interrupts instead
void spin(void) {
	// Respond to commands
	CommandSpin();

	// Move
	MoveSpin();
}
