#!/bin/bash
# File name: Check_Scenario.sh
# Version of DOCK: 1.3
# Final Modified Date: 25/08/2015
# 
# Author: Hao-Chih,Lin (Jim,Lin)
# Email : F44006076@gmail.com  
#
# Abstract:
# This is the most important module of DOCK system.
# The purpose of this function is to analyze parameters between different files of the DOCK system.
# The analysis result will be described in the "Check_result.tmp" temporary file in "Tmp" folder.
# "Check_result.tmp" is the key flag which will be referenced by all the other modules.
# Without "Check_result.tmp" file, other modules can not get proper information of which "Scenario" file was selected.
#
# Developer can add custom "checking parameter process" in this file.  
# 
# Development process
# 20/08/2015:
# User can import the scenario file from "Input" folder (default) or from specific location
#===================================================
#=======================Program=====================
#===================================================


#
#================
#===Initialize===

#---Change the name of scenario file---
Scenario_input=$1
DOCK_main_location=`pwd`
Date=`date +"%y%m%d-%H%M%S"`

#---Check the path of scenario file (default or specific path) --- 20/08/2015
if [ "`echo "$Scenario_input" | awk -F / '{print $2}'`" == "" ] || [ "$Scenario_input" == "" ]; then
	cd Input
	Scenario_file=$Scenario_input	
	#---check if the file exists or not---
	until [ -f "$Scenario_file" ]
	do
		read -p "Scenario file not found, please eneter correct name:" Scenario_file
	done
	Scenario_file_path=$DOCK_main_location/Input/$Scenario_file
	echo -e "\e[5mScenario file found\e[0m"

else
	#---remove the "/" at the end of path---	
	if [ "${Scenario_input: -1}" == "/" ]; then
		Scenario_input=`echo ${Scenario_input: 0:-1}`
	fi

	#---make sure the path start from "/"---
	if [ "${Scenario_input: 0:1}" != "/" ]; then
		Scenario_input="/"$Scenario_input
	fi

	Scenario_location=`echo "$Scenario_input" | awk -F / '{for(i=2; i<NF; i++) printf "/"$i}'`
	cd $Scenario_location
	Scenario_file=`echo "$Scenario_input" | awk -F / '{print $NF}'`

	#---check if the file exists or not---
	if [ -f "$Scenario_file" ]; then
		echo -e "\e[5mScenario file found\e[0m"
	else
		echo -e "\e[91m!! Scenario file not found !!\e[0m"
		echo -e "\e[91m!! Exit the program !!\e[0m"
		#---Put the "exit" information into "Check_result.tmp"
		{ 
			echo "Date = \"$Date\""
			echo "Exit = \"True\"" 
		} > $DOCK_main_location/Module/Tmp/Check_result.tmp
		exit 0
	fi
	Scenario_file_path=$Scenario_file

fi

#---Define some index value---
index=1
Error_count=0
list_index=0
Current_location=`pwd`

#---Check the confuguration file---
Configuration_file=`tac $Scenario_file | grep -m 1 '^ *Configuration_file *=' | awk -F '"' '{printf $2}'`
if [ -f "$Configuration_file" ]; then
	echo "Configuration file found"
else
	echo -e "\e[91m!! Configuration file not found !!\e[0m"
	echo -e "\e[91m!! Exit the program !!\e[0m"
	#---Put the "exit" information into "Check_result.tmp"
	{ 
		echo "Date = \"$Date\""
		echo "Exit = \"True\"" 
	} > $DOCK_main_location/Module/Tmp/Check_result.tmp
	exit 0
fi

#---Put the absolute path of configuration file into variable "Configuration_file_path"--- 
if [ "`echo "$Configuration_file" | awk -F / '{print $2}'`" == "" ]; then
	Configuration_file_path=$DOCK_main_location/Input/$Configuration_file
else
	Configuration_file_path=$Configuration_file
fi

#---Load the flag for detemining if the easy quat program use the sequence inputs or not---		
Easy_sed_inputs=`tac $Scenario_file | grep -m 1 '^ *Easy_sed_inputs *=' | awk -F '"' '{printf $2}'`

#---Load the flag of "Keep_temp_file" item---
Keep_temp_file=`tac $Scenario_file | grep -m 1 '^ *Keep_temp_file *=' | awk -F '"' '{printf $2}'`

#---Load the flag of "Debug_log_gen" item---
#Keep_debug_file=`tac $Scenario_file | grep -m 1 '^ *Keep_debug_file *=' | awk -F '"' '{printf $2}'`  # modified - 19082015

