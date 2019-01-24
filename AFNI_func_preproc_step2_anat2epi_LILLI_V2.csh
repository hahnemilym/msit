#! /bin/csh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Configure environment
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# Local Directory
setenv DIR /autofs/space/lilli_004/users/DARPA-MSIT

# Project Directory
setenv MSIT_DIR $DIR/msit

# Subjects Directory
setenv SUBJECTS_DIR $MSIT_DIR/subjs

# Parameters Directory
setenv PARAMS_DIR $MSIT_DIR/bsm_params/

# Analyses Directory
setenv ANALYSIS_DIR $MSIT_DIR/msit

# Subjects List
setenv SUBJECT_LIST $PARAMS_DIR/subjects_list_01-10-19.txt

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Define parameters
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

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

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Initialize subject(s) environment
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#set subjects = ($SUBJECT_LIST)
#foreach subj ( `cat $subjects` )

set subjects = (hc001)
foreach subj ($subjects)

echo "****************************************************************"
echo " AFNI | Functional preprocessing | PART 2"
echo "****************************************************************"

if ( ${do_epi} == 'yes' ) then

setenv DATA_DIR $SUBJECTS_DIR/${subj}/${task}

echo "****************************************************************"
echo " AFNI | 3dResample "
echo "****************************************************************"

cd ${DATA_DIR}/func

3dresample \
-prefix ${DATA_DIR}/func/${study}.${subj}.${task}.motion.1x1x1 \
-input ${DATA_DIR}/func/${study}.${subj}.${task}.motion.rs+tlrc \
-dxyz 1.0 1.0 1.0

echo "****************************************************************"
echo " AFNI | Warp Structural (MEMPRAGE) to Functional (EPI) Space "
echo "****************************************************************"

cd ${DATA_DIR}

align_epi_anat.py \
-anat ${DATA_DIR}/anat/${study}.${subj}.anat+orig \
-epi ${DATA_DIR}/func/${study}.${subj}.${task}.motion.1x1x1+tlrc \
-tlrc_apar ${DATA_DIR}/anat/${study}.${subj}.anat_MNI+tlrc \
-epi_base 6 \
-epi2anat \
-anat_has_skull no \
-volreg off \
-tshift off \
-deoblique off \
-suffix .py \
-ginormous_move

rm *malldump*

echo "****************************************************************"
echo " AFNI | 3dAutomask"
echo "****************************************************************"

cd ${DATA_DIR}/func

3dAutomask \
-prefix ${study}.${subj}.${task}.motion.mask+tlrc ${study}.${subj}.${task}.motion.1x1x1_tlrc.py+tlrc \
-clfrac .9 \
-eclip \
-peels 4 \
-SI 180

echo "****************************************************************"
echo " AFNI | Normalise Data - Calculate Coefficient of Variation "
echo "****************************************************************"

3dTstat \
-prefix ${study}.${subj}.${task}.mean \
${study}.${subj}.${task}.motion.1x1x1_tlrc.py+tlrc

3dTstat \
-stdev \
-prefix ${study}.${subj}.${task}.stdev_no_smooth \
${study}.${subj}.${task}.motion.1x1x1_tlrc.py+tlrc

3dcalc \
-a ${study}.${subj}.${task}.mean+tlrc \
-b ${study}.${subj}.${task}.stdev_no_smooth+tlrc \
-expr 'a/b' \
-prefix ${study}.${subj}.${task}.tSNR_no_smooth

rm *malldump*

echo "****************************************************************"
echo " AFNI | Generate Nuisance Regressor Masks: CSF, WM "
echo "****************************************************************"

cd ${DATA_DIR}/anat/

3dfractionize \
-template ${DATA_DIR}/func/${study}.${subj}.${task}.motion.1x1x1_tlrc.py+tlrc \
-input ${study}.${subj}.anat.seg.fsl.MNI+tlrc \
-prefix ${study}.${subj}.anat.seg.fsl.MNI.3x3x3 \
-clip .2 -vote

3dcalc \
-overwrite \
-a ${study}.${subj}.anat.seg.fsl.MNI.3x3x3+tlrc \
-expr 'equals(a,1)' \
-prefix ${study}.${subj}.anat.seg.fsl.MNI.CSF

