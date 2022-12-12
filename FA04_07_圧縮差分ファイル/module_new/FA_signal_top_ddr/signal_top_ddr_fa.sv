//--------------------------------------------------------------------------------------------------
// Company           : Oki Electric Industry Co., Ltd.
// Project Name      : FPGA development for sonar (29SS)
// Module Name       : signal_top_ddr
// Function          : FPGA signal_top_ddr Module
// Create Date       : 2019.04.12
// Original Designer : Koshiro SHIMIZU
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// History:
//--------------------------------------------------------------------------------------------------
// Ver   | Date         | Designer          | Comment
//--------------------------------------------------------------------------------------------------
// 1.0   | 2019.04.12   | Koshiro SHIMIZU   | 新規作成
// 1.1   | 2019.04.15   | kazuki Matsusaka  | w_sp_startのlogic宣言を追加
// 1.2   | 2022.09.15   | WNT) Kato         | fa_enを追加
//
// Copyright 2019 Oki Electric Industry Co., Ltd.
//
module signal_top_ddr (
	//input
	input	logic			i_clk156m							,	// system clock
	input	logic			i_arst								,	// asyncronous reset
	input	logic			i_ctrl_startp						,	// 信号処理開始指示パルス
	input	logic			i_sync_on							,	// 開始コードスタート位置('0')の通知信号
	input	logic			i_skip_tx							,	// レートダウン時の出力契機指示信号(0：出力する 1：出力しない)
	input	logic			i_ddr_endp							,	// DDRアクセス完了通知パルス
	input	logic			i_rd_sop							,	// Avalon-ST DDR3リードデータパケット先頭表示
	input	logic			i_rd_eop							,	// Avalon-ST DDR3リードデータパケット終了表示
	input	logic			i_rd_valid							,	// Avalon-ST DDR3リードデータパケット有効表示
	input	logic	[127:0]	i_rd_data							,	// Avalon-ST DDR3リードデータ
	input	logic			i_rd_first							,	// Avalon-ST DDR3リードデータ先頭表示（転送開始通知）
	input	logic			i_rd_last							,	// Avalon-ST DDR3リードデータ最終表示（転送完了通知）
	input	logic			i_wr_ready							,	// Avalon-ST DDR3ライト Ready
	input	logic	[3:0]	i_led_mode							,	// LEDモード設定
	input	logic			i_param_valid						,	// 処理パラメーター有効指示
	input	logic	[8:0]	i_param_cnt							,	// 処理パラメーター位置指示
	input	logic	[31:0]	i_param_data						,	// 処理パラメーター
	//output
	output 	logic			o_ctrl_endp							,	// 信号処理完了に伴う送信指示パルス
	output	logic			o_ddr_wxr							,	// DDRリード／ライトアクセス識別信号
	output	logic	[3:0]	o_ddr_area							,	// DDRアクセス音響データのエリア（面）指定
	output	logic	[26:0]	o_ddr_addr							,	// DDRアクセス開始アドレス
	output	logic	[31:0]	o_ddr_size							,	// DDRアクセスサイズ（byte）
	output	logic			o_ddr_start							,	// DDRアクセス開始指示
	output 	logic			o_rd_ready							,	// Avalon-ST 信号処理受信FIFO Ready
	output	logic			o_wr_sop							,	// Avalon-ST DDR3ライトデータパケット先頭表示
	output	logic			o_wr_eop							,	// Avalon-ST DDR3ライトデータパケット終了表示
	output	logic			o_wr_valid							,	// Avalon-ST DDR3ライトデータパケット有効表示
	output	logic	[127:0]	o_wr_data							,	// Avalon-ST DDR3ライトデータ
	output	logic			o_wr_first							,	// Avalon-ST DDR3ライトデータ先頭表示（転送開始通知）
	output	logic			o_wr_last							,	// Avalon-ST DDR3ライトデータ最終表示（転送完了通知）
	output	logic	[1:0]	o_dbg_led0							,	// DBG用LED0制御信号（00:消灯、01/10:点滅、11:点灯）
	output	logic	[1:0]	o_dbg_led1							,	// DBG用LED1制御信号（00:消灯、01/10:点滅、11:点灯）
	output	logic	[1:0]	o_dbg_led2							,	// DBG用LED2制御信号（00:消灯、01/10:点滅、11:点灯）
	output	logic	[1:0]	o_dbg_led3							,	// DBG用LED3制御信号（00:消灯、01/10:点滅、11:点灯）
	output	logic	[1:0]	o_dbg_led4							,	// DBG用LED4制御信号（00:消灯、01/10:点滅、11:点灯）
	output	logic	[1:0]	o_dbg_led5							,	// DBG用LED5制御信号（00:消灯、01/10:点滅、11:点灯）
	output	logic	[1:0]	o_dbg_led6							,	// DBG用LED6制御信号（00:消灯、01/10:点滅、11:点灯）
	output	logic	[1:0]	o_dbg_led7							  	// DBG用LED7制御信号（00:消灯、01/10:点滅、11:点灯）
	);

//--------------------------------------------------------------------------------------------------
// Reg & Wire //制御ブロック毎に信号を追加　v1.2 
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
			logic			o_ctrl_endp_fa04					;	// 信号処理完了に伴う送信指示パルス
			logic			o_ddr_wxr_fa04						;	// DDRリード／ライトアクセス識別信号
			logic	[3:0]	o_ddr_area_fa04						;	// DDRアクセス音響データのエリア（面）指定
			logic	[26:0]	o_ddr_addr_fa04						;	// DDRアクセス開始アドレス
			logic	[31:0]	o_ddr_size_fa04						;	// DDRアクセスサイズ（byte）
			logic			o_ddr_start_fa04					;	// DDRアクセス開始指示
			logic			o_rd_ready_fa04						;	// Avalon-ST 信号処理受信FIFO Ready
			logic			o_wr_sop_fa04						;	// Avalon-ST DDR3ライトデータパケット先頭表示
			logic			o_wr_eop_fa04						;	// Avalon-ST DDR3ライトデータパケット終了表示
			logic			o_wr_valid_fa04						;	// Avalon-ST DDR3ライトデータパケット有効表示
			logic	[127:0]	o_wr_data_fa04						;	// Avalon-ST DDR3ライトデータ
			logic			o_wr_first_fa04						;	// Avalon-ST DDR3ライトデータ先頭表示（転送開始通知）
			logic			o_wr_last_fa04						;	// Avalon-ST DDR3ライトデータ最終表示（転送完了通知）
			logic	[1:0]	o_dbg_led0_fa04						;	// DBG用LED0制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led1_fa04						;	// DBG用LED1制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led2_fa04						;	// DBG用LED2制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led3_fa04						;	// DBG用LED3制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led4_fa04						;	// DBG用LED4制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led5_fa04						;	// DBG用LED5制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led6_fa04						;	// DBG用LED6制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led7_fa04						;	// DBG用LED7制御信号（00:消灯、01/10:点滅、11:点灯）

			logic	[3:0]	w_frame_max_fa04					;
			logic	[3:0]	w_frame_time_fa04					;
			logic	[31:0]	w_frame_offset0_fa04				;
			logic	[31:0]	w_frame_offset1_fa04				;
			logic	[31:0]	w_iram01b_wr_offset_fa04			;
			logic	[31:0]	w_oramb_wr_offset_fa04				;
			logic			w_sp_end_fa04						;
			logic	[31:0]	w_iram0a_rd_addr_fa04				;
			logic			w_iram0a_rd_en_fa04					;
			logic	[31:0]	w_iram0b_rd_addr_fa04				;
			logic			w_iram0b_rd_en_fa04					;
			logic	[31:0]	w_iram1a_rd_addr_fa04				;
			logic			w_iram1a_rd_en_fa04					;
			logic	[31:0]	w_iram1b_rd_addr_fa04				;
			logic			w_iram1b_rd_en_fa04					;
			logic	[31:0]	w_orama_wr_data_fa04				;
			logic			w_orama_wr_valid_fa04				;
			logic	[31:0]	w_oramb_wr_data_fa04				;
			logic			w_oramb_wr_valid_fa04				;
			logic	[47:0]	w_sp_err_light_fa04					;
			logic	[47:0]	w_sp_err_flash_fa04					;
			logic	[31:0]	w_iram0a_rd_data_fa04				;
			logic			w_iram0a_rd_valid_fa04				;
			logic	[31:0]	w_iram0b_rd_data_fa04				;
			logic			w_iram0b_rd_valid_fa04				;
			logic	[31:0]	w_iram1a_rd_data_fa04				;
			logic			w_iram1a_rd_valid_fa04				;
			logic	[31:0]	w_iram1b_rd_data_fa04				;
			logic			w_iram1b_rd_valid_fa04				;
			logic			w_face_change_set_fa04				;
			logic			w_sp_start_fa04						; //add v1.1

			logic			w_calc_start_fa04					;
			logic			w_param_end_fa04					;
			logic	[3:0]	w_calc_cnt_fa04						;	//v1.2

