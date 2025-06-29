library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    Port (
        clk       : in  std_logic;            -- System clock
        reset     : in  std_logic;            -- Async reset
        data_in   : in  std_logic_vector(7 downto 0);  -- Byte to send
        start_tx  : in  std_logic;            -- Trigger transmission
        tx        : out std_logic;            -- Serial output
        busy      : out std_logic             -- TX busy indicator
    );
end uart_tx;

architecture Behavioral of uart_tx is
    constant CLK_FREQ   : integer := 50_000_000;  -- 50 MHz
    constant BAUD_RATE  : integer := 9600;
    constant TICKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;

    type state_type is (IDLE, START, DATA, PARITY, STOP);
    signal state       : state_type := IDLE;

    signal baud_cnt    : integer range 0 to TICKS_PER_BIT-1 := 0;
    signal bit_cnt     : integer range 0 to 7 := 0;

    signal tx_shift    : std_logic_vector(7 downto 0);
    signal tx_bit      : std_logic := '1';
    signal parity_bit  : std_logic := '0';

begin
    tx <= tx_bit;
    busy <= '1' when state /= IDLE else '0';

    process(clk, reset)
    begin
        if reset = '1' then
            state      <= IDLE;
            tx_bit     <= '1';
            baud_cnt   <= 0;
            bit_cnt    <= 0;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    tx_bit <= '1';
                    if start_tx = '1' then
                        tx_shift   <= data_in;
                        parity_bit <= even_parity(data_in);
                        baud_cnt   <= 0;
                        state      <= START;
                    end if;

                when START =>
                    tx_bit <= '0';
                    if baud_cnt = TICKS_PER_BIT - 1 then
                        baud_cnt <= 0;
                        bit_cnt  <= 0;
                        state    <= DATA;
                    else
                        baud_cnt <= baud_cnt + 1;
                    end if;

                when DATA =>
                    tx_bit <= tx_shift(bit_cnt);
                    if baud_cnt = TICKS_PER_BIT - 1 then
                        baud_cnt <= 0;
                        if bit_cnt = 7 then
                            state <= PARITY;
                        else
                            bit_cnt <= bit_cnt + 1;
                        end if;
                    else
                        baud_cnt <= baud_cnt + 1;
                    end if;

                when PARITY =>
                    tx_bit <= parity_bit;
                    if baud_cnt = TICKS_PER_BIT - 1 then
                        baud_cnt <= 0;
                        state    <= STOP;
                    else
                        baud_cnt <= baud_cnt + 1;
                    end if;

                when STOP =>
                    tx_bit <= '1';
                    if baud_cnt = TICKS_PER_BIT - 1 then
                        baud_cnt <= 0;
                        state    <= IDLE;
                    else
                        baud_cnt <= baud_cnt + 1;
                    end if;

            end case;
        end if;
    end process;

    -- Function to compute even parity
    function even_parity(data : std_logic_vector(7 downto 0)) return std_logic is
        variable ones : integer := 0;
    begin
        for i in data'range loop
            if data(i) = '1' then
                ones := ones + 1;
            end if;
        end loop;
        if (ones mod 2) = 0 then
            return '0'; -- Even number of ones, parity bit = 0
        else
            return '1'; -- Odd number of ones, parity bit = 1
        end if;
    end function;
    
end Behavioral;