3dcalc \
-overwrite \
-a ${study}.${subj}.anat.seg.fsl.MNI.3x3x3+tlrc \
-expr 'equals(a,2)' \
-prefix ${study}.${subj}.anat.seg.fsl.MNI.GM

3dcalc \
-overwrite \
-a ${study}.${subj}.anat.seg.fsl.MNI.3x3x3+tlrc \
-expr 'equals(a,3)' \
-prefix ${study}.${subj}.anat.seg.fsl.MNI.WM

echo "****************************************************************"
echo " AFNI | Create WM Mask w/ 1 Voxel Erosion "
echo "****************************************************************"

3dcalc \
-a ${study}.${subj}.anat.seg.fsl.MNI.WM+tlrc \
-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
-expr 'a*(1-amongst(0,b,c,d,e,f,g))' \
-prefix ${study}.${subj}.anat.seg.fsl.MNI.WM.erode1

echo "****************************************************************"
echo " AFNI | Create WM Mask w/ 2 Voxel Erosion "
echo "****************************************************************"

3dcalc \
-a ${study}.${subj}.anat.seg.fsl.MNI.WM.erode1+tlrc \
-b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
-expr 'a*(1-amongst(0,b,c,d,e,f,g))' \
-prefix ${study}.${subj}.anat.seg.fsl.MNI.WM.erode2

echo "****************************************************************"
echo " AFNI | Remove WM Mask w/ 1 Voxel Erosion "
echo "****************************************************************"

rm ${study}.${subj}.anat.seg.fsl.MNI.WM.erode1+tlrc

echo "****************************************************************"
echo " AFNI | Create CSF Mask w/ 1 Voxel Erosion "
echo "****************************************************************"

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
./${study}.${subj}.${task}.motion.1x1x1_tlrc.py+tlrc > ./NOISE_REGRESSOR.${task}.CSF.1D

3dmaskSVD \
-vnorm \
-sval 2 \
-mask ${DATA_DIR}/anat/${study}.${subj}.anat.seg.fsl.MNI.WM.erode2+tlrc \
-polort $polort \
./${study}.${subj}.${task}.motion.1x1x1_tlrc.py+tlrc > ./NOISE_REGRESSOR.${task}.WM.1D

1d_tool.py \
-infile NOISE_REGRESSOR.${task}.WM.1D -derivative \
-write NOISE_REGRESSOR.${task}.WM.derivative.1D

1d_tool.py \
-infile NOISE_REGRESSOR.${task}.CSF.1D -derivative \
-write NOISE_REGRESSOR.${task}.CSF.derivative.1D

echo "****************************************************************"
echo " AFNI | Regress out WM, CSF, and Motion "
echo " Retain Residuals (errts = error timeseries) "
echo "****************************************************************"

3dDeconvolve \
-input ${study}.${subj}.${task}.motion.1x1x1_tlrc.py+tlrc \
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
-input ${study}.${subj}.${task}.motion.1x1x1_tlrc.py+tlrc \
-matrix ${DATA_DIR}/func/${subj}.${task}.resid.xmat.1D \
-automask \
-Rbuck temp.bucket \
-Rerrts ${study}.${subj}.${task}.motion.resid

echo "****************************************************************"
echo " AFNI | Polynomial Detrending "
echo "****************************************************************"

3dDetrend -overwrite -verb -polort 2 \
-prefix ${study}.${subj}.${task}.detrend.resid \
${study}.${subj}.${task}.motion.resid+tlrc

3dcalc \
-a ${study}.${subj}.${task}.detrend.resid+tlrc \
-b ${study}.${subj}.${task}.mean+tlrc \
-expr 'a+b' \
-prefix detrend.resid_w_mean

3drename \
detrend.resid_w_mean+tlrc \
${study}.${subj}.${task}.detrend.resid

echo "****************************************************************"
echo " High-Pass temporal filtering task 128 s "
echo "****************************************************************"

3dFourier \
-prefix ${study}.${subj}.${task}.fourier.resid \
-highpass .0078 \
-retrend ${study}.${subj}.${task}.detrend.resid+tlrc

echo "****************************************************************"
echo " Spatial Smoothing "
echo "****************************************************************"

3dBlurToFWHM \
-input ${study}.${subj}.${task}.fourier.resid+tlrc \
-prefix ${study}.${subj}.${task}.smooth.resid \
-FWHM 6.0 \
-automask

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

