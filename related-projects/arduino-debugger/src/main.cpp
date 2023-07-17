#include "pins_arduino.h"
#include <Arduino.h>

const int CLK = 2;
const int WR = 3;
const int RD = 4;

const int ADDR0 = 22;
const int ADDR1 = 24;
const int ADDR2 = 26;
const int ADDR3 = 28;
const int ADDR4 = 30;
const int ADDR5 = 32;
const int ADDR6 = 34;
const int ADDR7 = 36;
const int ADDR8 = 38;
const int ADDR9 = 40;
const int ADDR10 = 42;
const int ADDR11 = 44;
const int ADDR12 = 46;
const int ADDR13 = 48;
const int ADDR14 = 50;
const int ADDR15 = 52;

const int DATA0 = 23;
const int DATA1 = 25;
const int DATA2 = 27;
const int DATA3 = 29;
const int DATA4 = 31;
const int DATA5 = 33;
const int DATA6 = 35;
const int DATA7 = 37;

uint8_t data_line;
uint16_t addr_line;
bool clk_line;
bool wr_line;
bool rd_line;

int isr_flag = 0;

void Interrupt();

void setup() {
  /* declare CLK, WR, RD */
  for (int i = 2; i < 5; i++) {
    pinMode(i, INPUT);
  }

  /* declare ADDR_ */
  for (int i = 22; i <= 52; i += 2) {
    pinMode(i, INPUT);
  }

  /* declare DATA_ */
  for (int i = 23; i <= 37; i += 2) {
    pinMode(i, INPUT);
  }

  /* add interrupt for CLK, RD and WR */
  attachInterrupt(digitalPinToInterrupt(CLK), Interrupt, RISING);
  attachInterrupt(digitalPinToInterrupt(RD), Interrupt, FALLING);
  attachInterrupt(digitalPinToInterrupt(WR), Interrupt, FALLING);

  Serial.begin(9600);
}

void loop() {
  if (isr_flag) {
    isr_flag = 0;
    char buffer[100];
    sprintf(buffer, "ADDR:%X\tDATA:%X\tCLK:%d\tWR:%d\tRD:%d", addr_line,
            data_line, (int)clk_line, (int)wr_line, (int)rd_line);
    Serial.println(buffer);
  }
}

void Interrupt() {
  clk_line = digitalRead(CLK);
  wr_line = digitalRead(WR);
  rd_line = digitalRead(RD);

  addr_line = 0;
  for (int i = 22; i <= 52; i += 2) {
    addr_line |= (digitalRead(i) & 0x0001) << ((i - 22) / 2);
  }

  data_line = 0;
  for (int i = 23; i <= 37; i += 2) {
    data_line |= (digitalRead(i) & 0x01) << ((i - 23) / 2);
  }

  isr_flag = 1;
}
