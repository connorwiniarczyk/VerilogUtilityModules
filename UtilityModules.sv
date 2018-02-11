//Module Name:  LevelToPulse
//Project Name: Security Device
//Description:  Generates a 1 clock cycle long pulse on the rising edge of any given signal
module LevelToPulse(
        input logic clk, reset,
        input logic level,
        output logic pulse
    );
    
    typedef enum logic [1:0] {READY, ON, OFF} State;
    State currentState, nextState;
    
    always_ff @(posedge clk) begin
        if(reset)   currentState = READY;
        else        currentState = nextState;
    end
    
    always_comb begin
        case(currentState)
            READY:  if(level)   nextState = ON;
                    else        nextState = READY;
            ON:                 nextState = OFF;
            OFF:    if(~level)  nextState = READY;
                    else        nextState = OFF;
            default:    nextState = READY;
        endcase
    end
    
    assign pulse = (currentState == ON);
    
endmodule

//Module Name:  ButtonDebouncer
//Description:  TODO
//
//TODO: test module
module ButtonDebouncer(
        input logic clk, reset,
        input logic in,
        output logic out
    );

    parameter = TIMETOSTABLE = 1000; // the number of clock cycles that the input needs to remain stable for it to be considered valid

    logic input_history [1:0] // two registers to store the previous states of the input

    //synchronize input_history registers to clk signal
    always_ff @(posedge clk) begin
        input_history[0] <= in;
        input_history[1] <= input_history[0];
    end

    //increment the value of a binary counter every time these signals match
    logic [$clog2(TIMETOSTABLE) - 1:0] counterValue;
    BinaryCounter #(TIMETOSTABLE) counter(
        .clk(clk), .reset(reset | ~(input_history[0] == input_history[1])), 
        .enable(input_history[0] == input_history[1]), // We only want the counter to increase if these two numbers are the same
        .out(counterValue)
    );

    //if the value has remained stable for more than the specified time, count it as valid and change the output
    always_ff @(posedge clk) begin
        if(counterValue >= TIMETOSTABLE)    out = ~out;
    end

endmodule

//Module Name:  clkdiv
//Project Name: Security Device
//Description:  Divides a given clock signal down to a given frequency
module clkdiv(input logic clk, input logic reset, output logic sclk);
    parameter DIVFREQ = 1000;  // desired frequency in Hz (change as needed)
    parameter DIVBITS = 30;   // enough bits to divide 100MHz down to 1 Hz
    parameter CLKFREQ = 100_000_000;
    parameter DIVAMT = (CLKFREQ / DIVFREQ) / 2;

    logic [DIVBITS-1:0] q;

    always_ff @(posedge clk)
        if (reset) begin
            q <= 0;
            sclk <= 0;
        end
        else if (q == DIVAMT-1) begin
            q <= 0;
            sclk <= ~sclk;
        end
    else q <= q + 1;

endmodule // clkdiv

//Module Name:  BinaryCounter
//Project Name: Security Device
//Description:  Counts up in binary from 0 to some maximum value
module BinaryCounter(
        input logic clk, reset, // clk and reset
        input logic enable,     // the counter will only increment when this signal is high
        output logic [$clog2(MAXVAL) - 1 : 0] out
    );

    parameter MAXVAL = 10; // The value we want to count up to 

    logic [$clog2(MAXVAL):0] count; // register which stores the current count

    always_ff @(posedge clk, posedge reset) begin : proc_
        if(reset | count == MAXVAL) begin
            count <= 0;
        end else if(enable) begin
            count <= count + 1;
        end else begin
            count <= count;
        end
    end

    assign out = count;

endmodule

//Module Name:  BinaryPulseGenerator
//Project Name: Security Device
//Description:  Uses a BinaryCounter to generate a 1 clock cycle long pulse every n clock cycles
module BinaryPulseGenerator (
    input logic clk, reset,   // clk and reset
    output logic out         // output pulse
);

    parameter TIME = 10;

    logic [$clog2(TIME) - 1 : 0] count;

    BinaryCounter #(TIME) counter(clk, reset, count);

    assign out = (count == TIME - 1);

endmodule

//Module Name:  Decoder
//Description:  Converts an arbitrary wide binary signal into the 1-hot equivilant
//
//TODO: test module
module Decoder(
    input logic [INPUTWIDTH - 1 : 0] in,
    output logic [(2 ** INPUTWIDTH) - 1 : 0] out
);

    parameter INPUTWIDTH = 2;

    logic [(2 ** INPUTWIDTH) - 1 : 0] zero = 1;

    assign out = zero >> in;

endmodule

//Module Name:  sevenSegDec
//Project Name: Security Device
//Description:  Decodes a 4 bit hexadecimal value into a a seven bit signal that displays the corresponding value on a seven segment display
module sevenSegDec(
        input [3:0] d,
        output logic [6:0] seg
    );

    assign seg[6] = (~d[3] & ~d[2] & ~d[1]) | (~d[3] & d[2] & d[1] & d[0]);
    assign seg[5] = (~d[3] & ~d[2] & ~d[1] & d[0]) | (~d[3] & ~d[2] & d[1]) | (~d[3] & d[2] & d[1] & d[0]) | (d[3] & d[2] & ~d[1]);
    assign seg[4] = (~d[3] & d[0]) | (~d[3] & d[2] & ~d[1]) | (~d[1] & d[0]);
    assign seg[3] = ~d[2] & ~d[1] & d[0] | d[2] & d[1] & d[0] | d[2] & ~d[1] & ~d[0] | d[3] & ~d[2] & d[1] & ~d[0] | d[3] & d[2] & ~d[1]; 
    assign seg[2] = d[3] & d[2] | ~d[3] & ~d[2] & d[1] & ~d[0]; 
    assign seg[1] = d[3] & d[2] | d[2] & ~d[1] & d[0] | d[2] & d[1] & ~d[0] | d[3] & d[1] & d[0];
    assign seg[0] = d[3] & d[2] & ~d[1] | ~d[3] & ~d[2] & ~d[1] & d[0] | ~d[3] & d[2] & ~d[1] & ~d[0] | d[3] & ~d[2] & d[1] & d[0];            
                   
endmodule