module DS18B20
(
	inout					io_data,
	input 				i_clk,
	input					i_rst,
	input					i_start,
	
	output				o_convertion_done,
	output 	[16:0]	o_temperature		
);
	parameter SKIP_ROM = 2'hCC;
	parameter CONVERT_T = 2'h44;
	parameter READ_T = 2'hBE;
	
	parameter COMMAND_IDLE_STATE 		= 4'b0001;
	parameter COMMAND_RESET_PULSE 	= 4'b0010;
	parameter COMMAND_CHECK_RESPOND 	= 4'b0011;
	parameter COMMAND_SEND_SKIP_ROM 	= 4'b0100;
	parameter COMMAND_SEND_CONVERT_T = 4'b0101;
		
	parameter COMMAND_SENSOR_NOT_DETECTED = 1'd9;
		
	reg		[16:0]	r_temperature;
	reg					r_convertion_done;
	reg		[3:0]		r_command_state;
	reg		[6:0]		r_timer_1us;
	reg		[10:0]	r_counter_of_1us;
	reg					r_io_data 			= 1'b1; //z
	reg					r_sensor_detected = 1'b0;
	
	assign 				o_temperature 		= r_temperature;
	assign				o_convertion_done = r_convertion_done;
	assign				io_data 				= r_io_data;
	wire					w_1us_done 			= (r_timer_1us == 50 ? 1'b1 : 1'b0);
	
	always @(posedge i_clk or posedge i_rst) begin
		if(i_rst) begin
			r_convertion_done <= 0;
			r_temperature 		<= 0;
			r_timer_1us 		<= 0;
			r_counter_of_1us 	<= 0;
			r_sensor_detected <= 0;
			r_io_data 			<= 1'b1; //z
			r_command_state 	<= COMMAND_IDLE_STATE;	
		end
		else begin
			if(r_timer_1us == 51)
				r_timer_1us <= 0;
			else
				r_timer_1us <= r_timer_1us + 1'b1;
				
			case (r_command_state)
				COMMAND_IDLE_STATE: begin
					r_convertion_done <= 0;
					r_temperature 		<= 0;
					r_timer_1us 		<= 0;
					r_counter_of_1us 	<= 0;
					r_sensor_detected <= 0;
					r_io_data 			<= 1'b1; //z
					if(i_start) begin
						r_command_state <= COMMAND_RESET_PULSE;
						r_io_data 			<= 1'b0;
					end
				end
				//////////////////////////////////////////////////////
				//////////////////////////////////////////////////////
				COMMAND_RESET_PULSE: begin
					if(r_counter_of_1us == 480) begin
						r_command_state 	<= COMMAND_CHECK_RESPOND;
						r_counter_of_1us	<= 0;
						r_io_data 			<= 1'b1; //z
					end
						else if(w_1us_done) begin
							r_counter_of_1us <= r_counter_of_1us + 1'b1;
						end
				end
				//////////////////////////////////////////////////////
				//////////////////////////////////////////////////////
				COMMAND_CHECK_RESPOND: begin
					if(r_counter_of_1us == 100) begin
						if(io_data)
							r_sensor_detected <= 1'b1;
						else begin
							r_sensor_detected <= 1'b0;
							r_command_state 	<= COMMAND_SENSOR_NOT_DETECTED;
						end
					end
						else if(r_counter_of_1us == 480) begin
							r_command_state 	<= COMMAND_SEND_SKIP_ROM;
							r_counter_of_1us	<= 0;
						end
							else if(w_1us_done) begin
								r_counter_of_1us <= r_counter_of_1us + 1'b1;
							end
				end
				//////////////////////////////////////////////////////
				//////////////////////////////////////////////////////
				COMMAND_SEND_SKIP_ROM: begin

				end
				//////////////////////////////////////////////////////
				//////////////////////////////////////////////////////
				default: begin
					r_convertion_done <= 0;
					r_temperature 		<= 0;
					r_timer_1us			<= 0;
					r_counter_of_1us 	<= 0;
					r_sensor_detected <= 0;
					r_io_data 			<= 1'b1; //z
					r_command_state 	<= COMMAND_IDLE_STATE;		
				end
			endcase
		end
	end
endmodule