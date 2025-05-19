// File: mt_uart.v

module mt_uart (
    input wire sysclk_n, sysclk_p,
    input wire reset,
    output reg [7:0] disp_state,  // drives LEDs
    output wire tx                // UART TX
);

    // === Differential Clock Buffer ===
    wire clk;
    IBUFDS #(
        .DIFF_TERM("TRUE"),
        .IBUF_LOW_PWR("FALSE")
    ) clk_ibuf (
        .O(clk),
        .I(sysclk_p),
        .IB(sysclk_n)
    );

    // === Create clock for sequence ===
    reg [27:0] counter = 0;
    reg seq_clk = 0;	

    always @(posedge clk) begin
        if (counter == 28'd1_000_000) begin // 100Hz.	Count to 100,000,000 for 1 Hz
            counter <= 0;
            seq_clk <= ~seq_clk;
        end else begin
            counter <= counter + 1;
        end
    end
	
	// === Create MT19937 instance ================================================ 
	wire [31:0] random_number;
	wire valid_rn;
	
	mt_fsm mt_fsm_instance(
		.clk(seq_clk), 
		.rst(!reset),
		.external_seed_enable(1'b1), // Signal to trigger first round of seeding after reset
		.external_seed_value(32'h0badbeef),
		.random_number(random_number),
		.valid_rn(valid_rn)
	);
	
	// === UART Transmission Logic ===============================================
	parameter MAX_BYTES = 4;  // Change as needed
	reg [7:0] uart_data;
	reg uart_start = 0;
	wire uart_ready;
	
	reg [7:0] data_to_send [0:MAX_BYTES-1];  // Your message buffer
	reg [3:0] send_index = 0;                // Current byte index
	reg [1:0] send_state = 0;  				 // 0: idle, 1: send low, 2: wait
	reg prev_seq_clk = 0;					 // Change to prev_seq_clk

	// Rising edge detection and transmission FSM
	always @(posedge clk) begin
		prev_seq_clk <= seq_clk;			 // Change to seq_clk
		uart_start <= 0;

		case (send_state)
			0: begin
				if (~prev_seq_clk && seq_clk && valid_rn) begin		// posedge seq_clk and valid_rn
					data_to_send[0] <= random_number[7:0];
					data_to_send[1] <= random_number[15:8];
					data_to_send[2] <= random_number[23:16];
					data_to_send[3] <= random_number[31:24];
					send_state <= 1;
					send_index <= 0;
				end
			end
			1: begin  // Send lower byte
				if (uart_ready && send_index < MAX_BYTES) begin
					uart_data <= data_to_send[send_index];
					uart_start <= 1;
					send_state <= 2;
					send_index <= send_index + 1;
				end
			end
			2: begin  // Wait for uart_ready to go low
				if (!uart_ready && send_index < MAX_BYTES)
					send_state <= 1;
				else if (!uart_ready)
					send_state <= 0;
			end
		endcase
	end
	
    // === UART Transmitter Instantiation ===
    uart_tx #(
        .CLK_FREQ(200_000_000),
        .BAUD_RATE(9600)
    ) uart_inst (
        .clk(clk),
        .start(uart_start),
        .data(uart_data),
        .tx(tx),
        .ready(uart_ready)
    );
    
    
    // === LED flashing for vibe ===========================================
    
    // === Create clock for LEDs ===
    reg [27:0] counter_LED = 0;
    reg led_clk = 0;
    reg prev_led_clk = 0;	

    always @(posedge clk) begin
        if (counter_LED == 28'd10_000_000) begin // 10Hz.	Count to 100,000,000 for 1 Hz
            counter_LED <= 0;
            led_clk <= ~led_clk;
        end else begin
            counter_LED <= counter_LED + 1;
        end
    end
    
    always @(posedge clk) begin
        prev_led_clk <= led_clk;
        if (~prev_led_clk && led_clk && valid_rn) begin		// posedge led_clk and valid_rn
		  disp_state <= random_number[7:0];
		end
    end
	
endmodule