// File: tb_mt_fsm.v
// Description: Testbench for mt_top_level (Top-Level Mersenne Twister)
// Generates 1 million random numbers and writes them to a text file.
`timescale 1ns / 1ps

module tb_mt_fsm;

    reg clk, rst;
    reg external_seed_enable;
    reg [31:0] external_seed_value;
    wire [31:0] random_number;
    wire valid_rn;

    integer file;
    integer i;

    // Instantiate the DUT (Device Under Test)
    mt_fsm uut (
        .clk(clk),
        .rst(rst),
        .external_seed_enable(external_seed_enable),
        .external_seed_value(external_seed_value),
        .random_number(random_number),
        .valid_rn(valid_rn)
    );

    // Clock generation (100MHz -> 10ns period)
    always #15 clk = ~clk;

    // Test procedure
    initial begin
        file = $fopen("samples_1M_post-imp_33MHz.txt", "w"); // Open file for writing
        if (file == 0) begin
            $display("Failed to open file! Simulation aborted.");
            $finish;
        end
        
        $display("Starting testbench for mt_top_level");
        clk = 0;
        rst = 1;
		i = 0;
        external_seed_enable = 1;
        external_seed_value = 32'hFEEDBEEF; // Example seed value
        
        #51 rst = 0; // Release reset
        #60 external_seed_enable = 0;
        
        // Generate 1,000,000 random numbers
        while (i<1000000) begin
            @(posedge clk);
            if (valid_rn) begin
                $fwrite(file, "%d\n", random_number); // Write to file
				i = i + 1;
            end
        end
        
        $fclose(file); // Close file
        $display("Testbench completed. Random numbers saved to random_numbers.txt");
        $finish;
    end

    // Monitor output
//    initial begin
//        $monitor("Sample Number=%d | Time=%0t | Random Number=%h | Valid=%b", i, $time, random_number, valid_rn);
//    end

endmodule
