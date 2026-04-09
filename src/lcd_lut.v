/*
    look up table which stores all the commands needed to initialize lcd screen
    
    INPUT initialization_command_index : index which selects specific command to output, commands are in order

    OUTPUT lcd_data_command : single bit, which tells is used with spi to tell lcd screen if byte is data or command
    OUTPUT lcd_data         : single byte, data for lcd
*/
module lcd_lut
(
	input wire [6:0] initialization_command_index,

	output wire 	  lcd_data_command,
	output wire [7:0] lcd_data
);

	localparam TOTAL_LCD_COMMANDS = 70;

	wire [8:0] lcd_init_commands[TOTAL_LCD_COMMANDS-1:0];

	// lcd_initialization commands taken from sipeed tang nano 9k github
	// https://github.com/sipeed/TangNano-9K-example/tree/main/spi_lcd

	assign lcd_init_commands[ 0] = 9'h036;
	assign lcd_init_commands[ 1] = 9'h170;
	assign lcd_init_commands[ 2] = 9'h03A;
	assign lcd_init_commands[ 3] = 9'h105;
	assign lcd_init_commands[ 4] = 9'h0B2;
	assign lcd_init_commands[ 5] = 9'h10C;
	assign lcd_init_commands[ 6] = 9'h10C;
	assign lcd_init_commands[ 7] = 9'h100;
	assign lcd_init_commands[ 8] = 9'h133;
	assign lcd_init_commands[ 9] = 9'h133;
	assign lcd_init_commands[10] = 9'h0B7;
	assign lcd_init_commands[11] = 9'h135;
	assign lcd_init_commands[12] = 9'h0BB;
	assign lcd_init_commands[13] = 9'h119;
	assign lcd_init_commands[14] = 9'h0C0;
	assign lcd_init_commands[15] = 9'h12C;
	assign lcd_init_commands[16] = 9'h0C2;
	assign lcd_init_commands[17] = 9'h101;
	assign lcd_init_commands[18] = 9'h0C3;
	assign lcd_init_commands[19] = 9'h112;
	assign lcd_init_commands[20] = 9'h0C4;
	assign lcd_init_commands[21] = 9'h120;
	assign lcd_init_commands[22] = 9'h0C6;
	assign lcd_init_commands[23] = 9'h10F;
	assign lcd_init_commands[24] = 9'h0D0;
	assign lcd_init_commands[25] = 9'h1A4;
	assign lcd_init_commands[26] = 9'h1A1;
	assign lcd_init_commands[27] = 9'h0E0;
	assign lcd_init_commands[28] = 9'h1D0;
	assign lcd_init_commands[29] = 9'h104;
	assign lcd_init_commands[30] = 9'h10D;
	assign lcd_init_commands[31] = 9'h111;
	assign lcd_init_commands[32] = 9'h113;
	assign lcd_init_commands[33] = 9'h12B;
	assign lcd_init_commands[34] = 9'h13F;
	assign lcd_init_commands[35] = 9'h154;
	assign lcd_init_commands[36] = 9'h14C;
	assign lcd_init_commands[37] = 9'h118;
	assign lcd_init_commands[38] = 9'h10D;
	assign lcd_init_commands[39] = 9'h10B;
	assign lcd_init_commands[40] = 9'h11F;
	assign lcd_init_commands[41] = 9'h123;
	assign lcd_init_commands[42] = 9'h0E1;
	assign lcd_init_commands[43] = 9'h1D0;
	assign lcd_init_commands[44] = 9'h104;
	assign lcd_init_commands[45] = 9'h10C;
	assign lcd_init_commands[46] = 9'h111;
	assign lcd_init_commands[47] = 9'h113;
	assign lcd_init_commands[48] = 9'h12C;
	assign lcd_init_commands[49] = 9'h13F;
	assign lcd_init_commands[50] = 9'h144;
	assign lcd_init_commands[51] = 9'h151;
	assign lcd_init_commands[52] = 9'h12F;
	assign lcd_init_commands[53] = 9'h11F;
	assign lcd_init_commands[54] = 9'h11F;
	assign lcd_init_commands[55] = 9'h120;
	assign lcd_init_commands[56] = 9'h123;
	assign lcd_init_commands[57] = 9'h021;
	assign lcd_init_commands[58] = 9'h029;
	assign lcd_init_commands[59] = 9'h02A; 
	assign lcd_init_commands[60] = 9'h100;
	assign lcd_init_commands[61] = 9'h128;
	assign lcd_init_commands[62] = 9'h101;
	assign lcd_init_commands[63] = 9'h117;
	assign lcd_init_commands[64] = 9'h02B; 
	assign lcd_init_commands[65] = 9'h100;
	assign lcd_init_commands[66] = 9'h135;
	assign lcd_init_commands[67] = 9'h100;
	assign lcd_init_commands[68] = 9'h1BB;
	assign lcd_init_commands[69] = 9'h02C; 

	assign lcd_data_command = lcd_init_commands[initialization_command_index][8];
	assign lcd_data         = lcd_init_commands[initialization_command_index][7:0];

endmodule