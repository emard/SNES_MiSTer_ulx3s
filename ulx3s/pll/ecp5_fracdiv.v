module fracdiv(input clkin, reset, input [31:0] div, output clkout);
	reg [31:0] acc = 0;
	always @(posedge clkin) begin
		{clkout, acc} <= acc + {1'b0, div};
	end
endmodule
