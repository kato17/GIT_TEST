//--------------------------------------------------------------------------------------------------
// Company           : Oki Electric Industry Co., Ltd.
// Project Name      : FPGA development for sonar (29SS)
// Module Name       : xa_dly_calc
// Function          : Beam Forming Delay Calcuration Module
// Create Date       : 2019.06.07
// Original Designer : Kenjiro Yakuwa
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// History:
//--------------------------------------------------------------------------------------------------
// Ver   | Date         | Designer          | Comment
//--------------------------------------------------------------------------------------------------
// 1.0   | 2019.06.07   | Kenjiro Yakuwa    | 新規作成
//
// Copyright 2019 Oki Electric Industry Co., Ltd.
//
//--------------------------------------------------------------------------------------------------
// Module & Port
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
module xa_bf_dly_calc_00 #(
    parameter      [10:0]    P_stave_num    =   11'd250              ,    // ステーブ数パラメータ
    parameter      [31:0]    P_fs           =   32'h454CCCCC         ,    // サンプリング周波数パラメータ(3276.8Hz)
    parameter      [31:0]    P_ts           =   32'h39A00000              // サンプリング周期数パラメータ
    )
(
// input
    input  wire              i_arst                                  ,    // 非同期リセット
    input  wire              i_clk156m                               ,    // クロック
    input  wire              i_bm_start                              ,    // 演算処理開始パルス(beam周期)
    input  wire    [31:0]    i_bf_dir_vector_ss_x                    ,    // 整相方位計算結果(X座標)
    input  wire    [31:0]    i_bf_dir_vector_ss_y                    ,    // 整相方位計算結果(Y座標)
    input  wire    [31:0]    i_bf_dir_vector_ss_z                    ,    // 整相方位計算結果(Z座標)
    input  wire    [31:0]    i_pos_wr_data                           ,    // TA用位置ベクトルデータ
    input  wire              i_pos_wr_en                             ,    // TA用受波器位置ベクトル格納RAMライトイネーブル
// output
    output wire    [31:0]    o_tau_precise0                          ,    // 遅延時間出力(小数部)
    output wire    [31:0]    o_tau_precise1                          ,    // 遅延時間出力(小数部)
    output wire    [31:0]    o_tau_sample0                           ,    // 遅延時間出力(整数部)
    output wire    [31:0]    o_tau_sample1                           ,    // 遅延時間出力(整数部)
    output wire    [9:0]     o_ch_idx0                               ,    // chIdx(センサーインデックス)
    output wire    [9:0]     o_ch_idx1                               ,    // chIdx(センサーインデックス)
    output wire              o_ch_start0                             ,    // ch(センサー)周期スタートパルス
    output wire              o_ch_start1                                  // ch(センサー)周期スタートパルス
);

//--------------------------------------------------------------------------------------------------
// Parameter
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0

//--------------------------------------------------------------------------------------------------
// Reg & Wire
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
    reg  [10:0]    r_wr_addr;
    wire [10:0]    s_stave_max;
    wire [9:0]     s_stave_max0;
    wire [9:0]     s_stave_max1;
    reg  [7:0]     r_clk_cntr0;
    reg            r_clk_cntr_en0;
    reg  [7:0]     r_clk_cntr1;
    reg            r_clk_cntr_en1;
    reg  [9:0]     r_ch_idx0;
    reg  [9:0]     r_ch_idx1;
    reg            r_rd_en;
    wire [11:0]    s_ch_idx0_x3;
    wire [11:0]    s_ch_idx1_x3;
    reg  [10:0]    r_rd_addr;
    wire [31:0]    s_rd_data;
    reg  [31:0]    r_rd_data0;
    reg  [31:0]    r_rd_data1;
    reg  [31:0]    r_rd_data2;
    reg  [31:0]    r_rd_data_lt0;
    reg  [31:0]    r_rd_data_lt1;
    reg  [31:0]    r_rd_data_lt2;
    wire [31:0]    s_delay;
    wire [31:0]    s_delay_smpl;
    wire [31:0]    s_tau_sample;
    wire [31:0]    s_tau_sample_flt;
    wire [31:0]    s_delay_round;
    reg  [383:0]   r_delay_sft;
    wire [31:0]    s_tau_precise;
    reg  [31:0]    r_tau_precise0;
    reg  [31:0]    r_tau_precise1;
    reg  [31:0]    r_tau_sample0;
    reg  [31:0]    r_tau_sample1;
    reg  [9:0]     r_ch_idx0_out;
    reg  [9:0]     r_ch_idx1_out;
    reg            r_ch_start0;
    reg            r_ch_start1;

