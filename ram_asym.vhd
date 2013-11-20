------------------------------------------------------------------------
--  ram_asym.vhd
--  wrapper for Xilinx RAM macro
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

-- for RAM
Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

entity ram_asym is
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
end entity;

architecture rtl of ram_asym is

constant gnd_8b      : std_logic_vector( 7 downto 0) := (others=>'0');

signal tmp8b1        : std_logic_vector( 7 downto 0);
signal tmp8b2        : std_logic_vector( 7 downto 0);

-- signal used only in the case data_width_out > 8
signal dia0          : std_logic_vector(15 downto 0);
signal dia1          : std_logic_vector(15 downto 0);
signal doa0          : std_logic_vector(15 downto 0);
signal doa1          : std_logic_vector(15 downto 0);

begin

-- if DATA_WIDTHB < 9 => 1 RAM36B : porta=32 bits, portb=8bits
-- if DATA_WIDTHB > 8 => 2 RAM36B : porta=16 bits, portb=8bits

gen0 :
if (DATA_WIDTHB > 0) and (DATA_WIDTHB < 9) generate

inst_ram0 : BRAM_TDP_MACRO
  generic map (
    BRAM_SIZE => "36Kb", -- Target BRAM, "18Kb" or "36Kb"
    DEVICE => "7SERIES", -- Target Device: "VIRTEX5", "VIRTEX6", "7SERIES", "SPARTAN6"
    DOA_REG => 0, -- Optional port A output register (0 or 1)
    DOB_REG => 0, -- Optional port B output register (0 or 1)
    INIT_A => X"000000000", -- Initial values on A output port
    INIT_B => X"000000000", -- Initial values on B output port
    INIT_FILE => "NONE",
    READ_WIDTH_A => 32,  -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
    READ_WIDTH_B => 8,  -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
    SIM_COLLISION_CHECK => "ALL", -- Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
    SRVAL_A => X"000000000",  -- Set/Reset value for A port output
    SRVAL_B => X"000000000",  -- Set/Reset value for B port output
    WRITE_MODE_A => "WRITE_FIRST", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
    WRITE_MODE_B => "WRITE_FIRST", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
    WRITE_WIDTH_A => 32, -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
    WRITE_WIDTH_B => 8  -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
  )
  port map (
    CLKA   => clka       , -- 1-bit input port-A clock
    DIA    => mem_dina   , -- Input port-A data, width defined by WRITE_WIDTH_A parameter
    DOA    => mem_douta  , -- Output port-A data, width defined by READ_WIDTH_A parameter
    ADDRA  => mem_addra  , -- Input port-A address, width defined by Port A depth
    ENA    => '1'        , -- 1-bit input port-A enable
    REGCEA => '1'        , -- 1-bit input port-A output register enable
    RSTA   => '0'        , -- 1-bit input port-A reset
    WEA    => mem_wea     , -- Input port-A write enable, width defined by Port A depth

    CLKB   => clkb       , -- 1-bit input port-B clock
    DIB    => gnd_8b     , -- Input port-B data, width defined by WRITE_WIDTH_B parameter
    DOB    => tmp8b1     , -- Output port-B data, width defined by READ_WIDTH_B parameter
    ADDRB  => mem_addrb  , -- Input port-B address, width defined by Port B depth
    ENB    => '1'        , -- 1-bit input port-B enable
    REGCEB => '1'        , -- 1-bit input port-B output register enable
    RSTB   => '0'        , -- 1-bit input port-B reset
    WEB    => "0"         -- Input port-B write enable, width defined by Port B depth
  );

