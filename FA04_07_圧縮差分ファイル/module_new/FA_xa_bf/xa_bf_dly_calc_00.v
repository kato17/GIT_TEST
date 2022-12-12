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
// 1.0   | 2019.06.07   | Kenjiro Yakuwa    | �V�K�쐬
//
// Copyright 2019 Oki Electric Industry Co., Ltd.
//
//--------------------------------------------------------------------------------------------------
// Module & Port
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
module xa_bf_dly_calc_00 #(
    parameter      [10:0]    P_stave_num    =   11'd250              ,    // �X�e�[�u���p�����[�^
    parameter      [31:0]    P_fs           =   32'h454CCCCC         ,    // �T���v�����O���g���p�����[�^(3276.8Hz)
    parameter      [31:0]    P_ts           =   32'h39A00000              // �T���v�����O�������p�����[�^
    )
(
// input
    input  wire              i_arst                                  ,    // �񓯊����Z�b�g
    input  wire              i_clk156m                               ,    // �N���b�N
    input  wire              i_bm_start                              ,    // ���Z�����J�n�p���X(beam����)
    input  wire    [31:0]    i_bf_dir_vector_ss_x                    ,    // �������ʌv�Z����(X���W)
    input  wire    [31:0]    i_bf_dir_vector_ss_y                    ,    // �������ʌv�Z����(Y���W)
    input  wire    [31:0]    i_bf_dir_vector_ss_z                    ,    // �������ʌv�Z����(Z���W)
    input  wire    [31:0]    i_pos_wr_data                           ,    // TA�p�ʒu�x�N�g���f�[�^
    input  wire              i_pos_wr_en                             ,    // TA�p��g��ʒu�x�N�g���i�[RAM���C�g�C�l�[�u��
// output
    output wire    [31:0]    o_tau_precise0                          ,    // �x�����ԏo��(������)
    output wire    [31:0]    o_tau_precise1                          ,    // �x�����ԏo��(������)
    output wire    [31:0]    o_tau_sample0                           ,    // �x�����ԏo��(������)
    output wire    [31:0]    o_tau_sample1                           ,    // �x�����ԏo��(������)
    output wire    [9:0]     o_ch_idx0                               ,    // chIdx(�Z���T�[�C���f�b�N�X)
    output wire    [9:0]     o_ch_idx1                               ,    // chIdx(�Z���T�[�C���f�b�N�X)
    output wire              o_ch_start0                             ,    // ch(�Z���T�[)�����X�^�[�g�p���X
    output wire              o_ch_start1                                  // ch(�Z���T�[)�����X�^�[�g�p���X
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
// �ʒu�x�N�g���e�[�u��RAM���C�g�A�h���X
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

// ��g��ʒu�e�[�u��RAM
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


// �X�e�[�u���ő�l
    assign s_stave_max  = P_stave_num - 1'b1;
    assign s_stave_max0 = s_stave_max[10:1];
    assign s_stave_max1 = s_stave_max[9:0];

// CLK�J�E���^�C�l�[�u��0
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

// CLK�J�E���^0
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

// CLK�J�E���^�C�l�[�u��1
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_clk_cntr_en1 <= 1'b0;
        end
        else if (r_clk_cntr0 == 8'd127) begin
            // clk_cntr0��128CLK�̒x��������������
            r_clk_cntr_en1 <= 1'b1;
        end
        else if (r_clk_cntr1 == 8'd255 && r_ch_idx1 == s_stave_max1) begin
            r_clk_cntr_en1 <= 1'b0;
        end
    end

// CLK�J�E���^1
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

// ��g��ʒu�e�[�u��RAM���[�h�C�l�[�u��
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

// ��g��ʒu�e�[�u��RAM���[�h�A�h���X
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_rd_addr <= 11'd0;
        end
        else if (r_clk_cntr_en0 == 1'b1 && r_clk_cntr0 == 8'd0) begin
            // P_stave_num�͍ő�682�B682x3=2046�Ȃ̂�11bit��OK�B
            // s_ch_idx0_x3[11]�͖��g�p(���0�ƂȂ邽�ߎ̂Ă�OK)
            r_rd_addr <= s_ch_idx0_x3[10:0];
        end
        else if (r_clk_cntr_en1 == 1'b1 && r_clk_cntr1 == 8'd0) begin
            // P_stave_num�͍ő�682�B682x3=2046�Ȃ̂�11bit��OK�B
            // s_ch_idx1_x3[11]�͖��g�p(���0�ƂȂ邽�ߎ̂Ă�OK)
            r_rd_addr <= s_ch_idx1_x3[10:0];
        end
        else if (r_rd_en == 1'b1) begin
            r_rd_addr <= r_rd_addr + 1'b1;
        end
    end

// ��g��ʒu�e�[�u��RAM���[�h�f�[�^S/P
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

//--- �x������[sec]�̌v�Z ---%
// FA_ho.m�̉��L�v�Z�̎��̌v�Z���s���B
// FPGA��R��L���������Ă���̂�
// �{���W���[���ł͂ǂ��炩�Е��݂̂̌v�Z�ƂȂ�
// ��FA_ho.m�v�Z��
// delay_R = pos_right(chIdx,:)*bfDirVector_ss_R; % �x������(�E��)
// delay_L = pos_left(chIdx,:)*bfDirVector_ss_L;  % �x������(����)
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

//-- �x�����Ԃ���x���T���v�����Z�o ---%
// �x������[sec] �x��́|�A�i�݂́{�̕���
// ��FA_ho.m�v�Z��
// delay_smpl_R = delay_R*fs;        % ���x���T���v����(0ori)���v�Z[smpl] ���u/Ts�v���u*fs�v�ő��
// delay_smpl_L = delay_L*fs;        % ���x���T���v����(0ori)���v�Z[smpl] ���u/Ts�v���u*fs�v�ő��
    ALTERA_FP_MULT_32BIT_OP03_3CK ALTERA_FP_MULT_32BIT_OP03_3CK_inst0 (
        .clk    (i_clk156m     ),
        .areset (i_arst        ),
        .a      (s_delay       ),
        .b      (P_fs          ),
        .q      (s_delay_smpl  ),
        .en     (1'b1          )
    );

// round�y��float->integer�ϊ�
// ��FA_ho.m�v�Z��
// tau_sample_R = round(delay_smpl_R);        % ���ł��߂������ւ̊ۂ�
// tau_sample_L = round(delay_smpl_L);        % ���ł��߂������ւ̊ۂ�
    ALTERA_FP_FLT32BIT_INT32BIT_OP02_2CK ALTERA_FP_FLT32BIT_INT32BIT_OP02_2CK_inst (
        .clk    (i_clk156m     ),
        .areset (i_arst        ),
        .a      (s_delay_smpl  ),
        .q      (s_tau_sample  ),
        .en     (1'b1          )
    );

// integer->float�ϊ�
// tau_precise�v�Z�̂���round��ēxfloat�ɖ߂�
// ��FA_ho.m�v�Z��
// tau_sample_R = round(delay_smpl_R);        % ���ł��߂������ւ̊ۂ�
// tau_sample_L = round(delay_smpl_L);        % ���ł��߂������ւ̊ۂ�
    ALTERA_FP_INT32BIT_FLT32BIT_OP02_4CK ALTERA_FP_INT32BIT_FLT32BIT_OP02_4CK_inst (
        .clk    (i_clk156m       ),
        .areset (i_arst          ),
        .a      (s_tau_sample    ),
        .q      (s_tau_sample_flt),
        .en     (1'b1            )
    );

// %--- �ڍגx������[sec]�̎Z�o
// ��FA_ho.m�v�Z��
// delay_round_R = Ts * tau_sample_R;        % ���x������[sec]�̐����l���ĎZ�o
// delay_round_L = Ts * tau_sample_L;        % ���x������[sec]�̐����l���ĎZ�o
    ALTERA_FP_MULT_32BIT_OP03_3CK ALTERA_FP_MULT_32BIT_OP03_3CK_inst1 (
        .clk    (i_clk156m       ),
        .areset (i_arst          ),
        .a      (P_ts            ),
        .b      (s_tau_sample_flt),
        .q      (s_delay_round   ),
        .en     (1'b1            )
    );

// delay�V�t�g
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_delay_sft <= 384'b0;
        end
        else begin
            r_delay_sft <= {r_delay_sft[351:0], s_delay};
        end
    end

// ��FA_ho.m�v�Z��
// tau_precise_R = delay_R - delay_round_R;        % ���x������[sec]���琮���l�������ď����l�i�ڍגx���j���Z�o
// tau_precise_L = delay_L - delay_round_L;        % ���x������[sec]���琮���l�������ď����l�i�ڍגx���j���Z�o
    ALTERA_FP_SUB_32BIT_OP03_3CK ALTERA_FP_SUB_32BIT_OP03_3CK_inst (
        .clk    (i_clk156m           ),
        .areset (i_arst              ),
        .a      (r_delay_sft[383:352]),
        .b      (s_delay_round       ),
        .q      (s_tau_precise       ),
        .en     (1'b1                )
    );

// �o�̓��^�C�~���O
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