#---Put file locations into variables---
VTS_project=`tac $Configuration_file | grep -m 1 '^ *VTS_project_file *=' | awk -F '"' '{printf $2}'`
VTS_new_project_location=`tac $Configuration_file | grep -m 1 '^ *VTS_project_location *=' | awk -F '"' '{printf $2}'`
CIC_output_location=`tac $Configuration_file | grep -m 1 '^ *Simulation_CIC_output_location *=' | awk -F '"' '{printf $2}'`

#---Load the definition of axes of satellite---
Satellite_Axes=`tac $Configuration_file | grep -m 1 '^ *Satellite_Axes *=' | awk -F '"' '{printf $2}'`

#
#===============================
#===Extrect data from IDM-CIC===
IDM_CIC_file=`tac $Scenario_file | grep -m 1 '^ *IDM_CIC_file *=' | awk -F '"' '{printf $2}'`
if [ -f "$IDM_CIC_file" ]; then
	echo  -e "\033[33m=====Extrecting data from IDM-CIC xml file=====\033[0m" 
	ProjectName=`grep '<projectName>' $IDM_CIC_file | cut -d '>' -f 2 | cut -d '<' -f 1`
	SystemVersion=`grep '<systemVersion>' $IDM_CIC_file | cut -d '>' -f 2 | cut -d '<' -f 1`
	echo "Project Name: $ProjectName"
	echo "System Version: $SystemVersion"
fi

#
#=======================
#===Scenario V.S. VTS===
echo  -e "\033[33m=====Checking data between Scenario and VTS=====\033[0m" 
#---Check the Satellite name in .vts file---
Satellite_name_vts=`grep '<Satellite Name' $VTS_project | cut -d '"' -f 2`
Satellite_name_sce=`tac $Configuration_file | grep -m 1 '^ *Satellite_name *=' | awk -F '"' '{printf $2}'`

if [ $Satellite_name_vts ==  $Satellite_name_sce ]; then
	echo "$index. Satellite_name        was checked: $Satellite_name_vts"
else
	echo  -e "\033[91m$index. Satellite_name is invalid: $Satellite_name_vts v.s. $Satellite_name_sce \033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 )) 

#---Check the file name of quaternion--- 
Satellite_quaternion_vts=`sed -n '/Satellite Name=/,/\/Satellite/p' $VTS_project | sed -n '/Quaternion/,/\/Quaternion/p' | grep '<File Name=' | cut -d '"' -f 2`
Satellite_quaternion_sce=`tac $Configuration_file | grep -m 1 '^ *Satellite_quaternion *=' | awk -F '"' '{printf $2}' | awk -F / '{print $(NF-1)"/"$NF}'`
if [ $Satellite_quaternion_vts ==  $Satellite_quaternion_sce ]; then
	echo "$index. Satellite_quaternion  was checked: $Satellite_quaternion_vts"
else
	echo  -e "\033[91m$index. Satellite_quaternion is invalid: $Satellite_quaternion_vts v.s. $Satellite_quaternion_sce \033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 )) 

#---Check the file name of position--- 
Satellite_position_vts=`sed -n '/Satellite Name=/,/\/Satellite/p' $VTS_project | sed -n '/Position/,/\/Position/p' | grep '<File Name=' | cut -d '"' -f 2`
Satellite_position_sce=`tac $Configuration_file | grep -m 1 '^ *Satellite_position *=' | awk -F '"' '{printf $2}' | awk -F / '{print $(NF-1)"/"$NF}'`
if [ $Satellite_position_vts ==  $Satellite_position_sce ]; then
	echo "$index. Satellite_position    was checked: $Satellite_position_vts"
else
	echo  -e "\033[91m$index. Satellite_position is invalid: $Satellite_position_vts v.s. $Satellite_position_sce \033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 )) 


#---Check the file name of satellite's 3ds model---
Satellite_3ds_vts=`sed -n '/Satellite Name=/,/\/Satellite/p' $VTS_project | sed -n '/Graphics3d/,/\/Graphics3d/p' | grep -m 1 '<File3ds Name=' | cut -d '"' -f 2`
Satellite_3ds_sce=`tac $Configuration_file | grep -m 1 '^ *Satellite_3ds *=' | awk -F '"' '{printf $2}' | awk -F / '{print $(NF-1)"/"$NF}'`
if [ $Satellite_3ds_vts ==  $Satellite_3ds_sce ]; then
	echo "$index. Satellite_3ds         was checked: $Satellite_3ds_vts"
