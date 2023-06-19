#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>
#include <string.h>
#include <ctype.h>
#include <fcntl.h>


// legal instructions
char instructions[35][7] = {
  "addwf", "andwf", "clrf", "comf", "decf", "decfsz", "incf", "incfsz", "iorwf",
  "movf", "movwf", "nop", "rlf", "rrf", "subwf", "swapf", "xorwf", "bcf", "bsf",
  "btfsc", "btfss", "addlw", "andlw", "call", "clrwdt", "goto", "iorlw", 
  "movlw", "retfie", "retlw", "return", "sleep", "sublw", "xorlw"
};
// opcode that corresponds with instruction
uint16_t opcode[35] = {
  0x0700, 0x0500, 0x0180, 0x0100, 0x0900, 0x0300, 0x0B00, 0x0A00, 0x0F00, 
  0x0400, 0x0800, 0x0080, 0x0000, 0x0D00, 0x0C00, 0x0200, 0x0E00, 0x0600, 
  0x1000, 0x1400, 0x1800, 0x1C00, 0x3E00, 0x3900, 0x2000, 0x0064, 0x2800, 
  0x3800, 0x3000, 0x0009, 0x3400, 0x0008, 0x0063, 0x3C00, 0x3A00
};
/* arguments of instruction; format: <f><d><b><k><k-shift><x><x><x>
 * 
 * <f>        : f argument expected
 * <d>        : d argument expected
 * <b>        : b argument expected
 * <k>        : k argument expected
 * <k-shift>  : how much to shift k; 0->8, 1->11
 * <x>        : do not care
 */
uint8_t instruction_args[35] = {
  0xC0, 0xC0, 0x80, 0x00, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0x80, 0x00,
  0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xA0, 0xA0, 0xA0, 0xA0, 0x10, 0x10, 0x18, 0x00,
  0x18, 0x10, 0x10, 0x00, 0x10, 0x00, 0x00, 0x10, 0x10
};
// for variables and their values
char** variables = NULL;
uint16_t* var_values = NULL;
int num_vars = 0;
bool var_continued = false; // used when a constant goes over multiple lines
// file file descriptors
int fd_read;
int fd_write;
// buffer used before writing to file
uint16_t* bin_file_buffer;
// buffer used to store line
char* line;


/* reads a single line from the file specified 
 *
 * the contents of the line will be stored in 'buf', which is expected to be 
 * pointing to heap data so that it can be realloc'd to the proper size, there
 * is no size requirement for 'buf'
 *
 * returns 0 if file is ended, returns any other number otherwise */
int read_line(int fd, char* buf); 

/* finds instruction index, returns -1 if not valid instruction */
int get_instr(char* instruction); 

/* parses a single line of code and produces the expected opcode output
 *
 * if a change in location is necessary (.org for example) the new location will
 * be returned, if no operation occurs, the number will be negative, otherwise 0
 * is returned */
int parse_line(char* line, uint16_t* opcode, uint64_t cur_loc, int line_num); 

/* gets the index of a variable, returns -1 if it does not exist */ 
int get_var(char* variable);

/* sets the value of the variable, creates variable if it does not exist */ 
void set_var(char* variable, uint16_t value);

