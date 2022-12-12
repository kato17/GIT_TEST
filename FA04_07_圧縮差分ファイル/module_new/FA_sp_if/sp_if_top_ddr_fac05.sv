//--------------------------------------------------------------------------------------------------
// Company           : Oki Electric Industry Co., Ltd.
// Project Name      : FPGA development for sonar (29SS)
// Module Name       : sp_if_top_ddr
// Function          : FPGA sp_if_top_ddr Module
// Create Date       : 2019.04.12
// Original Designer : Koshiro SHIMIZU
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// History:
//--------------------------------------------------------------------------------------------------
// Ver   | Date         | Designer          | Comment
//--------------------------------------------------------------------------------------------------
// 1.0   | 2019.04.12   | Koshiro SHIMIZU   | 新規作成
// 1.1   | 2022.09.15   | Masayuki Kato     | FAC05 制御毎に独立
//
// Copyright 2019 Oki Electric Industry Co., Ltd.
//
module sp_if_top_ddr_fac05 (											//FAC05 制御毎に独立v1.1
	//input
	input	logic			i_clk156m								,	// system clock
	input	logic			i_arst									,	// asyncronous reset
	input	logic	[3:0]	i_frame_max								,	// 入力データ格納RAMのデータ更新周期（0ori換算）
	input	logic	[31:0]	i_frame_offset0							,	// 1フレームごとの入力データ格納RAM0オフセットアドレスのオフセット値
	input	logic	[31:0]	i_frame_offset1							,	// 1フレームごとの入力データ格納RAM1オフセットアドレスのオフセット値
	input	logic	[31:0]	i_oramb_wr_offset						,	// 出力データ格納RAM PORT-Bライトアドレスのオフセット値
	input	logic			i_ctrl_startp							,	// 信号処理開始指示パルス
	input	logic			i_sp_end								,	// 信号処理完了パルス
	input	logic			i_ddr_endp								,	// DDRアクセス完了通知パルス
	input	logic			i_rd_sop								,	// Avalon-ST DDR3リードデータパケット先頭表示
	input	logic			i_rd_eop								,	// Avalon-ST DDR3リードデータパケット終了表示
	input	logic			i_rd_valid								,	// Avalon-ST DDR3リードデータパケット有効表示
	input	logic	[127:0]	i_rd_data								,	// Avalon-ST DDR3リードデータ
	input	logic			i_rd_first								,	// Avalon-ST DDR3リードデータ先頭表示（転送開始通知）
	input	logic			i_rd_last								,	// Avalon-ST DDR3リードデータ最終表示（転送完了通知）
	input	logic	[31:0]	i_iram0a_rd_addr						,	// 入力データ格納RAM0 PORT-Aリードアドレス
	input	logic			i_iram0a_rd_en							,	// 入力データ格納RAM0 PORT-Aリードアドレス有効指示
	input	logic	[31:0]	i_iram0b_rd_addr						,	// 入力データ格納RAM0 PORT-Bリードアドレス
	input	logic			i_iram0b_rd_en							,	// 入力データ格納RAM0 PORT-Bリードアドレス有効指示
	input	logic	[31:0]	i_iram1a_rd_addr						,	// 入力データ格納RAM1 PORT-Aリードアドレス
	input	logic			i_iram1a_rd_en							,	// 入力データ格納RAM1 PORT-Aリードアドレス有効指示
	input	logic	[31:0]	i_iram1b_rd_addr						,	// 入力データ格納RAM1 PORT-Bリードアドレス
	input	logic			i_iram1b_rd_en							,	// 入力データ格納RAM1 PORT-Bリードアドレス有効指示
	input	logic			i_wr_ready								,	// Avalon-ST DDR3ライト Ready
	input	logic	[31:0]	i_orama_wr_data							,	// 出力データ格納RAM PORT-Aライトデータ
	input	logic			i_orama_wr_valid						,	// 出力データ格納RAM PORT-Aライトデータ有効指示
	input	logic	[31:0]	i_oramb_wr_data							,	// 出力データ格納RAM PORT-Bライトデータ
	input	logic			i_oramb_wr_valid						,	// 出力データ格納RAM PORT-Bライトデータ有効指示
	input	logic	[3:0]	i_led_mode								,	// LEDモード設定
	input	logic	[47:0]	i_sp_err_light							,	// DBG用LED点灯条件信号
	input	logic	[47:0]	i_sp_err_flash							,	// DBG用LED点滅条件信号
	input	logic			i_skip_tx								,	// 開始コードスタート位置('0')の通知信号
	input	logic			i_sync_on								,	// レートダウン時の出力契機指示信号(0：出力する 1：出力しない)
	//output
	output	logic	[3:0]	o_frame_time							,	// フレームカウンター ※入力データ格納RAMのデータ更新周期の設定値により満了値が異なる
	output	logic			o_ddr_wxr								,	// DDRリード／ライトアクセス識別信号
	output	logic	[3:0]	o_ddr_area								,	// DDRアクセス音響データのエリア（面）指定
	output	logic	[26:0]	o_ddr_addr								,	// DDRアクセス開始アドレス
	output	logic	[31:0]	o_ddr_size								,	// DDRアクセスサイズ（byte）
	output	logic			o_ddr_start								,	// DDRアクセス開始指示
	output 	logic			o_sp_start								,	// 信号処理開始パルス（信号処理インタフェースからの指示）
	output 	logic			o_ctrl_endp								,	// 信号処理完了に伴う送信指示パルス
	output 	logic			o_rd_ready								,	// Avalon-ST 信号処理受信FIFO Ready
	output	logic	[31:0]	o_iram0a_rd_data						,	// 入力データ格納RAM0 PORT-Aリードデータ
	output	logic			o_iram0a_rd_valid						,	// 入力データ格納RAM0 PORT-Aリードデータ有効指示
	output	logic	[31:0]	o_iram0b_rd_data						,	// 入力データ格納RAM0 PORT-Bリードデータ
	output	logic			o_iram0b_rd_valid						,	// 入力データ格納RAM0 PORT-Bリードデータ有効指示
	output	logic	[31:0]	o_iram1a_rd_data						,	// 入力データ格納RAM1 PORT-Aリードデータ
	output	logic			o_iram1a_rd_valid						,	// 入力データ格納RAM1 PORT-Aリードデータ有効指示
	output	logic	[31:0]	o_iram1b_rd_data						,	// 入力データ格納RAM1 PORT-Bリードデータ
	output	logic			o_iram1b_rd_valid						,	// 入力データ格納RAM1 PORT-Bリードデータ有効指示
	output	logic			o_wr_sop								,	// Avalon-ST DDR3ライトデータパケット先頭表示
	output	logic			o_wr_eop								,	// Avalon-ST DDR3ライトデータパケット終了表示
	output	logic			o_wr_valid								,	// Avalon-ST DDR3ライトデータパケット有効表示
	output	logic	[127:0]	o_wr_data								,	// Avalon-ST DDR3ライトデータ
	output	logic			o_wr_first								,	// Avalon-ST DDR3ライトデータ先頭表示（転送開始通知）
	output	logic			o_wr_last								,	// Avalon-ST DDR3ライトデータ最終表示（転送完了通知）
	output	logic			o_ddr_endp								,	// 追加v1.1	
	output	logic	[1:0]	o_dbg_led0								,	// DBG用LED0制御信号（00:消灯、01/10:点滅、11:点灯）
	output	logic	[1:0]	o_dbg_led1								,	// DBG用LED1制御信号（00:消灯、01/10:点滅、11:点灯）
	output	logic	[1:0]	o_dbg_led2								,	// DBG用LED2制御信号（00:消灯、01/10:点滅、11:点灯）
	output	logic	[1:0]	o_dbg_led3								,	// DBG用LED3制御信号（00:消灯、01/10:点滅、11:点灯）
	output	logic	[1:0]	o_dbg_led4								,	// DBG用LED4制御信号（00:消灯、01/10:点滅、11:点灯）
	output	logic	[1:0]	o_dbg_led5								,	// DBG用LED5制御信号（00:消灯、01/10:点滅、11:点灯）
	output	logic	[1:0]	o_dbg_led6								,	// DBG用LED6制御信号（00:消灯、01/10:点滅、11:点灯）
	output	logic	[1:0]	o_dbg_led7									// DBG用LED7制御信号（00:消灯、01/10:点滅、11:点灯）
	);


