#! /bin/csh

setenv dir /autofs/space/lilli_004/users/DARPA-MSIT/msit/msit/scripts
setenv subs_dir /autofs/space/lilli_004/users/DARPA-MSIT/msit/subjs
setenv params_dir /autofs/space/lilli_004/users/DARPA-MSIT/msit/bsm_params

set subjects_list = ($params_dir/subjects.txt)

#find $subs_dir -maxdepth 1 -name "*hc0*" > $dir/hc.txt
#find $subs_dir -maxdepth 1 -name "*pp0*" > $dir/pts.txt

#foreach subjs (`cat $subjects_list`)
	#cd $subs_dir/${subjs}/msit_bsm/;
	#mkdir orig;
	#echo "-------mkdir orig for " $subjs "----------"
	#cd $subs_dir/${subjs}/msit_bsm/anat;
	#cp *.anat.nii* ../orig;
	#echo "-------T1s COPIED for " $subjs "----------"
	#cd $subs_dir/${subjs}/msit_bsm/func;
	#cp *.func.nii* ../orig;
	#cp *.mat* ../orig;
	#echo "-------EPIs COPIED for " $subjs "----------"

#end

#foreach subjs (`cat $subjects_list`)
	#cd $subs_dir/${subjs}/msit_bsm/;
	#rm *3dDeconvolve*
	#echo "-------3dDeconvolve.REML_cmd removed for " $subjs "----------"	
	#cd $subs_dir/${subjs}/msit_bsm/anat;
	#rm *
	#echo "-------T1s removed for " $subjs "----------"
	#cd $subs_dir/${subjs}/msit_bsm/func;
	#rm *
	#echo "-------EPIs removed for " $subjs "----------"
	#cd $subs_dir/${subjs}/msit_bsm/bsm;
	#rm *
	#echo "-------bsm removed for " $subjs "----------"
	#cd $subs_dir/${subjs}/msit_bsm/results;
	#rm *
	#echo "-------results removed for " $subjs "----------"
#end

foreach subjs (`cat $subjects_list`)
	cd $subs_dir/${subjs}/msit_bsm/orig;
	cp *.anat.nii* ../anat
	cp *.func.nii* ../func;
	cp *.mat* ../func;
	echo "-------orig files copied to func, anat " $subjs "----------"

end

cd $dir


