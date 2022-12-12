//--------------------------------------------------------------------------------------------------
// Company           : Oki Electric Industry Co., Ltd.
// Project Name      : FPGA development for sonar (29SS)
// Module Name       : xa_bf_ctrl
// Function          : Beam Forming Control Module
// Create Date       : 2019.06.04
// Original Designer : Kenjiro Yakuwa
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// History:
//--------------------------------------------------------------------------------------------------
// Ver   | Date         | Designer          | Comment
//--------------------------------------------------------------------------------------------------
// 1.0   | 2019.06.04   | Kenjiro Yakuwa    | 新規作成
// 1.1   | 2019.08.27   | MTC) Oikawa       | ステートマシン修正（P_IDLE削除）
// 1.2   | 2022.09.15   | Masayuki Kato     | 制御毎の処理に変更(FA04-FA07統合)
//
// Copyright 2019 Oki Electric Industry Co., Ltd.
//
//--------------------------------------------------------------------------------------------------
// Module & Port
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
module xa_bf_ctrl_fac04 #(												// v1.2
    parameter      [ 3:0]    P_frame_max    =    4'h7                ,    // 入力データ格納RAMのデータ更新周期（0ori換算）
    parameter      [19:0]    P_pad_size     =   20'd0                ,    // パディングデータ付与パラメータ
    parameter      [ 4:0]    P_calc_num     =    5'd2                     // 信号処理演算回数数パラメータ
)
(
// input
    input  wire              i_arst                                  ,    // 非同期リセット
    input  wire              i_clk156m                               ,    // クロック
    input  wire    [3:0]     i_frame_time                            ,    // フレームカウンター ※入力データ格納RAMのデータ更新周期の設定値により満了値が異なる
    input  wire              i_sp_start                              ,    // 信号処理開始パルス（信号処理インタフェースからの指示）
    input  wire              i_sp_start_fa05                         ,    // 信号処理開始パルス（信号処理インタフェースからの指示）v1.2
    input  wire              i_sp_start_fa06                         ,    // 信号処理開始パルス（信号処理インタフェースからの指示）v1.2
    input  wire              i_sp_start_fa07                         ,    // 信号処理開始パルス（信号処理インタフェースからの指示）v1.2

    input  wire              i_sp_end                                ,    // 演算処理完了通知（演算1回毎) w_join_end_fa04
    input  wire    [31:0]    i_frame_offset                          ,    // P_frame_offset0値入力
    input  wire              i_param_end                             ,    // 音速・位置ベクトル転送完了通知
    input  wire              i_system                                ,    // システム設定(1:TA, 0:FA)

	input	wire			i_sp_end_sub							,	// v1.2
	input	wire			i_ddr_endp_fa04							,	// v1.2
	input	wire			i_ddr_endp_fa05							,	// v1.2
	input	wire			i_ddr_endp_fa06							,	// v1.2
	input	wire			i_ddr_endp_fa07							,	// v1.2

	input	wire			i_calc_start_fa05			,//演算開始指示　v1.2
	input	wire			i_calc_start_fa06			,//演算開始指示　v1.2
//	input	wire			i_calc_start_fa07			,//演算開始指示　v1.2

    input wire	i_join_end_fa05	,// v1.2
    input wire	i_join_end_fa06	,// v1.2
    input wire	i_join_end_fa07	,// v1.2

// output
    output wire    [4:0]     o_frame_time                            ,    // フレームカウンター（信号処理回数単位)
    output wire              o_calc_start                            ,    // 演算処理開始パルス
    output wire              o_sp_end                                ,    // 信号処理完了パルス
    output wire    [19:0]    o_pad_size                              ,    // パディング付与量制御
    output wire              o_end_ins                               ,    // エンドコード付与制御
    output wire    [31:0]    o_frame_offset0                         ,    // 信号処理IF部へのframe_offset0値出力
    output wire              o_param_start                           ,     // 音速・位置ベクトル転送指示
    output wire	   [3:0]     o_fa_en								,	// v1.2
//    output wire				 o_param_end							,	// v1.2
//	output	wire			o_join_end_p							,	// v1.2
	output wire		[3:0]	o_calc_cnt_fa04							,	// v1.2
    output wire    [6:0]     o_r_state_fa04  							// v1.2
);

