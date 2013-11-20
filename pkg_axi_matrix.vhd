------------------------------------------------------------------------
--  pkg_axi_matrix.vhd
--  package with all components
--
--  Copyright (C) 2013 M.FORET
--
--  This program is free software: you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation, either version
--  2 of the License, or (at your option) any later version.
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

use work.axi3m_pkg.all;  -- axi records

package pkg_axi_matrix is

  component ram_asym
  generic (
    ADDR_WIDTHA    : integer := 15;  -- address width (32 bits word)
    ADDR_WIDTHB    : integer := 16;  -- address width
    DATA_WIDTHB    : integer := 16
  );
  port (
    clka           : in  std_logic;
    mem_addra      : in  std_logic_vector(ADDR_WIDTHA-1 downto 0);
    mem_wea        : in  std_logic_vector( 3 downto 0);
    mem_dina       : in  std_logic_vector(31 downto 0);
    mem_douta      : out std_logic_vector(31 downto 0);
    --
    clkb           : in  std_logic;
    mem_addrb      : in  std_logic_vector(ADDR_WIDTHB-1 downto 0);
    mem_doutb      : out std_logic_vector(DATA_WIDTHB-1 downto 0)
  );
  end component;

  component axi_to_memory
  generic (
    ADDR_WIDTH    : integer := 15  -- address width (32 bits word)
  );
  port (
    -- ========= AXI
    s_axi_aclk     : in  std_logic;
    --
    s_axi_areset_n : in  std_logic;

    -- write interface
    s_axi_wi : in  axi3m_write_out_r;
    s_axi_wo : out axi3m_write_in_r;

    -- read interface
    s_axi_ri : in  axi3m_read_out_r;
    s_axi_ro : out axi3m_read_in_r;

    -- ========= block ram interface
    mem_addr      : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    mem_we        : out std_logic_vector( 3 downto 0);
    mem_din       : out std_logic_vector(31 downto 0);
    mem_dout      : in  std_logic_vector(31 downto 0)
  );
  end component;

  component axi_3x3_lut
  generic (
    DATA_WIDTH_OUT   : positive := 8  -- data width output (1 to 16)
  );
  port (
    -- ========= AXI
    s_axi_aclk     : in  std_logic;
    --
    s_axi_areset_n : in  std_logic;

    -- write interface
    s_axi_wi : in  axi3m_write_out_r;
    s_axi_wo : out axi3m_write_in_r;

    -- read interface
    s_axi_ri : in  axi3m_read_out_r;
    s_axi_ro : out axi3m_read_in_r;

    -- ========= video interface
    video_clk     : in  std_logic;
    lut0_in       : in  std_logic_vector(11 downto 0);
    lut0_out      : out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
    lut1_in       : in  std_logic_vector(11 downto 0);
    lut1_out      : out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
    lut2_in       : in  std_logic_vector(11 downto 0);
    lut2_out      : out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
    lut3_in       : in  std_logic_vector(11 downto 0);
    lut3_out      : out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
    lut4_in       : in  std_logic_vector(11 downto 0);
    lut4_out      : out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
    lut5_in       : in  std_logic_vector(11 downto 0);
    lut5_out      : out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
    lut6_in       : in  std_logic_vector(11 downto 0);
    lut6_out      : out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
    lut7_in       : in  std_logic_vector(11 downto 0);
    lut7_out      : out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
    lut8_in       : in  std_logic_vector(11 downto 0);
    lut8_out      : out std_logic_vector(DATA_WIDTH_OUT-1 downto 0)
  );
  end component;

  component axi_matrix
  port (
    -- ========= AXI
    s_axi_aclk     : in  std_logic;
    --
    s_axi_areset_n : in  std_logic;

    -- write interface
    s_axi_wi : in  axi3m_write_out_r;
    s_axi_wo : out axi3m_write_in_r;

    -- read interface
    s_axi_ri : in  axi3m_read_out_r;
    s_axi_ro : out axi3m_read_in_r;

    -- ========= video interface
    clk_in        : in  std_logic;
    valid_in      : in  std_logic;
    R_in          : in  std_logic_vector(11 downto 0);  -- unsigned
    G_in          : in  std_logic_vector(11 downto 0);  -- unsigned
    B_in          : in  std_logic_vector(11 downto 0);  -- unsigned

    clk_out       : out std_logic;
    valid_out     : out std_logic;
    R_out         : out std_logic_vector(11 downto 0);  -- unsigned
    G_out         : out std_logic_vector(11 downto 0);  -- unsinged
    B_out         : out std_logic_vector(11 downto 0)   -- unsigned
  );
  end component;

end pkg_axi_matrix;