else
	echo  -e "\033[91m$index. Satellite_3ds is invalid: $Satellite_3ds_vts v.s. $Satellite_3ds_sce \033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 )) 

#---Check the ParentPath of Satellite---
Satellite_parent_vts=`grep '<Satellite Name' $VTS_project | cut -d '"' -f 4`
Satellite_parent_sce=`tac $Configuration_file | grep -m 1 '^ *Satellite_parentpath *=' | awk -F '"' '{printf $2}'`
if [ $Satellite_parent_vts ==  $Satellite_parent_sce ]; then
	echo "$index. Satellite_parentpath  was checked: $Satellite_parent_vts"
else
	echo  -e "\033[91m$index. Satellite_parentpath is invalid: $Satellite_parent_vts v.s. $Satellite_parent_sce \033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 )) 

#---Seperate the name of satellite's parentpath into two variables---
VTS_Body_ParentPath=`tac $Configuration_file | grep -m 1 '^ *Satellite_parentpath *=' | awk -F '"' '{printf $2}' | awk -F / '{print $1}'`
VTS_Body_Name=`tac $Configuration_file | grep -m 1 '^ *Satellite_parentpath *=' | awk -F '"' '{printf $2}' | awk -F / '{print $2}'`
VTS_Body_Axes=$VTS_Body_Name"_Axes"

#---Check the Start-time of VTS---
Satellite_start_vts_date=`grep 'StartDateTime' $VTS_project | cut -d '"' -f 4 | cut -d ' ' -f 1`
Satellite_start_vts_sec=`grep 'StartDateTime' $VTS_project | cut -d '"' -f 4 | cut -d ' ' -f 2`
Satellite_start_sce_date=`tac $Scenario_file | grep -m 1 '^ *Simulation_time_start *=' | awk -F '"' '{printf $2}' | awk '{printf $1}'`
Satellite_start_sce_sec=`tac $Scenario_file | grep -m 1 '^ *Simulation_time_start *=' | awk -F '"' '{printf $2}' | awk '{printf $2}'`  # modified - 21082015
if [ $(echo "$Satellite_start_vts_date/$Satellite_start_sce_date" | bc) -eq 1 ] && [ $(echo "$Satellite_start_vts_sec/$Satellite_start_sce_sec" | bc) -eq 1 ]; then
	echo "$index. Satellite_StartTime   was checked: $Satellite_start_vts_date $Satellite_start_vts_sec"
else
	echo  -e "\033[91m$index. Satellite_StartTime is invalid: $Satellite_start_vts_date $Satellite_start_vts_sec v.s. $Satellite_start_sce_date $Satellite_start_sce_sec\033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 )) 

#---Check the End-time of VTS---
Satellite_end_vts_date=`grep 'EndDateTime' $VTS_project | cut -d '"' -f 6 | cut -d ' ' -f 1`
Satellite_end_vts_sec=`grep 'EndDateTime' $VTS_project | cut -d '"' -f 6 | cut -d ' ' -f 2`
Satellite_end_sce_date=`tac $Scenario_file | grep -m 1 '^ *Simulation_time_end *=' | awk -F '"' '{printf $2}' | awk '{printf $1}'`
Satellite_end_sce_sec=`tac $Scenario_file | grep -m 1 '^ *Simulation_time_end *=' | awk -F '"' '{printf $2}' | awk '{printf $2}'`
if [ $(echo "$Satellite_end_vts_date/$Satellite_end_sce_date" | bc) -eq 1 ] && [ $(echo "$Satellite_end_vts_sec/$Satellite_end_sce_sec" | bc) -eq 1 ]; then
	echo "$index. Satellite_EndTime     was checked: $Satellite_end_vts_date $Satellite_end_vts_sec"
else
	echo  -e "\033[91m$index. Satellite_EndTime is invalid: $Satellite_end_vts_date $Satellite_end_vts_sec v.s. $Satellite_end_sce_date $Satellite_end_sce_sec\033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 )) 


#
#====================================
#===Scenario V.S. CIC (quaternion)===
echo  -e "\033[33m=====Checking data between Scenario and CIC (quaternion)=====\033[0m" 
Satellite_quaternion_sce=`tac $Configuration_file | grep -m 1 '^ *Satellite_quaternion *=' | awk -F '"' '{printf $2}'`

