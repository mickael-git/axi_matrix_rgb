------------------------------------------------------------------------
--  pkg_axi_master_model.vhd
--  simple model for axi read and write
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
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

use work.axi3m_pkg.all;  -- axi records
use work.pkg_tools_tb.all;

package pkg_axi_master_model is

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  procedure single_write( signal clk      : in  std_logic;
                          signal m_axi_wi : in  axi3m_write_in_r;
                          signal m_axi_wo : out axi3m_write_out_r;
                          variable data   : in  std_logic_vector;
                          variable addr   : in  std_logic_vector
                        );

  procedure burst_write ( signal clk          : in  std_logic;
                          signal m_axi_wi     : in  axi3m_write_in_r;
                          signal m_axi_wo     : out axi3m_write_out_r;
                          data_file  : in string;
                          variable addr       : in  std_logic_vector
                        );

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  procedure single_read ( signal clk      : in  std_logic;
                          signal m_axi_ri : in  axi3m_read_in_r;
                          signal m_axi_ro : out axi3m_read_out_r;
                          variable data   : out std_logic_vector;
                          variable addr   : in  std_logic_vector
                        );

  procedure burst_read  ( signal clk          : in  std_logic;
                          signal m_axi_ri     : in  axi3m_read_in_r;
                          signal m_axi_ro     : out axi3m_read_out_r;
                          data_file  : in string;
                          variable addr       : in  std_logic_vector
                        );

end pkg_axi_master_model;

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- PACKAGE BODY
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