//--------------------------------------------------------------------------------------------------
// Main
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// 位置ベクトルテーブルRAMライトアドレス
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_wr_addr <= 11'd0;
        end
        else if (i_pos_wr_en) begin
            r_wr_addr <= r_wr_addr + 1'b1;
        end
        else begin
            r_wr_addr <= 11'd0;
        end
    end

// 受波器位置テーブルRAM
    RAM_2PORT_XA_BF_POS_00 RAM_2PORT_XA_BF_POS_inst (
        .data      (i_pos_wr_data ),
        .wraddress (r_wr_addr     ),
        .rdaddress (r_rd_addr     ),
        .wren      (i_pos_wr_en   ),
        .clock     (i_clk156m     ),
        .rden      (r_rd_en       ),
        .enable    (1'b1          ),
        .aclr      (i_arst        ),
        .q         (s_rd_data     )
    );


// ステーブ数最大値
    assign s_stave_max  = P_stave_num - 1'b1;
    assign s_stave_max0 = s_stave_max[10:1];
    assign s_stave_max1 = s_stave_max[9:0];

// CLKカウンタイネーブル0
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_clk_cntr_en0 <= 1'b0;
        end
        else if (i_bm_start) begin
            r_clk_cntr_en0 <= 1'b1;
        end
        else if (r_clk_cntr0 == 8'd255 && r_ch_idx0 == s_stave_max0) begin
            r_clk_cntr_en0 <= 1'b0;
        end
    end

// CLKカウンタ0
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_clk_cntr0 <= 8'd0;
        end
        else if (r_clk_cntr_en0 == 1'b1) begin
            r_clk_cntr0 <= r_clk_cntr0 + 1'b1;
        end
        else begin
            r_clk_cntr0 <= 8'd0;
        end
    end

// CLKカウンタイネーブル1
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_clk_cntr_en1 <= 1'b0;
        end
        else if (r_clk_cntr0 == 8'd127) begin
            // clk_cntr0と128CLKの遅延差を持たせる
            r_clk_cntr_en1 <= 1'b1;
        end
        else if (r_clk_cntr1 == 8'd255 && r_ch_idx1 == s_stave_max1) begin
            r_clk_cntr_en1 <= 1'b0;
        end
    end

// CLKカウンタ1
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_clk_cntr1 <= 8'd0;
        end
        else if (r_clk_cntr_en1 == 1'b1) begin
            r_clk_cntr1 <= r_clk_cntr1 + 1'b1;
        end
        else begin
            r_clk_cntr1 <= 8'd0;
        end
    end

// ChIdx0
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_ch_idx0 <= 10'd0;
        end
        else if (i_bm_start) begin
            r_ch_idx0 <= 10'd0;
        end
        else if (r_clk_cntr_en0 == 1'b1 && r_clk_cntr0 == 8'd255)begin
            if (r_ch_idx0 >= s_stave_max0) begin
                r_ch_idx0 <= 10'd0;
            end
            else begin
                r_ch_idx0 <= r_ch_idx0 + 1'b1;
            end
        end
    end

// ChIdx1
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_ch_idx1 <= 10'd0;
        end
        else if (r_clk_cntr_en1 == 1'b0 && r_clk_cntr0 == 8'd127) begin
            r_ch_idx1 <= P_stave_num[10:1];
        end
        else if (r_clk_cntr_en1 == 1'b1 && r_clk_cntr1 == 8'd255)begin
            if (r_ch_idx1 >= s_stave_max1) begin
                r_ch_idx1 <= P_stave_num[10:1];
            end
            else begin
                r_ch_idx1 <= r_ch_idx1 + 1'b1;
            end
        end
    end

// 受波器位置テーブルRAMリードイネーブル
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_rd_en <= 1'b0;
        end
        else if ((r_clk_cntr_en0 == 1'b1 && r_clk_cntr0 <= 8'd2) ||
                 (r_clk_cntr_en1 == 1'b1 && r_clk_cntr1 <= 8'd2)) begin
            r_rd_en <= 1'b1;
        end
        else begin
            r_rd_en <= 1'b0;
        end
    end

// ChIdx x3
    assign s_ch_idx0_x3 = (r_ch_idx0 << 1) + {1'b0, r_ch_idx0} ;
    assign s_ch_idx1_x3 = (r_ch_idx1 << 1) + {1'b0, r_ch_idx1} ;

// 受波器位置テーブルRAMリードアドレス
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_rd_addr <= 11'd0;
        end
        else if (r_clk_cntr_en0 == 1'b1 && r_clk_cntr0 == 8'd0) begin
            // P_stave_numは最大682。682x3=2046なので11bitでOK。
            // s_ch_idx0_x3[11]は未使用(常に0となるため捨ててOK)
            r_rd_addr <= s_ch_idx0_x3[10:0];
        end
        else if (r_clk_cntr_en1 == 1'b1 && r_clk_cntr1 == 8'd0) begin
            // P_stave_numは最大682。682x3=2046なので11bitでOK。
            // s_ch_idx1_x3[11]は未使用(常に0となるため捨ててOK)
            r_rd_addr <= s_ch_idx1_x3[10:0];
        end
        else if (r_rd_en == 1'b1) begin
            r_rd_addr <= r_rd_addr + 1'b1;
        end
    end

// 受波器位置テーブルRAMリードデータS/P
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_rd_data0    <= 32'd0;
            r_rd_data1    <= 32'd0;
            r_rd_data2    <= 32'd0;
            r_rd_data_lt0 <= 32'd0;
            r_rd_data_lt1 <= 32'd0;
            r_rd_data_lt2 <= 32'd0;
        end
        else begin
            if (r_clk_cntr0 == 8'd3 || r_clk_cntr1 == 8'd3) begin
                r_rd_data0    <= s_rd_data;
            end
            if (r_clk_cntr0 == 8'd4 || r_clk_cntr1 == 8'd4) begin
                r_rd_data1    <= s_rd_data;
            end
            if (r_clk_cntr0 == 8'd5 || r_clk_cntr1 == 8'd5) begin
                r_rd_data2    <= s_rd_data;
            end
            if (r_clk_cntr0 == 8'd6 || r_clk_cntr1 == 8'd6) begin
                r_rd_data_lt0 <= r_rd_data0;
                r_rd_data_lt1 <= r_rd_data1;
                r_rd_data_lt2 <= r_rd_data2;
            end
        end
    end

//--- 遅延時間[sec]の計算 ---%
// FA_ho.mの下記計算の式の計算を行う。
// FPGAでRかLか分割しているので
// 本モジュールではどちらか片方のみの計算となる
// ■FA_ho.m計算式
// delay_R = pos_right(chIdx,:)*bfDirVector_ss_R; % 遅延時間(右舷)
// delay_L = pos_left(chIdx,:)*bfDirVector_ss_L;  % 遅延時間(左舷)
    ALTERA_FP_SP_3PT_32BIT_OP03_8CK ALTERA_FP_SP_3PT_32BIT_OP03_8CK_inst (
        .clk    (i_clk156m           ),
        .areset (i_arst              ),
        .q      (s_delay             ),
        .a0     (i_bf_dir_vector_ss_x),
        .b0     (r_rd_data_lt0       ),
        .a1     (i_bf_dir_vector_ss_y),
        .b1     (r_rd_data_lt1       ),
        .en     (1'b1                ),
        .a2     (i_bf_dir_vector_ss_z),
        .b2     (r_rd_data_lt2       )
    );

//-- 遅延時間から遅延サンプルを算出 ---%
// 遅延時間[sec] 遅れは－、進みは＋の符号
// ■FA_ho.m計算式
// delay_smpl_R = delay_R*fs;        % ●遅延サンプル数(0ori)を計算[smpl] ※「/Ts」を「*fs」で代替
// delay_smpl_L = delay_L*fs;        % ●遅延サンプル数(0ori)を計算[smpl] ※「/Ts」を「*fs」で代替
    ALTERA_FP_MULT_32BIT_OP03_3CK ALTERA_FP_MULT_32BIT_OP03_3CK_inst0 (
        .clk    (i_clk156m     ),
        .areset (i_arst        ),
        .a      (s_delay       ),
        .b      (P_fs          ),
        .q      (s_delay_smpl  ),
        .en     (1'b1          )
    );

// round及びfloat->integer変換
// ■FA_ho.m計算式
// tau_sample_R = round(delay_smpl_R);        % ●最も近い整数への丸め
// tau_sample_L = round(delay_smpl_L);        % ●最も近い整数への丸め
    ALTERA_FP_FLT32BIT_INT32BIT_OP02_2CK ALTERA_FP_FLT32BIT_INT32BIT_OP02_2CK_inst (
        .clk    (i_clk156m     ),
        .areset (i_arst        ),
        .a      (s_delay_smpl  ),
        .q      (s_tau_sample  ),
        .en     (1'b1          )
    );

// integer->float変換
// tau_precise計算のためround後再度floatに戻す
// ■FA_ho.m計算式
// tau_sample_R = round(delay_smpl_R);        % ●最も近い整数への丸め
// tau_sample_L = round(delay_smpl_L);        % ●最も近い整数への丸め
    ALTERA_FP_INT32BIT_FLT32BIT_OP02_4CK ALTERA_FP_INT32BIT_FLT32BIT_OP02_4CK_inst (
        .clk    (i_clk156m       ),
        .areset (i_arst          ),
        .a      (s_tau_sample    ),
        .q      (s_tau_sample_flt),
        .en     (1'b1            )
    );

// %--- 詳細遅延時間[sec]の算出
// ■FA_ho.m計算式
// delay_round_R = Ts * tau_sample_R;        % ●遅延時間[sec]の整数値を再算出
// delay_round_L = Ts * tau_sample_L;        % ●遅延時間[sec]の整数値を再算出
    ALTERA_FP_MULT_32BIT_OP03_3CK ALTERA_FP_MULT_32BIT_OP03_3CK_inst1 (
        .clk    (i_clk156m       ),
        .areset (i_arst          ),
        .a      (P_ts            ),
        .b      (s_tau_sample_flt),
        .q      (s_delay_round   ),
        .en     (1'b1            )
    );

// delayシフト
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_delay_sft <= 384'b0;
        end
        else begin
            r_delay_sft <= {r_delay_sft[351:0], s_delay};
        end
    end

// ■FA_ho.m計算式
// tau_precise_R = delay_R - delay_round_R;        % ●遅延時間[sec]から整数値を引いて小数値（詳細遅延）を算出
// tau_precise_L = delay_L - delay_round_L;        % ●遅延時間[sec]から整数値を引いて小数値（詳細遅延）を算出
    ALTERA_FP_SUB_32BIT_OP03_3CK ALTERA_FP_SUB_32BIT_OP03_3CK_inst (
        .clk    (i_clk156m           ),
        .areset (i_arst              ),
        .a      (r_delay_sft[383:352]),
        .b      (s_delay_round       ),
        .q      (s_tau_precise       ),
        .en     (1'b1                )
    );

// 出力リタイミング
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_tau_precise0 <= 32'd0;
            r_tau_precise1 <= 32'd0;
            r_tau_sample0  <= 32'd0;
            r_tau_sample1  <= 32'd0;
            r_ch_idx0_out  <= 10'd0;
            r_ch_idx1_out  <= 10'd0;
        end
        else begin
            if (r_clk_cntr0 == 8'd30) begin
                r_tau_precise0 <= s_tau_precise;
                r_tau_sample0  <= s_tau_sample;
                r_ch_idx0_out  <= r_ch_idx0;
            end
            if (r_clk_cntr1 == 8'd30) begin
                r_tau_precise1 <= s_tau_precise;
                r_tau_sample1  <= s_tau_sample;
                r_ch_idx1_out  <= r_ch_idx1;
            end
        end
    end

    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_ch_start0  <= 1'b0;
            r_ch_start1  <= 1'b0;
        end
        else begin
            if (r_clk_cntr0 == 8'd30) begin
                r_ch_start0  <= 1'b1;
            end
            else begin
                r_ch_start0  <= 1'b0;
            end
            if (r_clk_cntr1 == 8'd30) begin
                r_ch_start1  <= 1'b1;
            end
            else begin
                r_ch_start1  <= 1'b0;
            end
        end
    end

// ------ //
// Output //
// ------ //
    assign o_tau_precise0 = r_tau_precise0;
    assign o_tau_precise1 = r_tau_precise1;
    assign o_tau_sample0  = r_tau_sample0;
    assign o_tau_sample1  = r_tau_sample1;
    assign o_ch_idx0      = r_ch_idx0_out;
    assign o_ch_idx1      = r_ch_idx1_out;
    assign o_ch_start0    = r_ch_start0;
    assign o_ch_start1    = r_ch_start1;

endmodule
