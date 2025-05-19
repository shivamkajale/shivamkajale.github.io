// File: uart_tx.v

module uart_tx #(
    parameter CLK_FREQ = 200_000_000,    // Hz
    parameter BAUD_RATE = 9600
)(
    input wire clk,
    input wire start,
    input wire [7:0] data,
    output reg tx = 1'b1,
    output reg ready = 1'b1
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam TOTAL_BITS = 10; // 1 start + 8 data + 1 stop

    reg [3:0] bit_index = 0;
    reg [15:0] clk_count = 0;
    reg [9:0] shift_reg = 10'b1111111111; // 10 bits: [stop][data][start]
    reg sending = 0;

    always @(posedge clk) begin
        if (!sending && start) begin
            // Load shift register: {stop, data[7:0], start}
            // LSB is start bit, then data[0], ..., data[7], then stop bit as MSB
            shift_reg <= {1'b1, data, 1'b0}; // [stop][data][start]
            bit_index <= 0;
            clk_count <= 0;
            sending <= 1;
            ready <= 0;
        end else if (sending) begin
            if (clk_count < CLKS_PER_BIT - 1) begin
                clk_count <= clk_count + 1;
            end else begin
                clk_count <= 0;
                tx <= shift_reg[bit_index]; // Send current bit
                bit_index <= bit_index + 1;
                if (bit_index == TOTAL_BITS - 1) begin
                    sending <= 0;
                    ready <= 1;
                    tx <= 1; // idle
                end
            end
        end else begin
            tx <= 1; // idle line
        end
    end
endmodule
