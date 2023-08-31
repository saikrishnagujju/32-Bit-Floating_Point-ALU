`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.12.2021 22:37:09
// Design Name: 
// Module Name: fpu_and_alu
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

//Group Project!

//IEEE 754 Single Precision ALU (32-bits)
module fpu(clk, X, Y, outputcode, Output);
	input clk;
	input [31:0] X, Y;
	input [1:0] outputcode;
	output [31:0] Output;

	wire [31:0] Output;
	wire [7:0] x_exponent;
	wire [23:0] x_mantissa;
	wire [7:0] y_exponent;
	wire [23:0] y_mantissa;

	reg        output_sign;
	reg [7:0]  output_exponent;
	reg [24:0] output_mantissa;


	reg [31:0] adder_x_in;
	reg [31:0] adder_y_in;
	wire [31:0] adder_out;

	reg [31:0] multiplier_x_in;
	reg [31:0] multiplier_y_in;
	wire [31:0] multiplier_out;

	reg [31:0] divider_x_in;
	reg [31:0] divider_y_in;
	wire [31:0] divider_out;

	assign Output[31] = output_sign;
	assign Output[30:23] = output_exponent;
	assign Output[22:0] = output_mantissa[22:0];

	assign x_sign = X[31];
	assign x_exponent[7:0] = X[30:23];
	assign x_mantissa[23:0] = {1'b1, X[22:0]};

	assign y_sign = Y[31];
	assign y_exponent[7:0] = Y[30:23];
	assign y_mantissa[23:0] = {1'b1, Y[22:0]};

	assign ADD = !outputcode[1] & !outputcode[0];
	assign SUB = !outputcode[1] & outputcode[0];
	assign DIV = outputcode[1] & !outputcode[0];
	assign MUL = outputcode[1] & outputcode[0];

	adder A1
	(
		.a(adder_x_in),
		.b(adder_y_in),
		.out(adder_out)
	);

	multiplier M1
	(
		.a(multiplier_x_in),
		.b(multiplier_y_in),
		.out(multiplier_out)
	);

	divider D1
	(
		.a(divider_x_in),
		.b(divider_y_in),
		.out(divider_out)
	);

	always @ (posedge clk) begin
		if (ADD) begin
			//If x is NaN or y is zero return a
			if ((x_exponent == 255 && x_mantissa != 0) || (y_exponent == 0) && (y_mantissa == 0)) begin
				output_sign = x_sign;
				output_exponent = x_exponent;
				output_mantissa = x_mantissa;
			//If y is NaN or x is zero return y
			end else if ((y_exponent == 255 && y_mantissa != 0) || (x_exponent == 0) && (x_mantissa == 0)) begin
				output_sign = y_sign;
				output_exponent = y_exponent;
				output_mantissa = y_mantissa;
			//if x or y is inf return inf
			end else if ((x_exponent == 255) || (y_exponent == 255)) begin
				output_sign = x_sign ^ y_sign;
				output_exponent = 255;
				output_mantissa = 0;
			end else begin // Passed all corner cases
				adder_x_in = X;
				adder_y_in = Y;
				output_sign = adder_out[31];
				output_exponent = adder_out[30:23];
				output_mantissa = adder_out[22:0];
			end
		end else if (SUB) begin
			//If x is NaN or y is zero return a
			if ((x_exponent == 255 && x_mantissa != 0) || (y_exponent == 0) && (y_mantissa == 0)) begin
				output_sign = x_sign;
				output_exponent = x_exponent;
				output_mantissa = x_mantissa;
			//If y is NaN or x is zero return y
			end else if ((y_exponent == 255 && y_mantissa != 0) || (x_exponent == 0) && (x_mantissa == 0)) begin
				output_sign = y_sign;
				output_exponent = y_exponent;
				output_mantissa = y_mantissa;
			//if x or y is inf return inf
			end else if ((x_exponent == 255) || (y_exponent == 255)) begin
				output_sign = x_sign ^ y_sign;
				output_exponent = 255;
				output_mantissa = 0;
			end else begin // Passed all corner cases
				adder_x_in = X;
				adder_y_in = {~Y[31], Y[30:0]};
				output_sign = adder_out[31];
				output_exponent = adder_out[30:23];
				output_mantissa = adder_out[22:0];
			end
		end else if (DIV) begin
			divider_x_in = X;
			divider_y_in = Y;
			output_sign = divider_out[31];
			output_exponent = divider_out[30:23];
			output_mantissa = divider_out[22:0];
		end else begin //Multiplication
			//If x is NaN return NaN
			if (x_exponent == 255 && x_mantissa != 0) begin
				output_sign = x_sign;
				output_exponent = 255;
				output_mantissa = x_mantissa;
			//If y is NaN return NaN
			end else if (y_exponent == 255 && y_mantissa != 0) begin
				output_sign = y_sign;
				output_exponent = 255;
				output_mantissa = y_mantissa;
			//If x or y is 0 return 0
			end else if ((x_exponent == 0) && (x_mantissa == 0) || (y_exponent == 0) && (y_mantissa == 0)) begin
				output_sign = x_sign ^ y_sign;
				output_exponent = 0;
				output_mantissa = 0;
			//if x or y is inf return inf
			end else if ((x_exponent == 255) || (y_exponent == 255)) begin
				output_sign = x_sign;
				output_exponent = 255;
				output_mantissa = 0;
			end else begin // Passed all corner cases
				multiplier_x_in = X;
				multiplier_y_in = Y;
				output_sign = multiplier_out[31];
				output_exponent = multiplier_out[30:23];
				output_mantissa = multiplier_out[22:0];
			end
		end
	end
endmodule


module adder(a, b, out);
  input  [31:0] a, b;
  output [31:0] out;

  wire [31:0] out;
	reg a_sign;
	reg [7:0] a_exponent;
	reg [23:0] a_mantissa;
	reg b_sign;
	reg [7:0] b_exponent;
	reg [23:0] b_mantissa;

  reg o_sign;
  reg [7:0] o_exponent;
  reg [24:0] o_mantissa;

  reg [7:0] diff;
  reg [23:0] tmp_mantissa;
  reg [7:0] tmp_exponent;


  reg  [7:0] i_e;
  reg  [24:0] i_m;
  wire [7:0] o_e;
  wire [24:0] o_m;

  addition_normaliser norm1
  (
    .in_e(i_e),
    .in_m(i_m),
    .out_e(o_e),
    .out_m(o_m)
  );

  assign out[31] = o_sign;
  assign out[30:23] = o_exponent;
  assign out[22:0] = o_mantissa[22:0];

  always @ ( * ) begin
		a_sign = a[31];
		if(a[30:23] == 0) begin
			a_exponent = 8'b00000001;
			a_mantissa = {1'b0, a[22:0]};
		end else begin
			a_exponent = a[30:23];
			a_mantissa = {1'b1, a[22:0]};
		end
		b_sign = b[31];
		if(b[30:23] == 0) begin
			b_exponent = 8'b00000001;
			b_mantissa = {1'b0, b[22:0]};
		end else begin
			b_exponent = b[30:23];
			b_mantissa = {1'b1, b[22:0]};
		end
    if (a_exponent == b_exponent) begin // Equal exponents
      o_exponent = a_exponent;
      if (a_sign == b_sign) begin // Equal signs = add
        o_mantissa = a_mantissa + b_mantissa;
        //Signify to shift
        o_mantissa[24] = 1;
        o_sign = a_sign;
      end else begin // Opposite signs = subtract
        if(a_mantissa > b_mantissa) begin
          o_mantissa = a_mantissa - b_mantissa;
          o_sign = a_sign;
        end else begin
          o_mantissa = b_mantissa - a_mantissa;
          o_sign = b_sign;
        end
      end
    end else begin //Unequal exponents
      if (a_exponent > b_exponent) begin // A is bigger
        o_exponent = a_exponent;
        o_sign = a_sign;
				diff = a_exponent - b_exponent;
        tmp_mantissa = b_mantissa >> diff;
        if (a_sign == b_sign)
          o_mantissa = a_mantissa + tmp_mantissa;
        else
          	o_mantissa = a_mantissa - tmp_mantissa;
      end else if (a_exponent < b_exponent) begin // B is bigger
        o_exponent = b_exponent;
        o_sign = b_sign;
        diff = b_exponent - a_exponent;
        tmp_mantissa = a_mantissa >> diff;
        if (a_sign == b_sign) begin
          o_mantissa = b_mantissa + tmp_mantissa;
        end else begin
					o_mantissa = b_mantissa - tmp_mantissa;
        end
      end
    end
    if(o_mantissa[24] == 1) begin
      o_exponent = o_exponent + 1;
      o_mantissa = o_mantissa >> 1;
    end else if((o_mantissa[23] != 1) && (o_exponent != 0)) begin
      i_e = o_exponent;
      i_m = o_mantissa;
      o_exponent = o_e;
      o_mantissa = o_m;
    end
  end
endmodule

module multiplier(a, b, out);
  input  [31:0] a, b;
  output [31:0] out;

  wire [31:0] out;
	reg a_sign;
  reg [7:0] a_exponent;
  reg [23:0] a_mantissa;
	reg b_sign;
  reg [7:0] b_exponent;
  reg [23:0] b_mantissa;

  reg o_sign;
  reg [7:0] o_exponent;
  reg [24:0] o_mantissa;

	reg [47:0] product;

  assign out[31] = o_sign;
  assign out[30:23] = o_exponent;
  assign out[22:0] = o_mantissa[22:0];

	reg  [7:0] i_e;
	reg  [47:0] i_m;
	wire [7:0] o_e;
	wire [47:0] o_m;

	multiplication_normaliser norm1
	(
		.in_e(i_e),
		.in_m(i_m),
		.out_e(o_e),
		.out_m(o_m)
	);


  always @ ( * ) begin
		a_sign = a[31];
		if(a[30:23] == 0) begin
			a_exponent = 8'b00000001;
			a_mantissa = {1'b0, a[22:0]};
		end else begin
			a_exponent = a[30:23];
			a_mantissa = {1'b1, a[22:0]};
		end
		b_sign = b[31];
		if(b[30:23] == 0) begin
			b_exponent = 8'b00000001;
			b_mantissa = {1'b0, b[22:0]};
		end else begin
			b_exponent = b[30:23];
			b_mantissa = {1'b1, b[22:0]};
		end
    o_sign = a_sign ^ b_sign;
    o_exponent = a_exponent + b_exponent - 127;
    product = a_mantissa * b_mantissa;
		// Normalization
    if(product[47] == 1) begin
      o_exponent = o_exponent + 1;
      product = product >> 1;
    end else if((product[46] != 1) && (o_exponent != 0)) begin
      i_e = o_exponent;
      i_m = product;
      o_exponent = o_e;
      product = o_m;
    end
		o_mantissa = product[46:23];
	end
endmodule

module addition_normaliser(in_e, in_m, out_e, out_m);
  input [7:0] in_e;
  input [24:0] in_m;
  output [7:0] out_e;
  output [24:0] out_m;

  wire [7:0] in_e;
  wire [24:0] in_m;
  reg [7:0] out_e;
  reg [24:0] out_m;

  always @ ( * ) begin
		if (in_m[23:3] == 21'b000000000000000000001) begin
			out_e = in_e - 20;
			out_m = in_m << 20;
		end else if (in_m[23:4] == 20'b00000000000000000001) begin
			out_e = in_e - 19;
			out_m = in_m << 19;
		end else if (in_m[23:5] == 19'b0000000000000000001) begin
			out_e = in_e - 18;
			out_m = in_m << 18;
		end else if (in_m[23:6] == 18'b000000000000000001) begin
			out_e = in_e - 17;
			out_m = in_m << 17;
		end else if (in_m[23:7] == 17'b00000000000000001) begin
			out_e = in_e - 16;
			out_m = in_m << 16;
		end else if (in_m[23:8] == 16'b0000000000000001) begin
			out_e = in_e - 15;
			out_m = in_m << 15;
		end else if (in_m[23:9] == 15'b000000000000001) begin
			out_e = in_e - 14;
			out_m = in_m << 14;
		end else if (in_m[23:10] == 14'b00000000000001) begin
			out_e = in_e - 13;
			out_m = in_m << 13;
		end else if (in_m[23:11] == 13'b0000000000001) begin
			out_e = in_e - 12;
			out_m = in_m << 12;
		end else if (in_m[23:12] == 12'b000000000001) begin
			out_e = in_e - 11;
			out_m = in_m << 11;
		end else if (in_m[23:13] == 11'b00000000001) begin
			out_e = in_e - 10;
			out_m = in_m << 10;
		end else if (in_m[23:14] == 10'b0000000001) begin
			out_e = in_e - 9;
			out_m = in_m << 9;
		end else if (in_m[23:15] == 9'b000000001) begin
			out_e = in_e - 8;
			out_m = in_m << 8;
		end else if (in_m[23:16] == 8'b00000001) begin
			out_e = in_e - 7;
			out_m = in_m << 7;
		end else if (in_m[23:17] == 7'b0000001) begin
			out_e = in_e - 6;
			out_m = in_m << 6;
		end else if (in_m[23:18] == 6'b000001) begin
			out_e = in_e - 5;
			out_m = in_m << 5;
		end else if (in_m[23:19] == 5'b00001) begin
			out_e = in_e - 4;
			out_m = in_m << 4;
		end else if (in_m[23:20] == 4'b0001) begin
			out_e = in_e - 3;
			out_m = in_m << 3;
		end else if (in_m[23:21] == 3'b001) begin
			out_e = in_e - 2;
			out_m = in_m << 2;
		end else if (in_m[23:22] == 2'b01) begin
			out_e = in_e - 1;
			out_m = in_m << 1;
		end
  end
endmodule

module multiplication_normaliser(in_e, in_m, out_e, out_m);
  input [7:0] in_e;
  input [47:0] in_m;
  output [7:0] out_e;
  output [47:0] out_m;

  wire [7:0] in_e;
  wire [47:0] in_m;
  reg [7:0] out_e;
  reg [47:0] out_m;

  always @ ( * ) begin
	  if (in_m[46:41] == 6'b000001) begin
			out_e = in_e - 5;
			out_m = in_m << 5;
		end else if (in_m[46:42] == 5'b00001) begin
			out_e = in_e - 4;
			out_m = in_m << 4;
		end else if (in_m[46:43] == 4'b0001) begin
			out_e = in_e - 3;
			out_m = in_m << 3;
		end else if (in_m[46:44] == 3'b001) begin
			out_e = in_e - 2;
			out_m = in_m << 2;
		end else if (in_m[46:45] == 2'b01) begin
			out_e = in_e - 1;
			out_m = in_m << 1;
		end
  end
endmodule

module divider (a, b, out);
	input [31:0] a;
	input [31:0] b;
	output [31:0] out;

	wire [31:0] b_reciprocal;

	reciprocal recip
	(
		.in(b),
		.out(b_reciprocal)
	);

	multiplier mult
	(
		.a(a),
		.b(b_reciprocal),
		.out(out)
	);

endmodule

module reciprocal (in, out);
	input [31:0] in;

	output [31:0] out;

	assign out[31] = in[31];
	assign out[22:0] = N2[22:0];
	assign out[30:23] = (D==9'b100000000)? 9'h102 - in[30:23] : 9'h101 - in[30:23];

	wire [31:0] D;
	assign D = {1'b0, 8'h80, in[22:0]};

	wire [31:0] C1; //C1 = 48/17
	assign C1 = 32'h4034B4B5;
	wire [31:0] C2; //C2 = 32/17
	assign C2 = 32'h3FF0F0F1;
	wire [31:0] C3; //C3 = 2.0
	assign C3 = 32'h40000000;

	wire [31:0] N0;
	wire [31:0] N1;
	wire [31:0] N2;

	//Temporary connection wires
	wire [31:0] S0_2D_out;
	wire [31:0] S1_DN0_out;
	wire [31:0] S1_2min_DN0_out;
	wire [31:0] S2_DN1_out;
	wire [31:0] S2_2minDN1_out;

	wire [31:0] S0_N0_in;

	assign S0_N0_in = {~S0_2D_out[31], S0_2D_out[30:0]};

	//S0
	multiplier S0_2D
	(
		.a(C2),
		.b(D),
		.out(S0_2D_out)
	);

	adder S0_N0
	(
		.a(C1),
		.b(S0_N0_in),
		.out(N0)
	);

	//S1
	multiplier S1_DN0
	(
		.a(D),
		.b(N0),
		.out(S1_DN0_out)
	);

	adder S1_2minDN0
	(
		.a(C3),
		.b({~S1_DN0_out[31], S1_DN0_out[30:0]}),
		.out(S1_2min_DN0_out)
	);

	multiplier S1_N1
	(
		.a(N0),
		.b(S1_2min_DN0_out),
		.out(N1)
	);

	//S2
	multiplier S2_DN1
	(
		.a(D),
		.b(N1),
		.out(S2_DN1_out)
	);

	adder S2_2minDN1
	(
		.a(C3),
		.b({~S2_DN1_out[31], S2_DN1_out[30:0]}),
		.out(S2_2minDN1_out)
	);

	multiplier S2_N2
	(
		.a(N1),
		.b(S2_2minDN1_out),
		.out(N2)
	);

endmodule