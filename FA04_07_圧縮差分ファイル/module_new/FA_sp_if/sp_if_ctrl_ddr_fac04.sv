//--------------------------------------------------------------------------------------------------
// Company           : Oki Electric Industry Co., Ltd.
// Project Name      : FPGA development for sonar (29SS)
// Module Name       : sp_if_ctrl_ddr
// Function          : FPGA sp_if_ctrl_ddr Module
// Create Date       : 2019.04.12
// Original Designer : Koshiro SHIMIZU
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// History:
//--------------------------------------------------------------------------------------------------
// Ver   | Date         | Designer          | Comment
//--------------------------------------------------------------------------------------------------
// 1.0   | 2019.04.12   | Koshiro SHIMIZU   | 新規作成
// 1.1   | 2019.09.11   | Kazuki Matsusaka  | フレームカウンタの[i_sync_on]によるクリアを削除
// 1.2   | 2022.09.15   | Masayuki Kato     | 制御毎に独立
//
// Copyright 2019 Oki Electric Industry Co., Ltd.
//
module sp_if_ctrl_ddr_fac04 (										//制御毎に独立 v1.2
	input	logic			i_clk156m							,	// system clock(156.25MHz)
	input	logic			i_arst								,	// asyncronous reset
	input	logic	[3:0]	i_frame_max							,	// 入力データ格納RAMのデータ更新周期（0ori換算）
																	// ※sp_main_topでパラメーター宣言された値が信号化されたものである
	input	logic	[31:0]	i_frame_offset0						,	// 1フレームごとの入力データ格納RAM0オフセットアドレスのオフセット値
																	// ※sp_main_topでパラメーター宣言された値が信号化されたものである
	input	logic	[31:0]	i_frame_offset1						,	// 1フレームごとの入力データ格納RAM1オフセットアドレスのオフセット値
																		// ※sp_main_topでパラメーター宣言された値が信号化されたものである
	input	logic			i_ctrl_startp						,	// 信号処理開始指示パルス
	input	logic			i_skip_tx							,	// フレームデータ出力契機指示信号(0：出力する　1：出力しない)
	input	logic			i_sync_on							,	// 開始コードスタート位置('0')の通知信号
	input	logic			i_sp_end							,	// 信号処理完了パルス
	input	logic			i_ddr_endp							,	// DDRアクセス完了通知パルス
	input	logic			i_rxfifo_rd_last					,	// Avalon-ST DDRリードデータ最終表示(転送完了通知)

	output	logic	[3:0]	o_frame_time						,	// フレームカウンター ※入力データ格納RAMのデータ更新周期の設定値により満了値が異なる
	output	logic	[31:0]	o_ram0_offset_addr					,	// 入力データ格納RAM0ライトオフセットアドレス
	output	logic	[31:0]	o_ram1_offset_addr					,	// 入力データ格納RAM1ライトオフセットアドレス
	output	logic			o_ddr_wxr							,	// DDRリード／ライトアクセス識別信号
																	// 0：リード　1：ライト
	output	logic	[3:0]	o_ddr_area							,	// DDRアクセス音響データのエリア（面）指定
																	// 4'h0：Current　4'h1：1フレーム前　4'h2：2フレーム前
																	// 4'h3：3フレーム前　4'h4〜4'hf：Current
	output	logic	[26:0]	o_ddr_addr							,	// DDRアクセス開始アドレス
	output	logic	[31:0]	o_ddr_size							,	// DDRアクセスサイズ（16byte）
	output	logic			o_ddr_start							,	// DDRアクセス開始指示
	output 	logic			o_sp_start							,	// 信号処理開始パルス（信号処理インタフェースからの指示）
	output 	logic			o_ddr_rd_startp						,	// 音響データ（Rx）の内部格納バッファ取り込み開始指示
	output 	logic			o_ddr_wr_startp						,	// 音響データ（Tx）の出力データ格納RAM読出し開始指示
	output	logic			o_ddr_endp							,	//　制御信号追加 v1.2
	output 	logic			o_ctrl_endp								// 信号処理完了に伴う送信指示パルス
	);

//--------------------------------------------------------------------------------------------------
// Reg & Wire
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
	logic			ctrl_startp_d1								;
	logic			skip_tx_d1									;
	logic			sync_on_d1									;
	logic			sp_end_d1									;
	logic			sp_if_ctrl_cnt_en							;
	logic	[3:0]	sp_if_ctrl_cnt								;
	logic	[31:0]	frame_offset0								;
	logic	[31:0]	frame_offset1								;
	logic	[31:0]	ram_base_addr								;
	logic			ddr_order_mem_rd_adr_cnt_en					;
	logic	[9:0]	ddr_order_mem_rd_adr						;
	logic	[31:0]	ddr_order_mem_rd_data						;
	logic			ctrl_end_flg								;
	logic			w_pre_ddr_rd_startp							;
	logic			pre_ddr_rd_startp_d1						;
	logic			w_pre_ddr_wr_startp							;
	logic			pre_ddr_wr_startp_d1						;
	logic			wr_ddr_endp									;

