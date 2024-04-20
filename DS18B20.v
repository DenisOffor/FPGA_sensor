module DS18B20
(
	inout					io_data,
	input 				i_clk,
	input 				i_btn,
	
	//output reg [71:0] r_ram_9byte,
	output				o_convertion_done
);
	parameter SKIP_ROM = 8'hCC;
	parameter CONVERT_T = 8'h44;
	parameter READ_T = 8'hBE;
	
	parameter COMMAND_IDLE_STATE 		= 4'b0001;
	parameter COMMAND_RESET_PULSE 	= 4'b0010;
	parameter COMMAND_CHECK_RESPOND 	= 4'b0011;
	parameter COMMAND_SEND_COMMAND 	= 4'b0100;
	parameter COMMAND_WAIT_750MS 		= 4'b0101;
	parameter COMMAND_READ_BYTES 		= 4'b0110;
	
	reg					i_rst = 0;
	reg		[16:0]	r_temperature;
	reg					r_convertion_done;
	reg		[3:0]		r_command_state;
	reg		[6:0]		r_timer_1us;
	reg		[20:0]	r_counter_of_1us;
	reg					r_io_data 			= 1'b1;
	reg					r_sensor_detected = 1'b0;
	reg		[7:0]		r_sended_command;
	reg					r_750ms_done;
	reg		[71:0]	r_ram_9byte;
	
	assign 				o_temperature 		= r_temperature;
	assign				o_convertion_done = r_convertion_done;
	assign				io_data 				= r_io_data;
	wire					w_1us_done 			= (r_timer_1us == 50 ? 1'b1 : 1'b0);
	wire					w_750ms_done		= (r_counter_of_1us == 750000 ? 1'b1: 1'b0);
	reg		[6:0] 	r_iter = 0;
	
	wire					w_button_state;
	reg		[3:0]		r_command_state_delay;
	
	always @(posedge i_clk or posedge i_rst) begin
		if(i_rst) begin
			r_convertion_done <= 0;
			r_temperature 		<= 0;
			r_timer_1us 		<= 0;
			r_counter_of_1us 	<= 0;
			r_sensor_detected <= 0;
			r_sended_command 	<= 0;
			r_750ms_done		<= 0;
			r_ram_9byte			<= 0;
			r_io_data 			<= 1'b1; //z
			r_iter 				<= 0;
			r_command_state 	<= COMMAND_IDLE_STATE;	
		end
		else begin
			if(r_timer_1us == 51)
				r_timer_1us <= 0;
			else
				r_timer_1us <= r_timer_1us + 1'b1;
				
			if(w_1us_done)
				r_counter_of_1us <= r_counter_of_1us + 1'b1;
				
			r_command_state_delay <= r_command_state;	
					
			case (r_command_state_delay) 
				COMMAND_IDLE_STATE: begin
					r_convertion_done <= 0;
					r_temperature 		<= 0;
					r_timer_1us 		<= 0;
					r_counter_of_1us 	<= 0;
					r_sensor_detected <= 0;
					r_sended_command 	<= 0;
					r_750ms_done		<= 0;
					r_io_data 			<= 1'b1;
					if(w_button_state) begin
						r_command_state <= COMMAND_RESET_PULSE;
					end
				end
				//////////////////////////////////////////////////////
				//////////////////////////////////////////////////////
				COMMAND_RESET_PULSE: begin
					if(r_counter_of_1us == 0) begin
						r_io_data 			<= 1'b0;
					end	
					else if(r_counter_of_1us == 480) begin
						r_command_state 	<= COMMAND_CHECK_RESPOND;
						r_counter_of_1us	<= 0;
						r_timer_1us 		<= 0;
						r_io_data 			<= 1'b1; //z
					end
				end
				//////////////////////////////////////////////////////
				//////////////////////////////////////////////////////
				COMMAND_CHECK_RESPOND: begin
					if(r_counter_of_1us == 100) begin
						if(io_data) begin
							r_sensor_detected <= 1'b1;
							//r_command_state 	<= COMMAND_IDLE_STATE;
						end
						else begin
							r_sensor_detected <= 1'b0;
						end
					end
						else if(r_counter_of_1us == 480) begin
							r_command_state 	<= COMMAND_SEND_COMMAND;
							r_sended_command 	<= SKIP_ROM;
							r_counter_of_1us	<= 0;
							r_timer_1us 		<= 0;
						end
				end
				//////////////////////////////////////////////////////
				//////////////////////////////////////////////////////
				COMMAND_SEND_COMMAND: begin
					if(r_counter_of_1us == 0 && r_iter != 8) begin
						r_io_data 			<= 1'b0;
					end
					if (r_counter_of_1us == 2) begin
						if((r_sended_command >> r_iter) & 2'h01)
							r_io_data 			<= 1'b1;
						else 
							r_io_data 			<= 1'b0;
					end
						else if(r_counter_of_1us == 60) begin
							r_io_data 			<= 1'b1;
							r_counter_of_1us	<= 0;
							r_timer_1us 		<= 0;
							r_iter 				<= r_iter + 1'b1;
						end
						
					if(r_iter == 8) begin
						r_iter <= 0;
						r_io_data 			<= 1'b1;
						r_counter_of_1us	<= 0;
						r_timer_1us 		<= 0;
						
						if((r_sended_command == SKIP_ROM) && (r_750ms_done == 0)) begin
							r_sended_command 	<= CONVERT_T; 
						end
						else if(r_sended_command == CONVERT_T) begin
							r_command_state	<= COMMAND_WAIT_750MS;
						end
						else if((r_sended_command == SKIP_ROM) && (r_750ms_done == 1)) begin
							r_sended_command 	<= READ_T; 
						end
						else if(r_sended_command == READ_T) begin
							r_command_state	<= COMMAND_READ_BYTES;
						end
					end
				end
				////////////////////////////////////////////////////////
				////////////////////////////////////////////////////////								
				COMMAND_WAIT_750MS: begin
					if(w_750ms_done) begin
						r_750ms_done		<= 1'b1;
						r_counter_of_1us	<= 0;
						r_timer_1us 		<= 0;
						r_command_state 	<= COMMAND_RESET_PULSE;
					end
				end
				//////////////////////////////////////////////////////////
				//////////////////////////////////////////////////////////

				//////////////////////////////////////////////////////////
				//////////////////////////////////////////////////////////				
				COMMAND_READ_BYTES: begin
					if(r_counter_of_1us == 0) begin
						r_io_data 			<= 1'b0;//Z
					end
					if (r_counter_of_1us == 30) begin
						r_ram_9byte[r_iter] <= io_data;
					end
						else if(r_counter_of_1us == 60) begin
							r_counter_of_1us	<= 0;
							r_timer_1us 		<= 0;
							r_iter <= r_iter + 1'b1;
						end
					if(r_iter == 72) begin
						r_command_state 		<= COMMAND_IDLE_STATE;
						r_convertion_done 	<= 1'b1;
					end
				end
				//////////////////////////////////////////////////////
				//////////////////////////////////////////////////////
				default: begin
					r_convertion_done <= 0;
					r_temperature 		<= 0;
					r_timer_1us			<= 0;
					r_counter_of_1us 	<= 0;
					r_sensor_detected <= 0;
					r_sended_command 	<= 0;
					r_750ms_done		<= 0;
					r_ram_9byte			<= 0;
					r_io_data 			<= 1'b1; //z
					r_command_state 	<= COMMAND_IDLE_STATE;		
				end
			endcase
		end
	end
	
	debouncer my_debouncer(
		.clk(i_clk), 
		.button(~i_btn), 
		.button_state(w_button_state)
	);
endmodule