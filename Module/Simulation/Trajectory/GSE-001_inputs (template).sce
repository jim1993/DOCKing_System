//=========================================================
// BIRDY_TS: GSE-001_inputs.sce
//=========================================================
// date : 03-Feb-2015
// Ref: GSE-001
// CL=2
// version 1.1
// by	Boris SEGRET from v1.0
//	This is a template: only the names and values of the paramaters below are mandatory
//	This subprogramm is called at the beginning of BIRDY_TS for 1 run. It allows to run
//	many computed trajetcories by only changing the inputs here.
//
//	F/ a bash-shell program produces the GSE-001_inputs.sce file and launches 1 run with
//	$> nohup echo "exec('test.sce')" | scilab-adv-cli &
//	Note: if the main program launches many instances of BIRDY_TS, it is recommanded to
//	use the "nice" command to set a lowest priority like this:
//	$> nice -n 15 BIRDY_TS_batch
//	(batch-GSE-001 is the name of a main program to launch several instances of BIRDY_TS)
//	(the lowest priority will be inherited)

hpas = 21600; // output steps in seconds
npas = 990; // number of calculated dates
Host_traj = 'GL-01_sun_58122.xyzv';
kjettison = -39; // offset of jettisonning from the exit of Earth's SOI
outputfiles = "truc_v6_"; // prefix of the output trajectory files
outputcrits = "truc_perfos"; // files to append the performances of the computed trajectory
longLog = "truc"; // name of the log file for detailed monitoring of 1 run (may be overwritten!)

