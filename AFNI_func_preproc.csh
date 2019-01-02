#! /bin/csh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Configure environment
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# Local Directory
setenv DIR /Users/emilyhahn/projects

# Project Directory
setenv MSIT_DIR $DIR/msit

# Subjects Directory
setenv SUBJECTS_DIR $MSIT_DIR/subjs

# Parameters Directory
setenv PARAMS_DIR $MSIT_DIR/bsm_params/

# Analyses Directory
setenv ANALYSIS_DIR $MSIT_DIR/scripts

# Subjects List
#setenv SUBJECT_LIST $PARAMS_DIR/subjects_list_mmddyy.txt

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Define parameters
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# formerly 'seq+z'. Here, slices interleaved and odd.. possibly 'alt+z2' ?
set slice_pattern =  $ANALYSIS_DIR/slice_timing.txt

# number of regressors (e.g. wm, csf, motion)
set num_stimts = 28

# A = automatically choose polynomial detrending value based on
# time duration D of longest run: pnum = 1 + int(D/150)
set polort = A

set FWHM = 6
set TR = 1.75
set slices = 63

set study = msit
set task = (${study}_bsm)

set do_epi = 'yes'

# expand_nii_bandit_task.m - shows dir struct used in orig script
# matlab -nodesktop -nosplash -r "expand_nii_bandit_task;exit"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Initialize subject(s) environment
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#set subjects = ($SUBJECT_LIST)
#foreach SUBJECT ( `cat $subjects` )
set subjects = (test_001)

foreach subj ($subjects)

cd $SUBJECTS_DIR/${subj}/${task}
set activeSubjectdirectory = `pwd`

echo "****************************************************************"
echo " AFNI | Functional preprocessing "
echo "****************************************************************"

if ( ${do_epi} == 'yes' ) then

cd $activeSubjectdirectory/func

echo "****************************************************************"
echo " AFNI | AFNI to NIFTI "
echo "****************************************************************"

3dAFNItoNIFTI \
-prefix ${study}.${subj}.${task}.nii \
concat_${study}.${subj}.${task}.+orig

echo "****************************************************************"
echo " AFNI | Despiking"
echo "****************************************************************"

#rm ${study}.${subj}.${task}.DSPK*

3dDespike \
-overwrite \
-prefix ${study}.${subj}.${task}.DSPK \
${study}.${subj}.${task}.nii

#rm ${study}.${subj}.${task}.nii

echo "****************************************************************"
echo " AFNI | 3dTshift "
echo "****************************************************************"

#rm ${study}.${subj}.${task}.tshft+orig*

3dTshift \
-ignore 1 \
-tzero 0 \
-TR ${TR} \
-tpattern ${slice_pattern} \
-prefix ${study}.${subj}.${task}.tshft \
${study}.${subj}.${task}.DSPK+orig

#rm ${study}.${subj}.${task}.DSPK+orig*

echo "****************************************************************"
echo " AFNI | Deobliquing "
echo "****************************************************************"

#rm ${study}.${subj}.${task}.deoblique+orig*

3dWarp \
-deoblique \
-prefix ${study}.${subj}.${task}.deoblique \
${study}.${subj}.${task}.tshft+orig

#rm ${study}.${subj}.${task}.tshft+orig*

echo "****************************************************************"
echo " AFNI | Motion Correction "
echo "****************************************************************"

#rm ${study}.${subj}.${task}.motion+orig*

3dvolreg \
-verbose \
-zpad 1 \
-base ${study}.${subj}.${task}.deoblique+orig'[10]' \
-1Dfile ${study}.${subj}.${task}.motion.1D \
-prefix ${study}.${subj}.${task}.motion \
${study}.${subj}.${task}.deoblique+orig

#rm ${study}.${subj}.${task}.deoblique+orig*

echo "****************************************************************"
echo making motion regressors
echo "****************************************************************"

# wtf is make_motion_regressors and y r params not passed to it. send help
matlab -nodesktop -nosplash -r "make_motion_regressors;exit"

cd ${activeSubjectdirectory}

echo "****************************************************************"
echo warping EPI to anat space and normalizing
echo "****************************************************************"

