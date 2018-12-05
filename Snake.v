module Snake(start, master_clk, KB_clk, data, DAC_clk, VGA_R, VGA_G, VGA_B, VGA_hSync, VGA_vSync, blank_n);
	
	input master_clk, KB_clk, data; 
	output reg [7:0]VGA_R, VGA_G, VGA_B;  //Red, Green, Blue VGA signals
	output VGA_hSync, VGA_vSync, DAC_clk, blank_n; //Horizontal and Vertical sync signals
	wire [9:0] xcounter; //x pixel
	wire [9:0] ycounter; //y pixel
	reg [9:0] appleX;
	reg [8:0] appleY;
	wire [9:0]Xrandom;
	wire [8:0]Yrandom;
	wire displayArea;
	wire clockVGA; 
	wire R;
	wire G;
	wire B;
	wire [4:0] direction;
	wire lethal, nonLethal;
	reg bad_collision, good_collision, gameover;
	reg appleinputX, appleinputY, apple, border, found; 
	integer appleCount, count1, count2, count3;
	reg [6:0] size;
	input start;
	reg [9:0] snakeX[0:127];   //changed from 127 to 199 - see line97
	reg [8:0] snakeY[0:127]; 
	reg [9:0] snakeHeadX;
	reg [9:0] snakeHeadY;
	reg snakeHead;
	reg snakeBody;
	wire update, reset;
	integer maxSize = 16;  //changed from 16 to 25
	

	clk_reduce reduce1(master_clk, clockVGA); 
	
	VGA_gen gen1(clockVGA, xcounter, ycounter, displayArea, VGA_hSync, VGA_vSync, blank_n);
	
	
	randomGrid rand1(clockVGA, Xrandom, Yrandom);
	
	kbInput kbIn(KB_clk, data, direction, reset);
	
	updateClk UPDATE(master_clk, update);
	
	assign DAC_clk = clockVGA;
	//
	always @(posedge clockVGA)
	begin
		border <= (((xcounter >= 0) && (xcounter < 3) || (xcounter >= 638) && (xcounter < 641)) || ((ycounter >= 0) && (ycounter < 3) || (ycounter >= 477) && (ycounter < 480))); //changed 11 to 3, 630 to 638, y count 477 to 480
	end
	
	always@(posedge clockVGA)
	begin
	appleCount = appleCount+1;
		if(appleCount == 1)
		begin
			appleX <= 20;
			appleY <= 20;
		end
		else
		begin	
		
			if(good_collision)
			begin
			
				if((Xrandom<10) || (Xrandom>630) || (Yrandom<10) || (Yrandom>470))
				
				begin
				
					appleX <= 40;
					appleY <= 30;
				end
				else
				begin
				
					appleX <= Xrandom;
					appleY <= Yrandom;
					
				end
			end
			else if(~start)
			begin
			
				if((Xrandom<10) || (Xrandom>630) || (Yrandom<10) || (Yrandom>470))
				
				begin
				
					appleX <=340;
					
					appleY <=430;
					
				end
				else
				begin
				
					appleX <= Xrandom;
					appleY <= Yrandom;
					
				end
			end
		end
	end
	
	always @(posedge clockVGA)
	begin
		appleinputX <= (xcounter > appleX && xcounter < (appleX + 10));
		appleinputY <= (ycounter > appleY && ycounter < (appleY + 10));
		apple = appleinputX && appleinputY;
	end
	
	
	always@(posedge update)
	begin
	if(start)
	begin
		for(count1 = 127; count1 > 0; count1 = count1 - 1) //changed from 127 to 199
			begin
				if(count1 <= size - 1)
				begin
					snakeX[count1] = snakeX[count1 - 1];
					snakeY[count1] = snakeY[count1 - 1];
				end
			end
		case(direction)
		
			5'b00010: snakeY[0] <= (snakeY[0] - 10);  //changed all 10s to 15s
			5'b00100: snakeX[0] <= (snakeX[0] - 10);
			5'b01000: snakeY[0] <= (snakeY[0] + 10);
			5'b10000: snakeX[0] <= (snakeX[0] + 10);
			
			endcase	
		end
		
	else if(~start)
	
	begin
	
		for(count3 = 1; count3 < 128; count3 = count3+1)  //changed from 128 to 200
			begin
			snakeX[count3] = 700;  //changed from 700 to 350 and works, possibly need to make bigger
			snakeY[count3] = 500;  //changed from 500 to 250 and works, possibly need to make bigger
			end
	end
	
	end
	
		
	always@(posedge clockVGA)
	begin
		found = 0;
		
		for(count2 = 1; count2 < size; count2 = count2 + 1)
		begin
			if(~found)
			begin				
				snakeBody = ((xcounter > snakeX[count2] && xcounter < snakeX[count2]+10) && (ycounter > snakeY[count2] && ycounter < snakeY[count2]+10));  //changed from 10 to 5
				found = snakeBody;
			end
		end
	end


	
	always@(posedge clockVGA)
	begin	
		snakeHead = (xcounter > snakeX[0] && xcounter < (snakeX[0]+10)) && (ycounter > snakeY[0] && ycounter < (snakeY[0]+10));  //changed from 10 to 5
	end
		
	assign lethal = border || snakeBody;
	assign nonLethal = apple;
	always @(posedge clockVGA) if(nonLethal && snakeHead) begin good_collision<=1;
																					size = size+1;         //changed from 1 to 5
																					end
										else if(~start) size = 1;										
										else good_collision=0;
	always @(posedge clockVGA) if(lethal && snakeHead) bad_collision<=1;
										else bad_collision=0;
	always @(posedge clockVGA) if(bad_collision) gameover<=1;
										else if(~start) gameover=0;
										
	
									
	assign R = (displayArea && (apple || gameover));
	assign G = (displayArea && ((snakeHead||snakeBody) && ~gameover));
	assign B = (displayArea && (border && ~gameover) );//---------------------------------------------------------------Added border
	always@(posedge clockVGA)
	begin
	
		VGA_R = {8{B}}; //changed from R to B
		VGA_G = {8{R}}; //changed from G to R
		VGA_B = {8{G}}; //changed from B to G
		
	end 

endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////

module clk_reduce(master_clk, clockVGA);

	input master_clk; //50MHz clock
	output reg clockVGA; //25MHz clock
	reg q;

	always@(posedge master_clk)
	
	begin
	
		q <= ~q; 
		clockVGA <= q;
		
	end
	
endmodule


//////////////////////////////////////////////////////////////////////////////////////////////////////

module VGA_gen(clockVGA, xcounter, ycounter, displayArea, VGA_hSync, VGA_vSync, blank_n);

	input clockVGA;
	output reg [9:0]xcounter, ycounter; 
	output reg displayArea;  
	output VGA_hSync, VGA_vSync, blank_n;

	reg p_hSync, p_vSync; 
	
	integer porchHF = 640; //start of horizntal front porch
	integer syncH = 655;//start of horizontal sync
	integer porchHB = 747; //start of horizontal back porch
	integer maxH = 793; //total length of line.

	integer porchVF = 480; //start of vertical front porch 
	integer syncV = 490; //start of vertical sync
	integer porchVB = 492; //start of vertical back porch
	integer maxV = 525; //total rows. 

	always@(posedge clockVGA)
	
	begin
	
		if(xcounter === maxH)
			xcounter <= 0;
		else
			xcounter <= xcounter + 1;
	end
	// 93sync, 46 bp, 640 display, 15 fp
	// 2 sync, 33 bp, 480 display, 10 fp
	always@(posedge clockVGA)
	begin
		if(xcounter === maxH)
		begin
			if(ycounter === maxV)
				ycounter <= 0;
			else
			ycounter <= ycounter + 1;
		end
	end
	
	always@(posedge clockVGA)
	begin
		displayArea <= ((xcounter < porchHF) && (ycounter < porchVF)); 
	end

	always@(posedge clockVGA)
	begin
		p_hSync <= ((xcounter >= syncH) && (xcounter < porchHB)); 
		p_vSync <= ((ycounter >= syncV) && (ycounter < porchVB)); 
	end
 
	assign VGA_vSync = ~p_vSync; 
	assign VGA_hSync = ~p_hSync;
	assign blank_n = displayArea;
endmodule		

//////////////////////////////////////////////////////////////////////////////////////////////////////

module appleLocation(clockVGA, xcounter, ycounter, start, apple);
	input clockVGA, xcounter, ycounter, start;
	wire [9:0] appleX;
	wire [8:0] appleY;
	reg appleinputX, appleinputY;
	output apple;
	wire [9:0]Xrandom;
	wire [8:0]Yrandom;
	randomGrid rand1(clockVGA, Xrandom, Yrandom);
	
	assign appleX = 0;
	assign appleY = 0;
	
	always @(negedge clockVGA)
	begin
		appleinputX <= (xcounter > appleX && xcounter < (appleX + 10));
		appleinputY <= (ycounter > appleY && ycounter < (appleY + 10));
	end
	
	assign apple = appleinputX && appleinputY;
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////

module randomGrid(clockVGA, Xrandom, Yrandom);
	input clockVGA;
	output reg [9:0]Xrandom;
	output reg [8:0]Yrandom;
	reg [5:0]pointX, pointY = 10;

	always @(posedge clockVGA)
		pointX <= pointX + 3;	
	always @(posedge clockVGA)
		pointY <= pointY + 1;
	always @(posedge clockVGA)
	begin	
		if(pointX>62)
			Xrandom <= 620;
		else if (pointX<2)
			Xrandom <= 20;
		else
			Xrandom <= (pointX * 10);
	end
	
	always @(posedge clockVGA)
	begin	
		if(pointY>46)//---------------------------------------------------------------Changed to 469
			Yrandom <= 460;
		else if (pointY<2)
			Yrandom <= 20;
		else
			Yrandom <= (pointY * 10);
	end
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////

module kbInput(KB_clk, data, direction, reset);

	input KB_clk, data;
	output reg [4:0] direction;
	output reg reset = 0; 
	reg [7:0] code;
	reg [10:0]keyCode, previousCode;
	reg recordNext = 0;
	integer count = 0;

always@(negedge KB_clk)
	begin
		keyCode[count] = data;
		count = count + 1;			
		if(count == 11)
		begin
			if(previousCode == 8'hF0)
			begin
				code <= keyCode[8:1];
			end
			previousCode = keyCode[8:1];
			count = 0;
		end
	end
	
	always@(code)
	begin
		if(code == 8'h1D)
			direction = 5'b00010;
		else if(code == 8'h1C)
			direction = 5'b00100;
		else if(code == 8'h1B)
			direction = 5'b01000;
		else if(code == 8'h23)
			direction = 5'b10000;
		else if(code == 8'h5A)
			reset <= ~reset;
		else direction <= direction;
	end	
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////

module updateClk(master_clk, update);
	input master_clk;
	output reg update;
	reg [21:0]count;	

	always@(posedge master_clk)
	begin
		count <= count + 1;
		
		if(count == 1777777)
		
		begin
		
			update <= ~update;
			count <= 0;
		end	
	end
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////


