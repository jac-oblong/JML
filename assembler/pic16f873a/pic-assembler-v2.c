#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <ctype.h>


// legal instructions
const char instructions[35][7] = {
  "addwf", "andwf", "clrf", "clrw", "comf", "decf", "decfsz", "incf", "incfsz", 
  "iorwf", "movf", "movwf", "nop", "rlf", "rrf", "subwf", "swapf", "xorwf", 
  "bcf", "bsf", "btfsc", "btfss", "addlw", "andlw", "call", "clrwdt", "goto", 
  "iorlw", "movlw", "retfie", "retlw", "return", "sleep", "sublw", "xorlw"
};
// opcode that corresponds with instruction
const uint16_t instr_opcodes[35] = {
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
 * <k-zero>   : how much of k to allow through; 0->8, 1->11
 * <x>        : do not care
 */
const uint8_t instruction_args[35] = {
  0xC0, 0xC0, 0x80, 0x00, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0x80, 0x00,
  0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xA0, 0xA0, 0xA0, 0xA0, 0x10, 0x10, 0x18, 0x00,
  0x18, 0x10, 0x10, 0x00, 0x10, 0x00, 0x00, 0x10, 0x10
};
// for variables and their values
char** variables = NULL;
uint16_t* var_values = NULL;
int num_vars = 0;

// file file descriptors
FILE* f_read = NULL;
FILE* f_write = NULL;
// buffer used to store line
char* line = NULL;

// is the size of the file set and what size
bool size_set = false;
int f_size = 0;

// current opcode
uint16_t opcode = 0;


/* parses the command line arguments and sets the appropriate flags
 *
 * also opens the correct files */
void parse_command_line_args(int argc, char** argv);

/* finds instruction index, returns -1 if not valid instruction */
int get_instr(char* instruction); 

/* parses a single line of code and produces the expected opcode output
 *
 * if a change in location is necessary (.org for example) the new location will
 * be returned, if no operation occurs, the number will be negative, otherwise 0
 * is returned */
void parse_line(); 

/* handles all necessary changes when encountering .org 
 *
 * this includes changing the current location in the write file */
void handle_org();

/* handles all necessary changes when encountering .const 
 *
 * this includes creating a variable with the right value */
void handle_const();

/* handles all necessary changes when encountering .label 
 * 
 * this includes creating a constant that has the same value as the current
 * location in the write file */
void handle_label();

/* handles all necessary changes when encountering an instruction
 *
 * this includes forming the opcode, and writing it to the file */
void handle_instruction();

/* this function will write the current opcode to the output file */
void write_to_file();

/* gets the index of a variable, returns -1 if it does not exist */ 
int get_var(char* variable);

/* sets the value of the variable, creates variable if it does not exist */ 
void set_var(char* variable, uint16_t value);

/* sets up a array of variables, expects the variable name without brackets, and
 * the entire list of values without '{' or '}' */
void set_var_array(char* variable, char* values);

/* converts a string number into the integer value, returns -1 if not number */
int char_to_num(char* num);

/* exits the program safely, deleting all allocated memory and closing files */ 
void exit_safely(int code);


int main(int argc, char** argv) {
  parse_command_line_args(argc, argv);
}

void parse_command_line_args(int argc, char** argv) {
  // default input/output conditions
  char* input_file = "in.s";
  char* output_file = "a.bin";

  if (argc < 2) {
    fprintf(stdout, "ERROR: input file name required\n");
    exit_safely(EXIT_FAILURE);
  }
  
  // get input options from command line arguments
  for (int i=1; i < argc; i++) {
    if ( strcmp(argv[i], "-o") == 0 ) {
      #ifdef DEBUG_MODE
      printf("changing output file\n");
      #endif
      i++; // go to next argument
      output_file = argv[i];
      continue;

    } else if ( strcmp(argv[i], "-s") == 0 ) {
      #ifdef DEBUG_MODE
      printf("changing output file size\n");
      #endif
      i++; // go to next argument
      size_set = true;
      f_size = char_to_num(argv[i]);
      continue;

    } else {
      #ifdef DEBUG_MODE
      printf("changing input file\n");
      #endif
      input_file = argv[i];
    }
  }

  f_read = fopen(input_file, "r"); // read mode
  f_write = fopen(output_file, "wb"); // binary write mode
  if (f_read == NULL || f_write == NULL) {
    perror("fopen() failed\n");
    exit(EXIT_FAILURE);
  }
}

int get_instr(char* instruction) {
  for (int i=0; i < 35; i++) {
    if ( strcmp(instruction, instructions[i]) == 0 ) {
      return i;
    }
  }
  return -1;
}

void parse_line() {
}

void handle_org() {

}

void handle_const() {

}

void handle_label() {

}

void handle_instruction() {

}

int get_var(char* variable) { 
  // check input for any sort of junk
  int num_l_bracket = 0, num_r_bracket = 0;
  for (int i=0; i < strlen(variable); i++) {
    if (!isalpha(variable[i])) {
      if (variable[i] == '[') {
        num_l_bracket++;
      } else if (variable[i] == ']') {
        num_r_bracket++;
      }
      // if char is '_' make sure next char is not underscore
      else if (variable[i] == '_' && variable[i+1] == '_') {
        return -1;
      } else {
        return -1;
      }
    }
  }
  // is the variable an array
  char working_buf[strlen(variable)+3];
  if (variable[strlen(variable)-1] == ']') {
    strcpy(working_buf, variable);
    // find beginning bracket
    int i=0;
    while (working_buf[i] != '[' && i <= strlen(working_buf)) i++;
    if (i == strlen(working_buf)) {
      return -1;
    }
    // replace '[num]' at end of variable with __num__
    working_buf[i] = '_';
    i++;
    char temp = '_';
    while (working_buf[i] != ']') {
      char x = working_buf[i];
      working_buf[i] = temp;
      temp = x;
      i++;
    }
    working_buf[i] = '_';
    working_buf[i+1] = '_';
    working_buf[i+2] = '\0';
    // point to edited string
    variable = working_buf;
  }
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

void set_var_array(char* variable, char* values) {
  int i=0;
  char* next_value = strtok(values, ",");
  while (next_value != NULL) {
    // remove leading and trailing whitespace
    while (isspace(next_value[0])) next_value++;
    while (isspace(next_value[strlen(next_value)-1])) next_value[strlen(next_value)-1] = '\0';

    int v = char_to_num(next_value);
    if (v == -1) return;
    
    char buf[strlen(variable) + 4 + 3];
    sprintf(buf, "%s__%d__", variable, i);

    set_var(buf, v);
    
    next_value = strtok(NULL, ",");
  }
}

int char_to_num(char* num) {
  // check if numeric if not var
  for (int i=0; i < strlen(num); i++) {
    if (isdigit(num[i]) || 
        ((num[i] == 'x' || num[i] == 'X') && i == 1) || 
        ((num[i] == 'b' || num[i] == 'B') && i == 1)) {
      continue;
    }
    return -1;
  }

  // convert num into a number and return that number
  int return_val;
  if (num[0] == '0' && (num[1] == 'x' || num[1] == 'X')) { // hex
    return_val = strtol(num, NULL, 16);
  } else if (num[0] == '0' && (num[1] == 'b' || num[1] == 'B')) { // binary
    return_val = strtol(num, NULL, 2);
  } else { // decimal
    return_val = strtol(num, NULL, 10);
  }
  return return_val;
}

void exit_safely(int code) {
  for (int i=0; i < num_vars; i++) {
    free(variables[i]);
  }
  free(variables);
  free(var_values);
  free(line);

  fclose(f_read);
  fclose(f_write);

  exit(code);
}
