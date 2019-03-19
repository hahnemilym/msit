#! /bin/csh

setenv out_dir /autofs/space/lilli_004/users/DARPA-MSIT/msit
setenv subs_dir /autofs/space/lilli_004/users/DARPA-MSIT/msit/subjs
setenv params_dir /autofs/space/lilli_004/users/DARPA-MSIT/msit/bsm_params

#set subjects_list = ($params_dir/subjects.txt)
set subjects_list = (hc009 hc018 hc016 hc019 hc021 hc028 hc031 hc036 pp004 pp006 pp007 pp012 pp015)


foreach subjs (`cat $subjects_list`)
	cd $subs_dir/${subjs}/msit_bsm/results;
	cp *_LSS_avg_file.1D* $out_dir/beta_extract_output;
	cp *R.LSS.1D* $out_dir/beta_extract_output;
	echo "-------BSM extractions COPIED for " $subjs "----------"

end

cd $out_dir
