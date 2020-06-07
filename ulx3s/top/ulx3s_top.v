module top
#(
	parameter C_flash_loader=0,
	parameter C_esp32_loader=1
)
(
	input clk_25mhz,
	output [7:0] led,
	input [6:0] btn,
	input [3:0] sw,

	output sdram_clk, sdram_cke, sdram_csn, sdram_wen,
	output sdram_rasn, sdram_casn,

	output [12:0] sdram_a,
	output [1:0] sdram_ba,
	output [1:0] sdram_dqm,
	inout [15:0] sdram_d,

	output [3:0] gpdi_dp, // {clk, r, g, b}
	//output [3:0] gpdi_dn,

	output flash_csn,
	inout flash_mosi, flash_miso, flash_holdn, flash_wpn,

	input  ftdi_txd,
	output ftdi_rxd,

	input  wifi_txd,
	output wifi_rxd,
	output wifi_gpio0,
	input  wifi_gpio5,
	input  wifi_gpio16,

	inout  sd_clk, sd_cmd,
	inout   [3:0] sd_d,

	output [3:0] audio_out_l, audio_out_r,

	output [4:0] debug
);
	wire reset_in = !btn[0] & btn[1] & btn[2]; // reset: pwr+a+b 

	// passthru to ESP32 micropython serial console
	assign wifi_rxd = ftdi_txd;
	assign ftdi_rxd = wifi_txd;

	assign sd_d[3] = 1'bz; // FPGA pin pullup sets SD card inactive at SPI bus
	assign led[7] = sd_d[3];

	reg [7:0] R_cpu_control = 0;
	reg [7:0] reset_ctr = 0;
	reg reset_25mhz = 1;
	always @(posedge clk_25mhz) begin
		if (reset_in)
			reset_ctr <= 0;
		else if (!(&reset_ctr))
			reset_ctr <= reset_ctr + 1'b1;
		reset_25mhz <= R_cpu_control[0] | !(&reset_ctr);
	end

	assign led[0] = reset_25mhz;

	wire clk_125mhz;
	wire locked_125mhz;
	reg reset_125mhz = 1'b1;
	always @(posedge clk_125mhz)
		reset_125mhz <= !locked_125mhz || reset_25mhz;
	// x/4*5 for using 125MHz instead of 100MHz
	localparam DIV_NTSC = 922441723/4*5;
	localparam DIV_PAL = 914027882/4*5;
	wire pal_mode = sw[0];

	wire clk_frac;
	fracdiv fracdiv_i (.clkin(clk_125mhz), .reset(reset_125mhz), .div(pal_mode ? DIV_PAL : DIV_NTSC), .clkout(clk_frac));

	wire clk_mem, clk_video, clk_sys;
	wire locked_sys;
	wire [3:0] clocks_sys;
	ecp5pll
	#(
	    .in_hz(21477300),
	  .out0_hz(85909100), .out0_tol_hz(100),
	  .out1_hz(42954500), .out1_tol_hz(100), .out1_deg(90),
	  .out2_hz(21477300), .out2_tol_hz(100),
	  .out3_hz(21477300), .out3_tol_hz(100) // not used
	)
	pll_sys_i
	(
	  .clk_i(clk_frac),
	  .clk_o(clocks_sys),
	  .locked(locked_sys)
	);
	assign clk_mem   = clocks_sys[0];
	assign clk_video = clocks_sys[1];
	assign clk_sys   = clocks_sys[2];

	reg reset_sys = 1'b1;
	always @(posedge clk_sys)
//		reset_sys <= !locked_sys || reset_100mhz;
		reset_sys <= !locked_sys || reset_125mhz;

	assign led[2] = locked_sys;

	// Block RAM memories

	wire [16:0] WRAM_ADDR;
	wire WRAM_CE_N, WRAM_WE_N;
	wire [7:0] WRAM_D;
	reg [7:0] WRAM_Q;

	reg [7:0] wram[0:2**17-1];
