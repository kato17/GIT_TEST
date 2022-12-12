//--------------------------------------------------------------------------------------------------
// Company           : Oki Electric Industry Co., Ltd.
// Project Name      : FPGA development for sonar (29SS)
// Module Name       : sp_if_out_ddr
// Function          : FPGA Signal Processer Interface Output Module
// Create Date       : 2019.04.12
// Original Designer : Kazuki Matsusaka
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// History:
//--------------------------------------------------------------------------------------------------
// Ver   | Date         | Designer          | Comment
//--------------------------------------------------------------------------------------------------
// 1.0   | 2019.04.12   | Kazuki Matsusaka  | 新規作成
// 1.1   | 2019.06.18   | Kazuki Matsusaka  | 出力RAMリードアドレスのReady復旧時とカウント満了時の
//                                            保持条件の優先順位を入れ替え
// 1.2   | 2019.07.05   | Kazuki Matsusaka  | RAMアドレス選択切替条件を変更
//
// Copyright 2019 Oki Electric Industry Co., Ltd.
//
//--------------------------------------------------------------------------------------------------
// Module & Port
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
module sp_if_out_ddr (
	input	wire				i_arst						,// システムリセット
	input	wire				i_clk156m					,// システムクロック(156.25MHz)
	input	wire	[31:0]		i_oramb_wr_offset			,// 出力データ格納RAM portB側のライトオフセットアドレス
	output	wire				o_wr_sop					,// Avalon-ST DDR3ライトデータパケット先頭表示
	output	wire				o_wr_eop					,// Avalon-ST DDR3ライトデータパケット終了表示
	output	wire				o_wr_valid					,// Avalon-ST DDR3ライトデータパケット有効表示
	output	wire	[127:0]		o_wr_data					,// Avalon-ST DDR3ライトデータ
	input	wire				i_wr_ready					,// Avalon-ST DDR3ライト Ready
	output	wire				o_wr_first					,// Avalon-ST DDR3ライトデータ先頭表示(転送開始通知)
	output	wire				o_wr_last					,// Avalon-ST DDR3ライトデータ最終表示(転送完了通知)
	input	wire				i_ctrl_startp				,// 信号処理開始指示パルス
	input	wire				i_ddr_wr_startp				,// 音響データ（Tx）の内部格納バッファ読出し開始指示
	input	wire	[31:0]		i_ddr_size					,// DDRアクセス サイズ(byte)
	input	wire	[31:0]		i_orama_wr_data				,// 出力データ格納RAM PORT-Aライトデータ
	input	wire				i_orama_wr_valid			,// 出力データ格納RAM PORT-Aライトデータ有効指示
	input	wire	[31:0]		i_oramb_wr_data				,// 出力データ格納RAM PORT-Bライトデータ
	input	wire				i_oramb_wr_valid	 		 // 出力データ格納RAM PORT-Bライトデータ有効指示
);

//--------------------------------------------------------------------------------------------------
// Reg & Wire
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
	reg					ctrl_startp_d1		;
//	reg					ddr_wr_startp_d1	;
	wire					ddr_wr_startp_d1	;
	wire				ram_cnt_clear		;
	wire				pre_ram_cnt_clear		;
	wire	[31:0]		w_rama_wr_addr		;
	wire	[127:0]		w_rama_wr_data_128b;
	wire				w_rama_wr_en		;
	wire	[31:0]		w_ramb_wr_addr		;
	wire	[127:0]		w_ramb_wr_data_128b;
	wire				w_ramb_wr_en		;
	reg		[31:0]		ddr_size_d1			;
	reg					addr_sel			;
	reg					ram_rd_en_gen		;
	wire				adr_end_num			;
	reg		[31:0]		ram_rd_addr			;
	wire	[31:0]		rama_addr			;
	wire	[31:0]		ramb_addr			;
	wire	[127:0]		rama_rd_data		;
	wire				rama_rd_valid		;
	wire				w_fifo_wr_ready		;
	reg					fifo_wr_ready_d1	;
	reg		[127:0]		fifo_wr_data		;
	reg					fifo_wr_sop			;
	wire				fifo_wr_eop_gen		;
	wire				fifo_wr_eop			;
	reg					fifo_wr_valid_gen	;
	wire				fifo_wr_valid		;
	reg					ready_rep			;
	reg					ready_rep_d1		;
	reg		[31:0]		fifo_send_cnt		;
	reg		[11:0]		cnt_d				;	//cnt_delay	

//--------------------------------------------------------------------------------------------------
// Main
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
//初段FF
	always@( posedge i_clk156m or posedge i_arst )begin
		if( i_arst )
			ctrl_startp_d1 	<= 1'b0;
		else
			ctrl_startp_d1 	<= i_ctrl_startp;
	end