/* exits the program safely, deleting all allocated memory and closing files */ 
void exit_safely(int code);


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
        exit_safely(EXIT_FAILURE);
      }
      num_words = atoi(argv[i]);
      continue;

    } else {
      fprintf(stdout, "ERROR: unrecognized argument \"%s\"\n", argv[i]);
      exit_safely(EXIT_FAILURE);
    }
  }


  // open input & output files
  int fd_read = open(input_file, O_RDONLY);
  if (fd_read < 0) {
    perror(NULL);
    fprintf(stdout, "ERROR: open() file %s failed\n", input_file);
    exit_safely(EXIT_FAILURE);
  }
  int fd_write = open(output_file, O_CREAT | O_EXCL | O_WRONLY);
  if (fd_write < 0) {
    perror(NULL);
    fprintf(stdout, "ERROR: open() file %s failed\n", output_file);
    exit_safely(EXIT_FAILURE);
  }

  // file buffer (used because we want to navigate to certian locations)
  bin_file_buffer = (uint16_t*)calloc(num_words, sizeof(uint16_t));
  // size of buffer
  uint64_t buf_size = num_words;
  // current location in buffer
  uint64_t cur_file_buf_loc = 0;
  int line_num = 1; // useful for errors
  line = (char*)calloc(10, sizeof(char));
  // parse the input line by line and write to output buffer 
  while (read_line(fd_read, line) != 0) {
    uint16_t opcode;
    int rc = parse_line(line, &opcode, cur_file_buf_loc, line_num);
    // change file location because used '.org'
    if (rc > 0) {
      cur_file_buf_loc = rc;       
      continue;
    }
    // no operation occurs (blank line or comment)
    if (rc < 0) {
      line_num++;
      continue;
    }
    // writing outside the bounds of the specified file size
    if (cur_file_buf_loc >= num_words && num_words != 0) {
      fprintf(stderr, "WARNING: attempted to write outside of file boundaries\n LINE NUMBER: %d", line_num);
      line_num++;
      continue;
    }
    // need to alloc more memory because no size specified
    if (num_words == 0 && cur_file_buf_loc >= buf_size) {
      bin_file_buffer = realloc(bin_file_buffer, (cur_file_buf_loc+1)*sizeof(uint16_t));
      for (; num_words < cur_file_buf_loc+1; num_words++) {
        bin_file_buffer[num_words-1] = 0x0000;
      }
    }
    // overwritting data
    if (bin_file_buffer[cur_file_buf_loc] != 0) {
      fprintf(stderr, "WARNING: potentially overwriting already written data on line %d\n", line_num);
    }
    // write opcode
    bin_file_buffer[cur_file_buf_loc] = opcode;
    
    cur_file_buf_loc++;
    line_num++;
  }

  int rc = write(fd_write, bin_file_buffer, num_words*2);
  if (rc < 0) {
    perror("ERROR: failed to write to output file\n");
    exit_safely(EXIT_FAILURE);
  }
  if (rc != num_words*2) {
    fprintf(stderr, "WARNING: failed to write entire buffer, %d bytes written.\n", rc);
    exit_safely(EXIT_FAILURE);
  }

  exit_safely(EXIT_SUCCESS);
}

int read_line(int fd, char* buf) {
  // read from file one byte at time
  int len = 0;
  int rc;
  do {
    buf = realloc(buf, len+1);
    rc = read(fd, buf + len, 1);
    if (rc < 0) {
      perror("ERROR: read() failed\n");
      exit_safely(EXIT_FAILURE);
    }
    len++;
    
    if (buf[len] == '\n') break;
  } while (rc != 0);
  
  // add null char to end
  buf = realloc(buf, len+1);
  buf[len] = '\0';

  return rc;
}

int get_instr(char* instruction) {
  for (int i=0; i < 35; i++) {
    if ( strcmp(instruction, instructions[i]) == 0 ) {
      return i;
    }
  }
  return -1;
}

