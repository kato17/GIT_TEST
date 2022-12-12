//--------------------------------------------------------------------------------------------------
// Company           : Oki Electric Industry Co., Ltd.
// Project Name      : FPGA development for sonar (29SS)
// Module Name       : sp_main_top (fac04)
// Function          : FPGA sp_main_top Module
// Create Date       : 2019.06.07
// Original Designer : Hidehiko Masuda
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// History:
//--------------------------------------------------------------------------------------------------
// Ver   | Date         | Designer          | Comment
//--------------------------------------------------------------------------------------------------
// 1.0   | 2019.06.07   | Hidehiko Masuda   | 新規作成
// 1.1   | 2022.09.15   | Masayuki Kato     | 制御毎に独立
//
// Copyright 2019 Oki Electric Industry Co., Ltd.
//
//--------------------------------------------------------------------------------------------------
// Module & Port
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
module sp_main_top_fac04 (												//モジュール名変更 v1.1

// input
	input	logic			i_clk156m								,	// system clock
	input	logic			i_arst									,	// asyncronous reset
	input	logic	[3:0]	i_frame_time							,	// フレームカウンター ※入力データ格納RAMのデータ更新周期の設定値により満了値が異なる
	input 	logic			i_sp_start						,	// 信号処理開始パルス（信号処理インタフェースからの指示）
	input 	logic			i_sp_start_fa05						,	// 信号処理開始パルス（信号処理インタフェースからの指示）v1.1
	input 	logic			i_sp_start_fa06						,	// 信号処理開始パルス（信号処理インタフェースからの指示）v1.1
	input 	logic			i_sp_start_fa07						,	// 信号処理開始パルス（信号処理インタフェースからの指示）v1.1
	input	logic	[31:0]	i_iram0a_rd_data						,	// 入力データ格納RAM0 PORT-Aリードデータ
	input	logic			i_iram0a_rd_valid						,	// 入力データ格納RAM0 PORT-Aリードデータ有効指示
	input	logic	[31:0]	i_iram0b_rd_data						,	// 入力データ格納RAM0 PORT-Bリードデータ
	input	logic			i_iram0b_rd_valid						,	// 入力データ格納RAM0 PORT-Bリードデータ有効指示
	input	logic	[31:0]	i_iram1a_rd_data						,	// 入力データ格納RAM1 PORT-Aリードデータ
	input	logic			i_iram1a_rd_valid						,	// 入力データ格納RAM1 PORT-Aリードデータ有効指示
	input	logic	[31:0]	i_iram1b_rd_data						,	// 入力データ格納RAM1 PORT-Bリードデータ
	input	logic			i_iram1b_rd_valid						,	// 入力データ格納RAM1 PORT-Bリードデータ有効指示
	input	logic			i_param_valid							,	// 処理パラメーター有効指示
	input	logic	[8:0]	i_param_cnt								,	// 処理パラメーター位置指示
	input	logic	[31:0]	i_param_data							,	// 処理パラメーター
	input	logic			i_sp_end_sub							,	//前段モジュールからの受信 v1.1
	input	logic			i_ddr_endp_fa04							,	//DDR3リード完了(応答) v1.1
	input	logic			i_ddr_endp_fa05							,	//DDR3リード完了(応答) v1.1
	input	logic			i_ddr_endp_fa06							,	//DDR3リード完了(応答) v1.1
	input	logic			i_ddr_endp_fa07							,	//DDR3リード完了(応答) v1.1
	input	logic			i_calc_start_fa05						,	//演算開始指示　v1.1
	input	logic			i_calc_start_fa06						,	//演算開始指示　v1.1
//	input	logic			i_calc_start_fa07						,	//演算開始指示　v1.1
	input	logic			i_join_end_fa05							,	//v1.1
	input	logic			i_join_end_fa06							,	//v1.1
	input	logic			i_join_end_fa07							,	//v1.1


// output
	output	logic			o_sp_end								,	// 信号処理完了パルス
	output	logic	[31:0]	o_iram0a_rd_addr						,	// 入力データ格納RAM0 PORT-Aリードアドレス
	output	logic			o_iram0a_rd_en							,	// 入力データ格納RAM0 PORT-Aリードアドレス有効指示
	output	logic	[31:0]	o_iram0b_rd_addr						,	// 入力データ格納RAM0 PORT-Bリードアドレス
	output	logic			o_iram0b_rd_en							,	// 入力データ格納RAM0 PORT-Bリードアドレス有効指示
	output	logic	[31:0]	o_iram1a_rd_addr						,	// 入力データ格納RAM1 PORT-Aリードアドレス
	output	logic			o_iram1a_rd_en							,	// 入力データ格納RAM1 PORT-Aリードアドレス有効指示
	output	logic	[31:0]	o_iram1b_rd_addr						,	// 入力データ格納RAM1 PORT-Bリードアドレス
	output	logic			o_iram1b_rd_en							,	// 入力データ格納RAM1 PORT-Bリードアドレス有効指示
	output	logic	[31:0]	o_orama_wr_data							,	// 出力データ格納RAM PORT-Aライトデータ
	output	logic			o_orama_wr_valid						,	// 出力データ格納RAM PORT-Aライトデータ有効指示
	output	logic	[31:0]	o_oramb_wr_data							,	// 出力データ格納RAM PORT-Bライトデータ
	output	logic			o_oramb_wr_valid						,	// 出力データ格納RAM PORT-Bライトデータ有効指示
	output	logic	[47:0]	o_sp_err_light							,	// DBG用LED点灯条件信号
	output	logic	[47:0]	o_sp_err_flash							,	// DBG用LED点滅条件信号
//
//	output	logic	o_join_end_p									,	// v1.2
	output	logic	o_calc_start									,	// 追加　v1.1

// sp_if_top Parameter
	output	logic			o_face_change_set						,	// 信号処理インターフェース部の面切り替えON/OFF設定（1:切り替え有　0:切り替え無）
	output	logic	[3:0]	o_frame_max								,	// 入力データ格納RAMのデータ更新周期（0ori換算）
	output	logic	[31:0]	o_frame_offset0							,	// 1フレームごとの入力データ格納RAM0オフセットアドレスのオフセット値
	output	logic	[31:0]	o_frame_offset1							,	// 1フレームごとの入力データ格納RAM1オフセットアドレスのオフセット値
	output	logic	[31:0]	o_iram01b_wr_offset						,	// 入力データ格納RAM0,1共通 PORT-Bライトアドレスのオフセット値
	output	logic	[3:0]	o_fa_en									, 	// 状態選択信号 v1.1
//	output	logic			o_param_end_fa04						,	// v1.1
	output	logic	[6:0]	o_r_state_fa04							,	// 状態遷移v1.1					
	output	logic	[3:0]	o_calc_cnt_fa04							,//v1.1
	output	logic	[31:0]	o_oramb_wr_offset							// 出力データ格納RAM PORT-Bライトアドレスのオフセット値

);

