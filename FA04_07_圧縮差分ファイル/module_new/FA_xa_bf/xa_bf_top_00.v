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
// 1.0   | 2019.06.12   | Kenjiro Yakuwa    | �V�K�쐬
// 1.1   | 2022.09.15   | Masayuki Kato     | �ύX
//
// Copyright 2019 Oki Electric Industry Co., Ltd.
//
//--------------------------------------------------------------------------------------------------
// Module & Port
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
module xa_bf_top_00 #(														// v1.2
    parameter      [11:0]    P_sample_num        = 12'd128           ,    // �T���v�����p�����[�^
    parameter      [10:0]    P_stave_num         = 11'd250           ,    // �X�e�[�u���p�����[�^
    parameter      [10:0]    P_stv_add_num       = 11'd250           ,    // �X�e�[�u���Z���̉��Z�ΏۃX�e�[�u��
    parameter      [9:0]     P_beam_start_num    = 10'd0             ,    // �X�^�[�gbeam idx
    parameter      [9:0]     P_beam_num          = 10'd66            ,    // ���Z1�񖈂̉��Z�r�[����
    parameter      [19:0]    P_odata_num         = 20'd8448          ,    // ���Z1�񖈂̉��Z���ʃf�[�^����
    parameter      [31:0]    P_sp_adr_offset     = 32'h0003E806      ,    // �����Z�o�f�[�^�̃A�h���X�I�t�Z�b�g�l
    parameter      [31:0]    P_se_adr_offset     = 32'h0003E818      ,    // ��g��ʒu�f�[�^�̃A�h���X�I�t�Z�b�g�l
    parameter      [11:0]    P_se_data_size      = 12'd750           ,    // ��g��ʒu�f�[�^�̃��[�h�f�[�^��
    parameter      [31:0]    P_fs                = 32'h454CCCCC      ,    // �T���v�����O���g��
    parameter      [31:0]    P_ts                = 32'h39A00000      ,    // �T���v�����O����
    parameter      [31:0]    P_fs_del_smpl       = 32'h48200000      ,    // �t�B���^�[�I���C���f�b�N�X�p�W��
    parameter      [5:0]     P_offst_dly_fil     = 6'd25             ,    // �ڍגx���t�B���^�|�I�t�Z�b�g�l
    parameter      [11:0]    P_offst_dly_smpl    = 12'd1024          ,    // �x���o�b�t�@�[�I�t�Z�b�g�l
    parameter      [12:0]    P_buff_size         = 13'd2048          ,    // �x���o�b�t�@�[�T�C�Y
    parameter      [5:0]     P_buff_unit         = 6'd16             ,    // P_buff_size/P_sample_num
    parameter      [8:0]     P_pcnt_snd_spd      = 9'd0              ,    // �����̏����p�����[�^�[�i�[�ʒu
    parameter      [8:0]     P_pcnt_beam_phi0    = 9'd0              ,    // �Ӌp�l1�̏����p�����[�^�[�i�[�ʒu
    parameter      [8:0]     P_pcnt_beam_phi1    = 9'd0              ,    // �Ӌp�l2�̏����p�����[�^�[�i�[�ʒu
    parameter      [8:0]     P_pcnt_beam_phi2    = 9'd0              ,    // �Ӌp�l3�̏����p�����[�^�[�i�[�ʒu
    parameter      [8:0]     P_pcnt_beam_phi3    = 9'd0              ,    // �Ӌp�l4�̏����p�����[�^�[�i�[�ʒu
    parameter      [8:0]     P_pcnt_beam_phi4    = 9'd0              ,    // �Ӌp�l5�̏����p�����[�^�[�i�[�ʒu
    parameter      [8:0]     P_pcnt_beam_phi5    = 9'd0              ,    // �Ӌp�l6�̏����p�����[�^�[�i�[�ʒu
    parameter      [8:0]     P_pcnt_beam_phi6    = 9'd0              ,    // �Ӌp�l7�̏����p�����[�^�[�i�[�ʒu
    parameter      [8:0]     P_pcnt_beam_phi7    = 9'd0              ,    // �Ӌp�l8�̏����p�����[�^�[�i�[�ʒu
    parameter      [9:0]     P_beam_phi_cnt      = 10'd1             ,    // �Ӌp�l�J�E���g�A�b�v�̃r�[����
    parameter      [3:0]     P_beam_phi_max      = 4'd1              ,    // �Ӌp�l�J�E���g�A�b�v�̍ő�l
    parameter      [17:0]    P_beam_period       = 18'd32000              // 1beam������̃T���v����
)
(
// input
    input  wire              i_arst                                  ,    // �񓯊����Z�b�g
    input  wire              i_clk156m                               ,    // �N���b�N
    input  wire    [4:0]     i_frame_time                            ,    // �t���[���ԍ�
    input  wire              i_calc_start                            ,    // ���Z1�񖈂̐M�������J�n�p���X
    input  wire              i_param_start                           ,    // �����E�ʒu�x�N�g���]���J�n�w��
    input  wire              i_param_valid                           ,    // �����p�����[�^valid
    input  wire    [8:0]     i_param_cnt                             ,    // �����p�����[�^�A�h���X
    input  wire    [31:0]    i_param_data                            ,    // �����p�����[�^�f�[�^
    input  wire    [31:0]    i_iram0_rd_data                         ,    // ����RAM0���[�h�f�[�^
    input  wire              i_iram0_rd_valid                        ,    // ����RAM0���[�h�f�[�^valid
    input  wire    [31:0]    i_iram1_rd_data                         ,    // ����RAM1���[�h�f�[�^
    input  wire              i_iram1_rd_valid                        ,    // ����RAM1���[�h�f�[�^valid
    input  wire              i_snd_pos_sel                           ,    // �����E�ʒu�x�N�g���ؑ֎w��
// output
    output wire              o_param_end                             ,    // �����E�ʒu�x�N�g���]�������ʒm
    output wire              o_calc_end                              ,    // ���Z���������p���X
    output wire    [31:0]    o_bm_data                               ,    // ���Z���ʃf�[�^
    output wire              o_bm_data_valid                         ,    // ���Z���ʃf�[�^valid
    output wire    [31:0]    o_iram0_rd_addr                         ,    // ����RAM0 ���[�h�A�h���X
    output wire              o_iram0_rd_en                           ,    // ����RAM0 ���[�henable
    output wire    [31:0]    o_iram1_rd_addr                         ,    // ����RAM1 ���[�h�A�h���X
    output wire              o_iram1_rd_en                                // ����RAM1 ���[�henable
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
//  �����E�ʒu�x�N�g���I�����W���[��
    xa_bf_param_sel #(
        .P_sp_adr_offset          (P_sp_adr_offset      ),      // �����Z�o�f�[�^�̃A�h���X�I�t�Z�b�g�l
        .P_se_adr_offset          (P_se_adr_offset      ),      // ��g��ʒu�f�[�^�̃A�h���X�I�t�Z�b�g�l
        .P_se_data_size           (P_se_data_size       ),      // ��g��ʒu�f�[�^�̃��[�h�f�[�^��
        .P_pcnt_snd_spd           (P_pcnt_snd_spd       )       // �����̏����p�����[�^�[�i�[�ʒu
        )
    xa_bf_param_sel_inst (
        .i_arst                   (i_arst               ),      // �񓯊����Z�b�g
        .i_clk156m                (i_clk156m            ),      // �N���b�N
        .i_param_start            (i_param_start        ),      // �����E�ʒu�x�N�g���]���J�n�w��
        .i_param_data             (i_param_data         ),      // �����p�����[�^�f�[�^
        .i_param_valid            (i_param_valid        ),      // �����p�����[�^valid
        .i_param_cnt              (i_param_cnt          ),      // �����p�����[�^�A�h���X
        .i_snd_pos_sel            (i_snd_pos_sel        ),      // �����E�ʒu�x�N�g���ؑ֎w��
        .i_iram0_rd_data          (s_iram0_rd_data_sel0 ),      // ����RAM0���[�h�f�[�^
        .i_iram0_rd_valid         (s_iram0_rd_valid_sel0),      // ����RAM0���[�h�f�[�^valid
        .o_param_end              (w_param_end          ),      // �����E�ʒu�x�N�g���]�������ʒm
        .o_pos_wr_data            (w_pos_wr_data        ),      // ��g��ʒu�e�[�u���i�[RAM ���C�g�f�[�^
        .o_pos_wr_en              (w_pos_wr_en          ),      // ��g��ʒu�e�[�u���i�[RAM ���C�genable
        .o_iram_rd_addr           (w_iram_rd_addr_ps    ),      // ����RAM0 A�߰�ذ�ޱ��ڽ
        .o_iram_rd_en             (w_iram_rd_en_ps      ),      // ����RAM0 A�߰�ذ��en
        .o_iram0_sel              (w_iram0_sel          ),      // ����RAM0 A�߰đI��M��
        .o_snd_spd                (w_snd_spd            )       // �����p�����[�^�[�o��
    );