//
//	always@( posedge i_clk156m or posedge i_arst )begin
//		if( i_arst )
//			ddr_wr_startp_d1 	<= 1'b0;
//		else
//			ddr_wr_startp_d1	<= i_ddr_wr_startp;
//	end
	always@( posedge i_clk156m or posedge i_arst )begin
		if( i_arst )
			cnt_d <=  12'h801;
		else if(i_ddr_wr_startp)
				cnt_d <= 12'd0;
		else if(cnt_d == 12'h801)
				cnt_d <= cnt_d;
		else
				cnt_d <= cnt_d + 1'd1;
	end

	assign ddr_wr_startp_d1 = ((cnt_d == 12'h800) ? 1'b1 : 1'b0);

//RAMライトアドレスクリア信号生成
//IF部処理開始指示/DDR転送開始指示
	assign	ram_cnt_clear = ( ctrl_startp_d1 || ddr_wr_startp_d1 );


//--------------------------------------
//          sub module
//--------------------------------------
	sp_if_out_sub		out_sub_inst0(
		.i_arst				( i_arst				),
		.i_clk156m			( i_clk156m				),
		.i_ram_cnt_clear	( ram_cnt_clear			),
		.i_ram_wr_data		( i_orama_wr_data		),
		.i_ram_wr_valid		( i_orama_wr_valid		),
		.o_ram_wr_addr		( w_rama_wr_addr		),
		.o_ram_wr_data_128b	( w_rama_wr_data_128b	),
		.o_ram_wr_en	 	( w_rama_wr_en			) 
	);

	sp_if_out_sub		out_sub_inst1(
		.i_arst				( i_arst				),
		.i_clk156m			( i_clk156m				),
		.i_ram_cnt_clear	( ram_cnt_clear			),
		.i_ram_wr_data		( i_oramb_wr_data		),
		.i_ram_wr_valid		( i_oramb_wr_valid		),
		.o_ram_wr_addr		( w_ramb_wr_addr		),
		.o_ram_wr_data_128b	( w_ramb_wr_data_128b	),
		.o_ram_wr_en	 	( w_ramb_wr_en			) 
	);


//--------------------------------------
//         出力データ格納RAM
//--------------------------------------
	always@( posedge i_clk156m or posedge i_arst )begin
		if( i_arst )
			addr_sel 	<= 1'b0;
		else if( ddr_wr_startp_d1)
			addr_sel 	<= 1'b0;
//v1.2		else if( ctrl_startp_d1 )
		else if( ctrl_startp_d1 || fifo_wr_eop )	//v1.2
			addr_sel 	<= 1'b1;
	end

	assign rama_addr = ( addr_sel ) ? w_rama_wr_addr : ram_rd_addr;	// portA側ライト/リードアドレス選択
	assign ramb_addr = w_ramb_wr_addr + i_oramb_wr_offset;			// portB側ライトアドレスオフセット加算

	sp_if_out_ram		sp_if_out_ram_inst(
		.i_arst				( i_arst				),
		.i_clk156m			( i_clk156m				),
// Aport
		.i_rama_addr		( rama_addr				),// ライト/リード
		.i_rama_wr_data		( w_rama_wr_data_128b	),
		.i_rama_wr_en		( w_rama_wr_en			),
		.i_rama_rd_en		( ram_rd_en_gen			),
		.o_rama_rd_data		( rama_rd_data			),
		.o_rama_rd_valid	( rama_rd_valid			),//未使用
// Bport
		.i_ramb_addr		( ramb_addr				),// ライトのみ
		.i_ramb_wr_data		( w_ramb_wr_data_128b	),
		.i_ramb_wr_en		( w_ramb_wr_en			),
		.i_ramb_rd_en		( 1'b0					),
		.o_ramb_rd_data		( /*OPEN*/				),
		.o_ramb_rd_valid	( /*OPEN*/				)
	);

//--------------------------------------
//      信号処理結果出力制御(DDR転送)
//--------------------------------------
//---内蔵RAMリード制御---//

//---転送データサイズラッチ---//
	always@( posedge i_clk156m or posedge i_arst )begin
		if( i_arst )
			ddr_size_d1 	<= 32'd0;
		else if( ddr_wr_startp_d1 )
			ddr_size_d1	<= { 4'h0 ,i_ddr_size[31:4]} - 31'd1;		//16byte単位に設定と0oriのため-1
	end

//---リードイネーブル生成---//
	always@( posedge i_clk156m or posedge i_arst )begin
		if( i_arst )
			ram_rd_en_gen 	<= 1'b0;
		else if( ctrl_startp_d1 )
			ram_rd_en_gen 	<= 1'b0;
		else if( ddr_wr_startp_d1 )
			ram_rd_en_gen 	<= 1'b1;
		else if( fifo_wr_eop )
			ram_rd_en_gen 	<= 1'b0;
	end

//--アドレス生成---//

	assign adr_end_num = ( ram_rd_addr == ddr_size_d1) ? 1'b1 : 1'b0 ;

	always@( posedge i_clk156m or posedge i_arst )begin
		if( i_arst )
			ram_rd_addr 	<= 32'd0;
		else if( ram_cnt_clear )
			ram_rd_addr 	<= 32'd0;
		else if( w_fifo_wr_ready == 1'b0)
			ram_rd_addr 	<= fifo_send_cnt;
		else if( adr_end_num )
			ram_rd_addr 	<= ram_rd_addr;		//v1.1
		else if( ram_rd_en_gen )
			ram_rd_addr	<= ram_rd_addr + 32'd1;
	end

//---出力制御---//
//データ
	always@( posedge i_clk156m or posedge i_arst )begin
		if( i_arst )
			fifo_wr_data 	<= 127'd0;
		else
			fifo_wr_data	<= rama_rd_data;
	end

//SOP生成
	always@( posedge i_clk156m or posedge i_arst )begin
		if( i_arst )
			fifo_wr_sop 	<= 1'b0;
		else if( ram_rd_addr == 32'd2)
			fifo_wr_sop 	<= 1'b1;
		else
			fifo_wr_sop 	<= 1'b0;
	end

//EOP生成
	assign fifo_wr_eop_gen = ( fifo_send_cnt == ddr_size_d1) ? 1'b1 : 1'b0;
	assign fifo_wr_eop 	   = ( w_fifo_wr_ready & fifo_wr_valid) ? fifo_wr_eop_gen : 1'b0;

//valid生成
	always@( posedge i_clk156m or posedge i_arst )begin
		if( i_arst )
			fifo_wr_valid_gen 	<= 1'b0;
		else if( ram_cnt_clear )
			fifo_wr_valid_gen 	<= 1'b0;
		else if( w_fifo_wr_ready == 1'b0 )
			fifo_wr_valid_gen 	<= 1'b0;							//Readyが'0'で停止
		else if( fifo_wr_eop )
			fifo_wr_valid_gen 	<= 1'b0;							//出力完了で停止
		else if( ram_rd_addr == 32'd2)
			fifo_wr_valid_gen 	<= 1'b1;							//出力開始
		else if( ram_rd_en_gen && ready_rep_d1 )
			fifo_wr_valid_gen 	<= 1'b1;							//リード中のReady復旧からの開始
	end

	assign fifo_wr_valid = ( w_fifo_wr_ready ) ? fifo_wr_valid_gen : 1'b0;

//Ready復旧検出
	always@( posedge i_clk156m or posedge i_arst )begin
		if( i_arst )
			fifo_wr_ready_d1 <= 1'b1;
		else
			fifo_wr_ready_d1 <= w_fifo_wr_ready;
	end


	always@( posedge i_clk156m or posedge i_arst )begin
		if( i_arst )
			ready_rep 	<= 1'b0;
		else if( w_fifo_wr_ready == 1'b1 && fifo_wr_ready_d1 == 1'b0)
			ready_rep 	<= 1'b1;
		else
			ready_rep 	<= 1'b0;
	end

	always@( posedge i_clk156m or posedge i_arst )begin
		if( i_arst )
			ready_rep_d1 <= 1'b1;
		else
			ready_rep_d1 <= ready_rep;
	end

//転送数カウント
	always@( posedge i_clk156m or posedge i_arst )begin
		if( i_arst )
			fifo_send_cnt 	<= 32'd0;
		else if( ram_cnt_clear )
			fifo_send_cnt 	<= 32'd0;
		else if( fifo_wr_valid )
			fifo_send_cnt 	<= fifo_send_cnt + 32'd1;
	end

//--------------------------------------
//          Avalon-FIFO
//--------------------------------------
	FIFO_TX_DDR FIFO_TX_DDR_inst (
		.clk_clk                                   ( i_clk156m 					),// clk
		.reset_reset_n                             ( ~i_arst 					),// reset.reset_n
		.sc_fifo_0_in_data                         ( fifo_wr_data 				),// sc_fifo_0_in.data
		.sc_fifo_0_in_valid                        ( fifo_wr_valid 				),// valid
		.sc_fifo_0_in_ready                        ( w_fifo_wr_ready 			),// ready
		.sc_fifo_0_in_startofpacket                ( fifo_wr_sop 				),// startofpacket
		.sc_fifo_0_in_endofpacket                  ( fifo_wr_eop 				),// endofpacket
		.sc_fifo_0_in_channel                      ( {fifo_wr_sop,fifo_wr_eop} 	),// channel
		.st_pipeline_stage_0_source0_ready         ( i_wr_ready 				),// st_pipeline_stage_0_source0.ready
		.st_pipeline_stage_0_source0_valid         ( o_wr_valid 				),// valid
		.st_pipeline_stage_0_source0_startofpacket ( o_wr_sop 					),// startofpacket
		.st_pipeline_stage_0_source0_endofpacket   ( o_wr_eop 					),// endofpacket
		.st_pipeline_stage_0_source0_data          ( o_wr_data 					),// data
		.st_pipeline_stage_0_source0_channel       ( {o_wr_first,o_wr_last} 	)// channel
	);

endmodule
