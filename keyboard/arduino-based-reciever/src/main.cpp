#include "pins_arduino.h"
#include <Arduino.h>


const int clkPin        = 22;
const int dataPin       = 24;
const int clkEnablePin  = 26;
const int dataEnablePin = 28;

void setup() {
  pinMode(clkPin, INPUT_PULLUP);
  pinMode(dataPin, INPUT_PULLUP);

  digitalWrite(clkEnablePin, LOW);
  digitalWrite(dataEnablePin, LOW);
  pinMode(clkEnablePin, OUTPUT);
  pinMode(dataEnablePin, OUTPUT);
}

void loop() {
  digitalWrite(clkEnablePin, HIGH);
  delay(500);
  digitalWrite(dataEnablePin, HIGH);
  delay(500);
  digitalWrite(clkEnablePin, LOW);
  delay(500);
  digitalWrite(dataEnablePin, LOW);
  delay(500);
}
