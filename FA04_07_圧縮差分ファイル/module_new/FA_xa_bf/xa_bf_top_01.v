//--------------------------------------------------------------------------------------------------
// Company           : Oki Electric Industry Co., Ltd.
// Project Name      : FPGA development for sonar (29SS)
// Module Name       : xa_bf_top
// Function          : Beam Forming Top Module
// Create Date       : 2019.06.12
// Original Designer : Kenjiro Yakuwa
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// History:
//--------------------------------------------------------------------------------------------------
// Ver   | Date         | Designer          | Comment
//--------------------------------------------------------------------------------------------------
// 1.0   | 2019.06.12   | Kenjiro Yakuwa    | 新規作成
// 1.1   | 2022.09.15   | Masayuki Kato     | 変更
//
// Copyright 2019 Oki Electric Industry Co., Ltd.
//
//--------------------------------------------------------------------------------------------------
// Module & Port
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
module xa_bf_top_01 #(														// v1.2
    parameter      [11:0]    P_sample_num        = 12'd128           ,    // サンプル数パラメータ
    parameter      [10:0]    P_stave_num         = 11'd250           ,    // ステーブ数パラメータ
    parameter      [10:0]    P_stv_add_num       = 11'd250           ,    // ステーブ加算時の加算対象ステーブ数
    parameter      [9:0]     P_beam_start_num    = 10'd0             ,    // スタートbeam idx
    parameter      [9:0]     P_beam_num          = 10'd66            ,    // 演算1回毎の演算ビーム数
    parameter      [19:0]    P_odata_num         = 20'd8448          ,    // 演算1回毎の演算結果データ総数
    parameter      [31:0]    P_sp_adr_offset     = 32'h0003E806      ,    // 諸元算出データのアドレスオフセット値
    parameter      [31:0]    P_se_adr_offset     = 32'h0003E818      ,    // 受波器位置データのアドレスオフセット値
    parameter      [11:0]    P_se_data_size      = 12'd750           ,    // 受波器位置データのリードデータ数
    parameter      [31:0]    P_fs                = 32'h454CCCCC      ,    // サンプリング周波数
    parameter      [31:0]    P_ts                = 32'h39A00000      ,    // サンプリング周期
    parameter      [31:0]    P_fs_del_smpl       = 32'h48200000      ,    // フィルター選択インデックス用係数
    parameter      [5:0]     P_offst_dly_fil     = 6'd25             ,    // 詳細遅延フィルタ－オフセット値
    parameter      [11:0]    P_offst_dly_smpl    = 12'd1024          ,    // 遅延バッファーオフセット値
    parameter      [12:0]    P_buff_size         = 13'd2048          ,    // 遅延バッファーサイズ
    parameter      [5:0]     P_buff_unit         = 6'd16             ,    // P_buff_size/P_sample_num
    parameter      [8:0]     P_pcnt_snd_spd      = 9'd0              ,    // 音速の処理パラメーター格納位置
    parameter      [8:0]     P_pcnt_beam_phi0    = 9'd0              ,    // ふ仰角値1の処理パラメーター格納位置
    parameter      [8:0]     P_pcnt_beam_phi1    = 9'd0              ,    // ふ仰角値2の処理パラメーター格納位置
    parameter      [8:0]     P_pcnt_beam_phi2    = 9'd0              ,    // ふ仰角値3の処理パラメーター格納位置
    parameter      [8:0]     P_pcnt_beam_phi3    = 9'd0              ,    // ふ仰角値4の処理パラメーター格納位置
    parameter      [8:0]     P_pcnt_beam_phi4    = 9'd0              ,    // ふ仰角値5の処理パラメーター格納位置
    parameter      [8:0]     P_pcnt_beam_phi5    = 9'd0              ,    // ふ仰角値6の処理パラメーター格納位置
    parameter      [8:0]     P_pcnt_beam_phi6    = 9'd0              ,    // ふ仰角値7の処理パラメーター格納位置
    parameter      [8:0]     P_pcnt_beam_phi7    = 9'd0              ,    // ふ仰角値8の処理パラメーター格納位置
    parameter      [9:0]     P_beam_phi_cnt      = 10'd1             ,    // ふ仰角値カウントアップのビーム数
    parameter      [3:0]     P_beam_phi_max      = 4'd1              ,    // ふ仰角値カウントアップの最大値
    parameter      [17:0]    P_beam_period       = 18'd32000              // 1beamあたりのサンプル数
)
(
// input
    input  wire              i_arst                                  ,    // 非同期リセット
    input  wire              i_clk156m                               ,    // クロック
    input  wire    [4:0]     i_frame_time                            ,    // フレーム番号
    input  wire              i_calc_start                            ,    // 演算1回毎の信号処理開始パルス
    input  wire              i_param_start                           ,    // 音速・位置ベクトル転送開始指示
    input  wire              i_param_valid                           ,    // 処理パラメータvalid
    input  wire    [8:0]     i_param_cnt                             ,    // 処理パラメータアドレス
    input  wire    [31:0]    i_param_data                            ,    // 処理パラメータデータ
    input  wire    [31:0]    i_iram0_rd_data                         ,    // 入力RAM0リードデータ
    input  wire              i_iram0_rd_valid                        ,    // 入力RAM0リードデータvalid
    input  wire    [31:0]    i_iram1_rd_data                         ,    // 入力RAM1リードデータ
    input  wire              i_iram1_rd_valid                        ,    // 入力RAM1リードデータvalid
    input  wire              i_snd_pos_sel                           ,    // 音速・位置ベクトル切替指示
// output
    output wire              o_param_end                             ,    // 音速・位置ベクトル転送完了通知
    output wire              o_calc_end                              ,    // 演算処理完了パルス
    output wire    [31:0]    o_bm_data                               ,    // 演算結果データ
    output wire              o_bm_data_valid                         ,    // 演算結果データvalid
    output wire    [31:0]    o_iram0_rd_addr                         ,    // 入力RAM0 リードアドレス
    output wire              o_iram0_rd_en                           ,    // 入力RAM0 リードenable
    output wire    [31:0]    o_iram1_rd_addr                         ,    // 入力RAM1 リードアドレス
    output wire              o_iram1_rd_en                                // 入力RAM1 リードenable
);

