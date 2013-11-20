------------------------------------------------------------------------
--  pkg_tools_tb.vhd
--  some tools for testbench
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


package pkg_tools_tb is

   procedure display( msg_string : string;
                      header     : boolean := FALSE
                    );

end pkg_tools_tb;


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- PACKAGE BODY
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

package body pkg_tools_tb is


   procedure display( msg_string : string;
                      header     : boolean := FALSE
                    ) is
    variable ligne : LINE;
   begin

      if header then
         for i in 1 to 140 loop
            write(ligne, character'('-'));
         end loop;
         writeline(OUTPUT, ligne);
      end if;

      write(ligne, string'("   "));
      write(ligne, msg_string);
      writeline(OUTPUT, ligne);

      if header then
         for i in 1 to 140 loop
            write(ligne, character'('-'));
         end loop;
         writeline(OUTPUT, ligne);
      end if;

   end;

end pkg_tools_tb;
