//--------------------------------------------------------------------------------------------------
// Company           : Oki Electric Industry Co., Ltd.
// Project Name      : FPGA development for sonar (29SS)
// Module Name       : xa_dir_calc
// Function          : Beam Forming Direction Calcuration Module
// Create Date       : 2019.06.07
// Original Designer : Kenjiro Yakuwa
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// History:
//--------------------------------------------------------------------------------------------------
// Ver   | Date         | Designer          | Comment
//--------------------------------------------------------------------------------------------------
// 1.0   | 2019.06.04   | Kenjiro Yakuwa    | �V�K�쐬
//
// Copyright 2019 Oki Electric Industry Co., Ltd.
//
//--------------------------------------------------------------------------------------------------
// Module & Port
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
module xa_bf_dir_calc_01 (
// input
    input  wire              i_arst                                  ,    // �񓯊����Z�b�g
    input  wire              i_clk156m                               ,    // �N���b�N
    input  wire              i_bm_start                              ,    // ���Z�����J�n�p���X(beam����)
    input  wire    [31:0]    i_beam_phi                              ,    // �Ӌp�p�����[�^
    input  wire    [9:0]     i_beam_idx                              ,    // ���Z�Ώۃr�[���ԍ�
    input  wire    [31:0]    i_snd_spd                               ,    // �����p�����[�^
// output                                                                 
    output wire    [31:0]    o_bf_dir_vector_ss_x                    ,    // �o�̓f�[�^�iX���W)
    output wire    [31:0]    o_bf_dir_vector_ss_y                    ,    // �o�̓f�[�^�iY���W)
    output wire    [31:0]    o_bf_dir_vector_ss_z                    ,    // �o�̓f�[�^�iZ���W)
    output wire              o_bm_start                                   // ���Z�����J�n�w���o��(beam����)
);

//--------------------------------------------------------------------------------------------------
// Parameter
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
    localparam   P_pi_180    = 32'h3C8E_FA35; // pi/180
    localparam   P_pi_2      = 32'h3FC9_0FDB; // pi/2

//--------------------------------------------------------------------------------------------------
// Reg & Wire
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
    reg  [5:0]     r_count;
    wire [31:0]    s_rad_beam_phi;
    wire [31:0]    s_cos_offset;
    wire [31:0]    s_rad_beam_phi_ofst;
    wire [31:0]    s_cos_sin_phi;
    wire [9:0]     s_beam_idx_x3;
    reg  [9:0]     r_rd_addr;
    wire [31:0]    s_bf_dir_vector_th_xyz;
    wire [31:0]    s_bf_dir_vector_xyz;
    wire [31:0]    s_bf_dir_vector_ss_xyz;
    reg  [31:0]    r_bf_dir_vector_ss_x_lt;
    reg  [31:0]    r_bf_dir_vector_ss_y_lt;
    reg  [31:0]    r_bf_dir_vector_ss_z_lt;
    reg  [31:0]    r_bf_dir_vector_ss_x;
    reg  [31:0]    r_bf_dir_vector_ss_y;
    reg  [31:0]    r_bf_dir_vector_ss_z;
    reg            r_bm_start;

