/*
    spi master which is used to communicate to lcd and send bytes for initialization / writing pixels
    
    INPUT data_command : bit that tells spi master if incoming byte is data or command
    INPUT data         : byte which will be sent to lcd
    
    INPUT spi_transaction_start : signal to tell spi master to begin spi transaction
    OUTPUT spi_transaction_done : signal to tell outer module spi transaction is complete

    OUTPUT spi_clock, spi_reset, spi_chip_select, spi_data_command, spi_mosi : connected to physical pin lcd
*/
module spi_master
(
	input clock,
	input reset,
	input data_command,
	input [7:0] data,
    
    input  spi_transaction_start,
    output reg spi_transaction_done,

	output spi_clock,
	output spi_reset,
	output spi_chip_select,
	output spi_data_command,
	output spi_mosi
);
	
	assign spi_clock = ~clock;
  
    // registers to hold the spi outputs
	reg spi_reset_register; 
	reg spi_chip_select_register;
	reg spi_data_command_register;
	reg [7:0] spi_mosi_register;

	// assigning registers to the output spi ports
	assign spi_reset 	    = spi_reset_register;
	assign spi_chip_select  = spi_chip_select_register;
	assign spi_data_command = spi_data_command_register;
	assign spi_mosi         = spi_mosi_register[7];

	// counter to count how many bits in a 
	// byte have been sent so far
	reg [3:0] spi_bit_counter = 0;
    
    // spi master sends one byte at a time, setting chip select low to begin 
    // transaction and high to complete the transaction
	always @(posedge clock or negedge reset) begin
    	if (!reset) begin
            spi_reset_register        <= 0;
            spi_chip_select_register  <= 1;
            spi_data_command_register <= 0;
            spi_mosi_register         <= 0;
            spi_bit_counter           <= 0;
            spi_transaction_done      <= 0;
        end else begin

            spi_reset_register <= 1;
            
            // begin spi transaction, the mosi register will shift 1 bit per clock cycle
            // until the entire byte has been sent over spi
			if ((spi_transaction_start || spi_bit_counter > 0) && !spi_transaction_done) begin
				if (spi_bit_counter == 0) begin
					spi_chip_select_register  <= 0;
					spi_data_command_register <= data_command;
					spi_mosi_register 		  <= data;
                    spi_transaction_done      <= 0;

					spi_bit_counter <= spi_bit_counter + 1;
				end else if(spi_bit_counter < 8) begin
					spi_mosi_register <= spi_mosi_register << 1;

					spi_bit_counter <= spi_bit_counter + 1;
				end else begin
					spi_chip_select_register <= 1;
                    spi_transaction_done     <= 1;
            
					spi_bit_counter <= 0;
				end
			end 
			else begin
				spi_chip_select_register <= 1;
                spi_transaction_done     <= 0;
                
				spi_bit_counter <= 0;
			end

        end

	end

endmodule