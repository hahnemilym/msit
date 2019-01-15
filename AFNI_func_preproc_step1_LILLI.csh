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

# formerly 'seq+z'. Here, slices interleaved and odd...
#set slice_pattern = 'FROM_IMAGE'
#set slice_pattern = 'alt+z'
#set slice_pattern = '@filename'

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

#echo "****************************************************************"
#echo " AFNI | AFNI to NIFTI "
#echo "****************************************************************"

#3dAFNItoNIFTI \
#-prefix ${DATA_DIR}/func/${study}.${subj}.${task}.nii \
#${DATA_DIR}/func/${study}.${subj}.${task}

echo "****************************************************************"
echo " AFNI | Despiking (assumes spm mbst has been run)"
echo "****************************************************************"

rm ${study}.${subj}.${task}.DSPK*

3dDespike \
-overwrite \
-prefix ${study}.${subj}.${task}.DSPK \
a${study}.${subj}.func.nii

rm ${study}.${subj}.${task}.nii

#echo "****************************************************************"
#echo " AFNI | 3dTshift "
#echo "****************************************************************"

#rm ${study}.${subj}.${task}.tshft+orig*

#3dTshift \
#-ignore 1 \
#-tzero 0 \
#-TR ${TR} \
#-tpattern ${slice_pattern} \
#-prefix ${study}.${subj}.${task}.tshft \
#${study}.${subj}.${task}.DSPK+orig

#rm ${study}.${subj}.${task}.DSPK+orig*

echo "****************************************************************"
echo " AFNI | Deobliquing "
echo "****************************************************************"

rm ${study}.${subj}.${task}.deoblique+orig*

3dWarp \
-deoblique \
-prefix ${study}.${subj}.${task}.deoblique \
${study}.${subj}.${task}.DSPK+tlrc

rm ${study}.${subj}.${task}.DSPK+orig*

echo "****************************************************************"
echo " AFNI | Motion Correction "
echo "****************************************************************"

rm ${study}.${subj}.${task}.motion+orig*

3dvolreg \
-verbose \
-zpad 1 \
-base ${study}.${subj}.${task}.deoblique+tlrc'[10]' \
-1Dfile ${study}.${subj}.${task}.motion.1D \
-prefix ${study}.${subj}.${task}.motion \
${study}.${subj}.${task}.deoblique+tlrc

rm ${study}.${subj}.${task}.deoblique+orig*

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
