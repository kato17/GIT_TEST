//--------------------------------------------------------------------------------------------------
// Company           : Oki Electric Industry Co., Ltd.
// Project Name      : FPGA development for sonar (29SS)
// Module Name       : 
// Function          : FPGA sp_if_top_ddr Module
// Create Date       : 2022.09.05 
// Original Designer : Masayuki Kato 
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// History:
//--------------------------------------------------------------------------------------------------
// Ver   | Date         | Designer          | Comment
//--------------------------------------------------------------------------------------------------
// 1.0   | 2022.09.05   | Masayuki Kato     | 新規作成 
//
// Copyright 2019 Oki Electric Industry Co., Ltd.
//
module signal_sel (
    input  logic              i_arst                                  ,    // 非同期リセット
    input  logic              i_clk156m                               ,    // クロック

    input logic 				i_ctrl_startp,
    input logic 				i_calc_start_fa04,
    input logic 				i_calc_start_fa05,
    input logic 				i_calc_start_fa06,

    input  logic    		i_ddr_wxr_fa04                  ,   // DDRリード／ライトアクセス識別信号
    input  logic    [  3:0] i_ddr_area_fa04                 ,   // DDRアクセス音響データのエリア（面）指定
    input  logic    [ 26:0] i_ddr_addr_fa04                 ,   // DDRアクセス開始アドレス
    input  logic    [ 31:0] i_ddr_size_fa04                 ,   // DDRアクセスサイズ（byte）
    input  logic    		i_ddr_start_fa04                ,   // DDRアクセス開始指示
    input  logic    		i_rd_ready_fa04               ,   // Avalon-ST 信号処理受信FIFO Ready
    input  logic           i_wr_sop_fa04                        ,   // Avalon-ST DDR3ライトデータパケット先頭表示
    input  logic           i_wr_eop_fa04                        ,   // Avalon-ST DDR3ライトデータパケット終了表示
    input  logic           i_wr_valid_fa04                      ,   // Avalon-ST DDR3ライトデータパケット有効表示
    input  logic           i_wr_first_fa04                      ,   // Avalon-ST DDR3ライトデータパケット有効表示
    input  logic           i_wr_last_fa04                      ,   // Avalon-ST DDR3ライトデータパケット有効表示
    input  logic   [127:0] i_wr_data_fa04                       ,   // Avalon-ST DDR3ライトデータ

    input  logic    		i_ddr_wxr_fa05                  ,   // DDRリード／ライトアクセス識別信号
    input  logic    [  3:0] i_ddr_area_fa05                 ,   // DDRアクセス音響データのエリア（面）指定
    input  logic    [ 26:0] i_ddr_addr_fa05                 ,   // DDRアクセス開始アドレス
    input  logic    [ 31:0] i_ddr_size_fa05                 ,   // DDRアクセスサイズ（byte）
    input  logic    		i_ddr_start_fa05                ,   // DDRアクセス開始指示
    input  logic    		i_rd_ready_fa05               ,   // Avalon-ST 信号処理受信FIFO Ready
    input  logic           i_wr_sop_fa05                        ,   // Avalon-ST DDR3ライトデータパケット先頭表示
    input  logic           i_wr_eop_fa05                        ,   // Avalon-ST DDR3ライトデータパケット終了表示
    input  logic           i_wr_valid_fa05                      ,   // Avalon-ST DDR3ライトデータパケット有効表示
    input  logic           i_wr_first_fa05                      ,   // Avalon-ST DDR3ライトデータパケット有効表示
    input  logic           i_wr_last_fa05                      ,   // Avalon-ST DDR3ライトデータパケット有効表示
    input  logic   [127:0] i_wr_data_fa05                       ,   // Avalon-ST DDR3ライトデータ

    input  logic    		i_ddr_wxr_fa06                  ,   // DDRリード／ライトアクセス識別信号
    input  logic    [  3:0] i_ddr_area_fa06                 ,   // DDRアクセス音響データのエリア（面）指定
    input  logic    [ 26:0] i_ddr_addr_fa06                 ,   // DDRアクセス開始アドレス
    input  logic    [ 31:0] i_ddr_size_fa06                 ,   // DDRアクセスサイズ（byte）
    input  logic    		i_ddr_start_fa06                ,   // DDRアクセス開始指示
    input  logic    		i_rd_ready_fa06               ,   // Avalon-ST 信号処理受信FIFO Ready
    input  logic           i_wr_sop_fa06                        ,   // Avalon-ST DDR3ライトデータパケット先頭表示
    input  logic           i_wr_eop_fa06                        ,   // Avalon-ST DDR3ライトデータパケット終了表示
    input  logic           i_wr_valid_fa06                      ,   // Avalon-ST DDR3ライトデータパケット有効表示
    input  logic           i_wr_first_fa06                      ,   // Avalon-ST DDR3ライトデータパケット有効表示
    input  logic           i_wr_last_fa06                      ,   // Avalon-ST DDR3ライトデータパケット有効表示
    input  logic   [127:0] i_wr_data_fa06                       ,   // Avalon-ST DDR3ライトデータ

    input  logic    		i_ddr_wxr_fa07                  ,   // DDRリード／ライトアクセス識別信号
    input  logic    [  3:0] i_ddr_area_fa07                 ,   // DDRアクセス音響データのエリア（面）指定
    input  logic    [ 26:0] i_ddr_addr_fa07                 ,   // DDRアクセス開始アドレス
    input  logic    [ 31:0] i_ddr_size_fa07                 ,   // DDRアクセスサイズ（byte）
    input  logic    		i_ddr_start_fa07                ,   // DDRアクセス開始指示
    input  logic    		i_rd_ready_fa07               ,   // Avalon-ST 信号処理受信FIFO Ready
    input  logic           i_wr_sop_fa07                        ,   // Avalon-ST DDR3ライトデータパケット先頭表示
    input  logic           i_wr_eop_fa07                        ,   // Avalon-ST DDR3ライトデータパケット終了表示
    input  logic           i_wr_valid_fa07                      ,   // Avalon-ST DDR3ライトデータパケット有効表示
    input  logic           i_wr_first_fa07                      ,   // Avalon-ST DDR3ライトデータパケット有効表示
    input  logic           i_wr_last_fa07                      ,   // Avalon-ST DDR3ライトデータパケット有効表示
    input  logic   [127:0] i_wr_data_fa07                       ,   // Avalon-ST DDR3ライトデータ

	input  logic   [6:0]   i_r_state_fa04					,	
	input  logic	[3:0]		fa_en, 

	input logic 		 i_ddr_endp							,
	input logic			 i_rd_valid							,
	input logic			 i_rd_first							,
	input logic			 i_rd_last							,
	input logic			 i_rd_sop							,
	input logic			 i_rd_eop							,
    input logic   [127:0] i_rd_data                       	, 
	input logic			 i_wr_ready							, 
 	input logic   [3:0]	i_calc_cnt							,   //v1.1 calc_cnt_fa04    
	

    output	wire 			o_ddr_wxr					,
    output  wire		[3:0] 	o_ddr_area					,
    output  wire		[26:0] 	o_ddr_addr					,
    output  wire		[31:0] 	o_ddr_size					,
    output	wire 			o_ddr_start					,
    output	wire			o_rd_ready					,
    output  wire  	       o_wr_sop                        ,   // Avalon-ST DDR3ライトデータパケット先頭表示
    output  wire           o_wr_eop                        ,   // Avalon-ST DDR3ライトデータパケット終了表示
    output  wire           o_wr_valid                      ,   // Avalon-ST DDR3ライトデータパケット有効表示
    output  wire           o_wr_first                      ,   // Avalon-ST DDR3
    output  wire           o_wr_last                      ,   // Avalon-ST DDR3
    output  wire   [127:0] o_wr_data                      ,    // Avalon-ST DDR3ライトデータ

		output wire	o_ddr_endp_fa04,		//DDR Access CMP v1.1
		output wire	o_ddr_endp_fa05,		//DDR Access CMP v1.1
		output wire	o_ddr_endp_fa06,		//DDR Access CMP v1.1
		output wire	o_ddr_endp_fa07,		//DDR Access CMP v1.1

		output wire	o_rd_valid_fa04,		//DDR Access CMP v1.1
		output wire	o_rd_valid_fa05,		//DDR Access CMP v1.1
		output wire	o_rd_valid_fa06,		//DDR Access CMP v1.1
		output wire	o_rd_valid_fa07,		//DDR Access CMP v1.1

		output wire	o_rd_first_fa04,		//DDR Access CMP v1.1
		output wire	o_rd_first_fa05,		//DDR Access CMP v1.1
		output wire	o_rd_first_fa06,		//DDR Access CMP v1.1
		output wire	o_rd_first_fa07,		//DDR Access CMP v1.1

		output wire	o_rd_last_fa04,		//DDR Access CMP v1.1
		output wire	o_rd_last_fa05,		//DDR Access CMP v1.1
		output wire	o_rd_last_fa06,		//DDR Access CMP v1.1
		output wire	o_rd_last_fa07,		//DDR Access CMP v1.1

		output wire	o_rd_sop_fa04,		//DDR Access CMP v1.1
		output wire	o_rd_sop_fa05,		//DDR Access CMP v1.1
		output wire	o_rd_sop_fa06,		//DDR Access CMP v1.1
		output wire	o_rd_sop_fa07,		//DDR Access CMP v1.1

		output wire	o_rd_eop_fa04,		//DDR Access CMP v1.1
		output wire	o_rd_eop_fa05,		//DDR Access CMP v1.1
		output wire	o_rd_eop_fa06,		//DDR Access CMP v1.1
		output wire	o_rd_eop_fa07,		//DDR Access CMP v1.1

		output wire	[127:0]	o_rd_data_fa04,		//DDR Access CMP v1.1
		output wire	[127:0]	o_rd_data_fa05,		//DDR Access CMP v1.1
		output wire	[127:0]	o_rd_data_fa06,		//DDR Access CMP v1.1
		output wire	[127:0]	o_rd_data_fa07,		//DDR Access CMP v1.1

		output wire	o_wr_ready_fa04,		//DDR Access CMP v1.1
		output wire	o_wr_ready_fa05,		//DDR Access CMP v1.1
		output wire	o_wr_ready_fa06,		//DDR Access CMP v1.1
		output wire	o_wr_ready_fa07, 		//DDR Access CMP v1.1


		output logic r_calc_start_fa04,
		output logic r_calc_start_fa05,
		output logic r_calc_start_fa06


);
//--------------------------------------------------------------------------------
		logic[3:0]	r_ddr_endp;		//DDR Access CMP v1.1
		logic[3:0]	r_rd_valid;		//DDR Access CMP v1.1
		logic[3:0]	r_rd_first;		//DDR Access CMP v1.1
		logic[3:0]	r_rd_last;		//DDR Access CMP v1.1

		logic[3:0]		r_rd_sop;
		logic[3:0]		r_rd_eop;

		logic[127:0]		r_rd_data_fa04;
		logic[127:0]		r_rd_data_fa05;
		logic[127:0]		r_rd_data_fa06;
		logic[127:0]		r_rd_data_fa07;


    	logic		r_ctrl_endp					;
    	logic 		r_ddr_wxr					;
    	logic[3:0] 	r_ddr_area					;
    	logic[26:0] r_ddr_addr					;
    	logic[31:0] r_ddr_size					;
    	logic		r_ddr_start					;
    	logic 		r_rd_ready					;
      	logic       r_wr_sop                    ;   // Avalon-ST DDR3ライトデータパケット先頭表示
    	logic       r_wr_eop                    ;   // Avalon-ST DDR3ライトデータパケット終了表示
        logic       r_wr_valid                  ;   // Avalon-ST DDR3ライトデータパケット有効表示
        logic       r_wr_first                  ;   // Avalon-ST DDR3
        logic        r_wr_last                  ;   // Avalon-ST DDR3
				logic[127:0] r_wr_data                  ;    // Avalon-ST DDR3ライトデータ
				wire		st_en_res						;
				reg 		st_en						;
		logic calc_st_en;

		logic [3:0]	r_wr_ready;
		logic [3:0]	fa_en_delay;
		logic	wr_ready_ed;

		//--------------------------------------------------------------------------------
			localparam   P_WAIT_SPEC  = 7'b000_0010; // 緒元算出結果リード完了待ち状態
			localparam   P_WAIT_TRANS = 7'b000_0100; // 緒元算出結果転送完了待ち状態

			localparam   P_WAIT_RAM0_08  = 7'b000_1000; // DDR3→RAM0リード完了待ち状態
			localparam   P_WAIT_RAM0_09  = 7'b000_1001; // DDR3→RAM2リード完了待ち状態
			localparam   P_WAIT_RAM0_10  = 7'b000_1010; // DDR3→RAM3リード完了待ち状態
			localparam   P_WAIT_RAM0_11  = 7'b000_1011; // DDR3→RAM3リード完了待ち状態
			localparam   P_WAIT_RAM1_16  = 7'b001_0000; // DDR3→RAM1リード完了待ち状態
			localparam   P_WAIT_RAM1_17  = 7'b001_0001; // DDR3→RAM3リード完了待ち状態
			localparam   P_WAIT_RAM1_18  = 7'b001_0010; // DDR3→RAM3リード完了待ち状態
			localparam   P_WAIT_RAM1_19  = 7'b001_0011; // DDR3→RAM3リード完了待ち状態
			localparam   P_WAIT_CALC29   = 7'b001_1101; // 演算処理完了待ち 29 
			localparam   P_WAIT_CALC30   = 7'b001_1110; // 演算処理完了待ち 30 
			localparam   P_WAIT_CALC31   = 7'b001_1111; // 演算処理完了待ち 31
			localparam   P_WAIT_CALC     = 7'b010_0000; // 演算処理完了待ち 32
			localparam   P_END_JUDGE     = 7'b100_0000; // フレーム処理完了判定

			localparam   P_WAIT_DDR3W_04 = 7'b011_1100; //FA04_DDR3ライト完了待ち v1.2
			localparam   P_WAIT_DDR3W_05 = 7'b011_1101; //FA05_DDR3ライト完了待ち v1.2
			localparam   P_WAIT_DDR3W_06 = 7'b011_1110; //FA06_DDR3ライト完了待ち v1.2
			localparam   P_WAIT_DDR3W_07 = 7'b011_1111; //FA07_DDR3ライト完了待ち v1.2


		//--------------------------------------------------------------------------------
		   always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_wr_sop <= 1'd0;
				end
				else begin
					 case (fa_en)
						 4'b0001:  r_wr_sop = i_wr_sop_fa04;
						 4'b0010:  r_wr_sop = i_wr_sop_fa05;
						 4'b0100:  r_wr_sop = i_wr_sop_fa06;
						 4'b1000:  r_wr_sop = i_wr_sop_fa07;
						 default:  r_wr_sop = 1'd0;
					 endcase
				end
			end

			assign o_wr_sop = r_wr_sop;

		//--------------------------------------------------------------------------------
		  always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_wr_eop <= 1'd0;
				end
				else begin
					 case (fa_en)
						 4'b0001:  r_wr_eop = i_wr_eop_fa04;
						 4'b0010:  r_wr_eop = i_wr_eop_fa05;
						 4'b0100:  r_wr_eop = i_wr_eop_fa06;
						 4'b1000:  r_wr_eop = i_wr_eop_fa07;
						 default:  r_wr_eop = 1'd0;
					 endcase
				end
			end

			assign o_wr_eop = r_wr_eop;
		//--------------------------------------------------------------------------------
		  always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_wr_valid <= 1'd0;
				end
				else begin
					 case (fa_en)
						 4'b0001:  r_wr_valid = i_wr_valid_fa04;
						 4'b0010:  r_wr_valid = i_wr_valid_fa05;
						 4'b0100:  r_wr_valid = i_wr_valid_fa06;
						 4'b1000:  r_wr_valid = i_wr_valid_fa07;
						 default:  r_wr_valid = 1'd0;
					 endcase
				end
			end

			assign o_wr_valid = r_wr_valid;
		//--------------------------------------------------------------
		  always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_wr_data <= 128'd0;
				end
				else begin
					 case (fa_en)
						 4'b0001:  r_wr_data = i_wr_data_fa04;
						 4'b0010:  r_wr_data = i_wr_data_fa05;
						 4'b0100:  r_wr_data = i_wr_data_fa06;
						 4'b1000:  r_wr_data = i_wr_data_fa07;
						 default:  r_wr_data = 128'd0;
					 endcase
				end
			end

			assign o_wr_data = r_wr_data;
		//--------------------------------------------------------------------------------
		  always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_ddr_wxr <= 1'd0;
				end
				else begin
					 case (fa_en)
						 4'b0001:  r_ddr_wxr = i_ddr_wxr_fa04;
						 4'b0010:  r_ddr_wxr = i_ddr_wxr_fa05;
						 4'b0100:  r_ddr_wxr = i_ddr_wxr_fa06;
						 4'b1000:  r_ddr_wxr = i_ddr_wxr_fa07;
						 default:  r_ddr_wxr = 1'd0;
					 endcase
				end
			end

			assign o_ddr_wxr = r_ddr_wxr;
		//--------------------------------------------------------------------------------
		  always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_ddr_area <= 4'd0;
				end
				else begin
					 case (fa_en)
						 4'b0001:  r_ddr_area = i_ddr_area_fa04;
						 4'b0010:  r_ddr_area = i_ddr_area_fa05;
						 4'b0100:  r_ddr_area = i_ddr_area_fa06;
						 4'b1000:  r_ddr_area = i_ddr_area_fa07;
						 default:  r_ddr_area = 4'd0;
					 endcase
				end
			end

			assign o_ddr_area = r_ddr_area;
		//--------------------------------------------------------------------------------
		  always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_ddr_addr <= 27'd0;
				end
				else begin
					 case (fa_en)
						 4'b0001:  r_ddr_addr = i_ddr_addr_fa04;
						 4'b0010:  r_ddr_addr = i_ddr_addr_fa05;
						 4'b0100:  r_ddr_addr = i_ddr_addr_fa06;
						 4'b1000:  r_ddr_addr = i_ddr_addr_fa07;
						 default:  r_ddr_addr = 27'd0;
					 endcase
				end
			end

			assign o_ddr_addr = r_ddr_addr;
		//--------------------------------------------------------------------------------
		  always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_ddr_size <= 32'd0;
				end
				else begin
					 case (fa_en)
						 4'b0001:  r_ddr_size = i_ddr_size_fa04;
						 4'b0010:  r_ddr_size = i_ddr_size_fa05;
						 4'b0100:  r_ddr_size = i_ddr_size_fa06;
						 4'b1000:  r_ddr_size = i_ddr_size_fa07;
						 default:  r_ddr_size = 32'd0;
					 endcase
				end
			end

			assign o_ddr_size = r_ddr_size;
		//--------------------------------------------------------------------------------
		  always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_ddr_start <= 1'd0;
				end
				else begin
					 case (fa_en)
						 4'b0001:  r_ddr_start = i_ddr_start_fa04;
						 4'b0010:  r_ddr_start = i_ddr_start_fa05;
						 4'b0100:  r_ddr_start = i_ddr_start_fa06;
						 4'b1000:  r_ddr_start = i_ddr_start_fa07;
						 default:  r_ddr_start = 1'd0;
					 endcase
				end
			end

			assign o_ddr_start = r_ddr_start;
		//--------------------------------------------------------------------------------
		  always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_wr_first <= 1'd0;
				end
				else begin
					 case (fa_en)
						 4'b0001:  r_wr_first = i_wr_first_fa04;
						 4'b0010:  r_wr_first = i_wr_first_fa05;
						 4'b0100:  r_wr_first = i_wr_first_fa06;
						 4'b1000:  r_wr_first = i_wr_first_fa07;
						 default:  r_wr_first = 1'd0;
					 endcase
				end
			end

			assign o_wr_first = r_wr_first;
		//--------------------------------------------------------------------------------
		  always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_wr_last <= 1'd0;
				end
				else begin
					 case (fa_en)
						 4'b0001:  r_wr_last = i_wr_last_fa04;
						 4'b0010:  r_wr_last = i_wr_last_fa05;
						 4'b0100:  r_wr_last = i_wr_last_fa06;
						 4'b1000:  r_wr_last = i_wr_last_fa07;
						 default:  r_wr_last = 1'd0;
					 endcase
				end
			end

			assign o_wr_last = r_wr_last;
		//--------------------------------------------------------------------------------
		  always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_rd_ready <= 1'd0;
				end
				else begin
					 case (fa_en)
						 4'b0001:  r_rd_ready = i_rd_ready_fa04;
						 4'b0010:  r_rd_ready = i_rd_ready_fa05;
						 4'b0100:  r_rd_ready = i_rd_ready_fa06;
						 4'b1000:  r_rd_ready = i_rd_ready_fa07;
						 default:  r_rd_ready = 1'd0;
					 endcase
				end
			end

			assign o_rd_ready = r_rd_ready;

		//--------------------------------------------------------------------------------

		   always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_ddr_endp <= 4'd0;
				end
				else begin
					r_ddr_endp[0] = fa_en[0] & i_ddr_endp;
					r_ddr_endp[1] = fa_en[1] & i_ddr_endp;
					r_ddr_endp[2] = fa_en[2] & i_ddr_endp;
					r_ddr_endp[3] = fa_en[3] & i_ddr_endp;
				end
			end

			assign 		o_ddr_endp_fa04 = r_ddr_endp[0];
			assign 		o_ddr_endp_fa05 = r_ddr_endp[1];
			assign 		o_ddr_endp_fa06 = r_ddr_endp[2];
			assign 		o_ddr_endp_fa07 = r_ddr_endp[3];

			
		//--------------------------------------------------------------------------------
		   always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_rd_valid <= 4'd0;
				end
				else begin
					r_rd_valid[0] = fa_en[0] & i_rd_valid;
					r_rd_valid[1] = fa_en[1] & i_rd_valid;
					r_rd_valid[2] = fa_en[2] & i_rd_valid;
					r_rd_valid[3] = fa_en[3] & i_rd_valid;
				end
			end

			assign 		o_rd_valid_fa04 = r_rd_valid[0];
			assign 		o_rd_valid_fa05 = r_rd_valid[1];
			assign 		o_rd_valid_fa06 = r_rd_valid[2];
			assign 		o_rd_valid_fa07 = r_rd_valid[3];


		//--------------------------------------------------------------------------------
		   always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_rd_first <= 4'd0;
				end
				else begin
					r_rd_first[0] = fa_en[0] & i_rd_first;
					r_rd_first[1] = fa_en[1] & i_rd_first;
					r_rd_first[2] = fa_en[2] & i_rd_first;
					r_rd_first[3] = fa_en[3] & i_rd_first;
				end
			end

			assign 		o_rd_first_fa04 = r_rd_first[0];
			assign 		o_rd_first_fa05 = r_rd_first[1];
			assign 		o_rd_first_fa06 = r_rd_first[2];
			assign 		o_rd_first_fa07 = r_rd_first[3];

		//--------------------------------------------------------------------------------
		   always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_rd_last <= 4'd0;
				end
				else begin
					r_rd_last[0] = fa_en[0] & i_rd_last;
					r_rd_last[1] = fa_en[1] & i_rd_last;
					r_rd_last[2] = fa_en[2] & i_rd_last;
					r_rd_last[3] = fa_en[3] & i_rd_last;
				end
			end

			assign 		o_rd_last_fa04 = r_rd_last[0];
			assign 		o_rd_last_fa05 = r_rd_last[1];
			assign 		o_rd_last_fa06 = r_rd_last[2];
			assign 		o_rd_last_fa07 = r_rd_last[3];


		//--------------------------------------------------------------------------------

		   always@(posedge i_arst or posedge i_clk156m)begin
				if (i_arst) begin
					r_wr_ready <= 4'd0;
				end
				else begin
					r_wr_ready[0] = fa_en[0] & i_wr_ready;
					r_wr_ready[1] = fa_en[1] & i_wr_ready;
					r_wr_ready[2] = fa_en[2] & i_wr_ready;
					r_wr_ready[3] = fa_en[3] & i_wr_ready;
				end
			end

			assign 		o_wr_ready_fa04 = r_wr_ready[0];
			assign 		o_wr_ready_fa05 = r_wr_ready[1];
			assign 		o_wr_ready_fa06 = r_wr_ready[2];
			assign 		o_wr_ready_fa07 = r_wr_ready[3];



  assign calc_st_en = (i_calc_cnt == 4'd0) ? 1'b1 : 1'b0;

  always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
                r_calc_start_fa04  = 1'b0;
                r_calc_start_fa05  = 1'b0;
                r_calc_start_fa06  = 1'b0;
            end 
        else  begin
                r_calc_start_fa04  = calc_st_en & i_calc_start_fa04;
                r_calc_start_fa05  = calc_st_en & i_calc_start_fa05;
                r_calc_start_fa06  = calc_st_en & i_calc_start_fa06;
            end 
        end 

	always@(posedge i_arst or posedge i_clk156m)begin
		if (i_arst) begin
			r_rd_sop <= 4'd0;
		end
		else begin
			r_rd_sop[0] = i_rd_sop;
			r_rd_sop[1] = i_rd_sop;
			r_rd_sop[2] = i_rd_sop;
			r_rd_sop[3] = i_rd_sop;
		end
	end

	assign 		o_rd_sop_fa04 = r_rd_sop[0];
	assign 		o_rd_sop_fa05 = r_rd_sop[1];
	assign 		o_rd_sop_fa06 = r_rd_sop[2];
	assign 		o_rd_sop_fa07 = r_rd_sop[3];

	always@(posedge i_arst or posedge i_clk156m)begin
		if (i_arst) begin
			r_rd_eop <= 4'd0;
		end
		else begin
			r_rd_eop[0] = i_rd_eop;
			r_rd_eop[1] = i_rd_eop;
			r_rd_eop[2] = i_rd_eop;
			r_rd_eop[3] = i_rd_eop;
		end
	end

	assign 		o_rd_eop_fa04 = r_rd_eop[0];
	assign 		o_rd_eop_fa05 = r_rd_eop[1];
	assign 		o_rd_eop_fa06 = r_rd_eop[2];
	assign 		o_rd_eop_fa07 = r_rd_eop[3];

	always@(posedge i_arst or posedge i_clk156m)begin
		if (i_arst) begin
			r_rd_data_fa04 <= 128'd0;
			r_rd_data_fa05 <= 128'd0;
			r_rd_data_fa06 <= 128'd0;
			r_rd_data_fa07 <= 128'd0;
		end
		else begin
			r_rd_data_fa04 = i_rd_data;
			r_rd_data_fa05 = i_rd_data;
			r_rd_data_fa06 = i_rd_data;
			r_rd_data_fa07 = i_rd_data;
		end
	end

	assign 		o_rd_data_fa04 = r_rd_data_fa04;
	assign 		o_rd_data_fa05 = r_rd_data_fa05;
	assign 		o_rd_data_fa06 = r_rd_data_fa06;
	assign 		o_rd_data_fa07 = r_rd_data_fa07;



endmodule

