/*
    module that does all the math calculations/transformations on the 3d cube

    INPUT pixel_x, pixel_y : x and y location of pixel on the lcd screen

    INPUT angle_x, angle_y : rotation transformations done on 3d cube

    INPUT position_x, position_y : translation transformations done on 3d cube

    OUTPUT render_pixel : signal to tell outer module if current x, y location should be rendered
*/
module cube_renderer 
(
    input wire [7:0] pixel_x, 
    input wire [7:0] pixel_y,

    input wire [7:0] angle_x,
    input wire [7:0] angle_y,
    
    input wire signed [15:0] position_x,
    input wire signed [15:0] position_y,

    output wire render_pixel
);

    // wires for the sine and cosine values from look up tables
    wire signed [15:0] sin_x, cos_x;
    wire signed [15:0] sin_y, cos_y;

    angle_lut #(.SCALE(1)) angle_lut_x 
    (
        .angle(angle_x), 
        .cosine_value(cos_x), 
        .sine_value(sin_x)
    );

    angle_lut #(.SCALE(1)) angle_lut_y 
    (
        .angle(angle_y), 
        .cosine_value(cos_y), 
        .sine_value(sin_y)
    );

    
    // 8 vertices of a cube in 3d space
    wire signed [7:0] vertex_x [0:7];
    wire signed [7:0] vertex_y [0:7];
    wire signed [7:0] vertex_z [0:7];

    assign vertex_x[0] =  8'sd1; assign vertex_y[0] =  8'sd1; assign vertex_z[0] =  8'sd1;
    assign vertex_x[1] =  8'sd1; assign vertex_y[1] =  8'sd1; assign vertex_z[1] = -8'sd1;
    assign vertex_x[2] =  8'sd1; assign vertex_y[2] = -8'sd1; assign vertex_z[2] =  8'sd1;
    assign vertex_x[3] =  8'sd1; assign vertex_y[3] = -8'sd1; assign vertex_z[3] = -8'sd1;
    assign vertex_x[4] = -8'sd1; assign vertex_y[4] =  8'sd1; assign vertex_z[4] =  8'sd1;
    assign vertex_x[5] = -8'sd1; assign vertex_y[5] =  8'sd1; assign vertex_z[5] = -8'sd1;
    assign vertex_x[6] = -8'sd1; assign vertex_y[6] = -8'sd1; assign vertex_z[6] =  8'sd1;
    assign vertex_x[7] = -8'sd1; assign vertex_y[7] = -8'sd1; assign vertex_z[7] = -8'sd1;

    wire signed [15:0] screen_x [0:7];
    wire signed [15:0] screen_y [0:7];
    
    genvar v;
    generate
        for (v = 0; v < 8; v = v + 1) begin : rotation_calculation
            wire signed [15:0] vx = vertex_x[v];
            wire signed [15:0] vy = vertex_y[v];
            wire signed [15:0] vz = vertex_z[v];

            // check sign of vertex to obtain signed cosine/sine value
            wire signed [15:0] vx_cos_y = (vx > 0) ? cos_y : -cos_y;
            wire signed [15:0] vz_sin_y = (vz > 0) ? sin_y : -sin_y;
            wire signed [15:0] vx_sin_y = (vx > 0) ? sin_y : -sin_y;
            wire signed [15:0] vz_cos_y = (vz > 0) ? cos_y : -cos_y;
            
            // rotation around y axis
            //
            // x' = vx * cos(y) - vz * sin(y)
            // z' = vx * sin(y) - vz * cos(y)
            // y' = vy
            wire signed [15:0] x_prime = vx_cos_y - vz_sin_y;
            wire signed [15:0] z_prime = vx_sin_y + vz_cos_y; 
            wire signed [15:0] y_prime = (vy > 0) ? 16'sd127 : -16'sd127;

            // rotation around x axis
            // 
            // x'' = x'
            // y'' = y' * cos(x) - z' * sin(x)
            // arithmetic shift >>> 7 to scale back to 127

            // trying to get both values to fit in 18x18 dsp
            wire signed [8:0] z_prime_9bit = z_prime[8:0];
            wire signed [8:0] sin_x_9bit   = sin_x[8:0];

            wire signed [17:0] y_prime_cos_x = y_prime * cos_x;
            wire signed [17:0] z_prime_sin_x = z_prime_9bit * sin_x_9bit;

            wire signed [15:0] y_primedge2 = (y_prime_cos_x - z_prime_sin_x) >>> 7;
            wire signed [15:0] x_primedge2 = x_prime; 

            localparam signed [17:0] CUBE_SIZE = 28; 

            // projecting to 2d screen
            //
            // calculating the x/y rotation offsets then adding to x/y position
            wire signed [17:0] x_primedge2_size = x_primedge2 * CUBE_SIZE;
            wire signed [17:0] y_primedge2_size = y_primedge2 * CUBE_SIZE;

            // scaling down so it can fit on lcd screen
            wire signed [15:0] rotation_offset_x = x_primedge2_size >>> 7;
            wire signed [15:0] rotation_offset_y = y_primedge2_size >>> 7;

            assign screen_x[v] = rotation_offset_x + position_x;
            assign screen_y[v] = rotation_offset_y + position_y;
        end
    endgenerate


    // 12 edges of a cube in 3d space
    wire [2:0] edge1 [0:11];
    wire [2:0] edge2 [0:11];
    
    // assigning vertices to connect edges
    assign edge1[0] = 0; assign edge2[0] = 4;
    assign edge1[1] = 1; assign edge2[1] = 5;
    assign edge1[2] = 2; assign edge2[2] = 6;
    assign edge1[3] = 3; assign edge2[3] = 7;
    assign edge1[4] = 0; assign edge2[4] = 2;
    assign edge1[5] = 1; assign edge2[5] = 3;
    assign edge1[6] = 4; assign edge2[6] = 6;
    assign edge1[7] = 5; assign edge2[7] = 7;
    assign edge1[8] = 0; assign edge2[8] = 1;
    assign edge1[9] = 2; assign edge2[9] = 3;
    assign edge1[10]= 4; assign edge2[10]= 5;
    assign edge1[11]= 6; assign edge2[11]= 7;

    // increasing the size of pixel x/y so no overflows during calculations
    wire signed [8:0] pixel_x_9bit = {1'b0, pixel_x};
    wire signed [8:0] pixel_y_9bit = {1'b0, pixel_y};

    wire [11:0] draw_line;
    
    genvar e;
    generate
        for (e = 0; e < 12; e = e + 1) begin : edge_math
            // each edge has two x/y points representing the vertices
            wire signed [15:0] x1 = screen_x[edge1[e]];
            wire signed [15:0] y1 = screen_y[edge1[e]];
            wire signed [15:0] x2 = screen_x[edge2[e]];
            wire signed [15:0] y2 = screen_y[edge2[e]];
            
            wire signed [8:0] x1_9bit = x1[8:0];
            wire signed [8:0] y1_9bit = y1[8:0];
            wire signed [8:0] x2_9bit = x2[8:0];
            wire signed [8:0] y2_9bit = y2[8:0];

            // the distance between two vertices is used to draw length of the edge
            wire signed [8:0] delta_x = x2_9bit - x1_9bit;
            wire signed [8:0] delta_y = y2_9bit - y1_9bit;

            // vector from one pixel to a vertex
            wire signed [8:0] pixel_vector_x = pixel_x_9bit - x1_9bit;
            wire signed [8:0] pixel_vector_y = pixel_y_9bit - y1_9bit;

            // calculating the cross product between two vectors, also area of a parallelogram
            wire signed [17:0] cross_product1 = delta_x * pixel_vector_y;
            wire signed [17:0] cross_product2 = delta_y * pixel_vector_x;
            wire signed [17:0] cross_product = cross_product1 - cross_product2;
            wire signed [17:0] abs_cross_product = cross_product[17] ? -cross_product : cross_product;
            
            // check signed bit and create new wire for absolute value of delta_x/y
            wire signed [9:0] abs_delta_x = delta_x[8] ? -delta_x : delta_x;
            wire signed [9:0] abs_delta_y = delta_y[8] ? -delta_y : delta_y;

            // using absolute values of delta_x/y we can estimate how long line is
            wire signed [9:0] thickness_threshold = abs_delta_x + abs_delta_y;
            
            // calculating the bounds
            wire signed [8:0] minimum_x = (x1_9bit < x2_9bit) ? x1_9bit : x2_9bit;
            wire signed [8:0] maximum_x = (x1_9bit > x2_9bit) ? x1_9bit : x2_9bit;
            wire signed [8:0] minimum_y = (y1_9bit < y2_9bit) ? y1_9bit : y2_9bit;
            wire signed [8:0] maximum_y = (y1_9bit > y2_9bit) ? y1_9bit : y2_9bit;
            
            // check if inside bounding box
            wire inside_bounding_box = (pixel_x_9bit >= minimum_x) && (pixel_x_9bit <= maximum_x) && (pixel_y_9bit >= minimum_y) && (pixel_y_9bit <= maximum_y);
            
            // Combine bounds and line thickness checks
            assign draw_line[e] = inside_bounding_box && (abs_cross_product <= thickness_threshold);
        end
    endgenerate

    // if atleast one bit in draw_line is 1, then render_pixel is high
    assign render_pixel = (|draw_line);

endmodule