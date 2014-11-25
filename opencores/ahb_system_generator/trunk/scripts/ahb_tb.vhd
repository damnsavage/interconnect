
--*******************************************************************
--**                                                             ****
--**  AHB system generator                                       ****
--**                                                             ****
--**  Author: Federico Aglietti                                  ****
--**          federico.aglietti@opencores.org                   ****
--**                                                             ****
--*******************************************************************
--**                                                             ****
--** Copyright (C) 2004 Federico Aglietti                        ****
--**                    federico.aglietti@opencores.org         ****
--**                                                             ****
--** This source file may be used and distributed without        ****
--** restriction provided that this copyright statement is not   ****
--** removed from the file and that any derivative work contains ****
--** the original copyright notice and the associated disclaimer.****
--**                                                             ****
--**     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ****
--** EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ****
--** TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ****
--** FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ****
--** OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ****
--** INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ****
--** (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ****
--** GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ****
--** BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ****
--** LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ****
--** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ****
--** OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ****
--** POSSIBILITY OF SUCH DAMAGE.                                 ****
--**                                                             ****
--*******************************************************************
library ieee;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;

use work.ahb_package.all;
use work.ahb_configure.all;
use work.ahb_components.all;

entity ahb_tb is
end;

architecture rtl of ahb_tb is


signal mst_out_arb_0_v: mst_in_v_t(5 downto 0);
signal mst_in_arb_0_v: mst_out_v_t(5 downto 0);
signal slv_out_arb_0_v: slv_in_v_t(0 downto 0);
signal slv_in_arb_0_v: slv_out_v_t(0 downto 0);
signal addr_arb_matrix: addr_matrix_t(0 downto 0);
signal addr_ahbbrg_matrix: addr_matrix_t(1 downto 0);
signal addr_apbbrg_matrix: addr_matrix_t(1 downto 0);

signal ahb_mst_0_out: mst_out_t;
signal ahb_mst_0_in: mst_in_t;

signal ahb_mst_1_out: mst_out_t;
signal ahb_mst_1_in: mst_in_t;

signal ahb_mst_2_out: mst_out_t;
signal ahb_mst_2_in: mst_in_t;

signal ahb_mst_3_out: mst_out_t;
signal ahb_mst_3_in: mst_in_t;

signal ahb_mst_4_out: mst_out_t;
signal ahb_mst_4_in: mst_in_t;

signal ahb_mst_5_out: mst_out_t;
signal ahb_mst_5_in: mst_in_t;

signal ahb_slv_0_out: slv_out_t;
signal ahb_slv_0_in: slv_in_t;

signal conf : conf_type_v(5 downto 0);
signal dma_start : start_type_v(5 downto 0);
signal eot_int : std_logic_vector(5 downto 0);
signal sim_end : std_logic_vector(5 downto 0);

signal m_wrap_out : wrap_out_v(5 downto 0);
signal m_wrap_in : wrap_in_v(5 downto 0);
signal s_wrap_out : wrap_out_v(0 downto 0);
signal s_wrap_in : wrap_in_v(0 downto 0);

signal hresetn: std_logic;
signal hclk: std_logic;
signal remap: std_logic;

signal zero : std_logic;
signal no_conf_s : conf_type_t;
constant no_conf_c: conf_type_t:= ('0',"0000","00000000000000000000000000000000");
constant stim_0: uut_params_t:= (bits32,retry,master,'0',single,2,4,hprot_posted,0,1,0,'0');
constant stim_1: uut_params_t:= (bits32,retry,master,'0',single,2,4,hprot_posted,128,1,0,'0');
constant stim_2: uut_params_t:= (bits32,retry,master,'0',single,2,4,hprot_posted,256,1,0,'0');
constant stim_3: uut_params_t:= (bits32,retry,master,'0',single,2,4,hprot_posted,384,1,0,'0');
constant stim_4: uut_params_t:= (bits32,retry,master,'0',single,2,4,hprot_posted,512,1,0,'0');
constant stim_5: uut_params_t:= (bits32,retry,master,'0',single,2,4,hprot_posted,640,1,0,'0');

begin

zero <= '0';
no_conf_s <= no_conf_c;

ahb_mst_0_in <= mst_out_arb_0_v(5);
mst_in_arb_0_v(5) <= ahb_mst_0_out;
ahb_mst_1_in <= mst_out_arb_0_v(4);
mst_in_arb_0_v(4) <= ahb_mst_1_out;
ahb_mst_2_in <= mst_out_arb_0_v(3);
mst_in_arb_0_v(3) <= ahb_mst_2_out;
ahb_mst_3_in <= mst_out_arb_0_v(2);
mst_in_arb_0_v(2) <= ahb_mst_3_out;
ahb_mst_4_in <= mst_out_arb_0_v(1);
mst_in_arb_0_v(1) <= ahb_mst_4_out;
ahb_mst_5_in <= mst_out_arb_0_v(0);
mst_in_arb_0_v(0) <= ahb_mst_5_out;
ahb_slv_0_in <= slv_out_arb_0_v(0);
slv_in_arb_0_v(0) <= ahb_slv_0_out;

ahb_arb0: ahb_arbiter 
generic map(
num_arb => 0,
num_arb_msts => 6,
num_slvs => 1,
def_arb_mst => 0,
alg_number => 0)
port map(
  hresetn => hresetn,
  hclk => hclk,
  remap => remap,
  mst_in_v => mst_in_arb_0_v(5 downto 0),
  mst_out_v => mst_out_arb_0_v(5 downto 0),
  slv_in_v => slv_in_arb_0_v(0 downto 0),
  slv_out_v => slv_out_arb_0_v(0 downto 0));


ahb_mst0: ahb_master
generic map(
	fifohempty_level => 1,
	fifohfull_level => 7,
	fifo_length => 8)
port map (
	hresetn => hresetn,
	hclk => hclk,	
	mst_in => ahb_mst_0_in,
	mst_out => ahb_mst_0_out,       
	dma_start => dma_start(0),	
	m_wrap_out => m_wrap_out(0),
	m_wrap_in => m_wrap_in(0),
	eot_int => eot_int(0),
	slv_running => zero,
	mst_running => open);		

ahb_mst0_wrap: mst_wrap
generic map(
--synopsys translate_off
dump_file => "m0.log",
dump_type => dump_all,
--synopsys translate_on
ahb_max_addr => 4,
m_const_lat_write => 2,
m_const_lat_read => 2,
m_write_burst => 0,
m_read_burst => 0)
port map(
	hresetn => hresetn,
	clk => hclk,	
	conf => conf(0),
	dma_start => dma_start(0),	
	m_wrap_in => m_wrap_out(0),
	m_wrap_out => m_wrap_in(0));

ahb_mst1: ahb_master
generic map(
	fifohempty_level => 1,
	fifohfull_level => 7,
	fifo_length => 8)
port map (
	hresetn => hresetn,
	hclk => hclk,	
	mst_in => ahb_mst_1_in,
	mst_out => ahb_mst_1_out,       
	dma_start => dma_start(1),	
	m_wrap_out => m_wrap_out(1),
	m_wrap_in => m_wrap_in(1),
	eot_int => eot_int(1),
	slv_running => zero,
	mst_running => open);		

ahb_mst1_wrap: mst_wrap
generic map(
--synopsys translate_off
dump_file => "m1.log",
dump_type => dump_all,
--synopsys translate_on
ahb_max_addr => 4,
m_const_lat_write => 2,
m_const_lat_read => 2,
m_write_burst => 0,
m_read_burst => 0)
port map(
	hresetn => hresetn,
	clk => hclk,	
	conf => conf(1),
	dma_start => dma_start(1),	
	m_wrap_in => m_wrap_out(1),
	m_wrap_out => m_wrap_in(1));

ahb_mst2: ahb_master
generic map(
	fifohempty_level => 1,
	fifohfull_level => 7,
	fifo_length => 8)
port map (
	hresetn => hresetn,
	hclk => hclk,	
	mst_in => ahb_mst_2_in,
	mst_out => ahb_mst_2_out,       
	dma_start => dma_start(2),	
	m_wrap_out => m_wrap_out(2),
	m_wrap_in => m_wrap_in(2),
	eot_int => eot_int(2),
	slv_running => zero,
	mst_running => open);		

ahb_mst2_wrap: mst_wrap
generic map(
--synopsys translate_off
dump_file => "m2.log",
dump_type => dump_all,
--synopsys translate_on
ahb_max_addr => 4,
m_const_lat_write => 2,
m_const_lat_read => 2,
m_write_burst => 0,
m_read_burst => 0)
port map(
	hresetn => hresetn,
	clk => hclk,	
	conf => conf(2),
	dma_start => dma_start(2),	
	m_wrap_in => m_wrap_out(2),
	m_wrap_out => m_wrap_in(2));

ahb_mst3: ahb_master
generic map(
	fifohempty_level => 1,
	fifohfull_level => 7,
	fifo_length => 8)
port map (
	hresetn => hresetn,
	hclk => hclk,	
	mst_in => ahb_mst_3_in,
	mst_out => ahb_mst_3_out,       
	dma_start => dma_start(3),	
	m_wrap_out => m_wrap_out(3),
	m_wrap_in => m_wrap_in(3),
	eot_int => eot_int(3),
	slv_running => zero,
	mst_running => open);		

ahb_mst3_wrap: mst_wrap
generic map(
--synopsys translate_off
dump_file => "m3.log",
dump_type => dump_all,
--synopsys translate_on
ahb_max_addr => 4,
m_const_lat_write => 2,
m_const_lat_read => 2,
m_write_burst => 0,
m_read_burst => 0)
port map(
	hresetn => hresetn,
	clk => hclk,	
	conf => conf(3),
	dma_start => dma_start(3),	
	m_wrap_in => m_wrap_out(3),
	m_wrap_out => m_wrap_in(3));

ahb_mst4: ahb_master
generic map(
	fifohempty_level => 1,
	fifohfull_level => 7,
	fifo_length => 8)
port map (
	hresetn => hresetn,
	hclk => hclk,	
	mst_in => ahb_mst_4_in,
	mst_out => ahb_mst_4_out,       
	dma_start => dma_start(4),	
	m_wrap_out => m_wrap_out(4),
	m_wrap_in => m_wrap_in(4),
	eot_int => eot_int(4),
	slv_running => zero,
	mst_running => open);		

ahb_mst4_wrap: mst_wrap
generic map(
--synopsys translate_off
dump_file => "m4.log",
dump_type => dump_all,
--synopsys translate_on
ahb_max_addr => 4,
m_const_lat_write => 2,
m_const_lat_read => 2,
m_write_burst => 0,
m_read_burst => 0)
port map(
	hresetn => hresetn,
	clk => hclk,	
	conf => conf(4),
	dma_start => dma_start(4),	
	m_wrap_in => m_wrap_out(4),
	m_wrap_out => m_wrap_in(4));

ahb_mst5: ahb_master
generic map(
	fifohempty_level => 1,
	fifohfull_level => 7,
	fifo_length => 8)
port map (
	hresetn => hresetn,
	hclk => hclk,	
	mst_in => ahb_mst_5_in,
	mst_out => ahb_mst_5_out,       
	dma_start => dma_start(5),	
	m_wrap_out => m_wrap_out(5),
	m_wrap_in => m_wrap_in(5),
	eot_int => eot_int(5),
	slv_running => zero,
	mst_running => open);		

ahb_mst5_wrap: mst_wrap
generic map(
--synopsys translate_off
dump_file => "m5.log",
dump_type => dump_all,
--synopsys translate_on
ahb_max_addr => 4,
m_const_lat_write => 2,
m_const_lat_read => 2,
m_write_burst => 0,
m_read_burst => 0)
port map(
	hresetn => hresetn,
	clk => hclk,	
	conf => conf(5),
	dma_start => dma_start(5),	
	m_wrap_in => m_wrap_out(5),
	m_wrap_out => m_wrap_in(5));

ahb_slv0: ahb_slave_wait
generic map(
	num_slv => 0,
	fifohempty_level => 1,
	fifohfull_level => 7,
	fifo_length => 8)
port map (
	hresetn => hresetn,
	hclk => hclk,
	remap => remap,
	slv_in => ahb_slv_0_in,
	slv_out => ahb_slv_0_out,       
	s_wrap_out => s_wrap_out(0),
	s_wrap_in => s_wrap_in(0),
	mst_running => zero,
	prior_in => zero,
	slv_running => open,
	slv_err => open);		


ahb_slv0_wrap: slv_mem
generic map(
--synopsys translate_off
dump_file => "s0.log",
dump_type => dump_all,
--synopsys translate_on
ahb_max_addr => 8,
s_const_lat_write => 2,
s_const_lat_read => 2,
s_write_burst => 0,
s_read_burst => 0)
port map(
	hresetn => hresetn,
	clk => hclk,		
	conf => no_conf_s,
	dma_start => open,		
	s_wrap_in => s_wrap_out(0),
	s_wrap_out => s_wrap_in(0));


uut_stimulator_0: uut_stimulator 
generic map(
enable => 1,
stim_type => stim_0,
eot_enable => 1)
port map(
	 hclk => hclk,
	 hresetn => hresetn,
	 amba_error => zero,
	 eot_int => eot_int(0),
	 conf => conf(0),
	 sim_end => sim_end(0));


uut_stimulator_1: uut_stimulator 
generic map(
enable => 1,
stim_type => stim_1,
eot_enable => 1)
port map(
	 hclk => hclk,
	 hresetn => hresetn,
	 amba_error => zero,
	 eot_int => eot_int(1),
	 conf => conf(1),
	 sim_end => sim_end(1));


uut_stimulator_2: uut_stimulator 
generic map(
enable => 1,
stim_type => stim_2,
eot_enable => 1)
port map(
	 hclk => hclk,
	 hresetn => hresetn,
	 amba_error => zero,
	 eot_int => eot_int(2),
	 conf => conf(2),
	 sim_end => sim_end(2));


uut_stimulator_3: uut_stimulator 
generic map(
enable => 1,
stim_type => stim_3,
eot_enable => 1)
port map(
	 hclk => hclk,
	 hresetn => hresetn,
	 amba_error => zero,
	 eot_int => eot_int(3),
	 conf => conf(3),
	 sim_end => sim_end(3));


uut_stimulator_4: uut_stimulator 
generic map(
enable => 1,
stim_type => stim_4,
eot_enable => 1)
port map(
	 hclk => hclk,
	 hresetn => hresetn,
	 amba_error => zero,
	 eot_int => eot_int(4),
	 conf => conf(4),
	 sim_end => sim_end(4));


uut_stimulator_5: uut_stimulator 
generic map(
enable => 1,
stim_type => stim_5,
eot_enable => 1)
port map(
	 hclk => hclk,
	 hresetn => hresetn,
	 amba_error => zero,
	 eot_int => eot_int(5),
	 conf => conf(5),
	 sim_end => sim_end(5));


clock_pr:process
begin
  if hclk='1' then
    hclk <= '0';
    wait for 5 ns;
  else
    hclk <= '1';
    wait for 5 ns;
  end if;
end process;

reset_pr:process
begin
  hresetn<= '0';
  wait for 20 ns;
  hresetn <= '1';
  wait;
end process;

remap_pr:process
begin
  remap <= '0';
  wait for 2000 ns;
  remap <= '1';
  wait;
end process;

assert (not(sim_end(5)='1' and sim_end(4)='1' and sim_end(3)='1' and sim_end(2)='1' and sim_end(1)='1' and sim_end(0)='1')) report "*** SIMULATION ENDED ***" severity failure;

end rtl;

