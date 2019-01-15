#! /bin/csh
#use giant move for 002
#only one skull strip for 011, FCT run1 doesn't need expand
#015 FCT run1 doesn't need expand

set subjs = (001) #002 003 004 005 007 010 014 015 017 018 020 022 026 027 031 032 033 034 038 039 044 046 048 049 053 054 057 059 060 062 063 067 070 071 073 075)# complete:

set study = DOP

set TR = 2.00

set slices = 37

cd /home/aprivratsky/DOP

set rootpth = `pwd`

set do_anat = 'yes'

set do_epi = 'no'

set slice_pattern = 'seq+z'

foreach subj (${subjs})

set task = (rest FCT)

	mkdir ${rootpth}/${subj} 
	cd ${rootpth}/${subj}

	cp /raw/cisler/DOP/DOP_${subj}/day_1/*.nii .
	cp /raw/cisler/DOP/DOP_${subj}/day1/*.nii .
	cp /raw/cisler/DOP/DOP_${subj}/day1/day_1/*.nii . # DOP_059 data was put in bad folder arrangement

	mkdir day1 day1/anat day1/FCT day1/FCT/run1 day1/FCT/run2 day1/FCT/analyze day1/rest day1/rest/run1 day1/rest/run2

	if (${subj} == 060) then #060 had restarted run1
		mv *FCT*run1*3*nii day1/FCT/run1/${study}.${subj}.FCT.run1.nii
	else
		mv *FCT*run1*nii day1/FCT/run1/${study}.${subj}.FCT.run1.nii
	endif

	mv *FCT*run1*nii day1/FCT/run1/${study}.${subj}.FCT.run1.nii
	mv *FCT*run2*nii day1/FCT/run2/${study}.${subj}.FCT.run2.nii
	mv *Rest*run1*nii day1/rest/run1/${study}.${subj}.rest.run1.nii
	mv *Rest*run2*nii day1/rest/run2/${study}.${subj}.rest.run2.nii
	mv *T1W*nii day1/anat/${study}.${subj}.anat.nii
	rm *.nii

	cd day1/
	# save reference to activeSubject directory
	set activeSubjectdirectory = `pwd`
echo ${do_anat}
if ( ${do_anat} == 'yes' ) then
				cd anat	
				
				echo "****************************************************************"
				echo " Skull striping for ${study} ${subj}"
				echo "****************************************************************"	
		
				rm ${study}.${subj}.anat.sksp+orig*
				3dSkullStrip -input ${study}.${subj}.anat.nii \
					-prefix ${study}.${subj}.anat.sksp \
					-orig_vol \
					-niter 300

				#skull strip twice to ensure accuracy of skull removal

				rm ${study}.${subj}.anat.sksp1+orig*
				3dSkullStrip -input ${study}.${subj}.anat.sksp+orig \
					-prefix ${study}.${subj}.anat.sksp1 \
					-orig_vol \
					-niter 300
				#removes first skull strip
				rm ${study}.${subj}.anat.sksp+orig*
				3dcopy ${study}.${subj}.anat.sksp1+orig ${study}.${subj}.anat.sksp
				rm ${study}.${subj}.anat.sksp1+orig*
							
				echo "****************************************************************"
				echo " auto_tlrc T1 for ${study}${subj}"
				echo "****************************************************************"
				rm ${study}.${subj}.anat.sksp_MNI+tlrc*
				rm ${study}.${subj}.anat.mask*
				@auto_tlrc -no_ss -suffix _MNI -rmode quintic -base TT_icbm452+tlrc -input ${study}.${subj}.anat.sksp+orig
				
				3dAutomask -prefix ${study}.${subj}.anat.mask ${study}.${subj}.anat.sksp_MNI+tlrc

				#copy the normalized anat files to the group and reg check directories for future visualization
				cp ${study}.${subj}.anat.sksp_MNI+tlrc* ${rootpth}/regcheck/day1
				cp ${study}.${subj}.anat.sksp_MNI+tlrc* ${rootpth}/group/day1
								


				echo ""
				echo "****************************************************************"
				echo " creating an fsl segmentation "
				echo "****************************************************************"
				# convert afni to nifti (previously skull stripped image)
				rm ${study}.${subj}.anat.sksp.nii*
				rm ${study}.${subj}.anat_seg.nii.gz

				3dresample \
					-orient ASR \
					-inset ${study}.${subj}.anat.sksp+orig.HEAD \
					-prefix ${study}.${subj}.anat.sksp.nii
				
			
				
				# do GM,WM,CSF segmentation
				fast -t 1 -n 3 -H .5 -B -b --nopve -o ${study}.${subj}.anat ${study}.${subj}.anat.sksp.nii
	
				
			
				# move back to afni format
				# NOTE: order of these commands is important. If you change, test first.
				rm ${study}.${subj}.anat.seg.float+orig*
	
				#added by jc 9-13-10, because for some reason FSL makes the file a .gz
				gunzip ${study}.${subj}.anat_seg.nii.gz


				3dcopy -verb ${study}.${subj}.anat_seg.nii ${study}.${subj}.anat.seg.float
			
					
				3drefit -'anat'  ${study}.${subj}.anat.seg.float+orig
			
			
				# correct the data type from float to short so that downstream calls are not confused
				# note this is now given fsl stamp
				rm ${study}.${subj}.anat.seg.fsl+orig*

				3dcalc \
				-datum short \
				-a ${study}.${subj}.anat.seg.float+orig \
				-expr a \
				-prefix ${study}.${subj}.anat.seg.fsl 

				# remove intermediates
				rm -v ${study}.${subj}.anat.seg.float+orig* 
				rm -v ${study}.${subj}.anat.sksp.nii 
				rm -v ${study}.${subj}.anat_seg.nii 

				echo "****************************************************************"
				echo " warp segmented anat into MNI space"
				echo "****************************************************************"
				rm ${study}.${subj}.anat.seg.fsl.MNI+tlrc*
				
				@auto_tlrc -apar ${study}.${subj}.anat.sksp_MNI+tlrc \
					-no_ss -suffix .MNI -rmode quintic \
					-input ${study}.${subj}.anat.seg.fsl+orig


		cd ..
endif

if ( ${do_epi} == 'yes' ) then		
	foreach task (${task})

		if ( ${task} == 'FCT' ) then
			set scan = (run1 run2)
		else if ( ${task} == 'rest' ) then
				set scan = (run1 run2)
		endif
				
		cd ${activeSubjectdirectory}/${task}
		foreach scan (${scan})

			if ( ${task} == 'FCT' ) then

				echo ${rootpth} ${study} ${subj} ${task} ${scan} day1 > ${rootpth}/scripts/var_names_for_expand

				cd /home/aprivratsky/DOP/scripts/preproc
			
				matlab -nodesktop -nosplash -r "expand_nii_bandit_task;exit"

				3dAFNItoNIFTI -prefix ${activeSubjectdirectory}/${task}/${scan}/${study}.${subj}.${task}.${scan}.nii \
					${activeSubjectdirectory}/${task}/${scan}/concat_${study}.${subj}.${task}.${scan}+orig
			endif
		
			cd ${activeSubjectdirectory}/${task}/${scan}

		
				echo ""
				echo -------------------------------------------------------------------------------
				echo despiking
				echo -------------------------------------------------------------------------------
				rm ${study}.${subj}.${task}.${scan}.DSPK*
				3dDespike \
					-overwrite \
					-prefix ${study}.${subj}.${task}.${scan}.DSPK \
					${study}.${subj}.${task}.${scan}.nii

				rm ${study}.${subj}.${task}.${scan}.nii

				echo -------------------------------------------------------------------------------
				echo 3dTshift 
				echo -------------------------------------------------------------------------------
			
				 
				rm ${study}.${subj}.${task}.${scan}.tshft+orig*
				3dTshift -ignore 1 \
					-tzero 0 \
					-TR ${TR} \
					-tpattern ${slice_pattern} \
					-prefix ${study}.${subj}.${task}.${scan}.tshft \
					 ${study}.${subj}.${task}.${scan}.DSPK+orig
				
				rm ${study}.${subj}.${task}.${scan}.DSPK+orig*
			
				echo ""
				echo -------------------------------------------------------------------------------
				echo deobliquing
				echo -------------------------------------------------------------------------------
				rm ${study}.${subj}.${task}.${scan}.deoblique+orig*
				3dWarp -deoblique \
					-prefix ${study}.${subj}.${task}.${scan}.deoblique \
					${study}.${subj}.${task}.${scan}.tshft+orig

				rm ${study}.${subj}.${task}.${scan}.tshft+orig*

				echo ""
				echo -------------------------------------------------------------------------------
				echo motion correction
				echo -------------------------------------------------------------------------------
				rm ${study}.${subj}.${task}.${scan}.motion+orig*
				3dvolreg -verbose \
				-zpad 1 \
				-base ${study}.${subj}.${task}.${scan}.deoblique+orig'[10]' \
				-1Dfile ${study}.${subj}.${task}.${scan}.motion.1D \
				-prefix ${study}.${subj}.${task}.${scan}.motion \
				${study}.${subj}.${task}.${scan}.deoblique+orig

				cp ${study}.${subj}.${task}.${scan}.motion.1D ${rootpth}/motioncheck/day1
				rm ${study}.${subj}.${task}.${scan}.deoblique+orig*

				echo ""
				echo -------------------------------------------------------------------------------
				echo making motion regressors
				echo -------------------------------------------------------------------------------

				cd /home/aprivratsky/DOP/scripts/preproc
				echo ${study} ${subj} ${task} ${scan} day1 > var_names


				matlab -nodesktop -nosplash -r "make_motion_regressors;exit"

				cd ${activeSubjectdirectory}/${task}/${scan}


				echo ""
				echo -------------------------------------------------------------------------------
				echo warping EPI to anat space and normalizing
				echo -------------------------------------------------------------------------------

				cp ${activeSubjectdirectory}/anat/*sksp* .
				rm ${study}.${subj}.${task}.${scan}.motion_shft+orig*
				
				#@Align_Centers -base ${study}.${subj}.anat.sksp+orig -dset ${study}.${subj}.${task}.${scan}.motion+orig			
				rm ${study}.${subj}.${task}.${scan}.motion_py+orig*
				rm ${study}.${subj}.${task}.${scan}.motion_shft_tlrc_py+tlrc*
				rm ${study}.${subj}.${task}.${scan}.motion_tlrc_py+tlrc*
				
				set move = giant_move
				if ( ${subj} == 002 || ${subj} == 004 || ${subj} == 015 || ${subj} == 020 || ${subj} == 038 || ${subj} == 039 || ${subj} == 060) then
					set move = ginormous_move
				endif

				align_epi_anat.py -anat ${study}.${subj}.anat.sksp+orig \
				-epi ${study}.${subj}.${task}.${scan}.motion+orig \
				-epi_base 6 -epi2anat -suffix _py \
				-tlrc_apar ${study}.${subj}.anat.sksp_MNI+tlrc \
				-anat_has_skull no -volreg off -tshift off -deoblique off -${move}

				#use below command when running the @Align_Centers above
				#align_epi_anat.py -anat ${study}.${subj}.anat.sksp+orig -epi ${study}.${subj}.${task}.${scan}.motion_shft+orig -epi_base 6 -epi2anat -suffix _py -tlrc_apar ${study}.${subj}.anat.sksp_MNI+tlrc -anat_has_skull no -volreg off -tshift off -deoblique off

				#3drename ${study}.${subj}.${task}.${scan}.motion_shft_tlrc_py+tlrc ${study}.${subj}.${task}.${scan}.motion_tlrc_py
				rm ${study}.${subj}.${task}.${scan}.mean*
				rm ${study}.${subj}.${task}.${scan}.stdev_no_smooth*
				rm ${study}.${subj}.${task}.${scan}.tSNR_no_smooth*
				3dTstat -prefix ${study}.${subj}.${task}.${scan}.mean ${study}.${subj}.${task}.${scan}.motion_tlrc_py+tlrc
				3dTstat -stdev -prefix ${study}.${subj}.${task}.${scan}.stdev_no_smooth ${study}.${subj}.${task}.${scan}.motion_tlrc_py+tlrc
				3dcalc -a ${study}.${subj}.${task}.${scan}.mean+tlrc -b ${study}.${subj}.${task}.${scan}.stdev_no_smooth+tlrc -expr 'a/b' -prefix ${study}.${subj}.${task}.${scan}.tSNR_no_smooth
				#copy the mean image to reg check directory to check alignment and normalization
				cp ${study}.${subj}.${task}.${scan}.mean+tlrc* ${rootpth}/regcheck/day1
				cp ${study}.${subj}.${task}.${scan}.tSNR_no_smooth+tlrc* ${rootpth}/tSNR/day1
				rm ${study}.${subj}.${task}.${scan}.motion+orig
				rm *malldump*

				echo ""
				echo -------------------------------------------------------------------------------
				echo regressing out csf and wm and global signal
				echo -------------------------------------------------------------------------------	
				#first create masks for GM, WM, CSF and global signal

				cd ${activeSubjectdirectory}/anat/

				rm ${activeSubjectdirectory}/anat/${study}.${subj}.anat.seg.fsl.MNI.3x3x3+tlrc*

				3dfractionize -template ${activeSubjectdirectory}/${task}/${scan}/${study}.${subj}.${task}.${scan}.motion_tlrc_py+tlrc \
					-input ${study}.${subj}.anat.seg.fsl.MNI+tlrc \
					-prefix ${activeSubjectdirectory}/anat/${study}.${subj}.anat.seg.fsl.MNI.3x3x3 \
					-clip .2 -vote

				
				rm ${study}.${subj}.anat.seg.fsl.MNI.CSF+tlrc*
				3dcalc -overwrite \
					-a ${study}.${subj}.anat.seg.fsl.MNI.3x3x3+tlrc \
					-expr 'equals(a,1)' \
					-prefix ${study}.${subj}.anat.seg.fsl.MNI.CSF
		
				rm ${study}.${subj}.anat.seg.fsl.MNI.GM+tlrc*
 				3dcalc -overwrite \
 					-a ${study}.${subj}.anat.seg.fsl.MNI.3x3x3+tlrc \
 					-expr 'equals(a,2)' \
 					-prefix ${study}.${subj}.anat.seg.fsl.MNI.GM

				rm ${study}.${subj}.anat.seg.fsl.MNI.WM+tlrc*
				3dcalc -overwrite \
					-a ${study}.${subj}.anat.seg.fsl.MNI.3x3x3+tlrc \
					-expr 'equals(a,3)' \
					-prefix ${study}.${subj}.anat.seg.fsl.MNI.WM



				# create an WM mask with 1 voxel erosion
				rm ${study}.${subj}.anat.seg.fsl.MNI.WM.erode1+tlrc*
				3dcalc -a ${study}.${subj}.anat.seg.fsl.MNI.WM+tlrc \
					-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
					-expr 'a*(1-amongst(0,b,c,d,e,f,g))' \
					-prefix ${study}.${subj}.anat.seg.fsl.MNI.WM.erode1

				# create an WM mask with 2 voxel erosion
				rm ${study}.${subj}.anat.seg.fsl.MNI.WM.erode2+tlrc*
				3dcalc -a ${study}.${subj}.anat.seg.fsl.MNI.WM.erode1+tlrc \
					-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
					-expr 'a*(1-amongst(0,b,c,d,e,f,g))' \
					-prefix ${study}.${subj}.anat.seg.fsl.MNI.WM.erode2

				#remove WM mask with 1 voxel
				rm ${study}.${subj}.anat.seg.fsl.MNI.WM.erode1+tlrc

				# create an CSF mask with 1 voxel erosion
				rm ${study}.${subj}.anat.seg.fsl.MNI.CSF.erode1+tlrc*
				3dcalc -a ${study}.${subj}.anat.seg.fsl.MNI.CSF+tlrc \
					-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
					-expr 'a*(1-amongst(0,b,c,d,e,f,g))' \
					-prefix ${study}.${subj}.anat.seg.fsl.MNI.CSF.erode1

				cd ${activeSubjectdirectory}/${task}/${scan}

				
				#create CSF and WM regressors using maskSVD 
				3dmaskSVD \
					-vnorm \
					-sval 2 \
					-mask ${activeSubjectdirectory}/anat/${study}.${subj}.anat.seg.fsl.MNI.CSF.erode1+tlrc \
					-polort a \
					./${study}.${subj}.${task}.${scan}.motion_tlrc_py+tlrc > ./NOISE_REGRESSOR.${task}.${scan}.CSF.1D

				3dmaskSVD \
					-vnorm \
					-sval 2 \
					-mask ${activeSubjectdirectory}/anat/${study}.${subj}.anat.seg.fsl.MNI.WM.erode2+tlrc \
					-polort a \
					./${study}.${subj}.${task}.${scan}.motion_tlrc_py+tlrc > ./NOISE_REGRESSOR.${task}.${scan}.WM.1D



				rm NOISE_REGRESSOR.${task}.${scan}.WM.derivative.1D
				rm NOISE_REGRESSOR.${task}.${scan}.CSF.derivative.1D
				1d_tool.py -infile NOISE_REGRESSOR.${task}.${scan}.WM.1D -derivative \
					-write	NOISE_REGRESSOR.${task}.${scan}.WM.derivative.1D

				1d_tool.py -infile NOISE_REGRESSOR.${task}.${scan}.CSF.1D -derivative \
					-write	NOISE_REGRESSOR.${task}.${scan}.CSF.derivative.1D
				

				#perform regression of WM, CSF, and motion and keep residuals (errts = error timeseries)
				
				rm ${study}.${subj}.${task}.${scan}.motion_tlrc_py.resid+tlrc*
				rm ${study}.${subj}.${task}.${scan}.motion.resid+tlrc*


				3dDeconvolve \
				-input ${study}.${subj}.${task}.${scan}.motion_tlrc_py+tlrc \
				-polort A \
				-nfirst 0 \
				-num_stimts 28 \
				-stim_file 1 ${study}.${subj}.${task}.${scan}.motion.1D'[0]' -stim_base 1 \
				-stim_file 2 ${study}.${subj}.${task}.${scan}.motion.1D'[1]' -stim_base 2 \
				-stim_file 3 ${study}.${subj}.${task}.${scan}.motion.1D'[2]' -stim_base 3 \
				-stim_file 4 ${study}.${subj}.${task}.${scan}.motion.1D'[3]' -stim_base 4 \
				-stim_file 5 ${study}.${subj}.${task}.${scan}.motion.1D'[4]' -stim_base 5 \
				-stim_file 6 ${study}.${subj}.${task}.${scan}.motion.1D'[5]' -stim_base 6 \
				-stim_file 7 ${study}.${subj}.${task}.${scan}.motion.square.1D'[0]' -stim_base 7 \
				-stim_file 8 ${study}.${subj}.${task}.${scan}.motion.square.1D'[1]' -stim_base 8 \
				-stim_file 9 ${study}.${subj}.${task}.${scan}.motion.square.1D'[2]' -stim_base 9 \
				-stim_file 10 ${study}.${subj}.${task}.${scan}.motion.square.1D'[3]' -stim_base 10 \
				-stim_file 11 ${study}.${subj}.${task}.${scan}.motion.square.1D'[4]' -stim_base 11 \
				-stim_file 12 ${study}.${subj}.${task}.${scan}.motion.square.1D'[5]' -stim_base 12 \
				-stim_file 13 ${study}.${subj}.${task}.${scan}.motion_pre_t.1D'[0]' -stim_base 13 \
				-stim_file 14 ${study}.${subj}.${task}.${scan}.motion_pre_t.1D'[1]' -stim_base 14 \
				-stim_file 15 ${study}.${subj}.${task}.${scan}.motion_pre_t.1D'[2]' -stim_base 15 \
				-stim_file 16 ${study}.${subj}.${task}.${scan}.motion_pre_t.1D'[3]' -stim_base 16 \
				-stim_file 17 ${study}.${subj}.${task}.${scan}.motion_pre_t.1D'[4]' -stim_base 17 \
				-stim_file 18 ${study}.${subj}.${task}.${scan}.motion_pre_t.1D'[5]' -stim_base 18 \
				-stim_file 19 ${study}.${subj}.${task}.${scan}.motion_pre_t_square.1D'[0]' -stim_base 19 \
				-stim_file 20 ${study}.${subj}.${task}.${scan}.motion_pre_t_square.1D'[1]' -stim_base 20 \
				-stim_file 21 ${study}.${subj}.${task}.${scan}.motion_pre_t_square.1D'[2]' -stim_base 21 \
				-stim_file 22 ${study}.${subj}.${task}.${scan}.motion_pre_t_square.1D'[3]' -stim_base 22 \
				-stim_file 23 ${study}.${subj}.${task}.${scan}.motion_pre_t_square.1D'[4]' -stim_base 23 \
				-stim_file 24 ${study}.${subj}.${task}.${scan}.motion_pre_t_square.1D'[5]' -stim_base 24 \
				-stim_file 25 NOISE_REGRESSOR.${task}.${scan}.CSF.1D'[0]' -stim_base 25 \
				-stim_file 26 NOISE_REGRESSOR.${task}.${scan}.CSF.derivative.1D'[0]' -stim_base 26 \
				-stim_file 27 NOISE_REGRESSOR.${task}.${scan}.WM.1D'[0]' -stim_base 27 \
				-stim_file 28 NOISE_REGRESSOR.${task}.${scan}.WM.derivative.1D'[0]' -stim_base 28 \
				-x1D ${activeSubjectdirectory}/${task}/${scan}/${subj}.${task}.${scan}.resid.xmat.1D \
				-x1D_stop 


				3dREMLfit -input ${study}.${subj}.${task}.${scan}.motion_tlrc_py+tlrc \
					-matrix ${activeSubjectdirectory}/${task}/${scan}/${subj}.${task}.${scan}.resid.xmat.1D \
					-automask \
					-Rbuck temp.bucket \
					-Rerrts ${study}.${subj}.${task}.${scan}.motion.resid				

				rm ${study}.${subj}.${task}.${scan}.motion_py+orig*
				rm ${study}.${subj}.${task}.${scan}.motion_tlrc_py+tlrc*

				echo ""
				echo -------------------------------------------------------------------------------
				echo detrending
				echo -------------------------------------------------------------------------------				
				rm ${study}.${subj}.${task}.${scan}.detrend.resid+tlrc*
				3dDetrend -overwrite -verb -polort 2 \
					-prefix ${study}.${subj}.${task}.${scan}.detrend.resid \
					${study}.${subj}.${task}.${scan}.motion.resid+tlrc

				rm ${study}.${subj}.${task}.${scan}.motion.resid+tlrc*

				rm detrend.resid_w_mean+tlrc*
				3dcalc \
					-a ${study}.${subj}.${task}.${scan}.detrend.resid+tlrc \
					-b ${study}.${subj}.${task}.${scan}.mean+tlrc \
					-expr 'a+b' -prefix detrend.resid_w_mean

				rm ${study}.${subj}.${task}.${scan}.detrend.resid+tlrc*
				3drename detrend.resid_w_mean+tlrc ${study}.${subj}.${task}.${scan}.detrend.resid
				rm detrend.resid_w_mean+tlrc*


				if ( ${task} == 'rest' ) then

					echo ""
					echo -------------------------------------------------------------------------------
					echo bandpass temporal filtering rest 100 s to 10 s
					echo -------------------------------------------------------------------------------
					rm ${study}.${subj}.${task}.${scan}.fourier.resid+tlrc*
					3dFourier -prefix ${study}.${subj}.${task}.${scan}.fourier.resid \
						  -highpass .01 -lowpass .1 -retrend \
						  ${study}.${subj}.${task}.${scan}.detrend.resid+tlrc

					rm ${study}.${subj}.${task}.${scan}.detrend.resid+tlrc*

				else
					echo ""
					echo -------------------------------------------------------------------------------
					echo highpass temporal filtering task 128 s
					echo -------------------------------------------------------------------------------
					rm ${study}.${subj}.${task}.${scan}.fourier.resid+tlrc*
					3dFourier -prefix ${study}.${subj}.${task}.${scan}.fourier.resid \
						  -highpass .0078 -retrend \
						  ${study}.${subj}.${task}.${scan}.detrend.resid+tlrc

					rm ${study}.${subj}.${task}.${scan}.detrend.resid+tlrc*
				endif

				echo ""
				echo -------------------------------------------------------------------------------
				echo spatial smoothing
				echo -------------------------------------------------------------------------------
				rm ${study}.${subj}.${task}.${scan}.smooth.resid+tlrc*
				3dBlurToFWHM -input ${study}.${subj}.${task}.${scan}.fourier.resid+tlrc \
					-prefix ${study}.${subj}.${task}.${scan}.smooth.resid \
					-FWHM 8.0 \
					-automask
				
				rm ${study}.${subj}.${task}.${scan}.fourier.resid+tlrc*


				echo ""
				echo -------------------------------------------------------------------------------
				echo scaling to percent signal change
				echo -------------------------------------------------------------------------------
				rm ${study}.${subj}.${task}.${scan}.mean.resid+tlrc*
				rm ${study}.${subj}.${task}.${scan}.mask.resid+tlrc*
				rm ${study}.${subj}.${task}.${scan}.scaled.resid+tlrc*
				rm ${study}.${subj}.${task}.${scan}.std.resid+tlrc*

				3dTstat -prefix ${study}.${subj}.${task}.${scan}.mean.resid ${study}.${subj}.${task}.${scan}.smooth.resid+tlrc

				
				3dAutomask -dilate 1 \
					-prefix ${study}.${subj}.${task}.${scan}.mask.resid \
					${study}.${subj}.${task}.${scan}.smooth.resid+tlrc
	
				3dcalc -a ${study}.${subj}.${task}.${scan}.smooth.resid+tlrc \
					-b ${study}.${subj}.${task}.${scan}.mean.resid+tlrc \
					-c ${study}.${subj}.${task}.${scan}.mask.resid+tlrc \
					-expr "c*((a/b)*100)" \
					-float \
					-prefix ${study}.${subj}.${task}.${scan}.scaled.resid
				#alternative method of scaling: expr "c*(100*((a-b)/abs(b)))"

				rm ${study}.${subj}.${task}.${scan}.fourier.resid+tlrc*
				rm ${study}.${subj}.${task}.${scan}.mean.resid+tlrc*
				rm ${study}.${subj}.${task}.${scan}.mask.resid+tlrc*
				rm ${study}.${subj}.${task}.${scan}.std.resid+tlrc*

			

	end # end loop through scans
	end #end loop through tasks
	
	cd ${activeSubjectdirectory}
endif

end