#---Check the object_name---(Be careful when cut the parameter in txt file)
CIC_quat_name=`grep 'OBJECT_NAME' "$Satellite_quaternion_sce" | cut -d ' ' -f 3 | tr -d ["\r\n"]`
if [ $CIC_quat_name == $Satellite_name_sce ]; then
	echo "$index. CIC quat OBJECT_NAME  was checked: $CIC_quat_name"
else
	echo  -e "\033[91m$index. CIC quat OBJECT_NAME is invalid: $CIC_quat_name v.s. $Satellite_name_sce \033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 )) 

#---Check the REF_FRAME_A---
CIC_REF_FRAME_A=`grep 'REF_FRAME_A' "$Satellite_quaternion_sce" | cut -d ' ' -f 3 | tr -d ["\r\n"]`
Satellite_REF_FRAME_A=`tac $Configuration_file | grep -m 1 '^ *Satellite_ref_frame_A *=' | awk -F '"' '{printf $2}'`
if [ $CIC_REF_FRAME_A == $Satellite_REF_FRAME_A ]; then
	echo "$index. CIC quat REF_FRAME_A  was checked: $CIC_REF_FRAME_A"
else
	echo  -e "\033[91m$index. CIC quat REF_FRAME_A is invalid: $CIC_REF_FRAME_A v.s. $Satellite_REF_FRAME_A \033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 )) 

#---Check the REF_FRAME_B---
CIC_REF_FRAME_B=`grep 'REF_FRAME_B' "$Satellite_quaternion_sce" | cut -d ' ' -f 3 | tr -d ["\r\n"]`
Satellite_REF_FRAME_B=`tac $Configuration_file | grep -m 1 '^ *Satellite_ref_frame_B *=' | awk -F '"' '{printf $2}'`
if [ $CIC_REF_FRAME_B == $Satellite_REF_FRAME_B ]; then
	echo "$index.CIC quat REF_FRAME_B  was checked: $CIC_REF_FRAME_B"
else
	echo  -e "\033[91m$index. CIC quat REF_FRAME_B is invalid: $CIC_REF_FRAME_B v.s. $Satellite_REF_FRAME_B \033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 )) 

#---Check the ATTITUDE_DIR---
CIC_ATTITUDE_DIR=`grep 'ATTITUDE_DIR' "$Satellite_quaternion_sce" | cut -d ' ' -f 3 | tr -d ["\r\n"]`
Satellite_ATTITUDE_DIR=`tac $Configuration_file | grep -m 1 '^ *Satellite_attitude_dir *=' | awk -F '"' '{printf $2}'`
if [ $CIC_ATTITUDE_DIR == $Satellite_ATTITUDE_DIR ]; then
	echo "$index.CIC quat ATTITUDE_DIR was checked: $CIC_ATTITUDE_DIR"
else
	echo  -e "\033[91m$index. CIC quat ATTITUDE_DIR is invalid: $CIC_ATTITUDE_DIR v.s. $Satellite_ATTITUDE_DIR \033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 )) 

#---Check the TIME_SYSTEM---
CIC_TIME_SYSTEM=`grep 'TIME_SYSTEM' "$Satellite_quaternion_sce" | cut -d ' ' -f 3 | tr -d ["\r\n"]`
Satellite_TIME_SYSTEM=`tac $Configuration_file | grep -m 1 '^ *Satellite_time_system *=' | awk -F '"' '{printf $2}'`
if [ $CIC_TIME_SYSTEM == $Satellite_TIME_SYSTEM ]; then
	echo "$index.CIC quat TIME_SYSTEM  was checked: $CIC_TIME_SYSTEM"
else
	echo  -e "\033[91m$index.CIC quat TIME_SYSTEM is invalid: $CIC_TIME_SYSTEM v.s. $Satellite_TIME_SYSTEM \033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 )) 

#---Check the ATTITUDE_TYPE---
CIC_ATT_TYPE=`grep 'ATTITUDE_TYPE' "$Satellite_quaternion_sce" | cut -d ' ' -f 3 | tr -d ["\r\n"]`
Satellite_ATT_TYPE=`tac $Configuration_file | grep -m 1 '^ *Satellite_att_type *=' | awk -F '"' '{printf $2}'`
if [ $CIC_ATT_TYPE == $Satellite_ATT_TYPE ]; then
	echo "$index.CIC quat ATT_TYPE     was checked: $CIC_ATT_TYPE"
