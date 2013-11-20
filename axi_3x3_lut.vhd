------------------------------------------------------------------------
--  axi_3x3_lut.vhd
--  9 lut
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
use ieee.numeric_std.all;

use work.pkg_axi_matrix.all;  -- components

use work.axi3m_pkg.all;  -- axi records

entity axi_3x3_lut is
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
end entity;

architecture rtl of axi_3x3_lut is

function log2(val: natural) return natural is
  variable res : natural;
begin
  for i in 30 downto 0 loop
    if (val > (2**i)) then
      res := i;
      exit;
    end if;
  end loop;
  return (res + 1);
end function log2;

constant DATA_WIDTH_IN   : natural := lut0_in'length;
-- compute address width of memory = DATA_WIDTH_IN + log2(DATA_WIDTH_OUT) - ln2(32)
constant ADDR_WIDTH      : natural := DATA_WIDTH_IN + log2(DATA_WIDTH_OUT) - 5 + 4;

signal mem_addr      : std_logic_vector(ADDR_WIDTH-1 downto 0);
signal mem_we        : std_logic_vector( 3 downto 0);
signal mem_din       : std_logic_vector(31 downto 0);
signal mem_dout      : std_logic_vector(31 downto 0);

signal addr          : std_logic_vector(ADDR_WIDTH-1-4 downto 0);

