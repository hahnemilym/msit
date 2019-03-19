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
setenv SUBJECT_LIST $PARAMS_DIR/subjects.txt

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Define parameters
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# number of regressors [WM, CSF, motion]
set num_stimts = 28

# A = automatically choose polynomial detrending value based on
# time duration D of longest run: pnum = 1 + int(D/150)
set polort = A

set FWHM = 6
set TR = 1.75
set slices = 63

set study = msit
set task = (${study}_bsm)

set do_epi = 'yes'

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Initialize subject(s) environment
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#set subjects = ($SUBJECT_LIST)
#foreach subj ( `cat $subjects` )

set subjects = (hc009 hc018 hc019 hc021 hc028 hc031 hc036 pp004 pp006 pp007 pp012 pp015)
foreach subj ($subjects)

echo "****************************************************************"
echo " AFNI | Functional preprocessing | PART 2"
echo "****************************************************************"

if ( ${do_epi} == 'yes' ) then

setenv DATA_DIR $SUBJECTS_DIR/${subj}/${task}

cd ${DATA_DIR}/func

echo "****************************************************************"
echo " AFNI | 3dResample | Anatomy 1x1x1 --> 2x2x2 (EPI dimensions) "
echo "****************************************************************"

3dresample \
-prefix ${DATA_DIR}/anat/${study}.${subj}.anat.2x2x2 \
-input ${DATA_DIR}/anat/${study}.${subj}.anat+tlrc \
-dxyz 2.0 2.0 2.0

gunzip ${DATA_DIR}/anat/*.gz

echo "****************************************************************"
echo " AFNI | Warp Structural (MEMPRAGE) to Functional (EPI) Space "
echo "****************************************************************"

align_epi_anat.py \
##-anat  ${DATA_DIR}/anat/${study}.${subj}.anat+orig \
##-epi ${DATA_DIR}/func/${study}.${subj}.${task}.motion+tlrc \
##-tlrc_apar ${DATA_DIR}/anat/${study}.${subj}.anat.2x2x2+tlrc.BRIK \
-anat ${DATA_DIR}/anat/${study}.${subj}.anat.2x2x2+tlrc \
-epi ${DATA_DIR}/func/${study}.${subj}.${task}.motion+tlrc \
-epi_base 6 \
-epi2anat \
-anat_has_skull no \
-volreg off \
-tshift off \
-deoblique off \
-suffix .py \
-ginormous_move

rm *malldump*;
mv ${study}.${subj}.anat.2x2x2.py_e2a_only_mat.aff12.1D -t ${DATA_DIR}/anat/;

echo "****************************************************************"
echo " AFNI | Run 3dAutomask on Talairach Transformed Data "
echo "****************************************************************"

3dAutomask \
-prefix ${DATA_DIR}/anat/${study}.${subj}.anat.mask \
${DATA_DIR}/anat/${study}.${subj}.anat.2x2x2+tlrc

gunzip ${DATA_DIR}/anat/*.gz

echo "****************************************************************"
echo " AFNI | Mask EPI"
echo "****************************************************************"

3dmerge \
-doall \
-1fm_noclip \
-1fmask ${DATA_DIR}/anat/${study}.${subj}.anat.mask+tlrc \
-prefix ${DATA_DIR}/func/${study}.${subj}.${task}.motion.py.merge_strp ${DATA_DIR}/func/${study}.${subj}.${task}.motion.py+tlrc

3dcalc \
-a ${DATA_DIR}/func/${study}.${subj}.${task}.motion.py.merge_strp+tlrc \
-b ${DATA_DIR}/anat/${study}.${subj}.anat.mask+tlrc \
-prefix ${DATA_DIR}/func/${study}.${subj}.${task}.motion.py.strp \
-expr 'a*step(b)'

echo "****************************************************************"
echo " DONE"
echo "****************************************************************"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# exit loop: func preproc
endif

# exit loop: subjs
end

# return to project scripts
cd $ANALYSIS_DIR
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