//--------------------------------------------------------------------------------------------------
// Parameter
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
//--------------------------------------------------------------------------------------------------
// Reg & Wire
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
    wire           w_param_end;
    wire [31:0]    w_pos_wr_data;
    wire           w_pos_wr_en;
    wire [31:0]    w_iram_rd_addr_ps;
    wire           w_iram_rd_en_ps;
    wire           w_iram0_sel;
    wire [31:0]    w_snd_spd;
    wire [31:0]    w_beam_phi;
    wire [9:0]     w_beam_idx;
    wire           w_bm_start_ps;
    wire [31:0]    w_bf_dir_vector_ss_x;
    wire [31:0]    w_bf_dir_vector_ss_y;
    wire [31:0]    w_bf_dir_vector_ss_z;
    wire           w_bm_start_dc;
    wire [31:0]    w_tau_precise0;
    wire [31:0]    w_tau_precise1;
    wire [31:0]    w_tau_sample0;
    wire [31:0]    w_tau_sample1;
    wire [9:0]     w_ch_idx0;
    wire [9:0]     w_ch_idx1;
    wire           w_ch_start0;
    wire           w_ch_start1;
    wire [31:0]    w_ch_filter0;
    wire [31:0]    w_ch_filter1;
    wire           w_ch_filter0_valid;
    wire           w_ch_filter1_valid;
    wire [31:0]    w_iram_rd_addr_ds;
    wire           w_iram_rd_en_ds;
    wire [31:0]    w_ch_data0;
    wire           w_ch_data0_valid;
    wire [31:0]    w_iram_rd_addr1;
    wire           w_iram_rd_en1;
    wire [31:0]    w_ch_data1;
    wire           w_ch_data1_valid;
    wire [31:0]    w_conv_rslt;
    wire           w_conv_rslt_valid;
    wire [31:0]    w_bm_data;
    wire           w_bm_data_valid;
    wire           w_calc_end;

    reg  [31:0]    r_iram0_rd_data;
    reg            r_iram0_rd_valid;
    reg  [31:0]    r_iram1_rd_data;
    reg            r_iram1_rd_valid;
    wire [31:0]    s_iram0_rd_data_sel0;
    wire [31:0]    s_iram0_rd_data_sel1;
    wire           s_iram0_rd_valid_sel0;
    wire           s_iram0_rd_valid_sel1;
    reg  [31:0]    r_iram0_rd_addr;
    reg            r_iram0_rd_en;
    reg  [31:0]    r_iram1_rd_addr;
    reg            r_iram1_rd_en;