//--------------------------------------------------------------------------------------------------
// Main
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// ����p�J�E���^(64�i)
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_count <= 6'd63;
        end
        else if (i_bm_start)begin
            r_count <= 6'd0;
        end
        else if (r_count < 6'd63)begin
            // r_count=63�܂ŃJ�E���g�A�b�v�B63�ɂȂ�����z�[���h
            r_count <= r_count + 1'b1;
        end
    end

//   radBeamPhi = beamPhi*pi/180;        % ��pi/180�͌Œ�l��Z
    ALTERA_FP_MULT_32BIT_OP03_3CK ALTERA_FP_MULT_32BIT_OP03_3CK_inst0 (
        .clk    (i_clk156m     ),
        .areset (i_arst        ),
        .a      (i_beam_phi    ),
        .b      (P_pi_180      ),
        .q      (s_rad_beam_phi),
        .en     (1'b1          )
    );

// SIN���Z��IP1��ނ��g�p���邽��,COS�v�Z����ۂ�radBeamPhi��+pi/2�I�t�Z�b�g����B
    // SIN��COS�I�t�Z�b�g�l(+pi/2)
    assign s_cos_offset = (r_count == 6'd2 || r_count == 6'd3) ? P_pi_2  : 32'd0;

    // radBeamPhi-pi/2
    // radBeamPhi
    ALTERA_FP_ADD_32BIT_OP03_3CK ALTERA_FP_ADD_32BIT_OP03_3CK_inst (
        .clk    (i_clk156m          ),
        .areset (i_arst             ),
        .a      (s_rad_beam_phi     ),
        .b      (s_cos_offset       ),
        .q      (s_rad_beam_phi_ofst),
        .en     (1'b1               )
    );

// SIN���Z
    // cosPhi = sin(radBeamPhi+pi/2);        % ��cos(radBeamPhi)��sin�Ŏ����i�������ʉ��̂��߁j
    // sinPhi = sin(radBeamPhi);
    ALTERA_FP_SIN_32BIT_OP02_22CK ALTERA_FP_SIN_32BIT_OP02_22CK_inst (
        .clk    (i_clk156m          ),
        .areset (i_arst             ),
        .a      (s_rad_beam_phi_ofst),
        .q      (s_cos_sin_phi      ),
        .en     (1'b1               )
    );

// �����������ʌW��ROM���[�h�A�h���X����
    // i_beam_idx x3 (x3���Ă��r�b�g�������Ȃ��j
    assign s_beam_idx_x3 =  (i_beam_idx[8:0] << 1) + {1'b0, i_beam_idx[8:0]};

    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_rd_addr <= 10'd0;
        end
        else if (r_count == 6'd24)begin
            r_rd_addr <= s_beam_idx_x3;
        end
        else if (r_count == 6'd25 || r_count == 6'd26)begin
            r_rd_addr <= r_rd_addr + 1'b1;
        end
    end

// �������ʌW��ROM(bfDirVectorTh_x,y,z)
// Latency 17CLK
    ROM_1PORT_XA_BF_BFDIRVECTORTH_01 ROM_1PORT_XA_BF_BFDIRVECTORTH_inst (
        .address (r_rd_addr  ),
        .clock   (i_clk156m ),
        .clken   (1'b1      ),
        .aclr    (i_arst    ),
        .rden    (1'b1      ),
        .q       (s_bf_dir_vector_th_xyz)
    );

//  bfDirVector_x = bfDirVectorTh_x(beam) x sin(radBeamPhi + PI/2)
//  bfDirVector_y = bfDirVectorTh_y(beam) x sin(radBeamPhi + PI/2)
//  bfDirVector_z = bfDirVectorTh_z(beam) x sin(radBeamPhi + 0)
    ALTERA_FP_MULT_32BIT_OP03_3CK ALTERA_FP_MULT_32BIT_OP03_3CK_inst1 (
        .clk    (i_clk156m             ),
        .areset (i_arst                ),
        .a      (s_bf_dir_vector_th_xyz),
        .b      (s_cos_sin_phi         ),
        .q      (s_bf_dir_vector_xyz   ),
        .en     (1'b1                  )
    );

// bfDirVector_ss_R = bfDirVectorR/sndSpd;
// bfDirVector_ss_L = bfDirVectorL/sndSpd;
    ALTERA_FP_DIV_32BIT_OP03_17CK ALTERA_FP_DIV_32BIT_OP03_17CK_inst (
        .clk    (i_clk156m             ),
        .areset (i_arst                ),
        .a      (s_bf_dir_vector_xyz   ),
        .b      (i_snd_spd             ),
        .q      (s_bf_dir_vector_ss_xyz),
        .en     (1'b1                  )
    );

// S/P
    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_bf_dir_vector_ss_x_lt <= 32'd0;
            r_bf_dir_vector_ss_y_lt <= 32'd0;
            r_bf_dir_vector_ss_z_lt <= 32'd0;
            r_bf_dir_vector_ss_x    <= 32'd0;
            r_bf_dir_vector_ss_y    <= 32'd0;
            r_bf_dir_vector_ss_z    <= 32'd0;
        end
        else begin
            if (r_count == 6'd47) begin
                r_bf_dir_vector_ss_x_lt <= s_bf_dir_vector_ss_xyz;
            end
            if (r_count == 6'd48) begin
                r_bf_dir_vector_ss_y_lt <= s_bf_dir_vector_ss_xyz;
            end
            if (r_count == 6'd49) begin
                r_bf_dir_vector_ss_z_lt <= s_bf_dir_vector_ss_xyz;
            end
            if (r_count == 6'd50) begin
                 r_bf_dir_vector_ss_x <= r_bf_dir_vector_ss_x_lt;
                 r_bf_dir_vector_ss_y <= r_bf_dir_vector_ss_y_lt;
                 r_bf_dir_vector_ss_z <= r_bf_dir_vector_ss_z_lt;
            end
        end
    end

    always@( posedge i_arst or posedge i_clk156m)begin
        if (i_arst) begin
            r_bm_start <= 1'b0;
        end
        else if (r_count == 6'd50) begin
            r_bm_start <= 1'b1;
        end
        else begin
            r_bm_start <= 1'b0;
        end
    end

// ------ //
// Output //
// ------ //
    assign o_bf_dir_vector_ss_x = r_bf_dir_vector_ss_x;
    assign o_bf_dir_vector_ss_y = r_bf_dir_vector_ss_y;
    assign o_bf_dir_vector_ss_z = r_bf_dir_vector_ss_z;
    assign o_bm_start           = r_bm_start;

endmodule
