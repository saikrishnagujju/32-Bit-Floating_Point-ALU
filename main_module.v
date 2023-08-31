`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.12.2021 23:06:25
// Design Name: 
// Module Name: main_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

/********************/
/* Code for Control */
/********************/
module main_module(
    input clk,
    input [7:0] x,              //x is 8-bit signed input
    input [3:0] sel,            //sel is for selecting function
    output reg [31:0] answer    //answer stores the result in IEEE-754 format
    );

    // Additional registers for convinience
    reg [31:0] conv, num, denom, conv2,p,q;
    reg [7:0] i;
    
    /****************/
    /* Code for FPU */
    /****************/
    
    /***** covert *****/
    function [31:0] convert;
        input [7:0] x;
        input clock;
        reg [7:0] temp;
        reg [31:0] float;
        integer i,j,k;
        begin
            float = 32'b0;
            temp = x;
            float[31] = x[7];
            if(float[31] == 1'b1) begin
                temp = (~x) + 1 ;
            end
            j = -1;
            for(i =7; i>=0; i = i-1) begin
                if(temp[i] == 1 && j == -1)
                    j = i;
            end
            k = 22;
            {float[30:23]} = (j>=0) ? j+127: 8'b0;
            for(i = j-1; i>=0; i = i-1) begin
                float[k] = temp[i];
                k = k-1;
            end
            convert = float;
        end
    endfunction
    
    /***** divide *****/
    function [31:0] divide;
        input [31:0] A, B;
        input clock;
        // Registers to store the signbit, exponent and mantissa
        reg signA, signB, signRes;
        reg [7:0] expoA, expoB, expoRes;
        reg [23:0] mantissaA, mantissaB, mantissaRes;
        
        // Additional registers for convinience
        reg [7:0] diff, i;
        reg [24:0] tempResult, rem;
        reg [47:0] tempResult2;
        integer x,y;
        begin
            // Seperating sign, exponent and mantissa of A and B
            signA = A[31]; 
            signB = B[31];
            expoA = {A[30:23]};
            expoB = {B[30:23]};
            mantissaA = {1'b1, A[22:0]};
            mantissaB = {1'b1, B[22:0]};
            i = 0;
            
            // Find signbit, exponent and mantissa
            signRes = signA^signB;
            expoRes = expoA - expoB + 127;    
            
            // Division
            y = -1;
            tempResult = mantissaA/mantissaB;
            tempResult2 = (mantissaA%mantissaB)*2;
            for(x=24; x>=0; x = x-1) begin
                if (tempResult[x] == 1'b1 && y == -1)
                    y = x;
            end
            
            x = y;
            expoRes = expoRes + x - 1;
            
            for(y = x+1; y<=24; y = y+1) begin
                tempResult = tempResult << 1;
                if(tempResult2 == 0) begin end
                    
                else if(tempResult2 < mantissaB)
                    tempResult2 = tempResult2*2;
                else begin
                    tempResult[0] = 1;
                    tempResult2 = (tempResult2 - mantissaB)*2;
                end
            end
            
            //Normalize
            i = 0;
            if(tempResult != 25'b0) begin
                while (tempResult[24] != 1'b1) begin
                    tempResult = tempResult << 1;
                    i = i+1;
                end
                expoRes = expoRes - (i-1);
            end
            else begin
                expoRes = 0;
            end               
            
            // store the result
            divide = {signRes, expoRes, tempResult[23:1]};
        end
    endfunction
    
    /***** multiply *****/
    function [31:0] multiply;
        input [31:0] A, B;
        input clock;
        // Registers to store the signbit, exponent and mantissa
        reg signA, signB, signRes;
        reg [7:0] expoA, expoB, expoRes;
        reg [23:0] mantissaA, mantissaB, mantissaRes;
        
        // Additional registers for convinience
        reg [7:0] diff, i;
        reg [47:0] tempResult2;
        integer x,y;
        begin
            // Seperating sign, exponent and mantissa of A and B
            signA = A[31]; 
            signB = B[31];
            expoA = {A[30:23]};
            expoB = {B[30:23]};
            mantissaA = {1'b1, A[22:0]};
            mantissaB = {1'b1, B[22:0]};
            i = 0;

            // Find signbit, exponent and mantissa
            signRes = signA^signB;
            expoRes = expoA + expoB - 127;
            tempResult2 = mantissaA*mantissaB;
            
            //revise exponent
            if(tempResult2[47] == 1'b1) 
                expoRes = expoRes+1;
            
            //Normalize
            if(tempResult2 != 0) begin
                while (tempResult2[50] != 1'b1) begin
                    tempResult2 = tempResult2 << 1;
                end
            end
            else begin
                expoRes = 0;
            end              
            // store the result
            multiply = {signRes, expoRes, tempResult2[46:24]};
        end
    endfunction
    
    /***** add *****/
    function [31:0] add;
        input [31:0] A, B;
        input clock;
        // Registers to store the signbit, exponent and mantissa
        reg signA, signB, signRes;
        reg [7:0] expoA, expoB, expoRes;
        reg [23:0] mantissaA, mantissaB, mantissaRes;
        
        // Additional registers for convinience
        reg [7:0] diff, i;
        reg [24:0] tempResult, rem;
        reg [47:0] tempResult2;
        integer x,y;
        begin
            // Seperating sign, exponent and mantissa of A and B
            signA = A[31]; 
            signB = B[31];
            expoA = {A[30:23]};
            expoB = {B[30:23]};
            mantissaA = {1'b1, A[22:0]};
            mantissaB = {1'b1, B[22:0]};
            i = 0;

            // Do shifting
            if(expoA > expoB) begin
                diff = expoA - expoB;
                mantissaB = mantissaB >> diff;
                expoRes = expoA;
            end
            else begin
                diff = expoB - expoA;
                mantissaA = mantissaA >> diff;
                expoRes = expoB;
            end
            
            // Add the mantissa
            if (signA == 0 && signB == 0) begin
                tempResult = mantissaA + mantissaB;
                signRes = 1'b0;
            end
            else if (signA == 0 && signB == 1) begin
                tempResult = mantissaA > mantissaB ? mantissaA - mantissaB: mantissaB - mantissaA;
                signRes = mantissaA > mantissaB ? 1'b0: 1'b1;
            end
            else if (signA == 1 && signB == 0) begin
                tempResult = mantissaA > mantissaB ? mantissaA - mantissaB: mantissaB - mantissaA;
                signRes = mantissaA > mantissaB ? 1'b1: 1'b0;
            end
            else begin
                tempResult = mantissaA + mantissaB;
                signRes = 1'b0;
            end                                          
            
            //Normalize
            if(tempResult != 25'b0) begin
                while (tempResult[24] != 1'b1) begin
                    tempResult = tempResult << 1;
                    i = i+1;
                end
                expoRes = expoRes - (i-1);
            end
            else begin
                expoRes = 0;
            end
            
            // store the result
            add = {signRes, expoRes, tempResult[23:1]};
        end
    endfunction
    
    /***** sub *****/
    function [31:0] sub;
        input [31:0] A, B;
        input clock;
        // Registers to store the signbit, exponent and mantissa
        reg signA, signB, signRes;
        reg [7:0] expoA, expoB, expoRes;
        reg [23:0] mantissaA, mantissaB, mantissaRes;
        
        // Additional registers for convinience
        reg [7:0] diff, i;
        reg [24:0] tempResult, rem;
        reg [47:0] tempResult2;
        integer x,y;
        begin
            // Seperating sign, exponent and mantissa of A and B
            signA = A[31]; 
            signB = B[31];
            expoA = {A[30:23]};
            expoB = {B[30:23]};
            mantissaA = {1'b1, A[22:0]};
            mantissaB = {1'b1, B[22:0]};
            i = 0;

            // Do shifting
            if(expoA > expoB) begin
                diff = expoA - expoB;
                mantissaB = mantissaB >> diff;
                expoRes = expoA;
            end
            else begin
                diff = expoB - expoA;
                mantissaA = mantissaA >> diff;
                expoRes = expoB;
            end
            
            // Subtract the mantissa
            if (signA == 0 && signB == 0) begin
                tempResult = mantissaA > mantissaB ? mantissaA - mantissaB: mantissaB - mantissaA;
                signRes = mantissaA > mantissaB ? 1'b0: 1'b1;                
            end
            else if (signA == 0 && signB == 1) begin
                tempResult = mantissaA + mantissaB;
                signRes = 1'b0;
            end
            else if (signA == 1 && signB == 0) begin
                tempResult = mantissaA + mantissaB;
                signRes = 1'b0;                
            end
            else begin
                tempResult = mantissaA > mantissaB ? mantissaA - mantissaB: mantissaB - mantissaA;
                signRes = mantissaA > mantissaB ? 1'b1: 1'b0;
            end                                          
            
            //Normalize
            if(tempResult != 25'b0) begin
                while (tempResult[24] != 1'b1) begin
                    tempResult = tempResult << 1;
                    i = i+1;
                end
                expoRes = expoRes - (i-1);
            end
            else begin
                expoRes = 0;
            end                
            
            // store the result
            sub = {signRes, expoRes, tempResult[23:1]}; 
        end
    endfunction
    
    parameter [3:0] f0 = 4'b0000,   //if select is 0000 then we 1 / x
                    f1 = 4'b0001,   //if select is 0001 then we sqrt(x)
                    f2 = 4'b0010,   //if select is 0010 then we e^-x
                    f3 = 4'b0011,   //if select is 0011 then we e^x    
                    f4 = 4'b0100,   //if select is 0100 then we ln(x)
                    f5 = 4'b0101,   //if select is 0101 then we 2^(x^2)
                    f6 = 4'b0110,   //if select is 0110 then we sinh(x)
                    f7 = 4'b0111,   //if select is 0111 then we cosh(x) 
                    f8 = 4'b1000;   //if select is 1000 then we tanh(x)                                                          
    
    /**************************/
    /* Implementing Functions */
    /**************************/
                        
    always @(x or sel) begin
    
        // convert input to IEEE-754 single precision format
        conv = convert(x,clk);
        conv2 = convert(x-1,clk);
    
        // Finding the value of function
        case(sel)
            f0: begin
               answer = divide(32'b00111111100000000000000000000000,conv,clk);
            end
            
            f1: begin
                // Square root using newton's method
                if(x <= 0)begin
                    answer = 32'b0;
                end
                else begin
                    p = conv;
                    for(i=8'b00000001; i<= 20; i = i+1) begin
                        q = divide(add(p, divide(conv, p, clk), clk), 32'b01000000000000000000000000000000,clk);
                        p = q;
                    end
                    answer = q;
                end
            end
            
            f2: begin
                num = conv;                                      //x
                denom =  32'b00111111100000000000000000000000;   //1
                p = 32'b00111111100000000000000000000000;   //1
                
                for(i=8'b00000001; i<= 15; i = i+1) begin
                    p = (i[0] == 1'b1) ? sub(p, divide(num, denom,clk),clk) :add(p, divide(num, denom,clk),clk) ;
                    num = multiply(num, conv,clk);
                    denom = multiply(denom, convert(i+1, clk),clk);
                end
                answer = p;
            end
            
            f3: begin
                num = conv;                                      //x
                denom =  32'b00111111100000000000000000000000;   //1
                p = 32'b00111111100000000000000000000000;   //1
                
                for(i=8'b00000001; i<= 15; i = i+1'b1) begin
                    p = add(p, divide(num, denom,clk),clk);
                    num = multiply(num, conv,clk);
                    denom = multiply(denom, convert(i+1,clk),clk);
                end
                answer = p;
            end
            
            f4: begin
                num = conv;                                      //x
                denom =  32'b00111111100000000000000000000000;   //1
                p = divide(num, denom,clk); 
                
                for(i=8'b00000001; i<= 15; i = i+1) begin
                    num = multiply(num, conv,clk);
                    denom = convert(i+1,clk);
                    p = (i[0] == 1'b1) ? sub(p, divide(num, denom,clk),clk) :add(p, divide(num, denom,clk),clk) ;
                end
                answer = p;
            end
            
            f5: begin
                num = multiply(conv, conv,clk);                       //x^2
                num = multiply(conv,32'b00111111001100010111001000011000,clk);  //ln(2)*x*x
                denom =  32'b00111111100000000000000000000000;   //1
                p = 32'b00111111100000000000000000000000;   //1
                
                for(i=8'b00000001; i<= 15; i = i+1'b1) begin
                    p = add(p, divide(num, denom,clk),clk);
                    num = multiply(num, conv,clk);
                    denom = multiply(denom, convert(i+1,clk),clk);
                end
                answer = p;
            end
            
            f6: begin
                num = conv;                                      //x
                denom =  32'b00111111100000000000000000000000;   //1
                p = 32'b00111111100000000000000000000000;   //1
                
                for(i=8'b00000001; i<= 15; i = i+1) begin
                    p = (i[0] == 1'b1) ? sub(p, divide(num, denom,clk),clk) :add(p, divide(num, denom,clk),clk) ;
                    num = multiply(num, conv,clk);
                    denom = multiply(denom, convert(i+1,clk),clk);
                end
                
                num = conv;                                      //x
                denom =  32'b00111111100000000000000000000000;   //1
                q = 32'b00111111100000000000000000000000;   //1
                
                for(i=8'b00000001; i<= 15; i = i+1'b1) begin
                    q = add(q, divide(num, denom,clk),clk);
                    num = multiply(num, conv,clk);
                    denom = multiply(denom, convert(i+1,clk),clk);
                end
                
                answer = divide(sub(p, q, clk), 32'b01000000000000000000000000000000, clk);
            end
            
            f7: begin
                num = conv;                                      //x
                denom =  32'b00111111100000000000000000000000;   //1
                p = 32'b00111111100000000000000000000000;   //1
                
                for(i=8'b00000001; i<= 15; i = i+1) begin
                    p = (i[0] == 1'b1) ? sub(p, divide(num, denom, clk), clk) :add(p, divide(num, denom, clk), clk) ;
                    num = multiply(num, conv, clk);
                    denom = multiply(denom, convert(i+1, clk), clk);
                end
                
                num = conv;                                      //x
                denom =  32'b00111111100000000000000000000000;   //1
                q = 32'b00111111100000000000000000000000;   //1
                
                for(i=8'b00000001; i<= 15; i = i+1'b1) begin
                    q = add(q, divide(num, denom, clk), clk);
                    num = multiply(num, conv, clk);
                    denom = multiply(denom, convert(i+1, clk), clk);
                end
                
                answer = divide(add(p, q, clk), 32'b01000000000000000000000000000000, clk);
            end
            
            f8: begin
                num = multiply(conv,2, clk);                           //2x
                denom =  32'b00111111100000000000000000000000;   //1
                p = 32'b00111111100000000000000000000000;   //1
                
                for(i=8'b00000001; i<= 15; i = i+1) begin
                    p = (i[0] == 1'b1) ? sub(p, divide(num, denom, clk), clk) :add(p, divide(num, denom, clk), clk) ;
                    num = multiply(num, conv, clk);
                    denom = multiply(denom, convert(i+1, clk), clk);
                end
                
                answer = divide(add(p,32'b00111111100000000000000000000000, clk), sub(p,32'b00111111100000000000000000000000, clk), clk);
            end
            
            default: begin
                answer = 32'b0;
            end
        endcase
    end
endmodule