//--------------------------------------------------------------------------------------------------
// Main
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0

//入力信号の初段FlipFlop取り込み
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			ctrl_startp_d1 <= 1'b0								;
		else
			ctrl_startp_d1 <= i_ctrl_startp						;
	end


	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			skip_tx_d1 <= 1'b0									;
		else
			skip_tx_d1 <= i_skip_tx								;
	end


	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			sync_on_d1 <= 1'b0									;
		else
			sync_on_d1 <= i_sync_on								;
	end


	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			sp_end_d1 <= 1'b0									;
		else
			sp_end_d1 <= i_sp_end								;
	end


//フレームカウンター生成
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			o_frame_time <= i_frame_max							;
//del v1.1		else if ( sync_on_d1 )
//del v1.1			o_frame_time <= 4'd0								;
		else if ( ctrl_startp_d1 )	begin
			if ( o_frame_time == i_frame_max )
				o_frame_time <= 4'd0							;
			else
				o_frame_time <= o_frame_time + 4'd1				;
		end
	end


//入力データ格納RAM0オフセットアドレス生成
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			frame_offset0 <= 32'h00000000						;
		else
			frame_offset0 <= o_frame_time * i_frame_offset0		;
	end


	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			o_ram0_offset_addr <= 32'h00000000					;
		else
			o_ram0_offset_addr <= frame_offset0 + ram_base_addr	;
	end


//入力データ格納RAM1オフセットアドレス生成
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			frame_offset1 <= 32'h00000000						;
		else
			frame_offset1 <= o_frame_time * i_frame_offset1		;
	end


	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			o_ram1_offset_addr <= 32'h00000000					;
		else
			o_ram1_offset_addr <= frame_offset1 + ram_base_addr	;
	end