//--------------------------------------------------------------------------------------------------
// Parameter
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// Rev1.1    localparam   P_IDLE       = 7'b000_0001; // IDLE状態
    localparam   P_WAIT_SPEC  = 7'b000_0010; // 緒元算出結果リード完了待ち状態
    localparam   P_WAIT_TRANS = 7'b000_0100; // 緒元算出結果転送完了待ち状態
    localparam   P_WAIT_RAM0_08  = 7'b000_1000; // DDR3→RAM0リード完了待ち状態 v1.2
    localparam   P_WAIT_RAM0_09  = 7'b000_1001; // DDR3→RAM2リード完了待ち状態 v1.2
    localparam   P_WAIT_RAM0_10  = 7'b000_1010; // DDR3→RAM3リード完了待ち状態 v1.2
    localparam   P_WAIT_RAM0_11  = 7'b000_1011; // DDR3→RAM3リード完了待ち状態 v1.2
    localparam   P_WAIT_RAM1_16  = 7'b001_0000; // DDR3→RAM1リード完了待ち状態 v1.2
    localparam   P_WAIT_RAM1_17  = 7'b001_0001; // DDR3→RAM3リード完了待ち状態	v1.2
    localparam   P_WAIT_RAM1_18  = 7'b001_0010; // DDR3→RAM3リード完了待ち状態 v1.2
    localparam   P_WAIT_RAM1_19  = 7'b001_0011; // DDR3→RAM3リード完了待ち状態 v1.2
    localparam   P_WAIT_CALC29   = 7'b001_1101; // 演算処理完了待ち 29  v1.2
    localparam   P_WAIT_CALC30   = 7'b001_1110; // 演算処理完了待ち 30  v1.2
    localparam   P_WAIT_CALC31   = 7'b001_1111; // 演算処理完了待ち 31  v1.2
    localparam   P_WAIT_CALC     = 7'b010_0000; // 演算処理完了待ち
    localparam	 P_WAIT_DDR3W_04 = 7'b011_1100; //FA04_DDR3ライト完了待ち v1.2
    localparam	 P_WAIT_DDR3W_05 = 7'b011_1101; //FA05_DDR3ライト完了待ち v1.2
    localparam	 P_WAIT_DDR3W_06 = 7'b011_1110; //FA06_DDR3ライト完了待ち v1.2
    localparam	 P_WAIT_DDR3W_07 = 7'b011_1111; //FA07_DDR3ライト完了待ち v1.2
    localparam   P_END_JUDGE     = 7'b100_0000; // フレーム処理完了判定

//--------------------------------------------------------------------------------------------------
// Reg & Wire
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
    reg  [3:0]     r_frame_time;
    wire           s_frame_time_chg;
    reg  [6:0]     r_state;
    reg  [6:0]     r_state_1t;
// 	reg [6:0]		r_state_2t;			// v1.2
    reg  [4:0]     r_calc_cnt;
 
    reg            r_calc_start;
    reg  [19:0]    r_pad_size;
    reg            r_end_ins;
    reg            r_sp_end;
    reg            r_param_start;
    reg  [4:0]     r_frame_time_out;
    reg  [31:0]    r_frame_offset0;
   reg	param_reg;					// v1.2
   reg	param_end_reg;				// v1.2
   reg	sp_end_reg;					// v1.2
   reg	o_sp_end_reg;				// v1.2
   reg r_ddr_endp_fa04;				//v1.2
   reg r_ddr_endp_fa05;				//v1.2
   reg r_ddr_endp_fa06;				//v1.2
   reg r_ddr_endp_fa07;				//v1.2
