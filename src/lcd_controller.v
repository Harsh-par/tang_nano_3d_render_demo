/*
    controller to handle the initialization and writing pixels to lcd
    
    OUTPUT lcd_clock, lcd_reset, lcd_chip_select, lcd_data_command, lcd_mosi : connected to physical pin lcd
    
    INPUT pixel_data   : 16 bit pixel rgb value
    INPUT pixel_valid  : signal to let lcd controller know pixel_data is valid
    OUTPUT pixel_ready : signal to let outer module know lcd_controller is ready to receive pixel
*/
module lcd_controller
(
	input clock,
	input reset,

	output lcd_clock,
	output lcd_reset,
	output lcd_chip_select,
	output lcd_data_command,
	output lcd_data,

	input [15:0] pixel_data,
	input pixel_valid, 
	output pixel_ready 
);
    
    // registers used to hold pixels and current transmitting state
	reg [15:0] pixel_buffer;
    reg [1:0] pixel_transmit_state;

	assign pixel_ready = (current_state == LCD_WRITE) && (pixel_transmit_state == 0);
    
	// registers/wires used to interface lcd_initialize module
	reg [6:0] lcd_command_index_init = 0;
	wire lcd_data_command_init;
	wire [7:0] lcd_data_init;

	lcd_lut lcd_lut_inst
	(
		.initialization_command_index(lcd_command_index_init),
		.lcd_data_command(lcd_data_command_init),
		.lcd_data(lcd_data_init)
	);

	// registers/wires used to interface spi_master module
	reg spi_start;
	wire spi_done;
	reg data_command;
	reg [7:0] data;

	spi_master spi_master_inst
	(
		.clock(clock),
		.reset(reset),
		.data_command(data_command),
		.data(data),
		.spi_transaction_start(spi_start),
		.spi_transaction_done(spi_done),
		.spi_clock(lcd_clock),
		.spi_reset(lcd_reset),
		.spi_chip_select(lcd_chip_select),
		.spi_data_command(lcd_data_command),
		.spi_mosi(lcd_data)
	);
            
	localparam TOTAL_LCD_COMMANDS = 70;

	reg [2:0] current_state = LCD_IDLE;
    
	localparam LCD_IDLE           = 0;
	localparam LCD_RESET_WAIT     = 1;
	localparam LCD_WAKEUP_COMMAND = 2;
	localparam LCD_WAKEUP_WAIT    = 3;
	localparam LCD_INITIALIZE     = 4;
	localparam LCD_WRITE          = 5;

	localparam LCD_DELAY_120_MS = 9720000;
	reg [23:0] lcd_delay_counter;

	always @(posedge clock or negedge reset) begin
		if (!reset) begin
			current_state          <= LCD_IDLE;
			lcd_delay_counter      <= 0;
			lcd_command_index_init <= 0;
			spi_start              <= 0;
			data_command           <= 0;
			data                   <= 0;
			pixel_buffer           <= 0;
            pixel_transmit_state   <= 0;
		end else begin
			case (current_state)

				LCD_IDLE: begin
					lcd_delay_counter 	   <= 0;
					lcd_command_index_init <= 0;
					spi_start         	   <= 0;
                    pixel_transmit_state   <= 0;

					current_state <= LCD_RESET_WAIT;
				end

				LCD_RESET_WAIT: begin
					if (lcd_delay_counter < LCD_DELAY_120_MS) begin
						lcd_delay_counter <= lcd_delay_counter + 1;
					end else begin
						lcd_delay_counter <= 0;
						
						current_state <= LCD_WAKEUP_COMMAND;
					end
				end

				LCD_WAKEUP_COMMAND: begin
					if (!spi_done && !spi_start) begin
						data_command <= 0;     
						data         <= 8'h11; 
						spi_start    <= 1;
					end else begin
						spi_start    <= 0; 
					end

					if (spi_done) begin
						current_state <= LCD_WAKEUP_WAIT;
					end
				end

				LCD_WAKEUP_WAIT: begin
					if (lcd_delay_counter < LCD_DELAY_120_MS) begin
						lcd_delay_counter <= lcd_delay_counter + 1;
					end else begin
						lcd_delay_counter <= 0;

						current_state <= LCD_INITIALIZE;
					end
				end

				// state to initialize the display with all the commands
				// from the lcd_initialize look up table
				LCD_INITIALIZE: begin
					if (!spi_done && !spi_start) begin
						data_command <= lcd_data_command_init;
						data    	 <= lcd_data_init;
						spi_start    <= 1;
					end 
					else spi_start <= 0; 
				

					if (spi_done) begin
						lcd_command_index_init <= lcd_command_index_init + 1;

						if (lcd_command_index_init == TOTAL_LCD_COMMANDS - 1) current_state <= LCD_WRITE;
					end
				end

				// state to write pixels to display, sends msb then lsb
                LCD_WRITE: begin
                    spi_start <= 0; 
                    
                    case (pixel_transmit_state)
                        0: begin
                            if (pixel_valid) begin
                                pixel_buffer <= pixel_data;
                                data         <= pixel_data[15:8]; 
                                data_command <= 1; 
                                spi_start    <= 1;

                                pixel_transmit_state <= 1;
                            end
                        end
                        1: begin 
                            if (spi_done) begin
                                data         <= pixel_buffer[7:0]; 
                                data_command <= 1;
                                spi_start    <= 1;

                                pixel_transmit_state <= 2; 
                            end
                        end
                        2: begin 
                            if (spi_done) begin
                                pixel_transmit_state <= 0;
                            end
                        end
                    endcase
                end

			endcase

		end

	end

endmodule