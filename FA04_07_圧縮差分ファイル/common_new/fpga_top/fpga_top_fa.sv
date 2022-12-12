//--------------------------------------------------------------------------------------------------
// Company           : Oki Electric Industry Co., Ltd.
// Project Name      : FPGA development for sonar (29SS)
// Module Name       : fpga_top
// Function          : FPGA Top
// Create Date       : 2019.02.12
// Original Designer : MTC)Tadayuki Nagahara
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// History:
//--------------------------------------------------------------------------------------------------
// Ver   | Date         | Designer          | Comment
//--------------------------------------------------------------------------------------------------
// 0.0   | 2019.02.12   | MTC) Nagahara     | ・新規作成
//       | 2019.02.14   | MTC) Nagahara     | ・signal_top_ddr 接続
//       | 2019.02.15   | MTC) Nagahara     | ・P_cm_1g_dmy_inst (1Gbps SerDes インプリトライアル用パラメータ)追加
//       | 2019.02.21   | MTC) Nagahara     | ・DDR3 未使用時も DDR_MODULE、emif ipは実装し、診断まで行うため、端子処理を変更
//       | 2019.02.27   | MTC) Oikawa       | ・i_signal_proc削除(信号処理処理実行中信号を音響制御出力信号に変更）
//       | 2019.03.01   | MTC) Nagahara     | ・外部リセット代替回路追加 (リセット時間：1.6ms = 6.4ns*2^18-1 )
//       |              |                   |
// 0.1   | 2019.04.23   | Nemoto            | MANTIS 0000260：「DDR_NU」削除。
// 0.2   | 2019.05.10   | Nemoto            | DPRAM & I2C 未使用ピン処理変更
//       |              |                   | 未使用で対抗デバイスが存在し対抗デバイスのピンが入力　　：出力ピン設定＋Low出力
//       |              |                   | 未使用で対抗デバイスが存在し対抗デバイスのピンが双方向　：出力ピン設定＋Low出力
//       |              |                   | 未使用で対抗デバイスが存在し対抗デバイスのピンが出力　　：未使用ピン設定（RTLはピン削除）＋qsfで「as input tri-state with week pullup」設定
// 0.3   | 2019.05.28   | Nemoto            | SOKI 0516版対応
//       |              |                   | ・SRAMピン全削除
//       |              |                   | ・SFP 3state-Enable＝1'bz
// 0.4   | 2019.09.06   | Nemoto            | n_sdc_timeout追加（MTC改版 Rev1.4）
// 0.5   | 2019.10.01   | Nemoto            | n_pt_startp追加
// 0.6   | 2022.09.29   | Kato              |
//
// Copyright 2019 Oki Electric Industry Co., Ltd.
//

// `default_nettype none

`include "./inc_fpga_top_param.h"

//--------------------------------------------------------------------------------------------------
// Module & Port
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
//`timescale 1ps / 1ps

module fpga_top
    import cm_common_pkg::*, cm_sdc_pkg::* ;
   (
   // SYSTEM ------------------------------
          input  wire            SYS_CLK       ,
          input  wire            RESET         ,
   // Transceiver(SFP) --------------------
          input  wire            SFP_CLK       ,
          output wire            SFP1_TX       ,
          output wire            SFP2_TX       ,
          output wire            SFP3_TX       ,
          input  wire            SFP1_RX       ,
          input  wire            SFP2_RX       ,
          input  wire            SFP3_RX       ,
   // Transceiver(FPGA1=>FPGA2) -----------
   `ifdef P_FPGA1
          input  wire            F1_GXB_CLK    ,
          output wire            F1_TX_F2_RX1  ,
        //output wire            F1_TX_F2_RX2  ,
        //output wire            F1_TX_F2_RX3  ,
          input  wire            F2_TX_F1_RX1  ,
        //input  wire            F2_TX_F1_RX2  ,
        //input  wire            F2_TX_F1_RX3  ,
   `else
          input  wire            F2_GXB_CLK    ,
          input  wire            F1_TX_F2_RX1  ,
        //input  wire            F1_TX_F2_RX2  ,
        //input  wire            F1_TX_F2_RX3  ,
          output wire            F2_TX_F1_RX1  ,
        //output wire            F2_TX_F1_RX2  ,
        //output wire            F2_TX_F1_RX3  ,
   `endif
   // DDR3 --------------------------------
          input  wire            DDR_CLK       ,
          inout  wire  [31:0]    DDR_DQ        ,
          inout  wire  [ 3:0]    DDR_DQS       ,
          inout  wire  [ 3:0]    DDR_DQSn      ,
          output wire  [15:0]    DDR_ADDR      ,
          output wire  [ 2:0]    DDR_BA        ,
          output wire  [ 0:0]    DDR_CKE       ,
          output wire  [ 0:0]    DDR_CSn       ,
          output wire  [ 0:0]    DDR_RASn      ,
          output wire  [ 0:0]    DDR_CASn      ,
          output wire  [ 0:0]    DDR_WEn       ,
          output wire  [ 0:0]    DDR_ODT       ,
          output wire  [ 3:0]    DDR_DM        ,
          output wire  [ 0:0]    DDR_CK_0_P    ,
          output wire  [ 0:0]    DDR_CK_0_N    ,
   
          input  wire            DDR_RZQIN     ,
          output wire  [ 0:0]    DDR_RESETn    ,
//        output wire  [ 3:0]    DDR_NU        , // v0.1 Del
// SSRAM -------------------------------
//        output wire            DPRAM_MRST    , // v0.3 Del
// SSRAM(L) ----------------------------
//        output wire  [20:0]    DPR_AL        , // v0.3 Del
//        inout  wire  [17:0]    DPR_DQL       , // v0.3 Del
//        output wire  [ 1:0]    BEL           , // v0.3 Del
//        input  wire            BUSYL         , // v0.3 Del
//        output wire            CL            , // v0.3 Del
//        output wire  [ 1:0]    CEL           , // v0.3 Del
//        output wire            CQENL         , // v0.3 Del
//        input  wire            CQL0          , // v0.3 Del
//        input  wire            CQL1          , // v0.3 Del
//        output wire            OEL           , // v0.3 Del
//        input  wire            INTL          , // v0.3 Del
//        output wire            LowSPDL       , // v0.3 Del
//        output wire            RWL           , // v0.3 Del
//        input  wire            READYL        , // v0.3 Del
//        output wire            CNT_MCKL      , // v0.3 Del
//        output wire            ADSL          , // v0.3 Del
//        output wire            CNTENL        , // v0.3 Del
//        output wire            CNTRSTL       , // v0.3 Del
//        output wire            WRPL          , // v0.3 Del
//        output wire            RETL          , // v0.3 Del
//        output wire            FTSELL        , // v0.3 Del
//        input  wire            CNT_INTL      , // v0.3 Del
// SSRAM(R) ----------------------------
//        output wire  [20:0]    DPR_AR        , // v0.3 Del
//        inout  wire  [17:0]    DPR_DQR       , // v0.3 Del
//        output wire  [ 1:0]    BER           , // v0.3 Del
//        input  wire            BUSYR         , // v0.3 Del
//        output wire            CR            , // v0.3 Del
//        output wire  [ 1:0]    CER           , // v0.3 Del
//        output wire            CQENR         , // v0.3 Del
//        input  wire            CQR0          , // v0.3 Del
//        input  wire            CQR1          , // v0.3 Del
//        output wire            OER           , // v0.3 Del
//        input  wire            INTR          , // v0.3 Del
//        output wire            LowSPDR       , // v0.3 Del
//        output wire            RWR           , // v0.3 Del
//        input  wire            READYR        , // v0.3 Del
//        output wire            CNT_MCKR      , // v0.3 Del
//        output wire            ADSR          , // v0.3 Del
//        output wire            CNTENR        , // v0.3 Del
//        output wire            CNTRSTR       , // v0.3 Del
//        output wire            WRPR          , // v0.3 Del
//        output wire            RETR          , // v0.3 Del
//        output wire            FTSELR        , // v0.3 Del
//        input  wire            CNT_INTR      , // v0.3 Del
   // Others ------------------------------
   `ifdef P_FPGA1
          input  wire  [ 7:0]    F1_IN_F2_OUT  ,
          output wire  [ 7:0]    F1_OUT_F2_IN  ,
          output wire            F1_ROM_SCL    ,
//        inout  wire            F1_ROM_SDA    , // v0.2 Del
          output wire            F1_ROM_SDA    , // v0.2 Add
          output wire            F1_ROM_ENB    ,
   `else
          output wire  [ 7:0]    F1_IN_F2_OUT  ,
          input  wire  [ 7:0]    F1_OUT_F2_IN  ,
          output wire            F2_ROM_SCL    ,
//        inout  wire            F2_ROM_SDA    , // v0.2 Del
          output wire            F2_ROM_SDA    , // v0.2 Add
          output wire            F2_ROM_ENB    ,
   `endif

          output wire  [ 7:0]    LED           ,
          input  wire  [ 3:0]    HEX_SW        ,
          input  wire            toggl_sw1     ,
          input  wire            toggl_sw3     ,
          output wire            SFP1_TDISABLE ,
          output wire            SFP1_RS0      ,
          output wire            SFP1_RS1      ,
          input  wire            SFP1_TFAULT   ,
          input  wire            SFP1_MODABS   ,
          input  wire            SFP1_RXLOS    ,
          output wire            SFP1_SCL      ,
//        inout  wire            SFP1_SDA      , // v0.2 Del
          output wire            SFP1_SDA      , // v0.2 Add
          output wire            SFP1_I2CENB   ,
          output wire            SFP2_TDISABLE ,
          output wire            SFP2_RS0      ,
          output wire            SFP2_RS1      ,
          input  wire            SFP2_TFAULT   ,
          input  wire            SFP2_MODABS   ,
          input  wire            SFP2_RXLOS    ,
          output wire            SFP2_SCL      ,
//        inout  wire            SFP2_SDA      , // v0.2 Del
          output wire            SFP2_SDA      , // v0.2 Add
          output wire            SFP2_I2CENB   ,
          output wire            SFP3_TDISABLE ,
          output wire            SFP3_RS0      ,
          output wire            SFP3_RS1      ,
          input  wire            SFP3_TFAULT   ,
          input  wire            SFP3_MODABS   ,
          input  wire            SFP3_RXLOS    ,
          output wire            SFP3_SCL      ,
//        inout  wire            SFP3_SDA      , // v0.2 Del
          output wire            SFP3_SDA      , // v0.2 Add
          output wire            SFP3_I2CENB   
  );


