------------------------------------------------------------------------
--  axi_to_memory.vhd
--  support only aligned access and don't mask bytes
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

entity axi_to_memory is
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
end entity;

architecture rtl of axi_to_memory is

type type_state_fsm is (IDLE, READ_REQ, WAIT1, WAIT2, SEND_DATA, WRITING, END_WRITING);
signal state_fsm : type_state_fsm := IDLE;

signal awready_i : std_logic;
signal wready_i  : std_logic;
signal bvalid_i  : std_logic;
signal rvalid_i  : std_logic;
signal arready   : std_logic;
signal rlast     : std_logic;
signal rdata     : std_logic_vector(s_axi_ro.rdata'length-1 downto 0);

signal rwid      : std_logic_vector(s_axi_ro.rid'length-1 downto 0);

signal arlen_u           : unsigned(s_axi_ri.arlen'length downto 0);
signal elements_to_read  : unsigned(s_axi_ri.arlen'length downto 0);
signal address_to_read   : unsigned(ADDR_WIDTH-1 downto 0);
signal address_to_write  : unsigned(ADDR_WIDTH-1 downto 0);

begin

arlen_u <= unsigned('0' & s_axi_ri.arlen);

s_axi_wo.awready <= awready_i;
s_axi_wo.wready  <= wready_i;
s_axi_wo.bvalid  <= bvalid_i;
s_axi_wo.bresp   <= "00";  -- status ok
s_axi_wo.bid     <= rwid;

s_axi_ro.rvalid  <= rvalid_i;
s_axi_ro.rresp   <= "00";  -- status ok
s_axi_ro.rid     <= rwid;
s_axi_ro.arready <= arready;
s_axi_ro.rlast   <= rlast;
s_axi_ro.rdata   <= rdata;


fsm_axi : process(s_axi_aclk)
  begin

    if rising_edge(s_axi_aclk) then

      if (s_axi_areset_n = '0') then

        state_fsm           <= IDLE;
        arready             <= '0';
        rlast               <= '0';
        rdata               <= (others=>'0');
        rvalid_i            <= '0';
        awready_i           <= '0';
        wready_i            <= '0';
        bvalid_i            <= '0';
        elements_to_read    <= (others=>'0');
        address_to_read     <= (others=>'0');
        address_to_write    <= (others=>'0');
        mem_we              <= (others=>'0');
        mem_din             <= (others=>'0');

      else

        case state_fsm is

          when IDLE =>
            rdata          <= (others=>'0');
            rvalid_i       <= '0';
            rlast          <= '0';
            arready        <= '1';
            mem_we         <= (others=>'0');
            wready_i       <= '0';
            bvalid_i       <= '0';
            mem_din        <= (others=>'0');

            if (s_axi_wi.awvalid = '1' and awready_i = '1') then
              state_fsm          <= WRITING;
              address_to_write   <= unsigned(s_axi_wi.awaddr(ADDR_WIDTH+1 downto 2));  -- byte address => 32 bits word address
              awready_i          <= '0';
              rwid               <= s_axi_wi.awid;
            elsif (s_axi_ri.arvalid = '1') then
              state_fsm          <= READ_REQ;
              address_to_read    <= unsigned(s_axi_ri.araddr(ADDR_WIDTH+1 downto 2));  -- byte address => 32 bits word address
              arready            <= '0';
              elements_to_read   <= arlen_u + 1;
              rwid               <= s_axi_ri.arid;
            else
              state_fsm <= IDLE;
              awready_i      <= '1';
              mem_addr       <= (others=>'0');
              arready        <= '1';
            end if;

          -- ============= reading management
          when READ_REQ =>
            mem_addr <= std_logic_vector(address_to_read);
            if (elements_to_read = 0) then  -- all words are read
              arready   <= '1';
              state_fsm <= IDLE;
            else
              state_fsm <= WAIT1;
            end if;

          when WAIT1 =>
            address_to_read  <= address_to_read + 1;
            elements_to_read <= elements_to_read - 1;
            state_fsm        <= SEND_DATA;

          when SEND_DATA =>
            mem_addr <= std_logic_vector(address_to_read);
            if (s_axi_ri.rready = '1' and rvalid_i = '1') then  -- it is sent
              rvalid_i    <= '0';
              state_fsm   <= READ_REQ;
              rdata       <= (others=>'0');
              rlast       <= '0';
            else                                       -- we send it
              rvalid_i    <= '1';
              rdata       <= mem_dout;
              state_fsm   <= SEND_DATA;
              if (elements_to_read = 0) then           -- last one
                rlast <= '1';
              else
                rlast <= '0';
              end if;
            end if;

          -- ============= writing management
          when WRITING =>
            mem_addr <= std_logic_vector(address_to_write);
            wready_i <= '1';
            if (s_axi_wi.wvalid = '1' and wready_i = '1') then
              address_to_write <= address_to_write + 1;
              mem_din          <= s_axi_wi.wdata;
              mem_we           <= (others=>'1');
              if (s_axi_wi.wlast = '1') then
                wready_i  <= '0';
                bvalid_i  <= '1';
                state_fsm <= END_WRITING;
              else
                state_fsm <= WRITING;
              end if;
            else
              state_fsm <= WRITING;
              mem_we    <= (others=>'0');
              mem_din   <= (others=>'0');
            end if;

          when END_WRITING =>
            mem_din  <= (others => '0');
            mem_addr <= std_logic_vector(address_to_write);
            mem_we   <= (others=>'0');
            if (s_axi_wi.bready = '1' and bvalid_i = '1') then
              bvalid_i  <= '0';
              state_fsm <= IDLE;
            else
              bvalid_i  <= '1';
              state_fsm <= END_WRITING;
            end if;


          when others =>
            state_fsm <= IDLE;

        end case;

      end if;  -- if m_axi_aresetn

    end if;  -- if m_axi_aclk

  end process fsm_axi;

end rtl;
