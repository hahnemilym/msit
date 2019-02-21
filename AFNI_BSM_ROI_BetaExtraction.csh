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

#set subjects = ($SUBJECT_LIST)
#foreach SUBJECT ( `cat $subjects` )

set subjects = hc001
foreach SUBJECT ($subjects)

foreach ROI (dACC L_dlPFC R_dlPFC IFG)

setenv DATA_DIR ${SUBJECTS_DIR}/${SUBJECT}/${task}
cd $DATA_DIR/results;

echo "*******************************************************************************"
echo " AFNI | BSM Analysis - Extract $ROI Betas for $SUBJECT "
echo "*******************************************************************************"


echo "*******************************************************************************"
echo " AFNI | 3dcopy & 3dresample | Fit masks to func data       | " 
echo " AFNI | 3dbucket            | Stage func file to be masked | "
echo " AFNI | 3dmaskave           | Average voxels in mask       | "
echo "*******************************************************************************"

if ($ROI == 'IFG') then

rm *${ROI}*

3dcopy \
${ROI_DIR}/${ROI}+tlrc ${ROI}+tlrc

3dresample \
-master LSS.${SUBJECT}_despike+tlrc \
-prefix ${ROI}_mask_resamp \
-input ${ROI}+tlrc

3dbucket \
-prefix ${ROI}_LSS_avg LSS.${SUBJECT}_despike+tlrc

3dmaskave \
-quiet \
-mask ${ROI}_mask_resamp+tlrc ${ROI}_LSS_avg+tlrc > ${ROI}_LSS_avg_file.1D

1dplot ${ROI}_LSS_avg_file.1D

else if ($ROI == 'dACC' || $ROI == 'L_dlPFC' || $ROI == 'R_dlPFC') then

rm *${ROI}*

3dcopy \
${ROI_DIR}/${ROI}.nii ${ROI}.nii

3dresample \
-master LSS.${SUBJECT}_despike+tlrc \
-prefix ${ROI}_mask_resamp \
-input ${ROI}.nii

3dbucket \
-prefix ${ROI}_LSS_avg LSS.${SUBJECT}_despike+tlrc

3dmaskave \
-quiet \
-mask ${ROI}_mask_resamp+tlrc ${ROI}_LSS_avg+tlrc > ${ROI}_LSS_avg_file.1D

1dplot ${ROI}_LSS_avg_file.1D

else
echo "Check ROIs"

endif

echo "*******************************************************************************"
echo " AFNI | Beta Series Method - Beta Extraction COMPLETE | " ${SUBJECT}
echo "*******************************************************************************"

## End ROI loop
end

## End subject loop
end

cd ${ANALYSIS_DIR}

