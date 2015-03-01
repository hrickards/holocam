/* ****************************************************************************
   UART.c

	 Handles interrupt-driven serial communication with RPi over USB (Arduino has
	 an onboard USB UART chip)
***************************************************************************** */

#include <avr/io.h>
#include <avr/interrupt.h>
#include "UART.h"

// fosc = 16MHz in an Arduino board, so choosing 250k gives a good comprimise
// between error and speed (see p189 of ATMega 328 datasheet):w
#define BAUD	9600
// Calculates UBRRL_VALUE, UBRRH_VALUE and USE_2X for us from BAUD
#include <util/setbaud.h>

// Two ring buffers to store rx/tx data in. Taken from 
// http://www.downtowndougbrown.com/2014/08/microcontrollers-uarts/
#define RING_SIZE 256 // Make a power of 2 to make modular arithmetic a lot faster
 
// Transmission ring
// volatile so we can access in main code and interrupts
static volatile byte TXRingHead;
static volatile byte TXRingTail;
static volatile byte TXRingData[RING_SIZE];
static int TXRingAdd(byte c);
static int TXRingRemove(void);
inline static bool TXBufferFull(void);
inline static bool TXBufferEmpty(void);
 
// Receive ring
static volatile byte RXRingHead;
static volatile byte RXRingTail;
static volatile byte RXRingData[RING_SIZE];
static int RXRingAdd(byte c);
static int RXRingRemove(void);
inline static bool RXBufferFull(void);
inline static bool RXBufferEmpty(void);

// Store the number of lines (=number of 0x0D chars) in the
// receive buffer
static uint8_t LinesPresent = 0;

// Initially setup up UART
void UARTInit(void) {
	// Set baud rate
	UBRR0H = UBRRH_VALUE;
	UBRR0L = UBRRL_VALUE;

	// If we need to reduce clock divisor to obtain baud rate, do so
#if USE_2X
	UCSR0A |= _BV(U2X0);
#else
	UCSR0A &= ~(_BV(U2X0));
#endif

	// Set frame format
	// Parity disabled (00), so don't set UPM00 or UPM01
	// 1 stop bit, so don't set USBS0
	// Synchronous (00, so don't set UMSEL00 or UMSEL01
	// 8-bit data (011 -> 8 bits), so set UCSZ00 and UCSZ01, but not UCSZ02
	UCSR0C = _BV(UCSZ01) | _BV(UCSZ00);

	// Enable RX and TX
	UCSR0B = _BV(RXEN0) | _BV(TXEN0) | _BV(RXCIE0);

	// Initialise ring buffers
	TXRingHead = 0;
	RXRingHead = 0;
	TXRingTail = 0;
	RXRingTail = 0;
}


// From here on out, ring buffer code copied from
// http://www.downtowndougbrown.com/2014/08/microcontrollers-uarts/
void UARTWriteByte(byte data) {
    // Wait until there's room in the ring buffer
    while (TXBufferFull());
 
    // Add the data to the ring buffer now that there's room
    TXRingAdd(data);
 
    // Ensure the data register empty interrupt is turned on
    // (it gets turned off automatically when the UART is idle)
    UCSR0B |= _BV(UDRIE0);
}

bool UARTByteAvailable(void) { return !RXBufferEmpty(); }
bool UARTLineAvailable(void) { return LinesPresent > 0; }
 
byte UARTReadByte(void) {
    // Wait until a byte is available to read
    while (RXBufferEmpty());
 
    // Then return the byte
    return RXRingRemove();
}
 
bool RXBufferEmpty(void) {
    // If the head and tail are equal, the buffer is empty.
    return (RXRingHead == RXRingTail);
}
 
bool TXBufferEmpty(void) {
    // If the head and tail are equal, the buffer is empty.
    return (TXRingHead == TXRingTail);
}
 
bool RXBufferFull(void) {
    // If the head is one slot behind the tail, the buffer is full.
    return ((RXRingHead + 1) % RING_SIZE) == RXRingTail;
}
 
bool TXBufferFull(void) {
    // If the head is one slot behind the tail, the buffer is full.
    return ((TXRingHead + 1) % RING_SIZE) == TXRingTail;
}
 
static int TXRingAdd(byte c) {
    byte next_head = (TXRingHead + 1) % RING_SIZE;
    if (next_head != TXRingTail) {
        /* there is room */
        TXRingData[TXRingHead] = c;
        TXRingHead = next_head;
        return 0;
    } else {
        /* no room left in the buffer */
        return -1;
    }
}
 
static int TXRingRemove(void) {
    if (TXRingHead != TXRingTail) {
        int c = TXRingData[TXRingTail];
        TXRingTail = (TXRingTail + 1) % RING_SIZE;
        return c;
    } else {
        return -1;
    }
}
 
static int RXRingAdd(byte c) {
    byte next_head = (RXRingHead + 1) % RING_SIZE;
    if (next_head != RXRingTail) {
        /* there is room */
        RXRingData[RXRingHead] = c;
        RXRingHead = next_head;
				if (c == LINE_END) { LinesPresent++; }
        return 0;
    } else {
        /* no room left in the buffer */
        return -1;
    }
}
 
static int RXRingRemove(void) {
    if (RXRingHead != RXRingTail) {
        int c = RXRingData[RXRingTail];
        RXRingTail = (RXRingTail + 1) % RING_SIZE;
				if (c == LINE_END) { LinesPresent--; }
        return c;
    } else {
        return -1;
    }
}
 
ISR(USART_RX_vect) {
    byte data = UDR0;
    RXRingAdd(data);
}
 
ISR(USART_UDRE_vect) {
    if (!TXBufferEmpty()) {
        // Send the next byte if we have one to send
        UDR0 = (byte) TXRingRemove();
    } else {
        // Turn off the data register empty interrupt if
        // we have nothing left to send
        UCSR0B &= ~_BV(UDRIE0);
    }
}