//--------------------------------------------------------------------------------------------------------------
			logic			o_ctrl_endp_fa05						;	// 信号処理完了に伴う送信指示パルス
			logic			o_ddr_wxr_fa05						;	// DDRリード／ライトアクセス識別信号
			logic	[3:0]	o_ddr_area_fa05						;	// DDRアクセス音響データのエリア（面）指定
			logic	[26:0]	o_ddr_addr_fa05						;	// DDRアクセス開始アドレス
			logic	[31:0]	o_ddr_size_fa05						;	// DDRアクセスサイズ（byte）
			logic			o_ddr_start_fa05						;	// DDRアクセス開始指示
			logic			o_rd_ready_fa05						;	// Avalon-ST 信号処理受信FIFO Ready
			logic			o_wr_sop_fa05						;	// Avalon-ST DDR3ライトデータパケット先頭表示
			logic			o_wr_eop_fa05						;	// Avalon-ST DDR3ライトデータパケット終了表示
			logic			o_wr_valid_fa05						;	// Avalon-ST DDR3ライトデータパケット有効表示
			logic	[127:0]	o_wr_data_fa05						;	// Avalon-ST DDR3ライトデータ
			logic			o_wr_first_fa05						;	// Avalon-ST DDR3ライトデータ先頭表示（転送開始通知）
			logic			o_wr_last_fa05						;	// Avalon-ST DDR3ライトデータ最終表示（転送完了通知）
			logic	[1:0]	o_dbg_led0_fa05						;	// DBG用LED0制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led1_fa05						;	// DBG用LED1制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led2_fa05						;	// DBG用LED2制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led3_fa05						;	// DBG用LED3制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led4_fa05						;	// DBG用LED4制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led5_fa05						;	// DBG用LED5制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led6_fa05						;	// DBG用LED6制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led7_fa05						;	// DBG用LED7制御信号（00:消灯、01/10:点滅、11:点灯）

			logic	[3:0]	w_frame_max_fa05					;
			logic	[3:0]	w_frame_time_fa05					;
			logic	[31:0]	w_frame_offset0_fa05				;
			logic	[31:0]	w_frame_offset1_fa05				;
			logic	[31:0]	w_iram01b_wr_offset_fa05			;
			logic	[31:0]	w_oramb_wr_offset_fa05				;
			logic			w_sp_end_fa05						;
			logic	[31:0]	w_iram0a_rd_addr_fa05				;
			logic			w_iram0a_rd_en_fa05					;
			logic	[31:0]	w_iram0b_rd_addr_fa05				;
			logic			w_iram0b_rd_en_fa05					;
			logic	[31:0]	w_iram1a_rd_addr_fa05				;
			logic			w_iram1a_rd_en_fa05					;
			logic	[31:0]	w_iram1b_rd_addr_fa05				;
			logic			w_iram1b_rd_en_fa05					;
			logic	[31:0]	w_orama_wr_data_fa05				;
			logic			w_orama_wr_valid_fa05				;
			logic	[31:0]	w_oramb_wr_data_fa05				;
			logic			w_oramb_wr_valid_fa05				;
			logic	[47:0]	w_sp_err_light_fa05					;
			logic	[47:0]	w_sp_err_flash_fa05					;
			logic	[31:0]	w_iram0a_rd_data_fa05				;
			logic			w_iram0a_rd_valid_fa05				;
			logic	[31:0]	w_iram0b_rd_data_fa05				;
			logic			w_iram0b_rd_valid_fa05				;
			logic	[31:0]	w_iram1a_rd_data_fa05				;
			logic			w_iram1a_rd_valid_fa05				;
			logic	[31:0]	w_iram1b_rd_data_fa05				;
			logic			w_iram1b_rd_valid_fa05				;
			logic			w_face_change_set_fa05				;
			logic			w_sp_start_fa05						; //add v1.1
			logic	[6:0]	o_r_state_fa04						;

			logic	w_calc_start_fa05					;
			logic	w_param_end_fa05	;

//--------------------------------------------------------------------------------------------------
// Reg & Wire
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
			logic			o_ctrl_endp_fa06					;	// 信号処理完了に伴う送信指示パルス
			logic			o_ddr_wxr_fa06						;	// DDRリード／ライトアクセス識別信号
			logic	[3:0]	o_ddr_area_fa06						;	// DDRアクセス音響データのエリア（面）指定
			logic	[26:0]	o_ddr_addr_fa06						;	// DDRアクセス開始アドレス
			logic	[31:0]	o_ddr_size_fa06						;	// DDRアクセスサイズ（byte）
			logic			o_ddr_start_fa06					;	// DDRアクセス開始指示
			logic			o_rd_ready_fa06						;	// Avalon-ST 信号処理受信FIFO Ready
			logic			o_wr_sop_fa06						;	// Avalon-ST DDR3ライトデータパケット先頭表示
			logic			o_wr_eop_fa06						;	// Avalon-ST DDR3ライトデータパケット終了表示
			logic			o_wr_valid_fa06						;	// Avalon-ST DDR3ライトデータパケット有効表示
			logic	[127:0]	o_wr_data_fa06						;	// Avalon-ST DDR3ライトデータ
			logic			o_wr_first_fa06						;	// Avalon-ST DDR3ライトデータ先頭表示（転送開始通知）
			logic			o_wr_last_fa06						;	// Avalon-ST DDR3ライトデータ最終表示（転送完了通知）
			logic	[1:0]	o_dbg_led0_fa06						;	// DBG用LED0制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led1_fa06						;	// DBG用LED1制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led2_fa06						;	// DBG用LED2制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led3_fa06						;	// DBG用LED3制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led4_fa06						;	// DBG用LED4制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led5_fa06						;	// DBG用LED5制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led6_fa06						;	// DBG用LED6制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led7_fa06						;	// DBG用LED7制御信号（00:消灯、01/10:点滅、11:点灯）

			logic	[3:0]	w_frame_max_fa06					;
			logic	[3:0]	w_frame_time_fa06					;
			logic	[31:0]	w_frame_offset0_fa06				;
			logic	[31:0]	w_frame_offset1_fa06				;
			logic	[31:0]	w_iram01b_wr_offset_fa06			;
			logic	[31:0]	w_oramb_wr_offset_fa06				;
			logic			w_sp_end_fa06						;
			logic	[31:0]	w_iram0a_rd_addr_fa06				;
			logic			w_iram0a_rd_en_fa06					;
			logic	[31:0]	w_iram0b_rd_addr_fa06				;
			logic			w_iram0b_rd_en_fa06					;
			logic	[31:0]	w_iram1a_rd_addr_fa06				;
			logic			w_iram1a_rd_en_fa06					;
			logic	[31:0]	w_iram1b_rd_addr_fa06				;
			logic			w_iram1b_rd_en_fa06					;
			logic	[31:0]	w_orama_wr_data_fa06				;
			logic			w_orama_wr_valid_fa06				;
			logic	[31:0]	w_oramb_wr_data_fa06				;
			logic			w_oramb_wr_valid_fa06				;
			logic	[47:0]	w_sp_err_light_fa06					;
			logic	[47:0]	w_sp_err_flash_fa06					;
			logic	[31:0]	w_iram0a_rd_data_fa06				;
			logic			w_iram0a_rd_valid_fa06				;
			logic	[31:0]	w_iram0b_rd_data_fa06				;
			logic			w_iram0b_rd_valid_fa06				;
			logic	[31:0]	w_iram1a_rd_data_fa06				;
			logic			w_iram1a_rd_valid_fa06				;
			logic	[31:0]	w_iram1b_rd_data_fa06				;
			logic			w_iram1b_rd_valid_fa06				;
			logic			w_face_change_set_fa06				;
			logic			w_sp_start_fa06						; //add v1.1

			logic	w_calc_start_fa06					;
			logic	w_param_end_fa06	;
