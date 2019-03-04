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

set subjects = (hc009)
foreach SUBJECT ($subjects)

setenv DATA_DIR ${SUBJECTS_DIR}/${SUBJECT}/${task}
cd $DATA_DIR;

rm $DATA_DIR/results/${SUBJECT}_durations.par;
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
echo " AFNI | 3dresample ROI masks to TLRC space | " ${SUBJECT}
echo "*******************************************************************************"

foreach ROI (R_IFG L_IFG dACC R_dlPFC L_dlPFC )

cd $DATA_DIR;

rm ${DATA_DIR}/bsm/${ROI}+tlrc*;
rm ${DATA_DIR}/bsm/*${ROI}_mask_resamp*;

if ($ROI == 'R_IFG' || $ROI == 'L_IFG') then

3dcopy ${ROI_DIR}/${ROI}+tlrc $DATA_DIR/bsm/${ROI}

3dresample \
-master ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc \
-prefix ${DATA_DIR}/bsm/${ROI}_mask_resamp \
-input ${DATA_DIR}/bsm/${ROI}+tlrc

else if ($ROI == 'dACC' || $ROI == 'L_dlPFC' || $ROI == 'R_dlPFC') then

3dcopy ${ROI_DIR}/${ROI}.nii $DATA_DIR/bsm/${ROI}

3dresample \
-master ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc \
-prefix ${DATA_DIR}/bsm/${ROI}_mask_resamp \
-input ${DATA_DIR}/bsm/${ROI}+tlrc

endif

#echo "*******************************************************************************"
#echo " AFNI | 3dDeconvolve task | " ${SUBJECT} "|" ${ROI}
#echo "*******************************************************************************"

#cd $DATA_DIR/bsm;

#3dDeconvolve \
#-force_TR $TR \
#-input ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc \
#-nfirst 1 \
#-censor $DATA_DIR/bsm/${study}.${SUBJECT}.${task}.censor.T.1D \
##-polort 'A' \
#-num_stimts $num_stimts \
##-stim_times_IM 1 $stim_Combined "BLOCK(1.75,1)" \
#-stim_times_IM 1 $stim_Combined 'dmBLOCK' \
#-stim_label 1 BSM_IM_IC_Combined \
#-x1D $DATA_DIR/bsm/LSS.${ROI}.${SUBJECT}.xmat.1D \
#-allzero_OK \
#-nobucket \
#-x1D_stop

#echo "*******************************************************************************"
#echo " AFNI | 3dLSS | " ${SUBJECT} "|" ${ROI}
#echo "*******************************************************************************"

#rm $DATA_DIR/bsm/LSS.${ROI}.${SUBJECT}+tlrc*;

#3dLSS \
#-input ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc \
#-matrix ${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}.xmat.1D \
#-prefix ${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}

#echo "*******************************************************************************"
#echo " AFNI | Beta Series Method COMPLETE | " ${SUBJECT} "|" ${ROI}
#echo "*******************************************************************************"

#echo "*******************************************************************************"
#echo " AFNI | 3dDespike | " ${SUBJECT} "|" ${ROI}
#echo "*******************************************************************************"

#rm ${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}_despike*;

#3dDespike \
#-prefix ${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}_despike \
#${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}+tlrc

echo "*******************************************************************************"
echo " AFNI | 3dTstat | Sum LSS sub bricks for 3dclust | " ${SUBJECT} "|" ${ROI}
echo "*******************************************************************************"

#-tsnr \
#-autocorr 10 \
#-mean \

cd $DATA_DIR/bsm;

rm LSS_${ROI}.ClusterEffEst*;
rm LSS_${ROI}.ClusterMap*;
rm ${ROI}_sphere*;
rm OUT_${ROI}.txt;
rm LSS.${ROI}.${SUBJECT}_3dmean*;
#rm 3dTstat_autocorr_tsnr_data.txt;

3dTstat -sum -mask ${ROI}_mask_resamp+tlrc -prefix LSS.${ROI}.${SUBJECT}_3dmean ${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}_despike+tlrc

cp LSS.${ROI}.${SUBJECT}_3dmean* ${DATA_DIR}/results/;
#cp 3dTstat_autocorr_tsnr_data.txt ${DATA_DIR}/results/;

echo "*******************************************************************************"
echo " AFNI | 3dClusterize | Generate clusters for ROI sphere | " ${SUBJECT} "|" ${ROI}
echo "*******************************************************************************"

3dClusterize -inset ${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}_3dmean+tlrc -mask ${DATA_DIR}/bsm/${ROI}_mask_resamp+tlrc. -1sided RIGHT_TAIL p=0.001 -clust_nvox 30 -NN 3 -ithr 0 -idat 0 -pref_map ${DATA_DIR}/bsm/LSS_${ROI}.ClusterMap -pref_dat ${DATA_DIR}/bsm/LSS_${ROI}.ClusterEffEst > OUT_${ROI}.txt

cp LSS_${ROI}.ClusterEffEst* $DATA_DIR/results/;

cat OUT_${ROI}.txt | sed '20q;d' | tail -c 22 > ${ROI}.txt;

3dUndump \
-prefix ${ROI}_sphere \
-master LSS_${ROI}.ClusterEffEst+tlrc \
-srad 5 \
-xyz ${ROI}.txt

cp ${ROI}_sphere* $DATA_DIR/results/;

echo "*******************************************************************************"
echo " AFNI | 3dmerge, 3dcalc | Mask data w/ ROI sphere | " ${SUBJECT} "|" ${ROI}
echo "*******************************************************************************"

rm LSS_${ROI}.${SUBJECT}_masked*;
rm LSS_${ROI}.${SUBJECT}_3dmerge*;

3dmerge \
-doall \
-1fm_noclip \
-1fmask ${ROI}_sphere+tlrc \
-prefix LSS_${ROI}.${SUBJECT}_3dmerge ${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}_despike+tlrc
   
3dcalc \
-a LSS_${ROI}.${SUBJECT}_3dmerge+tlrc \
-b ${ROI}_sphere+tlrc \
-prefix LSS_${ROI}.${SUBJECT}_masked \
-expr 'a*step(b)'

cp LSS_${ROI}.${SUBJECT}_masked* ${DATA_DIR}/results;

echo "*******************************************************************************"
echo " AFNI | 3dbucket, 3dmaskave | Extract Beta Estimates | " ${SUBJECT} "|" ${ROI}
echo "*******************************************************************************"

cd $DATA_DIR/bsm;

rm ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg_file.1D;
rm ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg*;

3dbucket -prefix ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg LSS_${ROI}.${SUBJECT}_masked+tlrc

3dmaskave -quiet -mask ${ROI}_sphere+tlrc ${SUBJECT}.${ROI}_LSS_avg+tlrc > ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg_file.1D

cp ${SUBJECT}.${ROI}_LSS_avg_file.1D $MSIT_DIR/beta_extract_output/;

#1dplot ${SUBJECT}.${ROI}_LSS_avg_file.1D

echo "*******************************************************************************"
echo " AFNI | Beta Extraction COMPLETE | " ${SUBJECT}
echo "*******************************************************************************"

cd ${ANALYSIS_DIR}

#End ROI loop
end

## End subject loop
end

