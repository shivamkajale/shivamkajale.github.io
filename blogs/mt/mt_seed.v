// File: mt_seed.v
// Description: Implements the MT19937 seeding formula to initialize the 624-word state vector.
// Computes the state using the recurrence relation:
// s_i = (f * (s_{i-1} ^ (s_{i-1} >> (w-2))) + i) mod 2^32

module mt_seed (
    input wire clk, rst,
    input wire [31:0] seed_value,  // Seed input, i.e. last random number
	input wire [1:0] current_state,
	
    output reg done_seed,  // Flag off seeding completion to FSM
    output reg [9:0] write_addr_seed,
    output reg [31:0] write_data_seed,
    output reg write_en_seed
);

    // Constants
    parameter F = 32'h6C078965; // 1812433253 (multiplication factor for seeding)
    
    // Internal registers
    reg [9:0] index_seed;
    reg [31:0] state;
    
    always @(posedge clk) begin
        if (rst) begin
            index_seed <= 10'd0;
            write_en_seed <= 1'b0;
            done_seed <= 1'b0;
        end 
		else if (current_state == 2'b11) begin
			done_seed <= 1'b0;
		end
		else if (current_state == 2'b01) begin
            if (index_seed < 624) begin
				if (index_seed == 0) begin	// Very first value borrowed from ext_seed or last random number
					state <= seed_value;
					write_data_seed <= seed_value;
					done_seed <= 1'b0;
				end
				else begin
					state <= (F * (state ^ (state >> 30)) + index_seed) & 32'hFFFFFFFF; // Seeding formula
					write_data_seed <= (F * (state ^ (state >> 30)) + index_seed) & 32'hFFFFFFFF; // Seeding formula
				end
                write_addr_seed <= index_seed;
                write_en_seed <= 1'b1;
                index_seed <= index_seed + 1;
				if (index_seed == 623) begin
					done_seed <= 1'b1;
				end
            end 
			else begin 		// Seeding done. So, set flag appropriately.
                index_seed <= 10'd0;
				write_en_seed <= 1'b0;
				// done_seed <= 1'b1;
            end
        end
    end

endmodule