//--------------------------------------------------------------------------------------------------
// Parameter
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// 信号処理IF部共通パラメータ
	parameter	P_face_change_set	= 1'b0			;	// 信号処理インターフェース部の面切り替えON/OFF設定（1:切り替え有　0:切り替え無）
	parameter	P_frame_max			= 4'h1			;	// 入力データ格納RAMのデータ更新周期（0ori換算）
	parameter	P_frame_offset0		= 32'h0000_2400	;	// 1フレームごとの入力データ格納RAM0オフセットアドレスのオフセット値
	parameter	P_frame_offset1		= 32'h0000_2400	;	// 1フレームごとの入力データ格納RAM1オフセットアドレスのオフセット値
	parameter	P_iram01b_wr_offset	= 32'h0000_0000	;	// 入力データ格納RAM0,1共通 PORT-Bライトアドレスのオフセット値
	parameter	P_oramb_wr_offset	= 32'h0000_0360	;	// 出力データ格納RAM PORT-Bライトアドレスのオフセット値

// 信号処理部固有パラメータ
	parameter	P_sample_num		= 12'd128		;	// 演算1回毎の処理サンプル数
	parameter	P_stave_num			= 11'd144		;	// 演算1回毎の処理ステーブ数
	parameter	P_beam_num0			= 10'd27		;	// 演算1回毎の演算ビーム数（整相処理0側）
	parameter	P_beam_num1			= 10'd27		;	// 演算1回毎の演算ビーム数（整相処理1側）
	parameter	P_odata_num0		= 20'd3456		;	// 演算1回毎の演算結果データ総数（整相処理0側）
	parameter	P_odata_num1		= 20'd3456		;	// 演算1回毎の演算結果データ総数（整相処理1側）
	parameter	P_stv_add_num		= 11'd144		;	// ステーブ加算時の加算対象ステーブ数
	parameter	P_sp_adr_offset		= 32'h0000_0000	;	// 諸元算出のリードアドレスオフセット値
	parameter	P_se_adr_offset		= 32'h0000_0000	;	// 位置ベクトルのリードアドレスオフセット値
	parameter	P_se_data_size		= 12'd0			;	// 位置ベクトルのリードデータ量
	parameter	P_pad_size			= 20'd0			;	// パディングデータ付与量
	parameter	P_fs				= 32'h4680_0000	;	// サンプリング周波数
	parameter	P_ts				= 32'h3880_0000	;	// サンプリング周期
	parameter	P_fs_del_smpl		= 32'h4948_0000	;	// 詳細遅延フィルターインデックス用係数
	parameter	P_offst_dly_fil		= 6'd25			;	// 詳細遅延フィルターオフセット値
	parameter	P_offst_dly_smpl	= 12'd512		;	// 遅延バッファーオフセット値
	parameter	P_buff_size			= 13'd1024		;	// 遅延バッファーサイズ
	parameter	P_buff_unit			= 6'd8			;	// 遅延バッファー面個数
	parameter	P_pcnt_snd_spd		= 9'd9			;	// 処理パラ「音速」格納位置
	parameter	P_pcnt_beam_phi0	= 9'd43			;	// 処理パラ「ふ仰角値1」格納位置
	parameter	P_pcnt_beam_phi1	= 9'd0			;	// 処理パラ「ふ仰角値2」格納位置
	parameter	P_pcnt_beam_phi2	= 9'd0			;	// 処理パラ「ふ仰角値3」格納位置
	parameter	P_pcnt_beam_phi3	= 9'd0			;	// 処理パラ「ふ仰角値4」格納位置
	parameter	P_pcnt_beam_phi4	= 9'd0			;	// 処理パラ「ふ仰角値5」格納位置
	parameter	P_pcnt_beam_phi5	= 9'd0			;	// 処理パラ「ふ仰角値6」格納位置
	parameter	P_pcnt_beam_phi6	= 9'd0			;	// 処理パラ「ふ仰角値7」格納位置
	parameter	P_pcnt_beam_phi7	= 9'd0			;	// 処理パラ「ふ仰角値8」格納位置
	parameter	P_beam_phi_cnt0		= 10'd1			;	// ふ仰角値カウントアップビーム数（整相処理0側）
	parameter	P_beam_phi_cnt1		= 10'd1			;	// ふ仰角値カウントアップビーム数（整相処理1側）
	parameter	P_beam_phi_max0		= 4'd1			;	// ふ仰角値カウント最大値（整相処理0側）
	parameter	P_beam_phi_max1		= 4'd1			;	// ふ仰角値カウント最大値（整相処理1側）
	parameter	P_calc_num			= 5'd4			;	// 1フレームあたりの信号処理回数
	parameter	P_system			= 1'b0			;	// センサー種別指定（1:TA 0:FA）
	parameter	P_beam_start_num0	= 10'd0			;	// 開始ビーム番号（整相処理0側）
	parameter	P_beam_start_num1	= 10'd27		;	// 開始ビーム番号（整相処理1側）
	parameter	P_beam_period		= 18'd18432		;	// 1ビームあたりのサンプル数