//   wire w_sp_end_fa07;			//v1.2


	reg		r_join_end_fa04;	//v1.2
	reg		r_join_end_fa05;	//v1.2
	reg		r_join_end_fa06;	//v1.2
	reg		r_join_end_fa07;	//v1.2
	reg[1:0]	r_join_end_all;	//v1.2
	wire		w_join_end_all;
	wire	 	w_join_end_all_p;	//v1.2

//----------------------------------------------//
//		TEST				//
//----------------------------------------------//
	wire		fa04_en,fa05_en,fa06_en,fa07_en;	// v1.2
	wire[3:0]	fa_en;								// v1.2
//	wire		st_en;								// v1.2


//--------------------------------------------------------------------------------------------------
// Parameter Output
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0


//--------------------------------------------------------------------------------------------------
// Sub Module
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0

//--------------------------------------------------------------------------------------------------
// Main
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0

//assign w_sp_end_fa07 = fa07_en && i_sp_end;


// ------------------------------------ //
// ステートマシン、各タイミング信号生成 //
// ------------------------------------ //
// i_frame_time変化検出
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_frame_time <= P_frame_max;
        end
        else begin
            r_frame_time <= i_frame_time;
        end
    end

    assign s_frame_time_chg = (i_frame_time != r_frame_time) ? 1'b1 : 1'b0;

// State Machine
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
// Rev1.1            r_state <= P_IDLE;
            r_state <= P_WAIT_SPEC;
        end
        else begin
            case (r_state)
