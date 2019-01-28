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

setenv PARAMS_DIR /autofs/space/lilli_004/users/DARPA-MSIT/msit/msit/params/

# SUBJECT_LIST Directory
setenv SUBJECT_LIST ${PARAMS_DIR}/subjects_list_01-10-19.txt

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# II. Define parameters.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
set TR = 1.75
set polort = A
# A = set polynomial order (detrending) automatically

set stim_txt_file = $MSIT_DIR/msit/params/msit_bsm_stim.csv
set num_stimts = 1
# e.g. num_stimts = 2; includes C and I conditions separately

set study = msit
set task = (${study}_bsm)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# III. INDIVIDUAL ANALYSES
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#set subjects = ($SUBJECT_LIST)
#foreach SUBJECT ( `cat $subjects` )

set subjects = hc001
foreach SUBJECT ($subjects)

setenv DATA_DIR ${SUBJECTS_DIR}/${SUBJECT}/${task}
cd $DATA_DIR;

mkdir bsm;

echo "*******************************************************************************"
echo " AFNI | Beta Series Method Analysis "
echo "*******************************************************************************"

echo "*******************************************************************************"
echo " AFNI | Copy 1D Censor Data "
echo "*******************************************************************************"

cp ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.censor.1D > ${DATA_DIR}/bsm/${study}.${SUBJECT}.${task}.censor.1D

echo "*******************************************************************************"
echo " AFNI | 3dDeconvolve task "
echo "*******************************************************************************"

3dDeconvolve \
-force_TR $TR \
-input ${DATA_DIR}/func/msit.hc001.msit_bsm.smooth.resid+tlrc \
-nfirst 0 \
-censor ${DATA_DIR}/bsm/msit.hc001.msit_bsm.censor.1D \
-polort A \
-num_stimts $num_stimts \
-stim_times_IM 1 $PARAMS_DIR/msit_bsm_stim.csv "BLOCK(1,1)" \
-stim_label 1 stim_times_IM_label \
-x1D ${DATA_DIR}/bsm/LSS.xmat.1D \
-allzero_OK \
-nobucket \
-x1D_stop

echo "*******************************************************************************"
echo " AFNI | 3dLSS "
echo "*******************************************************************************"

3dLSS \
-input ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc \
-matrix ${DATA_DIR}/bsm/LSS.xmat.1D \
-prefix ${DATA_DIR}/bsm/LSS.${SUBJECT}

echo "*******************************************************************************"
echo " AFNI | 3dDespike "
echo "*******************************************************************************"

3dDespike \
-prefix ${DATA_DIR}/bsm/LSS.${SUBJECT}_despike \
${DATA_DIR}/bsm/LSS.${SUBJECT}

echo "*******************************************************************************"
echo " AFNI | Beta Series Method COMPLETE: " ${SUBJECT}
echo "*******************************************************************************"

cd ${ANALYSIS_DIR}/msit

## End subject loop
end

