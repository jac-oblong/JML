#include <Arduino.h>

const String begin_message[] = {
    "Please connect the RAM IC as shown below                                ",
    "MEGA PIN                         RAM IC                         MEGA PIN",
    "                         _____________________                          ",
    "P22 -------------------->|A0               D0|---------------------> P23",
    "P24 -------------------->|A1               D1|---------------------> P25",
    "P26 -------------------->|A2               D2|---------------------> P27",
    "P28 -------------------->|A3               D3|---------------------> P29",
    "P30 -------------------->|A4               D4|---------------------> P31",
    "P32 -------------------->|A5               D5|---------------------> P33",
    "P34 -------------------->|A6               D6|---------------------> P35",
    "P36 -------------------->|A7               D7|---------------------> P37",
    "P38 -------------------->|A8                 |                          ",
    "P40 -------------------->|A9                 |                          ",
    "P42 -------------------->|A10                |                          ",
    "P44 -------------------->|A11                |                          ",
    "P46 -------------------->|A12              WE|<--------------------- P47",
    "P48 -------------------->|A13              OE|<--------------------- P49",
    "P50 -------------------->|A14             CS1|<--------------------- P51",
    "P52 -------------------->|A15             CS2|<--------------------- P53",
    "                         ---------------------                         "};

bool WE_active_low = false, OE_active_low = false, CS1_active_low = false,
     CS2_active_low = false;
int ram_size = 0;

void write_all_ones();
void write_all_zeros();
void write_address();

void setup() {
  Serial.begin(9600);

  delay(500);

  for (int i = 0; i < 20; i++) {
    Serial.println(begin_message[i]);
  }

  Serial.print("How large is the RAM IC in bytes? ");
  while (Serial.available() == 0) {
  }
  ram_size = Serial.parseInt();
  Serial.println(ram_size);

  Serial.print("Is WE active low? (y/n) : ");
  while (Serial.available() == 0) {
  }
  WE_active_low = (((char)Serial.read()) == 'y');

  Serial.print("Is OE active low? (y/n) : ");
  while (Serial.available() == 0) {
  }
  OE_active_low = (((char)Serial.read()) == 'y');

  Serial.print("Is CS1 active low? (y/n) : ");
  while (Serial.available() == 0) {
  }
  CS1_active_low = (((char)Serial.read()) == 'y');

  Serial.print("Is CS2 active low? (y/n) : ");
  while (Serial.available() == 0) {
  }
  CS2_active_low = (((char)Serial.read()) == 'y');
}

void loop() {}

void write_all_ones() {}
void write_all_zeros() {}
void write_address() {}
