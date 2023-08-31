#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>

// reads contents of EEPROM into file
void read_to_file(char *filename, int serial_fd);
// write contents of file to EEPROM
void write_from_file(char *filename, int serial_fd);
// compares two string while ignoring case, 0 if equal, non-zero otherwise
int strcmpcaseins(char *str1, char *str2);
// reads entire line of user input into buf, buf should be dynamically allocated
// memory of size 256, and may be reallocated
void read_input(char **buf);

int main() {
  // prompt user for filename of serial port
  printf("Enter full path to file associated with Arduino serial port => ");

  // get user response
  char *filename = calloc(256, sizeof(char));
  if (!fgets(filename, 256, stdin)) {
    fprintf(stderr, "reading user input failed\n");
    free(filename);
    return EXIT_FAILURE;
  }
  // if full path not obtained, continue getting more
  while (filename[strlen(filename) - 1] != '\n') {
    filename = realloc(filename, strlen(filename) + 256);
    if (!fgets(filename + strlen(filename), 256, stdin)) {
      fprintf(stderr, "reading user input failed\n");
      free(filename);
      return EXIT_FAILURE;
    }
  }
  filename[strlen(filename) - 1] = '\0';

  // open user provided file
  int serial_port = open(filename, O_RDWR);
  if (serial_port < 0) {
    perror("open() failed on file");
    free(filename);
    return EXIT_FAILURE;
  }
  free(filename);

  // configuration
  struct termios tty;
  if (tcgetattr(serial_port, &tty) != 0) {
    perror("configuring connection failed (tcgetattr())");
    return EXIT_FAILURE;
  }
  // control modes
  tty.c_cflag &= ~PARENB;        // no parity bit
  tty.c_cflag &= ~CSTOPB;        // only one stop bit
  tty.c_cflag &= ~CSIZE;         // clear size bits
  tty.c_cflag |= CS8;            // 8 bits per byte
  tty.c_cflag &= ~CRTSCTS;       // Disable RTS/CTS
  tty.c_cflag |= CREAD | CLOCAL; // Turn on READ & ignore ctrl lines
  // local modes
  tty.c_lflag &= ~ICANON; // don't wait for new line to receive input
  tty.c_lflag &= ~ECHO;   // Disable echo
  tty.c_lflag &= ~ECHOE;  // Disable erasure
  tty.c_lflag &= ~ECHONL; // Disable new-line echo
  tty.c_lflag &= ~ISIG;   // Disable interpretation of INTR, QUIT and SUSP
  // input modes
  tty.c_iflag &= ~(IXON | IXOFF | IXANY); // Turn off s/w flow ctrl
  tty.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR |
                   ICRNL); // Disable any special handling of received bytes
  // output modes
  tty.c_oflag &= ~OPOST; // Prevent special interpretation of output bytes (e.g.
                         // newline chars)
  tty.c_oflag &= ~ONLCR; // Prevent conversion of newline to carriage
                         // return/line feed
  // VMIN and VTIME
  tty.c_cc[VTIME] = 10; // Wait for up to 1s (10 deciseconds), returning as soon
  tty.c_cc[VMIN] = 0;   // as any data is received.
  // baud rate
  cfsetispeed(&tty, B9600);
  cfsetospeed(&tty, B9600);

  // saving configuration and checking for errors
  if (tcsetattr(serial_port, TCSANOW, &tty) != 0) {
    perror("setting configuration failed");
    return EXIT_FAILURE;
  }

  // ensuring that Ardiuno is responsive, write any byte, should receive same
  // data with all bits flipped
  uint8_t msg = 0xAA;
  if (write(serial_port, &msg, sizeof(msg)) != 1) {
    perror("write() to serial port failed");
    return EXIT_FAILURE;
  }
  if (read(serial_port, &msg, sizeof(msg)) != 1) {
    perror("read() from serial port failed");
    return EXIT_FAILURE;
  }
  if (msg != 0x55) {
    fprintf(stderr,
            "connection with Arduino not confirmed, received wrong code");
    return EXIT_FAILURE;
  }

  printf("\n");
  while (1) {
    printf("> ");

    char buf[16];
    if (!fgets(buf, 16, stdin)) {
      fprintf(stderr, "reading user input failed\n");
      return EXIT_FAILURE;
    }

    if (strcmpcaseins(buf, "R\n")) {
      char *file = calloc(256, sizeof(char));
      read_input(&file);
      read_to_file(file, serial_port);
      free(file);

    } else if (strcmpcaseins(buf, "W\n")) {
      char *file = calloc(256, sizeof(char));
      read_input(&file);
      write_from_file(file, serial_port);
      free(file);

    } else if (strcmpcaseins(buf, "Q\n")) {
      break;

    } else {
      printf("Unrecognized command\n\n");
      fflush(stdin);
      continue;
    }
  }

  close(serial_port);
  return EXIT_SUCCESS;
}
