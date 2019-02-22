#! /bin/csh

setenv out_dir /autofs/space/lilli_004/users/DARPA-MSIT/msit
setenv subs_dir /autofs/space/lilli_004/users/DARPA-MSIT/msit/subjs
setenv params_dir /autofs/space/lilli_004/users/DARPA-MSIT/msit/msit/params

set subjects_list = ($params_dir/subjects.txt)

foreach subjs (`cat $subjects_list`)
	cd $subs_dir/${subjs}/msit_bsm/results;
	cp *_LSS_avg_file.1D* $out_dir/beta_extract_output;
	echo "-------BSM extractions COPIED for " $subjs "----------"

end

cd $dir