package body  pkg_axi_master_model  is

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ============================== single write
  procedure single_write( signal clk      : in  std_logic;
                          signal m_axi_wi : in  axi3m_write_in_r;
                          signal m_axi_wo : out axi3m_write_out_r;
                          variable data   : in  std_logic_vector;
                          variable addr   : in  std_logic_vector
                        ) is
  begin

    m_axi_wo.bready   <= '1';

    -- address
    m_axi_wo.awid     <= (others=>'0');
    m_axi_wo.awaddr   <= addr;
    m_axi_wo.awburst  <= (others=>'0');
    m_axi_wo.awlen    <= (others=>'0');
    m_axi_wo.awsize   <= std_logic_vector(to_unsigned(2, m_axi_wo.awsize'length));
    m_axi_wo.awprot   <= (others=>'U');
    m_axi_wo.awvalid  <= '1';
    wait until rising_edge(clk);
    while m_axi_wi.awready = '0' loop
      wait until rising_edge(clk);
    end loop;
    m_axi_wo.awaddr   <= (others=>'0');
    m_axi_wo.awvalid  <= '0';
    -- data
    m_axi_wo.wid      <= (others=>'0');
    m_axi_wo.wdata    <= data;
    m_axi_wo.wstrb    <= (others=>'1');
    m_axi_wo.wlast    <= '1';
    m_axi_wo.wvalid   <= '1';
    wait until rising_edge(clk);
    while m_axi_wi.wready = '0' loop
      wait until rising_edge(clk);
    end loop;
    m_axi_wo.wlast    <= '0';
    m_axi_wo.wvalid   <= '0';

    wait until m_axi_wi.bvalid = '1';
    wait until rising_edge(clk);

    m_axi_wo.bready   <= '0';

  end;

-- ============================== burst write
  procedure burst_write ( signal clk          : in  std_logic;
                          signal m_axi_wi     : in  axi3m_write_in_r;
                          signal m_axi_wo     : out axi3m_write_out_r;
                          data_file  : in string;
                          variable addr       : in  std_logic_vector
                        ) is
    file line_txt            : text open read_mode is data_file;
    variable file_line       : line;
    variable nb_value        : integer := 0;
    variable count           : integer := 0;
    variable data            : integer := 0;
  begin

    readline(line_txt, file_line);  -- comment line
    readline(line_txt, file_line);  -- size line
    read(file_line, nb_value);

    readline(line_txt, file_line);  -- empty line

    m_axi_wo.bready   <= '1';

    -- address
    m_axi_wo.awid     <= (others=>'0');
    m_axi_wo.awaddr   <= addr;
    m_axi_wo.awburst  <= (others=>'0');
    m_axi_wo.awlen    <= std_logic_vector(to_unsigned(nb_value-1, m_axi_wo.awlen'length));
    m_axi_wo.awsize   <= std_logic_vector(to_unsigned(2, m_axi_wo.awsize'length));
    m_axi_wo.awprot   <= (others=>'U');
    m_axi_wo.awvalid  <= '1';
    wait until rising_edge(clk);
    while m_axi_wi.awready = '0' loop
      wait until rising_edge(clk);
    end loop;
    m_axi_wo.awaddr   <= (others=>'0');
    m_axi_wo.awvalid  <= '0';

    -- data
    count := 0;
    while (not endfile(line_txt)) loop

      readline(line_txt, file_line);
      read(file_line, data);

      m_axi_wo.wid      <= (others=>'0');
      m_axi_wo.wdata    <= std_logic_vector(to_unsigned(data, m_axi_wo.wdata'length));
      m_axi_wo.wstrb    <= (others=>'1');
      m_axi_wo.wvalid   <= '1';
      if (count = nb_value-1) then
        m_axi_wo.wlast    <= '1';
      else
        m_axi_wo.wlast   <= '0';
      end if;
      wait until rising_edge(clk);
      while m_axi_wi.wready = '0' loop
        wait until rising_edge(clk);
      end loop;
      m_axi_wo.wlast    <= '0';
      m_axi_wo.wvalid   <= '0';

      count := count + 1;

    end loop;

    wait until m_axi_wi.bvalid = '1';
    wait until rising_edge(clk);

    m_axi_wo.bready   <= '0';

  end;

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ============================== single read
  procedure single_read ( signal clk      : in  std_logic;
                          signal m_axi_ri : in  axi3m_read_in_r;
                          signal m_axi_ro : out axi3m_read_out_r;
                          variable data   : out std_logic_vector;
                          variable addr   : in  std_logic_vector
                        ) is
  begin

    m_axi_ro.rready   <= '1';

    -- address
    m_axi_ro.arid     <= (others=>'0');
    m_axi_ro.araddr   <= addr;
    m_axi_ro.arburst  <= (others=>'0');
    m_axi_ro.arlen    <= (others=>'0');
    m_axi_ro.arsize   <= std_logic_vector(to_unsigned(2, m_axi_ro.arsize'length));
    m_axi_ro.arprot   <= (others=>'U');
    m_axi_ro.arvalid  <= '1';
    wait until rising_edge(clk);
    while m_axi_ri.arready = '0' loop
      wait until rising_edge(clk);
    end loop;
    m_axi_ro.araddr   <= (others=>'0');
    m_axi_ro.arvalid  <= '0';
    -- data
    wait until m_axi_ri.rvalid = '1';
    data := m_axi_ri.rdata;

    wait until rising_edge(clk);
    m_axi_ro.rready   <= '0';

  end;

-- ============================== burst read
  procedure burst_read  ( signal clk          : in  std_logic;
                          signal m_axi_ri     : in  axi3m_read_in_r;
                          signal m_axi_ro     : out axi3m_read_out_r;
                          data_file  : in string;
                          variable addr       : in  std_logic_vector
                        ) is
  file line_txt            : text open read_mode is data_file;
    variable file_line       : line;
    variable nb_value        : integer := 0;
    variable count           : integer := 0;
    variable data            : integer := 0;
  begin

    readline(line_txt, file_line);  -- comment line
    readline(line_txt, file_line);  -- size line
    read(file_line, nb_value);

    readline(line_txt, file_line);  -- empty line

    m_axi_ro.rready   <= '1';

    -- address
    m_axi_ro.arid     <= (others=>'0');
    m_axi_ro.araddr   <= addr;
    m_axi_ro.arburst  <= (others=>'0');
    m_axi_ro.arlen    <= std_logic_vector(to_unsigned(nb_value-1, m_axi_ro.arlen'length));
    m_axi_ro.arsize   <= std_logic_vector(to_unsigned(2, m_axi_ro.arsize'length));
    m_axi_ro.arprot   <= (others=>'U');
    m_axi_ro.arvalid  <= '1';
    wait until rising_edge(clk);
    while m_axi_ri.arready = '0' loop
      wait until rising_edge(clk);
    end loop;
    m_axi_ro.araddr   <= (others=>'0');
    m_axi_ro.arvalid  <= '0';

    -- data
    count := 0;
    while m_axi_ri.rlast = '0' loop
      if (m_axi_ri.rvalid = '1') then
        if (not endfile(line_txt)) then
          readline(line_txt, file_line);
          read(file_line, data);
          if (m_axi_ri.rdata /= std_logic_vector(to_unsigned(data, m_axi_ri.rdata'length))) then
            display("Error during comparison for value nb: " & integer'image(count));
          end if;
        end if;
        count := count + 1;
      end if;
      wait until rising_edge(clk);
    end loop;

    -- check last value
    if (m_axi_ri.rvalid = '1') then
      if (not endfile(line_txt)) then
        readline(line_txt, file_line);
        read(file_line, data);
        if (m_axi_ri.rdata /= std_logic_vector(to_unsigned(data, m_axi_ri.rdata'length))) then
          display("Error during comparison for value nb: " & integer'image(count));
        end if;
      end if;
    end if;

    wait until rising_edge(clk);
    m_axi_ro.rready   <= '0';

  end;

end pkg_axi_master_model;