//  �Ӌp�l�I�����W���[��
    xa_bf_phi_sel #(
        .P_beam_start_num         ( P_beam_start_num    ),      // �X�^�[�gbeam idx
        .P_beam_num               ( P_beam_num          ),      // ���Z1�񖈂̉��Z�r�[����
        .P_pcnt_beam_phi0         ( P_pcnt_beam_phi0    ),      // �Ӌp�l1�̏����p�����[�^�[�i�[�ʒu
        .P_pcnt_beam_phi1         ( P_pcnt_beam_phi1    ),      // �Ӌp�l2�̏����p�����[�^�[�i�[�ʒu
        .P_pcnt_beam_phi2         ( P_pcnt_beam_phi2    ),      // �Ӌp�l3�̏����p�����[�^�[�i�[�ʒu
        .P_pcnt_beam_phi3         ( P_pcnt_beam_phi3    ),      // �Ӌp�l4�̏����p�����[�^�[�i�[�ʒu
        .P_pcnt_beam_phi4         ( P_pcnt_beam_phi4    ),      // �Ӌp�l5�̏����p�����[�^�[�i�[�ʒu
        .P_pcnt_beam_phi5         ( P_pcnt_beam_phi5    ),      // �Ӌp�l6�̏����p�����[�^�[�i�[�ʒu
        .P_pcnt_beam_phi6         ( P_pcnt_beam_phi6    ),      // �Ӌp�l7�̏����p�����[�^�[�i�[�ʒu
        .P_pcnt_beam_phi7         ( P_pcnt_beam_phi7    ),      // �Ӌp�l8�̏����p�����[�^�[�i�[�ʒu
        .P_beam_phi_cnt           ( P_beam_phi_cnt      ),      // �Ӌp�l�J�E���g�A�b�v�̃r�[����
        .P_beam_phi_max           ( P_beam_phi_max      ),      // �Ӌp�l�J�E���g�A�b�v�̍ő�l
        .P_beam_period            ( P_beam_period       )       // 1beam������̃T���v����
        )
    xa_bf_phi_sel_inst (
        .i_arst                   (i_arst               ),       // �񓯊����Z�b�g
        .i_clk156m                (i_clk156m            ),       // �N���b�N
        .i_calc_start             (i_calc_start         ),       // ���Z1�񖈂̐M�������J�n�p���X
        .i_param_data             (i_param_data         ),       // �����p�����[�^�f�[�^
        .i_param_valid            (i_param_valid        ),       // �����p�����[�^valid
        .i_param_cnt              (i_param_cnt          ),       // �����p�����[�^�A�h���X
        .o_beam_phi               (w_beam_phi           ),       // �Ӌp�l�p�����[�^�|�o��
        .o_beam_idx               (w_beam_idx           ),       // �����Ώۃr�[���ԍ�
        .o_bm_start               (w_bm_start_ps        )        // ���Z�J�n�w��(beam����)
    );