//--------------------------------------------------------------------------------------------------
// Sub Module
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
//  音声・位置ベクトル選択モジュール
    xa_bf_param_sel #(
        .P_sp_adr_offset          (P_sp_adr_offset      ),      // 諸元算出データのアドレスオフセット値
        .P_se_adr_offset          (P_se_adr_offset      ),      // 受波器位置データのアドレスオフセット値
        .P_se_data_size           (P_se_data_size       ),      // 受波器位置データのリードデータ数
        .P_pcnt_snd_spd           (P_pcnt_snd_spd       )       // 音速の処理パラメーター格納位置
        )
    xa_bf_param_sel_inst (
        .i_arst                   (i_arst               ),      // 非同期リセット
        .i_clk156m                (i_clk156m            ),      // クロック
        .i_param_start            (i_param_start        ),      // 音速・位置ベクトル転送開始指示
        .i_param_data             (i_param_data         ),      // 処理パラメータデータ
        .i_param_valid            (i_param_valid        ),      // 処理パラメータvalid
        .i_param_cnt              (i_param_cnt          ),      // 処理パラメータアドレス
        .i_snd_pos_sel            (i_snd_pos_sel        ),      // 音速・位置ベクトル切替指示
        .i_iram0_rd_data          (s_iram0_rd_data_sel0 ),      // 入力RAM0リードデータ
        .i_iram0_rd_valid         (s_iram0_rd_valid_sel0),      // 入力RAM0リードデータvalid
        .o_param_end              (w_param_end          ),      // 音速・位置ベクトル転送完了通知
        .o_pos_wr_data            (w_pos_wr_data        ),      // 受波器位置テーブル格納RAM ライトデータ
        .o_pos_wr_en              (w_pos_wr_en          ),      // 受波器位置テーブル格納RAM ライトenable
        .o_iram_rd_addr           (w_iram_rd_addr_ps    ),      // 入力RAM0 Aﾎﾟｰﾄﾘｰﾄﾞｱﾄﾞﾚｽ
        .o_iram_rd_en             (w_iram_rd_en_ps      ),      // 入力RAM0 Aﾎﾟｰﾄﾘｰﾄﾞen
        .o_iram0_sel              (w_iram0_sel          ),      // 入力RAM0 Aﾎﾟｰﾄ選択信号
        .o_snd_spd                (w_snd_spd            )       // 音速パラメーター出力
    );