//--------------------------------------------------------------------------------------------------
// Reg/Wire/Logic
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0

	logic			w_sp_end			;	// xa_pad_join_inst => xa_bf_ctrl_inst
	logic	[4:0]	w_frame_time		;	// xa_bf_ctrl_inst => xa_bf_top_inst0, xa_bf_top_inst1
	logic			w_calc_start		;	// xa_bf_ctrl_inst => xa_bf_top_inst0, xa_bf_top_inst1
	logic	[19:0]	w_pad_size			;	// xa_bf_ctrl_inst => xa_pad_join_inst
	logic			w_end_ins			;	// xa_bf_ctrl_inst => xa_pad_join_inst
	logic			w_param_start		;	// xa_bf_ctrl_inst => xa_bf_top_inst0, xa_bf_top_inst1
	logic			w_param_end			;	// xa_bf_top_inst0 => xa_bf_ctrl_inst
	logic			w_calc_end			;	// xa_bf_top_inst1 => xa_pad_join_inst
	logic	[31:0]	w_oramb_wr_data		;	// xa_bf_top_inst1 => xa_pad_join_inst
	logic			w_oramb_wr_valid	;	// xa_bf_top_inst1 => xa_pad_join_inst

//--------------------------------------------------------------------------------------------------
// Parameter Output
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0

	assign o_face_change_set	= P_face_change_set		;
	assign o_frame_max 			= P_frame_max			;
