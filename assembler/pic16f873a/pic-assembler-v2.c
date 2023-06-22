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
// current line
int line_num = 1;
// buffer used to store line
char* line = NULL;
unsigned long line_length = 0;

// is the size of the file set and what size
bool size_set = false;
int f_size = 0;

// current opcode
uint16_t opcode = 0;


/* parses the command line arguments and sets the appropriate flags
 *
 * also opens the correct files and allocates any needed memory */
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
void handle_org(char* loc);

/* handles all necessary changes when encountering .const 
 *
 * this includes creating a variable with the right value */
void handle_const(char* var, char* val);

/* handles all necessary changes when encountering .label 
 * 
 * this includes creating a constant that has the same value as the current
 * location in the write file */
void handle_label(char* lab);

/* handles all necessary changes when encountering an instruction
 *
 * this includes forming the opcode, and writing it to the file */
void handle_instruction(char* instr);

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
  do {
    int rc = getline(&line, &line_length, f_read);
    line_num++;
    if (rc < 0) break; // error or EOF, both handled outside loop
   
    // parse the line just read in
    parse_line();

  } while (true);
  
  // check for errors in read file
  if (ferror(f_read) != 0) {
    perror("ERROR: input file read failure\n");
    exit_safely(EXIT_FAILURE);
  } 

  exit_safely(EXIT_SUCCESS);
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
  
  // open files
  f_read = fopen(input_file, "r"); // read mode
  f_write = fopen(output_file, "wb"); // binary write mode
  if (f_read == NULL || f_write == NULL) {
    perror("fopen() failed\n");
    exit(EXIT_FAILURE);
  }

  // allocate necessary memory
  line = (char*)calloc(150, sizeof(char));
  line_length = 150;
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
  // remove all comments from line
  for (int i=0; i < strlen(line); i++) {
    if (line[i] == ';') line[i] = '\0';
  }
  
  char* first = strtok(line, " ");
  if (first == NULL) return; // line is empty
  
  // .org, .const, or .label
  if (first[0] == '.') {
    // get next two potential arguments
    char* second = strtok(NULL, " ");
    char* third = strtok(NULL, "\n");

    if ( strcmp(first, ".org") == 0 ) {
      handle_org(second);
    } else if ( strcmp(first, ".const") == 0 ) {
      handle_const(second, third);
    } else if ( strcmp(first, ".label") == 0 ) {
      handle_label(second);
    } else {
      fprintf(stderr, "ERROR: Line %d; unrecognized command %s\n", line_num, first);
      exit_safely(EXIT_FAILURE);
    }

  // instruction
  } else {
    handle_instruction(first);
  }
}

void handle_org(char* loc) {
  // try converting straight to number
  int x = char_to_num(loc);
  // try finding variable
  int i = get_var(loc);
  // if neither number nor variable, error
  if (x < 0 && i < 0) {
    fprintf(stderr, "ERROR: Line %d; .org expects number argument\n", line_num);
    exit_safely(EXIT_FAILURE);
  }
  
  // if variable, get value
  if (i > 0) {
    x = var_values[i];
  }
  
  // go to correct location
  if (fseek(f_write, x, SEEK_SET) < 0) {
    perror("fseek() to correct location failed\n");
    exit_safely(EXIT_FAILURE);
  }
}

void handle_const(char* var, char* val) {
  // TODO: Handle constants
}

void handle_label(char* lab) {
  if (get_var(lab) >= 0) {
    fprintf(stderr, "WARNING: Line %d; label overwriting value\n", line_num);
  }
  
  // get current location in file
  int x = ftell(f_write);
  if (x < 0) { // check for errors
    perror("ftell() to find location failed\n");
    exit_safely(EXIT_FAILURE);
  }

  // set label to value
  set_var(lab, x);
}

void handle_instruction(char* instr) {
  // get index of instruction 
  int index = get_instr(instr);
  if (index < 0) {
    fprintf(stderr, "ERROR: Line %d; instruction not recognized\n", line_num);
    exit_safely(EXIT_FAILURE);
  }

  // get args and remove whitespace
  char* arg1 = strtok(NULL, ",");
  if (arg1 != NULL) {
    while (isspace(arg1[0])) arg1++;
    while (isspace(arg1[strlen(arg1)-1])) arg1[strlen(arg1)-1] = '\0';
  }
  char* arg2 = strtok(NULL, "\n");
  if (arg2 != NULL) {
    while (isspace(arg2[0])) arg2++;
    while (isspace(arg2[strlen(arg2)-1])) arg2[strlen(arg2)-1] = '\0';
  }

  uint8_t instr_args = instruction_args[index];

  if ((instr_args & 0x80) != 0) { // <f> argument expected
    if (arg1 == NULL) {
      fprintf(stderr, "ERROR: Line %d; '%s' expects args\n", line_num, instr);
    }
    // TODO: Handle getting <f> arg



    if ((instr_args & 0x40) != 0) { // <d> argument expected
      if (arg2 == NULL) {
        fprintf(stderr, "ERROR: Line %d; '%s' expects args\n", line_num, instr);
      }
      // TODO: Handle getting <d> arg

    } else if ((instr_args & 0x20) != 0) { // <b> argument expected
      if (arg2 == NULL) {
        fprintf(stderr, "ERROR: Line %d; '%s' expects args\n", line_num, instr);
      }
      // TODO: Handle getting <b> arg

    }

  } else if ((instr_args & 0x10) != 0) { // <k> argument expected
    if (arg1 == NULL) {
      fprintf(stderr, "ERROR: Line %d; '%s' expects args\n", line_num, instr);
    }
    // TODO: Handle getting <k> arg
    


    // TODO: Handle properly setting <k> arg
    if ((instr_args & 0x08) != 0) { // <k> takes 11 bits instead of 8

    } else { // <k> only takes up 8 bits

    }
  
  }

  // TODO: write opcode to file
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
