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

#set subjects = ($SUBJECT_LIST)
#foreach subj ( `cat $subjects` )

set subjects = (hc001)
foreach subj ($subjects)

echo "****************************************************************"
echo " AFNI | Anatomical preprocessing "
echo "****************************************************************"

if ( ${do_anat} == 'yes' ) then

setenv DATA_DIR $SUBJECTS_DIR/${subj}/${task}

cd ${DATA_DIR}/anat

echo "****************************************************************"
echo " AFNI | 3dcopy - convert NIFTI to AFNI "
echo "****************************************************************"

3dcopy ${study}.${subj}.anat.nii ${study}.${subj}.anat

echo "****************************************************************"
echo " AFNI | @auto_tlrc "
echo "****************************************************************"

@auto_tlrc \
-no_ss \
-suffix _MNI \
-rmode quintic \
-base TT_icbm452+tlrc \
-input ${study}.${subj}.anat+orig

echo "****************************************************************"
echo " AFNI | Run 3dAutomask "
echo "****************************************************************"

3dAutomask \
-prefix ${study}.${subj}.anat.mask_MNI+tlrc \
${study}.${subj}.anat_MNI+tlrc

echo "****************************************************************"
echo " AFNI | Configure FSL segmentation "
echo "****************************************************************"

3dresample \
-orient ASR \
-inset ${study}.${subj}.anat+orig.HEAD \
-prefix ${study}.${subj}.anat.FSL.nii

echo "****************************************************************"
echo " FSL | Segmentation: GM WM CSF "
echo "****************************************************************"

source /usr/local/freesurfer/nmr-stable60-env

fast -t 1 -n 3 -H .5 -B -b --nopve -o ${study}.${subj}.anat ${study}.${subj}.anat.FSL.nii 

echo "****************************************************************"
echo " AFNI | Revert segmented output to AFNI format "
echo "****************************************************************"

gunzip ${study}.${subj}.anat_seg.nii.gz

3dcopy \
-verb ${study}.${subj}.anat_seg.nii \
${study}.${subj}.anat.seg.float

3drefit \
-'anat' ${study}.${subj}.anat.seg.float+orig

echo "****************************************************************"
echo " AFNI | Convert the data type from float to short "
echo "****************************************************************"

3dcalc \
-datum short \
-a ${study}.${subj}.anat.seg.float+orig \
-expr a \
-prefix ${study}.${subj}.anat.seg.fsl

echo "****************************************************************"
echo " AFNI | Convert the data to MNI space "
echo "****************************************************************"

@auto_tlrc \
-apar ${study}.${subj}.anat_MNI+tlrc \
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

