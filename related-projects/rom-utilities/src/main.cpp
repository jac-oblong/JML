/*
** A tool for AT28C64 family EEPROMs
*/

#include "HardwareSerial.h"
#include "Print.h"
#include "Stream.h"
#include <Arduino.h>

const int OE = 52;
const int CS = 50;
const int WE = 48;

// addr pins are the pins between ADDR0 and ADDR12
const int ADDR0 = 34;
const int ADDR12 = 46;

// data pins are all pins between DATA0 and DATA7
const int DATA0 = 22;
const int DATA7 = 29;

const int OP_SIZE = 16;

/*
** sets data pins to be input if 'direction' or output if '!direction'
*/
void setup_pins(bool direction);
/*
** sets the addr pins to the address 'addr'
*/
void set_addr(uint16_t addr);
/*
** sets the data pins to data 'data'
*/
void set_data(uint8_t data);
/*
** returns the current data on the data pins
*/
uint8_t get_data();

void setup() {
  Serial.begin(9600);

  digitalWrite(OE, HIGH);
  digitalWrite(WE, HIGH);
  digitalWrite(CS, HIGH);
  pinMode(OE, OUTPUT);
  pinMode(WE, OUTPUT);
  pinMode(CS, OUTPUT);

  for (int i = ADDR0; i < ADDR12; i++) {
    pinMode(i, OUTPUT);
  }

  setup_pins(false);

  /*
  ** when first connecting Arduino to computer, the computer will send a value
  ** and the Arduino verifies itself by sending the same value, but with all
  ** bits flipped
  */
  while (Serial.available() == 0) {
  }
  uint8_t b = Serial.read();
  b = ~b;
  Serial.write(b);
}

void loop() {
  /*
  ** The Arduino will wait to receive an operation code over the serial port
  ** 0x00 -> read operation
  ** 0x01 -> write operation
  **
  ** Both reads and writes occur in 16 byte increments. After receiving the
  ** operation code, the Arduino will wait for the starting address of the
  ** operation (a 2 byte value, MSB first).
  **
  ** For a read operation, the Arduino will then send 16 bytes back over the
  ** serial port, corresponding to the 16 memory addresses starting from the one
  ** recieved.
  **
  ** For a write operation, the Arduino expects 16 bytes, which will then be
  ** programmed into the EEPROM starting at the address received.
  ** If less than 16 bytes should be written, first read the 16 bytes, then
  ** change the desired locations, then write the 16 bytes.
  **
  ** Addresses will wrap for all operations (i.e. if address 0x1FFF is reached,
  ** the next address will be 0x0000)
  **
  ** Once an operation has been completed, 0xFF will be written to the serial
  ** port to signify that it is ready for another operation.
  */
  while (Serial.available() < 3) {
  }

  uint8_t rw = Serial.read();
  uint16_t addr = Serial.read();
  addr = addr << 8;
  addr |= Serial.read();
  if (rw == 0x00) {
    // read contents of EEPROM
    digitalWrite(CS, HIGH);
    digitalWrite(WE, HIGH);
    digitalWrite(OE, HIGH);
    setup_pins(true);

    for (int i = 0; i < OP_SIZE; i++) {
      set_addr(addr + i);
      digitalWrite(CS, LOW);
      digitalWrite(OE, LOW);
      delayMicroseconds(1);
      Serial.write(get_data());
      digitalWrite(CS, HIGH);
      digitalWrite(OE, HIGH);
    }

  } else if (rw == 0x01) {
    // write data to EEPROM
    digitalWrite(WE, HIGH);
    digitalWrite(OE, HIGH);
    digitalWrite(CS, HIGH);
    setup_pins(false);

    for (int i = 0; i < OP_SIZE; i++) {
      set_addr(addr + i);

      while (Serial.available() == 0) {
      }
      uint8_t data = Serial.read();
      set_data(data);

      digitalWrite(CS, LOW);
      digitalWrite(WE, LOW);
      delayMicroseconds(1);
      digitalWrite(WE, HIGH);
      digitalWrite(CS, HIGH);
    }
  }

  digitalWrite(OE, HIGH);
  digitalWrite(WE, HIGH);
  digitalWrite(CS, HIGH);
  setup_pins(true);

  delayMicroseconds(50);

  Serial.write(0xFF);
}

void setup_pins(bool direction) {
  for (int i = DATA0; i < DATA7; i++) {
    if (direction) {
      pinMode(i, INPUT);
    } else {
      pinMode(i, OUTPUT);
    }
  }
}

void set_addr(uint16_t mem) {
  for (int i = ADDR0; i <= ADDR12; i++) {
    digitalWrite(i, mem & 1);
    mem = mem >> 1;
  }
}

void set_data(uint8_t data) {
  for (int i = DATA0; i <= DATA7; i++) {
    if ((data & 0x01) != 0) {
      digitalWrite(i, HIGH);
    } else {
      digitalWrite(i, LOW);
    }
    data = data >> 1;
  }
}

uint8_t get_data() {
  uint8_t data = 0;
  for (int i = DATA7; i >= DATA0; i--) {
    data = data << 1;
    if (digitalRead(i)) {
      data |= 0x01;
    } else {
      data &= 0xFE;
    }
  }
  return data;
}
