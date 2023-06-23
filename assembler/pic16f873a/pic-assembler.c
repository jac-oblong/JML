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
int line_num = 0;
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

/* converts an argument into its corresponding values
 *
 * handles both constants and number literals */
int16_t parse_instr_arg(char* arg);

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
  // if size specified, write to maximum to enforce it 
  if (size_set) {
    fseek(f_write, f_size*2-2, SEEK_SET);
    uint16_t temp = 0x0000;
    fwrite(&temp, sizeof(uint16_t), 1, f_write);
    fseek(f_write, 0, SEEK_SET);
  }
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
      i++; // go to next argument
      output_file = argv[i];
      continue;

    } else if ( strcmp(argv[i], "-s") == 0 ) {
      i++; // go to next argument
      size_set = true;
      f_size = char_to_num(argv[i]);
      continue;

    } else {
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

  // remove all whitespace from line in order to determine if empty
  char* line_cpy = line;
  while (isspace(line_cpy[0])) line_cpy++;
  while (isspace(line_cpy[strlen(line_cpy)-1])) line_cpy[strlen(line_cpy)-1] = '\0';
  if (strlen(line_cpy) == 0) return; // line is empty
  
  char* first = strtok(line, " ");
  
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
  // convert loc to value
  int x = parse_instr_arg(loc);

  // if neither number nor variable, error
  if (x < 0) {
    fprintf(stderr, "ERROR: Line %d; .org expects number argument\n", line_num);
    exit_safely(EXIT_FAILURE);
  }
  
  // go to correct location
  if (fseek(f_write, x, SEEK_SET) < 0) {
    perror("fseek() to correct location failed\n");
    exit_safely(EXIT_FAILURE);
  }
}

void handle_const(char* var, char* val) {
  if (var == NULL || val == NULL) {
    fprintf(stderr, "ERROR: Line %d; .const expects arguments\n", line_num);
    exit_safely(EXIT_FAILURE);
  }

  // remove whitespace from val (var's whitespace has already been removed)
  while (isspace(val[0])) val++;
  while (isspace(val[strlen(val)-1])) val[strlen(val)-1] = '\0';

  // make sure first character is alpha or underscore
  if (!(isalpha(var[0]) || var[0] == '_')) {
    fprintf(stderr, "ERROR: Line %d; constant must begin with alpha or '_'\n", line_num);
    exit_safely(EXIT_FAILURE); 
  }

  // handle var being an array
  if (var[strlen(var)-1] == ']') {
    // go to right after { in val 
    while (val[0] != '{' && strlen(val) != 0) val++;
    // check if '{' was not found
    if (strlen(val) == 0) {
      fprintf(stderr, "ERROR: Line %d; array expected, but '{' not found\n", line_num);
      exit_safely(EXIT_FAILURE);
    }
    val++;

    // remove '}' from end of val
    while (val[strlen(val)-1] != '}' && strlen(val) != 0) val[strlen(val)-1] = '\0';
    // check if '}' not found
    if (strlen(val) == 0) {
      fprintf(stderr, "ERROR: Line %d; array expected, but '}' not found\n", line_num);
      exit_safely(EXIT_FAILURE);
    }
    val[strlen(val)-1] = '\0';

    // remove '[' and ']' from var, this can be done by ending string at '['
    int i;
    for (i=0; i < strlen(var); i++) {
      if (var[i] == '[') var[i] = '\0';
    }
    // if i == strlen(var) then the '[' was not found
    if (i == strlen(var)) {
      fprintf(stderr, "ERROR: Line %d; array expected, but '[' not found\n", line_num);
      exit_safely(EXIT_FAILURE);
    }

    set_var_array(var, val);

  } else {
    // try to convert value to number
    int val_value = char_to_num(val);
    if (val_value < 0) {
      fprintf(stderr, "ERROR: Line %d; number value expected for .const\n", line_num);
      exit_safely(EXIT_FAILURE);
    }

    set_var(var, val_value);
  }
}

void handle_label(char* lab) {
  if (get_var(lab) >= 0) {
    fprintf(stderr, "WARNING: Line %d; label overwriting value\n", line_num);
  }
  
  // make sure first character is alpha or underscore
  if (!(isalpha(lab[0]) || lab[0] == '_')) {
    fprintf(stderr, "ERROR: Line %d; label must begin with alpha or '_'\n", line_num);
    exit_safely(EXIT_FAILURE); 
  }
  
  // get current location in file
  int x = ftell(f_write);
  if (x < 0) { // check for errors
    perror("ftell() to find location failed\n");
    exit_safely(EXIT_FAILURE);
  }
  
  /* divide location by 2 becuase computer is counting every byte, but pic 
   * counts every 2 bytes */
  x /= 2;

  // set label to value
  set_var(lab, x);
}

