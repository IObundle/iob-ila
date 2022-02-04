// This file is included by the source generated by ilaGenerateSource.py
// It contains the static code that depends on the defines generated

#include "iob-ila.h"
#include "printf.h"

static inline char intToHex(int val){
    if(val <= 9)
        return '0' + val;
    else
        return 'A' + (val - 10);
}

static inline char* OutputHex(char* buffer,int value){
	int lw = intToHex(value % 16);
	int hw = intToHex(value / 16);

	(*buffer++) = hw;
	(*buffer++) = lw;

	return buffer;	
}

int ila_output_data_size(int number_samples){
    int size_per_line = number_samples * ILA_BYTE_SIZE + 1; // For new line
    int size = size_per_line * number_samples;

    return size;
}

void ila_output_data(char* buffer,int number_samples){
    union{char i8[4];int i32;} data;

    buffer[0] = '\0'; // For the cases where number_samples == 0

    for(int i = 0; i < number_samples; i++){
        for(int ii = ILA_DWORD_SIZE - 1; ii >= 0; ii--){
            data.i32 = ila_get_large_value(i,ii);
            buffer = OutputHex(buffer,data.i8[3]);
            buffer = OutputHex(buffer,data.i8[2]);
            buffer = OutputHex(buffer,data.i8[1]);
            buffer = OutputHex(buffer,data.i8[0]);
        }
        
        (*buffer++) = '\n';
    }
    *buffer = '\0';
}
