#! /bin/csh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Configure environment
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# Local Directory
setenv DIR /autofs/space/lilli_004/users/DARPA-MSIT

# Project Directory
setenv MSIT_DIR $DIR/msit

# Subjects Directory
setenv SUBJECTS_DIR $MSIT_DIR/subjs

# Parameters Directory
setenv PARAMS_DIR $MSIT_DIR/bsm_params/

# Analyses Directory
setenv ANALYSIS_DIR $MSIT_DIR/msit

# Subjects List
setenv SUBJECT_LIST $PARAMS_DIR/subjects_list_01-10-19.txt

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Define parameters
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

set study = msit
set task = (${study}_bsm)

set do_anat = 'yes'

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Initialize subject(s) environment
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

set subjects = ($SUBJECT_LIST)
foreach SUBJECT ( `cat $subjects` )

#set subjects = (hc001)
#foreach subj ($subjects)

echo "****************************************************************"
echo " AFNI | Anatomical preprocessing "
echo "****************************************************************"

if ( ${do_anat} == 'yes' ) then

setenv DATA_DIR $SUBJECTS_DIR/${subj}/${task}

cd ${DATA_DIR}/anat

echo "****************************************************************"
echo " AFNI | Skull stripping - Round 1 "
echo "****************************************************************"

rm ${study}.${subj}.anat.sksp+orig*

3dSkullStrip \
-input ${study}.${subj}.anat.nii \
-prefix ${study}.${subj}.anat.sksp \
-orig_vol \
-niter 300

echo "****************************************************************"
echo " AFNI | Skull stripping - Round 2 (to ensure accuracy) "
echo "****************************************************************"

rm ${study}.${subj}.anat.sksp1+orig*

3dSkullStrip \
-input ${study}.${subj}.anat.sksp+orig \
-prefix ${study}.${subj}.anat.sksp1 \
-orig_vol \
-niter 300

rm ${study}.${subj}.anat.sksp+orig*

echo "****************************************************************"
echo " AFNI | 3dcopy "
echo "****************************************************************"

3dcopy \
${study}.${subj}.anat.sksp1+orig \
${study}.${subj}.anat.sksp

rm ${study}.${subj}.anat.sksp1+orig*

echo "****************************************************************"
echo " AFNI | @auto_tlrc "
echo "****************************************************************"

rm ${study}.${subj}.anat.sksp_MNI+tlrc*
rm ${study}.${subj}.anat.mask*

@auto_tlrc \
-no_ss \
-suffix _MNI \
-rmode quintic \
-base TT_icbm452+tlrc \
-input ${study}.${subj}.anat.sksp+orig

echo "****************************************************************"
echo " AFNI | Run 3dAutomask "
echo "****************************************************************"

3dAutomask \
-prefix ${study}.${subj}.anat.mask \
${study}.${subj}.anat.sksp_MNI+tlrc

echo "****************************************************************"
echo " AFNI | Configure FSL segmentation "
echo "****************************************************************"

rm ${study}.${subj}.anat.sksp.nii*
rm ${study}.${subj}.anat_seg.nii.gz

3dresample \
-orient ASR \
-inset ${study}.${subj}.anat.sksp+orig.HEAD \
-prefix ${study}.${subj}.anat.sksp.nii

echo "****************************************************************"
echo " FSL | Segmentation: GM WM CSF "
echo "****************************************************************"

source /usr/local/freesurfer/nmr-stable60-env

fast -t 1 -n 3 -H .5 -B -b --nopve -o ${study}.${subj}.anat ${study}.${subj}.anat.sksp.nii

echo "****************************************************************"
echo " AFNI | Revert segmented output to AFNI format "
echo "****************************************************************"

# NOTE: order of the following commands is important

rm ${study}.${subj}.anat.seg.float+orig*

gunzip ${study}.${subj}.anat_seg.nii.gz

3dcopy \
-verb ${study}.${subj}.anat_seg.nii \
${study}.${subj}.anat.seg.float

3drefit \
-'anat' ${study}.${subj}.anat.seg.float+orig

echo "****************************************************************"
echo " AFNI | Convert the data type from float to short "
echo "****************************************************************"

# Note: FSL stamp is applied

rm ${study}.${subj}.anat.seg.fsl+orig*

3dcalc \
-datum short \
-a ${study}.${subj}.anat.seg.float+orig \
-expr a \
-prefix ${study}.${subj}.anat.seg.fsl

rm -v ${study}.${subj}.anat.seg.float+orig*
rm -v ${study}.${subj}.anat.sksp.nii
rm -v ${study}.${subj}.anat_seg.nii

echo "****************************************************************"
echo " AFNI | Warp segmented anatomy into MNI space "
echo "****************************************************************"

rm ${study}.${subj}.anat.seg.fsl.MNI+tlrc*

@auto_tlrc \
-apar ${study}.${subj}.anat.sksp_MNI+tlrc \
-no_ss \
-suffix .MNI \
-rmode quintic \
-input ${study}.${subj}.anat.seg.fsl+orig

echo "****************************************************************"
echo "DONE"
echo "****************************************************************"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# exit loop: anat preproc
endif

# exit loop: subjs
end

# return to project scripts
cd $ANALYSIS_DIR
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

