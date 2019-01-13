#! /bin/csh


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
## TO-DO
## Check new arc preproc script for how to generate STC file and integrate into func preproc 1,2
## Debug subj who crashed on 3dAutomask
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# I. Set up environment
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# Local Directory
setenv MSIT_DIR /Users/emilyhahn/projects/msit/

# Subjects Directory
setenv SUBJECTS_DIR ${MSIT_DIR}/subjs

# Parameters Directory
setenv PARAMS_DIR ${MSIT_DIR}/bsm_params

# Analysis Directory
setenv ANALYSIS_DIR ${MSIT_DIR}/scripts

# SUBJECT_LIST Directory
#setenv SUBJECT_LIST ${PARAMS_DIR}/subjects_list_01-11-19.txt

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# II. Define parameters.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
set FWHM = 6
set TR = 1.75
set polort = A
# A = set polynomial order (detrending param) automatically

set stim_txt_file = msit_bsm_stim.csv
set num_stimts = 1
# E.G. num_stimts = 3; includes shock, rating, CS_presentation.
# Change this param and to = 2 if comparing C, I conditions seprately. Also stim_times_IM and stim_label

set study = msit
set task = (${study}_bsm)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# III. INDIVIDUAL ANALYSES
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#set subjects = ($SUBJECT_LIST)
#foreach SUBJECT ( `cat $subjects` )

set subjects = test_002
foreach SUBJECT ($subjects)

setenv DATA_DIR ${SUBJECTS_DIR}/${SUBJECT}/${task}
cd $DATA_DIR

echo "*******************************************************************************"
echo " AFNI | Beta Series Method Analysis "
echo "*******************************************************************************"

##rm ${DATA_DIR}/bsm/LSS.xmat.1D
##rm ${DATA_DIR}/bsm/LSS.${SUBJECT}.nii
#
#echo "*******************************************************************************"
#echo " AFNI | 1dtranspose 1D censor data "
#echo "*******************************************************************************"
#
#rm ${DATA_DIR}/func/censor_file
#${DATA_DIR}/func/func_t
#
#1dtranspose ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.censor.1D > ${DATA_DIR}/bsm/func_t
#
#1dtranspose ${DATA_DIR}/bsm/func_t > ${DATA_DIR}/bsm/censor_file
#
#echo "*******************************************************************************"
#echo " AFNI | 3dAFNItoNIFTI "
#echo "*******************************************************************************"
#
#3dAFNItoNIFTI \
#-prefix ${DATA_DIR}/bsm/${study}.${SUBJECT}.${task}.smooth.resid+tlrc.nii \
#${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc

echo "*******************************************************************************"
echo " AFNI | 3dDeconvolve task "
echo "*******************************************************************************"

3dDeconvolve \
-force_TR $TR \
-input ${DATA_DIR}/bsm/${study}.${SUBJECT}.${task}.smooth.resid+tlrc.nii \
-nfirst 0 \
-censor ${DATA_DIR}/bsm/censor_file \
-polort $polort \
-num_stimts $num_stimts \
-stim_times_IM 1 ${DATA_DIR}/bsm/${stim_txt_file} "BLOCK(1,1)" \
-stim_label 1 stim_times_IM_label \
-x1D ${DATA_DIR}/bsm/LSS.xmat.1D \
-allzero_OK \
-nobucket \
-x1D_stop

#echo "*******************************************************************************"
#echo " AFNI | 3dLSS "
#echo "*******************************************************************************"
#
#3dLSS \
#-input ${DATA_DIR}/bsm/${study}.${SUBJECT}.${task}.smooth.resid+tlrc.nii \
#-matrix ${DATA_DIR}/bsm/LSS.xmat.1D \
#-prefix ${DATA_DIR}/bsm/LSS.${SUBJECT}.nii
#
#echo "*******************************************************************************"
#echo " AFNI | 3dDespike "
#echo "*******************************************************************************"
#
##rm ${DATA_DIR}/bsm/LSS.${SUBJECT}_despike.nii
#
#3dDespike \
#-prefix ${DATA_DIR}/bsm/LSS.${SUBJECT}_despike.nii \
#${DATA_DIR}/bsm/LSS.${SUBJECT}.nii
#
#echo "*******************************************************************************"
#echo " AFNI | Beta Series Method COMPLETE: " ${SUBJECT}
#echo "*******************************************************************************"

cd ${ANALYSIS_DIR}

## End subject loop
end
