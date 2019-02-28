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

foreach ROI (IFG dACC R_dlPFC L_dlPFC)
#foreach ROI (L_dlPFC)

setenv DATA_DIR ${SUBJECTS_DIR}/${SUBJECT}/${task}
cd $DATA_DIR;

echo "*******************************************************************************"
echo " AFNI | BSM Analysis - Extract $ROI Betas for $SUBJECT "
echo "*******************************************************************************"

echo "*******************************************************************************"
echo " AFNI | 3dcopy & 3dresample | Fit masks to func data       | " 
echo " AFNI | 3dbucket            | Stage func file to be masked | "
echo " AFNI | 3dmaskave           | Average voxels in mask       | "
echo "*******************************************************************************"

cd $DATA_DIR/bsm;

rm ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg_file.1D*;
rm ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg*;

3dbucket -prefix ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg ${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}_despike+tlrc

3dmaskave \
-quiet \
#-perc 90 \
-mask $DATA_DIR/bsm/$ROI.${SUBJECT}.mask+tlrc ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg+tlrc > ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg_file.1D

1dplot ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg_file.1D

echo "*******************************************************************************"
echo " AFNI | Beta Series Method - Beta Extraction COMPLETE | " ${SUBJECT}
echo "*******************************************************************************"

## End ROI loop
end

## End subject loop
end

cd ${ANALYSIS_DIR}