else
	echo  -e "\033[91m$index.CIC quat TIME_SYSTEM is invalid: $CIC_ATT_TYPE v.s. $Satellite_ATT_TYPE \033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 ))

#---Check the Start time---
CIC_quat_start_date=`sed -n '/META_STOP/,$p' "$Satellite_quaternion_sce" | head -n 3 | tail -n 1 | cut -d ' ' -f 1`
CIC_quat_start_sec=`sed -n '/META_STOP/,$p' "$Satellite_quaternion_sce" | head -n 3 | tail -n 1 | cut -d ' ' -f 2`
if [ $(echo "$CIC_quat_start_date/$Satellite_start_sce_date" | bc) -eq 1 ] && [ $(echo "$CIC_quat_start_sec/$Satellite_start_sce_sec" | bc) -eq 1 ]; then
	echo "$index.CIC quat Start-time   was checked: $CIC_quat_start_date $CIC_quat_start_sec"
else
	echo  -e "\033[91m$index.CIC quat Start-time is invalid: $CIC_quat_start_date $CIC_quat_start_sec v.s. $Satellite_start_sce_date $Satellite_start_sce_sec\033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 ))

#---Check the End time---
CIC_quat_end_date=`sed -n '/META_STOP/,$p' "$Satellite_quaternion_sce" | tail -n 1 | cut -d ' ' -f 1`
CIC_quat_end_sec=`sed -n '/META_STOP/,$p' "$Satellite_quaternion_sce" | tail -n 1 | cut -d ' ' -f 2`
if [ $(echo "$CIC_quat_end_date/$Satellite_end_sce_date" | bc) -eq 1 ] && [ $(echo "$CIC_quat_end_sec/$Satellite_end_sce_sec" | bc) -eq 1 ]; then
	echo "$index.CIC quat End-time     was checked: $CIC_quat_end_date $CIC_quat_end_sec"
else
	echo  -e "\033[91m$index.CIC quat End-time is invalid: $CIC_quat_end_date $CIC_quat_end_sec v.s. $Satellite_end_sce_date $Satellite_end_sce_sec\033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 ))

#
#==================================
#===Scenario V.S. CIC (position)===
echo  -e "\033[33m=====Checking data between Scenario and CIC (position)=====\033[0m"
Satellite_position_sce=`tac $Configuration_file | grep -m 1 '^ *Satellite_position *=' | awk -F '"' '{printf $2}'`
#---Check the object_name---
CIC_pos_name=`grep 'OBJECT_NAME' "$Satellite_position_sce" | cut -d ' ' -f 3 | tr -d ["\r\n"]`
if [ $CIC_pos_name == $Satellite_name_sce ]; then
	echo "$index.CIC pos OBJECT_NAME   was checked: $CIC_pos_name"
else
	echo  -e "\033[91m$index.CIC pos OBJECT_NAME is invalid: $CIC_pos_name v.s. $Satellite_name_sce \033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 )) 

#---Check the REF_FRAME---
CIC_REF_FRAME=`grep 'REF_FRAME' "$Satellite_position_sce" | cut -d ' ' -f 3 | tr -d ["\r\n"]`
Satellite_REF_FRAME=`tac $Configuration_file | grep -m 1 '^ *Satellite_ref_frame_A *=' | awk -F '"' '{printf $2}'`
if [ $CIC_REF_FRAME == $Satellite_REF_FRAME ]; then
	echo "$index.CIC pos REF_FRAME     was checked: $CIC_REF_FRAME"
else
	echo  -e "\033[91m$index.CIC pos REF_FRAME is invalid: $CIC_REF_FRAME v.s. $Satellite_REF_FRAME \033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 ))

#---Check the TIME_SYSTEM---
CIC_TIME_SYSTEM=`grep 'TIME_SYSTEM' "$Satellite_position_sce" | cut -d ' ' -f 3 | tr -d ["\r\n"]`
if [ $CIC_TIME_SYSTEM == $Satellite_TIME_SYSTEM ]; then
	echo "$index.CIC pos TIME_SYSTEM   was checked: $CIC_TIME_SYSTEM"
else
	echo  -e "\033[91m$index.CIC pos TIME_SYSTEM is invalid: $CIC_TIME_SYSTEM v.s. $Satellite_TIME_SYSTEM \033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 )) 

