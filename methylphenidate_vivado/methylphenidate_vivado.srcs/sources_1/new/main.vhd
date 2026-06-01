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

    signal state : std_logic := '0';

    -- Signals for medikinet instantiation
    signal ap_done : std_logic;
    signal ap_idle : std_logic;
    signal ap_ready : std_logic;
    signal layer5_out_0 : std_logic_vector(15 downto 0);
    signal layer5_out_1 : std_logic_vector(15 downto 0);

    -- Fixed-point parameters: <16,6> means 10 fractional bits
    constant FRAC_BITS : integer := 10;
    constant SCALE     : real    := 2.0 ** FRAC_BITS;  -- 1024.0
    -- Function to convert real to fixed<16,6>
    function to_fixed(x : real) return std_logic_vector is
        variable scaled : integer;
    begin
        scaled := integer(x * SCALE);
        return std_logic_vector(to_signed(scaled, 16));
    end function;

begin

    -- Medikinet instantiation
    medikinet_inst : medikinet
        port map (
            ap_clk      => CLK,
            ap_rst      => '0',           -- No reset provided, tied to '0'
            ap_start    => state,         -- Use blink state to trigger starts
            ap_done     => ap_done,
            ap_idle     => ap_idle,
            ap_ready    => ap_ready,
            przeInput_ap_vld => '1',      -- Hardwired to '1' as requested
            przeInput   => to_fixed(-1.0) & to_fixed(-0.5),
            layer5_out_0 => layer5_out_0,
            layer5_out_0_ap_vld => open,
            layer5_out_1 => layer5_out_1,
            layer5_out_1_ap_vld => open
        );

    blink : process(CLK) begin
        if(rising_edge(CLK)) then
            state <= not state;
        else
            state <= state;
        end if;
    end process blink;

    -- LED assignments
    LED(0) <= state;
    LED(1) <= ap_done;

    LED0_R <= '1' when signed(layer5_out_0) > signed(layer5_out_1) else '0';
    LED0_B <= '1' when signed(layer5_out_1) > signed(layer5_out_0) else '0';

end Behavioral;
