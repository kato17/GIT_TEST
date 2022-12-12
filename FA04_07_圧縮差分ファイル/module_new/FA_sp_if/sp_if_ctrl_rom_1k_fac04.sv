//--------------------------------------------------------------------------------------------------
// Company           : Oki Electric Industry Co., Ltd.
// Project Name      : FPGA development for sonar (29SS)
// Module Name       : sp_if_ctrl_rom
// Function          : FPGA sp_if_ctrl_rom Module
// Create Date       : 2019.04.05
// Original Designer : Kazuki Matsusaka
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0
// History:
//--------------------------------------------------------------------------------------------------
// Ver   | Date         | Designer          | Comment
//--------------------------------------------------------------------------------------------------
// 1.0   | 2019.04.05   | Kazuki Matsusaka  | �V�K�쐬
// 1.1   | 2022.09.15   | Masayuki Kato     | ���W���[�����ύX 
//
// Copyright 2019 Oki Electric Industry Co., Ltd.
//
module sp_if_ctrl_rom_fac04 (								//���W���[�����ύX v1.1
	input	logic			i_arst						,	// asyncronous reset
	input	logic	[9:0]	i_order_mem_rd_adr			,	// �I�[�_�[ROM�Ǐo���A�h���X
	input	logic			i_clk156m					,	// system clock(156.25MHz)
	input	logic			i_order_mem_rden			,	// �I�[�_�[ROM�Ǐo���C�l�[�u��
	output	logic	[31:0]	o_order_mem_rd_data				// �I�[�_�[ROM�Ǐo���f�[�^
	);


//--------------------------------------------------------------------------------------------------
// Main
//--+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----0

//DDR�A�N�Z�X�I�[�_�[ROM
ROM_1PORT_SP_IF_ORDER_FAC04	ROM_1PORT_SP_IF_ORDER_inst (			//���W���[�����ύX v1.1
	.address	( i_order_mem_rd_adr    )	,
	.clock		( i_clk156m             )	,
	.clken		( 1'b1		            )	,
	.aclr		( i_arst	            )	,
	.rden		( i_order_mem_rden      )	,
	.q			( o_order_mem_rd_data   )
	);


endmodule