#---Check the Start time---
CIC_pos_start_date=`sed -n '/META_STOP/,$p' "$Satellite_position_sce" | head -n 3 | tail -n 1 | cut -d ' ' -f 1`
CIC_pos_start_sec=`sed -n '/META_STOP/,$p' "$Satellite_position_sce" | head -n 3 | tail -n 1 | cut -d ' ' -f 2`
if [ $(echo "$CIC_pos_start_date/$Satellite_start_sce_date" | bc) -eq 1 ] && [ $(echo "$CIC_pos_start_sec/$Satellite_start_sce_sec" | bc) -eq 1 ]; then
	echo "$index.CIC pos Start-time    was checked: $CIC_pos_start_date $CIC_pos_start_sec"
else
	echo  -e "\033[91m$index.CIC pos Start-time is invalid: $CIC_pos_start_date $CIC_pos_start_sec v.s. $Satellite_start_sce_date $Satellite_start_sce_sec\033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 ))

#---Check the End time---
CIC_quat_end_date=`sed -n '/META_STOP/,$p' "$Satellite_quaternion_sce" | tail -n 1 | cut -d ' ' -f 1`
CIC_quat_end_sec=`sed -n '/META_STOP/,$p' "$Satellite_quaternion_sce" | tail -n 1 | cut -d ' ' -f 2`
if [ $(echo "$CIC_quat_end_date/$Satellite_end_sce_date" | bc) -eq 1 ] && [ $(echo "$CIC_quat_end_sec/$Satellite_end_sce_sec" | bc) -eq 1 ]; then
	echo "$index.CIC pos End-time      was checked: $CIC_quat_end_date $CIC_quat_end_sec"
else
	echo  -e "\033[91m$index.CIC pos End-time is invalid: $CIC_quat_end_date $CIC_quat_end_sec v.s. $Satellite_end_sce_date $Satellite_end_sce_sec\033[0m"
	(( Error_count += 1 ))	
fi
(( index += 1 ))


