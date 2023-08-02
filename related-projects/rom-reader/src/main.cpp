#include "HardwareSerial.h"
#include "Print.h"
#include "Stream.h"
#include <Arduino.h>

const String begin_message[] = {
    "Please connect the ROM IC as shown below                                ",
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
    "P46 -------------------->|A12                |                          ",
    "P48 -------------------->|A13                |                          ",
    "P50 -------------------->|A14              OE|<--------------------- P51",
    "P52 -------------------->|A15              CS|<--------------------- P53",
    "                         ---------------------                         "};
const int OE = 51;
const int CS = 53;
bool OE_active_low = false, CS_active_low = false;
long rom_size = 0;

void setup_pins();
void set_addr(long mem);
uint8_t get_data();

void setup() {
  Serial.begin(9600);

  delay(500);

  for (int i = 0; i < 20; i++) {
    Serial.println(begin_message[i]);
  }

  Serial.print(
      "\nHow large is the RAM IC? (0 : 4k, 1 : 8k, 2 : 16k, 3 : 32k, 4 : 64k)");
  while (Serial.available() == 0) {
  }
  switch ((char)Serial.read()) {
  case '0':
    rom_size = 4096;
    break;
  case '1':
    rom_size = 8192;
    break;
  case '2':
    rom_size = 16384;
    break;
  case '3':
    rom_size = 32768;
    break;
  case '4':
    rom_size = 65536;
    break;
  default:
    rom_size = 0;
  }
  Serial.println(rom_size);

  Serial.print("\nIs OE active low? (y/n) : ");
  while (Serial.available() == 0) {
  }
  OE_active_low = (((char)Serial.read()) == 'y');
  Serial.println(OE_active_low);

  Serial.print("\nIs CS active low? (y/n) : ");
  while (Serial.available() == 0) {
  }
  CS_active_low = (((char)Serial.read()) == 'y');
  Serial.println(CS_active_low);

  setup_pins();

  digitalWrite(CS, !CS_active_low);
  digitalWrite(OE, !OE_active_low);

  /*
   *
   *
   *
   *
   *
   *
   *
   * CONTINUE FROM HERE
   *
   *
   *
   *
   *
   *
   *
   */

  Serial.print("\nWriting all zeros...");
  write_all_zeros();
  Serial.println("Complete");
  Serial.println("Checking data...");
  change_data_dir(true);
  digitalWrite(WE, WE_active_low);
  digitalWrite(OE, !OE_active_low);
  uint8_t cmp_data = 0b00000000;
  for (int i = 0; i < rom_size; i++) {
    set_addr(i);
    delayMicroseconds(50);
    uint8_t data = (word_size == 4) ? get_data() & 0x0F : get_data();
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

  digitalWrite(OE, OE_active_low);

  Serial.print("Writing all ones...");
  write_all_ones();
  Serial.println("Complete");
  Serial.println("Checking data...");
  change_data_dir(true);
  digitalWrite(WE, WE_active_low);
  digitalWrite(OE, !OE_active_low);
  cmp_data = word_size == 8 ? 0b11111111 : 0b00001111;
  for (int i = 0; i < rom_size; i++) {
    set_addr(i);
    delayMicroseconds(50);
    uint8_t data = (word_size == 4) ? get_data() & 0x0F : get_data();
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

  digitalWrite(OE, OE_active_low);

  Serial.print("Writing 0xAA...");
  write_0xAA();
  Serial.println("Complete");
  Serial.println("Checking data...");
  change_data_dir(true);
  digitalWrite(WE, WE_active_low);
  digitalWrite(OE, !OE_active_low);
  cmp_data = 0b10101010;
  if (word_size == 4) {
    cmp_data &= 0x0F;
  }
  for (int i = 0; i < rom_size; i++) {
    set_addr(i);
    delayMicroseconds(50);
    uint8_t data = (word_size == 4) ? get_data() & 0x0F : get_data();
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

  digitalWrite(OE, OE_active_low);

  Serial.print("Writing 0x55...");
  write_0x55();
  Serial.println("Complete");
  Serial.println("Checking data...");
  change_data_dir(true);
  digitalWrite(WE, WE_active_low);
  digitalWrite(OE, !OE_active_low);
  cmp_data = 0b01010101;
  if (word_size == 4) {
    cmp_data &= 0x0F;
  }
  for (int i = 0; i < rom_size; i++) {
    set_addr(i);
    delayMicroseconds(50);
    uint8_t data = (word_size == 4) ? get_data() & 0x0F : get_data();
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

  digitalWrite(OE, OE_active_low);
}

void loop() {}

void setup_pins() {
  for (int i = 22; i <= 52; i += 2) {
    pinMode(i, OUTPUT);
  }
  for (int i = 23; i <= 37; i += 1) {
    pinMode(i, INPUT);
  }

  pinMode(OE, OUTPUT);
  pinMode(WE, OUTPUT);
  pinMode(CS1, OUTPUT);
  pinMode(CS2, OUTPUT);
}

void change_data_dir(bool input) {
  for (int i = 23; i <= 37; i += 2) {
    if (input) {
      pinMode(i, INPUT);
    } else {
      pinMode(i, OUTPUT);
    }
  }
}

void write_all_ones() {
  uint8_t data = 0b11111111;
  for (int i = 0; i < rom_size; i++) {
    set_addr(i);
    delayMicroseconds(50);
    digitalWrite(WE, !WE_active_low);
    delayMicroseconds(50);
    change_data_dir(false);
    set_data(data);
    delayMicroseconds(50);
    digitalWrite(WE, WE_active_low);
    delayMicroseconds(50);
    change_data_dir(true);
  }
}

void write_all_zeros() {
  uint8_t data = 0b00000000;
  for (int i = 0; i < rom_size; i++) {
    set_addr(i);
    delayMicroseconds(50);
    digitalWrite(WE, !WE_active_low);
    delayMicroseconds(50);
    change_data_dir(false);
    set_data(data);
    delayMicroseconds(50);
    digitalWrite(WE, WE_active_low);
    delayMicroseconds(50);
    change_data_dir(true);
  }
}

void write_0xAA() {
  uint8_t data = 0b10101010;
  for (int i = 0; i < rom_size; i++) {
    set_addr(i);
    delayMicroseconds(50);
    digitalWrite(WE, !WE_active_low);
    delayMicroseconds(50);
    change_data_dir(false);
    set_data(data);
    delayMicroseconds(50);
    digitalWrite(WE, WE_active_low);
    delayMicroseconds(50);
    change_data_dir(true);
    delayMicroseconds(50);
  }
}

void write_0x55() {
  uint8_t data = 0b01010101;
  for (int i = 0; i < rom_size; i++) {
    set_addr(i);
    delayMicroseconds(50);
    digitalWrite(WE, !WE_active_low);
    delayMicroseconds(50);
    change_data_dir(false);
    set_data(data);
    delayMicroseconds(50);
    digitalWrite(WE, WE_active_low);
    delayMicroseconds(50);
    change_data_dir(true);
  }
}

void set_addr(long mem) {
  for (int i = 22; i <= 52; i += 2) {
    digitalWrite(i, mem & 1);
    mem = mem >> 1;
  }
}

void set_data(uint8_t data) {
  uint8_t modData = data;
  for (int i = 23; i <= 37; i += 2) {
    if ((modData & 0x01) != 0) {
      digitalWrite(i, HIGH);
    } else {
      digitalWrite(i, LOW);
    }
    modData = modData >> 1;
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
