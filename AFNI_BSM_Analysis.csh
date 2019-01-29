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
setenv SUBJECT_LIST ${PARAMS_DIR}/subjects.txt

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# II. Define parameters.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
set TR = 1.75
set polort = A
# A = set polynomial order (detrending) automatically

set stim_Combined = $MSIT_DIR/msit/params/combined_durations.csv
set stim_Incongruent = $MSIT_DIR/msit/params/incongruent_durations.csv
set stim_Congruent = $MSIT_DIR/msit/params/congruent_durations.csv

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

#mkdir bsm;

echo "*******************************************************************************"
echo " AFNI | Beta Series Method Analysis "
echo "*******************************************************************************"

echo "*******************************************************************************"
echo " AFNI | Copy 1D Censor Data "
echo "*******************************************************************************"

rm ${DATA_DIR}/bsm/${study}.${SUBJECT}.${task}.censor.T.1D

1d_tool.py \
-infile ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.censor.1D \
-transpose \
-write ${DATA_DIR}/bsm/${study}.${SUBJECT}.${task}.censor.T.1D

echo "*******************************************************************************"
echo " AFNI | 3dDeconvolve task "
echo "*******************************************************************************"

#You can also use dmBLOCK with -stim_times_IM, in which case    
#each time in the 'tname' file should have just ONE extra
#parameter -- the duration -- married to it, as in '30:15',     
#meaning a block of duration 15 seconds starting at t=30 s.

3dDeconvolve \
-force_TR $TR \
-input ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc \
-nfirst 0 \
-censor ${DATA_DIR}/bsm/${study}.${SUBJECT}.${task}.censor.T.1D \
-polort A \
-num_stimts $num_stimts \
-stim_times_IM 1 $stim_Combined "dmBLOCK" \
-stim_label 1 BSM_IM_IC_Combined \
-stim_times_IM 2 $stim_Incongruent "dmBLOCK" \
-stim_label 2 BSM_IM_Incongruent \
-stim_times_IM 3 $stim_Congruent "dmBLOCK" \
-stim_label 3 BSM_IM_Congruent \
-x1D ${DATA_DIR}/bsm/LSS.xmat.1D \
-allzero_OK \
-nobucket \
-x1D_stop

echo "*******************************************************************************"
echo " AFNI | 3dLSS "
echo "*******************************************************************************"

rm ${DATA_DIR}/bsm/LSS.${SUBJECT}

3dLSS \
-input ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc \
-matrix ${DATA_DIR}/bsm/LSS.xmat.1D \
-prefix ${DATA_DIR}/bsm/LSS.${SUBJECT}

echo "*******************************************************************************"
echo " AFNI | 3dDespike "
echo "*******************************************************************************"

rm ${DATA_DIR}/bsm/LSS.${SUBJECT}_despike+tlrc

3dDespike \
-prefix ${DATA_DIR}/bsm/LSS.${SUBJECT}_despike \
${DATA_DIR}/bsm/LSS.${SUBJECT}+tlrc

echo "*******************************************************************************"
echo " AFNI | Beta Series Method COMPLETE: " ${SUBJECT}
echo "*******************************************************************************"

cd ${ANALYSIS_DIR}

## End subject loop
end