#
#==================================
#===Scenario V.S. Seq-inputs===
if [ $Easy_sed_inputs == "True" ]; then
	#---Load the file name of "Seq_inputs_file"---
	Seq_inputs_file=`tac $Scenario_file | grep -m 1 '^ *Seq_inputs_file *=' | awk -F '"' '{printf $2}'`

	if [ ! -f "$Seq_inputs_file" ]; then
		#echo "Seq-inputs-file was checked"

		echo -e "\e[91m!! Seq-inputs-file not found !!\e[0m"
		echo -e "\e[91m!! Exit the program !!\e[0m"
		exit 0
	fi

	#---Put the absolute path of Seq_inputs_file into variable "Seq_inputs_file_path"--- 
	if [ "`echo "$Seq_inputs_file" | awk -F / '{print $2}'`" == "" ]; then
		Seq_inputs_file_path=$DOCK_main_location/Input/$Seq_inputs_file
	else
		Seq_inputs_file_path=$Seq_inputs_file
	fi
	

	echo  -e "\033[33m=====Checking data between Scenario and Seq-inputs file=====\033[0m"
	#---Check the object_name---(Be careful when cut the parameter in txt file)
	Seq_quat_name=`grep 'OBJECT_NAME' "$Seq_inputs_file" | cut -d ' ' -f 3 | tr -d ["\r\n"]`
	if [ $Seq_quat_name == $Satellite_name_sce ]; then
		echo "$index.Seq quat OBJECT_NAME  was checked: $Seq_quat_name"
	else
		echo  -e "\033[91m$index.Seq quat OBJECT_NAME is invalid: $Seq_quat_name v.s. $Satellite_name_sce \033[0m"
		(( Error_count += 1 ))	
	fi
	(( index += 1 )) 

	#---Check the REF_FRAME_A---
	Seq_REF_FRAME_A=`grep 'REF_FRAME_A' "$Seq_inputs_file" | cut -d ' ' -f 3 | tr -d ["\r\n"]`
	if [ $Seq_REF_FRAME_A == $Satellite_REF_FRAME_A ]; then
		echo "$index.Seq quat REF_FRAME_A  was checked: $Seq_REF_FRAME_A"
	else
		echo  -e "\033[91m$index.Seq quat REF_FRAME_A is invalid: $Seq_REF_FRAME_A v.s. $Satellite_REF_FRAME_A \033[0m"
		(( Error_count += 1 ))	
	fi
	(( index += 1 )) 

	#---Check the REF_FRAME_B---
	Seq_REF_FRAME_B=`grep 'REF_FRAME_B' "$Seq_inputs_file" | cut -d ' ' -f 3 | tr -d ["\r\n"]`
	if [ $Seq_REF_FRAME_B == $Satellite_REF_FRAME_B ]; then
		echo "$index.Seq quat REF_FRAME_B  was checked: $Seq_REF_FRAME_B"
	else
		echo  -e "\033[91m$index. Seq quat REF_FRAME_B is invalid: $Seq_REF_FRAME_B v.s. $Satellite_REF_FRAME_B \033[0m"
		(( Error_count += 1 ))	
	fi
	(( index += 1 )) 

	#---Check the ATTITUDE_DIR---
	Seq_ATTITUDE_DIR=`grep 'ATTITUDE_DIR' "$Seq_inputs_file" | cut -d ' ' -f 3 | tr -d ["\r\n"]`
	if [ $Seq_ATTITUDE_DIR == $Satellite_ATTITUDE_DIR ]; then
		echo "$index.Seq quat ATTITUDE_DIR was checked: $Seq_ATTITUDE_DIR"
	else
		echo  -e "\033[91m$index. Seq quat ATTITUDE_DIR is invalid: $Seq_ATTITUDE_DIR v.s. $Satellite_ATTITUDE_DIR \033[0m"
		(( Error_count += 1 ))	
	fi
	(( index += 1 )) 

	#---Check the TIME_SYSTEM---
	Seq_TIME_SYSTEM=`grep 'TIME_SYSTEM' "$Seq_inputs_file" | cut -d ' ' -f 3 | tr -d ["\r\n"]`
	if [ $Seq_TIME_SYSTEM == $Satellite_TIME_SYSTEM ]; then
		echo "$index.Seq quat TIME_SYSTEM  was checked: $Seq_TIME_SYSTEM"
	else
		echo  -e "\033[91m$index.Seq quat TIME_SYSTEM is invalid: $Seq_TIME_SYSTEM v.s. $Satellite_TIME_SYSTEM \033[0m"
		(( Error_count += 1 ))	
	fi
	(( index += 1 )) 

	#---Check the ATTITUDE_TYPE---
	Seq_ATT_TYPE=`grep 'ATTITUDE_TYPE' "$Seq_inputs_file" | cut -d ' ' -f 3 | tr -d ["\r\n"]`
	if [ $Seq_ATT_TYPE == $Satellite_ATT_TYPE ]; then
		echo "$index.Seq quat ATT_TYPE     was checked: $Seq_ATT_TYPE"
	else
		echo  -e "\033[91m$index.Seq quat TIME_SYSTEM is invalid: $Seq_ATT_TYPE v.s. $Satellite_ATT_TYPE \033[0m"
		(( Error_count += 1 ))	
	fi
	(( index += 1 ))

	#---Check the Start time---
	Seq_quat_start_date=`sed -n '/META_STOP/,$p' "$Seq_inputs_file" | head -n 3 | tail -n 1 | cut -d ' ' -f 1`
	Seq_quat_start_sec=`sed -n '/META_STOP/,$p' "$Seq_inputs_file" | head -n 3 | tail -n 1 | cut -d ' ' -f 2`
	if [ $(echo "$Seq_quat_start_date/$Satellite_start_sce_date" | bc) -eq 1 ] && [ $(echo "$Seq_quat_start_sec/$Satellite_start_sce_sec" | bc) -eq 1 ]; then
		echo "$index.Seq quat Start-time   was checked: $Seq_quat_start_date $Seq_quat_start_sec"
	else
		echo  -e "\033[91m$index.Seq quat Start-time is invalid: $Seq_quat_start_date $Seq_quat_start_sec v.s. $Satellite_start_sce_date $Satellite_start_sce_sec\033[0m"
		(( Error_count += 1 ))	
	fi
	(( index += 1 ))

	#---Check the End time---
	Seq_quat_end_date=`sed -n '/META_STOP/,$p' "$Seq_inputs_file" | tail -n 1 | cut -d ' ' -f 3`
	Seq_quat_end_sec=`sed -n '/META_STOP/,$p' "$Seq_inputs_file" | tail -n 1 | cut -d ' ' -f 4`
	if [ $(echo "$Seq_quat_end_date/$Satellite_end_sce_date" | bc) -eq 1 ] && [ $(echo "$Seq_quat_end_sec/$Satellite_end_sce_sec" | bc) -eq 1 ]; then
		echo "$index.Seq quat End-time     was checked: $Seq_quat_end_date $Seq_quat_end_sec"
	else
		echo  -e "\033[91m$index.Seq quat End-time is invalid: $Seq_quat_end_date $Seq_quat_end_sec v.s. $Satellite_end_sce_date $Satellite_end_sce_sec\033[0m"
		(( Error_count += 1 ))	
	fi
	(( index += 1 ))