mem_doutb <= tmp8b1(mem_doutb'length-1 downto 0);

end generate;

gen1 :
if (DATA_WIDTHB > 8) and (DATA_WIDTHB <17) generate

-- we split data as each memory contains 8bits of the 16 bits output
dia0 <= mem_dina(23 downto 16) & mem_dina( 7 downto 0);
dia1 <= mem_dina(31 downto 24) & mem_dina(15 downto 8);

mem_douta( 7 downto 0)  <= doa0( 7 downto 0);
mem_douta(15 downto 8)  <= doa1( 7 downto 0);
mem_douta(23 downto 16) <= doa0(15 downto 8);
mem_douta(31 downto 24) <= doa1(15 downto 8);

inst_ram0 : BRAM_TDP_MACRO
  generic map (
    BRAM_SIZE => "36Kb", -- Target BRAM, "18Kb" or "36Kb"
    DEVICE => "7SERIES", -- Target Device: "VIRTEX5", "VIRTEX6", "7SERIES", "SPARTAN6"
    DOA_REG => 0, -- Optional port A output register (0 or 1)
    DOB_REG => 0, -- Optional port B output register (0 or 1)
    INIT_A => X"000000000", -- Initial values on A output port
    INIT_B => X"000000000", -- Initial values on B output port
    INIT_FILE => "NONE",
    READ_WIDTH_A => 16,  -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
    READ_WIDTH_B => 8,  -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
    SIM_COLLISION_CHECK => "ALL", -- Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
    SRVAL_A => X"000000000",  -- Set/Reset value for A port output
    SRVAL_B => X"000000000",  -- Set/Reset value for B port output
    WRITE_MODE_A => "WRITE_FIRST", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
    WRITE_MODE_B => "WRITE_FIRST", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
    WRITE_WIDTH_A => 16, -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
    WRITE_WIDTH_B => 8  -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
  )
  port map (
    CLKA   => clka      , -- 1-bit input port-A clock
    DIA    => dia0      , -- Input port-A data, width defined by WRITE_WIDTH_A parameter
    DOA    => doa0      , -- Output port-A data, width defined by READ_WIDTH_A parameter
    ADDRA  => mem_addra , -- Input port-A address, width defined by Port A depth
    ENA    => '1'       , -- 1-bit input port-A enable
    REGCEA => '1'       , -- 1-bit input port-A output register enable
    RSTA   => '0'       , -- 1-bit input port-A reset
    WEA    => mem_wea( 1 downto 0), -- Input port-A write enable, width defined by Port A depth

    CLKB   => clkb      , -- 1-bit input port-B clock
    DIB    => gnd_8b    , -- Input port-B data, width defined by WRITE_WIDTH_B parameter
    DOB    => tmp8b1    , -- Output port-B data, width defined by READ_WIDTH_B parameter
    ADDRB  => mem_addrb , -- Input port-B address, width defined by Port B depth
    ENB    => '1'       , -- 1-bit input port-B enable
    REGCEB => '1'       , -- 1-bit input port-B output register enable
    RSTB   => '0'       , -- 1-bit input port-B reset
    WEB    => "0"         -- Input port-B write enable, width defined by Port B depth
  );

inst_ram1 : BRAM_TDP_MACRO
  generic map (
    BRAM_SIZE => "36Kb", -- Target BRAM, "18Kb" or "36Kb"
    DEVICE => "7SERIES", -- Target Device: "VIRTEX5", "VIRTEX6", "7SERIES", "SPARTAN6"
    DOA_REG => 0, -- Optional port A output register (0 or 1)
    DOB_REG => 0, -- Optional port B output register (0 or 1)
    INIT_A => X"000000000", -- Initial values on A output port
    INIT_B => X"000000000", -- Initial values on B output port
    INIT_FILE => "NONE",
    READ_WIDTH_A => 16,  -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
    READ_WIDTH_B => 8,  -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
    SIM_COLLISION_CHECK => "ALL", -- Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
    SRVAL_A => X"000000000",  -- Set/Reset value for A port output
    SRVAL_B => X"000000000",  -- Set/Reset value for B port output
    WRITE_MODE_A => "WRITE_FIRST", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
    WRITE_MODE_B => "WRITE_FIRST", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
    WRITE_WIDTH_A => 16, -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
    WRITE_WIDTH_B => 8  -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
  )
  port map (
    CLKA   => clka      , -- 1-bit input port-A clock
    DIA    => dia1      , -- Input port-A data, width defined by WRITE_WIDTH_A parameter
    DOA    => doa1      , -- Output port-A data, width defined by READ_WIDTH_A parameter
    ADDRA  => mem_addra , -- Input port-A address, width defined by Port A depth
    ENA    => '1'       , -- 1-bit input port-A enable
    REGCEA => '1'       , -- 1-bit input port-A output register enable
    RSTA   => '0'       , -- 1-bit input port-A reset
    WEA    => mem_wea( 3 downto 2), -- Input port-A write enable, width defined by Port A depth

    CLKB   => clkb      , -- 1-bit input port-B clock
    DIB    => gnd_8b    , -- Input port-B data, width defined by WRITE_WIDTH_B parameter
    DOB    => tmp8b2    , -- Output port-B data, width defined by READ_WIDTH_B parameter
    ADDRB  => mem_addrb , -- Input port-B address, width defined by Port B depth
    ENB    => '1'       , -- 1-bit input port-B enable
    REGCEB => '1'       , -- 1-bit input port-B output register enable
    RSTB   => '0'       , -- 1-bit input port-B reset
    WEB    => "0"         -- Input port-B write enable, width defined by Port B depth
  );

mem_doutb( 7 downto 0)                 <= tmp8b1;
mem_doutb(mem_doutb'length-1 downto 8) <= tmp8b2(mem_doutb'length-9 downto 0);

end generate;

end rtl;