//	assign o_frame_offset0		= P_frame_offset0		;	// 整相処理制御モジュールから出力
	assign o_frame_offset1		= P_frame_offset1		;
	assign o_iram01b_wr_offset	= P_iram01b_wr_offset	;
	assign o_oramb_wr_offset	= P_oramb_wr_offset		;

//--------------------------------------------------------------------------------------------------
// Unused Output
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0

//	assign	o_iram1a_rd_addr		= 32'd0		;	// 入力データ格納RAM1 PORT-Aリードアドレス
//	assign	o_iram1a_rd_en			= 1'b0		;	// 入力データ格納RAM1 PORT-Aリードアドレス有効指示
//	assign	o_iram1b_rd_addr		= 32'd0		;	// 入力データ格納RAM1 PORT-Bリードアドレス
//	assign	o_iram1b_rd_en			= 1'b0		;	// 入力データ格納RAM1 PORT-Bリードアドレス有効指示
//	assign	o_oramb_wr_data			= 32'd0		;	// 出力データ格納RAM PORT-Bライトデータ
//	assign	o_oramb_wr_valid		= 1'b0		;	// 出力データ格納RAM PORT-Bライトデータ有効指示
	assign	o_sp_err_light[47:6]	= 42'd0		;	// DBG用LED点灯条件信号
	assign	o_sp_err_flash			= 48'd0		;	// DBG用LED点滅条件信号

	assign o_calc_start				= w_calc_start	;	//v1.1	
//	assign o_sp_end					= w_sp_end		;	//v1.1
//--------------------------------------------------------------------------------------------------
// Sub Module
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
//------------------------------------//
//          入出力NaNチェック         //
//------------------------------------//
	inout_nanchk inout_nanchk_inst (
		.i_clk156m				( i_clk156m           ),
		.i_arst					( i_arst              ),
		.i_iram0a_rd_data		( i_iram0a_rd_data    ),
		.i_iram0a_rd_valid		( i_iram0a_rd_valid   ),
		.i_iram0b_rd_data		( i_iram0b_rd_data    ),
		.i_iram0b_rd_valid		( i_iram0b_rd_valid   ),
		.i_iram1a_rd_data		( i_iram1a_rd_data    ),
		.i_iram1a_rd_valid		( i_iram1a_rd_valid   ),
		.i_iram1b_rd_data		( i_iram1b_rd_data    ),
		.i_iram1b_rd_valid		( i_iram1b_rd_valid   ),
		.i_orama_wr_data		( o_orama_wr_data     ),
		.i_orama_wr_valid		( o_orama_wr_valid    ),
		.i_oramb_wr_data		( o_oramb_wr_data     ),
		.i_oramb_wr_valid		( o_oramb_wr_valid    ),
		.o_sp_err_light			( o_sp_err_light[5:0] )
	);