fi

#
#=================================
#=============Summary=============
echo  -e "\033[33m==============Analysis result==============\033[0m" 
if [ $Error_count -eq 0 ]; then
	echo "All parameters are valid !!"
	#---Creat temporary "Check_result" file---
	{ 
		echo "===This is a temporary file for recording the result of 'Check_Scenario' function===" 
		echo "Date = \"$Date\""
		echo "Scenario_name = \"$Scenario_file_path\""
		echo "Configuration_name = \"$Configuration_file_path\""
		echo "Error_flag = \"False\""
	} > $DOCK_main_location/Module/Tmp/Check_result.tmp
else
	echo -e "There are \e[91m$Error_count errors !!\e[0m"
	{ 
		echo "===This is a temporary file for recording the result of 'Check_Scenario' function===" 
		echo "Date = \"$Date\""
		echo "Scenario_name = \"$Scenario_file_path\""
		echo "Configuration_name = \"$Configuration_file_path\""
		echo "Error_flag = \"True\""
	} > $DOCK_main_location/Module/Tmp/Check_result.tmp
fi

#
#===========================================
#===Load "Module Selection" from Scenario===

#---Check if simulated quaternion module is selected or not--- 
PRODQUAT=`grep '^ *PRODQUAT *' $Scenario_file`
if [ "$PRODQUAT" == "" ]; then
	{ echo "PRODQUAT = \"False\""
	} >> $DOCK_main_location/Module/Tmp/Check_result.tmp
else
	{ echo "PRODQUAT = \"True\""
	} >> $DOCK_main_location/Module/Tmp/Check_result.tmp
fi

#---Check if easy quaternion module is selected or not--- 
EASYQUAT=`grep '^ *EASYQUAT *' $Scenario_file`
if [ "$EASYQUAT" == "" ]; then
	{ echo "EASYQUAT = \"False\""
	} >> $DOCK_main_location/Module/Tmp/Check_result.tmp
else
	{ echo "EASYQUAT = \"True\""
	} >> $DOCK_main_location/Module/Tmp/Check_result.tmp
fi

#---Check if trajectory solver module is selected or not--- 
PRODTRAJ=`grep '^ *PRODTRAJ *' $Scenario_file`
if [ "$PRODTRAJ" == "" ]; then
	{ echo "PRODTRAJ = \"False\""
	} >> $DOCK_main_location/Module/Tmp/Check_result.tmp
else
	{ echo "PRODTRAJ = \"True\""
	} >> $DOCK_main_location/Module/Tmp/Check_result.tmp
fi

#---Check if easy trajectory module is selected or not--- 
EASYTRAJ=`grep '^ *EASYTRAJ *' $Scenario_file`
if [ "$EASYTRAJ" == "" ]; then
	{ echo "EASYTRAJ = \"False\""
	} >> $DOCK_main_location/Module/Tmp/Check_result.tmp
else
	{ echo "EASYTRAJ = \"True\""
	} >> $DOCK_main_location/Module/Tmp/Check_result.tmp
fi

#---Check if vts creater module is selected or not--- 
PRODVTS=`grep '^ *PRODVTS *' $Scenario_file`
if [ "$PRODVTS" == "" ]; then
	{ echo "PRODVTS = \"False\""
	} >> $DOCK_main_location/Module/Tmp/Check_result.tmp
else
	{ echo "PRODVTS = \"True\""
	} >> $DOCK_main_location/Module/Tmp/Check_result.tmp
fi

#---Check if vts execution module is selected or not--- 
EXEVTS=`grep '^ *EXEVTS *' $Scenario_file`
if [ "$EXEVTS" == "" ]; then
	{ echo "EXEVTS = \"False\""
	} >> $DOCK_main_location/Module/Tmp/Check_result.tmp
else
	{ echo "EXEVTS = \"True\""
	} >> $DOCK_main_location/Module/Tmp/Check_result.tmp
fi

#---Check Easy_sed_inputs file---
if [ $Easy_sed_inputs == "True" ]; then
	#---Put the location of "Seq_inputs_file" into "Check_result.tmp"
	{ echo "Seq_inputs_file = \"$Seq_inputs_file_path\"" 
	} >> $DOCK_main_location/Module/Tmp/Check_result.tmp
fi
