------------------------------------------------------------------------
--  axi_matrix.vhd
--  latency = 3 clk
--
--  Copyright (C) 2013 M.FORET
--
--  This program is free software: you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation, either version
--  2 of the License, or (at your option) any later version.
------------------------------------------------------------------------

-- Apply 3 LUT on each input component
-- LUT 12b unsinged in -> 15b (±12.2) signed out
-- Rr = LUTa(R_in); Rg = LUTb(R_in); Rb = LUTc(R_in)
-- R_out = Rr + Rg + Rb
-- Take integer part and 
-- then test R_out with condition < 0 => = 0; > 2^12-1 => = 2^12-1

-- Addresses of LUTs (byte address)
-- Rr : 0*8192 = 0
-- Rg : 1*8192 = 0x2000
-- Rb : 2*8192 = 0x4000
-- Gr : 3*8192 = 0x6000
-- Gg : 4*8192 = 0x8000
-- Gb : 5*8192 = 0xA000
-- Br : 6*8192 = 0xC000
-- Bg : 7*8192 = 0xE000
-- Bb : 8*8192 = 0x10000

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_axi_matrix.all;  -- components

use work.axi3m_pkg.all;  -- axi records

entity axi_matrix is
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
end entity;

architecture rtl of axi_matrix is

constant DATA_WIDTH_IN     : positive := R_in'length;
constant DATA_WIDTH_OUT    : positive := 15;  -- ±12.2

signal Rr    : std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
signal Rg    : std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
signal Rb    : std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
signal Gr    : std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
signal Gg    : std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
signal Gb    : std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
signal Br    : std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
signal Bg    : std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
signal Bb    : std_logic_vector(DATA_WIDTH_OUT-1 downto 0);

signal sum_r : signed(DATA_WIDTH_OUT-1 downto 0);
signal sum_g : signed(DATA_WIDTH_OUT-1 downto 0);
signal sum_b : signed(DATA_WIDTH_OUT-1 downto 0);

signal valid_delay : std_logic_vector( 2 downto 0);
signal R_out_i     : std_logic_vector(R_out'range);
signal G_out_i     : std_logic_vector(G_out'range);
signal B_out_i     : std_logic_vector(B_out'range);

begin

matrix0 : axi_3x3_lut
  generic map (
    DATA_WIDTH_OUT  => DATA_WIDTH_OUT
  )
  port map (
    -- ========= AXI
    s_axi_aclk     => s_axi_aclk,
    --
    s_axi_areset_n => s_axi_areset_n,

    -- write interface
    s_axi_wi => s_axi_wi,
    s_axi_wo => s_axi_wo,

    -- read interface
    s_axi_ri => s_axi_ri,
    s_axi_ro => s_axi_ro,

    -- ========= video interface
    video_clk     => clk_in,
    lut0_in       => R_in,
    lut1_in       => G_in,
    lut2_in       => B_in,
    lut3_in       => R_in,
    lut4_in       => G_in,
    lut5_in       => B_in,
    lut6_in       => R_in,
    lut7_in       => G_in,
    lut8_in       => B_in,
    lut0_out      => Rr,
    lut1_out      => Rg,
    lut2_out      => Rb,
    lut3_out      => Gr,
    lut4_out      => Gg,
    lut5_out      => Gb,
    lut6_out      => Br,
    lut7_out      => Bg,
    lut8_out      => Bb
  );

-- sum of each component
  process(clk_in)
    variable sum_r_tmp : signed(DATA_WIDTH_OUT+1 downto 0);
    variable sum_g_tmp : signed(DATA_WIDTH_OUT+1 downto 0);
    variable sum_b_tmp : signed(DATA_WIDTH_OUT+1 downto 0);
  begin
    if rising_edge(clk_in) then
      sum_r_tmp := resize(signed(Rr), sum_r_tmp'length) + signed(Rg) + signed(Rb);
      sum_g_tmp := resize(signed(Gr), sum_g_tmp'length) + signed(Gg) + signed(Gb);
      sum_b_tmp := resize(signed(Br), sum_b_tmp'length) + signed(Bg) + signed(Bb);
      -- keep only integer part
      sum_r <= sum_r_tmp(sum_r_tmp'high downto 2);
      sum_g <= sum_g_tmp(sum_g_tmp'high downto 2);
      sum_b <= sum_b_tmp(sum_b_tmp'high downto 2);
    end if;
  end process;

-- test if < 0 or > max value
  process(clk_in)
  begin
    if rising_edge(clk_in) then
      if sum_r < 0 then
        R_out_i <= (others=>'0');
      elsif sum_r > 2**DATA_WIDTH_IN-1 then
        R_out_i <= std_logic_vector(to_unsigned(2**DATA_WIDTH_IN-1, R_out'length));
      else
        R_out_i <= std_logic_vector(sum_r(R_out'range));
      end if;
    end if;
  end process;

  process(clk_in)
  begin
    if rising_edge(clk_in) then
      if sum_g < 0 then
        G_out_i <= (others=>'0');
      elsif sum_g > 2**DATA_WIDTH_IN-1 then
        G_out_i <= std_logic_vector(to_unsigned(2**DATA_WIDTH_IN-1, G_out'length));
      else
        G_out_i <= std_logic_vector(sum_g(G_out'range));
      end if;
    end if;
  end process;

  process(clk_in)
  begin
    if rising_edge(clk_in) then
      if sum_b < 0 then
        B_out_i <= (others=>'0');
      elsif sum_b > 2**DATA_WIDTH_IN-1 then
        B_out_i <= std_logic_vector(to_unsigned(2**DATA_WIDTH_IN-1, B_out'length));
      else
        B_out_i <= std_logic_vector(sum_b(B_out'range));
      end if;
    end if;
  end process;

-- delay for valid
  process(clk_in)
  begin
    if rising_edge(clk_in) then
      valid_delay <= valid_delay(valid_delay'high-1 downto 0) & valid_in;
    end if;
  end process;

clk_out   <= clk_in;
valid_out <= valid_delay(valid_delay'high);
R_out     <= R_out_i;
G_out     <= G_out_i;
B_out     <= B_out_i;

end rtl;
