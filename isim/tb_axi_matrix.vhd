------------------------------------------------------------------------
--  tb_axi_matrix.vhd
--  testbench
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

use work.axi3m_pkg.all;  -- axi records

use work.pkg_axi_matrix.all;
use work.pkg_axi_master_model.all;
use work.pkg_tools_tb.all;

entity testbench is
end entity;

architecture tb of testbench is

constant DATA_WIDTH_IN  : positive := 12;  -- cannot be changed

signal s_axi_wo : axi3m_write_in_r;
signal s_axi_wi : axi3m_write_out_r;

signal s_axi_ro : axi3m_read_in_r;
signal s_axi_ri : axi3m_read_out_r;

signal axi_clk          : std_logic := '0';
signal axi_resetn       : std_logic := '1';

signal end_init         : std_logic := '0';

signal video_clk        : std_logic := '0';
signal video_in         : std_logic_vector(DATA_WIDTH_IN-1  downto 0);
signal valid_in         : std_logic := '0';

signal valid_out        : std_logic;
signal R_out            : std_logic_vector(DATA_WIDTH_IN-1  downto 0);
signal G_out            : std_logic_vector(DATA_WIDTH_IN-1  downto 0);
signal B_out            : std_logic_vector(DATA_WIDTH_IN-1  downto 0);

  procedure waiting(signal clk : std_logic; nb : integer) is
  begin
    for i in 1 to nb loop
      wait until rising_edge(clk);
    end loop;
  end;

begin

axi_clk <= not(axi_clk) after 10 ns;

video_clk <= not(video_clk) after 5 ns;

-- AXI tests
process
  variable data   : std_logic_vector(31 downto 0);
  variable addr   : std_logic_vector(31 downto 0);
begin
  axi_resetn <= '0';
  waiting(axi_clk, 5);
  axi_resetn <= '1';

  -- Rr
  display(string'("Burst Write ..."));
  addr := std_logic_vector(to_unsigned(0, addr'length));
  burst_write(axi_clk, s_axi_wo, s_axi_wi, "./data.txt", addr);

  display(string'("Burst Read ..."));
  addr := std_logic_vector(to_unsigned(0, addr'length));
  burst_read(axi_clk, s_axi_ro, s_axi_ri, "./check.txt", addr);

  -- Gg
  addr := std_logic_vector(to_unsigned(4*8192, addr'length));
  burst_write(axi_clk, s_axi_wo, s_axi_wi, "./data2.txt", addr);

  -- Bb
  addr := std_logic_vector(to_unsigned(8*8192, addr'length));
  burst_write(axi_clk, s_axi_wo, s_axi_wi, "./data3.txt", addr);

  end_init <= '1';

  wait for 50 us;

  display("End of simulation");
  wait  for 50 ns;

  report "End of test (this is not a failure)"
    severity failure;
  wait;
end process;

-- data through LUT
process
  variable count  : integer;
begin

  count := 0;
  wait until end_init = '1';

  wait until rising_edge(video_clk);

  valid_in <= '1';
  for i in 0 to 4095 loop
    video_in <= std_logic_vector(to_unsigned(count, video_in'length));
    wait until rising_edge(video_clk);
    count := count + 1;
  end loop;

  wait;
end process;


-- /////////////////////////////////////////////////////////////////////

uut0 : axi_matrix
  port map (
    -- ========= AXI
    s_axi_aclk      => axi_clk,
    --
    s_axi_areset_n  => axi_resetn,

    -- write interface
    s_axi_wi => s_axi_wi,
    s_axi_wo => s_axi_wo,

    -- read interface
    s_axi_ri => s_axi_ri,
    s_axi_ro => s_axi_ro,

    -- ========= video interface
    clk_in        => video_clk,
    valid_in      => valid_in,
    R_in          => video_in,
    G_in          => video_in,
    B_in          => video_in,

    clk_out       => open,
    valid_out     => valid_out,
    R_out         => R_out,
    G_out         => G_out,
    B_out         => B_out
  );

end tb;
