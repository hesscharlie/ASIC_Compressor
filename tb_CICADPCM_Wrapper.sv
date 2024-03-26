`timescale 1 ns / 1 ns


module testbench;
    reg clk;
    reg block_enable;
    reg pdm_in; 
    wire signed [3:0] encPcm;
    wire outValid;
	parameter clk_hold = 0;
	integer output_counter;
	reg slow_clk;

    integer x_in, x_read, x_out;

    // module instantiation
    CIC_ADPCM_Wrapper uut (
        .clk(clk),
		.slow_clk(slow_clk),
        .block_enable(block_enable),
        .pdm_in(pdm_in),
        .outValid(outValid),
        .encPcm(encPcm)
    );


		   
	always #5 clk = ~clk;

	//Clock Divider for ADPCM
	reg [3:0] counter; // 4-bit counter to divide the clock

	always @(posedge clk) begin
   		 // Increment the counter on each rising edge of the 512 kHz clock
    	 counter <= counter + 1;
   		 // Toggle the output every 8 counts to get a 64 kHz clock
   		 if (counter == 4'd7) begin
       		 slow_clk <= ~slow_clk;
         	 counter <= 4'd0; // Reset counter after reaching 7
    	 end
	 end


	
	always @(posedge clk)
	begin
		if (output_counter >= 63) begin
			# clk_hold $fwrite(x_out,"%d\n",encPcm);
			output_counter <= 0;
		end
		else begin
			output_counter <= output_counter + 1;
		end
	end
	
	initial
	begin
		clk <= 1'b0;
		block_enable <= 1'b0;
		slow_clk <= 1'b0;
		pdm_in <= 1'b0;
		output_counter <= 0;
		counter <= 4'b0;
		x_in <= $fopen("pdm_stimulus.txt","r");
		x_out <= $fopen("pdm_stimulus_out.txt","w");
	end 
	
	initial
	begin
		repeat(16) @(posedge clk);
		block_enable <= # clk_hold 1;
		while (!$feof(x_in))
		begin
			x_read <= # clk_hold $fscanf(x_in,"%d\n",pdm_in);
			@(posedge clk);
		end
		repeat(100) @(posedge clk);
		$fclose(x_in);
		$fclose(x_out);
		$stop;
	end


endmodule

