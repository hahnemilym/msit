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
setenv SUBJECT_LIST $PARAMS_DIR/subjects.txt

# ROI masks Directory
setenv ROI_DIR $SUBJECTS_DIR/masks/AFNI_ROIs

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# II. Define parameters.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
set TR = 1.75
#set polort = A
# A = set polynomial order (detrending) automatically

set num_stimts = 1
# e.g. num_stimts = 2; includes C and I conditions separately

set study = msit
set task = (${study}_bsm)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# III. INDIVIDUAL ANALYSES
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

set subjects = ($SUBJECT_LIST)
foreach SUBJECT ( `cat $subjects` )

#set subjects = (pp004 pp005 pp008 pp010 pp016 hc017 hc011 hc021)
#set subjects = (hc001)
#foreach SUBJECT ($subjects)

echo "*******************************************************************************"
echo " AFNI | Beta Series Method Analysis | " ${SUBJECT}
echo "*******************************************************************************"

setenv DATA_DIR ${SUBJECTS_DIR}/${SUBJECT}/${task}
cd $DATA_DIR;

#rm $DATA_DIR/results/${SUBJECT}_durations.par;
rm $DATA_DIR/results/${SUBJECT}_durations_dmBLOCK.par;

#cp $MSIT_DIR/durations/${SUBJECT}_durations.par $DATA_DIR/results/;
cp $MSIT_DIR/durations/${SUBJECT}_durations_dmBLOCK.par $DATA_DIR/results/;

#set stim_Combined = $DATA_DIR/results/${SUBJECT}_durations.par;
set stim_Combined = $DATA_DIR/results/${SUBJECT}_durations_dmBLOCK.par;

echo "*******************************************************************************"
echo " AFNI | Copy 1D Censor Data | " ${SUBJECT}
echo "*******************************************************************************"

rm ${DATA_DIR}/bsm/${study}.${SUBJECT}.${task}.censor.T.1D;

1d_tool.py \
-infile ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.censor.1D \
-transpose \
-write ${DATA_DIR}/bsm/${study}.${SUBJECT}.${task}.censor.T.1D

echo "*******************************************************************************"
echo " AFNI | 3dresample ROI mask to TLRC space | " ${SUBJECT}
echo "*******************************************************************************"

foreach ROI (dACC L_dlPFC R_dlPFC L_IFG R_IFG)

cd $DATA_DIR;

