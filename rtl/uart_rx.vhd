-- uart_rx.vhd
-- UART Receiver with 16x oversampling and shift register storage

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
    Port (
        clk        : in  std_logic;  -- System clock
        rst        : in  std_logic;  -- Asynchronous reset
        rx         : in  std_logic;  -- UART RX line
        data_out   : out std_logic_vector(7 downto 0); -- Received byte
        data_valid : out std_logic  -- High when valid byte is available
    );
end uart_rx;

architecture Behavioral of uart_rx is
    constant BAUD_RATE      : integer := 9600;
    constant OVERSAMPLE     : integer := 16;
    constant CLK_FREQ       : integer := 50_000_000; -- Example: 50 MHz system clock
    constant SAMPLE_TICKS   : integer := CLK_FREQ / (BAUD_RATE * OVERSAMPLE);

    type state_type is (IDLE, START, DATA, PARITY, STOP);
    signal state         : state_type := IDLE;
    signal bit_cnt       : integer range 0 to 7 := 0;
    signal clk_cnt       : integer := 0;
    signal sample_cnt    : integer range 0 to OVERSAMPLE-1 := 0;
    signal shift_reg     : std_logic_vector(7 downto 0) := (others => '0');
    signal sampled_bit   : std_logic := '1';
    signal parity_bit    : std_logic := '0';
    signal rx_sync       : std_logic_vector(1 downto 0) := (others => '1');

begin
    -- Synchronize RX line to clk
    process(clk)
    begin
        if rising_edge(clk) then
            rx_sync <= rx_sync(0) & rx;
        end if;
    end process;

    -- UART Receiver process
    process(clk, rst)
    begin
        if rst = '1' then
            state       <= IDLE;
            bit_cnt     <= 0;
            clk_cnt     <= 0;
            sample_cnt  <= 0;
            shift_reg   <= (others => '0');
            data_out    <= (others => '0');
            data_valid  <= '0';
        elsif rising_edge(clk) then
            data_valid <= '0'; -- Default low
            case state is
                when IDLE =>
                    if rx_sync(1) = '0' then -- Detected start bit
                        clk_cnt <= SAMPLE_TICKS / 2; -- Middle of start bit
                        state   <= START;
                    end if;

                when START =>
                    if clk_cnt = 0 then
                        if rx_sync(1) = '0' then -- Confirm valid start bit
                            clk_cnt    <= SAMPLE_TICKS;
                            bit_cnt    <= 0;
                            state      <= DATA;
                        else
                            state <= IDLE; -- False start bit
                        end if;
                    else
                        clk_cnt <= clk_cnt - 1;
                    end if;

                when DATA =>
                    if clk_cnt = 0 then
                        shift_reg <= rx_sync(1) & shift_reg(7 downto 1);
                        bit_cnt   <= bit_cnt + 1;
                        if bit_cnt = 7 then
                            state <= PARITY;
                        end if;
                        clk_cnt <= SAMPLE_TICKS;
                    else
                        clk_cnt <= clk_cnt - 1;
                    end if;

                when PARITY =>
                    if clk_cnt = 0 then
                        parity_bit <= rx_sync(1);
                        clk_cnt    <= SAMPLE_TICKS;
                        state      <= STOP;
                    else
                        clk_cnt <= clk_cnt - 1;
                    end if;

                when STOP =>
                    if clk_cnt = 0 then
                        if rx_sync(1) = '1' then -- Valid stop bit
                            data_out   <= shift_reg;
                            data_valid <= '1';
                        end if;
                        state <= IDLE;
                    else
                        clk_cnt <= clk_cnt - 1;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;
