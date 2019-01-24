#! /bin/csh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Configure environment
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# Local Directory
setenv DIR /autofs/space/lilli_004/users/DARPA-MSIT

# Recon Dir
setenv RECON_DIR /autofs/space/lilli_001/users/DARPA-Recons

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

#cd $RECON_DIR

echo "****************************************************************"
echo " SUMA | Convert from FreeSurfer Space to AFNI "
echo "****************************************************************"

@SUMA_Make_Spec_FS -NIFTI -fspath ${RECON_DIR}/${subj} -sid $subj

echo "****************************************************************"
echo " SUMA | Copy FS --> AFNI Converted Image to BSM Dir"
echo "****************************************************************"

setenv DATA_DIR $SUBJECTS_DIR/${subj}/${task}/anat

cd $DATA_DIR

cp ${RECON_DIR}/${subj}/SUMA/brain.finalsurfs.nii $DATA_DIR

mv $DATA_DIR/brain.finalsurfs.nii $DATA_DIR/msit.${subj}.anat.nii

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

