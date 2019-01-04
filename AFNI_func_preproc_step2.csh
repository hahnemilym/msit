#! /bin/csh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# To-do:
# 1. Siemens interleaved slice pattern ??
# ---> mimick general_multiband_slicetime.m
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

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

# formerly 'seq+z'. Here, slices interleaved and odd...
#set slice_pattern = 'FROM_IMAGE'
#set slice_pattern = '@filename'
set slice_pattern = 'alt+z'

# number of regressors [WM, CSF, motion]
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

# expand_nii_bandit_task.m - shows orig dir struct
# matlab -nodesktop -nosplash -r "expand_nii_bandit_task;exit"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Initialize subject(s) environment
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#set subjects = ($SUBJECT_LIST)
#foreach SUBJECT ( `cat $subjects` )
set subjects = (test_002)

foreach subj ($subjects)

echo "****************************************************************"
echo " AFNI | Functional preprocessing | PART 2"
echo "****************************************************************"

if ( ${do_epi} == 'yes' ) then

setenv DATA_DIR $SUBJECTS_DIR/${subj}/${task}
cd ${DATA_DIR}/func

echo "****************************************************************"
echo " AFNI | Warp Functional (EPI) to Structural (MEMPRAGE) Space "
echo "****************************************************************"

cp $DATA_DIR/anat/*sksp* ${DATA_DIR}/func

#rm ${study}.${subj}.${task}.motion_shft+orig*

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
-giant_move

echo "****************************************************************"
echo " AFNI | Normalise Coregistered Data"
echo "****************************************************************"

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

#rm ${study}.${subj}.${task}.motion+orig
#rm *malldump*

echo "****************************************************************"
echo " AFNI | Generate Nuisance Regressor Masks: CSF, WM "
echo "****************************************************************"

cd ${DATA_DIR}/anat/

#rm ${DATA_DIR}/anat/${study}.${subj}.anat.seg.fsl.MNI.3x3x3+tlrc*

3dfractionize \
-template ${DATA_DIR}/func/${study}.${subj}.${task}.motion_tlrc_py+tlrc \
-input ${study}.${subj}.anat.seg.fsl.MNI+tlrc \
-prefix ${study}.${subj}.anat.seg.fsl.MNI.3x3x3 \
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

echo "****************************************************************"
echo " AFNI | Create WM Mask w/ 1 Voxel Erosion "
echo "****************************************************************"

#rm ${study}.${subj}.anat.seg.fsl.MNI.WM.erode1+tlrc*

cd ${DATA_DIR}/anat/

3dcalc \
-a ${study}.${subj}.anat.seg.fsl.MNI.WM+tlrc \
-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
-expr 'a*(1-amongst(0,b,c,d,e,f,g))' \
-prefix ${study}.${subj}.anat.seg.fsl.MNI.WM.erode1

echo "****************************************************************"
echo " AFNI | Create WM Mask w/ 2 Voxel Erosion "
echo "****************************************************************"

cd ${DATA_DIR}/anat/

#rm ${study}.${subj}.anat.seg.fsl.MNI.WM.erode2+tlrc*

3dcalc \
-a ${study}.${subj}.anat.seg.fsl.MNI.WM.erode1+tlrc \
-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
-expr 'a*(1-amongst(0,b,c,d,e,f,g))' \
-prefix ${study}.${subj}.anat.seg.fsl.MNI.WM.erode2

echo "****************************************************************"
echo " AFNI | Remove WM Mask w/ 1 Voxel Erosion "
echo "****************************************************************"

cd ${DATA_DIR}/anat/
rm ${study}.${subj}.anat.seg.fsl.MNI.WM.erode1+tlrc

echo "****************************************************************"
echo " AFNI | Create CSF Mask w/ 1 Voxel Erosion "
echo "****************************************************************"

#rm ${study}.${subj}.anat.seg.fsl.MNI.CSF.erode1+tlrc*

3dcalc \
-a ${study}.${subj}.anat.seg.fsl.MNI.CSF+tlrc \
-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
-expr 'a*(1-amongst(0,b,c,d,e,f,g))' \
-prefix ${study}.${subj}.anat.seg.fsl.MNI.CSF.erode1

echo "****************************************************************"
echo " AFNI | Create CSF and WM Nuisance Regressors Using maskSVD "
echo "****************************************************************"

cd ${DATA_DIR}/func/

3dmaskSVD \
-vnorm \
-sval 2 \
-mask ${DATA_DIR}/anat/${study}.${subj}.anat.seg.fsl.MNI.CSF.erode1+tlrc \
-polort $polort \
./${study}.${subj}.${task}.motion_tlrc_py+tlrc > ./NOISE_REGRESSOR.${task}.CSF.1D

3dmaskSVD \
-vnorm \
-sval 2 \
-mask ${DATA_DIR}/anat/${study}.${subj}.anat.seg.fsl.MNI.WM.erode2+tlrc \
-polort $polort \
./${study}.${subj}.${task}.motion_tlrc_py+tlrc > ./NOISE_REGRESSOR.${task}.WM.1D

rm NOISE_REGRESSOR.${task}.WM.derivative.1D
rm NOISE_REGRESSOR.${task}.CSF.derivative.1D

1d_tool.py \
-infile NOISE_REGRESSOR.${task}.WM.1D -derivative \
-write    NOISE_REGRESSOR.${task}.WM.derivative.1D

1d_tool.py \
-infile NOISE_REGRESSOR.${task}.CSF.1D -derivative \
-write    NOISE_REGRESSOR.${task}.CSF.derivative.1D

echo "****************************************************************"
echo " AFNI | Regress out WM, CSF, and Motion "
echo " Retain Residuals (errts = error timeseries) "
echo "****************************************************************"

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
-x1D ${DATA_DIR}/func/${subj}.${task}.resid.xmat.1D \
-x1D_stop


3dREMLfit \
-input ${study}.${subj}.${task}.motion_tlrc_py+tlrc \
-matrix ${DATA_DIR}/func/${subj}.${task}.resid.xmat.1D \
-automask \
-Rbuck temp.bucket \
-Rerrts ${study}.${subj}.${task}.motion.resid

#rm ${study}.${subj}.${task}.motion_py+orig*
#rm ${study}.${subj}.${task}.motion_tlrc_py+tlrc*

echo "****************************************************************"
echo " AFNI | Polynomial Detrending "
echo "****************************************************************"

#rm ${study}.${subj}.${task}.detrend.resid+tlrc*

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
echo " AFNI | Spatial Smoothing "
echo "****************************************************************"

#rm ${study}.${subj}.${task}.smooth.resid+tlrc*
# REMOVED: -input ${study}.${subj}.${task}.fourier.resid+tlrc

3dBlurToFWHM \
-input ${study}.${subj}.${task}.detrend.resid+tlrc \
-prefix ${study}.${subj}.${task}.smooth.resid \
-FWHM 8.0 \
-automask

#rm ${study}.${subj}.${task}.fourier.resid+tlrc*

echo "****************************************************************"
echo " DONE"
echo "****************************************************************"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# exit loop: func preproc
endif

# exit loop: subjs
end

# return to project scripts
cd $ANALYSIS_DIR
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

