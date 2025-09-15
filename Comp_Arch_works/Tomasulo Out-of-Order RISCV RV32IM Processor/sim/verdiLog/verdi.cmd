simSetSimulator "-vcssv" -exec \
           "/home/ql21/ece411/mp_ooo/fa24_ece411_AG_Crushers/sim/vcs/top_tb" \
           -args "-exitstatus"
debImport "-dbdir" \
          "/home/ql21/ece411/mp_ooo/fa24_ece411_AG_Crushers/sim/vcs/top_tb.daidir"
debLoadSimResult \
           /home/ql21/ece411/mp_ooo/fa24_ece411_AG_Crushers/sim/vcs/dump.fsdb
wvCreateWindow
srcHBSelect "top_tb.dut" -win $_nTrace1
srcHBSelect "top_tb.dut" -win $_nTrace1
srcSetScope "top_tb.dut" -delim "." -win $_nTrace1
srcHBSelect "top_tb.dut" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "instr_push" -line 14 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "instr_pop" -line 15 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "instr_in" -line 17 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "instr_arr" -line 23 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "head" -line 31 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "tail" -line 31 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvSetCursor -win $_nWave2 12587.691293 -snap {("G1" 3)}
wvSelectSignal -win $_nWave2 {( "G1" 4 )} 
wvSetPosition -win $_nWave2 {("G1" 4)}
wvExpandBus -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 10)}
wvDisplayGridCount -win $_nWave2 -off
wvGetSignalClose -win $_nWave2
wvReloadFile -win $_nWave2