//--------------------------------------------------------------------------------------------------
// Parameter
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0


//--------------------------------------------------------------------------------------------------
// Reg & Wire
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0

          wire             n_lpmcnt_cout          ;
          reg              n_lpmcnt_ld_en     =  1'b0       ;
          reg    [ 17:0]   n_lpmcnt_ld_data   = 18'h0_0000  ;
          reg              sm_xreset              ;
//-----------------------------------------------------
          wire             n_refclk_f2f           ;

          wire             n_cm_prom_sop          ;
          wire             n_cm_prom_valid        ;
          wire   [  8:0]   n_cm_prom_cnt          ;
          wire   [ 31:0]   n_cm_prom_data         ;

          wire             n_clk312m              ;
          wire             n_clk156m              ;
          wire             n_arst                 ;

          wire             n_p0_rx_serial_data    ;
          wire             n_p0_tx_serial_data    ;

          wire   [  3:0]   n_cm_hexsw             ;
			wire[3:0]		o_fa_en				;		// v0.6
			wire[6:0]		o_state_fa04		;		// v0.6
			wire[7:0]		o_mode_14			;		// v0.6

//==============================================================================
// signal_top_<=> cm_top間
          wire             n_sdc_sig_start               ;   // 信号処理開始指示パルス
          wire             n_sdc_syncdt_zero             ;   // 開始コードスタート位置('0')の通知信号
          wire             n_sdc_skip_tx                 ;   // レートダウン時の出力契機指示信号(0：出力する 1：出力しない)
          wire             n_sp_ctrl_endp                ;   // 信号処理完了に伴う送信指示パルス

          wire             n_spif_rd_ready               ;   // Avalon-ST 信号処理受信FIFO Ready
          wire             n_spif_rd_sop                 ;   // Avalon-ST DDR3リードデータパケット先頭表示
          wire             n_spif_rd_eop                 ;   // Avalon-ST DDR3リードデータパケット終了表示
          wire             n_spif_rd_valid               ;   // Avalon-ST DDR3リードデータパケット有効表示
          wire   [127:0]   n_spif_rd_data                ;   // Avalon-ST DDR3リードデータ
          wire             n_spif_rd_first               ;   // Avalon-ST DDR3リードデータ先頭表示（転送開始通知）
          wire             n_spif_rd_last                ;   // Avalon-ST DDR3リードデータ最終表示（転送完了通知）

          wire             n_sp_wr_ready                 ;   // Avalon-ST DDR3ライト Ready
          wire             n_sp_wr_sop                   ;   // Avalon-ST DDR3ライトデータパケット先頭表示
          wire             n_sp_wr_eop                   ;   // Avalon-ST DDR3ライトデータパケット終了表示
          wire             n_sp_wr_valid                 ;   // Avalon-ST DDR3ライトデータパケット有効表示
          wire   [127:0]   n_sp_wr_data                  ;   // Avalon-ST DDR3ライトデータ

          wire             n_ppara_param_valid           ;   // 処理パラメーター有効指示
          wire   [  8:0]   n_ppara_param_cnt             ;   // 処理パラメーター位置指示
          wire   [ 31:0]   n_ppara_param_data            ;   // 処理パラメーター

          wire   [  1:0]   n_sp_dbg_led0                 ;   // DBG用LED0制御信号（00:消灯、01/10:点滅、11:点灯）
          wire   [  1:0]   n_sp_dbg_led1                 ;   // DBG用LED1制御信号（00:消灯、01/10:点滅、11:点灯）
          wire   [  1:0]   n_sp_dbg_led2                 ;   // DBG用LED2制御信号（00:消灯、01/10:点滅、11:点灯）
          wire   [  1:0]   n_sp_dbg_led3                 ;   // DBG用LED3制御信号（00:消灯、01/10:点滅、11:点灯）
          wire   [  1:0]   n_sp_dbg_led4                 ;   // DBG用LED4制御信号（00:消灯、01/10:点滅、11:点灯）
          wire   [  1:0]   n_sp_dbg_led5                 ;   // DBG用LED5制御信号（00:消灯、01/10:点滅、11:点灯）
          wire   [  1:0]   n_sp_dbg_led6                 ;   // DBG用LED6制御信号（00:消灯、01/10:点滅、11:点灯）
          wire   [  1:0]   n_sp_dbg_led7                 ;   // DBG用LED7制御信号（00:消灯、01/10:点滅、11:点灯）

`ifdef P_DDR_inst
          wire             n_sp_ddr_wxr                  ;   // DDRリード／ライトアクセス識別信号
          wire   [  3:0]   n_sp_ddr_area                 ;   // DDRアクセス音響データのエリア（面）指定
          wire   [ 26:0]   n_sp_ddr_addr                 ;   // DDRアクセス開始アドレス
          wire   [ 31:0]   n_sp_ddr_size                 ;   // DDRアクセスサイズ（byte）
          wire             n_sp_ddr_start                ;   // DDRアクセス開始指示
          wire             n_spif_ddr_endp               ;   // DDRアクセス完了通知パルス
`else
          wire             n_sdc_header_read_port        ;   // ヘッダをリードするメモリ領域 (0:入力データ0, 1:入力データ1)

          wire             n_spif_rd_psel                ;   // 音響データ入力port表示(0：port0　1：port1)
          wire   [  3:0]   n_sp_wr_psel                  ;   // 音響データ出力port指示(bit0：port0?bit3：port3　同時出力可)

          wire             n_sp_wr_first                 ;   // Avalon-ST 出力音響データ先頭表示（転送開始通知）
          wire             n_sp_wr_last                  ;   // Avalon-ST 出力音響データ最終表示（転送完了通知）

          wire             n_sdc_timeout                 ;   // 音響データタイムアウト信号 v0.4
          wire             n_pt_startp                   ;   // 基板情報ラッチタイミング信号 v0.5