//--------------------------------------------------------------------------------------------------
// Reg & Wire
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
			logic			w_rxfifo_rd_last						;
			logic			w_ddr_rd_startp							;
			logic			w_ddr_wr_startp							;
			logic	[31:0]	w_iram0_offset_addr						;
			logic	[31:0]	w_iram1_offset_addr						;


//--------------------------------------------------------------------------------------------------
// Sub Module Instance
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0

sp_if_ctrl_ddr_fac05	sp_if_ctrl_ddr_inst_fac05 (				//制御毎に独立　v1.1
//Input
	.i_clk156m				( i_clk156m           )	,
	.i_arst					( i_arst              )	,
	.i_frame_max			( i_frame_max         )	,
	.i_frame_offset0		( i_frame_offset0     )	,
	.i_frame_offset1		( i_frame_offset1     )	,
	.i_ctrl_startp			( i_ctrl_startp       )	,
	.i_skip_tx				( i_skip_tx           )	,
	.i_sync_on				( i_sync_on           )	,
	.i_sp_end				( i_sp_end            )	,
	.i_ddr_endp				( i_ddr_endp          )	,
	.i_rxfifo_rd_last		( w_rxfifo_rd_last    )	,

//Output
	.o_frame_time			( o_frame_time        )	,
	.o_ram0_offset_addr		( w_iram0_offset_addr )	,
	.o_ram1_offset_addr		( w_iram1_offset_addr )	,
	.o_ddr_wxr				( o_ddr_wxr           )	,
	.o_ddr_area				( o_ddr_area          )	,
	.o_ddr_addr				( o_ddr_addr          )	,
	.o_ddr_size				( o_ddr_size          )	,
	.o_ddr_start			( o_ddr_start         )	,
	.o_sp_start				( o_sp_start          )	,
	.o_ddr_rd_startp		( w_ddr_rd_startp     )	,
	.o_ddr_wr_startp		( w_ddr_wr_startp     )	,
	.o_ddr_endp				( o_ddr_endp		)	,			//選択信号追加 v1.1
	.o_ctrl_endp			( o_ctrl_endp         )
);