int parse_line(char* line, uint16_t* opcode, uint64_t cur_loc, int line_num) {
  // remove leading whitespace
  while (isspace(line[0])) line++;

  // get first word, will say what to do with rest of line
  char* word1 = strtok(line, " ");
  if (word1 != NULL) {
    // if semicolon, make end of string
    for (int i=0; i < strlen(word1); i++) {
      if (word1[i] == ';') {
        word1[i] = '\0';
        break;
      }
    }
    // if length of string is zero, nothing to do anymore
    if (strlen(word1) == 0) return -1;
    
    // '.org', '.label' or '.const' command
    if (word1[0] == '.') {
      if (strcmp(word1, ".org") == 0) { // .org
        char* arg1 = strtok(NULL, " ");
        if (arg1 == NULL) {
          fprintf(stderr, "ERROR: Line %d; .org expects argument\n", line_num);
          exit_safely(EXIT_FAILURE);
        }
        // TODO: What if variable given instead of number
        for (int i=0; i < strlen(arg1); i++) {
          if (isdigit(arg1[i]) || 
              (arg1[i] == 'x' || arg1[i] == 'X') && i == 1 || 
              (arg1[i] == 'b' || arg1[i] == 'B') && i == 1) {
            continue;
          }
          fprintf(stderr, "ERROR: Line %d; .org expects number argument\n", line_num);
          exit_safely(EXIT_FAILURE);
        }
        // convert arg1 into a number and return that number
        int return_val;
        if (arg1[0] == '0' && (arg1[1] == 'x' || arg1[1] == 'X')) { // hex
          return_val = strtol(arg1, NULL, 16);
        } else if (arg1[0] == '0' && (arg1[1] == 'b' || arg1[1] == 'B')) { // binary
          return_val = strtol(arg1, NULL, 2);
        } else { // decimal
          return_val = strtol(arg1, NULL, 10);
        }
        // check for unused third command and warn about it 
        if (strtok(NULL, " ") != NULL) {
          fprintf(stderr, "WARNING: unused argument for .org on line %d\n", line_num);
        }

        return return_val;

      } else if (strcmp(word1, ".label") == 0) { // .label
        char* label = strtok(NULL, " ");
        if (label == NULL) {
          fprintf(stderr, "ERROR: Line %d; .label expects argument\n", line_num);
          exit_safely(EXIT_FAILURE);
        }
        if (get_var(label) != -1) { // overwriting another label
          fprintf(stderr, "WARNING: Line %d; overwriting label %s\n", line_num, label);
        }
        set_var(label, cur_loc);
        
        // check for unused third command and warn about it 
        if (strtok(NULL, " ") != NULL) {
          fprintf(stderr, "WARNING: unused argument for .label on line %d\n", line_num);
        }

        return -1; // no opcode given

      } else { // .const
        char* name = strtok(NULL, " ");
        if (name == NULL) {
          fprintf(stderr, "ERROR: Line %d; .const expects argument\n", line_num);
          exit_safely(EXIT_FAILURE);
        }
        char* value = strtok(NULL, " ");
        if (value == NULL) {
          fprintf(stderr, "ERROR: Line %d; .const expects argument\n", line_num);
          exit_safely(EXIT_FAILURE);
        }

        // TODO: what about if array of values
        
        for (int i=0; i < strlen(value); i++) {
          if (isdigit(value[i]) || 
              (value[i] == 'x' || value[i] == 'X') && i == 1 || 
              (value[i] == 'b' || value[i] == 'B') && i == 1) {
            continue;
          }
          fprintf(stderr, "ERROR: Line %d; .const expects number argument\n", line_num);
          exit_safely(EXIT_FAILURE);
        }
        // convert value into a number and return that number
        int num_val;
        if (value[0] == '0' && (value[1] == 'x' || value[1] == 'X')) { // hex
          num_val = strtol(value, NULL, 16);
        } else if (value[0] == '0' && (value[1] == 'b' || value[1] == 'B')) { // binary
          num_val = strtol(value, NULL, 2);
        } else { // decimal
          num_val = strtol(value, NULL, 10);
        }

        set_var(name, num_val);
        // check for unused third command and warn about it 
        if (strtok(NULL, " ") != NULL) {
          fprintf(stderr, "WARNING: unused argument for .const on line %d\n", line_num);
        }

        return -1; // no opcode given
      }

    // instruction
    } else {
      // TODO: implement instruction
    }

  } else { // the line was all whitespace
    return -1;
  }
  return 0;
}

int get_var(char* variable) {
  for (int i=0; i < num_vars; i++) {
    if ( strcmp(variable, variables[i]) == 0 ) return i;
  }
  return -1;
}

void set_var(char* variable, uint16_t value) {
  for (int i=0; i < num_vars; i++) {
    if ( strcmp(variable, variables[i]) == 0 ) {
      var_values[i] = value;
      return;
    }
  }
  num_vars++;
  variables = realloc(variables, num_vars*sizeof(char*));
  variables[num_vars-1] = (char*)calloc(strlen(variable)+1, sizeof(char));
  strcpy(variables[num_vars-1], variable);
  var_values = realloc(var_values, num_vars*sizeof(uint16_t));
  var_values[num_vars-1] = value;
}

void exit_safely(int code) {
  for (int i=0; i < num_vars; i++) {
    free(variables[i]);
  }
  free(variables);
  free(var_values);
  free(bin_file_buffer);
  free(line);

  close(fd_read);
  close(fd_write);

  exit(code);
}
