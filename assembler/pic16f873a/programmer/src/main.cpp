#include <Arduino.h>


// PINS
const int START_PIN     = A0;
const int START_LED     = A1;
const int ERASE_PIN     = A2;
const int ERASE_LED     = A3;
const int PROGM_PIN     = A4;
const int PROGM_LED     = A5;
const int PROGM_CLK     =  2;
const int PROGM_DTA     =  3;
const int MASTR_CLR     =  4;
const int PROGM_MAN     =  5;

// control whether or not to do anything
bool started = false;
// control whether or not we are programming
bool programming = false;
// control whether program memory has be completed
bool progm_mem_done = false;
// number of bytes recieved through Serial
unsigned long num_bytes_recieved;
// current data gotten from serial port
uint16_t serial_data;
// number of loads performed since last program command
uint8_t num_loads;


/* handles the leds and when they should be on, an led being on means
 * that the corresponding push-button will recieve an input */ 
void handle_leds();
/* starts programming of the pic */ 
void start_progm();
/* erases the entire pic microcontroller */
void erase_pic();
/* loads data into the pic; true ==> program memory; false ==> data memory */
void load_mem(uint16_t data, bool progm);
/* increments the address */ 
void incr_address();
/* begins erase/program of pic */ 
void begin_erase_program();


void setup() {
  // slow baud rate because need to wait while programming pic
  Serial.begin(2400); 
  
  digitalWrite(START_PIN, LOW);
  digitalWrite(START_LED, LOW);
  digitalWrite(ERASE_PIN, LOW);
  digitalWrite(ERASE_LED, LOW);
  digitalWrite(PROGM_PIN, LOW);
  digitalWrite(PROGM_LED, LOW);
  digitalWrite(PROGM_CLK, LOW);
  digitalWrite(PROGM_DTA, LOW);
  digitalWrite(MASTR_CLR, LOW);
  digitalWrite(PROGM_MAN, LOW);

  pinMode(START_PIN, INPUT);
  pinMode(ERASE_PIN, INPUT);
  pinMode(PROGM_PIN, INPUT);
  
  pinMode(START_LED, OUTPUT);
  pinMode(ERASE_LED, OUTPUT);
  pinMode(PROGM_LED, OUTPUT);
  pinMode(PROGM_CLK, OUTPUT);
  pinMode(PROGM_DTA, OUTPUT);
  pinMode(MASTR_CLR, OUTPUT);
  pinMode(PROGM_MAN, OUTPUT);
}

void loop() {
  handle_leds();

  if (!started && digitalRead(START_PIN)) {
    started = true;
    Serial.print("Starting...");
    start_progm();
    Serial.println("Done");
  }
  if (!started) return;

  if (digitalRead(ERASE_PIN) && !programming) {
    Serial.print("Erasing...");
    erase_pic();
    Serial.println("Done");
  }

  if (digitalRead(PROGM_PIN)) {
    programming = true;
    Serial.println("Programming has begun, send data now");
  }
  if (!programming) return;

  if (Serial.available() > 0) {
    num_bytes_recieved++;
    
    int inByte = Serial.read();

    if (!progm_mem_done && num_bytes_recieved <= 8192) { // still in instruction memory
      if (num_bytes_recieved % 2 == 1) {
        serial_data = inByte << 8;
      } else {
        inByte &= 0x000000FF;
        serial_data |= inByte;
        load_mem(serial_data, true);
        incr_address();
      }

    } else { // now in regular memory
      load_mem(inByte, false);
      incr_address();
      
    }
    
    // begin programming if 8 bytes loaded
    if (num_loads == 8) {
      begin_erase_program();
      num_loads = 0;
    } 
    
    // if end of program mem continue to data mem
    if (num_bytes_recieved == 8192) {
      // move to eeprom memory
      progm_mem_done = true;
      programming = false;

      // move to data memory
      digitalWrite(PROGM_DTA, LOW);
      for (int i=0; i < 6; i++) {
        digitalWrite(PROGM_CLK, HIGH);
        delayMicroseconds(2);
        digitalWrite(PROGM_CLK, LOW);
      }

      // move to address 0x2100
      for (int i=0; i < 100; i++) {
        incr_address();
      }  
    }
  }
}

