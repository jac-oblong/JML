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
  if (Serial.available() > 0) {
    int inByte = Serial.read();

    Serial.print("recieved: ");
    Serial.println(inByte, BIN);
  }
}