sp_if_in_ddr sp_if_in_ddr_inst (
	.i_arst					( i_arst              )	,
	.i_clk156m				( i_clk156m           )	,
	.i_rd_sop				( i_rd_sop            )	,
	.i_rd_eop				( i_rd_eop            )	,
	.i_rd_valid				( i_rd_valid          )	,
	.i_rd_data				( i_rd_data           )	,
	.o_rd_ready				( o_rd_ready          )	,
	.i_rd_first				( i_rd_first          )	,
	.i_rd_last				( i_rd_last           )	,
	.i_ddr_rd_startp		( w_ddr_rd_startp     )	,
	.i_iram0_offset_addr	( w_iram0_offset_addr )	,
	.i_iram1_offset_addr	( w_iram1_offset_addr )	,
	.i_sp_start				( o_sp_start          )	,
	.o_rxfifo_rd_last		( w_rxfifo_rd_last    )	,
//RAM0-Aport
	.i_iram0a_rd_addr		( i_iram0a_rd_addr    )	,
	.i_iram0a_rd_en			( i_iram0a_rd_en      )	,
	.o_iram0a_rd_data		( o_iram0a_rd_data    )	,
	.o_iram0a_rd_valid		( o_iram0a_rd_valid   )	,
//RAM0-Bport
	.i_iram0b_rd_addr		( i_iram0b_rd_addr    )	,
	.i_iram0b_rd_en			( i_iram0b_rd_en      )	,
	.o_iram0b_rd_data		( o_iram0b_rd_data    )	,
	.o_iram0b_rd_valid		( o_iram0b_rd_valid   )	,
//RAM1-Aport
	.i_iram1a_rd_addr		( i_iram1a_rd_addr    )	,
	.i_iram1a_rd_en			( i_iram1a_rd_en      )	,
	.o_iram1a_rd_data		( o_iram1a_rd_data    )	,
	.o_iram1a_rd_valid		( o_iram1a_rd_valid   )	,
//RAM1-Bport
	.i_iram1b_rd_addr		( i_iram1b_rd_addr    )	,
	.i_iram1b_rd_en			( i_iram1b_rd_en      )	,
	.o_iram1b_rd_data		( o_iram1b_rd_data    )	,
	.o_iram1b_rd_valid		( o_iram1b_rd_valid   )
);


sp_if_out_ddr	sp_if_out_ddr_inst (
	.i_arst					( i_arst              )	,
	.i_clk156m				( i_clk156m           )	,
	.i_oramb_wr_offset		( i_oramb_wr_offset   )	,
	.o_wr_sop				( o_wr_sop            )	,
	.o_wr_eop				( o_wr_eop            )	,
	.o_wr_valid				( o_wr_valid          )	,
	.o_wr_data				( o_wr_data           )	,
	.i_wr_ready				( i_wr_ready          )	,
	.o_wr_first				( o_wr_first          )	,
	.o_wr_last				( o_wr_last           )	,
	.i_ctrl_startp			( i_ctrl_startp       )	,
	.i_ddr_wr_startp		( w_ddr_wr_startp     )	,
	.i_ddr_size				( o_ddr_size          )	,
	.i_orama_wr_data		( i_orama_wr_data     )	,
	.i_orama_wr_valid		( i_orama_wr_valid    )	,
	.i_oramb_wr_data		( i_oramb_wr_data     )	,
	.i_oramb_wr_valid		( i_oramb_wr_valid    )
);


sp_if_led_cmd	sp_if_led_cmd_inst (
//Input
	.i_arst				( i_arst         )	,
	.i_clk156m			( i_clk156m      )	,
	.i_led_mode			( i_led_mode     )	,
	.i_sp_err_light		( i_sp_err_light )	,
	.i_sp_err_flash		( i_sp_err_flash )	,

//Output
	.o_dbg_led0			( o_dbg_led0     )	,
	.o_dbg_led1			( o_dbg_led1     )	,
	.o_dbg_led2			( o_dbg_led2     )	,
	.o_dbg_led3			( o_dbg_led3     )	,
	.o_dbg_led4			( o_dbg_led4     )	,
	.o_dbg_led5			( o_dbg_led5     )	,
	.o_dbg_led6			( o_dbg_led6     )	,
	.o_dbg_led7			( o_dbg_led7     )
);


endmodule