void handle_leds() {
  digitalWrite(START_LED, LOW);
  digitalWrite(ERASE_LED, LOW);
  digitalWrite(PROGM_LED, LOW);
  if (!started) {
    digitalWrite(START_LED, HIGH);
  } else if (!programming) {
    digitalWrite(ERASE_LED, HIGH);
    digitalWrite(PROGM_LED, HIGH);
  }
}

void start_progm() {
  digitalWrite(PROGM_MAN, HIGH);
  delayMicroseconds(2);
  digitalWrite(MASTR_CLR, HIGH);
}

void erase_pic() {
  // load configuration so ALL data is erased (code is 0b00000)
  digitalWrite(PROGM_DTA, LOW); 
  for (int i=0; i < 6; i++) {
    digitalWrite(PROGM_CLK, HIGH);
    delayMicroseconds(2);
    digitalWrite(PROGM_CLK, LOW);
  }

  // erase chip (code is 0b11111)
  digitalWrite(PROGM_DTA, HIGH);
  for (int i=0; i < 6; i++) {
    digitalWrite(PROGM_CLK, HIGH);
    delayMicroseconds(2);
    digitalWrite(PROGM_CLK, LOW);
  }
  digitalWrite(PROGM_DTA, LOW); 
  delay(10); // wait for erase to complete

  // get out of and re-enter programming mode so back at adress 0x0000
  digitalWrite(PROGM_MAN, LOW);
  delayMicroseconds(2);
  digitalWrite(MASTR_CLR, LOW);
  delayMicroseconds(2);
  start_progm();
}

void load_mem(uint16_t data, bool progm) {
  num_loads++;
  
  // load program mem command is 0b00000010 and load data mem is 0b00000011
  uint8_t command = 0x02;
  if (!progm) {
    command++;
  }
  
  // send command
  for (int i=0; i < 6; i++) {
    digitalWrite(PROGM_CLK, HIGH);
    digitalWrite(PROGM_DTA, command & 0x01);
    command = command >> 1;
    delayMicroseconds(2);
    digitalWrite(PROGM_CLK, LOW);
  }

  // send start bit (0)
  digitalWrite(PROGM_CLK, HIGH);
  digitalWrite(PROGM_DTA, LOW);
  delayMicroseconds(2);
  digitalWrite(PROGM_CLK, LOW);

  // send first 14 bits of data
  for (int i=0; i < 14; i++) {
    digitalWrite(PROGM_CLK, HIGH);
    digitalWrite(PROGM_DTA, data & 0x0001);
    data = data >> 1;
    delayMicroseconds(2);
    digitalWrite(PROGM_CLK, LOW);
  }

  // send stop bit (0)
  digitalWrite(PROGM_CLK, HIGH);
  digitalWrite(PROGM_DTA, LOW);
  delayMicroseconds(2);
  digitalWrite(PROGM_CLK, LOW);
}

void increment_address() {
  uint8_t command = 0x04;
  
  // send command
  for (int i=0; i < 6; i++) {
    digitalWrite(PROGM_CLK, HIGH);
    digitalWrite(PROGM_DTA, command & 0x01);
    command = command >> 1;
    delayMicroseconds(2);
    digitalWrite(PROGM_CLK, LOW);
  }
}

void begin_erase_program() {
  uint8_t command = 0x08;
  
  // send command
  for (int i=0; i < 6; i++) {
    digitalWrite(PROGM_CLK, HIGH);
    digitalWrite(PROGM_DTA, command & 0x01);
    command = command >> 1;
    delayMicroseconds(2);
    digitalWrite(PROGM_CLK, LOW);
  } 

  // delay while process is complete 
  delay(10);
}