// �������ʌv�Z���W���[��
    xa_bf_dir_calc_00 xa_bf_dir_calc_inst(							//v1.2 
        .i_arst                   (i_arst               ),       // �񓯊����Z�b�g
        .i_clk156m                (i_clk156m            ),       // �N���b�N
        .i_bm_start               (w_bm_start_ps        ),       // ���Z�����J�n�p���X(beam����)
        .i_beam_phi               (w_beam_phi           ),       // �Ӌp�p�����[�^
        .i_beam_idx               (w_beam_idx           ),       // ���Z�Ώۃr�[���ԍ�
        .i_snd_spd                (w_snd_spd            ),       // �����p�����[�^
        .o_bf_dir_vector_ss_x     (w_bf_dir_vector_ss_x ),       // �o�̓f�[�^�iX���W)
        .o_bf_dir_vector_ss_y     (w_bf_dir_vector_ss_y ),       // �o�̓f�[�^�iY���W)
        .o_bf_dir_vector_ss_z     (w_bf_dir_vector_ss_z ),       // �o�̓f�[�^�iZ���W)
        .o_bm_start               (w_bm_start_dc        )        // ���Z�����J�n�w���o��(beam����)
    );

// �x�����Ԍv�Z���������W���[��
     xa_bf_dly_calc_00 #(											// v1.2	
        .P_stave_num              (P_stave_num          ),        // �X�e�[�u���p�����[�^
        .P_fs                     (P_fs                 ),        // �T���v�����O���g���p�����[�^(3276.8Hz)
        .P_ts                     (P_ts                 )         // �T���v�����O�������p�����[�^
        )                                                  
     xa_bf_dly_calc_inst                                   
     (                                                     
        .i_arst                   (i_arst               ),        // �񓯊����Z�b�g
        .i_clk156m                (i_clk156m            ),        // �N���b�N
        .i_bm_start               (w_bm_start_dc        ),        // ���Z�����J�n�p���X(beam����)
        .i_bf_dir_vector_ss_x     (w_bf_dir_vector_ss_x ),        // �������ʌv�Z����(X���W)
        .i_bf_dir_vector_ss_y     (w_bf_dir_vector_ss_y ),        // �������ʌv�Z����(Y���W)
        .i_bf_dir_vector_ss_z     (w_bf_dir_vector_ss_z ),        // �������ʌv�Z����(Z���W)
        .i_pos_wr_data            (w_pos_wr_data        ),        // TA�p�ʒu�x�N�g���f�[�^
        .i_pos_wr_en              (w_pos_wr_en          ),        // TA�p��g��ʒu�x�N�g���i�[RAM���C�g�C�l�[�u��
        .o_tau_precise0           (w_tau_precise0       ),        // �x�����ԏo��(������)
        .o_tau_precise1           (w_tau_precise1       ),        // �x�����ԏo��(������)
        .o_tau_sample0            (w_tau_sample0        ),        // �x�����ԏo��(������)
        .o_tau_sample1            (w_tau_sample1        ),        // �x�����ԏo��(������)
        .o_ch_idx0                (w_ch_idx0            ),        // chIdx(�Z���T�[�C���f�b�N�X)
        .o_ch_idx1                (w_ch_idx1            ),        // chIdx(�Z���T�[�C���f�b�N�X)
        .o_ch_start0              (w_ch_start0          ),        // ch(�Z���T�[)�����X�^�[�g�p���X
        .o_ch_start1              (w_ch_start1          )         // ch(�Z���T�[)�����X�^�[�g�p���X
    );

