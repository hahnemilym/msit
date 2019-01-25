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
setenv ANALYSIS_DIR $MSIT_DIR/scripts

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

setenv DATA_DIR $SUBJECTS_DIR/${subj}/${task}

echo "****************************************************************"
echo " AFNI | Functional preprocessing | PART 1"
echo "****************************************************************"

if ( ${do_epi} == 'yes' ) then

cd ${DATA_DIR}/func

echo "****************************************************************"
echo " AFNI | Despiking (assumes SPM MBST script has been run)"
echo "****************************************************************"

3dDespike \
-overwrite \
-prefix ${study}.${subj}.${task}.DSPK \
a${study}.${subj}.func.nii

echo "****************************************************************"
echo " AFNI | Deobliquing "
echo "****************************************************************"

3dWarp \
-deoblique \
-prefix ${study}.${subj}.${task}.deoblique \
${study}.${subj}.${task}.DSPK+tlrc

echo "****************************************************************"
echo " AFNI | Motion Correction "
echo "****************************************************************"

3dvolreg \
-verbose \
-zpad 1 \
-base ${study}.${subj}.${task}.deoblique+tlrc'[10]' \
-1Dfile ${study}.${subj}.${task}.motion.1D \
-prefix ${study}.${subj}.${task}.motion \
${study}.${subj}.${task}.deoblique+tlrc

echo "****************************************************************"
echo " DONE"
echo "****************************************************************"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# exit loop: func preproc
endif

# exit loop: subjs
end

# return to project scripts
cd $ANALYSIS_DIR/../msit
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