//  ふ仰角値選択モジュール
    xa_bf_phi_sel #(
        .P_beam_start_num         ( P_beam_start_num    ),      // スタートbeam idx
        .P_beam_num               ( P_beam_num          ),      // 演算1回毎の演算ビーム数
        .P_pcnt_beam_phi0         ( P_pcnt_beam_phi0    ),      // ふ仰角値1の処理パラメーター格納位置
        .P_pcnt_beam_phi1         ( P_pcnt_beam_phi1    ),      // ふ仰角値2の処理パラメーター格納位置
        .P_pcnt_beam_phi2         ( P_pcnt_beam_phi2    ),      // ふ仰角値3の処理パラメーター格納位置
        .P_pcnt_beam_phi3         ( P_pcnt_beam_phi3    ),      // ふ仰角値4の処理パラメーター格納位置
        .P_pcnt_beam_phi4         ( P_pcnt_beam_phi4    ),      // ふ仰角値5の処理パラメーター格納位置
        .P_pcnt_beam_phi5         ( P_pcnt_beam_phi5    ),      // ふ仰角値6の処理パラメーター格納位置
        .P_pcnt_beam_phi6         ( P_pcnt_beam_phi6    ),      // ふ仰角値7の処理パラメーター格納位置
        .P_pcnt_beam_phi7         ( P_pcnt_beam_phi7    ),      // ふ仰角値8の処理パラメーター格納位置
        .P_beam_phi_cnt           ( P_beam_phi_cnt      ),      // ふ仰角値カウントアップのビーム数
        .P_beam_phi_max           ( P_beam_phi_max      ),      // ふ仰角値カウントアップの最大値
        .P_beam_period            ( P_beam_period       )       // 1beamあたりのサンプル数
        )
    xa_bf_phi_sel_inst (
        .i_arst                   (i_arst               ),       // 非同期リセット
        .i_clk156m                (i_clk156m            ),       // クロック
        .i_calc_start             (i_calc_start         ),       // 演算1回毎の信号処理開始パルス
        .i_param_data             (i_param_data         ),       // 処理パラメータデータ
        .i_param_valid            (i_param_valid        ),       // 処理パラメータvalid
        .i_param_cnt              (i_param_cnt          ),       // 処理パラメータアドレス
        .o_beam_phi               (w_beam_phi           ),       // ふ仰角値パラメータ－出力
        .o_beam_idx               (w_beam_idx           ),       // 処理対象ビーム番号
        .o_bm_start               (w_bm_start_ps        )        // 演算開始指示(beam周期)
    );

// 整相方位計算モジュール
    xa_bf_dir_calc_01 xa_bf_dir_calc_inst(							// v1.2
        .i_arst                   (i_arst               ),       // 非同期リセット
        .i_clk156m                (i_clk156m            ),       // クロック
        .i_bm_start               (w_bm_start_ps        ),       // 演算処理開始パルス(beam周期)
        .i_beam_phi               (w_beam_phi           ),       // ふ仰角パラメータ
        .i_beam_idx               (w_beam_idx           ),       // 演算対象ビーム番号
        .i_snd_spd                (w_snd_spd            ),       // 音速パラメータ
        .o_bf_dir_vector_ss_x     (w_bf_dir_vector_ss_x ),       // 出力データ（X座標)
        .o_bf_dir_vector_ss_y     (w_bf_dir_vector_ss_y ),       // 出力データ（Y座標)
        .o_bf_dir_vector_ss_z     (w_bf_dir_vector_ss_z ),       // 出力データ（Z座標)
        .o_bm_start               (w_bm_start_dc        )        // 演算処理開始指示出力(beam周期)
    );