// �ڍגx���t�B���^�I�����W���[��
    xa_bf_fil_sel #(
        .P_fs_del_smpl            (P_fs_del_smpl        ),        // �t�B���^�[�I���C���f�b�N�X�p�W��
        .P_offst_dly_fil          (P_offst_dly_fil      )         // �ڍגx���t�B���^�|�I�t�Z�b�g�l
    )                                                       
    xa_bf_fil_sel_inst (                                    
        .i_arst                   (i_arst               ),        // �񓯊����Z�b�g
        .i_clk156m                (i_clk156m            ),        // �N���b�N
        .i_tau_precise0           (w_tau_precise0       ),        // �x�����ԓ���(������)
        .i_tau_precise1           (w_tau_precise1       ),        // �x�����ԓ���(������)
        .i_ch_start0              (w_ch_start0          ),        // ch(�Z���T�[)�����X�^�[�g�p���X
        .i_ch_start1              (w_ch_start1          ),        // ch(�Z���T�[)�����X�^�[�g�p���X
        .o_ch_filter0             (w_ch_filter0         ),        // �t�B���^�[�W���o��0
        .o_ch_filter1             (w_ch_filter1         ),        // �t�B���^�[�W���o��1
        .o_ch_filter_valid0       (w_ch_filter0_valid   ),        // �t�B���^�[�W���o��0 valid
        .o_ch_filter_valid1       (w_ch_filter1_valid   )         // �t�B���^�[�W���o��1 valid
    );

