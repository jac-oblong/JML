/*
** A tool for AT28C64 family EEPROMs
*/

#include "HardwareSerial.h"
#include "Print.h"
#include "Stream.h"
#include <Arduino.h>

const int OE = 48;
const int WE = 50;
const int CS = 52;

// addr pins are the even numbered pins between ADDR0 and ADDR12
const int ADDR0 = 22;
const int ADDR12 = 46;

// data pins are all pins between DATA0 and DATA7
const int DATA0 = 2;
const int DATA7 = 9;

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

  for (int i = ADDR0; i < ADDR12; i += 2) {
    pinMode(i, OUTPUT);
  }

  setup_pins(false);
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
    setup_pins(true);
    digitalWrite(CS, LOW);
    digitalWrite(OE, LOW);

    for (int i = 0; i < OP_SIZE; i++) {
      set_addr(addr + i);
      delayMicroseconds(1);
      Serial.write(get_data());
    }

  } else if (rw == 0x01) {
    // write data to EEPROM
    digitalWrite(WE, HIGH);
    digitalWrite(OE, HIGH);
    digitalWrite(CS, HIGH);
    setup_pins(false);
    digitalWrite(CS, LOW);

    for (int i = 0; i < OP_SIZE; i++) {
      set_addr(addr + i);

      while (Serial.available() == 0) {
      }
      uint8_t data = Serial.read();
      set_data(data);

      digitalWrite(WE, LOW);
      delayMicroseconds(1);
      digitalWrite(WE, HIGH);
    }

  } else {
    Serial.print("Unrecognized code: ");
    Serial.println(rw, HEX);
  }

  digitalWrite(OE, HIGH);
  digitalWrite(WE, HIGH);
  digitalWrite(CS, HIGH);
  setup_pins(true);

  delayMicroseconds(50);
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
  for (int i = ADDR0; i <= ADDR12; i += 2) {
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
  for (int i = 37; i >= 23; i -= 2) {
    data = data << 1;
    if (digitalRead(i)) {
      data |= 0x01;
    } else {
      data &= 0xFE;
    }
  }
  return data;
}