// 遅延時間計算＆分解モジュール
     xa_bf_dly_calc_01 #(											// v1.2
        .P_stave_num              (P_stave_num          ),        // ステーブ数パラメータ
        .P_fs                     (P_fs                 ),        // サンプリング周波数パラメータ(3276.8Hz)
        .P_ts                     (P_ts                 )         // サンプリング周期数パラメータ
        )                                                  
     xa_bf_dly_calc_inst                                   
     (                                                     
        .i_arst                   (i_arst               ),        // 非同期リセット
        .i_clk156m                (i_clk156m            ),        // クロック
        .i_bm_start               (w_bm_start_dc        ),        // 演算処理開始パルス(beam周期)
        .i_bf_dir_vector_ss_x     (w_bf_dir_vector_ss_x ),        // 整相方位計算結果(X座標)
        .i_bf_dir_vector_ss_y     (w_bf_dir_vector_ss_y ),        // 整相方位計算結果(Y座標)
        .i_bf_dir_vector_ss_z     (w_bf_dir_vector_ss_z ),        // 整相方位計算結果(Z座標)
        .i_pos_wr_data            (w_pos_wr_data        ),        // TA用位置ベクトルデータ
        .i_pos_wr_en              (w_pos_wr_en          ),        // TA用受波器位置ベクトル格納RAMライトイネーブル
        .o_tau_precise0           (w_tau_precise0       ),        // 遅延時間出力(小数部)
        .o_tau_precise1           (w_tau_precise1       ),        // 遅延時間出力(小数部)
        .o_tau_sample0            (w_tau_sample0        ),        // 遅延時間出力(整数部)
        .o_tau_sample1            (w_tau_sample1        ),        // 遅延時間出力(整数部)
        .o_ch_idx0                (w_ch_idx0            ),        // chIdx(センサーインデックス)
        .o_ch_idx1                (w_ch_idx1            ),        // chIdx(センサーインデックス)
        .o_ch_start0              (w_ch_start0          ),        // ch(センサー)周期スタートパルス
        .o_ch_start1              (w_ch_start1          )         // ch(センサー)周期スタートパルス
    );

// 詳細遅延フィルタ選択モジュール
    xa_bf_fil_sel #(
        .P_fs_del_smpl            (P_fs_del_smpl        ),        // フィルター選択インデックス用係数
        .P_offst_dly_fil          (P_offst_dly_fil      )         // 詳細遅延フィルタ－オフセット値
    )                                                       
    xa_bf_fil_sel_inst (                                    
        .i_arst                   (i_arst               ),        // 非同期リセット
        .i_clk156m                (i_clk156m            ),        // クロック
        .i_tau_precise0           (w_tau_precise0       ),        // 遅延時間入力(小数部)
        .i_tau_precise1           (w_tau_precise1       ),        // 遅延時間入力(小数部)
        .i_ch_start0              (w_ch_start0          ),        // ch(センサー)周期スタートパルス
        .i_ch_start1              (w_ch_start1          ),        // ch(センサー)周期スタートパルス
        .o_ch_filter0             (w_ch_filter0         ),        // フィルター係数出力0
        .o_ch_filter1             (w_ch_filter1         ),        // フィルター係数出力1
        .o_ch_filter_valid0       (w_ch_filter0_valid   ),        // フィルター係数出力0 valid
        .o_ch_filter_valid1       (w_ch_filter1_valid   )         // フィルター係数出力1 valid
    );

// サンプル遅延補正モジュール0
    xa_bf_dly_smpl #(
        .P_offst_dly_smpl         (P_offst_dly_smpl     ),        // 遅延バッファオフセット値パラメータ
        .P_sample_num             (P_sample_num         ),        // サンプル数パラメータ
        .P_stave_num              (P_stave_num          ),        // ステーブ数パラメータ
        .P_buff_unit              (P_buff_unit          ),        // P_buff_size/P_sample_num
        .P_buff_size              (P_buff_size          )         // 遅延バッファサイズパラメータ
        )                                                   
    xa_bf_dly_smpl_inst0 (                                  
        .i_arst                   (i_arst               ),        // 非同期リセット
        .i_clk156m                (i_clk156m            ),        // クロック
        .i_tau_sample             (w_tau_sample0        ),        // 遅延時間入力（整数部）
        .i_ch_start               (w_ch_start0          ),        // ch(センサー)周期スタートパルス
        .i_ch_idx                 (w_ch_idx0            ),        // chIdx(センサーインデックス)
        .i_frame_time             (i_frame_time         ),        // フレーム番号
        .i_iram_rd_data           (s_iram0_rd_data_sel1 ),        // 入力データ格納RAMリードデータ
        .i_iram_rd_valid          (s_iram0_rd_valid_sel1),        // 入力データ格納RAMリードデータvalid
        .o_iram_rd_addr           (w_iram_rd_addr_ds    ),        // 入力データ格納RAMリードアドレス出力
        .o_iram_rd_en             (w_iram_rd_en_ds      ),        // 入力データ格納RAMリードイネーブル
        .o_ch_data                (w_ch_data0           ),        // 出力データ
        .o_ch_data_valid          (w_ch_data0_valid     )         // 出力データvalid
    );

