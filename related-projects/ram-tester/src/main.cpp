#include "Print.h"
#include <Arduino.h>

const String begin_message[] = {
    "Please connect the RAM IC as shown below                                ",
    "MEGA PIN                         RAM IC                         MEGA PIN",
    "                         _____________________                          ",
    "P22 -------------------->|A0               D0|<--------------------> P23",
    "P24 -------------------->|A1               D1|<--------------------> P25",
    "P26 -------------------->|A2               D2|<--------------------> P27",
    "P28 -------------------->|A3               D3|<--------------------> P29",
    "P30 -------------------->|A4               D4|<--------------------> P31",
    "P32 -------------------->|A5               D5|<--------------------> P33",
    "P34 -------------------->|A6               D6|<--------------------> P35",
    "P36 -------------------->|A7               D7|<--------------------> P37",
    "P38 -------------------->|A8                 |                          ",
    "P40 -------------------->|A9                 |                          ",
    "P42 -------------------->|A10                |                          ",
    "P44 -------------------->|A11                |                          ",
    "P46 -------------------->|A12              WE|<--------------------- P47",
    "P48 -------------------->|A13              OE|<--------------------- P49",
    "P50 -------------------->|A14             CS1|<--------------------- P51",
    "P52 -------------------->|A15             CS2|<--------------------- P53",
    "                         ---------------------                         "};
const int WE = 47;
const int OE = 49;
const int CS1 = 51, CS2 = 53;
bool WE_active_low = false, OE_active_low = false, CS1_active_low = false,
     CS2_active_low = false;
long ram_size = 0, word_size = 0;

void setup_pins(bool data_in);
void write_all_ones();
void write_all_zeros();
void write_address();
void set_addr(long mem);
void set_data(long data);
uint8_t get_data();

void setup() {
  Serial.begin(9600);

  delay(500);

  for (int i = 0; i < 20; i++) {
    Serial.println(begin_message[i]);
  }

  Serial.print("\nHow large is the RAM IC? (0 : 16, 1 : 1024, 2 : 2048, 3 : "
               "8192, 4 : 32768)");
  while (Serial.available() == 0) {
  }
  switch (Serial.read()) {
  case 0:
    ram_size = 16;
  case 1:
    ram_size = 1024;
  case 2:
    ram_size = 2048;
  case 3:
    ram_size = 8192;
  case 4:
    ram_size = 32768;
  default:
    ram_size = 0;
  }
  Serial.println(ram_size);

  Serial.print("\nHow many bits at each address? ");
  while (Serial.available() == 0) {
  }
  word_size = Serial.parseInt();
  Serial.println(ram_size);

  Serial.print("\nIs WE active low? (y/n) : ");
  while (Serial.available() == 0) {
  }
  WE_active_low = (((char)Serial.read()) == 'y');

  Serial.print("\nIs OE active low? (y/n) : ");
  while (Serial.available() == 0) {
  }
  OE_active_low = (((char)Serial.read()) == 'y');

  Serial.print("\nIs CS1 active low? (y/n) : ");
  while (Serial.available() == 0) {
  }
  CS1_active_low = (((char)Serial.read()) == 'y');

  Serial.print("\nIs CS2 active low? (y/n) : ");
  while (Serial.available() == 0) {
  }
  CS2_active_low = (((char)Serial.read()) == 'y');

  setup_pins(false);

  digitalWrite(CS1, !CS1_active_low);
  digitalWrite(CS2, !CS2_active_low);
  digitalWrite(WE, WE_active_low);
  digitalWrite(OE, OE_active_low);

  Serial.print("\nWriting all ones...");
  write_all_ones();
  Serial.println("Complete");
  Serial.println("Checking data...");
  setup_pins(true);
  uint8_t cmp_data = word_size == 8 ? 0b11111111 : 0b00001111;
  for (int i = 0; i < ram_size; i++) {
    set_addr(i);
    delay(2);
    uint8_t data = get_data();
    if (data != cmp_data) {
      Serial.print("ERROR: addr ");
      Serial.print(i, HEX);
      Serial.print(" expected ");
      Serial.print(cmp_data, HEX);
      Serial.print(" got ");
      Serial.println(data, HEX);
    }
  }
  Serial.println("Complete\n");
  setup_pins(false);

  Serial.print("Writing all zeros...");
  write_all_zeros();
  Serial.println("Complete");
  Serial.println("Checking data...");
  setup_pins(true);
  cmp_data = 0b00000000;
  for (int i = 0; i < ram_size; i++) {
    set_addr(i);
    delay(2);
    uint8_t data = get_data();
    if (data != cmp_data) {
      Serial.print("ERROR: addr ");
      Serial.print(i, HEX);
      Serial.print(" expected ");
      Serial.print(cmp_data, HEX);
      Serial.print(" got ");
      Serial.println(data, HEX);
    }
  }
  Serial.println("Complete\n");
  setup_pins(false);

  Serial.print("Writing address...");
  write_address();
  Serial.println("Complete");
  Serial.println("Checking data...");
  setup_pins(true);
  for (int i = 0; i < ram_size; i++) {
    set_addr(i);
    delay(2);
    uint8_t data = get_data();
    if (data != (uint8_t)i) {
      Serial.print("ERROR: addr ");
      Serial.print(i, HEX);
      Serial.print(" expected ");
      Serial.print((uint8_t)i, HEX);
      Serial.print(" got ");
      Serial.println(data, HEX);
    }
  }
  Serial.println("Complete\n");
  setup_pins(false);
}

void loop() {}

void setup_pins(bool data_in) {
  for (int i = 22; i <= 52; i += 2) {
    pinMode(i, OUTPUT);
  }
  for (int i = 23; i <= 37; i += 1) {
    if (data_in) {
      pinMode(i, INPUT);
    } else {
      pinMode(i, OUTPUT);
    }
  }

  pinMode(OE, OUTPUT);
  pinMode(WE, OUTPUT);
  pinMode(CS1, OUTPUT);
  pinMode(CS2, OUTPUT);
}

void write_all_ones() {
  uint8_t data = 0b11111111;
  for (int i = 0; i < ram_size; i++) {
    set_addr(i);
    set_data(data);
    delay(2);
    digitalWrite(WE, !WE_active_low);
    delay(2);
    digitalWrite(WE, WE_active_low);
    delay(2);
  }
}

void write_all_zeros() {
  uint8_t data = 0b00000000;
  for (int i = 0; i < ram_size; i++) {
    set_addr(i);
    set_data(data);
    delay(2);
    digitalWrite(WE, !WE_active_low);
    delay(2);
    digitalWrite(WE, WE_active_low);
    delay(2);
  }
}

void write_address() {
  for (int i = 0; i < ram_size; i++) {
    set_addr(i);
    set_data(i);
    delay(2);
    digitalWrite(WE, !WE_active_low);
    delay(2);
    digitalWrite(WE, WE_active_low);
    delay(2);
  }
}

void set_addr(long mem) {
  for (int i = 22; i <= 52; i += 2) {
    digitalWrite(i, mem & 1);
    mem = mem >> 1;
  }
}

void set_data(long data) {
  for (int i = 23; i <= 37; i += 2) {
    digitalWrite(i, data & 1);
    data = data >> 1;
  }
}

uint8_t get_data() {
  uint8_t data;
  for (int i = 23; i < 23 + word_size; i += 2) {
    data &= digitalRead(i);
    data = data << 1;
  }
  return data;
}
