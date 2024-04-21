module ds18b20_tb
(
		inout			io_data
);
	reg clk;
	reg start;
	
	initial begin
		#0 clk <= 1'b0;
		#0 start <= 1'b0;
		#50 start <= 1'b1;
		#40000 start <= 1'b0;
	end
	
	always @(*)
		#100	clk <= ~clk;
	
	DS18B20	my_DS18B20
	(
		.io_data(io_data),
		.i_clk(clk),
		.i_btn(start)
	);
endmodule