// サンプル遅延補正モジュール1
    xa_bf_dly_smpl #(
        .P_offst_dly_smpl         (P_offst_dly_smpl     ),        // 遅延バッファオフセット値パラメータ
        .P_sample_num             (P_sample_num         ),        // サンプル数パラメータ
        .P_stave_num              (P_stave_num          ),        // ステーブ数パラメータ
        .P_buff_unit              (P_buff_unit          ),        // P_buff_size/P_sample_num
        .P_buff_size              (P_buff_size          )         // 遅延バッファサイズパラメータ
        )                                                   
    xa_bf_dly_smpl_inst1 (                                  
        .i_arst                   (i_arst               ),        // 非同期リセット
        .i_clk156m                (i_clk156m            ),        // クロック
        .i_tau_sample             (w_tau_sample1        ),        // 遅延時間入力（整数部）
        .i_ch_start               (w_ch_start1          ),        // ch(センサー)周期スタートパルス
        .i_ch_idx                 (w_ch_idx1            ),        // chIdx(センサーインデックス)
        .i_frame_time             (i_frame_time         ),        // フレーム番号
        .i_iram_rd_data           (r_iram1_rd_data      ),        // 入力データ格納RAMリードデータ
        .i_iram_rd_valid          (r_iram1_rd_valid     ),        // 入力データ格納RAMリードデータvalid
        .o_iram_rd_addr           (w_iram_rd_addr1      ),        // 入力データ格納RAMリードアドレス出力
        .o_iram_rd_en             (w_iram_rd_en1        ),        // 入力データ格納RAMリードイネーブル
        .o_ch_data                (w_ch_data1           ),        // 出力データ
        .o_ch_data_valid          (w_ch_data1_valid     )         // 出力データvalid
    );

// 畳み込み演算モジュール
    xa_cm_conv #(
        .P_sample_num             (P_sample_num         ),        // サンプル数パラメータ
        .P_stave_num              (P_stave_num          ),        // ステーブ数パラメータ
        .P_beam_num               (P_beam_num           )         // 演算1回毎の演算ビーム数
        )                                                   
    xa_cm_conv_inst (                                       
        .i_arst                   (i_arst               ),        // 非同期リセット
        .i_clk156m                (i_clk156m            ),        // クロック
        .i_calc_start             (i_calc_start         ),        // 演算1回毎の信号処理開始パルス
        .i_ch_data0               (w_ch_data0           ),        // 入力データ0
        .i_ch_data0_valid         (w_ch_data0_valid     ),        // 入力データvalid0
        .i_ch_data1               (w_ch_data1           ),        // 入力データ0
        .i_ch_data1_valid         (w_ch_data1_valid     ),        // 入力データvalid0
        .i_ch_filter0             (w_ch_filter0         ),        // 係数データ0
        .i_ch_filter0_valid       (w_ch_filter0_valid   ),        // 係数データ0 valid
        .i_ch_filter1             (w_ch_filter1         ),        // 係数データ1
        .i_ch_filter1_valid       (w_ch_filter1_valid   ),        // 係数データ1 valid
        .o_conv_rslt              (w_conv_rslt          ),        // 出力データ
        .o_conv_rslt_valid        (w_conv_rslt_valid    ),        // 出力データvalid
        .o_conv_rslt_asel         (/* open */           ),        // 出力データ選択A
        .o_conv_rslt_bsel         (/* open */           ),        // 出力データ選択B
        .o_calc_end               (/* open */           )         // 演算処理完了パルス
    );                            
                                  
