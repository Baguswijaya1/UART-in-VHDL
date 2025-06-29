library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_loopback_tb is
end uart_loopback_tb;

architecture Behavioral of uart_loopback_tb is

    -- Constants
    constant CLK_PERIOD : time := 20 ns; -- 50 MHz clock

    -- Signals
    signal clk       : std_logic := '0';
    signal reset     : std_logic := '1';

    signal tx_start  : std_logic := '0';
    signal tx_data   : std_logic_vector(7 downto 0) := x"00";
    signal tx_busy   : std_logic;
    signal tx_line   : std_logic;

    signal rx_line   : std_logic;
    signal rx_data   : std_logic_vector(7 downto 0);
    signal rx_ready  : std_logic;

begin

    -- Clock process
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Connect tx -> rx
    rx_line <= tx_line;

    -- Instantiate TX
    uart_tx_inst : entity work.uart_tx
        port map (
            clk      => clk,
            reset    => reset,
            data_in  => tx_data,
            start_tx => tx_start,
            tx       => tx_line,
            busy     => tx_busy
        );

    -- Instantiate RX
    uart_rx_inst : entity work.uart_rx
        port map (
            clk        => clk,
            reset      => reset,
            rx         => rx_line,
            data_out   => rx_data,
            data_ready => rx_ready
        );

    -- Stimulus
    stimulus : process
    begin
        wait for 100 ns;
        reset <= '0';

        -- Wait some cycles
        wait for 1000 ns;

        -- Send a byte
        tx_data  <= x"5A";      -- Example: 0b01011010
        tx_start <= '1';
        wait for CLK_PERIOD;
        tx_start <= '0';

        -- Wait until transmission + reception done
        wait until rx_ready = '1';

        wait for 1000 ns;

        assert rx_data = x"5A"
            report "UART loopback failed!" severity error;

        wait;
    end process;

end Behavioral;
