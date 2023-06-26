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
// current instr to be programmed
uint16_t instr;
// number of bytes recieved through Serial
unsigned long num_bytes_recieved;


/* handles the leds and when they should be on, an led being on means
 * that the corresponding push-button will recieve an input */ 
void handle_leds();
/* erases the entire pic microcontroller */
void erase_pic();
/* programs the contents of `instr` to the pic */
void progm_instr();
/* programs `val` into the pic */
void progm_mem(uint8_t val);


void setup() {
  Serial.begin(9600);
  
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
    digitalWrite(PROGM_MAN, HIGH);
    delay(1);
    digitalWrite(MASTR_CLR, HIGH);
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

    if (num_bytes_recieved < 8192) { // still in instruction memory
      if (num_bytes_recieved % 2 == 1) {
        instr = inByte << 8;
      } else {
        inByte &= 0x000000FF;
        instr |= inByte;
        progm_instr();
      }

    } else { // now in regular memory
      progm_mem(inByte);
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