//------------------------------------//
//            信号処理部関連          //
//------------------------------------//
	// 整相処理制御モジュール
	xa_bf_ctrl_fac04 #(										//v1.1
		.P_frame_max			( P_frame_max          ),	// 入力データ格納RAMのデータ更新周期（0ori換算）	// [v1.1]
		.P_pad_size				( P_pad_size           ),	// パディングデータ付与量
		.P_calc_num				( P_calc_num           )	// 信号処理回数
		)
	xa_bf_ctrl_inst (
		.i_arst					( i_arst               ),	// 非同期リセット
		.i_clk156m				( i_clk156m            ),	// クロック
		.i_frame_time			( i_frame_time         ),	// 現在のフレーム数
		.i_sp_start				( i_sp_start           ),	// 信号処理開始パルス
		.i_sp_start_fa05				( i_sp_start_fa05           ),	// 信号処理開始パルスv1.1
		.i_sp_start_fa06				( i_sp_start_fa06           ),	// 信号処理開始パルスv1.1
		.i_sp_start_fa07				( i_sp_start_fa07           ),	// 信号処理開始パルスv1.1
		.i_sp_end				( w_sp_end             ),	// 演算処理完了パルス（信号処理部からの入力）
		.i_frame_offset			( P_frame_offset0      ),	// sp_main_topからのP_frame_offset0値入力
		.i_param_end			( w_param_end          ),	// 音速・位置ベクトル転送完了通知
		.i_system				( P_system             ),	// システム設定
		.i_ddr_endp_fa04		(i_ddr_endp_fa04		),	//DDR3リード完了(応答)v1.1
		.i_ddr_endp_fa05		(i_ddr_endp_fa05		),	//DDR3リード完了(応答)v1.1
		.i_ddr_endp_fa06		(i_ddr_endp_fa06		),	//DDR3リード完了(応答)v1.1
		.i_ddr_endp_fa07		(i_ddr_endp_fa07		),	//DDR3リード完了(応答)v1.1
		.i_sp_end_sub			(i_sp_end_sub			),	//v1.1

		.i_calc_start_fa05		(i_calc_start_fa05),		//v1.1
		.i_calc_start_fa06		(i_calc_start_fa06),		//v1.1
//		.i_calc_start_fa07		(i_calc_start_fa07),		//v1.1

		.i_join_end_fa05		(i_join_end_fa05),			//v1.1
		.i_join_end_fa06		(i_join_end_fa06),			//v1.1
		.i_join_end_fa07		(i_join_end_fa05),			//v1.1
		.o_frame_time			( w_frame_time         ),	// 現在のフレーム数（信号処理部への出力）
		.o_calc_start			( w_calc_start         ),	// 演算処理開始パルス（信号処理部への開始通知）
		.o_sp_end				( o_sp_end             ),	// 信号処理完了パルス
		.o_pad_size				( w_pad_size           ),	// パディング付与量制御
		.o_end_ins				( w_end_ins            ),	// エンドコード付与制御
		.o_frame_offset0		( o_frame_offset0      ),	// 信号処理IF部へのi_frame_offset0値出力
		.o_param_start			( w_param_start        ),	// 音速・位置ベクトル転送開始指示
		.o_r_state_fa04			( o_r_state_fa04	   ),	//v1.1
		.o_calc_cnt_fa04		( o_calc_cnt_fa04	),	//v1.1
//		.o_param_end			( o_param_end_fa04		),	//v1.1
//		.o_join_end_p			(o_join_end_p			),
		.o_fa_en				( o_fa_en				)	//v1.1
	);

	// 整相処理0側TOPモジュール
	xa_bf_top_00 #(											//v1.1
		.P_sample_num			( P_sample_num         ),	// サンプル数
		.P_stave_num			( P_stave_num          ),	// ステーブ数
		.P_stv_add_num			( P_stv_add_num        ),	// ステーブ加算時の加算対象ステーブ数
		.P_beam_start_num		( P_beam_start_num0    ),	// スタートbeam idx
		.P_beam_num				( P_beam_num0          ),	// 演算1回毎の演算ビーム数
		.P_odata_num			( P_odata_num0         ),	// 演算1回毎の演算結果データ総数
		.P_sp_adr_offset		( P_sp_adr_offset      ),	// 諸元算出データのアドレスオフセット値
		.P_se_adr_offset		( P_se_adr_offset      ),	// 受波器位置データのアドレスオフセット値
		.P_se_data_size			( P_se_data_size       ),	// 受波器位置データのリードデータ数
		.P_fs					( P_fs                 ),	// サンプリング周波数
		.P_ts					( P_ts                 ),	// サンプリング周期
		.P_fs_del_smpl			( P_fs_del_smpl        ),	// フィルター選択インデックス用係数
		.P_offst_dly_fil		( P_offst_dly_fil      ),	// 詳細遅延フィルタ−オフセット値
		.P_offst_dly_smpl		( P_offst_dly_smpl     ),	// 遅延バッファーオフセット値
		.P_buff_size			( P_buff_size          ),	// 遅延バッファーサイズ
		.P_buff_unit			( P_buff_unit          ),	// P_buff_size/P_sample_num
		.P_pcnt_snd_spd			( P_pcnt_snd_spd       ),	// 音速の処理パラメーター格納位置
		.P_pcnt_beam_phi0		( P_pcnt_beam_phi0     ),	// ふ仰角値1の処理パラメーター格納位置
		.P_pcnt_beam_phi1		( P_pcnt_beam_phi1     ),	// ふ仰角値2の処理パラメーター格納位置
		.P_pcnt_beam_phi2		( P_pcnt_beam_phi2     ),	// ふ仰角値3の処理パラメーター格納位置
		.P_pcnt_beam_phi3		( P_pcnt_beam_phi3     ),	// ふ仰角値4の処理パラメーター格納位置
		.P_pcnt_beam_phi4		( P_pcnt_beam_phi4     ),	// ふ仰角値5の処理パラメーター格納位置
		.P_pcnt_beam_phi5		( P_pcnt_beam_phi5     ),	// ふ仰角値6の処理パラメーター格納位置
		.P_pcnt_beam_phi6		( P_pcnt_beam_phi6     ),	// ふ仰角値7の処理パラメーター格納位置
		.P_pcnt_beam_phi7		( P_pcnt_beam_phi7     ),	// ふ仰角値8の処理パラメーター格納位置
		.P_beam_phi_cnt			( P_beam_phi_cnt0      ),	// ふ仰角値カウントアップのビーム数
		.P_beam_phi_max			( P_beam_phi_max0      ),	// ふ仰角値カウントアップの最大値
		.P_beam_period			( P_beam_period        )	// 1beamあたりのサンプル数
		)
	xa_bf_top_inst0 (
		.i_arst					( i_arst               ),	// 非同期リセット
		.i_clk156m				( i_clk156m            ),	// クロック
		.i_frame_time			( w_frame_time         ),	// 現在のフレーム数
		.i_calc_start			( w_calc_start         ),	// 演算1回毎の信号処理開始パルス
		.i_param_start			( w_param_start        ),	// 音速・位置ベクトル転送開始指示
		.i_param_valid			( i_param_valid        ),	// 処理パラメーターvalid
		.i_param_cnt			( i_param_cnt          ),	// 処理パラメーターアドレス
		.i_param_data			( i_param_data         ),	// 処理パラメーターvalid
		.i_iram0_rd_data		( i_iram0a_rd_data     ),	// 入力RAM0 リードデータ
		.i_iram0_rd_valid		( i_iram0a_rd_valid    ),	// 入力RAM0 リードデータvalid
		.i_iram1_rd_data		( i_iram1a_rd_data     ),	// 入力RAM1 リードデータ
		.i_iram1_rd_valid		( i_iram1a_rd_valid    ),	// 入力RAM1 リードデータvalid
		.i_snd_pos_sel			( P_system             ),	// 音速・位置ベクトル切替指示
		.o_param_end			( w_param_end          ),	// 音速・位置ベクトル転送完了通知
		.o_calc_end				( /* open */           ),	// 演算1回毎の信号処理完了通知
		.o_bm_data				( o_orama_wr_data      ),	// 演算結果データ
		.o_bm_data_valid		( o_orama_wr_valid     ),	// 演算結果データvalid
		.o_iram0_rd_addr		( o_iram0a_rd_addr     ),	// 入力RAM0 リードアドレス
		.o_iram0_rd_en			( o_iram0a_rd_en       ),	// 入力RAM0 リードenable
		.o_iram1_rd_addr		( o_iram1a_rd_addr     ),	// 入力RAM1 リードアドレス
		.o_iram1_rd_en			( o_iram1a_rd_en       )	// 入力RAM1 リードenable
	);

	// 整相処理1側TOPモジュール
	xa_bf_top_00 #(											//v1.1
		.P_sample_num			( P_sample_num         ),	// サンプル数
		.P_stave_num			( P_stave_num          ),	// ステーブ数
		.P_stv_add_num			( P_stv_add_num        ),	// ステーブ加算時の加算対象ステーブ数
		.P_beam_start_num		( P_beam_start_num1    ),	// スタートbeam idx
		.P_beam_num				( P_beam_num1          ),	// 演算1回毎の演算ビーム数
		.P_odata_num			( P_odata_num1         ),	// 演算1回毎の演算結果データ総数
		.P_sp_adr_offset		( P_sp_adr_offset      ),	// 諸元算出データのアドレスオフセット値
		.P_se_adr_offset		( P_se_adr_offset      ),	// 受波器位置データのアドレスオフセット値
		.P_se_data_size			( P_se_data_size       ),	// 受波器位置データのリードデータ数
		.P_fs					( P_fs                 ),	// サンプリング周波数
		.P_ts					( P_ts                 ),	// サンプリング周期
		.P_fs_del_smpl			( P_fs_del_smpl        ),	// フィルター選択インデックス用係数
		.P_offst_dly_fil		( P_offst_dly_fil      ),	// 詳細遅延フィルタ−オフセット値
		.P_offst_dly_smpl		( P_offst_dly_smpl     ),	// 遅延バッファーオフセット値
		.P_buff_size			( P_buff_size          ),	// 遅延バッファーサイズ
		.P_buff_unit			( P_buff_unit          ),	// P_buff_size/P_sample_num
		.P_pcnt_snd_spd			( P_pcnt_snd_spd       ),	// 音速の処理パラメーター格納位置
		.P_pcnt_beam_phi0		( P_pcnt_beam_phi0     ),	// ふ仰角値1の処理パラメーター格納位置
		.P_pcnt_beam_phi1		( P_pcnt_beam_phi1     ),	// ふ仰角値2の処理パラメーター格納位置
		.P_pcnt_beam_phi2		( P_pcnt_beam_phi2     ),	// ふ仰角値3の処理パラメーター格納位置
		.P_pcnt_beam_phi3		( P_pcnt_beam_phi3     ),	// ふ仰角値4の処理パラメーター格納位置
		.P_pcnt_beam_phi4		( P_pcnt_beam_phi4     ),	// ふ仰角値5の処理パラメーター格納位置
		.P_pcnt_beam_phi5		( P_pcnt_beam_phi5     ),	// ふ仰角値6の処理パラメーター格納位置
		.P_pcnt_beam_phi6		( P_pcnt_beam_phi6     ),	// ふ仰角値7の処理パラメーター格納位置
		.P_pcnt_beam_phi7		( P_pcnt_beam_phi7     ),	// ふ仰角値8の処理パラメーター格納位置
		.P_beam_phi_cnt			( P_beam_phi_cnt1      ),	// ふ仰角値カウントアップのビーム数
		.P_beam_phi_max			( P_beam_phi_max1      ),	// ふ仰角値カウントアップの最大値
		.P_beam_period			( P_beam_period        )	// 1beamあたりのサンプル数
		)
	xa_bf_top_inst1 (
		.i_arst					( i_arst               ),	// 非同期リセット
		.i_clk156m				( i_clk156m            ),	// クロック
		.i_frame_time			( w_frame_time         ),	// 現在のフレーム数
		.i_calc_start			( w_calc_start         ),	// 演算1回毎の信号処理開始パルス
		.i_param_start			( w_param_start        ),	// 音速・位置ベクトル転送開始指示
		.i_param_valid			( i_param_valid        ),	// 処理パラメーターvalid
		.i_param_cnt			( i_param_cnt          ),	// 処理パラメーターアドレス
		.i_param_data			( i_param_data         ),	// 処理パラメーターvalid
		.i_iram0_rd_data		( i_iram0b_rd_data     ),	// 入力RAM0 リードデータ
		.i_iram0_rd_valid		( i_iram0b_rd_valid    ),	// 入力RAM0 リードデータvalid
		.i_iram1_rd_data		( i_iram1b_rd_data     ),	// 入力RAM1 リードデータ
		.i_iram1_rd_valid		( i_iram1b_rd_valid    ),	// 入力RAM1 リードデータvalid
		.i_snd_pos_sel			( P_system             ),	// 音速・位置ベクトル切替指示
		.o_param_end			( /* open */           ),	// 音速・位置ベクトル転送完了通知
		.o_calc_end				( w_calc_end           ),	// 演算1回毎の信号処理完了通知
		.o_bm_data				( w_oramb_wr_data      ),	// 演算結果データ
		.o_bm_data_valid		( w_oramb_wr_valid     ),	// 演算結果データvalid
		.o_iram0_rd_addr		( o_iram0b_rd_addr     ),	// 入力RAM0 リードアドレス
		.o_iram0_rd_en			( o_iram0b_rd_en       ),	// 入力RAM0 リードenable
		.o_iram1_rd_addr		( o_iram1b_rd_addr     ),	// 入力RAM1 リードアドレス
		.o_iram1_rd_en			( o_iram1b_rd_en       )	// 入力RAM1 リードenable
	);

	// パディング＋エンドコード付与モジュール
	xa_pad_join		xa_pad_join_inst (
		.i_arst					( i_arst               ),	// 非同期リセット
		.i_clk156m				( i_clk156m            ),	// クロック
		.i_clr					( i_sp_start           ),	// クリア
		.i_join_start			( w_calc_end           ),	// 信号処理開始パルス
		.i_dat					( w_oramb_wr_data      ),	// 入力データ
		.i_val					( w_oramb_wr_valid     ),	// 入力データvalid
		.i_pad_type				( 2'b00                ),	// パディングデータ種別
		.i_pad_size				( w_pad_size           ),	// パディングデータ付与サイズ（word数）
		.i_end_ins				( w_end_ins            ),	// エンドコード付与有無（0:無, 1:有）
		.o_join_end				( w_sp_end             ),	// 信号処理完了パルス
		.o_dat					( o_oramb_wr_data      ),	// 出力データ
		.o_val					( o_oramb_wr_valid     )	// 出力データvalid
	);

endmodule
