// File: mt_fsm.v

module mt_fsm (
    input wire clk, rst,
    input wire external_seed_enable, // Signal to trigger first round of seeding after reset
	input wire [31:0] external_seed_value,
    output reg [31:0] random_number,
    output reg valid_rn
);

    // FSM state definitions
    parameter S0_IDLE  = 2'b00,
			  S1_SEED  = 2'b01,
			  S2_TWIST = 2'b10,
			  S3_TRANSIT = 2'b11;
	
	reg [1:0] current_state, previous_state;
	// reg start_seed, start_twist
	
	// Control signals
    wire done_seed, done_twist, valid_rn_fsm;
	wire okay_to_temper;
	
	// State memory interface
    wire [9:0] read_addr1, read_addr2, read_addrM, write_addr_seed, write_addr_twist;
    wire [31:0] write_data_seed, write_data_twist, state_in1, state_in2, state_inM, random_number_fsm;
    wire write_en_seed, write_en_twist;
	
	// Instantiate state memory
    mt_state_mem state_mem (
        .clk(clk),
        .rst(rst),
        .write_en_seed(write_en_seed),
        .write_en_twist(write_en_twist),
        .write_addr_seed(write_addr_seed),
		.write_addr_twist(write_addr_twist),
        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .read_addr3(read_addrM),
        .write_data_seed(write_data_seed),
		.write_data_twist(write_data_twist),
        .read_data1(state_in1),
        .read_data2(state_in2),
        .read_data3(state_inM)
    );
	
	// Instantiate seeding module
    mt_seed seed_gen (
        .clk(clk),
        .rst(rst),
		.seed_value(random_number),
		.current_state(current_state),
        .done_seed(done_seed),
        .write_addr_seed(write_addr_seed),
        .write_data_seed(write_data_seed),
        .write_en_seed(write_en_seed)
    );

    // Instantiate twisting module
    mt_twist twist (
        .clk(clk),
        .rst(rst),
        .matrix_a(32'h9908B0DF),
		.current_state(current_state),
		.external_seed_value(external_seed_value),
		//.seed_value(random_number),
        .state_in1(state_in1),
        .state_in2(state_in2),
        .state_inM(state_inM),
        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .read_addrM(read_addrM),
		.write_en_twist(write_en_twist),
        .write_addr_twist(write_addr_twist),
        .write_data_twist(write_data_twist),
		.done_twist(done_twist),
		.random_number(random_number_fsm),
		.valid_rn(valid_rn_fsm)
    );
	
	always @(posedge clk) begin
        if (rst) begin
            current_state <= S0_IDLE;  
        end 
		else begin
		    random_number <= random_number_fsm;
		    valid_rn <= valid_rn_fsm; 
			case (current_state)
				S0_IDLE: begin
					if (external_seed_enable) begin
						current_state <= S1_SEED;
						previous_state <= current_state;
					end
				end
				
				S1_SEED: begin
					if (done_seed && done_twist) begin // Transition when seeding is complete
						current_state <= S3_TRANSIT;
						previous_state <= current_state;
					end
					else if (done_seed) begin // Transition when seeding is complete
						current_state <= S2_TWIST;
						previous_state <= current_state;
					end
				end
				
				S2_TWIST: begin
					if (done_twist && done_seed) begin // Transition when twisting is complete
						current_state <= S3_TRANSIT;
						previous_state <= current_state;
					end
					else if (done_twist) begin
						current_state <= S1_SEED;
						previous_state <= current_state;
					end
				end
				S3_TRANSIT: begin
					if (previous_state == S2_TWIST) begin
						current_state <= S1_SEED;
						previous_state <= current_state;
					end
					else if (previous_state == S1_SEED) begin
						current_state <= S2_TWIST;
						previous_state <= current_state;
					end
				end
			endcase
		end
    end
endmodule