// Rev1.1                 //  P_IDLE
// Rev1.1                 P_IDLE : begin
// Rev1.1                     if (s_frame_time_chg == 1'b1) begin
// Rev1.1                       r_state <= P_WAIT_SPEC;
// Rev1.1                     end
// Rev1.1                 end
                 //  P_WAIT_SPEC
                 P_WAIT_SPEC : begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
                     else if (i_system == 1'b1 && i_sp_start == 1'b1) begin
                       // TAの時はi_sp_start=1'b1(緒元算出結果のリード完了）で遷移
                       r_state <= P_WAIT_TRANS;
                     end
                     else if (i_system == 1'b0) begin
                       // FAの時は緒元算出結果のリードを行わないので即遷移
                       r_state <= P_WAIT_TRANS;
                     end
                 end
                 //  P_WAIT_TRANS
                 P_WAIT_TRANS : begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
                     else if (i_param_end == 1'b1) begin
                       r_state <= P_WAIT_RAM0_08;	// v1.2
                     end
                 end
		//FAC04の処理
                 //  P_WAIT_RAM0
                 P_WAIT_RAM0_08 : begin				// v1.2
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
                     else if (i_sp_start == 1'b1) begin
                       r_state <= P_WAIT_RAM1_16;	// v1.2
                     end
                 end
                 //  P_WAIT_RAM1 v1.2
                 P_WAIT_RAM1_16 : begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
                     else if (i_sp_start == 1'b1) begin
                      // r_state <= P_WAIT_CALC;		//v1.2
                       r_state <= P_WAIT_CALC29;		//v1.2
                     end
                 end
                 //  P_WAIT_CALC29
                 P_WAIT_CALC29 : begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
//                     else if (i_sp_end == 1'b1) begin
                     else if (r_calc_start == 1'b1) begin
                       r_state <= P_WAIT_RAM0_09;
                 	end
		end
		//FAC05の処理 v1.2
                 //  P_WAIT_RAM2 	//v1.2
                 P_WAIT_RAM0_09 : begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
                     else if (i_sp_start_fa05 == 1'b1) begin
                       r_state <= P_WAIT_RAM1_17;
                     end
                 end
                 //  P_WAIT_RAM3 	//v1.2
                 P_WAIT_RAM1_17 : begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
                     else if (i_sp_start_fa05 == 1'b1) begin
                       r_state <= P_WAIT_CALC30;
                     end
                 end
                 //  P_WAIT_CALC30
                 P_WAIT_CALC30 : begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
//                     else if (i_sp_end == 1'b1) begin
			else if(i_calc_start_fa05==1'b1)begin
                       r_state <= P_WAIT_RAM0_10;
                     end
                 end
		//FAC06の処理　v1.2
                 //  P_WAIT_RAM4 	//v1.2
                 P_WAIT_RAM0_10 : begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
                     else if (i_sp_start_fa06 == 1'b1) begin
                       r_state <= P_WAIT_RAM1_18;
                     end
                 end
                 //  P_WAIT_RAM5 	//v1.2
                 P_WAIT_RAM1_18 : begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
                     else if (i_sp_start_fa06 == 1'b1) begin
                       r_state <= P_WAIT_CALC31;
                     end
                 end
                 //  P_WAIT_CALC31
                 P_WAIT_CALC31 : begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
//                     else if (i_sp_end == 1'b1) begin
			else if(i_calc_start_fa06==1'b1)begin
                       r_state <= P_WAIT_RAM0_11;
                     end
                 end
		//FAC07の処理　v1.2
                 //  P_WAIT_RAM6 	//v1.2
                 P_WAIT_RAM0_11 : begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
                     else if (i_sp_start_fa07 == 1'b1) begin
                       r_state <= P_WAIT_RAM1_19;
                     end
                 end
                 //  P_WAIT_RAM7 	//v1.2
                 P_WAIT_RAM1_19 : begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
                     else if (i_sp_start_fa07 == 1'b1) begin
                       r_state <= P_WAIT_CALC;
                     end
                 end

                 //  P_WAIT_CALC
                 P_WAIT_CALC : begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
		     else if (w_join_end_all ==1'b1)begin
//		     else if (w_join_end_all_p ==1'b1)begin
//                     else if (w_sp_end_fa07 == 1'b1) begin
//                       r_state <= P_END_JUDGE;
                       r_state <= P_WAIT_DDR3W_04;
                     end
                 end
		//DDR3ライト処理　v1.2
				//P_WAIT_DDR3W_04 _60
				P_WAIT_DDR3W_04 :begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
//                     else if (w_join_end_all == 1'b1) begin
                     else if (i_ddr_endp_fa04 == 1'b1) begin
                       r_state <= P_WAIT_DDR3W_05;
                     end
                 end

				//P_WAIT_DDR3W_05 _61
				P_WAIT_DDR3W_05 :begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
                     else if (i_ddr_endp_fa05 == 1'b1) begin
                       r_state <= P_WAIT_DDR3W_06;
                     end
                 end

				//P_WAIT_DDR3W_06 _62
				P_WAIT_DDR3W_06 :begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
                     else if (i_ddr_endp_fa06 == 1'b1) begin
                       r_state <= P_WAIT_DDR3W_07;
                     end
                 end

				//P_WAIT_DDR3W_07 _63
				P_WAIT_DDR3W_07 :begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
                     else if (i_ddr_endp_fa07 == 1'b1) begin
                       r_state <= P_END_JUDGE;
                     end
                 end

                 //  P_END_JUDGE _64
                 P_END_JUDGE : begin
                     if (s_frame_time_chg == 1'b1) begin
                       r_state <= P_WAIT_SPEC;
                     end
                     else if(r_calc_cnt <= (P_calc_num - 5'd1)) begin
   		                 	   r_state <= P_WAIT_RAM0_08;		//v1.2
							end
					else if (r_calc_cnt == P_calc_num) begin
// Rev1.1                       r_state <= P_IDLE;
                       		r_state <= P_WAIT_SPEC;
                     		end
                 	end
			
                 default : begin
// Rev1.1                     r_state <= P_IDLE;
                     r_state <= P_WAIT_SPEC;
                 end
            endcase
        end
    end

// State Machine 1τ Delay
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
// Rev1.1            r_state_1t <= P_IDLE;
            r_state_1t <= P_WAIT_SPEC;
//            r_state_2t <=6'd0;				//v1.2
        end
        else begin
            r_state_1t <= r_state;
//            r_state_2t <= r_state_1t;		//v1.2
        end
    end

// 演算処理回数カウンタ
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_calc_cnt <= 5'b00000;
        end
        else if ((r_state_1t != P_WAIT_SPEC) && (r_state == P_WAIT_SPEC)) begin
            // P_WAIT_SPEC以外の状態からP_WAIT_SPECに遷移
            r_calc_cnt <= 5'b00000;
        end
//次段の処理開始でカウントアップする　
//       else if ((r_state == P_WAIT_CALC29) && (i_sp_end == 1'b1)) begin
          else if (i_sp_end == 1'b1) begin
 
           r_calc_cnt <= r_calc_cnt + 1'b1;
        end
    end

// 演算処理開始パルス出力
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_calc_start     <= 1'b0;
        end
//        else if ((r_state_1t == P_WAIT_RAM1) && (r_state == P_WAIT_CALC)) begin	//v1.2
//FA04
        else if ((r_state_1t == P_WAIT_RAM1_16) && (r_state == P_WAIT_CALC29)) begin	//v1.2
            // P_WAIT_RAM -> P_WAIT_CALC
            r_calc_start <= 1'b1;
        end
//FA05
//        else if ((r_state_1t == P_WAIT_RAM1_17) && (r_state == P_WAIT_CALC30)) begin	//v1.2
            // P_WAIT_RAM -> P_WAIT_CALC
//            r_calc_start <= 1'b1;
//        end
//FA06
//        else if ((r_state_1t == P_WAIT_RAM1_18) && (r_state == P_WAIT_CALC31)) begin	//v1.2
            // P_WAIT_RAM -> P_WAIT_CALC
//            r_calc_start <= 1'b1;
//        end
//FA07
//        else if ((r_state_1t == P_WAIT_RAM1_19) && (r_state == P_WAIT_CALC)) begin	//v1.2
            // P_WAIT_RAM -> P_WAIT_CALC
//            r_calc_start <= 1'b1;
//        end
        else begin
            r_calc_start <= 1'b0;
        end
    end

// パディング＋エンドコード挿入指示
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_pad_size <= 20'd0;
            r_end_ins  <=  1'b0;
        end
//        else if (r_state == P_WAIT_CALC) begin		//v1.2
        else if (r_state == P_WAIT_CALC29) begin		//v1.2
            if (r_calc_cnt == (P_calc_num - 5'd1)) begin
                r_pad_size <= P_pad_size;
                r_end_ins  <=  1'b1;
            end
            else begin
                r_pad_size <= 20'd0;
                r_end_ins  <=  1'b0;
            end
        end
        else begin
            r_pad_size <= 20'd0;
            r_end_ins  <=  1'b0;
        end
    end

// 演算処理完了パルス出力
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_sp_end <= 1'b0;
        end
        else if ((r_state_1t == P_WAIT_TRANS) && (r_state == P_WAIT_RAM0_08)) begin	//v1.2
           if (i_system == 1'b1) begin
               r_sp_end <= 1'b1; // TA：緒元算出結果転送に対するのo_sp_end出力(ダミー)
           end
           else begin
               r_sp_end <= 1'b0; // FA：緒元算出結果転送が無いのでo_sp_end出力無し。
           end
        end
//FA04 v1.2
        else if ((r_state_1t == P_WAIT_RAM0_08) && (r_state == P_WAIT_RAM1_16)) begin
            r_sp_end <= 1'b1; // DDR3→入力RAM0への書き込み完了に対するo_sp_end出力(ダミー)
        end
//FA05
//        else if ((r_state_1t == P_WAIT_RAM0_09) && (r_state == P_WAIT_RAM1_17)) begin					//v1.2
//            r_sp_end <= 1'b1; // DDR3→入力RAM2への書き込み完了に対するo_sp_end出力(ダミー)		//v1.2
//        end																						//v1.2
//FA06
//        else if ((r_state_1t == P_WAIT_RAM0_10) && (r_state == P_WAIT_RAM1_18)) begin					//v1.2
//            r_sp_end <= 1'b1; // DDR3→入力RAM4への書き込み完了に対するo_sp_end出力(ダミー)		//v1.2
//        end																						//v1.2
//FA07
//        else if ((r_state_1t == P_WAIT_RAM0_11) && (r_state == P_WAIT_RAM1_19)) begin					//v1.2
//            r_sp_end <= 1'b1; // DDR3→入力RAM6への書き込み完了に対するo_sp_end出力(ダミー)		//v1.2
//        end																						//v1.2
//        else if ((r_state_1t == P_END_JUDGE) && (r_state == P_WAIT_RAM0_08)) begin
//            r_sp_end <= 1'b1; // 演算完了に対するo_sp_end出力
//        end
// Rev1.1        else if ((r_state_1t == P_END_JUDGE) && (r_state == P_IDLE)) begin
//        else if ((r_state_1t == P_END_JUDGE) && (r_state == P_WAIT_SPEC)) begin
//	 else if(i_sp_end_sub == 1'b1)begin	//v1.2
//            r_sp_end <= 1'b1; // 演算完了に対するo_sp_end出力
//        end
//v1.2
	 	else if(w_join_end_all_p == 1'b1)begin						
            r_sp_end <= 1'b1;
        end
        else begin
            r_sp_end <= 1'b0;
        end
    end

// パラメータ転送開始指示出力
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_param_start <= 1'b0;
        end
        else if ((r_state_1t == P_WAIT_SPEC) && (r_state == P_WAIT_TRANS)) begin
            r_param_start <= 1'b1;
        end
        else begin
            r_param_start <= 1'b0;
        end
    end

// 出力frame_time生成
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_frame_time_out <= 5'd0;
        end
        else if (r_calc_start == 1'b1) begin
           if (P_calc_num == 5'd16) begin
               r_frame_time_out <= {r_frame_time[0],   r_calc_cnt[3:0]};
           end
           else if (P_calc_num == 5'd8) begin
               r_frame_time_out <= {r_frame_time[1:0], r_calc_cnt[2:0]};
           end
           else if (P_calc_num == 5'd4) begin
               r_frame_time_out <= {r_frame_time[2:0], r_calc_cnt[1:0]};
           end
           else if (P_calc_num == 5'd2) begin
               r_frame_time_out <= {r_frame_time[3:0], r_calc_cnt[0]};
           end
           else begin
               r_frame_time_out <= {1'b0, r_frame_time[3:0]};
           end
        end
    end

// 入力RAM0フレームオフセット制御
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_frame_offset0 <= 32'h0000_0000;
        end
        else if (r_state == P_WAIT_SPEC) begin
            if (i_system == 1'b1) begin
                r_frame_offset0 <= 32'h0000_0000;
             end
             else begin
                r_frame_offset0 <= i_frame_offset;
             end
        end
        else begin
            r_frame_offset0 <= i_frame_offset;
        end
    end


//DDR3出力信号選択制御信号 v1.2
/*
    assign fa04_en = (r_state_2t == P_WAIT_RAM0_08 || r_state_2t == P_WAIT_RAM1_16 ||r_state_2t == P_WAIT_CALC29 ||r_state_2t == P_WAIT_DDR3W_04  || r_state_2t == P_END_JUDGE );
    assign fa05_en = (r_state_2t == P_WAIT_RAM0_09 || r_state_2t == P_WAIT_RAM1_17 ||r_state_2t == P_WAIT_CALC30 ||r_state_2t == P_WAIT_DDR3W_05  );
    assign fa06_en = (r_state_2t == P_WAIT_RAM0_10 || r_state_2t == P_WAIT_RAM1_18 ||r_state_2t == P_WAIT_CALC31 ||r_state_2t == P_WAIT_DDR3W_06  );
    assign fa07_en = (r_state_2t == P_WAIT_RAM0_11 || r_state_2t == P_WAIT_RAM1_19 ||r_state_2t == P_WAIT_CALC   ||r_state_2t == P_WAIT_DDR3W_07  );
*/
    assign fa04_en = (r_state == P_WAIT_RAM0_08 || r_state == P_WAIT_RAM1_16 ||r_state == P_WAIT_CALC29 ||r_state == P_WAIT_DDR3W_04  || r_state == P_END_JUDGE );
    assign fa05_en = (r_state == P_WAIT_RAM0_09 || r_state == P_WAIT_RAM1_17 ||r_state == P_WAIT_CALC30 ||r_state == P_WAIT_DDR3W_05  );
    assign fa06_en = (r_state == P_WAIT_RAM0_10 || r_state == P_WAIT_RAM1_18 ||r_state == P_WAIT_CALC31 ||r_state == P_WAIT_DDR3W_06  );
    assign fa07_en = (r_state == P_WAIT_RAM0_11 || r_state == P_WAIT_RAM1_19 ||r_state == P_WAIT_CALC   ||r_state == P_WAIT_DDR3W_07  );

    assign fa_en = {fa07_en,fa06_en,fa05_en,fa04_en};

//	assign st_en = (r_state == P_WAIT_RAM1_16) ? 1'b1 : 1'b0; 

//次段へのparam_end送信 v1.2
/*
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
		param_reg <= 1'd0;
	end
	
	else if(param_reg == 1'd1)begin
			if(r_state == P_END_JUDGE)begin
				param_reg <= 1'd0;
			end
			else begin
				param_reg <= param_reg;
			end	
		end
	else begin 
			param_reg <= i_param_end;
		end
	end

    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
		param_end_reg <= 1'd0;
	end
		else begin
			param_end_reg <= i_sp_start && param_reg && st_en ;
		end
	end


//次段へのsp_end送信 v1.2
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
		sp_end_reg <= 1'd0;
	end
	else if(sp_end_reg == 1'd1)begin
			if(r_state == P_WAIT_RAM1_16)begin
				sp_end_reg <= 1'd0;
			end
		else begin
				sp_end_reg <= sp_end_reg;
			end
		end
	else begin
		sp_end_reg <= i_sp_end_sub;
		end
    end

    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
		o_sp_end_reg <= 1'd0;
	end
		else begin
			o_sp_end_reg <= i_sp_end && sp_end_reg;
		end
	end
*/

//前半RAMアクセス完了信号の状態保持 v1.2
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
			r_ddr_endp_fa04 <= 1'd0;
		end
		else if(r_state == P_END_JUDGE)begin
				r_ddr_endp_fa04 <= 1'd0;
			end
		else if(r_ddr_endp_fa04 == 1'd1)begin
				r_ddr_endp_fa04 <= r_ddr_endp_fa04;
			end
		else begin
				r_ddr_endp_fa04 <= i_ddr_endp_fa04 ;
			end
    end

//前半RAMアクセス完了信号の状態保持 v1.2
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
			r_ddr_endp_fa05 <= 1'd0;
		end
		else if(r_state == P_END_JUDGE)begin
				r_ddr_endp_fa05 <= 1'd0;
			end
		else if(r_ddr_endp_fa05 == 1'd1)begin
				r_ddr_endp_fa05 <= r_ddr_endp_fa05;
			end
		else begin
				r_ddr_endp_fa05 <= i_ddr_endp_fa05 ;
			end
    end
//前半RAMアクセス完了信号の状態保持 v1.2
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
			r_ddr_endp_fa06 <= 1'd0;
		end
		else if(r_state == P_END_JUDGE)begin
				r_ddr_endp_fa06 <= 1'd0;
			end
		else if(r_ddr_endp_fa06 == 1'd1)begin
				r_ddr_endp_fa06 <= r_ddr_endp_fa06;
			end
		else begin
				r_ddr_endp_fa06 <= i_ddr_endp_fa06 ;
			end
    end
//前半RAMアクセス完了信号の状態保持 v1.2
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
			r_ddr_endp_fa07 <= 1'd0;
		end
//		else if(r_state == P_END_JUDGE)begin
		else if((r_state == P_WAIT_RAM0_08) ||(r_state == P_WAIT_SPEC))begin
				r_ddr_endp_fa07 <= 1'd0;
			end
		else if(r_ddr_endp_fa07 == 1'd1)begin
				r_ddr_endp_fa07 <= r_ddr_endp_fa07;
			end
		else begin
				r_ddr_endp_fa07 <= i_ddr_endp_fa07 ;
			end
    end
//------------------------------------------------------
//4Signal Effect Complite v1.2
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
			r_join_end_fa04 <= 1'd0;
		end
		else if(r_state == P_END_JUDGE)begin
				r_join_end_fa04 <= 1'd0;
			end
		else if(r_join_end_fa04 == 1'd1)begin
				r_join_end_fa04 <= r_join_end_fa04;
			end
		else begin
				r_join_end_fa04 <= i_sp_end;
			end
    end
//4Signal Effect Complite v1.2
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
			r_join_end_fa05 <= 1'd0;
		end
		else if(r_state == P_END_JUDGE)begin
				r_join_end_fa05 <= 1'd0;
			end
		else if(r_join_end_fa05 == 1'd1)begin
				r_join_end_fa05 <= r_join_end_fa05;
			end
		else begin
				r_join_end_fa05 <= i_join_end_fa05 ;
			end
    end

//4Signal Effect Complite v1.2
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
			r_join_end_fa06 <= 1'd0;
		end
		else if(r_state == P_END_JUDGE)begin
				r_join_end_fa06 <= 1'd0;
			end
		else if(r_join_end_fa06 == 1'd1)begin
				r_join_end_fa06 <= r_join_end_fa06;
			end
		else begin
				r_join_end_fa06 <= i_join_end_fa06 ;
			end
    end

//4Signal Effect Complite v1.2
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
			r_join_end_fa07 <= 1'd0;
		end
		else if(r_state == P_END_JUDGE)begin
				r_join_end_fa07 <= 1'd0;
			end
		else if(r_join_end_fa07 == 1'd1)begin
				r_join_end_fa07 <= r_join_end_fa07;
			end
		else begin
				r_join_end_fa07 <= i_join_end_fa07 ;
			end
    end

//4Signal Effect Complite v1.2
	assign w_join_end_all = r_join_end_fa04 && r_join_end_fa05 && r_join_end_fa06  && r_join_end_fa07 ;

    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) 
			r_join_end_all = 2'd0;
		else begin
			r_join_end_all[0] <= w_join_end_all;
			r_join_end_all[1] <= r_join_end_all[0];
		end
	end 
			
	assign w_join_end_all_p = !r_join_end_all[1] && r_join_end_all[0];



// ------ //
// Output //
// ------ //
    assign o_frame_time     = r_frame_time_out;
    assign o_param_start    = r_param_start;
    assign o_calc_start     = r_calc_start;
    assign o_sp_end         = r_sp_end; 	//v1.2

    assign o_pad_size       = r_pad_size;
    assign o_end_ins        = r_end_ins;
    assign o_frame_offset0  = r_frame_offset0;
    assign o_r_state_fa04	= r_state;			// v1.2
    assign o_fa_en	    	= fa_en;			// v1.2
	assign o_calc_cnt_fa04	= r_calc_cnt[3:0];	//v1.2
//	assign o_join_all_p		= w_join_end_all_p;		// v1.2
//    assign o_param_end		= param_end_reg; 	// v1.2
//    assign o_sp_end  		= o_sp_end_reg;		// v1.2

endmodule
