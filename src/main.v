module main
(
    input clock,
    input reset,
    
    input button,

    output lcd_clock,
    output lcd_reset,
    output lcd_chip_select,
    output lcd_data_command,
    output lcd_data
);


    // using the gowin ip generator to generate a pll ip
    wire clock_80mhz;

    Gowin_rPLL pll_inst
    (
        .clkin(clock),
        .clkout(clock_80mhz)
    );


    // signals/registers used to send pixels to lcd controller
    reg [15:0] pixel_data = 0;
    reg  pixel_valid;
    wire pixel_ready;
    
    lcd_controller lcd_controller_inst
    (
        .clock(clock_80mhz),
        .reset(reset),
        .lcd_clock(lcd_clock),
        .lcd_reset(lcd_reset),
        .lcd_chip_select(lcd_chip_select),
        .lcd_data_command(lcd_data_command),
        .lcd_data(lcd_data),
        .pixel_data(pixel_data),
        .pixel_valid(pixel_valid),
        .pixel_ready(pixel_ready)
    );


    // signals/wires used to change color of cube/background and control speed of color changing
    wire [15:0] color_cube;
    wire [15:0] color_background;

    reg [7:0] hue_counter_cube = 0;
    reg [7:0] hue_counter_background = 127;

    reg [3:0] hue_divider = 0;

    rgb_lut rgb_lut_inst0
    (
        .hue(hue_counter_cube),
        .rgb(color_cube)
    );

    rgb_lut rgb_lut_inst1
    (
        .hue(hue_counter_background),
        .rgb(color_background)
    );
    

    localparam LCD_SCREEN_WIDTH  = 240;
    localparam LCD_SCREEN_HEIGHT = 135;
    

    // wile 3d cube is moving x/y positions these boundaries are checked to change x/y direction
    localparam WIDTH_X1  = 45;
    localparam WIDTH_X2  = 195;
    localparam HEIGHT_Y1 = 47;
    localparam HEIGHT_Y2 = 77;


    // next x/y pixel is updated based on if the current x/y pixel has reached the screens width/height
    reg [7:0] current_pixel_x;
    reg [7:0] current_pixel_y;

    wire [7:0] next_pixel_x = (current_pixel_x == LCD_SCREEN_WIDTH - 1) ? 0 : current_pixel_x + 1;
    wire [7:0] next_pixel_y = (current_pixel_x == LCD_SCREEN_WIDTH - 1) ? ((current_pixel_y == LCD_SCREEN_HEIGHT - 1) ? 0 : current_pixel_y + 1) : current_pixel_y;


    // end of frame is used to ensure certain updates only occur once a frame
    wire end_of_line  = (current_pixel_x == LCD_SCREEN_WIDTH - 1 && pixel_ready);
    wire end_of_frame = (current_pixel_x == LCD_SCREEN_WIDTH - 1 && current_pixel_y == LCD_SCREEN_HEIGHT - 1 && pixel_ready);


    // registers used to perform transformations on 3d cube like rotate/translate/bounce
    reg [7:0] angle_x = 0;
    reg [7:0] angle_y = 0;

    reg [1:0] angle_divider = 0;

    reg signed [15:0] position_x = 120;
    reg signed [15:0] position_y = 67;
    
    reg direction_x = 0;
    reg direction_y = 0;

    wire render_pixel;

    cube_renderer cube_renderer_inst
    (
        .pixel_x(current_pixel_x),
        .pixel_y(current_pixel_y),
        .angle_x(angle_x),
        .angle_y(angle_y),
        .position_x(position_x),
        .position_y(position_y),
        .render_pixel(render_pixel)
    );

    
    // updates angle, position, direction and color of rendered cube
    always @(posedge clock_80mhz or negedge reset) begin
        if (!reset) begin
            angle_x <= 0;
            angle_y <= 0;

            position_x <= 120;
            position_y <= 67;

            direction_x <= 0;
            direction_y <= 0;

            hue_counter_background <= 127;
            hue_counter_cube       <= 0;
        end else begin 

            if (end_of_frame) begin
      
                if (direction_x == 0) begin
                    if (position_x >= WIDTH_X2) 
                        direction_x <= 1; 
                    else 
                        position_x <= position_x + 1;
                end else begin
                    if (position_x <= WIDTH_X1) 
                        direction_x <= 0; 
                    else 
                        position_x <= position_x - 1;
                end

                if (direction_y == 0) begin
                    if (position_y >= HEIGHT_Y2) 
                        direction_y <= 1; 
                    else 
                        position_y <= position_y + 1;
                end else begin 
                    if (position_y <= HEIGHT_Y1) 
                        direction_y <= 0; 
                    else 
                        position_y <= position_y - 1;
                end
               
                angle_divider <= angle_divider + 1;

                if(angle_divider == 0) begin
                    angle_y <= angle_y + 1;
                    angle_x <= angle_x + 1;
                end
                
                hue_divider <= hue_divider + 1;

                if(hue_divider == 0) begin
                    hue_counter_cube <= hue_counter_cube + 1;
                    hue_counter_background <= hue_counter_background + 1;
                end
            end
        end 
    end 
    
    
    // updates current pixel x/y location and colors cube/background
    always @(posedge clock_80mhz or negedge reset) begin
        if (!reset) begin
            current_pixel_x <= 0;
            current_pixel_y <= 0;

            pixel_valid <= 0;
            pixel_data  <= 0;
        end else begin
            pixel_valid <= 1; 

            if (pixel_ready) begin
                if (render_pixel) begin
                    pixel_data <= color_cube; 
                end
                else pixel_data <= color_background; 

                current_pixel_x <= next_pixel_x;
                current_pixel_y <= next_pixel_y;
            end
        end
    end

endmodule