//--------------------------------------------------------------------------------------------------------------
			logic			o_ctrl_endp_fa07						;	// 信号処理完了に伴う送信指示パルス
			logic			o_ddr_wxr_fa07						;	// DDRリード／ライトアクセス識別信号
			logic	[3:0]	o_ddr_area_fa07						;	// DDRアクセス音響データのエリア（面）指定
			logic	[26:0]	o_ddr_addr_fa07						;	// DDRアクセス開始アドレス
			logic	[31:0]	o_ddr_size_fa07						;	// DDRアクセスサイズ（byte）
			logic			o_ddr_start_fa07						;	// DDRアクセス開始指示
			logic			o_rd_ready_fa07						;	// Avalon-ST 信号処理受信FIFO Ready
			logic			o_wr_sop_fa07						;	// Avalon-ST DDR3ライトデータパケット先頭表示
			logic			o_wr_eop_fa07						;	// Avalon-ST DDR3ライトデータパケット終了表示
			logic			o_wr_valid_fa07						;	// Avalon-ST DDR3ライトデータパケット有効表示
			logic	[127:0]	o_wr_data_fa07						;	// Avalon-ST DDR3ライトデータ
			logic			o_wr_first_fa07						;	// Avalon-ST DDR3ライトデータ先頭表示（転送開始通知）
			logic			o_wr_last_fa07						;	// Avalon-ST DDR3ライトデータ最終表示（転送完了通知）
			logic	[1:0]	o_dbg_led0_fa07						;	// DBG用LED0制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led1_fa07						;	// DBG用LED1制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led2_fa07						;	// DBG用LED2制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led3_fa07						;	// DBG用LED3制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led4_fa07						;	// DBG用LED4制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led5_fa07						;	// DBG用LED5制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led6_fa07						;	// DBG用LED6制御信号（00:消灯、01/10:点滅、11:点灯）
			logic	[1:0]	o_dbg_led7_fa07						;	// DBG用LED7制御信号（00:消灯、01/10:点滅、11:点灯）

			logic	[3:0]	w_frame_max_fa07					;
			logic	[3:0]	w_frame_time_fa07					;
			logic	[31:0]	w_frame_offset0_fa07				;
			logic	[31:0]	w_frame_offset1_fa07				;
			logic	[31:0]	w_iram01b_wr_offset_fa07			;
			logic	[31:0]	w_oramb_wr_offset_fa07				;
			logic			w_sp_end_fa07						;
			logic	[31:0]	w_iram0a_rd_addr_fa07				;
			logic			w_iram0a_rd_en_fa07					;
			logic	[31:0]	w_iram0b_rd_addr_fa07				;
			logic			w_iram0b_rd_en_fa07					;
			logic	[31:0]	w_iram1a_rd_addr_fa07				;
			logic			w_iram1a_rd_en_fa07					;
			logic	[31:0]	w_iram1b_rd_addr_fa07				;
			logic			w_iram1b_rd_en_fa07					;
			logic	[31:0]	w_orama_wr_data_fa07				;
			logic			w_orama_wr_valid_fa07				;
			logic	[31:0]	w_oramb_wr_data_fa07				;
			logic			w_oramb_wr_valid_fa07				;
			logic	[47:0]	w_sp_err_light_fa07					;
			logic	[47:0]	w_sp_err_flash_fa07					;
			logic	[31:0]	w_iram0a_rd_data_fa07				;
			logic			w_iram0a_rd_valid_fa07				;
			logic	[31:0]	w_iram0b_rd_data_fa07				;
			logic			w_iram0b_rd_valid_fa07				;
			logic	[31:0]	w_iram1a_rd_data_fa07				;
			logic			w_iram1a_rd_valid_fa07				;
			logic	[31:0]	w_iram1b_rd_data_fa07				;
			logic			w_iram1b_rd_valid_fa07				;
			logic			w_face_change_set_fa07				;
			logic			w_sp_start_fa07						; //add v1.1

			wire	w_param_end_fa07	;

			logic	o_ddr_endp_fa04;		//DDR3ライト完了
			logic	o_ddr_endp_fa05;		//DDR3ライト完了
			logic	o_ddr_endp_fa06;		//DDR3ライト完了
			logic	o_ddr_endp_fa07;		//DDR3ライト完了


			logic	w_join_end_fa05;		//信号処理完了　v1.1
			logic	w_join_end_fa06;		//信号処理完了　v1.1
			logic	w_join_end_fa07;		//信号処理完了　v1.1


		logic	i_ddr_endp_fa04;		//DDR Access CMP v1.1
		logic	i_ddr_endp_fa05;		//DDR Access CMP v1.1
		logic	i_ddr_endp_fa06;		//DDR Access CMP v1.1
		logic	i_ddr_endp_fa07;		//DDR Access CMP v1.1

		logic	i_wr_ready_fa04;		//DDR Access CMP v1.1
		logic	i_wr_ready_fa05;		//DDR Access CMP v1.1
		logic	i_wr_ready_fa06;		//DDR Access CMP v1.1
		logic	i_wr_ready_fa07;		//DDR Access CMP v1.1

		logic	i_rd_valid_fa04;		//DDR Access CMP v1.1
		logic	i_rd_valid_fa05;		//DDR Access CMP v1.1
		logic	i_rd_valid_fa06;		//DDR Access CMP v1.1
		logic	i_rd_valid_fa07;		//DDR Access CMP v1.1

		logic	i_rd_first_fa04;		//DDR Access CMP v1.1
		logic	i_rd_first_fa05;		//DDR Access CMP v1.1
		logic	i_rd_first_fa06;		//DDR Access CMP v1.1
		logic	i_rd_first_fa07;		//DDR Access CMP v1.1

		logic	i_rd_last_fa04;		//DDR Access CMP v1.1
		logic	i_rd_last_fa05;		//DDR Access CMP v1.1
		logic	i_rd_last_fa06;		//DDR Access CMP v1.1
		logic	i_rd_last_fa07;		//DDR Access CMP v1.1

		logic	i_rd_sop_fa04;		//DDR Access CMP v1.1
		logic	i_rd_sop_fa05;		//DDR Access CMP v1.1
		logic	i_rd_sop_fa06;		//DDR Access CMP v1.1
		logic	i_rd_sop_fa07;		//DDR Access CMP v1.1

		logic	i_rd_eop_fa04;		//DDR Access CMP v1.1
		logic	i_rd_eop_fa05;		//DDR Access CMP v1.1
		logic	i_rd_eop_fa06;		//DDR Access CMP v1.1
		logic	i_rd_eop_fa07;		//DDR Access CMP v1.1

		logic[127:0]	i_rd_data_fa04;		//DDR Access CMP v1.1
		logic[127:0]	i_rd_data_fa05;		//DDR Access CMP v1.1
		logic[127:0]	i_rd_data_fa06;		//DDR Access CMP v1.1
		logic[127:0]	i_rd_data_fa07;		//DDR Access CMP v1.1

		logic[3:0]	o_rs_data_up;	//モニタ信号　v1.1
		logic[3:0]	o_rs_data_dn;	//モニタ信号　v1.1

		logic		r_calc_start_fa04;
		logic		r_calc_start_fa05;
		logic		r_calc_start_fa06;
		logic		r_calc_start_fa07;
		logic[3:0]	o_fa_en;


//--------------------------------------------------------------------------------------------------
	parameter 	Res1	= 7'b000_0001;
	parameter 	Res2 	= 7'b001_0011;


//--------------------------------------------------------------------------------------------------
// Sub Module Instance
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0

