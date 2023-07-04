#include "USBAPI.h"
#include "pins_arduino.h"
#include <Arduino.h>


const int clkISR        = 21;
const int clkPin        = 22;
const int dataPin       = 24;
const int clkEnablePin  = 26;
const int dataEnablePin = 28;

// need to recieve something from keyboard before sending message to make sure
// it is plugged in
volatile bool begin = false;
bool begun = false;

volatile int pulses = 0;
volatile uint16_t data;
volatile int flag;


// initializes the keyboard to ps/2 protocol and read data from keyboard
void Keyboard_ISR();


void setup() {
  Serial.begin(9600);
  pinMode(clkPin, INPUT_PULLUP);
  pinMode(dataPin, INPUT_PULLUP);

  digitalWrite(clkEnablePin, LOW);
  digitalWrite(dataEnablePin, LOW);
  pinMode(clkEnablePin, OUTPUT);
  pinMode(dataEnablePin, OUTPUT);

  attachInterrupt(digitalPinToInterrupt(clkISR), Keyboard_ISR, FALLING);
}

void loop() {
  if (begin && !begun) {
    begun = true;
    Serial.println("starting");
    digitalWrite(clkEnablePin, HIGH);
    digitalWrite(dataEnablePin, HIGH);
    digitalWrite(clkEnablePin, LOW);
  }
  if (flag && pulses && pulses) {
    Serial.print("0x");
    Serial.print(data,HEX);
    Serial.println();
    flag = data = 0;
  }
}

void Keyboard_ISR() {
  int x = digitalRead(dataPin) ? 1 : 0;
  data = (data << 1) | x;
  pulses++;
  if (pulses == 11) {
    begin = true;
    flag = 1;
    pulses = 0;
  }
  digitalWrite(dataEnablePin, LOW);
}
