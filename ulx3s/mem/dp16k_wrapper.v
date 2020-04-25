module dp16k_wrapper_9bit #(parameter addr_width = 8) (
	input clock,
	input [addr_width-1:0] address_a = 0,
	input [8:0] data_a = 0,
	input enable_a = 1,
	input wren_a = 0,
	output [8:0] q_a,
	input cs_a = 1,
	input [addr_width-1:0] address_b = 0,
	input [8:0] data_b = 0,
	input enable_b = 1,
	input wren_b = 0,
	output [8:0] q_b,
	input cs_b = 1
);
`ifdef SIM
	reg [8:0] mem[0:2**addr_width-1];
	reg [8:0] q_a, q_b;
	initial begin :mem_init
		integer i;
		for (i = 0; i < 2**addr_width; i = i + 1'b1)
			mem[i] = 0;
	end
	always @(posedge clock) begin
		if (enable_a) begin
			if (cs_a && wren_a) mem[address_a] <= data_a;
			q_a <= mem[address_a];
		end
		if (enable_b) begin
			if (cs_b && wren_b) mem[address_b] <= data_b;
			q_b <= mem[address_b];
		end
	end
`else
	wire [10:0] A1ADDR = address_a;
	wire [10:0] B1ADDR = address_b;

	DP16KD #(
		.DATA_WIDTH_A(9),
		.DATA_WIDTH_B(9),
		.CLKAMUX("CLKA"),
		.CLKBMUX("CLKB"),
		.WRITEMODE_A("WRITETHROUGH"),
		.WRITEMODE_B("WRITETHROUGH"),
		.GSR("AUTO")
	) _TECHMAP_REPLACE_ (
		.ADA0(1'b0), .ADA1(1'b0), .ADA2(1'b0), .ADA3(A1ADDR[0]), .ADA4(A1ADDR[1]), .ADA5(A1ADDR[2]), .ADA6(A1ADDR[3]), .ADA7(A1ADDR[4]), .ADA8(A1ADDR[5]), .ADA9(A1ADDR[6]), .ADA10(A1ADDR[7]), .ADA11(A1ADDR[8]), .ADA12(A1ADDR[9]), .ADA13(A1ADDR[10]),
		.ADB0(1'b0), .ADB1(1'b0), .ADB2(1'b0), .ADB3(B1ADDR[0]), .ADB4(B1ADDR[1]), .ADB5(B1ADDR[2]), .ADB6(B1ADDR[3]), .ADB7(B1ADDR[4]), .ADB8(B1ADDR[5]), .ADB9(B1ADDR[6]), .ADB10(B1ADDR[7]), .ADB11(B1ADDR[8]), .ADB12(B1ADDR[9]), .ADB13(B1ADDR[10]),
		.DIA0(data_a[0]), .DIA1(data_a[1]), .DIA2(data_a[2]), .DIA3(data_a[3]), .DIA4(data_a[4]), .DIA5(data_a[5]), .DIA6(data_a[6]), .DIA7(data_a[7]), .DIA8(data_a[8]), .DIA9(1'b0), .DIA10(1'b0), .DIA11(1'b0), .DIA12(1'b0), .DIA13(1'b0), .DIA14(1'b0), .DIA15(1'b0), .DIA16(1'b0), .DIA17(1'b0),
		.DIB0(data_b[0]), .DIB1(data_b[1]), .DIB2(data_b[2]), .DIB3(data_b[3]), .DIB4(data_b[4]), .DIB5(data_b[5]), .DIB6(data_b[6]), .DIB7(data_b[7]), .DIB8(data_b[8]), .DIB9(1'b0), .DIB10(1'b0), .DIB11(1'b0), .DIB12(1'b0), .DIB13(1'b0), .DIB14(1'b0), .DIB15(1'b0), .DIB16(1'b0), .DIB17(1'b0),
		.DOA0(q_a[0]), .DOA1(q_a[1]), .DOA2(q_a[2]), .DOA3(q_a[3]), .DOA4(q_a[4]), .DOA5(q_a[5]), .DOA6(q_a[6]), .DOA7(q_a[7]), .DOA8(q_a[8]),
		.DOB0(q_b[0]), .DOB1(q_b[1]), .DOB2(q_b[2]), .DOB3(q_b[3]), .DOB4(q_b[4]), .DOB5(q_b[5]), .DOB6(q_b[6]), .DOB7(q_b[7]), .DOB8(q_b[8]),
		.CLKA(clock), .CLKB(clock),
		.WEA(wren_a && cs_a), .CEA(enable_a), .OCEA(1'b1),
		.WEB(wren_b && cs_b), .CEB(enable_b), .OCEB(1'b1),
		.RSTA(1'b0), .RSTB(1'b0)
	);
`endif
endmodule

module dp16k_wrapper_8bit #(parameter addr_width = 8) (
	input clock,
	input [addr_width-1:0] address_a = 0,
	input [7:0] data_a = 0,
	input enable_a = 1,
	input wren_a = 0,
	output [7:0] q_a,
	input cs_a = 1,
	input [addr_width-1:0] address_b = 0,
	input [7:0] data_b = 0,
	input enable_b = 1,
	input wren_b = 0,
	output [7:0] q_b,
	input cs_b = 1
);
`ifdef SIM
	reg [7:0] mem[0:2**addr_width-1];
	reg [7:0] q_a, q_b;
	initial begin :mem_init
		integer i;
		for (i = 0; i < 2**addr_width; i = i + 1'b1)
			mem[i] = 0;
	end
	always @(posedge clock) begin
		if (enable_a) begin
			if (cs_a && wren_a) mem[address_a] <= data_a;
			q_a <= mem[address_a];
		end
		if (enable_b) begin
			if (cs_b && wren_b) mem[address_b] <= data_b;
			q_b <= mem[address_b];
		end
	end
`else
	wire [10:0] A1ADDR = address_a;
	wire [10:0] B1ADDR = address_b;

	DP16KD #(
		.DATA_WIDTH_A(9),
		.DATA_WIDTH_B(9),
		.CLKAMUX("CLKA"),
		.CLKBMUX("CLKB"),
		.WRITEMODE_A("WRITETHROUGH"),
		.WRITEMODE_B("WRITETHROUGH"),
		.GSR("AUTO")
	) _TECHMAP_REPLACE_ (
		.ADA0(1'b0), .ADA1(1'b0), .ADA2(1'b0), .ADA3(A1ADDR[0]), .ADA4(A1ADDR[1]), .ADA5(A1ADDR[2]), .ADA6(A1ADDR[3]), .ADA7(A1ADDR[4]), .ADA8(A1ADDR[5]), .ADA9(A1ADDR[6]), .ADA10(A1ADDR[7]), .ADA11(A1ADDR[8]), .ADA12(A1ADDR[9]), .ADA13(A1ADDR[10]),
		.ADB0(1'b0), .ADB1(1'b0), .ADB2(1'b0), .ADB3(B1ADDR[0]), .ADB4(B1ADDR[1]), .ADB5(B1ADDR[2]), .ADB6(B1ADDR[3]), .ADB7(B1ADDR[4]), .ADB8(B1ADDR[5]), .ADB9(B1ADDR[6]), .ADB10(B1ADDR[7]), .ADB11(B1ADDR[8]), .ADB12(B1ADDR[9]), .ADB13(B1ADDR[10]),
		.DIA0(data_a[0]), .DIA1(data_a[1]), .DIA2(data_a[2]), .DIA3(data_a[3]), .DIA4(data_a[4]), .DIA5(data_a[5]), .DIA6(data_a[6]), .DIA7(data_a[7]), .DIA8(1'b0), .DIA9(1'b0), .DIA10(1'b0), .DIA11(1'b0), .DIA12(1'b0), .DIA13(1'b0), .DIA14(1'b0), .DIA15(1'b0), .DIA16(1'b0), .DIA17(1'b0),
		.DIB0(data_b[0]), .DIB1(data_b[1]), .DIB2(data_b[2]), .DIB3(data_b[3]), .DIB4(data_b[4]), .DIB5(data_b[5]), .DIB6(data_b[6]), .DIB7(data_b[7]), .DIB8(1'b0), .DIB9(1'b0), .DIB10(1'b0), .DIB11(1'b0), .DIB12(1'b0), .DIB13(1'b0), .DIB14(1'b0), .DIB15(1'b0), .DIB16(1'b0), .DIB17(1'b0),
		.DOA0(q_a[0]), .DOA1(q_a[1]), .DOA2(q_a[2]), .DOA3(q_a[3]), .DOA4(q_a[4]), .DOA5(q_a[5]), .DOA6(q_a[6]), .DOA7(q_a[7]),
		.DOB0(q_b[0]), .DOB1(q_b[1]), .DOB2(q_b[2]), .DOB3(q_b[3]), .DOB4(q_b[4]), .DOB5(q_b[5]), .DOB6(q_b[6]), .DOB7(q_b[7]),
		.CLKA(clock), .CLKB(clock),
		.WEA(wren_a && cs_a), .CEA(enable_a), .OCEA(1'b1),
		.WEB(wren_b && cs_b), .CEB(enable_b), .OCEB(1'b1),
		.RSTA(1'b0), .RSTB(1'b0)
	);
`endif
endmodule
