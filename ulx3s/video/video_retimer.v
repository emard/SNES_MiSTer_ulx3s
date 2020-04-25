
module video_retimer (
	input input_clk,
	input dot_clock,
	input [7:0] R_in, G_in, B_in,
	input input_valid,
	input hsync_in, vblank_in,

	input output_clk,
	output reg [7:0] R_out, G_out, B_out,
	output reg output_blank,
	output reg hsync_out, vsync_out
);

localparam xbits = 12;
localparam ybits = 12;

localparam xres = 640;
localparam yres = 480;

localparam hfp = 16;
localparam hpulse = 96;
localparam hbp = 57;

localparam vfp = 10;
localparam vpulse = 2;
localparam vbp = 22;

localparam htotal = xres+hfp+hpulse+hbp;
localparam vtotal = yres+vfp+vpulse+vbp;

reg [14:0] linebuffer[0:8*255];

reg dot_clock_last;
reg dot_clock_strobe;
reg hsync_in_last;
reg [7:0] hctr_in;
reg [7:0] vctr_in;

always @(posedge input_clk) begin
	dot_clock_last <= dot_clock;
	dot_clock_strobe <= dot_clock && !dot_clock_last;

	if (vblank_in) begin
		hctr_in <= 0;
		vctr_in <= 0;
	end else if (hsync_in) begin
		hctr_in <= 0;
		if (!hsync_in_last)
			vctr_in <= vctr_in + 1'b1;
	end else if (input_valid && dot_clock_strobe) begin
		hctr_in <= hctr_in + 1'b1;
	end

	hsync_in_last <= hsync_in;

	if (input_valid && dot_clock_strobe && (vctr_in < 224))
		linebuffer[{vctr_in[2:0], hctr_in}] <= {R_in[7:3], G_in[7:3], B_in[7:3]};
end

reg [xbits-1:0] hctr_out = 0;
reg [ybits-1:0] vctr_out = 0;
reg inc, dec = 0;

reg [14:0] pixel;

reg [2:0] vblank_pipe;

always @(posedge output_clk) begin

	vblank_pipe <= {vblank_pipe[1:0], vblank_in};

	if (vblank_pipe[2:1] == 2'b01) begin
		if (vctr_out > 465) begin
			dec <= 1'b1;
		end else if (vctr_out < 465) begin
			inc <= 1'b1;
		end
	end


	if (hctr_out == htotal-1) begin
		hctr_out <= 0;
		if (vctr_out >= vtotal-1) begin
			vctr_out <= 0;
		end else begin
			if (inc)
				vctr_out <= vctr_out + 2;
			else if (!dec)
				vctr_out <= vctr_out + 1;
		end
		inc <= 1'b0;
		dec <= 1'b0;
	end else begin
		hctr_out <= hctr_out + 1'b1;
	end
	
	hsync_out <= (hctr_out >= (xres + hfp) && hctr_out < (xres + hfp + hpulse));
	vsync_out <= (vctr_out >= (yres + vfp) && vctr_out < (yres + vfp + vpulse));
	output_blank <= !(hctr_out < xres && vctr_out < yres);
	pixel <= linebuffer[{vctr_out[3:1], hctr_out[8:1]-8'd31}];
	if (hctr_out >= 63 && hctr_out < 575 && vctr_out >= 16 && vctr_out < 464) begin
		R_out <= {pixel[14:10], {3{pixel[10]}}};
		G_out <= {pixel[9:5], {3{pixel[5]}}};
		B_out <= {pixel[4:0], {3{pixel[0]}}};
	end else begin
		{R_out, G_out, B_out} <= 24'h000000;
	end
end
endmodule