//----- 信号処理IFトップモジュールの呼出し -----　
//制御ブロック毎にモジュールを追加 FAC04 v1.2
sp_if_top_ddr_fac04	sp_if_top_ddr_04_inst (
//Input
	.i_clk156m			( i_clk156m         )						,
	.i_arst				( i_arst            )						,
	.i_frame_max		( w_frame_max_fa04       )					,
	.i_frame_offset0	( w_frame_offset0_fa04   )					,
	.i_frame_offset1	( w_frame_offset1_fa04   )					,
	.i_oramb_wr_offset	( w_oramb_wr_offset_fa04 )					,
	.i_ctrl_startp		( i_ctrl_startp     )						,
	.i_sp_end			( w_sp_end_fa04          )					,
	.i_ddr_endp			( i_ddr_endp_fa04        )						,
	.i_rd_sop			( i_rd_sop_fa04          )						,
	.i_rd_eop			( i_rd_eop_fa04          )						,
	.i_rd_valid			( i_rd_valid_fa04        )						,
	.i_rd_data			( i_rd_data_fa04         )						,
	.i_rd_first			( i_rd_first_fa04        )						,
	.i_rd_last			( i_rd_last_fa04         )						,
	.i_iram0a_rd_addr	( w_iram0a_rd_addr_fa04  )					,
	.i_iram0a_rd_en		( w_iram0a_rd_en_fa04    )					,
	.i_iram0b_rd_addr	( w_iram0b_rd_addr_fa04  )					,
	.i_iram0b_rd_en		( w_iram0b_rd_en_fa04    )					,
	.i_iram1a_rd_addr	( w_iram1a_rd_addr_fa04  )					,
	.i_iram1a_rd_en		( w_iram1a_rd_en_fa04    )					,
	.i_iram1b_rd_addr	( w_iram1b_rd_addr_fa04  )					,
	.i_iram1b_rd_en		( w_iram1b_rd_en_fa04    )					,
	.i_wr_ready			( i_wr_ready_fa04        )						,
	.i_orama_wr_data	( w_orama_wr_data_fa04   )					,
	.i_orama_wr_valid	( w_orama_wr_valid_fa04  )					,
	.i_oramb_wr_data	( w_oramb_wr_data_fa04   )					,
	.i_oramb_wr_valid	( w_oramb_wr_valid_fa04  )					,
	.i_led_mode			( i_led_mode        )						,
	.i_sp_err_light		( w_sp_err_light_fa04    )					,
	.i_sp_err_flash		( w_sp_err_flash_fa04    )					,
	.i_skip_tx			( i_skip_tx         )						,
	.i_sync_on			( i_sync_on         )						,
//Output
	.o_frame_time		( w_frame_time_fa04      )					,
	.o_ddr_wxr			( o_ddr_wxr_fa04         )					,
	.o_ddr_area			( o_ddr_area_fa04        )					,
	.o_ddr_addr			( o_ddr_addr_fa04        )					,
	.o_ddr_size			( o_ddr_size_fa04        )					,
	.o_ddr_start		( o_ddr_start_fa04       )					,
	.o_sp_start			( w_sp_start_fa04        )					,
	.o_ctrl_endp		( o_ctrl_endp_fa04       )					,	//v1.2 fac07のみ使用
	.o_rd_ready			( o_rd_ready_fa04        )					,
	.o_iram0a_rd_data	( w_iram0a_rd_data_fa04  )					,
	.o_iram0a_rd_valid	( w_iram0a_rd_valid_fa04 )					,
	.o_iram0b_rd_data	( w_iram0b_rd_data_fa04  )					,
	.o_iram0b_rd_valid	( w_iram0b_rd_valid_fa04 )					,
	.o_iram1a_rd_data	( w_iram1a_rd_data_fa04  )					,
	.o_iram1a_rd_valid	( w_iram1a_rd_valid_fa04 )					,
	.o_iram1b_rd_data	( w_iram1b_rd_data_fa04  )					,
	.o_iram1b_rd_valid	( w_iram1b_rd_valid_fa04 )					,
	.o_wr_sop			( o_wr_sop_fa04          )					,
	.o_wr_eop			( o_wr_eop_fa04          )					,
	.o_ddr_endp			( o_ddr_endp_fa04),
	.o_wr_valid			( o_wr_valid_fa04        )					,
	.o_wr_data			( o_wr_data_fa04         )					,
	.o_wr_first			( o_wr_first_fa04        )					,
	.o_wr_last			( o_wr_last_fa04         )					,
	.o_dbg_led0			( o_dbg_led0        )						,
	.o_dbg_led1			( o_dbg_led1        )						,
	.o_dbg_led2			( o_dbg_led2        )						,
	.o_dbg_led3			( o_dbg_led3        )						,
	.o_dbg_led4			( o_dbg_led4        )						,
	.o_dbg_led5			( o_dbg_led5        )						,
	.o_dbg_led6			( o_dbg_led6        )						,
	.o_dbg_led7			( o_dbg_led7        )
);


