module sprom_verilog #(
	parameter addr_width = 8,
	parameter data_width = 8,
	parameter length = 256,
	parameter [1023:0] hex_file = "",
) (
	input clock,
	input [addr_width-1:0] address,
	output reg [data_width-1:0] q
);
	reg [data_width-1:0] mem[0:length-1];
	generate
		if (hex_file != "")
			initial $readmemh(hex_file, mem);
	endgenerate
	always @(posedge clock)
		q <= mem[address];
endmodule
