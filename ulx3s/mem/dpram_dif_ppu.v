module dpram_dif_ppu #(
	parameter addr_width = 8,
	parameter data_width = 8
) (
	input clock,
	input [7:0] address_a = 0,
	input [15:0] data_a = 0,
	input enable_a = 1,
	input wren_a = 0,
	output [15:0] q_a,
	input cs_a = 1,
	input [6:0] address_b = 0,
	input enable_b = 1,
	output [31:0] q_b,
	input cs_b = 1
);

	reg [15:0] mem[0:255];
	initial begin :mem_init
		integer i;
		for (i = 0; i < 2**addr_width; i = i + 1'b1)
			mem[i] = 0;
	end
	always @(posedge clock)
		if (enable_a && wren_a && cs_a)
			mem[address_a] <= data_a;
	reg [7:0] aa;
	reg [6:0] ab;
	always @(posedge clock) begin
		if (enable_a) aa <= address_a;
		if (enable_b) ab <= address_b;
	end
	assign q_a = mem[aa];
	assign q_b = {mem[{ab, 1'b1}], mem[{ab, 1'b0}]};

endmodule