`ifdef INIT_RAM
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
	reg [7:0] VRAM1_Q;

	reg [7:0] vram1[0:2**15-1];
`ifdef INIT_RAM
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
	reg [7:0] VRAM2_Q;

	reg [7:0] vram2[0:2**15-1];
`ifdef INIT_RAM
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
	reg [7:0] ARAM_Q;

	reg [7:0] aram[0:2**16-1];
`ifdef INIT_RAM
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

	wire [24:0] main_ram_addr;
	wire main_ram_rd, main_ram_wr, main_ram_word, main_ram_busy;
	wire [15:0] main_ram_din, main_ram_dout;

	sdram sdram_i(
		.SDRAM_DQ(sdram_d),
		.SDRAM_A(sdram_a),
		.SDRAM_DQML(sdram_dqm[0]),
		.SDRAM_DQMH(sdram_dqm[1]),
		.SDRAM_BA(sdram_ba),
		.SDRAM_nCS(sdram_csn),
		.SDRAM_nWE(sdram_wen),
		.SDRAM_nRAS(sdram_rasn),
		.SDRAM_nCAS(sdram_casn),
		.SDRAM_CLK(sdram_clk),
		.SDRAM_CKE(sdram_cke),

		.init(/*reset_sys*/ 1'b0),
		.clk(clk_mem),
		.addr(main_ram_addr),
		.rd(main_ram_rd),
		.wr(main_ram_wr),
		.din(main_ram_din),
		.dout(main_ram_dout),
		.busy(main_ram_busy),
		.word(main_ram_word)
	);

	wire load_done;
	wire [24:0] load_addr;
	wire [15:0] load_data;
	wire load_wr;

	wire [23:0] ROM_ADDR;
	wire ROM_CE_N, ROM_OE_N;
	wire ROM_WORD;
	wire [15:0] ROM_Q = main_ram_dout;

	wire [19:0] BSRAM_ADDR;
	wire BSRAM_CE_N, BSRAM_WE_N;
	wire [7:0] BSRAM_D;
	wire [7:0] BSRAM_Q = main_ram_dout[7:0];

	assign main_ram_addr = load_done ? (BSRAM_CE_N ? {1'b0, ROM_ADDR} : {5'b10000, BSRAM_ADDR}) : load_addr;
	assign main_ram_wr = load_done ? (!BSRAM_CE_N && !BSRAM_WE_N) : load_wr;
	assign main_ram_rd = load_done && ((!ROM_CE_N && !ROM_OE_N) || (!BSRAM_CE_N && BSRAM_WE_N));
	assign main_ram_word = load_done ? (BSRAM_CE_N && ROM_WORD) : 1'b1;
	assign main_ram_din = load_done ? {BSRAM_D, BSRAM_D} : load_data;

	wire [7:0] rom_type;
	wire [23:0] rom_mask, ram_mask;

	wire loading, flashmem_ready;
	wire [23:0] flash_address;
	wire [31:0] flash_dout; // only [15:0] used
	generate
	if(C_flash_loader)
	begin
	icosoc_flashmem
	flash_i
	(
		.clk(clk_sys),
		.reset(reset_sys),
		.valid(loading),        // <-
		.ready(flashmem_ready), // -> 
		.addr(flash_address),   // <-
		.rdata(flash_dout),     // ->

		.spi_cs  (flash_csn),
		.spi_sclk(flash_sck),
		.spi_mosi(flash_mosi),
		.spi_miso(flash_miso)
	);
	game_loader
	loader
	(
		.clk(clk_sys),
		.reset(reset_sys),
		.ready(load_done),
		//.sel(sw[3:1]),
		.sel(0),

		.loading(loading),               // ->
		.flashmem_ready(flashmem_ready), // <-
		.flash_address(flash_address),   // ->
		.flash_dout(flash_dout[15:0]),   // <-

		.wren(load_wr),
		.load_address(load_addr),
		.load_data(load_data),

		.rom_type(rom_type),
		.rom_mask(rom_mask),
		.ram_mask(ram_mask)
	);
	assign wifi_gpio0 = 1'b1;
	assign led[3] = load_done;
	(* keep *) USRMCLK flash_mclk_i(.USRMCLKTS(1'b0), .USRMCLKI(flash_sck));
	end
	if(C_esp32_loader)
	begin
		wire irq;
		wire [31:0] spi_addr;
		wire [7:0] spi_in, spi_out;
		wire spi_rd, spi_wr;
		spi_ram_btn
		#(
			.c_addr_bits($bits(spi_addr)),
			.c_sclk_capable_pin(1'b0)
		)
		spi_ram_btn_inst
		(
			.clk(clk_sys),
			.csn(~wifi_gpio5),
			.sclk(wifi_gpio16),
			.mosi(sd_d[1]), // wifi_gpio4
			.miso(sd_d[2]), // wifi_gpio12
			.btn(btn),
			.irq(irq),
			.rd(spi_rd),
			.wr(spi_wr),
			.addr(spi_addr),
			.data_in(spi_in),
			.data_out(spi_out)
		);
		assign wifi_gpio0 = ~irq;
		reg [7:0] R_data[0:1];
		reg R_spi_wr;
		reg flashmem_ready;
		always @(posedge clk_sys)
		begin
			R_spi_wr <= spi_wr;
			if(spi_wr == 1'b1)
			begin
				if(spi_addr[31:24] == 8'hFF)
					R_cpu_control <= spi_out;
				else
					R_data[spi_addr[0]] <= spi_out;
			end
			flashmem_ready <= spi_addr[31:24] != 8'h00 || spi_addr[0] == 1'b0 ? 1'b0 : spi_wr & ~R_spi_wr;
		end
		assign led[6] = R_cpu_control[0];
		assign flash_dout[15:8] = R_data[1];
		assign flash_dout[7:0]  = R_data[0];
		game_loader
		loader
		(
			.clk(clk_sys),
			.reset(reset_sys),
			.ready(load_done),
			//.sel(sw[3:1]),
			.sel(0),

			//.loading(loading),               // ->
			.flashmem_ready(flashmem_ready), // <-
			//.flash_address(flash_address),   // ->
			.flash_dout(flash_dout[15:0]),   // <-

			.wren(load_wr),
			.load_address(load_addr),
			.load_data(load_data),

			.rom_type(rom_type),
			.rom_mask(rom_mask),
			.ram_mask(ram_mask)
		);
		assign led[3] = load_done;
    	end
	endgenerate

	reg snes_reset = 1'b1;
	reg [4:0] snes_reset_count = 0;
	always @(posedge clk_sys) begin
		if (!load_done || reset_sys) begin
			snes_reset <= 1'b1;
			snes_reset_count <= 0;
		end else begin
			if (&snes_reset_count) begin
				snes_reset <= 1'b0;
			end else begin
				snes_reset_count <= snes_reset_count + 1'b1;
			end
		end
	end

	// FIXME: fixed config for Super Mario World
	//localparam ROM_TYPE = 0;
	//localparam ROM_SIZE = 512*1024;
	//localparam RAM_SIZE = 2*1024;


	wire [7:0] R,G,B;
	wire FIELD, INTERLACE;
	wire HSYNC, VSYNC;
	wire HBlank_n, VBlank_n;
	wire HIGH_RES, DOTCLK;
	wire [15:0] AUDIO_L, AUDIO_R;

	wire [23:0] trace_addr;

	wire [1:0] JOY1_DI;
	wire JOY_STRB, JOY1_CLK, JOY1_P6;

	main main
	(
		.RESET_N(~snes_reset),

		.MCLK(clk_sys), // 21.47727 / 21.28137
		.ACLK(clk_sys),

		.GSU_ACTIVE(),
		.GSU_TURBO(1'b0),

		.ROM_TYPE(rom_type),
		.ROM_MASK(rom_mask),
		.RAM_MASK(ram_mask),
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

		.JOY1_DI(JOY1_DI),
		.JOY2_DI(1'b1),
		.JOY_STRB(JOY_STRB),
		.JOY1_CLK(JOY1_CLK),
		.JOY2_CLK(JOY2_CLK),
		.JOY1_P6(JOY1_P6),
		.JOY2_P6(JOY2_P6),
		.JOY2_P6_in(1'b0),
		
		.EXT_RTC(64'b0),
		
		.TURBO(1'b0),
		.TURBO_ALLOW(),

		.AUDIO_L(AUDIO_L),
		.AUDIO_R(AUDIO_R),

		.TRACE_ADDR(trace_addr)
	);

	wire clk_pix_dvi;
	wire clk_fast_dvi;
	wire [3:0] clocks_dvi;
	ecp5pll
	#(
	    .in_hz( 25*1000000),
	  .out0_hz(125*1000000),
	  .out1_hz( 25*1000000),
	  .out2_hz( 25*1000000), // not used
	  .out3_hz( 25*1000000), // not used
	)
	pll_dvi_i
	(
	  .clk_i(clk_25mhz),
	  .clk_o(clocks_dvi),
	  .locked(locked_125mhz)
	);
	assign clk_fast_dvi = clocks_dvi[0];
	assign clk_pix_dvi  = clocks_dvi[1];
	assign clk_125mhz   = clocks_dvi[0];

	wire hsync_dvi, vsync_dvi, blank_dvi;
	wire [7:0] r_dvi, g_dvi, b_dvi;
`ifdef USE_VGA
	vga /*#(
		.C_resolution_x(1024),
		.C_hsync_front_porch(16),
		.C_hsync_pulse(96),
		.C_hsync_back_porch(44),
		.C_resolution_y(768),
		.C_vsync_front_porch(10),
		.C_vsync_pulse(2),
		.C_vsync_back_porch(31),
		.C_bits_x(11),
		.C_bits_y(11)
	)*/ vga_instance (
		.clk_pixel(clk_pix_dvi),
		.vga_hsync(hsync_dvi),
		.vga_vsync(vsync_dvi),
		
		.vga_blank(blank_dvi)
	);
`else 
	video_retimer retimer_i (
		.input_clk(clk_sys),
		.dot_clock(DOTCLK),
		.R_in(R), .G_in(G), .B_in(B),
		.input_valid(HBlank_n && VBlank_n),
		.hsync_in(HSYNC), .vblank_in(!VBlank_n),

		.output_clk(clk_pix_dvi),
		.R_out(r_dvi), .G_out(g_dvi), .B_out(b_dvi),
		.output_blank(blank_dvi),
		.hsync_out(hsync_dvi), .vsync_out(vsync_dvi)
	);
`endif

	wire [7:0] osd_vga_r, osd_vga_g, osd_vga_b;
	wire osd_vga_hsync, osd_vga_vsync, osd_vga_blank;
	spi_osd
	#(
	  .c_start_x(62), .c_start_y(80),
	  .c_chars_x(64), .c_chars_y(20),
	  .c_init_on(0),
	  .c_char_file("osd.mem"),
	  .c_font_file("font_bizcat8x16.mem")
	)
	spi_osd_inst
	(
	  .clk_pixel(clk_pix_dvi), .clk_pixel_ena(1),
	  .i_r(blank_dvi ? 8'b0 : r_dvi),
	  .i_g(blank_dvi ? 8'b0 : g_dvi),
	  .i_b(blank_dvi ? 8'b0 : b_dvi),
	  .i_hsync(hsync_dvi), .i_vsync(vsync_dvi), .i_blank(blank_dvi),
	  .i_csn(~wifi_gpio5), .i_sclk(wifi_gpio16), .i_mosi(sd_d[1]), // .o_miso(),
	  .o_r(osd_vga_r), .o_g(osd_vga_g), .o_b(osd_vga_b),
	  .o_hsync(osd_vga_hsync), .o_vsync(osd_vga_vsync), .o_blank(osd_vga_blank)
	);

	wire [1:0] tmds[3:0];

	vga2dvid #(
		.C_ddr(1'b1),
		.C_depth(8)
	) vga2dvid_instance (
		.clk_pixel(clk_pix_dvi),
		.clk_shift(clk_fast_dvi),
		.in_red(osd_vga_r),
		.in_green(osd_vga_g),
		.in_blue(osd_vga_b),
		.in_hsync(osd_vga_hsync),
		.in_vsync(osd_vga_vsync),
		.in_blank(osd_vga_blank),
		.out_clock(tmds[3]),
		.out_red(tmds[2]),
		.out_green(tmds[1]),
		.out_blue(tmds[0])
	);

	ODDRX1F ddr_clock (.D0(tmds[3][0]), .D1(tmds[3][1]), .Q(gpdi_dp[3]), .SCLK(clk_fast_dvi), .RST(0));
	ODDRX1F ddr_red   (.D0(tmds[2][0]), .D1(tmds[2][1]), .Q(gpdi_dp[2]), .SCLK(clk_fast_dvi), .RST(0));
	ODDRX1F ddr_green (.D0(tmds[1][0]), .D1(tmds[1][1]), .Q(gpdi_dp[1]), .SCLK(clk_fast_dvi), .RST(0));
	ODDRX1F ddr_blue  (.D0(tmds[0][0]), .D1(tmds[0][1]), .Q(gpdi_dp[0]), .SCLK(clk_fast_dvi), .RST(0));

/*
	uart_tracer trace_i (
		.clk(clk_25mhz),
		.trace_data({rom_type, rom_mask[23:16], trace_addr[23:8]}),
		.uart_tx(ftdi_rxd)
	);
*/
	wire dac_l, dac_r;

	assign led[4] = R[7] || R[6];
	assign led[5] = G[7] || G[6];

	//assign led[6] = dac_l;
	//assign led[7] = dac_r;

	wire [15:0] audio_l_u = AUDIO_L + 16'h8000;
	wire [15:0] audio_r_u = AUDIO_R + 16'h8000;

	sigma_delta_dac #(.MSBI(15)) dac_l_i (.CLK(clk_sys), .RESET(reset_sys), .DACin(audio_l_u), .DACout(dac_l));
	sigma_delta_dac #(.MSBI(15)) dac_r_i (.CLK(clk_sys), .RESET(reset_sys), .DACin(audio_r_u), .DACout(dac_r));

	assign audio_out_l = {4{dac_l}};
	assign audio_out_r = {4{dac_r}};

	assign debug[0] = clk_sys;
	assign debug[1] = DOTCLK;
	assign debug[2] = HSYNC;
	assign debug[3] = VSYNC;
	assign debug[4] = HBlank_n;

	// ULX3S to SNES input

	wire [15:0] joy1_buttons;

	assign joy1_buttons[0] = ~btn[1]; // B: FIRE1
	assign joy1_buttons[1] = ~btn[2]; // Y: FIRE2
	assign joy1_buttons[2] = 1'b1; // SELECT: unmapped
	assign joy1_buttons[3] = btn[0]; // START: PWRn
	assign joy1_buttons[4] = ~btn[3]; // UP
	assign joy1_buttons[5] = ~btn[4]; // DOWN
	assign joy1_buttons[6] = ~btn[5]; // LEFT
	assign joy1_buttons[7] = ~btn[6]; // RIGHT
	assign joy1_buttons[15:8] = 8'hFF; // AXLR: not mapped, remainder: unused


	reg [15:0] joy1_shift = 16'hFFFF;
	assign JOY1_DI = {1'b1, joy1_shift[0]};
	reg joy_strb_last, joy_clk_last;

	always @(posedge clk_sys) begin
		if (JOY_STRB)
			joy1_shift <= joy1_buttons;
		if (JOY1_CLK && !joy_clk_last)
			joy1_shift <= {1'b0, joy1_shift[15:1]};
		joy_clk_last <= JOY1_CLK;
	end

endmodule
