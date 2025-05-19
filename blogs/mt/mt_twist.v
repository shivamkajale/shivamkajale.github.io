// File: mt_twist.v
// Description: Implements the twist transformation of the Mersenne Twister (MT19937)
// Updates the state vector using bitwise operations and a predefined transformation matrix.
// Runs sequentially over 624 cycles to generate the next state.

module mt_twist (
    input wire clk, rst,
    input wire [31:0] matrix_a, // Constant matrix A for transformation
    input wire [1:0] current_state,
    input wire [31:0] external_seed_value,
    
    // Interface with state memory
    input wire [31:0] state_in1, state_in2, state_inM,
    output reg [9:0] read_addr1, read_addr2, read_addrM,
    
	output reg write_en_twist,
	output reg [9:0] write_addr_twist,
    output reg [31:0] write_data_twist,
	
	output reg done_twist,  // Asserted when twisting is complete
	output reg [31:0] random_number,
    output reg valid_rn
);

    // Constants for bit manipulation
    parameter UPPER_MASK = 32'h80000000;  // Most significant bit (MSB)
    parameter LOWER_MASK = 32'h7FFFFFFF;  // Remaining bits
    parameter M = 397; // Offset for state update
    // Tempering constants
    parameter U = 11, S = 7, T = 15, L = 18;
    parameter B = 32'h9D2C5680, C = 32'hEFC60000;
    
	// Internal registers
    reg [9:0] index_twist;
    reg [31:0] x, xA;
    
    // Pipeline registers for intermediate values
    reg [31:0] y1, y2, y3;
    reg valid_reg1, valid_reg2, valid_reg3, okay_to_temper;
    
    always @(posedge clk) begin
        if (rst) begin
            random_number <= external_seed_value;
			valid_rn <= 0;
            index_twist <= 10'd0;
            done_twist <= 1'b0;
            write_en_twist <= 1'b0;
            valid_reg1 <= 1'b0;
            valid_reg2 <= 1'b0;
            valid_reg3 <= 1'b0;
			write_data_twist <= external_seed_value;
			y1 <= external_seed_value;
			y2 <= external_seed_value;
			y3 <= external_seed_value;
            okay_to_temper <= 1'b0;
        end 
		else if (current_state == 2'b10) begin
            if (index_twist == 0) begin
                done_twist <= 1'b0;  // Clear done flag when a new cycle begins
            end
            if (index_twist < 624) begin
				if (index_twist == 623) begin
					done_twist <= 1'b1;
				end
                // Read addresses (state memory outputs valid immediately)
                read_addr1 <= index_twist;
                read_addr2 <= (index_twist + 1) % 624;
                read_addrM <= (index_twist + M) % 624;

                // Compute twisted value
                x = (state_in1 & UPPER_MASK) | (state_in2 & LOWER_MASK);
                xA = x >> 1;
                if (x[0]) xA = xA ^ matrix_a;
                
                write_data_twist <= state_inM ^ xA;
                
                // Write back to memory
                write_addr_twist <= index_twist;
                write_en_twist <= 1'b1;
                
                // Move to next index
                index_twist <= index_twist + 1;
				okay_to_temper <= 1'b1;
				
				// Stage 1: First XOR with right shift (U)
				y1 <= write_data_twist ^ (write_data_twist >> U);
				valid_reg1 <= okay_to_temper;

				// Stage 2: AND-mask with B and XOR (S)
				y2 <= y1 ^ ((y1 << S) & B);
				valid_reg2 <= valid_reg1;

				// Stage 3: AND-mask with C and XOR (T)
				y3 <= y2 ^ ((y2 << T) & C);
				valid_reg3 <= valid_reg2;

				// Stage 4: Final XOR with right shift (L)
				random_number <= y3 ^ (y3 >> L);
				valid_rn <= valid_reg3;
            end 
			else begin
                // done_twist <= 1'b1;  // Set done flag when 624 updates are complete
                write_en_twist <= 1'b0;
                index_twist <= 10'd0;
            end
        end
		else if (current_state == 2'b01 || current_state == 2'b11) begin
			if (current_state == 2'b11) begin
				done_twist <= 1'b0;
			end
			if (okay_to_temper) begin
				okay_to_temper <= 1'b0;
				y1 <= write_data_twist ^ (write_data_twist >> U);
				valid_reg1 <= okay_to_temper;
				y2 <= y1 ^ ((y1 << S) & B);
				valid_reg2 <= valid_reg1;
				y3 <= y2 ^ ((y2 << T) & C);
				valid_reg3 <= valid_reg2;
				random_number <= y3 ^ (y3 >> L);
				valid_rn <= valid_reg3;
			end
			else if (valid_reg1) begin
				valid_reg1 <= 0;
				y2 <= y1 ^ ((y1 << S) & B);
				valid_reg2 <= valid_reg1;
				y3 <= y2 ^ ((y2 << T) & C);
				valid_reg3 <= valid_reg2;
				random_number <= y3 ^ (y3 >> L);
				valid_rn <= valid_reg3;
			end
			else if (valid_reg2) begin
				valid_reg2 <= 1'b0;
				y3 <= y2 ^ ((y2 << T) & C);
				valid_reg3 <= valid_reg2;
				random_number <= y3 ^ (y3 >> L);
				valid_rn <= valid_reg3;	
			end
			else if (valid_reg3) begin
				valid_reg3 <= 1'b0;
				random_number <= y3 ^ (y3 >> L);
				valid_rn <= valid_reg3;	
			end
			else begin
				valid_rn <= 1'b0;
			end
		end
    end
endmodule