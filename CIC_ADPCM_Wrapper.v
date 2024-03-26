module CIC_ADPCM_Wrapper(
    input clk,          // Clock input
	input slow_clk,		// ADPCM clock (generate from Clock)
    input block_enable,   // Block enable input
    input pdm_in,   // 1 bit pdm input
    output outValid,            // Output valid signal
    output [3:0] encPcm // 4-bit pcm encoded output
);

reg clk_enable; // Clock enable input for CIC
reg rst; // Reset signal
reg inValid; // Input Valid signal for ADPCM encoder, set from clk_enable delayed
wire signed [15:0] filter_out;
reg signed [1:0] filter_in;



always @(*) begin
    filter_in = {(~pdm_in), 1'b1};
end

// State Machine for generating rst and clk_enable signals

// Enumerating states
  

`define IDLE	2'd0
`define TRANSITION	2'd1
`define COMPRESS	2'd2

// State register
reg [1:0] state, next_state;


//Initialize State Machine?
/* 
always @(posedge clk) begin
	if (block_enable)
		state <= `IDLE;
end
*/

// Next state logic
always @(*) begin
    case(state)
        `IDLE: begin
            if (block_enable)
                next_state = `TRANSITION;
            else
                next_state = `IDLE;
        end
        `TRANSITION: begin
            next_state = `COMPRESS;
        end
        `COMPRESS: begin
            if (!block_enable)
                next_state = `IDLE;
            else
                next_state = `COMPRESS;
        end
        default: next_state = `IDLE;
    endcase
end

// State transition
always @(posedge clk) begin
    state <= next_state;
end

// Output logic
always @(*) begin
    case(state)
        `IDLE: begin
            clk_enable = 0;
            rst = 1;
        end
        `TRANSITION: begin
            clk_enable = 0;
            rst = 0;
        end
        `COMPRESS: begin
            clk_enable = 1;
            rst = 0;
        end
        default: begin
            clk_enable = 0;
            rst = 1;
        end
    endcase
end





CICDecimatorVerilogBlock cic (
    .clk(clk),
    .clk_enable(clk_enable),
    .reset(rst),
    .filter_in(filter_in),
    .filter_out(filter_out),
    .ce_out(/* not used */)
    );


//Generating inValid signal for ADPCM, clk_enable delayed by 66 cycles
reg [6:0] counter;
reg oldValue;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        counter <= 7'b0;
		inValid <= 1'b0;
		oldValue <= 1'b0;
    end
	else if(counter >= 66) begin
		inValid <= oldValue;
		counter <= 1'b0;
	end
	else if(counter == 0) begin
		oldValue <= clk_enable;
		counter <= counter + 1;
	end
	else begin
		counter <= counter + 1;
	end
	
end




ima_adpcm_enc enc
(
	.clock(slow_clk), 
	.reset(rst), 
	.inSamp(filter_out), 
	.inValid(inValid),
	.inReady(/* inReady */),
	.outPCM(encPcm), 
	.outValid(outValid), 
	.outPredictSamp(/* not used */), 
	.outStepIndex(/* not used */) 
);



endmodule