library ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spram is
        generic (
                addr_width    : integer := 8;
                data_width    : integer := 8;
                mem_init_file : string := " "
        );
        PORT
        (
                clock                   : in  STD_LOGIC;

                address       : in  STD_LOGIC_VECTOR (addr_width-1 DOWNTO 0);
                data          : in  STD_LOGIC_VECTOR (data_width-1 DOWNTO 0) := (others => '0');
                enable               : in  STD_LOGIC := '1';
                wren          : in  STD_LOGIC := '0';
                q                     : out STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
                cs       : in  std_logic := '1'
        );
end entity;

architecture arch of spram is

type ram_type is array(natural range ((2**addr_width)-1) downto 0) of std_logic_vector(data_width-1 downto 0);
signal ram : ram_type;

begin

-- Port A
process (clock)
begin
	if (clock'event and clock = '1') then
		if enable='1' and cs='1' then
			if wren='1' then
				ram(to_integer(unsigned(address))) <= data;
				--q <= data;
			--else
                        end if;
				q <= ram(to_integer(unsigned(address)));
			--end if;
		end if;
	end if;
end process;



end architecture;