signal mem_dout0     : std_logic_vector(mem_dout'range);
signal mem_dout1     : std_logic_vector(mem_dout'range);
signal mem_dout2     : std_logic_vector(mem_dout'range);
signal mem_dout3     : std_logic_vector(mem_dout'range);
signal mem_dout4     : std_logic_vector(mem_dout'range);
signal mem_dout5     : std_logic_vector(mem_dout'range);
signal mem_dout6     : std_logic_vector(mem_dout'range);
signal mem_dout7     : std_logic_vector(mem_dout'range);
signal mem_dout8     : std_logic_vector(mem_dout'range);

signal mem_wea0      : std_logic_vector( 3 downto 0);
signal mem_wea1      : std_logic_vector( 3 downto 0);
signal mem_wea2      : std_logic_vector( 3 downto 0);
signal mem_wea3      : std_logic_vector( 3 downto 0);
signal mem_wea4      : std_logic_vector( 3 downto 0);
signal mem_wea5      : std_logic_vector( 3 downto 0);
signal mem_wea6      : std_logic_vector( 3 downto 0);
signal mem_wea7      : std_logic_vector( 3 downto 0);
signal mem_wea8      : std_logic_vector( 3 downto 0);

alias sel_mem        : std_logic_vector( 3 downto 0) is mem_addr(ADDR_WIDTH-1 downto ADDR_WIDTH-1-3);

begin


axi_to_mem0 : axi_to_memory
  generic map (
    ADDR_WIDTH    => ADDR_WIDTH
  )
  port map (
    s_axi_aclk     => s_axi_aclk,

    s_axi_areset_n => s_axi_areset_n,

    s_axi_wi       => s_axi_wi,
    s_axi_wo       => s_axi_wo,

    s_axi_ri       => s_axi_ri,
    s_axi_ro       => s_axi_ro,

    mem_addr       => mem_addr,
    mem_we         => mem_we  ,
    mem_din        => mem_din ,
    mem_dout       => mem_dout
  );

  process(sel_mem, mem_dout0, mem_dout1, mem_dout2, mem_dout3,
          mem_dout4, mem_dout5, mem_dout6, mem_dout7)
  begin
    case sel_mem is
      when "0001"  => mem_dout <= mem_dout1;
      when "0010"  => mem_dout <= mem_dout2;
      when "0011"  => mem_dout <= mem_dout3;
      when "0100"  => mem_dout <= mem_dout4;
      when "0101"  => mem_dout <= mem_dout5;
      when "0110"  => mem_dout <= mem_dout6;
      when "0111"  => mem_dout <= mem_dout7;
      when "1000"  => mem_dout <= mem_dout8;
      when others  => mem_dout <= mem_dout0;
    end case;
  end process;

mem_wea0 <= mem_we when sel_mem="0000" else (others=>'0');
mem_wea1 <= mem_we when sel_mem="0001" else (others=>'0');
mem_wea2 <= mem_we when sel_mem="0010" else (others=>'0');
mem_wea3 <= mem_we when sel_mem="0011" else (others=>'0');
mem_wea4 <= mem_we when sel_mem="0100" else (others=>'0');
mem_wea5 <= mem_we when sel_mem="0101" else (others=>'0');
mem_wea6 <= mem_we when sel_mem="0110" else (others=>'0');
mem_wea7 <= mem_we when sel_mem="0111" else (others=>'0');
mem_wea8 <= mem_we when sel_mem="1000" else (others=>'0');

addr <= mem_addr(ADDR_WIDTH-1-4 downto 0);

lut0: ram_asym
  generic map (
    ADDR_WIDTHA    => ADDR_WIDTH-4   ,
    ADDR_WIDTHB    => DATA_WIDTH_IN  ,
    DATA_WIDTHB    => DATA_WIDTH_OUT
  )
  port map (
    clka           => s_axi_aclk ,
    mem_addra      => addr       ,
    mem_wea        => mem_wea0   ,
    mem_dina       => mem_din    ,
    mem_douta      => mem_dout0  ,
    --
    clkb           => video_clk  ,
    mem_addrb      => lut0_in    ,
    mem_doutb      => lut0_out
  );

lut1: ram_asym
  generic map (
    ADDR_WIDTHA    => ADDR_WIDTH-4   ,
    ADDR_WIDTHB    => DATA_WIDTH_IN  ,
    DATA_WIDTHB    => DATA_WIDTH_OUT
  )
  port map (
    clka           => s_axi_aclk ,
    mem_addra      => addr       ,
    mem_wea        => mem_wea1   ,
    mem_dina       => mem_din    ,
    mem_douta      => mem_dout1  ,
    --
    clkb           => video_clk  ,
    mem_addrb      => lut1_in    ,
    mem_doutb      => lut1_out
  );

lut2: ram_asym
  generic map (
    ADDR_WIDTHA    => ADDR_WIDTH-4   ,
    ADDR_WIDTHB    => DATA_WIDTH_IN  ,
    DATA_WIDTHB    => DATA_WIDTH_OUT
  )
  port map (
    clka           => s_axi_aclk ,
    mem_addra      => addr       ,
    mem_wea        => mem_wea2   ,
    mem_dina       => mem_din    ,
    mem_douta      => mem_dout2  ,
    --
    clkb           => video_clk  ,
    mem_addrb      => lut2_in    ,
    mem_doutb      => lut2_out
  );

lut3: ram_asym
  generic map (
    ADDR_WIDTHA    => ADDR_WIDTH-4   ,
    ADDR_WIDTHB    => DATA_WIDTH_IN  ,
    DATA_WIDTHB    => DATA_WIDTH_OUT
  )
  port map (
    clka           => s_axi_aclk ,
    mem_addra      => addr       ,
    mem_wea        => mem_wea3   ,
    mem_dina       => mem_din    ,
    mem_douta      => mem_dout3  ,
    --
    clkb           => video_clk  ,
    mem_addrb      => lut3_in    ,
    mem_doutb      => lut3_out
  );

lut4: ram_asym
  generic map (
    ADDR_WIDTHA    => ADDR_WIDTH-4   ,
    ADDR_WIDTHB    => DATA_WIDTH_IN  ,
    DATA_WIDTHB    => DATA_WIDTH_OUT
  )
  port map (
    clka           => s_axi_aclk ,
    mem_addra      => addr       ,
    mem_wea        => mem_wea4   ,
    mem_dina       => mem_din    ,
    mem_douta      => mem_dout4  ,
    --
    clkb           => video_clk  ,
    mem_addrb      => lut4_in    ,
    mem_doutb      => lut4_out
  );

lut5: ram_asym
  generic map (
    ADDR_WIDTHA    => ADDR_WIDTH-4   ,
    ADDR_WIDTHB    => DATA_WIDTH_IN  ,
    DATA_WIDTHB    => DATA_WIDTH_OUT
  )
  port map (
    clka           => s_axi_aclk ,
    mem_addra      => addr       ,
    mem_wea        => mem_wea5   ,
    mem_dina       => mem_din    ,
    mem_douta      => mem_dout5  ,
    --
    clkb           => video_clk  ,
    mem_addrb      => lut5_in    ,
    mem_doutb      => lut5_out
  );

lut6: ram_asym
  generic map (
    ADDR_WIDTHA    => ADDR_WIDTH-4   ,
    ADDR_WIDTHB    => DATA_WIDTH_IN  ,
    DATA_WIDTHB    => DATA_WIDTH_OUT
  )
  port map (
    clka           => s_axi_aclk ,
    mem_addra      => addr       ,
    mem_wea        => mem_wea6   ,
    mem_dina       => mem_din    ,
    mem_douta      => mem_dout6  ,
    --
    clkb           => video_clk  ,
    mem_addrb      => lut6_in    ,
    mem_doutb      => lut6_out
  );

lut7: ram_asym
  generic map (
    ADDR_WIDTHA    => ADDR_WIDTH-4   ,
    ADDR_WIDTHB    => DATA_WIDTH_IN  ,
    DATA_WIDTHB    => DATA_WIDTH_OUT
  )
  port map (
    clka           => s_axi_aclk ,
    mem_addra      => addr       ,
    mem_wea        => mem_wea7   ,
    mem_dina       => mem_din    ,
    mem_douta      => mem_dout7  ,
    --
    clkb           => video_clk  ,
    mem_addrb      => lut7_in    ,
    mem_doutb      => lut7_out
  );

lut8: ram_asym
  generic map (
    ADDR_WIDTHA    => ADDR_WIDTH-4   ,
    ADDR_WIDTHB    => DATA_WIDTH_IN  ,
    DATA_WIDTHB    => DATA_WIDTH_OUT
  )
  port map (
    clka           => s_axi_aclk ,
    mem_addra      => addr       ,
    mem_wea        => mem_wea8   ,
    mem_dina       => mem_din    ,
    mem_douta      => mem_dout8  ,
    --
    clkb           => video_clk  ,
    mem_addrb      => lut8_in    ,
    mem_doutb      => lut8_out
  );

end rtl;