// �T���v���x���␳���W���[��0
    xa_bf_dly_smpl #(
        .P_offst_dly_smpl         (P_offst_dly_smpl     ),        // �x���o�b�t�@�I�t�Z�b�g�l�p�����[�^
        .P_sample_num             (P_sample_num         ),        // �T���v�����p�����[�^
        .P_stave_num              (P_stave_num          ),        // �X�e�[�u���p�����[�^
        .P_buff_unit              (P_buff_unit          ),        // P_buff_size/P_sample_num
        .P_buff_size              (P_buff_size          )         // �x���o�b�t�@�T�C�Y�p�����[�^
        )                                                   
    xa_bf_dly_smpl_inst0 (                                  
        .i_arst                   (i_arst               ),        // �񓯊����Z�b�g
        .i_clk156m                (i_clk156m            ),        // �N���b�N
        .i_tau_sample             (w_tau_sample0        ),        // �x�����ԓ��́i�������j
        .i_ch_start               (w_ch_start0          ),        // ch(�Z���T�[)�����X�^�[�g�p���X
        .i_ch_idx                 (w_ch_idx0            ),        // chIdx(�Z���T�[�C���f�b�N�X)
        .i_frame_time             (i_frame_time         ),        // �t���[���ԍ�
        .i_iram_rd_data           (s_iram0_rd_data_sel1 ),        // ���̓f�[�^�i�[RAM���[�h�f�[�^
        .i_iram_rd_valid          (s_iram0_rd_valid_sel1),        // ���̓f�[�^�i�[RAM���[�h�f�[�^valid
        .o_iram_rd_addr           (w_iram_rd_addr_ds    ),        // ���̓f�[�^�i�[RAM���[�h�A�h���X�o��
        .o_iram_rd_en             (w_iram_rd_en_ds      ),        // ���̓f�[�^�i�[RAM���[�h�C�l�[�u��
        .o_ch_data                (w_ch_data0           ),        // �o�̓f�[�^
        .o_ch_data_valid          (w_ch_data0_valid     )         // �o�̓f�[�^valid
    );

// �T���v���x���␳���W���[��1
    xa_bf_dly_smpl #(
        .P_offst_dly_smpl         (P_offst_dly_smpl     ),        // �x���o�b�t�@�I�t�Z�b�g�l�p�����[�^
        .P_sample_num             (P_sample_num         ),        // �T���v�����p�����[�^
        .P_stave_num              (P_stave_num          ),        // �X�e�[�u���p�����[�^
        .P_buff_unit              (P_buff_unit          ),        // P_buff_size/P_sample_num
        .P_buff_size              (P_buff_size          )         // �x���o�b�t�@�T�C�Y�p�����[�^
        )                                                   
    xa_bf_dly_smpl_inst1 (                                  
        .i_arst                   (i_arst               ),        // �񓯊����Z�b�g
        .i_clk156m                (i_clk156m            ),        // �N���b�N
        .i_tau_sample             (w_tau_sample1        ),        // �x�����ԓ��́i�������j
        .i_ch_start               (w_ch_start1          ),        // ch(�Z���T�[)�����X�^�[�g�p���X
        .i_ch_idx                 (w_ch_idx1            ),        // chIdx(�Z���T�[�C���f�b�N�X)
        .i_frame_time             (i_frame_time         ),        // �t���[���ԍ�
        .i_iram_rd_data           (r_iram1_rd_data      ),        // ���̓f�[�^�i�[RAM���[�h�f�[�^
        .i_iram_rd_valid          (r_iram1_rd_valid     ),        // ���̓f�[�^�i�[RAM���[�h�f�[�^valid
        .o_iram_rd_addr           (w_iram_rd_addr1      ),        // ���̓f�[�^�i�[RAM���[�h�A�h���X�o��
        .o_iram_rd_en             (w_iram_rd_en1        ),        // ���̓f�[�^�i�[RAM���[�h�C�l�[�u��
        .o_ch_data                (w_ch_data1           ),        // �o�̓f�[�^
        .o_ch_data_valid          (w_ch_data1_valid     )         // �o�̓f�[�^valid
    );