//----- 信号処理部トップモジュールの呼出し -----
//制御ブロック毎にモジュールを追加 FAC04 v1.2
sp_main_top_fac04	sp_main_top_04_inst (
//Input
	.i_clk156m			( i_clk156m         )						,
	.i_arst				( i_arst            )						,
	.i_frame_time		( w_frame_time_fa04      )					,
	.i_sp_start			( w_sp_start_fa04        )					,
	.i_sp_start_fa05	( w_sp_start_fa05        )					,//v1.2
	.i_sp_start_fa06	( w_sp_start_fa06        )					,//v1.2
	.i_sp_start_fa07	( w_sp_start_fa07        )					,//v1.2

	.i_iram0a_rd_data	( w_iram0a_rd_data_fa04  )					,
	.i_iram0a_rd_valid	( w_iram0a_rd_valid_fa04 )					,
	.i_iram0b_rd_data	( w_iram0b_rd_data_fa04  )					,
	.i_iram0b_rd_valid	( w_iram0b_rd_valid_fa04 )					,
	.i_iram1a_rd_data	( w_iram1a_rd_data_fa04  )					,
	.i_iram1a_rd_valid	( w_iram1a_rd_valid_fa04 )					,
	.i_iram1b_rd_data	( w_iram1b_rd_data_fa04  )					,
	.i_iram1b_rd_valid	( w_iram1b_rd_valid_fa04 )					,
	.i_param_valid		( i_param_valid     )						,
	.i_param_cnt		( i_param_cnt       )						,
	.i_param_data		( i_param_data      )						,
	.i_sp_end_sub		( 1'b0)						,//v1.2 制御信号を内部で生成する
	.i_ddr_endp_fa04	( o_ddr_endp_fa04)						,//v1.2
	.i_ddr_endp_fa05	( o_ddr_endp_fa05)						,//v1.2
	.i_ddr_endp_fa06	( o_ddr_endp_fa06)						,//v1.2
	.i_ddr_endp_fa07	( o_ddr_endp_fa07)						,//v1.2
	.i_calc_start_fa05	( w_calc_start_fa05)						,//v1.2
	.i_calc_start_fa06	( w_calc_start_fa06)						,//v1.2
//	.i_calc_start_fa07	( w_calc_start_fa07)						,//v1.2
	.i_join_end_fa05	(w_join_end_fa05)							,//v1.2	
	.i_join_end_fa06	(w_join_end_fa06)							,//v1.2
	.i_join_end_fa07	(w_join_end_fa07)							,//v1.2


//Output

	.o_sp_end			( w_sp_end_fa04            )					,
	.o_iram0a_rd_addr	( w_iram0a_rd_addr_fa04    )					,
	.o_iram0a_rd_en		( w_iram0a_rd_en_fa04      )					,
	.o_iram0b_rd_addr	( w_iram0b_rd_addr_fa04    )					,
	.o_iram0b_rd_en		( w_iram0b_rd_en_fa04      )					,
	.o_iram1a_rd_addr	( w_iram1a_rd_addr_fa04    )					,
	.o_iram1a_rd_en		( w_iram1a_rd_en_fa04      )					,
	.o_iram1b_rd_addr	( w_iram1b_rd_addr_fa04    )					,
	.o_iram1b_rd_en		( w_iram1b_rd_en_fa04      )					,
	.o_orama_wr_data	( w_orama_wr_data_fa04     )					,
	.o_orama_wr_valid	( w_orama_wr_valid_fa04    )					,
	.o_oramb_wr_data	( w_oramb_wr_data_fa04     )					,
	.o_oramb_wr_valid	( w_oramb_wr_valid_fa04    )					,
	.o_sp_err_light		( w_sp_err_light_fa04      )					,
	.o_sp_err_flash		( w_sp_err_flash_fa04      )					,
	.o_face_change_set	( w_face_change_set_fa04   )					,//DDR有版では未使用
	.o_frame_max		( w_frame_max_fa04         )					,
	.o_frame_offset0	( w_frame_offset0_fa04     )					,
	.o_frame_offset1	( w_frame_offset1_fa04     )					,
	.o_iram01b_wr_offset( w_iram01b_wr_offset_fa04 )					,//DDR有版では未使用
	.o_oramb_wr_offset	( w_oramb_wr_offset_fa04   )					,
   	.o_fa_en		(o_fa_en		) 					,	//v1.2
	.o_calc_start		(w_calc_start_fa04	)			,	//v1.2
//	.o_param_end_fa04	(w_param_end_fa04)				,	//v1.2
	.o_calc_cnt_fa04	(w_calc_cnt_fa04)				,	//v1.2	
    .o_r_state_fa04		(o_r_state_fa04		)				//v1.2
);

//--------------------------------------------------------------------------------------------------
// Sub Module Instance
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0

//----- 信号処理IFトップモジュールの呼出し -----
//制御ブロック毎にモジュールを追加 FAC05 v1.2
sp_if_top_ddr_fac05	sp_if_top_ddr_05_inst (
//Input
	.i_clk156m			( i_clk156m         )						,
	.i_arst				( i_arst            )						,
	.i_frame_max		( w_frame_max_fa05       )					,
	.i_frame_offset0	( w_frame_offset0_fa05   )					,
	.i_frame_offset1	( w_frame_offset1_fa05   )					,
	.i_oramb_wr_offset	( w_oramb_wr_offset_fa05 )					,
//	.i_ctrl_startp		( i_ctrl_startp     )						,
	.i_ctrl_startp		(  r_calc_start_fa04 )						,
	.i_sp_end			( w_sp_end_fa05          )					,
	.i_ddr_endp			( i_ddr_endp_fa05        )						,
	.i_rd_sop			( i_rd_sop_fa05         )						,
	.i_rd_eop			( i_rd_eop_fa05         )						,
	.i_rd_valid			( i_rd_valid_fa05        )						,
	.i_rd_data			( i_rd_data_fa05        )						,
	.i_rd_first			( i_rd_first_fa05        )						,
	.i_rd_last			( i_rd_last_fa05         )						,
	.i_iram0a_rd_addr	( w_iram0a_rd_addr_fa05  )					,
	.i_iram0a_rd_en		( w_iram0a_rd_en_fa05    )					,
	.i_iram0b_rd_addr	( w_iram0b_rd_addr_fa05  )					,
	.i_iram0b_rd_en		( w_iram0b_rd_en_fa05    )					,
	.i_iram1a_rd_addr	( w_iram1a_rd_addr_fa05  )					,
	.i_iram1a_rd_en		( w_iram1a_rd_en_fa05    )					,
	.i_iram1b_rd_addr	( w_iram1b_rd_addr_fa05  )					,
	.i_iram1b_rd_en		( w_iram1b_rd_en_fa05    )					,
	.i_wr_ready			( i_wr_ready_fa05        )						,
	.i_orama_wr_data	( w_orama_wr_data_fa05   )					,
	.i_orama_wr_valid	( w_orama_wr_valid_fa05  )					,
	.i_oramb_wr_data	( w_oramb_wr_data_fa05   )					,
	.i_oramb_wr_valid	( w_oramb_wr_valid_fa05  )					,
	.i_led_mode			( i_led_mode        )						,
	.i_sp_err_light		( w_sp_err_light_fa05    )					,
	.i_sp_err_flash		( w_sp_err_flash_fa05    )					,
	.i_skip_tx			( i_skip_tx         )						,
	.i_sync_on			( i_sync_on         )						,
//	.i_param_end		( w_param_end_fa04 ),



//Output
	.o_frame_time		( w_frame_time_fa05      )					,
	.o_ddr_wxr			( o_ddr_wxr_fa05         )					,
	.o_ddr_area			( o_ddr_area_fa05        )					,
	.o_ddr_addr			( o_ddr_addr_fa05        )					,
	.o_ddr_size			( o_ddr_size_fa05        )					,
	.o_ddr_start		( o_ddr_start_fa05       )					,
	.o_sp_start			( w_sp_start_fa05        )					,
	.o_ctrl_endp		( o_ctrl_endp_fa05       )					,	//v1.2 fac07のみ使用
	.o_rd_ready			( o_rd_ready_fa05        )					,
	.o_iram0a_rd_data	( w_iram0a_rd_data_fa05  )					,
	.o_iram0a_rd_valid	( w_iram0a_rd_valid_fa05 )					,
	.o_iram0b_rd_data	( w_iram0b_rd_data_fa05  )					,
	.o_iram0b_rd_valid	( w_iram0b_rd_valid_fa05 )					,
	.o_iram1a_rd_data	( w_iram1a_rd_data_fa05  )					,
	.o_iram1a_rd_valid	( w_iram1a_rd_valid_fa05 )					,
	.o_iram1b_rd_data	( w_iram1b_rd_data_fa05  )					,
	.o_iram1b_rd_valid	( w_iram1b_rd_valid_fa05 )					,
	.o_wr_sop			( o_wr_sop_fa05          )					,
	.o_wr_eop			( o_wr_eop_fa05          )					,
	.o_wr_valid			( o_wr_valid_fa05        )					,
	.o_wr_data			( o_wr_data_fa05         )					,
	.o_wr_first			( o_wr_first_fa05        )					,
	.o_wr_last			( o_wr_last_fa05         )					,
	.o_ddr_endp			( o_ddr_endp_fa05),
	.o_dbg_led0			( 	/*Open*/			        )						,
	.o_dbg_led1			( 	/*Open*/			        )						,
	.o_dbg_led2			(  /*Open*/			        )						,
	.o_dbg_led3			(  /*Open*/			        )						,
	.o_dbg_led4			(  /*Open*/			        )						,
	.o_dbg_led5			(  /*Open*/			       )						,
	.o_dbg_led6			(  /*Open*/			        )						,
	.o_dbg_led7			( 	/*Open*/			        )
);


//----- 信号処理部トップモジュールの呼出し -----
//制御ブロック毎にモジュールを追加 FAC05 v1.2

sp_main_top_fac05	sp_main_top_05_inst (
//Input
	.i_clk156m			( i_clk156m         )						,
	.i_arst				( i_arst            )						,
	.i_frame_time		( w_frame_time_fa05      )					,
	.i_sp_start			( w_sp_start_fa05        )					,
	.i_iram0a_rd_data	( w_iram0a_rd_data_fa05  )					,
	.i_iram0a_rd_valid	( w_iram0a_rd_valid_fa05 )					,
	.i_iram0b_rd_data	( w_iram0b_rd_data_fa05  )					,
	.i_iram0b_rd_valid	( w_iram0b_rd_valid_fa05 )					,
	.i_iram1a_rd_data	( w_iram1a_rd_data_fa05  )					,
	.i_iram1a_rd_valid	( w_iram1a_rd_valid_fa05 )					,
	.i_iram1b_rd_data	( w_iram1b_rd_data_fa05  )					,
	.i_iram1b_rd_valid	( w_iram1b_rd_valid_fa05 )					,
	.i_param_valid		( i_param_valid     )						,
	.i_param_cnt		( i_param_cnt       )						,
	.i_param_data		( i_param_data      )						,
//	.i_param_end		( w_param_end_fa04)						,	//v1.2
	.i_ddr_endp			( o_ddr_endp_fa07)						,//v1.2
	.i_sp_end_sub		( o_ddr_endp_fa04)						,	//v1.2
	.i_r_state_fa04		( o_r_state_fa04) 						,	//v1.2

//Output

	.o_sp_end			( w_sp_end_fa05            )					,
	.o_iram0a_rd_addr	( w_iram0a_rd_addr_fa05    )					,
	.o_iram0a_rd_en		( w_iram0a_rd_en_fa05      )					,
	.o_iram0b_rd_addr	( w_iram0b_rd_addr_fa05    )					,
	.o_iram0b_rd_en		( w_iram0b_rd_en_fa05      )					,
	.o_iram1a_rd_addr	( w_iram1a_rd_addr_fa05    )					,
	.o_iram1a_rd_en		( w_iram1a_rd_en_fa05      )					,
	.o_iram1b_rd_addr	( w_iram1b_rd_addr_fa05    )					,
	.o_iram1b_rd_en		( w_iram1b_rd_en_fa05      )					,
	.o_orama_wr_data	( w_orama_wr_data_fa05     )					,
	.o_orama_wr_valid	( w_orama_wr_valid_fa05    )					,
	.o_oramb_wr_data	( w_oramb_wr_data_fa05     )					,
	.o_oramb_wr_valid	( w_oramb_wr_valid_fa05    )					,
	.o_sp_err_light		( w_sp_err_light_fa05      )					,
	.o_sp_err_flash		( w_sp_err_flash_fa05      )					,
	.o_face_change_set	( w_face_change_set_fa05   )					,//DDR有版では未使用
	.o_frame_max		( w_frame_max_fa05         )					,
	.o_frame_offset0	( w_frame_offset0_fa05     )					,
	.o_frame_offset1	( w_frame_offset1_fa05     )					,
	.o_iram01b_wr_offset( w_iram01b_wr_offset_fa05 )					,//DDR有版では未使用

	.o_calc_start		(w_calc_start_fa05	)							,//v1.2
//	.o_param_end_fa05		(w_param_end_fa05),
	.w_sp_end			(w_join_end_fa05)								,//v1.2
	.o_oramb_wr_offset	( w_oramb_wr_offset_fa05   )					
);

//----- 信号処理IFトップモジュールの呼出し -----
//制御ブロック毎にモジュールを追加 FAC06 v1.2

sp_if_top_ddr_fac06	sp_if_top_ddr_06_inst (
//Input
	.i_clk156m			( i_clk156m         )						,
	.i_arst				( i_arst            )						,
	.i_frame_max		( w_frame_max_fa06       )					,
	.i_frame_offset0	( w_frame_offset0_fa06   )					,
	.i_frame_offset1	( w_frame_offset1_fa06   )					,
	.i_oramb_wr_offset	( w_oramb_wr_offset_fa06 )					,
//	.i_ctrl_startp		( i_ctrl_startp     )						,
	.i_ctrl_startp		( r_calc_start_fa05     )						,
	.i_sp_end			( w_sp_end_fa06          )					,
	.i_ddr_endp			( i_ddr_endp_fa06        )						,
	.i_rd_sop			( i_rd_sop_fa06         )						,
	.i_rd_eop			( i_rd_eop_fa06          )						,
	.i_rd_valid			( i_rd_valid_fa06        )						,
	.i_rd_data			( i_rd_data_fa06         )						,
	.i_rd_first			( i_rd_first_fa06       )						,
	.i_rd_last			( i_rd_last_fa06         )						,
	.i_iram0a_rd_addr	( w_iram0a_rd_addr_fa06  )					,
	.i_iram0a_rd_en		( w_iram0a_rd_en_fa06    )					,
	.i_iram0b_rd_addr	( w_iram0b_rd_addr_fa06  )					,
	.i_iram0b_rd_en		( w_iram0b_rd_en_fa06    )					,
	.i_iram1a_rd_addr	( w_iram1a_rd_addr_fa06  )					,
	.i_iram1a_rd_en		( w_iram1a_rd_en_fa06    )					,
	.i_iram1b_rd_addr	( w_iram1b_rd_addr_fa06  )					,
	.i_iram1b_rd_en		( w_iram1b_rd_en_fa06    )					,
	.i_wr_ready			( i_wr_ready_fa06        )						,
	.i_orama_wr_data	( w_orama_wr_data_fa06   )					,
	.i_orama_wr_valid	( w_orama_wr_valid_fa06  )					,
	.i_oramb_wr_data	( w_oramb_wr_data_fa06   )					,
	.i_oramb_wr_valid	( w_oramb_wr_valid_fa06  )					,
	.i_led_mode			( i_led_mode        )						,
	.i_sp_err_light		( w_sp_err_light_fa06    )					,
	.i_sp_err_flash		( w_sp_err_flash_fa06    )					,
	.i_skip_tx			( i_skip_tx         )						,
	.i_sync_on			( i_sync_on         )						,
//	.i_param_end		( w_param_end_fa05 ),

//Output
	.o_frame_time		( w_frame_time_fa06      )					,
	.o_ddr_wxr			( o_ddr_wxr_fa06         )					,
	.o_ddr_area			( o_ddr_area_fa06        )					,
	.o_ddr_addr			( o_ddr_addr_fa06        )					,
	.o_ddr_size			( o_ddr_size_fa06        )					,
	.o_ddr_start		( o_ddr_start_fa06       )					,
	.o_sp_start			( w_sp_start_fa06        )					,
	.o_ctrl_endp		( o_ctrl_endp_fa06       )					,	//v1.2 fac07のみ使用
	.o_rd_ready			( o_rd_ready_fa06        )					,
	.o_iram0a_rd_data	( w_iram0a_rd_data_fa06  )					,
	.o_iram0a_rd_valid	( w_iram0a_rd_valid_fa06 )					,
	.o_iram0b_rd_data	( w_iram0b_rd_data_fa06  )					,
	.o_iram0b_rd_valid	( w_iram0b_rd_valid_fa06 )					,
	.o_iram1a_rd_data	( w_iram1a_rd_data_fa06  )					,
	.o_iram1a_rd_valid	( w_iram1a_rd_valid_fa06 )					,
	.o_iram1b_rd_data	( w_iram1b_rd_data_fa06  )					,
	.o_iram1b_rd_valid	( w_iram1b_rd_valid_fa06 )					,
	.o_wr_sop			( o_wr_sop_fa06          )					,
	.o_wr_eop			( o_wr_eop_fa06          )					,
	.o_wr_valid			( o_wr_valid_fa06        )					,
	.o_wr_data			( o_wr_data_fa06         )					,
	.o_wr_first			( o_wr_first_fa06        )					,
	.o_wr_last			( o_wr_last_fa06         )					,
	.o_ddr_endp			( o_ddr_endp_fa06),
	.o_dbg_led0			( 	/*Open*/			)					,
	.o_dbg_led1			(	/*Open*/			)					,
	.o_dbg_led2			( 	/*Open*/			)					,
	.o_dbg_led3			( 	/*Open*/			)					,
	.o_dbg_led4			( 	/*Open*/			)					,
	.o_dbg_led5			( 	/*Open*/			)					,
	.o_dbg_led6			( 	/*Open*/			)					,
	.o_dbg_led7			( 	/*Open*/			)
);


//----- 信号処理部トップモジュールの呼出し -----
//制御ブロック毎にモジュールを追加 FAC06 v1.2

sp_main_top_fac06	sp_main_top_06_inst (
//Input
	.i_clk156m			( i_clk156m         )						,
	.i_arst				( i_arst            )						,
	.i_frame_time		( w_frame_time_fa06      )					,
	.i_sp_start		( w_sp_start_fa06        )					,
	.i_iram0a_rd_data	( w_iram0a_rd_data_fa06  )					,
	.i_iram0a_rd_valid	( w_iram0a_rd_valid_fa06 )					,
	.i_iram0b_rd_data	( w_iram0b_rd_data_fa06  )					,
	.i_iram0b_rd_valid	( w_iram0b_rd_valid_fa06 )					,
	.i_iram1a_rd_data	( w_iram1a_rd_data_fa06  )					,
	.i_iram1a_rd_valid	( w_iram1a_rd_valid_fa06 )					,
	.i_iram1b_rd_data	( w_iram1b_rd_data_fa06  )					,
	.i_iram1b_rd_valid	( w_iram1b_rd_valid_fa06 )					,
	.i_param_valid		( i_param_valid     )						,
	.i_param_cnt		( i_param_cnt       )						,
	.i_param_data		( i_param_data      )						,
//	.i_param_end		( w_param_end_fa05	)					,	//v1.2
	.i_ddr_endp			( o_ddr_endp_fa07)						,//v1.2
	.i_sp_end_sub		( o_ddr_endp_fa05	)					,	//v1.2
	.i_r_state_fa04		( o_r_state_fa04	)  					,	//v1.2

//Output

	.o_sp_end			( w_sp_end_fa06            )				,
	.o_iram0a_rd_addr	( w_iram0a_rd_addr_fa06    )				,
	.o_iram0a_rd_en		( w_iram0a_rd_en_fa06      )				,
	.o_iram0b_rd_addr	( w_iram0b_rd_addr_fa06    )				,
	.o_iram0b_rd_en		( w_iram0b_rd_en_fa06      )				,
	.o_iram1a_rd_addr	( w_iram1a_rd_addr_fa06    )				,
	.o_iram1a_rd_en		( w_iram1a_rd_en_fa06      )				,
	.o_iram1b_rd_addr	( w_iram1b_rd_addr_fa06    )				,
	.o_iram1b_rd_en		( w_iram1b_rd_en_fa06      )				,
	.o_orama_wr_data	( w_orama_wr_data_fa06     )				,
	.o_orama_wr_valid	( w_orama_wr_valid_fa06    )				,
	.o_oramb_wr_data	( w_oramb_wr_data_fa06     )				,
	.o_oramb_wr_valid	( w_oramb_wr_valid_fa06    )				,
	.o_sp_err_light		( w_sp_err_light_fa06      )				,
	.o_sp_err_flash		( w_sp_err_flash_fa06      )				,
	.o_face_change_set	( w_face_change_set_fa06   )				,//DDR有版では未使用
	.o_frame_max		( w_frame_max_fa06         )				,
	.o_frame_offset0	( w_frame_offset0_fa06     )				,
	.o_frame_offset1	( w_frame_offset1_fa06     )				,
	.o_iram01b_wr_offset( w_iram01b_wr_offset_fa06 )				,//DDR有版では未使用
	.o_calc_start		(w_calc_start_fa06	)					,
//	.o_param_end_fa06	(w_param_end_fa06),
	.w_sp_end			(w_join_end_fa06)								,//v1.2
	.o_oramb_wr_offset	( w_oramb_wr_offset_fa06   )	
);


//----- 信号処理IFトップモジュールの呼出し -----
//制御ブロック毎にモジュールを追加 FAC07 v1.2

sp_if_top_ddr_fac07	sp_if_top_ddr_07_inst (
//Input
	.i_clk156m			( i_clk156m         )						,
	.i_arst				( i_arst            )						,
	.i_frame_max		( w_frame_max_fa07       )					,
	.i_frame_offset0	( w_frame_offset0_fa07   )					,
	.i_frame_offset1	( w_frame_offset1_fa07   )					,
	.i_oramb_wr_offset	( w_oramb_wr_offset_fa07 )					,
//	.i_ctrl_startp		( i_ctrl_startp     )						,
	.i_ctrl_startp		( r_calc_start_fa06     )					,
	.i_sp_end			( w_sp_end_fa07          )					,
	.i_ddr_endp			( i_ddr_endp_fa07        )					,
	.i_rd_sop			( i_rd_sop_fa07          )						,
	.i_rd_eop			( i_rd_eop_fa07          )						,
	.i_rd_valid			( i_rd_valid_fa07        )						,
	.i_rd_data			( i_rd_data_fa07         )						,
	.i_rd_first			( i_rd_first_fa07        )						,
	.i_rd_last			( i_rd_last_fa07         )						,
	.i_iram0a_rd_addr	( w_iram0a_rd_addr_fa07  )					,
	.i_iram0a_rd_en		( w_iram0a_rd_en_fa07    )					,
	.i_iram0b_rd_addr	( w_iram0b_rd_addr_fa07  )					,
	.i_iram0b_rd_en		( w_iram0b_rd_en_fa07    )					,
	.i_iram1a_rd_addr	( w_iram1a_rd_addr_fa07  )					,
	.i_iram1a_rd_en		( w_iram1a_rd_en_fa07    )					,
	.i_iram1b_rd_addr	( w_iram1b_rd_addr_fa07  )					,
	.i_iram1b_rd_en		( w_iram1b_rd_en_fa07    )					,
	.i_wr_ready			( i_wr_ready_fa07        )						,
	.i_orama_wr_data	( w_orama_wr_data_fa07   )					,
	.i_orama_wr_valid	( w_orama_wr_valid_fa07  )					,
	.i_oramb_wr_data	( w_oramb_wr_data_fa07   )					,
	.i_oramb_wr_valid	( w_oramb_wr_valid_fa07  )					,
	.i_led_mode			( i_led_mode        )						,
	.i_sp_err_light		( w_sp_err_light_fa07    )					,
	.i_sp_err_flash		( w_sp_err_flash_fa07    )					,
	.i_skip_tx			( i_skip_tx         )						,
	.i_sync_on			( i_sync_on         )						,
//	.i_param_end		( w_param_end_fa06 ),

//Output
	.o_frame_time		( w_frame_time_fa07      )					,
	.o_ddr_wxr			( o_ddr_wxr_fa07         )					,
	.o_ddr_area			( o_ddr_area_fa07        )					,
	.o_ddr_addr			( o_ddr_addr_fa07        )					,
	.o_ddr_size			( o_ddr_size_fa07        )					,
	.o_ddr_start		( o_ddr_start_fa07       )					,
	.o_sp_start			( w_sp_start_fa07        )					,
	.o_ctrl_endp		( o_ctrl_endp_fa07       )					,
	.o_rd_ready			( o_rd_ready_fa07        )					,
	.o_iram0a_rd_data	( w_iram0a_rd_data_fa07  )					,
	.o_iram0a_rd_valid	( w_iram0a_rd_valid_fa07 )					,
	.o_iram0b_rd_data	( w_iram0b_rd_data_fa07  )					,
	.o_iram0b_rd_valid	( w_iram0b_rd_valid_fa07 )					,
	.o_iram1a_rd_data	( w_iram1a_rd_data_fa07  )					,
	.o_iram1a_rd_valid	( w_iram1a_rd_valid_fa07 )					,
	.o_iram1b_rd_data	( w_iram1b_rd_data_fa07  )					,
	.o_iram1b_rd_valid	( w_iram1b_rd_valid_fa07 )					,
	.o_wr_sop			( o_wr_sop_fa07          )					,
	.o_wr_eop			( o_wr_eop_fa07          )					,
	.o_wr_valid			( o_wr_valid_fa07        )					,
	.o_wr_data			( o_wr_data_fa07         )					,
	.o_wr_first			( o_wr_first_fa07        )					,
	.o_wr_last			( o_wr_last_fa07         )					,
	.o_ddr_endp			( o_ddr_endp_fa07),
	.o_dbg_led0			( 	/*Open*/			)					,
	.o_dbg_led1			(	/*Open*/			)					,
	.o_dbg_led2			( 	/*Open*/			)					,
	.o_dbg_led3			( 	/*Open*/			)					,
	.o_dbg_led4			( 	/*Open*/			)					,
	.o_dbg_led5			( 	/*Open*/			)					,
	.o_dbg_led6			( 	/*Open*/			)					,
	.o_dbg_led7			( 	/*Open*/			)
);


//----- 信号処理部トップモジュールの呼出し -----
//制御ブロック毎にモジュールを追加 FAC07 v1.2

sp_main_top_fac07	sp_main_top_07_inst (
//Input
	.i_clk156m			( i_clk156m         )						,
	.i_arst				( i_arst            )						,
	.i_frame_time		( w_frame_time_fa07      )					,
	.i_sp_start			( w_sp_start_fa07        )					,
	.i_iram0a_rd_data	( w_iram0a_rd_data_fa07  )					,
	.i_iram0a_rd_valid	( w_iram0a_rd_valid_fa07 )					,
	.i_iram0b_rd_data	( w_iram0b_rd_data_fa07  )					,
	.i_iram0b_rd_valid	( w_iram0b_rd_valid_fa07 )					,
	.i_iram1a_rd_data	( w_iram1a_rd_data_fa07  )					,
	.i_iram1a_rd_valid	( w_iram1a_rd_valid_fa07 )					,
	.i_iram1b_rd_data	( w_iram1b_rd_data_fa07  )					,
	.i_iram1b_rd_valid	( w_iram1b_rd_valid_fa07 )					,
	.i_param_valid		( i_param_valid     )						,
	.i_param_cnt		( i_param_cnt       )						,
	.i_param_data		( i_param_data      )						,
//	.i_param_end		( w_param_end_fa06	)					,	//v1.2
	.i_ddr_endp			( o_ddr_endp_fa07	)						,//v1.2
	.i_sp_end_sub		( o_ddr_endp_fa06	)					,	//v1.2
    	.i_r_state_fa04		( o_r_state_fa04	) 					,	//v1.2

//Output

	.o_sp_end			( w_sp_end_fa07            )				,
	.o_iram0a_rd_addr	( w_iram0a_rd_addr_fa07    )				,
	.o_iram0a_rd_en		( w_iram0a_rd_en_fa07      )				,
	.o_iram0b_rd_addr	( w_iram0b_rd_addr_fa07    )				,
	.o_iram0b_rd_en		( w_iram0b_rd_en_fa07      )				,
	.o_iram1a_rd_addr	( w_iram1a_rd_addr_fa07    )				,
	.o_iram1a_rd_en		( w_iram1a_rd_en_fa07      )				,
	.o_iram1b_rd_addr	( w_iram1b_rd_addr_fa07    )				,
	.o_iram1b_rd_en		( w_iram1b_rd_en_fa07      )				,
	.o_orama_wr_data	( w_orama_wr_data_fa07     )				,
	.o_orama_wr_valid	( w_orama_wr_valid_fa07    )				,
	.o_oramb_wr_data	( w_oramb_wr_data_fa07     )				,
	.o_oramb_wr_valid	( w_oramb_wr_valid_fa07    )				,
	.o_sp_err_light		( w_sp_err_light_fa07      )				,
	.o_sp_err_flash		( w_sp_err_flash_fa07      )				,
	.o_face_change_set	( w_face_change_set_fa07   )				,//DDR有版では未使用
	.o_frame_max		( w_frame_max_fa07         )				,
	.o_frame_offset0	( w_frame_offset0_fa07     )				,
	.o_frame_offset1	( w_frame_offset1_fa07     )				,
	.o_iram01b_wr_offset	( w_iram01b_wr_offset_fa07 )				,//DDR有版では未使用
//	.o_calc_start		(w_calc_start_fa07	)					,
//	.o_param_end_fa07	(w_param_end_fa07),
	.w_sp_end			(w_join_end_fa07)								,//v1.2
	.o_oramb_wr_offset	( w_oramb_wr_offset_fa07   )	
);

//----- 信号SELトップモジュールの呼出し -----

//Input
signal_sel	signal_sel_inst(
	.i_arst(i_arst)								,
	.i_clk156m(i_clk156m)							,
	.i_ctrl_startp(i_ctrl_startp),
	.i_calc_start_fa04(w_calc_start_fa04),
	.i_calc_start_fa05(w_calc_start_fa05),
	.i_calc_start_fa06(w_calc_start_fa06),

	.i_ddr_wxr_fa04(o_ddr_wxr_fa04)					,
	.i_ddr_area_fa04(o_ddr_area_fa04)				,
	.i_ddr_addr_fa04(o_ddr_addr_fa04)				,
	.i_ddr_size_fa04(o_ddr_size_fa04)				,
	.i_ddr_start_fa04(o_ddr_start_fa04)				,
	.i_rd_ready_fa04(o_rd_ready_fa04)				,
	.i_wr_sop_fa04(o_wr_sop_fa04)					,
	.i_wr_eop_fa04(o_wr_eop_fa04)					,
	.i_wr_valid_fa04(o_wr_valid_fa04)				,
	.i_wr_data_fa04(o_wr_data_fa04)					,
	.i_wr_first_fa04(o_wr_first_fa04) ,
	.i_wr_last_fa04(o_wr_last_fa04) ,

	.i_ddr_wxr_fa05(o_ddr_wxr_fa05)					,
	.i_ddr_area_fa05(o_ddr_area_fa05)				,
	.i_ddr_addr_fa05(o_ddr_addr_fa05)				,
	.i_ddr_size_fa05(o_ddr_size_fa05)				,
	.i_ddr_start_fa05(o_ddr_start_fa05)				,
	.i_rd_ready_fa05(o_rd_ready_fa05)				,
	.i_wr_sop_fa05(o_wr_sop_fa05)					,
	.i_wr_eop_fa05(o_wr_eop_fa05)					,
	.i_wr_valid_fa05(o_wr_valid_fa05)				,
	.i_wr_data_fa05(o_wr_data_fa05)					,
	.i_wr_first_fa05(o_wr_first_fa05) 				,
	.i_wr_last_fa05(o_wr_last_fa05) 				,

	.i_ddr_wxr_fa06(o_ddr_wxr_fa06)					,
	.i_ddr_area_fa06(o_ddr_area_fa06)				,
	.i_ddr_addr_fa06(o_ddr_addr_fa06)				,
	.i_ddr_size_fa06(o_ddr_size_fa06)				,
	.i_ddr_start_fa06(o_ddr_start_fa06)				,
	.i_rd_ready_fa06(o_rd_ready_fa06)				,
	.i_wr_sop_fa06(o_wr_sop_fa06)					,
	.i_wr_eop_fa06(o_wr_eop_fa06)					,
	.i_wr_valid_fa06(o_wr_valid_fa06)				,
	.i_wr_data_fa06(o_wr_data_fa06)					,
	.i_wr_first_fa06(o_wr_first_fa06) ,
	.i_wr_last_fa06(o_wr_last_fa06) ,

	.i_ddr_wxr_fa07(o_ddr_wxr_fa07)					,
	.i_ddr_area_fa07(o_ddr_area_fa07)				,
	.i_ddr_addr_fa07(o_ddr_addr_fa07)				,
	.i_ddr_size_fa07(o_ddr_size_fa07)				,
	.i_ddr_start_fa07(o_ddr_start_fa07)				,
	.i_rd_ready_fa07(o_rd_ready_fa07)				,
	.i_wr_sop_fa07(o_wr_sop_fa07)					,
	.i_wr_eop_fa07(o_wr_eop_fa07)					,
	.i_wr_valid_fa07(o_wr_valid_fa07)				,
	.i_wr_data_fa07(o_wr_data_fa07)					,
	.i_wr_first_fa07(o_wr_first_fa07) 				,
	.i_wr_last_fa07(o_wr_last_fa07) 				,

	.i_r_state_fa04(o_r_state_fa04)					,
	.fa_en(o_fa_en)									,

	.i_ddr_endp(i_ddr_endp)							,				//DDR Access v1.1
	.i_rd_valid(i_rd_valid)							,				//DDR Access v1.1
	.i_rd_first(i_rd_first)							,				//DDR Access v1.1
	.i_rd_last(i_rd_last)							,				//DDR Access v1.1
	.i_rd_sop(i_rd_sop)								,				//DDR Access v1.1
	.i_rd_eop(i_rd_eop)								,				//DDR Access v1.1
	.i_rd_data(i_rd_data)							,				//DDR Access v1.1
	.i_wr_ready(i_wr_ready)							, 				//DDR Access v1.1
	.i_calc_cnt(w_calc_cnt_fa04)					,				//v1.1


//Output
	.o_ddr_wxr(o_ddr_wxr)							,
	.o_ddr_area(o_ddr_area)							,
	.o_ddr_addr(o_ddr_addr)							,
	.o_ddr_size(o_ddr_size)							,
	.o_ddr_start(o_ddr_start)						,
	.o_rd_ready(o_rd_ready)							,
	.o_wr_sop(o_wr_sop)								,
	.o_wr_eop(o_wr_eop)								,
	.o_wr_valid(o_wr_valid)							,
	.o_wr_data(o_wr_data)							,
	.o_wr_first(o_wr_first) 						,
	.o_wr_last(o_wr_last) 							,	

	.o_ddr_endp_fa04(i_ddr_endp_fa04)				,	//DDR Access CMP v1.1
	.o_ddr_endp_fa05(i_ddr_endp_fa05)				,	//DDR Access CMP v1.1
	.o_ddr_endp_fa06(i_ddr_endp_fa06)				,	//DDR Access CMP v1.1
	.o_ddr_endp_fa07(i_ddr_endp_fa07)				,	//DDR Access CMP v1.1

	.o_rd_valid_fa04(i_rd_valid_fa04)				,	//DDR Access  v1.1
	.o_rd_valid_fa05(i_rd_valid_fa05)				,	//DDR Access  v1.1
	.o_rd_valid_fa06(i_rd_valid_fa06)				,	//DDR Access  v1.1
	.o_rd_valid_fa07(i_rd_valid_fa07)				,	//DDR Access  v1.1

	.o_rd_first_fa04(i_rd_first_fa04)				,	//DDR Access  v1.1
	.o_rd_first_fa05(i_rd_first_fa05)				,	//DDR Access  v1.1
	.o_rd_first_fa06(i_rd_first_fa06)				,	//DDR Access  v1.1
	.o_rd_first_fa07(i_rd_first_fa07)				,	//DDR Access  v1.1
	
	.o_rd_last_fa04(i_rd_last_fa04)					,	//DDR Access  v1.1
	.o_rd_last_fa05(i_rd_last_fa05)					,	//DDR Access  v1.1
	.o_rd_last_fa06(i_rd_last_fa06)					,	//DDR Access  v1.1
	.o_rd_last_fa07(i_rd_last_fa07)					,	//DDR Access  v1.1

	.o_rd_sop_fa04(i_rd_sop_fa04)					,	//DDR Access  v1.1
	.o_rd_sop_fa05(i_rd_sop_fa05)					,	//DDR Access  v1.1
	.o_rd_sop_fa06(i_rd_sop_fa06)					,	//DDR Access  v1.1
	.o_rd_sop_fa07(i_rd_sop_fa07)					,	//DDR Access  v1.1

	.o_rd_eop_fa04(i_rd_eop_fa04)					,	//DDR Access  v1.1
	.o_rd_eop_fa05(i_rd_eop_fa05)					,	//DDR Access  v1.1
	.o_rd_eop_fa06(i_rd_eop_fa06)					,	//DDR Access  v1.1
	.o_rd_eop_fa07(i_rd_eop_fa07)					,	//DDR Access  v1.1

	.o_rd_data_fa04(i_rd_data_fa04)					,	//DDR Access  v1.1
	.o_rd_data_fa05(i_rd_data_fa05)					,	//DDR Access  v1.1
	.o_rd_data_fa06(i_rd_data_fa06)					,	//DDR Access  v1.1
	.o_rd_data_fa07(i_rd_data_fa07)					,	//DDR Access  v1.1

	.o_wr_ready_fa04(i_wr_ready_fa04)				,	//DDR Access  v1.1
	.o_wr_ready_fa05(i_wr_ready_fa05)				,	//DDR Access  v1.1
	.o_wr_ready_fa06(i_wr_ready_fa06)				,	//DDR Access  v1.1
	.o_wr_ready_fa07(i_wr_ready_fa07) 				,	//DDR Access  v1.1

	.r_calc_start_fa04(r_calc_start_fa04)				,
	.r_calc_start_fa05(r_calc_start_fa05)				,
	.r_calc_start_fa06(r_calc_start_fa06)				
);


assign o_ctrl_endp = o_ctrl_endp_fa07;



endmodule

