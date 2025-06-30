    stimulus : process
        variable data : std_logic_vector(7 downto 0) := "11000110"; -- 198
        variable parity : std_logic := '0';
    begin
        wait for 100 us;
        rst <= '0';
        wait for 100 us;

        -- Send start bit
        rx_in <= '0';
        wait for clk_period * 16;

        -- Send 8 data bits LSB first
        for i in 0 to 7 loop
            rx_in <= data(i);
            wait for clk_period * 16;
        end loop;

        -- Compute even parity
        parity := '0';
        for i in 0 to 7 loop
            if data(i) = '1' then
                parity := parity xor '1';
            end if;
        end loop;

        -- Send parity bit
        rx_in <= parity;
        wait for clk_period * 16;

        -- Send stop bit
        rx_in <= '1';
        wait for clk_period * 16;

        -- Wait to observe echoed response
        wait for 2 ms;
        wait;
    end process;
