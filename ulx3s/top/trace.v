module uart_tracer(input clk, input [31:0] trace_data, output uart_tx);
	// May be capturing from another domain
	reg [31:0] td_sync_0, td_sync_1;
	always @(posedge clk) begin
		td_sync_0 <= trace_data;
		td_sync_1 <= td_sync_0;
	end

	function [7:0] to_hex;
		input [3:0] nibble;
		begin
			to_hex = (nibble >= 10 ? (55 + nibble) : (48 + nibble)); 
		end
	endfunction

	reg [4:0] nibble = 0;
	reg uart_send = 0;
	reg [3:0] char_delay = 0;
	reg [7:0] uart_data = 0;

	wire uart_busy;

	always @(posedge clk) begin
		uart_send <= 1'b0;
		if (!uart_busy) begin
			if (&char_delay) begin
				if (nibble < 8) begin
					// Hex char
					uart_send <= 1'b1;
					uart_data <= to_hex(td_sync_1[(7-nibble) * 4 +: 4]);
				end else if (nibble == 8) begin
					uart_send <= 1'b1;
					uart_data <= 13; // CR
				end else if (nibble == 9) begin
					uart_send <= 1'b1;
					uart_data <= 10; // LF
				end else begin
					// Idle inter-word gap
				end
				nibble <= nibble + 1'b1;
				char_delay <= 0;
			end else begin
				char_delay <= char_delay + 1'b1;
			end
		end else begin
			char_delay <= 0;
		end
	end

	uart_tx #(
		.clk_freq(25000000),
		.baud(500000)
	) tx_i (
		.clk(clk),
		.tx_start(uart_send),
		.tx_data(uart_data),
		.tx_busy(uart_busy),
		.tx(uart_tx)
	);

endmodule
