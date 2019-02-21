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

setenv ROI_DIR $SUBJECTS_DIR/masks/AFNI_ROIs

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# II. Define parameters.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
set TR = 1.75

set study = msit
set task = (${study}_bsm)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# III. INDIVIDUAL ANALYSES
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

set ROI = IFG

#dACC
#L_dlPFC
#R_dlPFC
#IFG

#set subjects = ($SUBJECT_LIST)
#foreach SUBJECT ( `cat $subjects` )

set subjects = hc001
foreach SUBJECT ($subjects)

setenv DATA_DIR ${SUBJECTS_DIR}/${SUBJECT}/${task}
cd $DATA_DIR/results;

echo "*******************************************************************************"
echo " AFNI | BSM Analysis - Extract Betas | " ${SUBJECT}
echo "*******************************************************************************"

echo "*******************************************************************************"
echo " AFNI | Configure environment | " ${SUBJECT}
echo "*******************************************************************************"

echo "Removing previous $ROI files"
rm *${ROI}*

#echo "3dcopy $ROI mask"
#3dcopy ${ROI_DIR}/${ROI}.nii ${ROI}.nii
3dcopy ${ROI_DIR}/${ROI}+tlrc ${ROI}+tlrc

# Uncomment for IFG beta extraction
#echo "creating IFG mask"
#whereami -mask_atlas_region TT_Daemon::inf_frontal_gyrus

echo "*******************************************************************************"
echo " AFNI | 3dbucket - Stage func file to be masked | " ${SUBJECT}
echo "*******************************************************************************"

3dbucket -prefix ${ROI}_LSS_avg LSS.${SUBJECT}_despike+tlrc

echo "*******************************************************************************"
echo " AFNI | 3dresample - Force $ROI mask to match dimensions of BSM | " ${SUBJECT}
echo "*******************************************************************************"

#3dresample -master LSS.${SUBJECT}_despike+tlrc -prefix ${ROI}_mask_resamp -input ${ROI}.nii

# Uncomment for IFG beta extraction
3dresample -master LSS.${SUBJECT}_despike+tlrc -prefix ${ROI}_mask_resamp -input ${ROI}+tlrc

echo "*******************************************************************************"
echo " AFNI | 3dmaskave - Average voxels in $ROI mask | " ${SUBJECT}
echo "*******************************************************************************"

3dmaskave -quiet -mask ${ROI}_mask_resamp+tlrc ${ROI}_LSS_avg+tlrc > ${ROI}_LSS_avg_file.1D

1dplot ${ROI}_LSS_avg_file.1D

echo "*******************************************************************************"
echo " AFNI | Beta Series Method - Beta Extraction COMPLETE | " ${SUBJECT}
echo "*******************************************************************************"

cd ${ANALYSIS_DIR}

## End subject loop
end