`endif

//==============================================================================
// DDR_MODULE_<=> cm_top間
          wire             n_ddr_ctrl_fifo_write         ;
          wire   [127:0]   n_ddr_ctrl_fifo_write_data    ;
          wire             n_ddr_ctrl_fifo_read          ;
          wire             n_ddr_ctrl_reg_read           ;
          wire             n_ddr_ctrl_reg_write          ;
          wire   [ 31:0]   n_ddr_ctrl_reg_write_data     ;
          wire             n_ddr_ctrl_reg_wa_enable      ;
          wire             n_ddr_ctrl_reg_ra_enable      ;
          wire             n_ddr_ctrl_reg_trans_enable   ;
          wire             n_ddr_ctrl_reg_receive_enable ;
          wire             n_ddr_ctrl_reg_burst_enable   ;
          wire             n_ddr_ctrl_reg_mode_enable    ;
          wire             n_ddr_ctrl_reg_rw_enable      ;
          wire             n_ddr_ctrl_reg_fw_enable      ;
          wire             n_ddr_ctrl_reg_fr_enable      ;

          wire   [127:0]   n_ddr_mod_fifo_read_data      ;
          wire   [ 31:0]   n_ddr_mod_reg_read_data       ;
          wire   [  6:0]   n_ddr_mod_status              ;
          wire   [ 12:0]   n_ddr_mod_fifo_w_status       ;
          wire   [ 12:0]   n_ddr_mod_fifo_r_status       ;

          wire             n_cal_success                 ;
          wire             n_cal_fail                    ;

//==============================================================================
// DDR_MODULE_<=> DDR3 (emif) IP間
          wire             ddr_user_clk                  ;
          wire             ddr_user_rst_n                ;
          wire             ddr_ready                     ;
          wire             ddr_read                      ;
          wire             ddr_write                     ;
          wire   [ 26:0]   ddr_address                   ;
          wire   [127:0]   ddr_readdata                  ;
          wire   [127:0]   ddr_writedata                 ;
          wire   [  6:0]   ddr_burstcount                ;
          wire   [ 15:0]   ddr_byteenable                ;
          wire             ddr_valid                     ;

//--------------------------------------------------------------------------------------------------
// Main
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0

//-----------------------------------------------------------------------
// FPGA1 or 2 の端子差分吸収
//-----------------------------------------------------------------------
`ifdef P_FPGA1
       assign n_refclk_f2f        = ( P_refclk_f2f_sel == 1'b0 ) ? F1_GXB_CLK : SFP_CLK ;
       assign n_p0_rx_serial_data = F2_TX_F1_RX1        ;
       assign F1_TX_F2_RX1        = n_p0_tx_serial_data ;

`else
       assign n_refclk_f2f        = ( P_refclk_f2f_sel == 1'b0 ) ? F2_GXB_CLK : SFP_CLK ;
       assign n_p0_rx_serial_data = F1_TX_F2_RX1        ;
       assign F2_TX_F1_RX1        = n_p0_tx_serial_data ;
`endif


//-----------------------------------------------------------------------
// 外部リセット代替回路追加 (リセット時間：1.6ms = 6.4ns*2^18-1 )
//-----------------------------------------------------------------------
cm_lpm_counter_18bit cm_lpm_counter_18bit_inst
  (
    .clock   ( SFP_CLK           ) , //  counter_input.clock
    .clk_en  ( ~n_lpmcnt_cout    ) , //               .clk_en
    .cnt_en  ( ~n_lpmcnt_cout    ) , //               .cnt_en
    .sload   ( n_lpmcnt_ld_en    ) , //               .sload
    .aclr    ( ~RESET            ) , //               .aclr
    .data    ( n_lpmcnt_ld_data  ) , //               .data
    .q       ( /* open */        ) , // counter_output.q
    .cout    ( n_lpmcnt_cout     )   //               .cout
   );

always@ (negedge RESET or posedge SFP_CLK )
  begin
    if ( RESET == 1'b0 ) begin
         sm_xreset  <= 1'b0 ;
    end
    else begin
         sm_xreset  <= n_lpmcnt_cout ;
    end
  end

//-----------------------------------------------------------------------
// Parameter ROM Common
//-----------------------------------------------------------------------
cm_param_rom cm_param_rom_inst							//v0.6
    (
     .i_arst                 ( n_arst                 ) , // asyncronous reset
     .i_clk156m              ( n_clk156m              ) , // clock (156.25MHz)
//     .i_fa_en				(o_fa_en				)	, // 切替信号を追加　v0.6

     .o_param_sop            ( n_cm_prom_sop          ) , // SOP
     .o_param_valid          ( n_cm_prom_valid        ) , // Valid
     .o_param_cnt            ( n_cm_prom_cnt          ) , // Count Value
     .o_param_data           ( n_cm_prom_data         )   // Data
     );


//-----------------------------------------------------------------------
// Common
//-----------------------------------------------------------------------
`ifdef P_DDR_inst
    cm_top_ddr
       #(
         .P_cm_rstgen_sel               ( P_cm_rstgen_sel                ) , // リセット生成回路選択

         .P_cm_tim_100us_decval         ( P_cm_tim_100us_decval          ) , // 100us 周期パルスのデコード値 (156.25MHzカウント値)

         .P_cm_1g_dmy_inst              ( P_cm_1g_dmy_inst               ) , // インプリトライアル用1Gbps SerDes Dumy回路実装指示  1=Dumy回路 0=通常回路
         .P_cm_p0_inst                  ( P_cm_p0_inst                   ) , // カード内FPGA間 種別  0=未実装  1=1G UDP
         .P_cm_p1_inst                  ( P_cm_p1_inst                   ) , // SFP#1          種別  0=未実装  1=1G UDP  2=10G UDP  3=XGMII
         .P_cm_p2_inst                  ( P_cm_p2_inst                   ) , // SFP#2          種別  0=未実装  1=1G UDP  2=10G UDP  3=XGMII
         .P_cm_p3_inst                  ( P_cm_p3_inst                   ) , // SFP#3          種別  0=未実装  1=1G UDP  2=10G UDP  3=XGMII

         .P_SEQ_START_TYPE              ( P_SEQ_START_TYPE               ) , // シーケンサ起動タイプ (ONE_PORT/TWO_PORT/RATEDOWN)
         .P_ODTRD_TYPE                  ( P_ODTRD_TYPE                   )   // 出力データリード制御タイプ (ONE_PORT/TWO_PORT/NONE)
         )
      cm_top_inst
        (
         .i_arst                        ( ~sm_xreset                     ) , // asyncronous reset
         .i_refclk_sfp                  ( SFP_CLK                        ) , // Reference Clock (156.25MHz)
         .i_refclk_f2f                  ( n_refclk_f2f                   ) , // Reference Clock (156.25MHz)
         .o_pll156m_lock                ( /* open */                     ) , // PLL Lock
         .o_clk312m                     ( n_clk312m                      ) , // clock (312.50MHz)
         .o_clk156m                     ( n_clk156m                      ) , // clock (156.25MHz)
         .o_arst                        ( n_arst                         ) , // asyncronous reset

        //-------------------------------------------------------------------------------------------
         .i_p0_rx_serial_data           ( n_p0_rx_serial_data            ) , // 受信シリアルデータ (カード内FPGA間)
         .o_p0_tx_serial_data           ( n_p0_tx_serial_data            ) , // 送信シリアルデータ (カード内FPGA間)
         .i_p1_rx_serial_data           ( SFP1_RX                        ) , // 受信シリアルデータ (SFP#1)
         .o_p1_tx_serial_data           ( SFP1_TX                        ) , // 送信シリアルデータ (SFP#1)
         .i_p2_rx_serial_data           ( SFP2_RX                        ) , // 受信シリアルデータ (SFP#2)
         .o_p2_tx_serial_data           ( SFP2_TX                        ) , // 送信シリアルデータ (SFP#2)
         .i_p3_rx_serial_data           ( SFP3_RX                        ) , // 受信シリアルデータ (SFP#3)
         .o_p3_tx_serial_data           ( SFP3_TX                        ) , // 送信シリアルデータ (SFP#3)

        // Common Parameter ROM ---------------------------------------------------------------------
         .i_param_sop                   ( n_cm_prom_sop                  ) , // Parameter ROMリード先頭表示
         .i_param_valid                 ( n_cm_prom_valid                ) , // Parameter ROMリード有効表示
         .i_param_cnt                   ( n_cm_prom_cnt                  ) , // Parameter ROMリードウンタ
         .i_param_data                  ( n_cm_prom_data                 ) , // Parameter ROMリードデータ

        // DDR3端子 ---------------------------------------------------------------------------------
         .o_ddr_ctrl_fifo_write         ( n_ddr_ctrl_fifo_write          ),
         .o_ddr_ctrl_fifo_write_data    ( n_ddr_ctrl_fifo_write_data     ),
         .o_ddr_ctrl_fifo_read          ( n_ddr_ctrl_fifo_read           ),
         .o_ddr_ctrl_reg_read           ( n_ddr_ctrl_reg_read            ),
         .o_ddr_ctrl_reg_write          ( n_ddr_ctrl_reg_write           ),
         .o_ddr_ctrl_reg_write_data     ( n_ddr_ctrl_reg_write_data      ),
         .o_ddr_ctrl_reg_wa_enable      ( n_ddr_ctrl_reg_wa_enable       ),
         .o_ddr_ctrl_reg_ra_enable      ( n_ddr_ctrl_reg_ra_enable       ),
         .o_ddr_ctrl_reg_trans_enable   ( n_ddr_ctrl_reg_trans_enable    ),
         .o_ddr_ctrl_reg_receive_enable ( n_ddr_ctrl_reg_receive_enable  ),
         .o_ddr_ctrl_reg_burst_enable   ( n_ddr_ctrl_reg_burst_enable    ),
         .o_ddr_ctrl_reg_mode_enable    ( n_ddr_ctrl_reg_mode_enable     ),
         .o_ddr_ctrl_reg_rw_enable      ( n_ddr_ctrl_reg_rw_enable       ),
         .o_ddr_ctrl_reg_fw_enable      ( n_ddr_ctrl_reg_fw_enable       ),
         .o_ddr_ctrl_reg_fr_enable      ( n_ddr_ctrl_reg_fr_enable       ),

         .i_ddr_mod_fifo_read_data      ( n_ddr_mod_fifo_read_data       ),
         .i_ddr_mod_reg_read_data       ( n_ddr_mod_reg_read_data        ),
         .i_ddr_mod_status              ( n_ddr_mod_status               ),
         .i_ddr_mod_fifo_w_status       ( n_ddr_mod_fifo_w_status        ),
         .i_ddr_mod_fifo_r_status       ( n_ddr_mod_fifo_r_status        ),

        .i_cal_fail                     ( n_cal_fail                     ),

        // 光モジュール端子 -------------------------------------------------------------------------
         .SFP1_TFAULT                   ( SFP1_TFAULT                    ) ,
         .SFP1_MODABS                   ( SFP1_MODABS                    ) ,
         .SFP1_RXLOS                    ( SFP1_RXLOS                     ) ,
         .SFP2_TFAULT                   ( SFP2_TFAULT                    ) ,
         .SFP2_MODABS                   ( SFP2_MODABS                    ) ,
         .SFP2_RXLOS                    ( SFP2_RXLOS                     ) ,
         .SFP3_TFAULT                   ( SFP3_TFAULT                    ) ,
         .SFP3_MODABS                   ( SFP3_MODABS                    ) ,
         .SFP3_RXLOS                    ( SFP3_RXLOS                     ) ,

        // 信号処理部端子 ---------------------------------------------------------------------------
//         .i_signal_proc                 (   1'b1                         ) , // input  wire           // signal process 未使用に変更 20190227 
         .i_signal_state0               ( n_sp_dbg_led0                  ) , // input  wire [  1:0]   // signal state 0
         .i_signal_state1               ( n_sp_dbg_led1                  ) , // input  wire [  1:0]   // signal state 1
         .i_signal_state2               ( n_sp_dbg_led2                  ) , // input  wire [  1:0]   // signal state 2
         .i_signal_state3               ( n_sp_dbg_led3                  ) , // input  wire [  1:0]   // signal state 3
         .i_signal_state4               ( n_sp_dbg_led4                  ) , // input  wire [  1:0]   // signal state 4
         .i_signal_state5               ( n_sp_dbg_led5                  ) , // input  wire [  1:0]   // signal state 5
         .i_signal_state6               ( n_sp_dbg_led6                  ) , // input  wire [  1:0]   // signal state 6
         .i_signal_state7               ( n_sp_dbg_led7                  ) , // input  wire [  1:0]   // signal state 7

         .o_ppara_param_sop             ( /* open */                     ) , // output wire           // 処理パラメータシリアルデータ先頭
         .o_ppara_param_valid           ( n_ppara_param_valid            ) , // output wire           // 処理パラメータシリアルデータ有効
         .o_ppara_param_cnt             ( n_ppara_param_cnt              ) , // output wire [  8:0]   // 処理パラメータシリアルカウンタ(0-511)
         .o_ppara_param_data            ( n_ppara_param_data             ) , // output wire [ 31:0]   // 処理パラメータシリアルデータ(512W)

         .o_sig_start                   ( n_sdc_sig_start                ) , // output wire           // 信号処理開始指示
         .i_sig_done                    ( n_sp_ctrl_endp                 ) , // input  wire           // 信号処理完了通知
         .o_skip_tx                     ( n_sdc_skip_tx                  ) , // output wire           // 送信スキップ (0:スキップしない, 1:スキップする)
         .o_syncdt_zero                 ( n_sdc_syncdt_zero              ) , // output wire           // 同期データゼロ出力
         .o_header_read_port            ( /* open */                     ) , // output wire           // ヘッダをリードするメモリ領域 (0:入力データ0, 1:入力データ1)

         .i_ddr_wxr                     ( n_sp_ddr_wxr                   ) , // input  wire           // 信号処理部 Read(=0),Write(=1)識別
         .i_ddr_area                    ( n_sp_ddr_area                  ) , // input  wire  [  3:0]  // 信号処理部 DDRアクセス 音響データのエリア(面)指定
         .i_ddr_addr                    ( n_sp_ddr_addr                  ) , // input  wire  [ 26:0]  // 信号処理部 DDRアクセス 開始アドレス
         .i_ddr_size                    ( n_sp_ddr_size                  ) , // input  wire  [ 31:0]  // 信号処理部 DDRアクセス サイズ(byte)
         .i_ddr_start                   ( n_sp_ddr_start                 ) , // input  wire           // 信号処理部 DDRアクセス 開始指示
         .o_ddr_endp                    ( n_spif_ddr_endp                ) , // output wire           // 信号処理部 DDRアクセス 完了通知パルス

         .o_wr_ready                    ( n_sp_wr_ready                  ) , // output wire           // 信号処理部 DDR3ライトデータパケットReady
         .i_wr_sop                      ( n_sp_wr_sop                    ) , // input  wire           // 信号処理部 DDR3ライトデータパケット先頭表示
         .i_wr_eop                      ( n_sp_wr_eop                    ) , // input  wire           // 信号処理部 DDR3ライトデータパケット終了表示
         .i_wr_valid                    ( n_sp_wr_valid                  ) , // input  wire           // 信号処理部 DDR3ライトデータパケット有効表示
         .i_wr_data                     ( n_sp_wr_data                   ) , // input  wire  [127:0]  // 信号処理部 DDR3ライトデータ

         .i_rd_ready                    ( n_spif_rd_ready                ) , // input  wire           // 信号処理部 信号処理受信FIFO Ready
         .o_rd_sop                      ( n_spif_rd_sop                  ) , // output wire           // 信号処理部 DDR3リードデータパケット先頭表示
         .o_rd_eop                      ( n_spif_rd_eop                  ) , // output wire           // 信号処理部 DDR3リードデータパケット終了表示
         .o_rd_valid                    ( n_spif_rd_valid                ) , // output wire           // 信号処理部 DDR3リードデータパケット有効表示
         .o_rd_data                     ( n_spif_rd_data                 ) , // output wire  [127:0]  // 信号処理部 DDR3リードデータ
         .o_rd_first                    ( n_spif_rd_first                ) , // output wire           // 信号処理部 DDR3リードデータ開始表示(転送開始通知)
         .o_rd_last                     ( n_spif_rd_last                 ) , // output wire           // 信号処理部 DDR3リードデータ最終表示(転送完了通知)

        // Rotary SW --------------------------------------------------------------------------------
         .HEX_SW                        ( HEX_SW                         ) ,
         .o_hexsw                       ( n_cm_hexsw                     ) ,

        // LED --------------------------------------------------------------------------------------
         .o_led                         ( LED                            ) ,
		 .i_state_fa04					(o_state_fa04)						, 							//Add signal v0.6
		 .i_mode_14						(o_mode_14)														//Add signal v0.6
        );

    //-----------------------------------------------------------------------------------------------
    signal_top_ddr  signal_top_inst
        (
         .i_clk156m                     ( n_clk156m                      )  ,   // system clock
         .i_arst                        ( n_arst                         )  ,   // asyncronous reset
         .i_ctrl_startp                 ( n_sdc_sig_start                )  ,   // 信号処理開始指示パルス
         .i_sync_on                     ( n_sdc_syncdt_zero              )  ,   // 開始コードスタート位置('0')の通知信号
         .i_skip_tx                     ( n_sdc_skip_tx                  )  ,   // レートダウン時の出力契機指示信号(0：出力する 1：出力しない)
         .i_ddr_endp                    ( n_spif_ddr_endp                )  ,   // DDRアクセス完了通知パルス
         .i_rd_sop                      ( n_spif_rd_sop                  )  ,   // Avalon-ST DDR3リードデータパケット先頭表示
         .i_rd_eop                      ( n_spif_rd_eop                  )  ,   // Avalon-ST DDR3リードデータパケット終了表示
         .i_rd_valid                    ( n_spif_rd_valid                )  ,   // Avalon-ST DDR3リードデータパケット有効表示
         .i_rd_data                     ( n_spif_rd_data                 )  ,   // Avalon-ST DDR3リードデータ
         .i_rd_first                    ( n_spif_rd_first                )  ,   // Avalon-ST DDR3リードデータ先頭表示（転送開始通知）
         .i_rd_last                     ( n_spif_rd_last                 )  ,   // Avalon-ST DDR3リードデータ最終表示（転送完了通知）
         .i_wr_ready                    ( n_sp_wr_ready                  )  ,   // Avalon-ST DDR3ライト Ready
         .i_led_mode                    ( n_cm_hexsw                     )  ,   // LEDモード設定
         .i_param_valid                 ( n_ppara_param_valid            )  ,   // 処理パラメーター有効指示
         .i_param_cnt                   ( n_ppara_param_cnt              )  ,   // 処理パラメーター位置指示
         .i_param_data                  ( n_ppara_param_data             )  ,   // 処理パラメーター

         .o_ctrl_endp                   ( n_sp_ctrl_endp                 )  ,   // 信号処理完了に伴う送信指示パルス
         .o_ddr_wxr                     ( n_sp_ddr_wxr                   )  ,   // DDRリード／ライトアクセス識別信号
         .o_ddr_area                    ( n_sp_ddr_area                  )  ,   // DDRアクセス音響データのエリア（面）指定
         .o_ddr_addr                    ( n_sp_ddr_addr                  )  ,   // DDRアクセス開始アドレス
         .o_ddr_size                    ( n_sp_ddr_size                  )  ,   // DDRアクセスサイズ（byte）
         .o_ddr_start                   ( n_sp_ddr_start                 )  ,   // DDRアクセス開始指示
         .o_rd_ready                    ( n_spif_rd_ready                )  ,   // Avalon-ST 信号処理受信FIFO Ready
         .o_wr_sop                      ( n_sp_wr_sop                    )  ,   // Avalon-ST DDR3ライトデータパケット先頭表示
         .o_wr_eop                      ( n_sp_wr_eop                    )  ,   // Avalon-ST DDR3ライトデータパケット終了表示
         .o_wr_valid                    ( n_sp_wr_valid                  )  ,   // Avalon-ST DDR3ライトデータパケット有効表示
         .o_wr_data                     ( n_sp_wr_data                   )  ,   // Avalon-ST DDR3ライトデータ
         .o_wr_first                    ( /* open */                     )  ,   // Avalon-ST DDR3ライトデータ先頭表示（転送開始通知）
         .o_wr_last                     ( /* open */                     )  ,   // Avalon-ST DDR3ライトデータ最終表示（転送完了通知）
	 	 .o_fa_en			(o_fa_en			)   ,	// 切替信号を追加　v0.6
		 .o_state_fa04					(o_state_fa04					)	,	// add DBG signal v0.6
		 .o_mode_14						(o_mode_14						)	,	// add DBG signal v0.6
         .o_dbg_led0                    ( n_sp_dbg_led0                  )  ,   // DBG用LED0制御信号（00:消灯、01/10:点滅、11:点灯）
         .o_dbg_led1                    ( n_sp_dbg_led1                  )  ,   // DBG用LED1制御信号（00:消灯、01/10:点滅、11:点灯）
         .o_dbg_led2                    ( n_sp_dbg_led2                  )  ,   // DBG用LED2制御信号（00:消灯、01/10:点滅、11:点灯）
         .o_dbg_led3                    ( n_sp_dbg_led3                  )  ,   // DBG用LED3制御信号（00:消灯、01/10:点滅、11:点灯）
         .o_dbg_led4                    ( n_sp_dbg_led4                  )  ,   // DBG用LED4制御信号（00:消灯、01/10:点滅、11:点灯）
         .o_dbg_led5                    ( n_sp_dbg_led5                  )  ,   // DBG用LED5制御信号（00:消灯、01/10:点滅、11:点灯）
         .o_dbg_led6                    ( n_sp_dbg_led6                  )  ,   // DBG用LED6制御信号（00:消灯、01/10:点滅、11:点灯）
         .o_dbg_led7                    ( n_sp_dbg_led7                  )      // DBG用LED7制御信号（00:消灯、01/10:点滅、11:点灯）
        );

`else

    cm_top_bram
       #(
         .P_cm_rstgen_sel               ( P_cm_rstgen_sel                ) , // リセット生成回路選択

         .P_cm_tim_100us_decval         ( P_cm_tim_100us_decval          ) , // 100us 周期パルスのデコード値 (156.25MHzカウント値)

         .P_cm_1g_dmy_inst              ( P_cm_1g_dmy_inst               ) , // インプリトライアル用1Gbps SerDes Dumy回路実装指示  1=Dumy回路 0=通常回路
         .P_cm_p0_inst                  ( P_cm_p0_inst                   ) , // カード内FPGA間 種別  0=未実装  1=1G UDP
         .P_cm_p1_inst                  ( P_cm_p1_inst                   ) , // SFP#1          種別  0=未実装  1=1G UDP  2=10G UDP  3=XGMII
         .P_cm_p2_inst                  ( P_cm_p2_inst                   ) , // SFP#2          種別  0=未実装  1=1G UDP  2=10G UDP  3=XGMII
         .P_cm_p3_inst                  ( P_cm_p3_inst                   ) , // SFP#3          種別  0=未実装  1=1G UDP  2=10G UDP  3=XGMII

         .P_SEQ_START_TYPE              ( P_SEQ_START_TYPE               ) , // シーケンサ起動タイプ (ONE_PORT/TWO_PORT/RATEDOWN)
         .P_ODTRD_TYPE                  ( P_ODTRD_TYPE                   )   // 出力データリード制御タイプ (ONE_PORT/TWO_PORT/NONE)
         )
      cm_top_inst
        (
         .i_arst                        ( ~sm_xreset                     ) , // asyncronous reset
         .i_refclk_sfp                  ( SFP_CLK                        ) , // Reference Clock (156.25MHz)
         .i_refclk_f2f                  ( n_refclk_f2f                   ) , // Reference Clock (156.25MHz)
         .o_pll156m_lock                ( /* open */                     ) , // PLL Lock
         .o_clk312m                     ( n_clk312m                      ) , // clock (312.50MHz)
         .o_clk156m                     ( n_clk156m                      ) , // clock (156.25MHz)
         .o_arst                        ( n_arst                         ) , // asyncronous reset

        //-------------------------------------------------------------------------------------------
         .i_p0_rx_serial_data           ( n_p0_rx_serial_data            ) , // 受信シリアルデータ (カード内FPGA間)
         .o_p0_tx_serial_data           ( n_p0_tx_serial_data            ) , // 送信シリアルデータ (カード内FPGA間)
         .i_p1_rx_serial_data           ( SFP1_RX                        ) , // 受信シリアルデータ (SFP#1)
         .o_p1_tx_serial_data           ( SFP1_TX                        ) , // 送信シリアルデータ (SFP#1)
         .i_p2_rx_serial_data           ( SFP2_RX                        ) , // 受信シリアルデータ (SFP#2)
         .o_p2_tx_serial_data           ( SFP2_TX                        ) , // 送信シリアルデータ (SFP#2)
         .i_p3_rx_serial_data           ( SFP3_RX                        ) , // 受信シリアルデータ (SFP#3)
         .o_p3_tx_serial_data           ( SFP3_TX                        ) , // 送信シリアルデータ (SFP#3)

        // Common Parameter ROM ---------------------------------------------------------------------
         .i_param_sop                   ( n_cm_prom_sop                  ) , // Parameter ROMリード先頭表示
         .i_param_valid                 ( n_cm_prom_valid                ) , // Parameter ROMリード有効表示
         .i_param_cnt                   ( n_cm_prom_cnt                  ) , // Parameter ROMリードウンタ
         .i_param_data                  ( n_cm_prom_data                 ) , // Parameter ROMリードデータ

        // DDR3端子 ---------------------------------------------------------------------------------
         .o_ddr_ctrl_fifo_write         ( n_ddr_ctrl_fifo_write          ),
         .o_ddr_ctrl_fifo_write_data    ( n_ddr_ctrl_fifo_write_data     ),
         .o_ddr_ctrl_fifo_read          ( n_ddr_ctrl_fifo_read           ),
         .o_ddr_ctrl_reg_read           ( n_ddr_ctrl_reg_read            ),
         .o_ddr_ctrl_reg_write          ( n_ddr_ctrl_reg_write           ),
         .o_ddr_ctrl_reg_write_data     ( n_ddr_ctrl_reg_write_data      ),
         .o_ddr_ctrl_reg_wa_enable      ( n_ddr_ctrl_reg_wa_enable       ),
         .o_ddr_ctrl_reg_ra_enable      ( n_ddr_ctrl_reg_ra_enable       ),
         .o_ddr_ctrl_reg_trans_enable   ( n_ddr_ctrl_reg_trans_enable    ),
         .o_ddr_ctrl_reg_receive_enable ( n_ddr_ctrl_reg_receive_enable  ),
         .o_ddr_ctrl_reg_burst_enable   ( n_ddr_ctrl_reg_burst_enable    ),
         .o_ddr_ctrl_reg_mode_enable    ( n_ddr_ctrl_reg_mode_enable     ),
         .o_ddr_ctrl_reg_rw_enable      ( n_ddr_ctrl_reg_rw_enable       ),
         .o_ddr_ctrl_reg_fw_enable      ( n_ddr_ctrl_reg_fw_enable       ),
         .o_ddr_ctrl_reg_fr_enable      ( n_ddr_ctrl_reg_fr_enable       ),

         .i_ddr_mod_fifo_read_data      ( n_ddr_mod_fifo_read_data       ),
         .i_ddr_mod_reg_read_data       ( n_ddr_mod_reg_read_data        ),
         .i_ddr_mod_status              ( n_ddr_mod_status               ),
         .i_ddr_mod_fifo_w_status       ( n_ddr_mod_fifo_w_status        ),
         .i_ddr_mod_fifo_r_status       ( n_ddr_mod_fifo_r_status        ),

        .i_cal_fail                     ( n_cal_fail                     ),

        // 光モジュール端子 -------------------------------------------------------------------------
         .SFP1_TFAULT                   ( SFP1_TFAULT                    ) ,
         .SFP1_MODABS                   ( SFP1_MODABS                    ) ,
         .SFP1_RXLOS                    ( SFP1_RXLOS                     ) ,
         .SFP2_TFAULT                   ( SFP2_TFAULT                    ) ,
         .SFP2_MODABS                   ( SFP2_MODABS                    ) ,
         .SFP2_RXLOS                    ( SFP2_RXLOS                     ) ,
         .SFP3_TFAULT                   ( SFP3_TFAULT                    ) ,
         .SFP3_MODABS                   ( SFP3_MODABS                    ) ,
         .SFP3_RXLOS                    ( SFP3_RXLOS                     ) ,

        // 信号処理部端子 ---------------------------------------------------------------------------
//         .i_signal_proc                 (   1'b1                         ) , // input  wire           // signal process 未使用に変更 20190227
         .i_signal_state0               ( n_sp_dbg_led0                  ) , // input  wire [  1:0]   // signal state 0
         .i_signal_state1               ( n_sp_dbg_led1                  ) , // input  wire [  1:0]   // signal state 1
         .i_signal_state2               ( n_sp_dbg_led2                  ) , // input  wire [  1:0]   // signal state 2
         .i_signal_state3               ( n_sp_dbg_led3                  ) , // input  wire [  1:0]   // signal state 3
         .i_signal_state4               ( n_sp_dbg_led4                  ) , // input  wire [  1:0]   // signal state 4
         .i_signal_state5               ( n_sp_dbg_led5                  ) , // input  wire [  1:0]   // signal state 5
         .i_signal_state6               ( n_sp_dbg_led6                  ) , // input  wire [  1:0]   // signal state 6
         .i_signal_state7               ( n_sp_dbg_led7                  ) , // input  wire [  1:0]   // signal state 7

         .o_ppara_param_sop             ( /* open */                     ) , // output wire           // 処理パラメータシリアルデータ先頭
         .o_ppara_param_valid           ( n_ppara_param_valid            ) , // output wire           // 処理パラメータシリアルデータ有効
         .o_ppara_param_cnt             ( n_ppara_param_cnt              ) , // output wire [  8:0]   // 処理パラメータシリアルカウンタ(0-511)
         .o_ppara_param_data            ( n_ppara_param_data             ) , // output wire [ 31:0]   // 処理パラメータシリアルデータ(512W)

         .o_sig_start                   ( n_sdc_sig_start                ) , // output wire           // 信号処理開始指示
         .i_sig_done                    ( n_sp_ctrl_endp                 ) , // input  wire           // 信号処理完了通知
         .o_skip_tx                     ( n_sdc_skip_tx                  ) , // output wire           // 送信スキップ (0:スキップしない, 1:スキップする)
         .o_syncdt_zero                 ( n_sdc_syncdt_zero              ) , // output wire           // 同期データゼロ出力
         .o_header_read_port            ( n_sdc_header_read_port         ) , // output wire           // ヘッダをリードするメモリ領域 (0:入力データ0, 1:入力データ1)
         .o_sdc_timeout                 ( n_sdc_timeout                  ) , // output wire           // タイムアウト信号 v0.4
         .i_pt_startp                   ( n_pt_startp                    ) , // output wire           // 基板情報ラッチタイミング信号 v0.5

         .o_wr_ready                    ( n_sp_wr_ready                  ) , // output wire           // 信号処理部出力 データReady
         .i_wr_sop                      ( n_sp_wr_sop                    ) , // input  wire           // 信号処理部出力 データパケット先頭表示
         .i_wr_eop                      ( n_sp_wr_eop                    ) , // input  wire           // 信号処理部出力 データパケット終了表示
         .i_wr_valid                    ( n_sp_wr_valid                  ) , // input  wire           // 信号処理部出力 データパケット有効表示
         .i_wr_data                     ( n_sp_wr_data                   ) , // input  wire [127:0]   // 信号処理部出力 データ
         .i_wr_first                    ( n_sp_wr_first                  ) , // input  wire           // 信号処理部出力 データ開始表示(転送開始通知)
         .i_wr_last                     ( n_sp_wr_last                   ) , // input  wire           // 信号処理部出力 データ最終表示(転送完了通知)
         .i_wr_psel                     ( n_sp_wr_psel                   ) , // input  wire [  3:0]   // 信号処理部出力 データ入力ポート識別

         .i_rd_ready                    ( n_spif_rd_ready                ) , // input  wire           // 信号処理部入力 データReady
         .o_rd_sop                      ( n_spif_rd_sop                  ) , // output wire           // 信号処理部入力 データパケット先頭表示
         .o_rd_eop                      ( n_spif_rd_eop                  ) , // output wire           // 信号処理部入力 データパケット終了表示
         .o_rd_valid                    ( n_spif_rd_valid                ) , // output wire           // 信号処理部入力 データパケット有効表示
         .o_rd_data                     ( n_spif_rd_data                 ) , // output wire [127:0]   // 信号処理部入力 データ
         .o_rd_first                    ( n_spif_rd_first                ) , // output wire           // 信号処理部入力 データ開始表示(転送開始通知)
         .o_rd_last                     ( n_spif_rd_last                 ) , // output wire           // 信号処理部入力 データ最終表示(転送完了通知)
         .o_rd_psel                     ( n_spif_rd_psel                 ) , // output wire           // 信号処理部入力 データ入力ポート識別

        // Rotary SW --------------------------------------------------------------------------------
         .HEX_SW                        ( HEX_SW                         ) ,
         .o_hexsw                       ( n_cm_hexsw                     ) ,

        // LED --------------------------------------------------------------------------------------
         .o_led                         ( LED                            )  ,
		 .i_state_fa04					(o_state_fa04) 				//v0.6
        );

    //-----------------------------------------------------------------------------------------------
    signal_top_im  signal_top_inst
        (
         .i_clk156m                     ( n_clk156m                      )  ,   // system clock
         .i_arst                        ( n_arst                         )  ,   // asyncronous reset
         .i_ctrl_startp                 ( n_sdc_sig_start                )  ,   // 信号処理開始指示パルス
         .o_ctrl_endp                   ( n_sp_ctrl_endp                 )  ,   // 信号処理完了に伴う送信指示パルス
         .i_header_read_port            ( n_sdc_header_read_port         )  ,   // 音響フレームヘッダ読み出し領域(0=入力データ Port0、1=入力データ Port1)
         .i_sdc_timeout                 ( n_sdc_timeout                  )  ,   // 音響データタイムアウト信号 v0.4
         .o_pt_startp                   ( n_pt_startp                    )  ,   // 基板情報ラッチタイミング信号 v0.5
         .i_sync_on                     ( n_sdc_syncdt_zero              )  ,   // 開始コードスタート位置('0')の通知信号
         .i_skip_tx                     ( n_sdc_skip_tx                  )  ,   // レートダウン時の出力契機指示信号(0：出力する 1：出力しない)
         .i_rd_sop                      ( n_spif_rd_sop                  )  ,   // Avalon-ST 入力音響データパケット先頭表示
         .i_rd_eop                      ( n_spif_rd_eop                  )  ,   // Avalon-ST 入力音響データパケット終了表示
         .i_rd_valid                    ( n_spif_rd_valid                )  ,   // Avalon-ST 入力音響データパケット有効表示
         .i_rd_data                     ( n_spif_rd_data                 )  ,   // Avalon-ST 入力音響データ
         .i_rd_first                    ( n_spif_rd_first                )  ,   // Avalon-ST 入力音響データ先頭表示（転送開始通知）
         .i_rd_last                     ( n_spif_rd_last                 )  ,   // Avalon-ST 入力音響データ最終表示（転送完了通知）
         .i_rd_psel                     ( n_spif_rd_psel                 )  ,   // 音響データ入力port表示(0：port0　1：port1)
         .o_rd_ready                    ( n_spif_rd_ready                )  ,   // Avalon-ST 信号処理受信FIFO Ready
         .o_wr_sop                      ( n_sp_wr_sop                    )  ,   // Avalon-ST 出力音響データパケット先頭表示
         .o_wr_eop                      ( n_sp_wr_eop                    )  ,   // Avalon-ST 出力音響データパケット終了表示
         .o_wr_valid                    ( n_sp_wr_valid                  )  ,   // Avalon-ST 出力音響データパケット有効表示
         .o_wr_data                     ( n_sp_wr_data                   )  ,   // Avalon-ST 出力音響データ
         .o_wr_first                    ( n_sp_wr_first                  )  ,   // Avalon-ST 出力音響データ先頭表示（転送開始通知）
         .o_wr_last                     ( n_sp_wr_last                   )  ,   // Avalon-ST 出力音響データ最終表示（転送完了通知）
         .i_wr_ready                    ( n_sp_wr_ready                  )  ,   // Avalon-ST 出力音響 Ready
         .o_wr_psel                     ( n_sp_wr_psel                   )  ,   // 音響データ出力port指示(bit0：port0?bit3：port3　同時出力可)
         .o_dbg_led0                    ( n_sp_dbg_led0                  )  ,   // DBG用LED0制御信号（00:消灯、01/10:点滅、11:点灯）
         .o_dbg_led1                    ( n_sp_dbg_led1                  )  ,   // DBG用LED1制御信号（00:消灯、01/10:点滅、11:点灯）
         .o_dbg_led2                    ( n_sp_dbg_led2                  )  ,   // DBG用LED2制御信号（00:消灯、01/10:点滅、11:点灯）
         .o_dbg_led3                    ( n_sp_dbg_led3                  )  ,   // DBG用LED3制御信号（00:消灯、01/10:点滅、11:点灯）
         .o_dbg_led4                    ( n_sp_dbg_led4                  )  ,   // DBG用LED4制御信号（00:消灯、01/10:点滅、11:点灯）
         .o_dbg_led5                    ( n_sp_dbg_led5                  )  ,   // DBG用LED5制御信号（00:消灯、01/10:点滅、11:点灯）
         .o_dbg_led6                    ( n_sp_dbg_led6                  )  ,   // DBG用LED6制御信号（00:消灯、01/10:点滅、11:点灯）
         .o_dbg_led7                    ( n_sp_dbg_led7                  )  ,   // DBG用LED7制御信号（00:消灯、01/10:点滅、11:点灯）
         .i_led_mode                    ( n_cm_hexsw                     )  ,   // LEDモード設定
         .i_param_valid                 ( n_ppara_param_valid            )  ,   // 処理パラメーター有効指示
         .i_param_cnt                   ( n_ppara_param_cnt              )  ,   // 処理パラメーター位置指示
         .i_param_data                  ( n_ppara_param_data             )  //0415kari ,   // 処理パラメーター
//0415kari         .o_header_face_num             (                                )      // ヘッダ付与面指示(0?3面前)  ◆◆◆ 保留 20190215
        );

`endif



//----------------------------------------------------
// SFP 関連端子

//DISABLE  1 : Disable
//RS0   0 : 1.25Gb/s , 1 : 9.95Gb/s to 10.3125Gb/s
//RS1   No Connect

    assign SFP1_TDISABLE = ( P_cm_p1_inst == 2'd0 ) ? 1'b1 : 1'b0 ;
    assign SFP1_RS0      = ( P_cm_p1_inst == 2'd1 ) ? 1'b0 : 1'b1 ;
    assign SFP1_RS1      = 1'b0;
    assign SFP1_I2CENB   = 1'bz;                                    // v0.3 Mod   1'b0 => 1'bz
    assign SFP1_SCL      = 1'b1;                                    // v0.3 Mod   1'b0 => 1'b1
    assign SFP1_SDA      = 1'b1;                                    // v0.3 Mod   1'b0 => 1'b1

    assign SFP2_TDISABLE = ( P_cm_p2_inst == 2'd0 ) ? 1'b1 : 1'b0 ;
    assign SFP2_RS0      = ( P_cm_p2_inst == 2'd1 ) ? 1'b0 : 1'b1 ;
    assign SFP2_RS1      = 1'b0;
    assign SFP2_I2CENB   = 1'bz;                                    // v0.3 Mod   1'b0 => 1'bz
    assign SFP2_SCL      = 1'b1;                                    // v0.3 Mod   1'b0 => 1'b1
    assign SFP2_SDA      = 1'b1;                                    // v0.3 Mod   1'b0 => 1'b1

    assign SFP3_TDISABLE = ( P_cm_p3_inst == 2'd0 ) ? 1'b1 : 1'b0 ;
    assign SFP3_RS0      = ( P_cm_p3_inst == 2'd1 ) ? 1'b0 : 1'b1 ;
    assign SFP3_RS1      = 1'b0;
    assign SFP3_I2CENB   = 1'bz;                                    // v0.3 Mod   1'b0 => 1'bz
    assign SFP3_SCL      = 1'b1;                                    // v0.3 Mod   1'b0 => 1'b1
    assign SFP3_SDA      = 1'b1;                                    // v0.3 Mod   1'b0 => 1'b1

//UNUSED
//  assign DPR_AL   = 21'h000000; // v0.3 Del
//  assign BEL      = 2'h0;       // v0.3 Del
//  assign CL       = 1'b0;       // v0.3 Del
//  assign CEL      = 2'h0;       // v0.3 Del
//  assign CQENL    = 1'b0;       // v0.3 Del
//  assign OEL      = 1'b0;       // v0.3 Del
//  assign LowSPDL  = 1'b0;       // v0.3 Del
//  assign RWL      = 1'b0;       // v0.3 Del
//  assign CNT_MCKL = 1'b0;       // v0.3 Del
//  assign ADSL     = 1'b0;       // v0.3 Del
//  assign CNTENL   = 1'b0;       // v0.3 Del
//  assign CNTRSTL  = 1'b0;       // v0.3 Del
//  assign WRPL     = 1'b0;       // v0.3 Del
//  assign RETL     = 1'b0;       // v0.3 Del
//  assign FTSELL   = 1'b0;       // v0.3 Del

//  assign DPR_AR   = 21'h000000; // v0.3 Del
//  assign BER      = 2'h0;       // v0.3 Del
//  assign CR       = 1'b0;       // v0.3 Del
//  assign CER      = 2'h0;       // v0.3 Del
//  assign CQENR    = 1'b0;       // v0.3 Del
//  assign OER      = 1'b0;       // v0.3 Del
//  assign LowSPDR  = 1'b0;       // v0.3 Del
//  assign RWR      = 1'b0;       // v0.3 Del
//  assign CNT_MCKR = 1'b0;       // v0.3 Del
//  assign ADSR     = 1'b0;       // v0.3 Del
//  assign CNTENR   = 1'b0;       // v0.3 Del
//  assign CNTRSTR  = 1'b0;       // v0.3 Del
//  assign WRPR     = 1'b0;       // v0.3 Del
//  assign RETR     = 1'b0;       // v0.3 Del
//  assign FTSELR   = 1'b0;       // v0.3 Del
//  assign DPRAM_MRST = 1'b0;     // v0.3 Del

`ifdef P_FPGA1
    assign F1_OUT_F2_IN = 8'h00;
    assign F1_ROM_SCL   = 1'b1;  // v0.3 Mod   1'b0 => 1'b1
    assign F1_ROM_SDA   = 1'b1;  // v0.3 Mod   1'b0 => 1'b1
    assign F1_ROM_ENB   = 1'bz;  // v0.3 Mod   1'b0 => 1'bz
`else
    assign F1_IN_F2_OUT = 8'h00;
    assign F2_ROM_SCL   = 1'b1;  // v0.3 Mod   1'b0 => 1'b1
    assign F2_ROM_SDA   = 1'b1;  // v0.3 Mod   1'b0 => 1'b1
    assign F2_ROM_ENB   = 1'bz;  // v0.3 Mod   1'b0 => 1'bz
`endif

//---------------------------------------------------------------
// DDRマクロ (EMIF 制御)
//---------------------------------------------------------------
DDR_MODULE DDR_MODULE_inst
   (
    //DDR avalon I/F
    .DDR_CLK                     ( ddr_user_clk                  ) , // input             
    .DDR_RESET_N                 ( ddr_user_rst_n                ) , // input             
    .DDR_WAIT_REQ_N              ( ddr_ready                     ) , // input             
    .DDR_READ                    ( ddr_read                      ) , // output            
    .DDR_WRITE                   ( ddr_write                     ) , // output            
    .DDR_ADDRESS                 ( ddr_address                   ) , // output   [26:0]   
    .DDR_READDATA                ( ddr_readdata                  ) , // input   [127:0]   
    .DDR_WRITEDATA               ( ddr_writedata                 ) , // output  [127:0]   
    .DDR_BURSTCOUNT              ( ddr_burstcount                ) , // output    [6:0]   
    .DDR_BYTE_ENABLE             ( ddr_byteenable                ) , // output   [15:0]   
    .DDR_READ_VALID              ( ddr_valid                     ) , // input             
    .INIT_DONE                   ( n_cal_success                 ) , // input             

    //FIFO I/F
    .USER_CLK                    ( n_clk156m                     ) , // input             
    .USER_RESET_N                ( ~n_arst                       ) , // input             
    .FIFO_WRITE                  ( n_ddr_ctrl_fifo_write         ) , // input             
    .FIFO_READ                   ( n_ddr_ctrl_fifo_read          ) , // input             
    .FIFO_READ_RDY               ( /* open */                    ) , // output            
    .FIFO_WRITE_DATA             ( n_ddr_ctrl_fifo_write_data    ) , // input   [127:0]   
    .FIFO_READ_DATA              ( n_ddr_mod_fifo_read_data      ) , // output  [127:0]   

    //REG I/F
    .REG_WRITE                   ( n_ddr_ctrl_reg_write          ) , // input             
    .REG_READ                    ( n_ddr_ctrl_reg_read           ) , // input             
    .REG_WRITE_DATA              ( n_ddr_ctrl_reg_write_data     ) , // input    [31:0]   
    .REG_READ_DATA               ( n_ddr_mod_reg_read_data       ) , // output   [31:0]   
    .WA_ENABLE                   ( n_ddr_ctrl_reg_wa_enable      ) , // input             
    .RA_ENABLE                   ( n_ddr_ctrl_reg_ra_enable      ) , // input             
    .TRANS_ENABLE                ( n_ddr_ctrl_reg_trans_enable   ) , // input             
    .RECEIVE_ENABLE              ( n_ddr_ctrl_reg_receive_enable ) , // input             
    .BURST_ENABLE                ( n_ddr_ctrl_reg_burst_enable   ) , // input             
    .MODE_ENABLE                 ( n_ddr_ctrl_reg_mode_enable    ) , // input             
    .RW_ENABLE                   ( n_ddr_ctrl_reg_rw_enable      ) , // input             
    .STATUS_ENABLE               ( 1'b0                          ) , // input             
    .INRS_ENABLE                 ( 1'b0                          ) , // input             
    .FW_ENABLE                   ( n_ddr_ctrl_reg_fw_enable      ) , // input             
    .FR_ENABLE                   ( n_ddr_ctrl_reg_fr_enable      ) , // input             
    .LED                         ( /* open */                    ) , // output   [ 7:0]   

    .INIT_SKIP                   ( 1'b0                          ) , // input             ◆◆ 20190214 実動作では使用しないので、0固定とする 
    .STATUS                      ( n_ddr_mod_status              ) , // output   [ 6:0]   

    .FIFO_W_STATUS               ( n_ddr_mod_fifo_w_status       ) , // output   [12:0]   
    .FIFO_R_STATUS               ( n_ddr_mod_fifo_r_status       )   // output   [12:0]   
    );

//---------------------------------------------------------------
// DDR if IP (EMIF)
//---------------------------------------------------------------
DDR3 DDR3_inst
   (
    .amm_ready_0                 ( ddr_ready      ) , // output wire               ctrl_amm_0.waitrequest_n
    .amm_read_0                  ( ddr_read       ) , // input  wire                         .read
    .amm_write_0                 ( ddr_write      ) , // input  wire                         .write
    .amm_address_0               ( ddr_address    ) , // input  wire [26:0]                  .address
    .amm_readdata_0              ( ddr_readdata   ) , // output wire [127:0]                 .readdata
    .amm_writedata_0             ( ddr_writedata  ) , // input  wire [127:0]                 .writedata
    .amm_burstcount_0            ( ddr_burstcount ) , // input  wire [6:0]                   .burstcount
    .amm_byteenable_0            ( ddr_byteenable ) , // input  wire [15:0]                  .byteenable
    .amm_readdatavalid_0         ( ddr_valid      ) , // output wire                         .readdatavalid
    .emif_usr_clk                ( ddr_user_clk   ) , // output wire             emif_usr_clk.clk
    .emif_usr_reset_n            ( ddr_user_rst_n ) , // output wire         emif_usr_reset_n.reset_n
    .global_reset_n              ( sm_xreset      ) , // input  wire           global_reset_n.reset_n

    .mem_ck                      ( DDR_CK_0_P     ) , // output wire [0:0]                mem.mem_ck
    .mem_ck_n                    ( DDR_CK_0_N     ) , // output wire [0:0]                   .mem_ck_n
    .mem_a                       ( DDR_ADDR       ) , // output wire [15:0]                  .mem_a
    .mem_ba                      ( DDR_BA         ) , // output wire [2:0]                   .mem_ba
    .mem_cke                     ( DDR_CKE        ) , // output wire [0:0]                   .mem_cke
    .mem_cs_n                    ( DDR_CSn        ) , // output wire [0:0]                   .mem_cs_n
    .mem_odt                     ( DDR_ODT        ) , // output wire [0:0]                   .mem_odt
    .mem_reset_n                 ( DDR_RESETn     ) , // output wire [0:0]                   .mem_reset_n
    .mem_we_n                    ( DDR_WEn        ) , // output wire [0:0]                   .mem_we_n
    .mem_ras_n                   ( DDR_RASn       ) , // output wire [0:0]                   .mem_ras_n
    .mem_cas_n                   ( DDR_CASn       ) , // output wire [0:0]                   .mem_cas_n
    .mem_dqs                     ( DDR_DQS        ) , // inout  wire [3:0]                   .mem_dqs
    .mem_dqs_n                   ( DDR_DQSn       ) , // inout  wire [3:0]                   .mem_dqs_n
    .mem_dq                      ( DDR_DQ         ) , // inout  wire [31:0]                  .mem_dq
    .mem_dm                      ( DDR_DM         ) , // output wire [3:0]                   .mem_dm
    .oct_rzqin                   ( DDR_RZQIN      ) , // input  wire                      oct.oct_rzqin
    .pll_ref_clk                 ( DDR_CLK        ) , // input  wire              pll_ref_clk.clk
    .local_cal_success           ( n_cal_success  ) , // output wire                   status.local_cal_success
    .local_cal_fail              ( n_cal_fail     )   // output wire                         .local_cal_fail
    );

endmodule