// ステーブ加算モジュール         
    xa_bf_stv_add #(              
        .P_sample_num             (P_sample_num         ),        // サンプル数パラメータ
        .P_stv_add_num            (P_stv_add_num        ),        // ステーブ加算時の加算対象ステーブ数パラメータ
        .P_odata_num              (P_odata_num          )         // 出力データ総数パラメータ
        )                                                   
    xa_bf_stv_add_inst (                                    
        .i_arst                   (i_arst               ),        // 非同期リセット
        .i_clk156m                (i_clk156m            ),        // クロック
        .i_calc_start             (i_calc_start         ),        // 演算1回毎の信号処理開始パルス
        .i_conv_rslt              (w_conv_rslt          ),        // 入力データ
        .i_conv_rslt_valid        (w_conv_rslt_valid    ),        // 入力データvalid
        .o_bm_data                (w_bm_data            ),        // 出力データ
        .o_bm_data_valid          (w_bm_data_valid      ),        // 出力データvalid
        .o_calc_end               (w_calc_end           )         // 演算処理完了パルス
    );

//--------------------------------------------------------------------------------------------------
// Main
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// Input FF
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_iram0_rd_data  <= 32'd0;
            r_iram0_rd_valid <= 1'b0;
            r_iram1_rd_data  <= 32'd0;
            r_iram1_rd_valid <= 1'b0;
        end
        else begin
            r_iram0_rd_data  <= i_iram0_rd_data;
            r_iram0_rd_valid <= i_iram0_rd_valid;
            r_iram1_rd_data  <= i_iram1_rd_data;
            r_iram1_rd_valid <= i_iram1_rd_valid;
        end
    end

// 音速・位置ベクトル選択モジュールへの入力RAM0リードデータ
    assign s_iram0_rd_data_sel0  = (w_iram0_sel == 1'b0) ? r_iram0_rd_data  : 32'd0;
    assign s_iram0_rd_valid_sel0 = (w_iram0_sel == 1'b0) ? r_iram0_rd_valid : 1'b0;
// サンプル遅延補正モジュールへの入力RAM0リードデータ
    assign s_iram0_rd_data_sel1  = (w_iram0_sel == 1'b1) ? r_iram0_rd_data  : 32'd0;
    assign s_iram0_rd_valid_sel1 = (w_iram0_sel == 1'b1) ? r_iram0_rd_valid : 1'b0;

// Output FF
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_iram0_rd_addr <= 32'd0;
            r_iram0_rd_en   <= 1'b0;
            r_iram1_rd_addr <= 32'd0;
            r_iram1_rd_en   <= 1'b0;
        end
        else begin
            if (w_iram0_sel == 1'b1) begin
                // xa_bf_dly_smpl_inst0側
                r_iram0_rd_addr <= w_iram_rd_addr_ds;
                r_iram0_rd_en   <= w_iram_rd_en_ds;
            end
            else begin
                r_iram0_rd_addr <= w_iram_rd_addr_ps;
                r_iram0_rd_en   <= w_iram_rd_en_ps;
            end
            r_iram1_rd_addr <= w_iram_rd_addr1;
            r_iram1_rd_en   <= w_iram_rd_en1;
        end
    end

// ------ //
// Output //
// ------ //
    assign o_param_end     = w_param_end;
    assign o_calc_end      = w_calc_end;
    assign o_bm_data       = w_bm_data;
    assign o_bm_data_valid = w_bm_data_valid;
    assign o_iram0_rd_addr = r_iram0_rd_addr;
    assign o_iram0_rd_en   = r_iram0_rd_en;
    assign o_iram1_rd_addr = r_iram1_rd_addr;
    assign o_iram1_rd_en   = r_iram1_rd_en;

endmodule