// ��ݍ��݉��Z���W���[��
    xa_cm_conv #(
        .P_sample_num             (P_sample_num         ),        // �T���v�����p�����[�^
        .P_stave_num              (P_stave_num          ),        // �X�e�[�u���p�����[�^
        .P_beam_num               (P_beam_num           )         // ���Z1�񖈂̉��Z�r�[����
        )                                                   
    xa_cm_conv_inst (                                       
        .i_arst                   (i_arst               ),        // �񓯊����Z�b�g
        .i_clk156m                (i_clk156m            ),        // �N���b�N
        .i_calc_start             (i_calc_start         ),        // ���Z1�񖈂̐M�������J�n�p���X
        .i_ch_data0               (w_ch_data0           ),        // ���̓f�[�^0
        .i_ch_data0_valid         (w_ch_data0_valid     ),        // ���̓f�[�^valid0
        .i_ch_data1               (w_ch_data1           ),        // ���̓f�[�^0
        .i_ch_data1_valid         (w_ch_data1_valid     ),        // ���̓f�[�^valid0
        .i_ch_filter0             (w_ch_filter0         ),        // �W���f�[�^0
        .i_ch_filter0_valid       (w_ch_filter0_valid   ),        // �W���f�[�^0 valid
        .i_ch_filter1             (w_ch_filter1         ),        // �W���f�[�^1
        .i_ch_filter1_valid       (w_ch_filter1_valid   ),        // �W���f�[�^1 valid
        .o_conv_rslt              (w_conv_rslt          ),        // �o�̓f�[�^
        .o_conv_rslt_valid        (w_conv_rslt_valid    ),        // �o�̓f�[�^valid
        .o_conv_rslt_asel         (/* open */           ),        // �o�̓f�[�^�I��A
        .o_conv_rslt_bsel         (/* open */           ),        // �o�̓f�[�^�I��B
        .o_calc_end               (/* open */           )         // ���Z���������p���X
    );                            
                                  
// �X�e�[�u���Z���W���[��         
    xa_bf_stv_add #(              
        .P_sample_num             (P_sample_num         ),        // �T���v�����p�����[�^
        .P_stv_add_num            (P_stv_add_num        ),        // �X�e�[�u���Z���̉��Z�ΏۃX�e�[�u���p�����[�^
        .P_odata_num              (P_odata_num          )         // �o�̓f�[�^�����p�����[�^
        )                                                   
    xa_bf_stv_add_inst (                                    
        .i_arst                   (i_arst               ),        // �񓯊����Z�b�g
        .i_clk156m                (i_clk156m            ),        // �N���b�N
        .i_calc_start             (i_calc_start         ),        // ���Z1�񖈂̐M�������J�n�p���X
        .i_conv_rslt              (w_conv_rslt          ),        // ���̓f�[�^
        .i_conv_rslt_valid        (w_conv_rslt_valid    ),        // ���̓f�[�^valid
        .o_bm_data                (w_bm_data            ),        // �o�̓f�[�^
        .o_bm_data_valid          (w_bm_data_valid      ),        // �o�̓f�[�^valid
        .o_calc_end               (w_calc_end           )         // ���Z���������p���X
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

// �����E�ʒu�x�N�g���I�����W���[���ւ̓���RAM0���[�h�f�[�^
    assign s_iram0_rd_data_sel0  = (w_iram0_sel == 1'b0) ? r_iram0_rd_data  : 32'd0;
    assign s_iram0_rd_valid_sel0 = (w_iram0_sel == 1'b0) ? r_iram0_rd_valid : 1'b0;
// �T���v���x���␳���W���[���ւ̓���RAM0���[�h�f�[�^
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
                // xa_bf_dly_smpl_inst0��
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