cp ${activeSubjectdirectory}/anat/*sksp* .

#rm ${study}.${subj}.${task}.motion_shft+orig*

#@Align_Centers -base ${study}.${subj}.anat.sksp+orig -dset ${study}.${subj}.${task}.motion+orig
#rm ${study}.${subj}.${task}.motion_py+orig*
#rm ${study}.${subj}.${task}.motion_shft_tlrc_py+tlrc*
#rm ${study}.${subj}.${task}.motion_tlrc_py+tlrc*

align_epi_anat.py \
-anat ${study}.${subj}.anat.sksp+orig \
-epi ${study}.${subj}.${task}.motion+orig \
-epi_base 6 \
-epi2anat \
-suffix _py \
-tlrc_apar ${study}.${subj}.anat.sksp_MNI+tlrc \
-anat_has_skull no \
-volreg off \
-tshift off \
-deoblique off \
-move

#use below command when running the @Align_Centers above
#align_epi_anat.py \
#-anat ${study}.${subj}.anat.sksp+orig \
#-epi ${study}.${subj}.${task}.motion_shft+orig \
#-epi_base 6 -epi2anat -suffix _py \
#-tlrc_apar ${study}.${subj}.anat.sksp_MNI+tlrc \
#-anat_has_skull no -volreg off -tshift off -deoblique off

#3drename ${study}.${subj}.${task}.motion_shft_tlrc_py+tlrc \
#${study}.${subj}.${task}.motion_tlrc_py
#rm ${study}.${subj}.${task}.mean*
#rm ${study}.${subj}.${task}.stdev_no_smooth*
#rm ${study}.${subj}.${task}.tSNR_no_smooth*

3dTstat \
-prefix ${study}.${subj}.${task}.mean \
${study}.${subj}.${task}.motion_tlrc_py+tlrc

3dTstat \
-stdev \
-prefix ${study}.${subj}.${task}.stdev_no_smooth \
${study}.${subj}.${task}.motion_tlrc_py+tlrc

3dcalc \
-a ${study}.${subj}.${task}.mean+tlrc \
-b ${study}.${subj}.${task}.stdev_no_smooth+tlrc \
-expr 'a/b' \
-prefix ${study}.${subj}.${task}.tSNR_no_smooth

#copy the mean image to reg check directory to check alignment and normalization
#cp ${study}.${subj}.${task}.mean+tlrc* ${rootpth}/regcheck/day1
#cp ${study}.${subj}.${task}.tSNR_no_smooth+tlrc* ${rootpth}/tSNR/day1
#rm ${study}.${subj}.${task}.motion+orig
#rm *malldump*

echo "****************************************************************"
echo regressing out csf and wm and global signal
echo "****************************************************************"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#first create masks for GM, WM, CSF and global signal
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

cd ${activeSubjectdirectory}/anat/

#rm ${activeSubjectdirectory}/anat/${study}.${subj}.anat.seg.fsl.MNI.3x3x3+tlrc*

3dfractionize \
-template ${activeSubjectdirectory}/${study}.${subj}.${task}.motion_tlrc_py+tlrc \
-input ${study}.${subj}.anat.seg.fsl.MNI+tlrc \
-prefix ${activeSubjectdirectory}/anat/${study}.${subj}.anat.seg.fsl.MNI.3x3x3 \
-clip .2 -vote

#rm ${study}.${subj}.anat.seg.fsl.MNI.CSF+tlrc*

3dcalc \
-overwrite \
-a ${study}.${subj}.anat.seg.fsl.MNI.3x3x3+tlrc \
-expr 'equals(a,1)' \
-prefix ${study}.${subj}.anat.seg.fsl.MNI.CSF

#rm ${study}.${subj}.anat.seg.fsl.MNI.GM+tlrc*

3dcalc \
-overwrite \
-a ${study}.${subj}.anat.seg.fsl.MNI.3x3x3+tlrc \
-expr 'equals(a,2)' \
-prefix ${study}.${subj}.anat.seg.fsl.MNI.GM

#rm ${study}.${subj}.anat.seg.fsl.MNI.WM+tlrc*

3dcalc \
-overwrite \
-a ${study}.${subj}.anat.seg.fsl.MNI.3x3x3+tlrc \
-expr 'equals(a,3)' \
-prefix ${study}.${subj}.anat.seg.fsl.MNI.WM

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# create an WM mask with 1 voxel erosion
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#rm ${study}.${subj}.anat.seg.fsl.MNI.WM.erode1+tlrc*

3dcalc \
-a ${study}.${subj}.anat.seg.fsl.MNI.WM+tlrc \
-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
-expr 'a*(1-amongst(0,b,c,d,e,f,g))' \
-prefix ${study}.${subj}.anat.seg.fsl.MNI.WM.erode1

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# create an WM mask with 2 voxel erosion
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#rm ${study}.${subj}.anat.seg.fsl.MNI.WM.erode2+tlrc*

3dcalc \
-a ${study}.${subj}.anat.seg.fsl.MNI.WM.erode1+tlrc \
-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
-expr 'a*(1-amongst(0,b,c,d,e,f,g))' \
-prefix ${study}.${subj}.anat.seg.fsl.MNI.WM.erode2

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#remove WM mask with 1 voxel
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

rm ${study}.${subj}.anat.seg.fsl.MNI.WM.erode1+tlrc

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# create an CSF mask with 1 voxel erosion
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#rm ${study}.${subj}.anat.seg.fsl.MNI.CSF.erode1+tlrc*

3dcalc \
-a ${study}.${subj}.anat.seg.fsl.MNI.CSF+tlrc \
-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
-expr 'a*(1-amongst(0,b,c,d,e,f,g))' \
-prefix ${study}.${subj}.anat.seg.fsl.MNI.CSF.erode1

cd ${activeSubjectdirectory}/${task}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#create CSF and WM regressors using maskSVD
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

3dmaskSVD \
-vnorm \
-sval 2 \
-mask ${activeSubjectdirectory}/anat/${study}.${subj}.anat.seg.fsl.MNI.CSF.erode1+tlrc \
-polort $polort \
./${study}.${subj}.${task}.motion_tlrc_py+tlrc > ./NOISE_REGRESSOR.${task}.CSF.1D

3dmaskSVD \
-vnorm \
-sval 2 \
-mask ${activeSubjectdirectory}/anat/${study}.${subj}.anat.seg.fsl.MNI.WM.erode2+tlrc \
-polort $polort \
./${study}.${subj}.${task}.motion_tlrc_py+tlrc > ./NOISE_REGRESSOR.${task}.WM.1D

#rm NOISE_REGRESSOR.${task}.WM.derivative.1D
#rm NOISE_REGRESSOR.${task}.CSF.derivative.1D

1d_tool.py \
-infile NOISE_REGRESSOR.${task}.WM.1D -derivative \
-write    NOISE_REGRESSOR.${task}.WM.derivative.1D

1d_tool.py \
-infile NOISE_REGRESSOR.${task}.CSF.1D -derivative \
-write    NOISE_REGRESSOR.${task}.CSF.derivative.1D

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# perform regression of WM, CSF, and motion
# keep residuals (errts = error timeseries)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#rm ${study}.${subj}.${task}.motion_tlrc_py.resid+tlrc*
#rm ${study}.${subj}.${task}.motion.resid+tlrc*

3dDeconvolve \
-input ${study}.${subj}.${task}.motion_tlrc_py+tlrc \
-polort $polort \
-nfirst 0 \
-num_stimts $num_stimts \
-stim_file 1 ${study}.${subj}.${task}.motion.1D'[0]' -stim_base 1 \
-stim_file 2 ${study}.${subj}.${task}.motion.1D'[1]' -stim_base 2 \
-stim_file 3 ${study}.${subj}.${task}.motion.1D'[2]' -stim_base 3 \
-stim_file 4 ${study}.${subj}.${task}.motion.1D'[3]' -stim_base 4 \
-stim_file 5 ${study}.${subj}.${task}.motion.1D'[4]' -stim_base 5 \
-stim_file 6 ${study}.${subj}.${task}.motion.1D'[5]' -stim_base 6 \
-stim_file 7 ${study}.${subj}.${task}.motion.square.1D'[0]' -stim_base 7 \
-stim_file 8 ${study}.${subj}.${task}.motion.square.1D'[1]' -stim_base 8 \
-stim_file 9 ${study}.${subj}.${task}.motion.square.1D'[2]' -stim_base 9 \
-stim_file 10 ${study}.${subj}.${task}.motion.square.1D'[3]' -stim_base 10 \
-stim_file 11 ${study}.${subj}.${task}.motion.square.1D'[4]' -stim_base 11 \
-stim_file 12 ${study}.${subj}.${task}.motion.square.1D'[5]' -stim_base 12 \
-stim_file 13 ${study}.${subj}.${task}.motion_pre_t.1D'[0]' -stim_base 13 \
-stim_file 14 ${study}.${subj}.${task}.motion_pre_t.1D'[1]' -stim_base 14 \
-stim_file 15 ${study}.${subj}.${task}.motion_pre_t.1D'[2]' -stim_base 15 \
-stim_file 16 ${study}.${subj}.${task}.motion_pre_t.1D'[3]' -stim_base 16 \
-stim_file 17 ${study}.${subj}.${task}.motion_pre_t.1D'[4]' -stim_base 17 \
-stim_file 18 ${study}.${subj}.${task}.motion_pre_t.1D'[5]' -stim_base 18 \
-stim_file 19 ${study}.${subj}.${task}.motion_pre_t_square.1D'[0]' -stim_base 19 \
-stim_file 20 ${study}.${subj}.${task}.motion_pre_t_square.1D'[1]' -stim_base 20 \
-stim_file 21 ${study}.${subj}.${task}.motion_pre_t_square.1D'[2]' -stim_base 21 \
-stim_file 22 ${study}.${subj}.${task}.motion_pre_t_square.1D'[3]' -stim_base 22 \
-stim_file 23 ${study}.${subj}.${task}.motion_pre_t_square.1D'[4]' -stim_base 23 \
-stim_file 24 ${study}.${subj}.${task}.motion_pre_t_square.1D'[5]' -stim_base 24 \
-stim_file 25 NOISE_REGRESSOR.${task}.CSF.1D'[0]' -stim_base 25 \
-stim_file 26 NOISE_REGRESSOR.${task}.CSF.derivative.1D'[0]' -stim_base 26 \
-stim_file 27 NOISE_REGRESSOR.${task}.WM.1D'[0]' -stim_base 27 \
-stim_file 28 NOISE_REGRESSOR.${task}.WM.derivative.1D'[0]' -stim_base 28 \
-x1D ${activeSubjectdirectory}/${subj}.${task}.resid.xmat.1D \
-x1D_stop


3dREMLfit \
-input ${study}.${subj}.${task}.motion_tlrc_py+tlrc \
-matrix ${activeSubjectdirectory}/${subj}.${task}.resid.xmat.1D \
-automask \
-Rbuck temp.bucket \
-Rerrts ${study}.${subj}.${task}.motion.resid

#rm ${study}.${subj}.${task}.motion_py+orig*
#rm ${study}.${subj}.${task}.motion_tlrc_py+tlrc*

echo "****************************************************************"
echo detrending
echo "****************************************************************"

rm ${study}.${subj}.${task}.detrend.resid+tlrc*

3dDetrend -overwrite -verb -polort 2 \
-prefix ${study}.${subj}.${task}.detrend.resid \
${study}.${subj}.${task}.motion.resid+tlrc

#rm ${study}.${subj}.${task}.motion.resid+tlrc*
#rm detrend.resid_w_mean+tlrc*

3dcalc \
-a ${study}.${subj}.${task}.detrend.resid+tlrc \
-b ${study}.${subj}.${task}.mean+tlrc \
-expr 'a+b' -prefix detrend.resid_w_mean

#rm ${study}.${subj}.${task}.detrend.resid+tlrc*

3drename \
detrend.resid_w_mean+tlrc \
${study}.${subj}.${task}.detrend.resid

#rm detrend.resid_w_mean+tlrc*

echo "****************************************************************"
echo spatial smoothing
echo "****************************************************************"

#rm ${study}.${subj}.${task}.smooth.resid+tlrc*

3dBlurToFWHM \
-input ${study}.${subj}.${task}.fourier.resid+tlrc \
-prefix ${study}.${subj}.${task}.smooth.resid \
-FWHM 8.0 \
-automask

#rm ${study}.${subj}.${task}.fourier.resid+tlrc*


echo "****************************************************************"
echo scaling to percent signal change
echo "****************************************************************"

#rm ${study}.${subj}.${task}.mean.resid+tlrc*
#rm ${study}.${subj}.${task}.mask.resid+tlrc*
#rm ${study}.${subj}.${task}.scaled.resid+tlrc*
#rm ${study}.${subj}.${task}.std.resid+tlrc*

3dTstat \
-prefix ${study}.${subj}.${task}.mean.resid \
${study}.${subj}.${task}.smooth.resid+tlrc


3dAutomask \
-dilate 1 \
-prefix ${study}.${subj}.${task}.mask.resid \
${study}.${subj}.${task}.smooth.resid+tlrc

3dcalc \
-a ${study}.${subj}.${task}.smooth.resid+tlrc \
-b ${study}.${subj}.${task}.mean.resid+tlrc \
-c ${study}.${subj}.${task}.mask.resid+tlrc \
-expr "c*((a/b)*100)" \
-float \
-prefix ${study}.${subj}.${task}.scaled.resid

#alternative method of scaling: expr "c*(100*((a-b)/abs(b)))"

#rm ${study}.${subj}.${task}.fourier.resid+tlrc*
#rm ${study}.${subj}.${task}.mean.resid+tlrc*
#rm ${study}.${subj}.${task}.mask.resid+tlrc*
#rm ${study}.${subj}.${task}.std.resid+tlrc*

echo "****************************************************************"
echo "DONE"
echo "****************************************************************"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# exit loop: anat preproc
endif

# exit loop: subjs
end

# return to project scripts
cd $ANALYSIS_DIR
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

