library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity main is
  Port (
    CLK : in std_logic;
    LED : out std_logic_vector(3 downto 0);
    LED0_B : out std_logic;
    LED0_R : out std_logic
  );
end main;

architecture Behavioral of main is

    component medikinet is port (
        ap_clk : IN STD_LOGIC;
        ap_rst : IN STD_LOGIC;
        ap_start : IN STD_LOGIC;
        ap_done : OUT STD_LOGIC;
        ap_idle : OUT STD_LOGIC;
        ap_ready : OUT STD_LOGIC;
        przeInput_ap_vld : IN STD_LOGIC;
        przeInput : IN STD_LOGIC_VECTOR (31 downto 0);
        layer5_out_0 : OUT STD_LOGIC_VECTOR (15 downto 0);
        layer5_out_0_ap_vld : OUT STD_LOGIC;
        layer5_out_1 : OUT STD_LOGIC_VECTOR (15 downto 0);
        layer5_out_1_ap_vld : OUT STD_LOGIC );
    end component medikinet;

    -- Signals for the network
    signal ap_done : std_logic;
    signal ap_idle : std_logic;
    signal ap_ready : std_logic;
    signal ap_start : std_logic := '1';
    signal layer5_out_0 : std_logic_vector(15 downto 0);
    signal layer5_out_1 : std_logic_vector(15 downto 0);

    -- Converting floating point to fixed point that network requires
    -- Fixed-point parameters: <16,6> means 10 fractional bits
    constant FRAC_BITS : integer := 10;
    constant SCALE     : real    := 2.0 ** FRAC_BITS;
    function to_fixed(x : real) return std_logic_vector is
        variable scaled : integer;
    begin
        scaled := integer(x * SCALE);
        return std_logic_vector(to_signed(scaled, 16));
    end function;

    -- Example points to test
    type t_point_arr is array (0 to 3) of std_logic_vector(31 downto 0);
    constant points_array : t_point_arr := (
        to_fixed(-0.5) & to_fixed( 0.5),
        to_fixed( 0.5) & to_fixed( 0.5),
        to_fixed(-0.5) & to_fixed(-0.5),
        to_fixed( 0.5) & to_fixed(-0.5)
    );
    signal network_input : std_logic_vector(31 downto 0);
    signal point_idx     : integer range 0 to 3 := 0;
    signal last_point_idx : integer range 0 to 3 := 3;

    -- Prescaler to slow down the point switching so it's visible with the eye
    constant SEC_CYCLES : natural := 100_000_000;
    signal prescaler : natural range 0 to SEC_CYCLES - 1 := 0;
    signal tick_1s   : std_logic := '0';

begin
    medikinet_inst : medikinet
        port map (
            ap_clk      => CLK,
            ap_rst      => '0',
            ap_start    => ap_start,
            ap_done     => ap_done,
            ap_idle     => ap_idle,
            ap_ready    => ap_ready,
            przeInput_ap_vld => '1',
            przeInput   => network_input,
            layer5_out_0 => layer5_out_0,
            layer5_out_0_ap_vld => open,
            layer5_out_1 => layer5_out_1,
            layer5_out_1_ap_vld => open
        );

    prescaler_proc : process(clk)
    begin
        if rising_edge(clk) then
            if prescaler = SEC_CYCLES - 1 then
                prescaler <= 0;
                tick_1s   <= '1';
            else
                prescaler <= prescaler + 1;
                tick_1s   <= '0';
            end if;
        end if;
    end process prescaler_proc;

    point_switching : process(clk) begin
        if rising_edge(clk) and tick_1s = '1' then
            if ap_done = '1' then
                last_point_idx <= point_idx;

                ap_start <= '1';
                if point_idx = 3 then
                    point_idx <= 0;
                else
                    point_idx <= point_idx + 1;
                end if;
            else
                ap_start <= '0';
            end if;
        end if;
    end process point_switching;

    network_input <= points_array(point_idx);

    LED(0) <= '1' when (last_point_idx mod 2) = 1 else '0';
    LED(1) <= '1' when last_point_idx >= 2 else '0';

    LED0_R <= '1' when signed(layer5_out_0) > signed(layer5_out_1) else '0';
    LED0_B <= '1' when signed(layer5_out_1) > signed(layer5_out_0) else '0';

end Behavioral;
