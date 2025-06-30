library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart is
  Port (
    clk      : in  std_logic;      -- System clock
    rst      : in  std_logic;      -- Reset
    rx_in    : in  std_logic;      -- UART RX from PC
    tx_out   : out std_logic       -- UART TX to PC
  );
end uart;

architecture Behavioral of uart is

  -- Signals
  signal rx_data   : std_logic_vector(7 downto 0);
  signal rx_valid  : std_logic;
  signal tx_data   : std_logic_vector(7 downto 0);
  signal tx_start  : std_logic := '0';
  signal tx_busy   : std_logic;

begin

  -- UART Receiver
  uart_rx_inst : entity work.uart_rx
    port map (
      clk        => clk,
      rst        => rst,
      rx         => rx_in,
      data_out   => rx_data,
      data_valid => rx_valid
    );

  -- UART Transmitter
  uart_tx_inst : entity work.uart_tx
    port map (
      clk       => clk,
      reset     => rst,
      data_in   => tx_data,
      start_tx  => tx_start,
      tx        => tx_out,
      busy      => tx_busy
    );

  -- Echo logic: when RX is valid and TX is ready
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        tx_start <= '0';
        tx_data  <= (others => '0');
      else
        if rx_valid = '1' and tx_busy = '0' then
          tx_data  <= rx_data;
          tx_start <= '1';
        else
          tx_start <= '0';
        end if;
      end if;
    end if;
  end process;

end Behavioral;
