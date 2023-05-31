#include "pins_arduino.h"
#include <Arduino.h>


const int clkISR        = 20;
const int clkPin        = 22;
const int dataPin       = 24;
const int clkEnablePin  = 26;
const int dataEnablePin = 28;

/*
 * Want to send this message:
 *  01100111110
 *  00101111111
 *  00000000010
 *  00101111111
 *  01011011110
 *  00101111111
 *  00000000010
 *  00101111111
 *
 * Need to send top-left bit first
 */
const int message[] = {
  0,1,1,0,0,1,1,1,1,1,0,
  0,0,1,0,1,1,1,1,1,1,1,
  0,0,0,0,0,0,0,0,0,1,0,
  0,0,1,0,1,1,1,1,1,1,1,
  0,1,0,1,1,0,1,1,1,1,0,
  0,0,1,0,1,1,1,1,1,1,1,
  0,0,0,0,0,0,0,0,0,1,0,
  0,0,1,0,1,1,1,1,1,1,1,
  1 // final state we want data line to be in (tied high)
};
volatile int cur_bit = 0;
// need to recieve something from keyboard before sending message to make sure
// it is plugged in
volatile bool begin = false;
bool begun = false;

void Message_ISR();

void setup() {
  Serial.begin(9600);
  pinMode(clkPin, INPUT_PULLUP);
  pinMode(dataPin, INPUT_PULLUP);

  digitalWrite(clkEnablePin, LOW);
  digitalWrite(dataEnablePin, LOW);
  pinMode(clkEnablePin, OUTPUT);
  pinMode(dataEnablePin, OUTPUT);

  attachInterrupt(digitalPinToInterrupt(clkISR), Message_ISR, FALLING);
}

void loop() {
  if (begin && !begun) {
    begun = true;
    detachInterrupt(digitalPinToInterrupt(clkISR));
    Serial.println("starting");
    digitalWrite(clkEnablePin, HIGH);
    digitalWrite(dataEnablePin, HIGH);
    digitalWrite(clkEnablePin, LOW);
    attachInterrupt(digitalPinToInterrupt(clkISR), Message_ISR, FALLING);
  }
  if (cur_bit >= 89) {
    detachInterrupt(digitalPinToInterrupt(clkISR));
    Serial.println("done");
    cur_bit = 0;
  }
}

void Message_ISR() {
  if (!begin || !begun) {
    begin = true;
    return;
  }
  if (cur_bit % 22 == 21) {
    digitalWrite(clkEnablePin, HIGH);
  }
  cur_bit++;
  // need to flip bit as we are using a transistor to pull the line low
  digitalWrite(dataEnablePin, !message[cur_bit]);
  digitalWrite(clkEnablePin, LOW);
}
