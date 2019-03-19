
setenv out_dir /autofs/space/lilli_004/users/DARPA-MSIT/msit
setenv subs_dir /autofs/space/lilli_004/users/DARPA-MSIT/msit/subjs
setenv params_dir /autofs/space/lilli_004/users/DARPA-MSIT/msit/bsm_params

#find $subs_dir -maxdepth 1 -name "*hc0*" > $dir/hc.txt
#find $subs_dir -maxdepth 1 -name "*pp0*" > $dir/pts.txt


#set subjects_list = ($params_dir/subjects.txt)
#foreach subjs (`cat $subjects_list`)
set subjects_list = (hc009 hc018 hc016 hc019 hc021 hc028 hc031 hc036 pp004 pp006 pp007 pp012 pp015)
foreach subjs ($subjects_list)
	echo $subjs
	cd $subs_dir/${subjs}/msit_bsm/anat;
	cp *.anat.mask+tlrc.* ../results;
	cp *.anat.2x2x2+tlrc.* ../results;
	echo "-------T1s COPIED for " $subjs "----------"
	cd $subs_dir/${subjs}/msit_bsm/func;
	cp *.smooth.resid+tlrc.* ../results;
	echo "-------smooth.resid+tlrc. COPIED for " $subjs "----------"
	cp *.motion.py.strp+tlrc.* ../results;
	echo "-------.motion.py.strp+tlrc. COPIED for " $subjs "----------"
	echo "-------EPIs COPIED for " $subjs "----------"
	cd $subs_dir/${subjs}/msit_bsm/bsm;
	cp *LSS* ../results;
	echo "-------BSM COPIED for " $subjs "----------"
end

cd $out_dir
