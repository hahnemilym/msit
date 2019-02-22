#! /bin/csh

setenv dir /autofs/space/lilli_004/users/DARPA-MSIT/msit/msit/scripts
setenv subs_dir /autofs/space/lilli_004/users/DARPA-MSIT/msit/subjs
setenv params_dir /autofs/space/lilli_004/users/DARPA-MSIT/msit/msit/params

#find $subs_dir -maxdepth 1 -name "*hc0*" > $dir/hc.txt
#find $subs_dir -maxdepth 1 -name "*pp0*" > $dir/pts.txt


set subjects_list = ($params_dir/subjects.txt)
foreach subjs (`cat $subjects_list`)
	cd $subs_dir/${subjs}/msit_bsm/anat;
	cp *.anat.mask+tlrc.* ../results;
	cp *.anat.2x2x2+tlrc.* ../results;
	echo "-------T1s COPIED for " $subjs "----------"
	cd $subs_dir/${subjs}/msit_bsm/func;
	cp *.smooth.resid+tlrc.* ../results;
	cp *.motion.py.strp+tlrc.* ../results;
	echo "-------EPIs COPIED for " $subjs "----------"
	cp *LSS* ../results;
	echo "-------BSM COPIED for " $subjs "----------"

end

cd $dir


