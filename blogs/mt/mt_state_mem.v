// File: mt_state_mem.v
// Description: Implements a memory module for storing the 624-word state 
// vector of the Mersenne Twister (MT19937) algorithm. This module supports 
// concurrent reading of three state values and allows writing to a specific 
// address. Designed for optimized access to facilitate the twisting step.

module mt_state_mem (
    input  wire clk, rst,
    input  wire write_en_seed, write_en_twist,
    input  wire [9:0] write_addr_seed, write_addr_twist, read_addr1, read_addr2, read_addr3,
    input  wire [31:0] write_data_seed, write_data_twist,
    output reg [31:0] read_data1, read_data2, read_data3
);

    // State vector memory (624 entries, 32-bit each)
    reg [31:0] state [0:623];
    integer i;
    
    // Reset logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 624; i = i + 1) begin
                state[i] <= 32'h0;  // Initialize state vector
            end
        end 
		else if (write_en_seed) begin
            state[write_addr_seed] <= write_data_seed; // Update state vector
        end
		else if (write_en_twist) begin
            state[write_addr_twist] <= write_data_twist; // Update state vector
        end
    end
    
    // Read logic (combinational for immediate access)
    always @(*) begin
        read_data1 = state[read_addr1];
        read_data2 = state[read_addr2];
        read_data3 = state[read_addr3];
    end
    
endmodule
