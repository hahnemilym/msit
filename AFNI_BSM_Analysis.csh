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

set subjects = ($SUBJECT_LIST)
foreach SUBJECT ( `cat $subjects` )

#set subjects = (hc006 hc007)
#foreach SUBJECT ($subjects)

setenv DATA_DIR ${SUBJECTS_DIR}/${SUBJECT}/${task}
cd $DATA_DIR;

##rm $DATA_DIR/results/${SUBJECT}_durations.par;
#rm $DATA_DIR/results/${SUBJECT}_durations_dmBLOCK.par;

##cp $MSIT_DIR/durations/${SUBJECT}_durations.par $DATA_DIR/results/;
#cp $MSIT_DIR/durations/${SUBJECT}_durations_dmBLOCK.par $DATA_DIR/results/;

##set stim_Combined = $DATA_DIR/results/${SUBJECT}_durations.par;
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

## Use 3dBrickStat TTnew+tlrc -count -percentile 90 1 90 to return # voxels above % threshold

foreach ROI (IFG dACC R_dlPFC L_dlPFC)

cd $DATA_DIR;

rm ${DATA_DIR}/bsm/${ROI}+tlrc*;
rm ${DATA_DIR}/bsm/*${ROI}_mask_resamp*;

if ($ROI == 'IFG') then

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

echo "*******************************************************************************"
echo " AFNI | 3dttest++ and 3dClustSim | " ${SUBJECT}
echo "*******************************************************************************"

## NOTE: t-statistics to z-scores - automatically implemented with 3dclustsim

## PRO TIP (Option 1, used here): Simply use -Clustsim with 3dttest++ then append the 3dttest++ -prefix file 
## to the *.CSimA.cmd file to stage the OSGM results (to .HEAD file) for 3dClusterize.

## Option 2: If not using 3dttest++ for -Clustsim, use afni_proc.py 
## --OR --
## Option 3: See https://afni.nimh.nih.gov/pub/dist/doc/program_help/3dClustSim.html 
## for information on cluster simulation, formation, thresholding, and adding that 
## data to the dataset's header. This allows 3dClusterize to automatically read 
## the output of 3dClustSim and 3dRefit instead of using AFNI's 'Clusterize' GUI.

cd $DATA_DIR/bsm;

rm *TT*;
rm ${study}.${SUBJECT}.${task}.${ROI}.OSGM.resid*;
rm OSGM_${ROI}*;
rm OSGM_${ROI}.CSimA.cmd;

cd $DATA_DIR/bsm;

3dttest++ \
-setA ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc \
-resid ${study}.${SUBJECT}.${task}.${ROI}.OSGM.resid \
-mask ${ROI}_mask_resamp+tlrc \
-prefix OSGM_${ROI}
##-CLUSTSIM

#echo "*******************************************************************************"
#echo " AFNI | 3dClustSim | " ${SUBJECT}
#echo "*******************************************************************************"

## --------->> OPTIONAL (if thresholds have already been determined)

#rm 3dFWHMx.1D;

#3dFWHMx \
#-mask ${ROI}_mask_resamp+tlrc \
#-input ${study}.${SUBJECT}.${task}.${ROI}.OSGM.resid+tlrc

#cd $DATA_DIR/bsm;

#rm *CStemp*;

#3dClustSim \
#-mask OSGM_${ROI}+tlrc \
#-acf 0.993995 4.22737 2.08668 \
#-niml \
##-prefix CStemp \
#-athr 0.05 \
#-pthr 0.001

#echo "*******************************************************************************"
#echo " AFNI | Scripted 3dRefit from 3dttest++ -CLUSTSIM step | " ${SUBJECT}
#echo "*******************************************************************************"

## --------->> OPTIONAL (if thresholds have already been determined)

##cd $DATA_DIR/bsm;

##if ($ROI == 'IFG') then
##sed -i.bck '$s/$/OSGM_IFG+tlrc/' OSGM_${ROI}.CSimA.cmd;

##else if ($ROI == 'dACC') then
##sed -i.bck '$s/$/OSGM_dACC+tlrc/' OSGM_${ROI}.CSimA.cmd;

##else if ($ROI == 'L_dlPFC') then
##sed -i.bck '$s/$/OSGM_L_dlPFC+tlrc/' OSGM_${ROI}.CSimA.cmd;

##else if ($ROI == 'R_dlPFC') then
##sed -i.bck '$s/$/OSGM_R_dlPFC+tlrc/' OSGM_${ROI}.CSimA.cmd;

##endif

##source OSGM_${ROI}.CSimA.cmd;

echo "*******************************************************************************"
echo " AFNI | 3dclust | Attenuate size of ROI mask " ${SUBJECT}
echo "*******************************************************************************"

cd $DATA_DIR/bsm;

rm OSGM_${ROI}.ClusterEffEst*
rm OSGM_${ROI}.ClusterMap*

3dClusterize \
-inset ${DATA_DIR}/bsm/OSGM_${ROI}+tlrc. \
#-mask_from_hdr \
-mask ${ROI}_mask_resamp+tlrc. \
-1sided RIGHT_TAIL p=0.00000005 \
-clust_nvox 30 \
-NN 3 \
-idat 0 \
-ithr 0 \
-pref_map OSGM_${ROI}.ClusterMap \
-pref_dat OSGM_${ROI}.ClusterEffEst

#3dcalc \
#-a OSGM_IFG.ClusterMap+tlrc \
#-expr 'max(a)' \
#-prefix OSGM_IFG.ClusterMap_MAX

echo "*******************************************************************************"
echo " AFNI | 3dDeconvolve task | " ${SUBJECT}
echo "*******************************************************************************"

cd $DATA_DIR/bsm;

3dDeconvolve \
-force_TR $TR \
-input ${DATA_DIR}/func/${study}.${SUBJECT}.${task}.smooth.resid+tlrc \
-nfirst 1 \
-censor $DATA_DIR/bsm/${study}.${SUBJECT}.${task}.censor.T.1D \
#-polort 'A' \
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

echo "*******************************************************************************"
echo " AFNI | BSM Analysis - Extract $ROI Betas for $SUBJECT "
echo "*******************************************************************************"

echo "*******************************************************************************"
echo " AFNI | 3dcopy & 3dresample | Fit masks to func data       | " 
echo " AFNI | 3dbucket            | Stage func file to be masked | "
echo " AFNI | 3dmaskave           | Average voxels in mask       | "
echo "*******************************************************************************"

## -perc flag of 3dmaskave may or may not be desireable

cd $DATA_DIR/bsm;

rm ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg_file.1D*;
rm ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg*;

3dbucket \
-prefix ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg \
${DATA_DIR}/bsm/LSS.${ROI}.${SUBJECT}_despike+tlrc

3dmaskave \
-quiet \
-mask $DATA_DIR/bsm/OSGM_${ROI}.ClusterMap+tlrc. \
${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg+tlrc \
> ${DATA_DIR}/bsm/${SUBJECT}.${ROI}_LSS_avg_file.1D

1dplot ${SUBJECT}.${ROI}_LSS_avg_file.1D 

echo "*******************************************************************************"
echo " AFNI | Beta Series Method - Beta Extraction COMPLETE | " ${SUBJECT}
echo "*******************************************************************************"

cd ${ANALYSIS_DIR}

#End ROI loop
end

## End subject loop
end