rm ${DATA_DIR}/bsm/${ROI}+tlrc*;
rm ${DATA_DIR}/bsm/*${ROI}_mask_resamp*;

if ($ROI == 'R_IFG' || $ROI == 'L_IFG' || $ROI == 'dACC') then

3dcopy ${ROI_DIR}/${ROI}+tlrc $DATA_DIR/bsm/${ROI}

3dresample \
-master ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc \
-prefix ${DATA_DIR}/bsm/${ROI}_mask_resamp \
-input ${DATA_DIR}/bsm/${ROI}+tlrc

else if ($ROI == 'L_dlPFC' || $ROI == 'R_dlPFC') then

3dcopy ${ROI_DIR}/${ROI}.nii $DATA_DIR/bsm/${ROI}

3dresample \
-master ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc \
-prefix ${DATA_DIR}/bsm/${ROI}_mask_resamp \
-input ${DATA_DIR}/bsm/${ROI}+tlrc

endif

echo "*******************************************************************************"
echo " AFNI | 3dmerge, 3dcalc | Filter to retain POS values | " ${SUBJECT} "|" ${ROI}
echo "*******************************************************************************"

cd ${DATA_DIR}/bsm;

rm ${DATA_DIR}/bsm/${ROI}_mask_resamp_3dmerge*;
rm ${DATA_DIR}/bsm/${ROI}.data_masked*;
rm ${DATA_DIR}/bsm/${ROI}.data_mask_POS*;
rm ${DATA_DIR}/bsm/${ROI}.data_masked_POS*;

3dmerge \
-doall \
-1noneg \
-1fm_noclip \
-1fmask ${DATA_DIR}/bsm/${ROI}_mask_resamp+tlrc \
-prefix ${DATA_DIR}/bsm/${ROI}_mask_resamp_3dmerge \
${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc

3dcalc \
-a ${DATA_DIR}/bsm/${ROI}_mask_resamp_3dmerge+tlrc \
-b ${DATA_DIR}/bsm/${ROI}_mask_resamp+tlrc \
-prefix ${DATA_DIR}/bsm/${ROI}.data_masked_3dcalc \
-expr 'a*step(b)'

echo "*******************************************************************************"
echo " AFNI | 3dDespike | Despike " ${SUBJECT} "|" ${ROI}
echo "*******************************************************************************"

rm ${DATA_DIR}/bsm/${ROI}.data_masked+tlrc*;
rm ${DATA_DIR}/bsm/*despike*

3dDespike \
-prefix ${DATA_DIR}/bsm/${ROI}.data_despike \
${DATA_DIR}/bsm/${ROI}.data_masked_3dcalc+tlrc

echo "*******************************************************************************"
echo " AFNI | 3dDeconvolve | Configure design matrix for BSM | " ${SUBJECT} "|" ${ROI}
echo "*******************************************************************************"

cd $DATA_DIR/bsm;

3dDeconvolve \
-force_TR $TR \
-input ${DATA_DIR}/bsm/${ROI}.data_despike+tlrc \
-num_stimts $num_stimts \
-stim_times_IM 1 $stim_Combined 'dmBLOCK' \
-stim_label 1 BSM_IM_IC_Combined \
-censor ${DATA_DIR}/bsm/${study}.${SUBJECT}.${task}.censor.T.1D \
-nfirst 2 \
-nlast 227 \
-allzero_OK \
-x1D ${DATA_DIR}/bsm/${ROI}.${SUBJECT}.R.xmat.1D \
-nobucket \
-x1D_stop

echo "*******************************************************************************"
echo " AFNI | 3dLSS | Run Beta Series Method | " ${SUBJECT} "|" ${ROI}
echo "*******************************************************************************"

rm ${DATA_DIR}/bsm/3dLSS.${ROI}.${SUBJECT}+tlrc*;
rm ${DATA_DIR}/bsm/${ROI}.${SUBJECT}.R.LSS.1D;
rm ${ROI}.${SUBJECT}.R.mult.1D;

3dLSS \
-input ${DATA_DIR}/bsm/${ROI}.data_despike+tlrc \
-matrix ${DATA_DIR}/bsm/${ROI}.${SUBJECT}.R.xmat.1D \
-save1D ${DATA_DIR}/bsm/${ROI}.${SUBJECT}.R.LSS.1D \
-prefix ${DATA_DIR}/bsm/3dLSS.${ROI}.${SUBJECT}

cp ${DATA_DIR}/bsm/3dLSS.${ROI}.${SUBJECT}* ${DATA_DIR}/results/ 


1dmatcalc "&read(${ROI}.${SUBJECT}.R.xmat.1D) &transp &read(${ROI}.${SUBJECT}.R.LSS.1D) &mult &write(${ROI}.${SUBJECT}.R.mult.1D)"
#1dplot ${ROI}.${SUBJECT}.R.mult.1D &
#1dgrayplot ${ROI}.${SUBJECT}.R.mult.1D &

echo "*******************************************************************************"
echo " AFNI | Beta Series Method COMPLETE | " ${SUBJECT} "|" ${ROI}
echo "*******************************************************************************"

echo "*******************************************************************************"
echo " AFNI | 3dcalc | Discard TRs - timepoints 0,1,192 | " ${SUBJECT} "|" ${ROI}
echo "*******************************************************************************"

cd ${DATA_DIR}/bsm;

rm ${DATA_DIR}/bsm/${ROI}.${SUBJECT}.LSS.data_masked*

3dcalc \
-a ${DATA_DIR}/bsm/3dLSS.${ROI}.${SUBJECT}+tlrc'[2..190]' \
-expr 'a' \
-prefix ${ROI}.${SUBJECT}.LSS.data_masked

#3dcalc \
#-a ${DATA_DIR}/bsm/3dLSS.${ROI}.${SUBJECT}+tlrc'[2..190]' \
#-expr 'posval(a)' 
#-prefix ${ROI}.${SUBJECT}.LSS.data_masked

echo "*******************************************************************************"
echo " AFNI | 3dTstat | Sum LSS sub bricks for 3dclust | " ${SUBJECT} "|" ${ROI}
echo "*******************************************************************************"

rm ${DATA_DIR}/bsm/LSS_${ROI}.ClusterEffEst+tlrc*;
rm ${DATA_DIR}/bsm/LSS_${ROI}.ClusterMap+tlrc*;

rm ${DATA_DIR}/bsm/${ROI}.3de.OUT.1D;
rm ${DATA_DIR}/bsm/ext1.txt;
rm ${DATA_DIR}/bsm/${ROI}.3dExtrema.txt;
rm ${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}_3dsum+tlrc*;

3dTstat \
-sum \
-prefix LSS.${ROI}.${SUBJECT}_3dsum \
${ROI}.${SUBJECT}.LSS.data_masked+tlrc

cp ${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}_3dsum* ${DATA_DIR}/results/

echo "*******************************************************************************"
echo " AFNI | 3dExtrema | Extract coordinates of max voxels given 3dClustSim "
echo " 		 | cluster-forming threshold | " ${SUBJECT} "|" ${ROI}
echo "*******************************************************************************"

rm ${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}_3dmean+tlrc*;

## NOTE: Anything modified w/ 3dExtrema affects the lines starting with 'cat' 
## Modify accordingly or sphere generation step will NOT work

3dExtrema \
-volume \
-maxima \
-nbest 1 \
-mask_thr p=.001 \
-prefix LSS.${ROI}.${SUBJECT}_3dmean \
LSS.${ROI}.${SUBJECT}_3dsum+tlrc \
> ${ROI}.3de.OUT.1D 

cat ${DATA_DIR}/bsm/${ROI}.3de.OUT.1D | sed '9q;d' | tail -c 48 > ${DATA_DIR}/bsm/ext1.txt;
cat ${DATA_DIR}/bsm/ext1.txt | sed '1q;d' | head -c 35 > ${DATA_DIR}/bsm/${ROI}.3dExtrema.txt;

#rm ${DATA_DIR}/results/LSS.${ROI}.${SUBJECT}_3dmean*;
cp ${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}_3dmean* ${DATA_DIR}/results/;

echo "*******************************************************************************"
echo " AFNI | 3dUndump | Generate ROI sphere mask | " ${SUBJECT} "|" ${ROI}
echo "*******************************************************************************"

rm ${DATA_DIR}/bsm/${ROI}_sphere+tlrc*;

3dUndump \
-prefix ${DATA_DIR}/bsm/${ROI}_sphere \
-master ${DATA_DIR}/bsm/${ROI}.${SUBJECT}.LSS.data_masked+tlrc \
-srad 5 \
-xyz ${DATA_DIR}/bsm/${ROI}.3dExtrema.txt \

cp ${ROI}_sphere* $DATA_DIR/results/;

echo "*******************************************************************************"
echo " AFNI | 3dcalc | Mask data w/ ROI sphere | " ${SUBJECT} "|" ${ROI}
echo "*******************************************************************************"

rm ${DATA_DIR}/bsm/LSS_${ROI}.${SUBJECT}_sphere_data+tlrc*;
   
3dcalc \
-a ${DATA_DIR}/bsm/${ROI}.${SUBJECT}.LSS.data_masked+tlrc \
-b ${DATA_DIR}/bsm/${ROI}_sphere+tlrc \
-prefix ${DATA_DIR}/bsm/LSS_${ROI}.${SUBJECT}_sphere_data \
-expr 'a*step(b)'

cp ${DATA_DIR}/bsm/LSS_${ROI}.${SUBJECT}_sphere_data* ${DATA_DIR}/results;

echo "*******************************************************************************"
echo " AFNI | 3dbucket, 3dmaskave | Extract BSM Estimates | " ${SUBJECT} "|" ${ROI}
echo "*******************************************************************************"

cd $DATA_DIR/bsm;

rm ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg*;

3dbucket \
-prefix ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg \
${DATA_DIR}/bsm/LSS_${ROI}.${SUBJECT}_sphere_data+tlrc

3dmaskave \
-quiet \
-mask ${DATA_DIR}/bsm/${ROI}_sphere+tlrc \
${DATA_DIR}/bsm/LSS_${ROI}.${SUBJECT}_sphere_data+tlrc \
> ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg_file.1D

cp ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg_file.1D $MSIT_DIR/beta_extract_output/;

#1dplot ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg_file.1D

echo "*******************************************************************************"
echo " AFNI | Beta Extraction COMPLETE | " ${SUBJECT}
echo "*******************************************************************************"

cd ${ANALYSIS_DIR}

#End ROI loop
end

## End subject loop
end

