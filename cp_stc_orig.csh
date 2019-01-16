setenv MSIT_DIR /autofs/space/lilli_004/users/DARPA-MSIT/msit

setenv subjects ${MSIT_DIR}/msit/subjects.txt

set subject = ($subjects)

foreach subj ( `cat $subject` )

# make msit_bsm dir
echo mkdir ${MSIT_DIR}/subjs;
echo mkdir ${MSIT_DIR}/subjs/${subj};
echo mkdir ${MSIT_DIR}/subjs/${subj}/msit_bsm;

# Make depth 3 dir
echo mkdir ${MSIT_DIR}/subjs/${subj}/msit_bsm/func;
echo mkdir ${MSIT_DIR}/subjs/${subj}/msit_bsm/anat;
echo mkdir ${MSIT_DIR}/subjs/${subj}/msit_bsm/results;

# cp STC and orig .nii files
echo cp ${MSIT_DIR}/subjs_orig/${subj}/msit_bsm/func/amsit.${subj}.func.* ${MSIT_DIR}/subjs/${subj}/msit_bsm/func/;
echo cp ${MSIT_DIR}/subjs_orig/${subj}/msit_bsm/func/msit.${subj}.func.* ${MSIT_DIR}/subjs/${subj}/msit_bsm/func/;

end
