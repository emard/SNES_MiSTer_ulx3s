module game_loader
(
	input clk,
	input reset,
	output ready,
	input [2:0] sel,

	output reg    loading = 1'b0,
	output [23:0] flash_address,
	input  [15:0] flash_dout,
	input         flashmem_ready,

	output reg wren,
	output reg [24:0] load_address,
	output reg [15:0] load_data,

	output reg [23:0] rom_mask,
	output reg [23:0] ram_mask,
	output reg  [7:0] rom_type
);

	reg load_done = 1'b0;
	assign ready = load_done;

	reg [22:0] rom_address = 0;
	assign flash_address = ((4'h2 + sel) << 20) + (rom_address << 1);

	reg [10:0] startup_wait_ctr = 0;

	reg [3:0] state;

	reg almost_done = 0;
	//wire flashmem_ready;

	reg [1:0] rom_lohi;
	reg [7:0] rom_mapper, rom_chipset, rom_company;
	reg in_header;
	reg header_found;

	always @(posedge clk) begin
		if (reset) begin
			startup_wait_ctr <= 0;
			rom_address <= 0;
			almost_done <= 1'b0;
			load_done <= 0;
			loading <= 1'b0;
			wren <= 1'b0;
			rom_mask <= (512*1024) - 1; // default: 512kB
			ram_mask <= (4 * 1024) - 1; // default: 4kB BSRAM
			rom_type <= 8'h00; // default: LoROM, no mapper/enhancements
			rom_mapper <= 8'h00;
			rom_chipset <= 8'h00;
			rom_company <= 8'h00;
			in_header <= 1'b0;
			header_found <= 1'b0;
			rom_lohi <= 2'b00;
		end else if (!load_done) begin
			wren <= 1'b0;
			if (almost_done) begin
				load_done <= 1'b1;
			end else if (!loading) begin
				if (&startup_wait_ctr)
					loading <= 1'b1;
				else
					startup_wait_ctr <= startup_wait_ctr + 1'b1;
			end else begin
				if (flashmem_ready) begin
					load_address <= {5'b0, rom_address, 1'b0};
					wren <= 1'b1;
					load_data <= flash_dout[15:0];
					if ((rom_address & rom_mask[23:1]) == rom_mask[23:1])
						almost_done <= 1'b1;
					else
						rom_address <= rom_address + 1'b1;
					if (!header_found) begin
						if ({rom_address, 1'b0} == 24'h007FC0 || {rom_address, 1'b0} == 24'h00FFC0) begin
							rom_lohi <= {1'b0, rom_address[14]};
							in_header <= 1'b1;
						end
						if (in_header) begin
							case ({rom_address[6:0], 1'b0})
								8'hD4: begin
									rom_mapper <= flash_dout[15:8];
								end
								8'hD6: begin
									rom_chipset <= flash_dout[7:0];
									rom_mask <= (1024 << flash_dout[11:8]) - 1;
								end
								8'hD8: begin
									ram_mask <= (1024 << flash_dout[3:0]) - 1;
								end
								8'hDA: begin
									rom_company <= flash_dout[7:0];
									in_header <= 1'b0;
									header_found <= 1'b1;
								end
								default: begin
									if ({rom_address[6:0], 1'b0} < 8'hD4 && (flash_dout[15] || flash_dout[7] || !(|flash_dout)))
										in_header <= 1'b0; // not ASCII
								end
							endcase
						end
					end
					// From https://github.com/MiSTer-devel/Main_MiSTer/blob/f056480a07b4f9f065cb9680cd1d14098bcaaf82/support/snes/snes.cpp#L165
					if (header_found) begin
						rom_type <= {6'h00, rom_lohi};
						if ((rom_mapper == 8'h20 || rom_mapper == 8'h21) && (rom_chipset == 8'h03))
							rom_type[7:4] <= 4'h8;
						else if (rom_mapper == 8'h30 && rom_chipset == 8'h05 && rom_company != 8'hb2)
							rom_type[7:4] <= 4'h8;
						else if (rom_mapper == 8'h31 && (rom_chipset == 8'h03 || rom_chipset == 8'h05))
							rom_type[7:4] <= 4'h8;
						else if (rom_mapper == 8'h20 && rom_chipset == 8'h05)
							rom_type[7:4] <= 4'h9;
						else if (rom_mapper == 8'h30 && rom_chipset == 8'h05 && rom_company == 8'hb2)
							rom_type[7:4] <= 4'hA;
						else if (rom_mapper == 8'h30 && rom_chipset == 8'h03)
							rom_type[7:4] <= 4'hB;
						else if (rom_mapper == 8'h30 && rom_chipset == 8'hf6)
							rom_type[7:3] <= 5'b10001;
						else if (rom_mapper == 8'h30 && rom_chipset == 8'h25)
							rom_type[7:4] <= 4'hC;
						else if (rom_mapper == 8'h3a && (rom_chipset == 8'hf5 || rom_chipset == 8'hf9))
							rom_type[7:4] <= 4'hD;
						else if (rom_mapper == 8'h23 && (rom_chipset == 8'h32 || rom_chipset == 8'h34 || rom_chipset == 8'h35))
							rom_type[7:4] <= 4'h6;
						else if (rom_mapper == 8'h20 && (rom_chipset == 8'h13 || rom_chipset == 8'h14 || rom_chipset == 8'h15))
							rom_type[7:4] <= 4'h7;
					end
				end
			end
		end
	end
endmodule
