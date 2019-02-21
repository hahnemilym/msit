#! /bin/csh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# I. Set up environment
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# Local Directory
setenv MSIT_DIR /autofs/space/lilli_004/users/DARPA-MSIT/msit

# Subjects Directory
setenv SUBJECTS_DIR ${MSIT_DIR}/subjs

# Parameters Directory
setenv PARAMS_DIR ${MSIT_DIR}/bsm_params

# Analysis Directory
setenv ANALYSIS_DIR ${MSIT_DIR}/msit

setenv IM_PARAMS_DIR $MSIT_DIR/msit/params

# SUBJECT_LIST Directory
setenv SUBJECT_LIST ${PARAMS_DIR}/subjects.txt

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# II. Define parameters.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
set TR = 1.75

set study = msit
set task = (${study}_bsm)
set ROI = ba46

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# III. INDIVIDUAL ANALYSES
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#set subjects = ($SUBJECT_LIST)
#foreach SUBJECT ( `cat $subjects` )

set subjects = hc001
foreach SUBJECT ($subjects)

setenv DATA_DIR ${SUBJECTS_DIR}/${SUBJECT}/${task}
cd $DATA_DIR/results;

echo "*******************************************************************************"
echo " AFNI | Beta Series Method Analysis - Extract Betas | " ${SUBJECT}
echo "*******************************************************************************"

echo "*******************************************************************************"
echo " AFNI | 3dbucket | " ${SUBJECT}
echo "*******************************************************************************"

3dbucket -prefix LSS_avg LSS.${SUBJECT}_despike+tlrc

echo "*******************************************************************************"
echo " AFNI | 3dmaskave | " ${SUBJECT}
echo "*******************************************************************************"

3dmaskave -quiet-mask ${ROI}_mask_resamp+tlrc LSS_avg+tlrc > LSS_avg_file.1D

echo "*******************************************************************************"
echo " AFNI | Beta Series Method - Beta Extraction COMPLETE | " ${SUBJECT}
echo "*******************************************************************************"

cd ${ANALYSIS_DIR}

## End subject loop
end

