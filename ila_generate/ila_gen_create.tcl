############################################################
#
#	Introduction: This is a tcl to generate an ILA
#
#	Creator: QianYu-1102
#
#	Create time: 2024/6/22
#
#	E-mail: 3050064793@qq.com
#
############################################################

#	first use should delete the # of the following four sentence code.
#	If you want to generate multiple ILA messages in the same folder, comment out the following four lines of code after using tcl for the first time.
#-------------------------------------------#
#file delete -force -- $ports_info_path
#file delete -force -- $ila_gen_tcl_path
#file mkdir $ports_info_path
#file mkdir $ila_gen_tcl_path
#-------------------------------------------#

# this line is to set your ILA's name
set ila_name "ila_test"	
# This line sets the maximum bit width of the signal port, signals exceeding this maximum bit width will not be added to the ILA list
set max_width 100	

set ports_info_path "./ports_info"
set ila_gen_tcl_path "./ila_gen_tcl"
set ports_width [get_property BUS_WIDTH [get_pins -of_objects [get_selected_objects]]]
set ports_name [get_property NAME [get_pins -of_objects [get_selected_objects]]]
set fp [open "$ports_info_path/${ila_name}_ports_list.txt" w]
set fp1 [open "$ports_info_path/${ila_name}_ports_width.txt" w]
set cnt 0

foreach name $ports_name width $ports_width {
	if {$cnt == 0} {
		if {[regexp {\[} $name]} {
			set match [regexp -all -inline {u_.*\[} $name]
			if {$width <= $max_width} {
				#puts $fp "match is $match \n"
				#puts $fp "name: $name, width: $width \n"
				puts $fp $name
				puts $fp1 $width
				incr cnt
			} else {}
		} else {
			set match $name
			if {[regexp {u_.*/clk} $name] || [regexp {u_.*/rst_n} $name] || [regexp {u_.*/hbm_clk} $name] || [regexp {u_.*/hbm_rst_n} $name]} {
			} else {
				#puts $fp "name: $name, width: 1 \n"
				puts $fp $name
				puts $fp1 "1"
				incr cnt
			}
		}
	} else {
		if {[regexp {\[} $name]} {
			if {[string equal $match [regexp -all -inline {u_.*\[} $name]]==0} {
				if {$width <= $max_width} {
					set match [regexp -all -inline {u_.*\[} $name]
					#puts $fp "match is $match \n"
					#puts $fp "name: $name, width: $width \n"
					puts $fp $name
					puts $fp1 $width
					incr cnt
				} else {}
			} else {}
		} else {
			if {[string equal $match $name]==0} {
				set match $name
				if {[regexp {u_.*/clk} $name] || [regexp {u_.*/rst_n} $name] || [regexp {u_.*/hbm_clk} $name] || [regexp {u_.*/hbm_rst_n} $name]} {
				} else {
					#puts $fp "name: $name, width: 1"
					puts $fp $name
					puts $fp1 "1"
					incr cnt
				}
			} else {}
		}
	}
	#puts $fp "\ncnt is $cnt"
}
puts $fp "\ntotal ports number is $cnt"
close $fp  
close $fp1

set fp1 [open "$ports_info_path/${ila_name}_ports_width.txt" r]
set fp2 [open "$ila_gen_tcl_path/${ila_name}_ila_gen.tcl" w]
set cnt_ila 0
set content [read $fp1]
foreach line [split $content "\n"] {
	if {$cnt_ila == 0} {
		puts $fp2 "create_ip -name ila -vendor xilinx.com -library ip -module_name ila_${ila_name}"
		puts $fp2 "set_property -dict \[list CONFIG.C_NUM_OF_PROBES \{$cnt\}\\"
		puts $fp2 "CONFIG.Component_Name \{ila_$ila_name\}\\"
		puts $fp2 "CONFIG.C_DATA_DEPTH {1024}\\"
		puts $fp2 "CONFIG.EN_BRAM_DRC {false}\\"
		puts $fp2 "CONFIG.C_TRIGIN_EN {false}\\"
		puts $fp2 "CONFIG.C_TRIGOUT_EN {false}\\"
		puts $fp2 "CONFIG.C_ADV_TRIGGER {false}\\"
		puts $fp2 "CONFIG.C_PROBE0_WIDTH \{$line\}\\"
	} else {
		puts $fp2 "CONFIG.C_PROBE${cnt_ila}_WIDTH \{$line\}\\"
	}
	incr cnt_ila
	if {$cnt_ila == $cnt} {
		puts $fp2 "\] \[get_ips ila_$ila_name\]"
		break
	}
}

close $fp1
close $fp2
