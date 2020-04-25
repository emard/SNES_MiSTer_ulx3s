`timescale 1ns / 1ps
module top(input clk_sys, output HSYNC, VSYNC, FIELD, INTERLACE, output [7:0] R, G, B, output [23:0] ROM_ADDR);


	wire [16:0] WRAM_ADDR;
	wire WRAM_CE_N, WRAM_WE_N;
	wire [7:0] WRAM_D;
	reg [7:0] WRAM_Q = 8'b0;

	reg [7:0] wram[0:2**17-1];
`ifdef INIT_WRAM
	initial begin : wram_init
		integer i;
		for (i = 0; i < 2**17; i++)
			wram[i] = (i[9] ^ i[0]) ? 8'hFF : 8'h00;
	end
`endif
	always @(posedge clk_sys) begin
		if (!WRAM_WE_N && !WRAM_CE_N) wram[WRAM_ADDR] <= WRAM_D;
		WRAM_Q <= wram[WRAM_ADDR];
	end


	wire [15:0] VRAM1_ADDR;
	wire VRAM1_CE_N = 1'b0;
	wire VRAM1_WE_N;
	wire [7:0] VRAM1_D;
	reg [7:0] VRAM1_Q = 8'b0;

	reg [7:0] vram1[0:2**15-1];
`ifdef INIT_VRAM
	initial begin : vram1_init
		integer i;
		for (i = 0; i < 2**15; i++)
			vram1[i] = 8'h00;
	end
`endif
	always @(posedge clk_sys) begin
		if (!VRAM1_WE_N && !VRAM1_CE_N) vram1[VRAM1_ADDR[14:0]] <= VRAM1_D;
		VRAM1_Q <= vram1[VRAM1_ADDR[14:0]];
	end

	wire [15:0] VRAM2_ADDR;
	wire VRAM2_CE_N = 1'b0;
	wire VRAM2_WE_N;
	wire [7:0] VRAM2_D;
	reg [7:0] VRAM2_Q = 8'b0;

	reg [7:0] vram2[0:2**15-1];
`ifdef INIT_VRAM
	initial begin : vram2_init
		integer i;
		for (i = 0; i < 2**15; i++)
			vram2[i] = 8'h00;
	end
`endif
	always @(posedge clk_sys) begin
		if (!VRAM2_WE_N && !VRAM2_CE_N) vram2[VRAM2_ADDR[14:0]] <= VRAM2_D;
		VRAM2_Q <= vram2[VRAM2_ADDR[14:0]];
	end

	wire [15:0] ARAM_ADDR;
	wire ARAM_CE_N, ARAM_WE_N;
	wire [7:0] ARAM_D;
	reg [7:0] ARAM_Q = 8'b0;

	reg [7:0] aram[0:2**16-1];
`ifdef INIT_ARAM
	initial begin : aram_init
		integer i;
		for (i = 0; i < 2**16; i++)
			aram[i] = 8'h00;
	end