//sp_if_ctrlモジュール内部カウンターイネーブル信号生成
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			sp_if_ctrl_cnt_en <= 1'b0							;
		else if ( ctrl_startp_d1 || sp_end_d1 || wr_ddr_endp )
			sp_if_ctrl_cnt_en <= 1'b1							;
		else if ( sp_if_ctrl_cnt == 4'd15 )
			sp_if_ctrl_cnt_en <= 1'b0							;
	end


//sp_if_ctrlモジュール内部カウンター生成
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			sp_if_ctrl_cnt <= 4'd0								;
		else if ( ctrl_startp_d1 || sp_end_d1 || wr_ddr_endp )
			sp_if_ctrl_cnt <= 4'd0								;
		else if ( sp_if_ctrl_cnt_en )	begin
			if ( sp_if_ctrl_cnt == 4'd15  )
				sp_if_ctrl_cnt <= sp_if_ctrl_cnt				;
			else
				sp_if_ctrl_cnt <= sp_if_ctrl_cnt + 4'd1			;
		end
	end


//DDRアクセスオーダーROMの読出しアドレスイネーブル信号生成
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			ddr_order_mem_rd_adr_cnt_en <= 1'b0					;
		else if ( ctrl_startp_d1 || sp_end_d1 || wr_ddr_endp )
			ddr_order_mem_rd_adr_cnt_en <= 1'b1					;
		else if ( sp_if_ctrl_cnt == 4'd5 )
			ddr_order_mem_rd_adr_cnt_en <= 1'b0					;
	end


//DDRアクセスオーダーROMの読出しアドレス生成
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			ddr_order_mem_rd_adr <= 10'd0							;
		else if ( !skip_tx_d1 && ctrl_startp_d1 )
			ddr_order_mem_rd_adr <= 10'd0							;
		else if ( ddr_order_mem_rd_adr == 10'd1023 )
			ddr_order_mem_rd_adr <= ddr_order_mem_rd_adr			;
		else if ( ddr_order_mem_rd_adr_cnt_en )
			ddr_order_mem_rd_adr <= ddr_order_mem_rd_adr + 10'd1	;
	end


//入力データ格納RAMベースアドレス生成
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			ram_base_addr <= 32'h00000000														;
		else if ( sp_if_ctrl_cnt == 4'd2 )
			ram_base_addr <= { ddr_order_mem_rd_data[31], 13'h0, ddr_order_mem_rd_data[17:0] }	;
	end


//リード/ライト識別信号生成
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			o_ddr_wxr <= 1'b0									;
		else if ( sp_if_ctrl_cnt == 4'd3 )
			o_ddr_wxr <= ddr_order_mem_rd_data[0]				;
	end


//DDRアクセス 音響データのエリア(面)指定信号生成
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			o_ddr_area <= 4'h0									;
		else if ( sp_if_ctrl_cnt == 4'd4 )
			o_ddr_area <= ddr_order_mem_rd_data[3:0]			;
	end


//DDRアクセス開始アドレス信号生成
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			o_ddr_addr <= 27'h0000000							;
		else if ( sp_if_ctrl_cnt == 4'd5 )
			o_ddr_addr <= ddr_order_mem_rd_data[26:0]			;
	end


//DDRアクセスサイズ(容量)信号生成
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			o_ddr_size <= 32'h00000000							;
		else if ( sp_if_ctrl_cnt == 4'd6 )
			o_ddr_size <= { ddr_order_mem_rd_data[27:0] , 4'b0000 }	;
	end


//DDRアクセス 開始指示信号生成
//本信号はDDRアクセスオーダーROMからの読出しデータを使用せず、ハード的に「リード/ライト識別」
//「DDRアクセス 音響データのエリア(面)指定」「DDRアクセス開始アドレス」「DDRアクセスサイズ(容量)」
//が確定後に出力する
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			o_ddr_start <= 1'b0									;
		else if ( i_ddr_endp || ctrl_startp_d1 )
			o_ddr_start <= 1'b0									;
		else if ( sp_if_ctrl_cnt == 4'd7 )
			o_ddr_start <= 1'b1									;
	end


//DDRアクセス終了指示信号生成
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			ctrl_end_flg <= 1'b0								;
		else if ( sp_if_ctrl_cnt == 4'd7 )
			ctrl_end_flg <= ddr_order_mem_rd_data[0]			;
	end


//信号処理開始パルス生成
//sp_if_inモジュールのi_rxfifo_rd_lastを1回叩いた信号
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			o_sp_start <= 1'b0									;
		else
			o_sp_start <= i_rxfifo_rd_last						;
	end



//DDR読出し開始パルス生成
//「読出し識別」かつ「DDRアクセス 開始指示」の立ち上がり微分とする
	assign w_pre_ddr_rd_startp = ~o_ddr_wxr & o_ddr_start		;

	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			pre_ddr_rd_startp_d1 <= 1'b0						;
		else
			pre_ddr_rd_startp_d1 <= w_pre_ddr_rd_startp			;
	end

	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			o_ddr_rd_startp <= 1'b0											;
		else
			o_ddr_rd_startp <= w_pre_ddr_rd_startp & ~pre_ddr_rd_startp_d1	;
	end


//DDR書込み開始パルス生成
//「書込み識別」かつ「DDRアクセス 開始指示」の立ち上がり微分とする
	assign w_pre_ddr_wr_startp = o_ddr_wxr & o_ddr_start		;

	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			pre_ddr_wr_startp_d1 <= 1'b0						;
		else
			pre_ddr_wr_startp_d1 <= w_pre_ddr_wr_startp			;
	end

	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			o_ddr_wr_startp <= 1'b0											;
		else
			o_ddr_wr_startp <= w_pre_ddr_wr_startp & ~pre_ddr_wr_startp_d1	;
	end


//ライトアクセス完了パルス生成
//「終了指示がディセーブル」かつ「ライト識別」かつ「DDRアクセス完了通知パルスが有効」
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			wr_ddr_endp <= 1'b0												;
		else
			wr_ddr_endp <= ~ctrl_end_flg & o_ddr_wxr & i_ddr_endp			;
	end


//信号処理完了に伴う送信指示パルス生成
//「DDRアクセス終了指示が有効」かつ「ライト識別」かつ「DDRアクセス完了通知パルスが有効」
	always_ff @( posedge i_clk156m, posedge i_arst )	begin
		if ( i_arst )
			o_ctrl_endp <= 1'b0															;
		else
			o_ctrl_endp <= ~skip_tx_d1 & ctrl_end_flg & o_ddr_wxr & i_ddr_endp			;
	end



//--------------------------------------------------------------------------------------------------
// Sub Module Instance
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
//DDRアクセスオーダーROMモジュール
sp_if_ctrl_rom_fac04	sp_if_ctrl_rom_inst (				//制御毎に実装 v1.2
	.i_arst					( i_arst                )	,
	.i_order_mem_rd_adr		( ddr_order_mem_rd_adr  )	,
	.i_clk156m				( i_clk156m             )	,
	.i_order_mem_rden		( 1'b1                  )	,
	.o_order_mem_rd_data	( ddr_order_mem_rd_data )
	);

//-------------------
//	OUTPUT
//-------------------

	assign o_ddr_endp = wr_ddr_endp  | o_ctrl_endp;				//制御信号出力追加 v1.2


endmodule
