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
set polort = A
# A = set polynomial order (detrending) automatically

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

#rm $DATA_DIR/results/${SUBJECT}_durations.par;
rm $DATA_DIR/results/${SUBJECT}_durations_dmBLOCK.par;

#cp $MSIT_DIR/durations/${SUBJECT}_durations.par $DATA_DIR/results/;
cp $MSIT_DIR/durations/${SUBJECT}_durations_dmBLOCK.par $DATA_DIR/results/;

#set stim_Combined = $DATA_DIR/results/${SUBJECT}_durations.par;
set stim_Combined = $DATA_DIR/results/${SUBJECT}_durations_dmBLOCK.par;

echo "*******************************************************************************"
echo " AFNI | Beta Series Method Analysis | " ${SUBJECT}
echo "*******************************************************************************"

echo "*******************************************************************************"
echo " AFNI | Copy 1D Censor Data | " ${SUBJECT}
echo "*******************************************************************************"

rm ${DATA_DIR}/bsm/${study}.${SUBJECT}.${task}.censor.T.1D;

1d_tool.py \
-infile ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.censor.1D \
-transpose \
-write ${DATA_DIR}/bsm/${study}.${SUBJECT}.${task}.censor.T.1D

echo "*******************************************************************************"
echo " AFNI | Perform OSGM and 3dClustSim to clusterize ROIs | " ${SUBJECT}
echo "*******************************************************************************"

# NOTE: t-statistics to z-scores - automatically implemented with 3dclustsim
# Use 3dBrickStat TTnew+tlrc -count -percentile 90 1 90 to return # voxels above % threshold

foreach ROI (IFG dACC R_dlPFC L_dlPFC)
#foreach ROI (L_dlPFC)

cd $DATA_DIR;

rm ${DATA_DIR}/results/${ROI}+tlrc*;
rm ${DATA_DIR}/results/*${ROI}_mask_resamp*;

if ($ROI == 'IFG') then

3dcopy ${ROI_DIR}/${ROI}+tlrc $DATA_DIR/results/${ROI}

3dresample \
-master ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc \
-prefix ${DATA_DIR}/results/${ROI}_mask_resamp \
-input ${DATA_DIR}/results/${ROI}+tlrc

else if ($ROI == 'dACC' || $ROI == 'L_dlPFC' || $ROI == 'R_dlPFC') then

3dcopy ${ROI_DIR}/${ROI}.nii $DATA_DIR/results/${ROI}

3dresample \
-master ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc \
-prefix ${DATA_DIR}/results/${ROI}_mask_resamp \
-input ${DATA_DIR}/results/${ROI}+tlrc

endif

echo "*******************************************************************************"
echo " AFNI | 3dttest++ using -Clustsim | " ${SUBJECT}
echo "*******************************************************************************"

rm $DATA_DIR/bsm/*TT*;
rm $DATA_DIR/bsm/${study}.${SUBJECT}.${task}.${ROI}.OSGM.resid*;
rm $DATA_DIR/bsm/OSGM_${ROI}*;

cd $DATA_DIR/bsm;

3dttest++ \
-setA ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc \
-resid ${study}.${SUBJECT}.${task}.${ROI}.OSGM.resid \
-mask ${DATA_DIR}/results/${ROI}_mask_resamp+tlrc \
-prefix OSGM_${ROI} \
-Clustsim

echo "*******************************************************************************"
echo " AFNI | 3dcalc | Create Mask from 3dttest++ -Clustsim results | " ${SUBJECT}
echo "*******************************************************************************"

cd $DATA_DIR/bsm;

rm *$ROI.${SUBJECT}.mask*;

if ($ROI == 'IFG') then

3dcalc \
-a 'OSGM_IFG+tlrc[1]' \
-expr 'notzero(a)' \
-prefix $DATA_DIR/bsm/$ROI.${SUBJECT}.mask

else if ($ROI == 'dACC') then

3dcalc \
-a 'OSGM_dACC+tlrc[1]' \
-expr 'notzero(a)' \
-prefix $DATA_DIR/bsm/$ROI.${SUBJECT}.mask

else if ($ROI == 'L_dlPFC') then

3dcalc \
-a 'OSGM_L_dlPFC+tlrc[1]' \
-expr 'notzero(a)' \
-prefix $DATA_DIR/bsm/$ROI.${SUBJECT}.mask

else if ($ROI == 'L_dlPFC') then

3dcalc \
-a 'OSGM_R_dlPFC+tlrc[1]' \
-expr 'notzero(a)' \
-prefix $DATA_DIR/bsm/$ROI.${SUBJECT}.mask

endif

cd $DATA_DIR;

echo "*******************************************************************************"
echo " AFNI | 3dDeconvolve task | " ${SUBJECT}
echo "*******************************************************************************"

#You can also use dmBLOCK with -stim_times_IM, in which case    
#each time in the 'tname' file should have just ONE extra
#parameter -- the duration -- married to it, as in '30:15',     
#meaning a block of duration 15 seconds starting at t=30 s.

3dDeconvolve \
-force_TR $TR \
-input ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc \
-nfirst 1 \
-censor $DATA_DIR/bsm/${study}.${SUBJECT}.${task}.censor.T.1D \
-polort 'A' \
-num_stimts $num_stimts \
#-stim_times_IM 1 $stim_Combined "BLOCK(1.75,1)" \
-stim_times_IM 1 $stim_Combined 'dmBLOCK' \
-stim_label 1 BSM_IM_IC_Combined \
-x1D $DATA_DIR/bsm/LSS.${ROI}.${SUBJECT}.xmat.1D \
-allzero_OK \
-nobucket \
-x1D_stop

echo "*******************************************************************************"
echo " AFNI | 3dLSS | " ${SUBJECT}
echo "*******************************************************************************"

rm $DATA_DIR/bsm/LSS.${ROI}.${SUBJECT}+tlrc*;

3dLSS \
-input ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc \
-matrix ${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}.xmat.1D \
-prefix ${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}

echo "*******************************************************************************"
echo " AFNI | 3dDespike | " ${SUBJECT}
echo "*******************************************************************************"

rm ${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}_despike*;

3dDespike \
-prefix ${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}_despike \
${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}+tlrc

echo "*******************************************************************************"
echo " AFNI | Beta Series Method COMPLETE | " ${SUBJECT}
echo "*******************************************************************************"

cd ${ANALYSIS_DIR}

#End ROI loop
end

## End subject loop
end

