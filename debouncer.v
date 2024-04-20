module debouncer(
	input clk, 
	input button, 
	output reg button_state
);
	reg [5:0] counter;
	wire change_state = button ^ button_state;	
	wire max_cnt = &counter;
	
	initial begin
		counter <= 0;
		button_state <= 0;
	end
	
	always @(posedge clk)
	begin
		if(change_state) begin
			counter <= counter + 1'b1;
			if(max_cnt)  begin
				counter <= 0;
				button_state <= ~button_state;
			end
		end		
		else
			counter <= 0;
	end
endmodule
