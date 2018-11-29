library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.P65816_pkg.all;

entity AddSubBCD is
	port( 
		A		: in std_logic_vector(15 downto 0); 
		B		: in std_logic_vector(15 downto 0); 
		CI		: in std_logic;
		ADD	: in std_logic;
		BCD	: in std_logic; 
		w16	: in std_logic; 
		S		: out std_logic_vector(15 downto 0);
		CO		: out std_logic;
		VO	: out std_logic
    );
end AddSubBCD;

architecture rtl of AddSubBCD is

	signal tempB : std_logic_vector(15 downto 0);
	signal res : unsigned(15 downto 0);
	signal C7, C15, V7, V15 : std_logic;

begin
	
	tempB <= B when ADD = '1' else B xor x"FFFF";

	process(A, tempB, CI, ADD, BCD)
		variable temp0, temp1, temp2, temp3 : unsigned(6 downto 0);
		variable temp00, temp11, temp22, temp33 : std_logic_vector(6 downto 0);
		variable c0, c1, c2, c3 : std_logic;
	begin
		temp0 := ("000" & unsigned(A(3 downto 0))) + ("000" & unsigned(tempB(3 downto 0))) + ("000000" & CI);
		c0 := '0';
		if BCD = '1' then 
			if ADD = '1' then 
				if temp0 > 9 then
					temp00 := std_logic_vector(temp0 + 6);
				else
					temp00 := std_logic_vector(temp0);
				end if;
			else
				if temp0 <= 15 then
					temp00 := std_logic_vector(temp0 - 6);
				else
					temp00 := std_logic_vector(temp0);
				end if;
			end if;
		else
			temp00 := std_logic_vector(temp0);
		end if;
		if temp00(5 downto 4) /= "00" and temp00(6) = '0' then
			c0 := '1';
		end if;
		
		temp1 := ("000" & unsigned(A(7 downto 4))) + ("000" & unsigned(tempB(7 downto 4))) + ("000000" & c0);
		c1 := '0';
		V7 <= temp1(3);
		if BCD = '1' then 
			if ADD = '1' then 
				if temp1 > 9 then
					temp11 := std_logic_vector(temp1 + 6);
				else
					temp11 := std_logic_vector(temp1);
				end if;
			else
				if temp1 <= 15 then
					temp11 := std_logic_vector(temp1 - 6);
				else
					temp11 := std_logic_vector(temp1);
				end if;
			end if;
		else
			temp11 := std_logic_vector(temp1);
		end if;
		if temp11(5 downto 4) /= "00" and temp11(6) = '0' then
			c1 := '1';
		end if;
		
		temp2 := ("000" & unsigned(A(11 downto 8))) + ("000" & unsigned(tempB(11 downto 8))) + ("000000" & c1);
		c2 := '0';
		if BCD = '1' then 
			if ADD = '1' then 
				if temp2 > 9 then
					temp22 := std_logic_vector(temp2 + 6);
				else
					temp22 := std_logic_vector(temp2);
				end if;
			else
				if temp2 <= 15 then
					temp22 := std_logic_vector(temp2 - 6);
				else
					temp22 := std_logic_vector(temp2);
				end if;
			end if;
		else
			temp22 := std_logic_vector(temp2);
		end if;
		if temp22(5 downto 4) /= "00" and temp22(6) = '0' then
			c2 := '1';
		end if;
		
		temp3 := ("000" & unsigned(A(15 downto 12))) + ("000" & unsigned(tempB(15 downto 12))) + ("000000" & c2);
		c3 := '0';
		V15 <= temp3(3);
		if BCD = '1' then 
			if ADD = '1' then 
				if temp3 > 9 then
					temp33 := std_logic_vector(temp3 + 6);
				else
					temp33 := std_logic_vector(temp3);
				end if;
			else
				if temp3 <= 15 then
					temp33 := std_logic_vector(temp3 - 6);
				else
					temp33 := std_logic_vector(temp3);
				end if;
			end if;
		else
			temp33 := std_logic_vector(temp3);
		end if;
		if temp33(5 downto 4) /= "00" and temp33(6) = '0' then
			c3 := '1';
		end if;
		
		res <= temp3(3 downto 0) & temp2(3 downto 0) & temp1(3 downto 0) & temp0(3 downto 0);
		C7 <= c1;
		C15 <= c3;
	end process;
	
	S <= std_logic_vector(res);
	VO <= (not (A(7) xor tempB(7))) and (A(7) xor V7) when w16 = '0' else (not (A(15) xor tempB(15))) and (A(15) xor V15);
	CO <= C7 when w16 = '0' else C15;

end rtl;