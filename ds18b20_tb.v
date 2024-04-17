module ds18b20_tb
(
		inout			io_data
);
	reg clk;
	reg rst;
	reg start;
	
	initial begin
		#0 clk <= 1'b0;
		#0 rst <= 1'b1;
		#0 start <= 1'b0;
		#300 rst <= 1'b0;
		#50 start <= 1'b1;
		#400 start <= 1'b0;
	end
	
	always @(*)
		#100	clk <= ~clk;
	
	DS18B20	my_DS18B20
	(
		.io_data(io_data),
		.i_clk(clk),
		.i_rst(rst),
		.i_start(start),
		
		.o_convertion_done(),
		.o_temperature()		
	);
endmodule