`endif
	always @(posedge clk_sys) begin
		if (!ARAM_WE_N && !ARAM_CE_N) aram[ARAM_ADDR] <= ARAM_D;
		ARAM_Q <= aram[ARAM_ADDR];
	end

	localparam  BSRAM_BITS = 14; 
	wire [19:0] BSRAM_ADDR;
	wire BSRAM_CE_N, BSRAM_WE_N;
	wire [7:0] BSRAM_D;
	reg [7:0] BSRAM_Q = 8'b0;

	reg [7:0] bsram[0:2**BSRAM_BITS-1];
	initial begin : bsram_init
		integer i;
		for (i = 0; i < 2**BSRAM_BITS; i++)
			bsram[i] = 8'hFF;
	end

	always @(posedge clk_sys) begin
		if (!BSRAM_WE_N && !BSRAM_CE_N) bsram[BSRAM_ADDR[BSRAM_BITS-1:0]] <= BSRAM_D;
		BSRAM_Q <= bsram[BSRAM_ADDR[BSRAM_BITS-1:0]];
	end

	reg reset = 1'b1;
	reg [7:0] reset_ctr = 0;
	always @(posedge clk_sys) begin
		if (&reset_ctr)
			reset <= 1'b0;
		else
			reset_ctr <= reset_ctr + 1'b1;
	end

	// SMW
	localparam ROM_TYPE = 8'h00;
	localparam ROM_SIZE = 512*1024;
	localparam RAM_SIZE = 2*1024;

	reg [15:0] rom[0:(ROM_SIZE/2)-1];
	initial $readmemh("rom.init", rom);
	wire [23:0] ROM_ADDR;
	wire ROM_CE_N, ROM_OE_N;
	wire ROM_WORD;
	reg [15:0] ROM_Q = 16'b0;

	always @(posedge clk_sys) begin
		if (!ROM_CE_N && !ROM_OE_N) begin
			if (!ROM_WORD && ROM_ADDR[0])
				ROM_Q <= {rom[ROM_ADDR[23:1]][7:0], rom[ROM_ADDR[23:1]][15:8]};
			else
				ROM_Q <= rom[ROM_ADDR[23:1]];
		end
	end

	wire [7:0] R,G,B;
	wire FIELD, INTERLACE;
	wire HSYNC, VSYNC;
	wire HBlank_n, VBlank_n;
	wire HIGH_RES, DOTCLK;
	wire [15:0] AUDIO_L, AUDIO_R;

	main main
	(
		.RESET_N(~reset),

		.MCLK(clk_sys), // 21.47727 / 21.28137
		.ACLK(clk_sys),

		//.GSU_ACTIVE(),
		.GSU_TURBO(1'b0),

		.ROM_TYPE(ROM_TYPE),
		.ROM_MASK(ROM_SIZE - 1),
		.RAM_MASK(RAM_SIZE - 1),
		.PAL(1'b0),
		.BLEND(1'b0),

		.ROM_ADDR(ROM_ADDR),
		.ROM_Q(ROM_Q),
		.ROM_CE_N(ROM_CE_N),
		.ROM_OE_N(ROM_OE_N),
		.ROM_WORD(ROM_WORD),

		.BSRAM_ADDR(BSRAM_ADDR),
		.BSRAM_D(BSRAM_D),			
		.BSRAM_Q(BSRAM_Q),			
		.BSRAM_CE_N(BSRAM_CE_N),
		.BSRAM_WE_N(BSRAM_WE_N),

		.WRAM_ADDR(WRAM_ADDR),
		.WRAM_D(WRAM_D),
		.WRAM_Q(WRAM_Q),
		.WRAM_CE_N(WRAM_CE_N),
		.WRAM_WE_N(WRAM_WE_N),

		.VRAM1_ADDR(VRAM1_ADDR),
		.VRAM1_DI(VRAM1_Q),
		.VRAM1_DO(VRAM1_D),
		.VRAM1_WE_N(VRAM1_WE_N),

		.VRAM2_ADDR(VRAM2_ADDR),
		.VRAM2_DI(VRAM2_Q),
		.VRAM2_DO(VRAM2_D),
		.VRAM2_WE_N(VRAM2_WE_N),

		.ARAM_ADDR(ARAM_ADDR),
		.ARAM_D(ARAM_D),
		.ARAM_Q(ARAM_Q),
		.ARAM_CE_N(ARAM_CE_N),
		.ARAM_WE_N(ARAM_WE_N),

		.R(R),
		.G(G),
		.B(B),

		.FIELD(FIELD),
		.INTERLACE(INTERLACE),
		.HIGH_RES(HIGH_RES),
		.DOTCLK(DOTCLK),
		
		.HBLANKn(HBlank_n),
		.VBLANKn(VBlank_n),
		.HSYNC(HSYNC),
		.VSYNC(VSYNC),

		.JOY1_DI(1'b1),
		.JOY2_DI(1'b1),
		.JOY_STRB(JOY_STRB),
		.JOY1_CLK(JOY1_CLK),
		.JOY2_CLK(JOY2_CLK),
		.JOY1_P6(JOY1_P6),
		.JOY2_P6(JOY2_P6),
		.JOY2_P6_in(JOY2_P6_DI),
		
		.EXT_RTC(64'b0),
		
		.TURBO(1'b0),
		//.TURBO_ALLOW(),

		.AUDIO_L(AUDIO_L),
		.AUDIO_R(AUDIO_R)
	);
endmodule
