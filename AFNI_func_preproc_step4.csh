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

set subjects = ($SUBJECT_LIST)
foreach subj ( `cat $subjects` )

#set subjects = (hc001)
#foreach subj ($subjects)

echo "****************************************************************"
echo " AFNI | Functional preprocessing | PART 3"
echo "****************************************************************"

if ( ${do_epi} == 'yes' ) then

setenv DATA_DIR $SUBJECTS_DIR/${subj}/${task}

cd ${DATA_DIR}/func

echo "****************************************************************"
echo " AFNI | Polynomial Detrending "
echo "****************************************************************"

cd ${DATA_DIR}/func/

3dDetrend \
-overwrite \
-verb \
-polort 2 \
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
echo " EPI High-Pass Filter - 128 s "
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
-FWHM 8.0 \
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