void handle_instruction(char* instr) {
  // remove trailing whitespace (could be a newline)
  while (isspace(instr[strlen(instr)-1])) instr[strlen(instr)-1] = '\0';

  // get index of instruction 
  int index = get_instr(instr);
  if (index < 0) {
    fprintf(stderr, "ERROR: Line %d; instruction '%s' not recognized\n", line_num, instr);
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
  opcode = instr_opcodes[index];

  if ((instr_args & 0x80) != 0) { // <f> argument expected
    if (arg1 == NULL) {
      fprintf(stderr, "ERROR: Line %d; '%s' expects args\n", line_num, instr);
    }
  
    // parse <f> instr
    int16_t f_val = parse_instr_arg(arg1);
    if (f_val < 0) {
      fprintf(stderr, "ERROR: Line %d; <f> argument unrecognized\n", line_num);
      exit_safely(EXIT_FAILURE);
    }

    // write <f> to opcode (first zero all irrelevent bits)
    f_val &= 0x007F; // 0b01111111
    opcode |= f_val;

    if ((instr_args & 0x40) != 0) { // <d> argument expected
      if (arg2 == NULL) {
        fprintf(stderr, "ERROR: Line %d; '%s' expects args\n", line_num, instr);
      }
      // parse <d> instr
      int16_t d_val = parse_instr_arg(arg2);
      if (d_val < 0) {
        fprintf(stderr, "ERROR: Line %d; <f> argument unrecognized\n", line_num);
        exit_safely(EXIT_FAILURE);
      }

      /* write <d> to opcode (first zero all irrelevent bits and shift to 
       * correct position) */
      d_val = ((uint16_t)d_val) << 7;
      d_val &= 0x0000080; // 0b0000000010000000
      opcode |= d_val;

    } else if ((instr_args & 0x20) != 0) { // <b> argument expected
      if (arg2 == NULL) {
        fprintf(stderr, "ERROR: Line %d; '%s' expects args\n", line_num, instr);
      }
      // parse <b> instr
      int16_t b_val = parse_instr_arg(arg2);
      if (b_val < 0) {
        fprintf(stderr, "ERROR: Line %d; <f> argument unrecognized\n", line_num);
        exit_safely(EXIT_FAILURE);
      }

      /* write <b> to opcode (first zero all irrelevent bits and shift to 
       * correct position) */
      b_val = ((uint16_t)b_val) << 7;
      b_val &= 0x0380; // 0b0000001110000000
      opcode |= b_val;

    }

  } else if ((instr_args & 0x10) != 0) { // <k> argument expected
    if (arg1 == NULL) {
      fprintf(stderr, "ERROR: Line %d; '%s' expects args\n", line_num, instr);
    }
    
    // parse <k> instr
    int16_t k_val = parse_instr_arg(arg1);
    if (k_val < 0) {
      fprintf(stderr, "ERROR: Line %d; <f> argument unrecognized\n", line_num);
      exit_safely(EXIT_FAILURE);
    }
    
    // zero all irrelevent bits of <k>
    if ((instr_args & 0x08) != 0) { // <k> takes 11 bits instead of 8
      k_val &= 0x07FF; // 0b0000011111111111
    } else { // <k> only takes up 8 bits
      k_val &= 0x00FF; // 0b0000000011111111
    }
    
    // write <k> to opcode
    opcode |= k_val;
  }
  
  // make sure not writing outside bounds of set size
  if (size_set && ftell(f_write) / 2 > f_size) {
    fprintf(stderr, "ERROR: Line %d; writing outside bounds of file\n", line_num);
    exit_safely(EXIT_FAILURE);
  }
  // write opcode to file
  fwrite(&opcode, sizeof(uint16_t), 1, f_write);
}

int16_t parse_instr_arg(char* arg) {
  // try converting to number
  int16_t val = char_to_num(arg);
  // check if variable
  int index = get_var(arg);
  if (val < 0 && index < 0) {
    return -1;
  }

  // if var, set value correctly
  if (index >= 0) {
    val = var_values[index];
  }

  return val;
}

int get_var(char* variable) { 
  // check input for any sort of junk
  if (isdigit(variable[0])) return -1; // first char cannot be digit
  int num_l_bracket = 0, num_r_bracket = 0;
  for (int i=0; i < strlen(variable); i++) {
    if (!isalpha(variable[i]) && !isdigit(variable[i])) {
      if (variable[i] == '[') {
        num_l_bracket++;
      } else if (variable[i] == ']') {
        num_r_bracket++;
      }
      // if char is '_' make sure next char is not underscore
      else if (variable[i] == '_') {
        if (variable[i+1] == '_') {
          return -1;
        }
        continue;
  
      // character not recognized
      } else {
        return -1;
      }
    }
  }
  // check for too many brackets
  if (num_l_bracket != num_r_bracket || num_l_bracket > 1) {
    fprintf(stderr, "ERROR: Line %d; brackets are not used correctly\n", line_num);
    exit_safely(EXIT_FAILURE);
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
    // replace [num] at end of variable with __num__
    working_buf[i] = '_';
    i++;
    char temp = '_';
    while (working_buf[i] != ']') {
      char x = working_buf[i];
      working_buf[i] = temp;
      temp = x;
      i++;
    }
    working_buf[i] = temp;
    working_buf[i+1] = '_';
    working_buf[i+2] = '_';
    working_buf[i+3] = '\0';
    // point to edited string
    variable = working_buf;
  }
  
  for (int i=0; i < num_vars; i++) {
    if ( strcmp(variable, variables[i]) == 0 ) {
      return i;
    }
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
    if (v == -1) {
      fprintf(stderr, "ERROR: Line: %d; value not recognized\n", line_num);
      exit_safely(EXIT_FAILURE);
    }
    
    int num_digits = 0, i_copy = i;
    while (i_copy != 0) {
      i_copy /= 10;
      num_digits++;
    }

    char buf[strlen(variable) + 5 + num_digits];
    sprintf(buf, "%s__%d__", variable, i);

    set_var(buf, v);

    i++;    
    next_value = strtok(NULL, ",");
  }
}

int char_to_num(char* num) {
  // buffer for errors
  char* err_buf;
  // convert num into a number and return that number
  long return_val;
  if (num[0] == '0' && (num[1] == 'x' || num[1] == 'X')) { // hex
    return_val = strtol(num+2, &err_buf, 16);
  } else if (num[0] == '0' && (num[1] == 'b' || num[1] == 'B')) { // binary
    return_val = strtol(num+2, &err_buf, 2);
  } else { // decimal
    return_val = strtol(num, &err_buf, 10);
  }
  
  // check for any errors
  if (strlen(err_buf) != 0) {
    return -1;
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
