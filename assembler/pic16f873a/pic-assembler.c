#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>
#include <string.h>
#include <ctype.h>
#include <fcntl.h>


/*
 * reads a single line from the file specified 
 *
 * the contents of the line will be stored in 'buf', which is expected to be 
 * pointing to heap data so that it can be realloc'd to the proper size 
 *
 * returns 0 if file is ended, returns any other number otherwise
 */
int read_line(int fd, char* buf) {
  // read from file one byte at time
  int len = 0;
  int rc;
  do {
    buf = realloc(buf, len+1);
    rc = read(fd, buf + len, 1);
    if (rc < 0) {
      perror("ERROR: read() failed\n");
      exit(EXIT_FAILURE);
    }
    len++;
    
    if (buf[len] == '\n') break;
  } while (rc != 0);
  
  // add null char to end
  buf = realloc(buf, len+1);
  buf[len] = '\0';

  return rc;
}

/*
 * parses a single line of code and produces the expected opcode output
 *
 * if a change in location is necessary (.org for example) the new location will
 * be returned, otherwise 0 is returned
 */
unsigned int parse_line(char* line, int16_t opcode) {
  // TODO: parse input to create opcode output
}

int main(int argc, char** argv) {
  // default input/output conditions
  char* input_file;
  char* output_file = "a.bin";
  int num_words = 0;
  
  // get input options from command line arguments
  for (int i=1; i < argc; i++) {
    if ( strcmp(argv[i], "-o") == 0 ) {
      i++; // go to next argument
      output_file = argv[i];
      continue;

    } else if ( strcmp(argv[i], "-s") == 0 ) {
      i++; // go to next argument
      bool is_num;
      for (int j=0; j < strlen(argv[i]); j++) {
        if (!isdigit(argv[i][j])) is_num = false;
      }
      if (!is_num) {
        fprintf(stdout, "ERROR: illegal argument for option \"-s\": %s\n", argv[i+1]);
        return EXIT_FAILURE;
      }
      num_words = atoi(argv[i]);
      continue;

    } else {
      fprintf(stdout, "ERROR: unrecognized argument \"%s\"\n", argv[i]);
      return EXIT_FAILURE;
    }
  }


  // open input & output files
  int fd_read = open(input_file, O_RDONLY);
  if (fd_read < 0) {
    perror(NULL);
    fprintf(stdout, "ERROR: open() file %s failed\n", input_file);
    return EXIT_FAILURE;
  }
  int fd_write = open(output_file, O_CREAT | O_EXCL | O_WRONLY);
  if (fd_write < 0) {
    perror(NULL);
    fprintf(stdout, "ERROR: open() file %s failed\n", output_file);
    return EXIT_FAILURE;
  }


  // parse the input line by line and write to output buffer
  uint16_t* bin_file_buffer = (uint16_t*)calloc(num_words, sizeof(uint16_t));
  uint64_t cur_file_buf_loc = 0;
  int line_num = 1;
  char* line = (char*)calloc(10, sizeof(char));
  while (read_line(fd_read, line) != 0) {
    int16_t opcode;
    unsigned int rc = parse_line(line, opcode);
    if (rc != 0) cur_file_buf_loc = rc;
    if (cur_file_buf_loc >= num_words) {
      fprintf(stderr, "WARNING: attempted to write outside of file boundaries\n LINE NUMBER: %d", line_num);
      cur_file_buf_loc++;
      line_num++;
      continue;
    }
    bin_file_buffer[cur_file_buf_loc] = opcode;
    
    cur_file_buf_loc++;
    line_num++;
  }

  int rc = write(fd_write, bin_file_buffer, num_words*2);
  if (rc < 0) {
    perror("ERROR: failed to write to output file\n");
    return EXIT_FAILURE;
  }
  if (rc != num_words*2) {
    fprintf(stderr, "WARNING: failed to write entire buffer, %d bytes written.\n", rc);
    return EXIT_FAILURE;
  }


  close(fd_write);
  close(fd_read);

  return EXIT_SUCCESS;
}
