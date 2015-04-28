/* ****************************************************************************
   ServoDriver
   
   Communicates with a master over I2C, and moves two servos to the positions
   received over this channel
***************************************************************************** */

#include <Wire.h>   // I2C library
#include <Servo.h>  // Standard servo library

// Physical restrictions
// (servo itself allows 0 to 180 degrees)
#define TILT_MIN 1250
#define TILT_MAX 2300
#define PAN_MIN 700
#define PAN_MAX 2300

// Control pins: connect Vcc/GND appropriately
#define TILT_PIN 5
#define PAN_PIN 6

// Arbitrary, but make sure it matches on the master
#define I2C_ADDRESS 0

// Notification LED
#define LED_PIN 13

// Servo library objects
Servo tiltServo;
Servo panServo;

void setup() {
  // Initialise servos
  tiltServo.attach(TILT_PIN);
  panServo.attach(PAN_PIN);
  
  // Initialise I2C
  Wire.begin(I2C_ADDRESS);
  Wire.onReceive(receiveDataEvent);
  
  // Initialise output LED
  digitalWrite(LED_PIN, LOW);
  pinMode(LED_PIN, OUTPUT);
}

void loop() {
  delay(100);
}

// Called whenever we receive I2C data. Data formatted into 2-byte
// commands. For now (TODO) we require both bytes to be sent simultaneously
// and not with any other data.
// Bit 0: 0 for tilt servo, 1 for pan servo
// Bits 1-12: number of microseconds to move servo to
void receiveDataEvent(int numBytes) {
  if (numBytes == 2) {
    byte b1 = Wire.read();
    byte b2 = Wire.read();
    
    // int is 16-bit signed (vs. standard 8-bit 'unsigned' byte)
    // Want bits 1 through 7 of byte 0, and bits 0 through 4 of byte 1
    // 0b11111000 = 0xF8
    // 0b10000000 = 0x7F
    int value = ((b1 & 0x7F) << 5) | ((b2 & 0xF8) >> 3);
    byte address = (b1 >> 7);
    
    // Toggle LED
    digitalWrite(LED_PIN, !digitalRead(LED_PIN));

    // Move required servo, capping at min/max values for that servo
    if (address) {
      if (value < TILT_MIN) {
        value = TILT_MIN;
      } else if (value > TILT_MAX) {
        value = TILT_MAX;
      }
      tiltServo.writeMicroseconds(value);
    } else {
      if (value < PAN_MIN) {
        value = PAN_MIN;
      } else if (value > PAN_MAX) {
        value = PAN_MAX;
      }
      panServo.writeMicroseconds(value);
    }
  } else {
    // TODO: Handle the error case here
    // Can we really do anything without implementing (needlessly) bidirectional comms?
  }
}
