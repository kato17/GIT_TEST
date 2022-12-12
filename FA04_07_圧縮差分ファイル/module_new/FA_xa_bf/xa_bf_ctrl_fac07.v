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
// 1.2   | 2022.09.15   | WNT) Kato         | ステートマシン修正（P_IDLE削除）

//
// Copyright 2019 Oki Electric Industry Co., Ltd.
//
//--------------------------------------------------------------------------------------------------
// Module & Port
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
module xa_bf_ctrl_fac07 #(			//v1.2
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
	input  wire              i_sp_end                                ,    // 演算処理完了通知（演算1回毎)
	input  wire    [31:0]    i_frame_offset                          ,    // P_frame_offset0値入力
	input  wire              i_param_end                             ,    // 音速・位置ベクトル転送完了通知
	input  wire              i_system                                ,    // システム設定(1:TA, 0:FA)
	input  wire    [6:0]     i_r_state_fa04						     ,		//状態信号 v1.2
	input  wire		     	 i_sp_end_sub						 	 ,	//前段のアクセス完了パルス v1.2
	input  wire		     	 i_ddr_endp							   	 ,	//前段のアクセス完了パルス v1.2

// output
    output wire    [4:0]     o_frame_time                            ,    // フレームカウンター（信号処理回数単位)
    output wire              o_calc_start                            ,    // 演算処理開始パルス
    output wire              o_sp_end                                ,    // 信号処理完了パルス
    output wire    [19:0]    o_pad_size                              ,    // パディング付与量制御
    output wire              o_end_ins                               ,    // エンドコード付与制御
    output wire    [31:0]    o_frame_offset0                         ,    // 信号処理IF部へのframe_offset0値出力
    output wire              o_param_start                                // 音速・位置ベクトル転送指示
);

//--------------------------------------------------------------------------------------------------
// Parameter
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// Rev1.1    localparam   P_IDLE       = 7'b000_0001; // IDLE状態
    localparam   P_WAIT_FA06  = 7'b000_0011; // FA04完了待ち状態
    localparam   P_WAIT_SPEC  = 7'b000_0010; // 緒元算出結果リード完了待ち状態
    localparam   P_WAIT_TRANS = 7'b000_0100; // 緒元算出結果転送完了待ち状態
    localparam   P_WAIT_RAM0  = 7'b000_1000; // DDR3→RAM0リード完了待ち状態
    localparam   P_WAIT_RAM1  = 7'b001_0000; // DDR3→RAM1リード完了待ち状態
    localparam   P_WAIT_CALC  = 7'b010_0000; // 演算処理完了待ち
    localparam   P_END_JUDGE  = 7'b100_0000; // フレーム処理完了判定



//--------------------------------------------------------------------------------------------------
// Reg & Wire
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
    reg  [3:0]     r_frame_time;
    wire           s_frame_time_chg;
    reg  [6:0]     r_state;
    reg  [6:0]     r_state_1t;

    reg  [4:0]     r_calc_cnt;
    reg            r_calc_start;
    reg  [19:0]    r_pad_size;
    reg            r_end_ins;
    reg            r_sp_end;
    reg            r_param_start;
    reg  [4:0]     r_frame_time_out;
    reg  [31:0]    r_frame_offset0;

    reg		param_reg		;	//v1.2
    reg		param_end_reg	;	//v1.2
    reg		sp_end_reg		;	//v1.2
    reg		o_sp_end_reg	;	//v1.2

//--------------------------------------------------------------------------------------------------
// Parameter Output
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0


//--------------------------------------------------------------------------------------
// Sub Module
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0

//--------------------------------------------------------------------------------------------------
// Main
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
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
// FA07の状態遷移　v1.2
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
		r_state <= P_WAIT_SPEC;
        end
        else begin
            case (r_state)
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
					r_state <= P_WAIT_RAM0;   // v1.2
				end
			end
		//  P_WAIT_RAM0
		P_WAIT_RAM0 : begin
			if (s_frame_time_chg == 1'b1) begin
				r_state <= P_WAIT_RAM0;
				end
			else if (r_state == P_WAIT_RAM0 && i_sp_start == 1'b1) begin
				r_state <= P_WAIT_RAM1;
				end
		end
		//  P_WAIT_RAM1
		P_WAIT_RAM1 : begin
			if (s_frame_time_chg == 1'b1) begin
				r_state <= P_WAIT_RAM0;
				end
			else if (r_state == P_WAIT_RAM1 && i_sp_start == 1'b1) begin
				r_state <= P_WAIT_CALC;
				end
		end
		//  P_WAIT_CALC
		P_WAIT_CALC : begin
			if (s_frame_time_chg == 1'b1) begin
					r_state <= P_WAIT_RAM0;
				end
			else if (i_ddr_endp == 1'b1 ) begin
					r_state <= P_END_JUDGE;
				end
			end
		//  P_END_JUDGE
		P_END_JUDGE : begin
			if (s_frame_time_chg == 1'b1) begin
				r_state <= P_WAIT_SPEC;
				end
			else if (r_calc_cnt <= (P_calc_num - 5'd1)) begin
					r_state <= P_WAIT_RAM0;
				end
			else if (r_calc_cnt == P_calc_num) begin
					r_state <= P_WAIT_SPEC;
				end
			end				
				default : begin
					r_state <= P_WAIT_SPEC;
				end
			endcase
		end
	end


    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_state_1t <= P_WAIT_SPEC;
        end
        else  begin
            r_state_1t <= r_state;
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
        else if (i_sp_end == 1'b1) begin
            r_calc_cnt <= r_calc_cnt + 1'b1;
        end
    end

// 演算処理開始パルス出力
    always@(posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_calc_start     <= 1'b0;
        end
        else if ((r_state_1t == P_WAIT_RAM1) && (r_state == P_WAIT_CALC)) begin
            // P_WAIT_RAM -> P_WAIT_CALC
            r_calc_start <= 1'b1;
        end
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
        else if (r_state == P_WAIT_CALC) begin
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
        else if ((r_state_1t == P_WAIT_TRANS) && (r_state == P_WAIT_RAM0)) begin
           if (i_system == 1'b1) begin
               r_sp_end <= 1'b1; // TA：緒元算出結果転送に対するのo_sp_end出力(ダミー)
           end
           else begin
               r_sp_end <= 1'b0; // FA：緒元算出結果転送が無いのでo_sp_end出力無し。
           end
        end
        else if ((r_state_1t == P_WAIT_RAM0) && (r_state == P_WAIT_RAM1)) begin
            r_sp_end <= 1'b1; // DDR3→入力RAM0への書き込み完了に対するo_sp_end出力(ダミー)
        end
// Rev1.1        else if ((r_state_fa04_1t == P_END_JUDGE) && (r_state == P_IDLE)) begin
	 else if(i_sp_end_sub == 1'b1)begin	//v1.2
            r_sp_end <= 1'b1; // 演算完了に対するo_sp_end出力
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



// ------ //
// Output //
// ------ //
    assign o_frame_time     = r_frame_time_out;
    assign o_param_start    = r_param_start;
    assign o_calc_start     = r_calc_start;
    assign o_sp_end         = r_sp_end;
    assign o_pad_size       = r_pad_size;
    assign o_end_ins        = r_end_ins;
    assign o_frame_offset0  = r_frame_offset0;

endmodule
