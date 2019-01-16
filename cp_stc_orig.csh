setenv MSIT_DIR /autofs/space/lilli_004/users/DARPA-MSIT/msit;

mkdir ${MSIT_DIR}/subjs;

setenv subjects ${MSIT_DIR}/msit/subjects.txt;
set subject = ($subjects);
foreach subj ( `cat $subject` )

#set subject = (test_002)
#foreach subj ( $subject )

# make msit_bsm dir
mkdir ${MSIT_DIR}/subjs/${subj};
mkdir ${MSIT_DIR}/subjs/${subj}/msit_bsm;

echo 'msit_bsm dir struct created: ' $subj;

# Make depth 3 dir
mkdir ${MSIT_DIR}/subjs/${subj}/msit_bsm/func;
mkdir ${MSIT_DIR}/subjs/${subj}/msit_bsm/anat;
mkdir ${MSIT_DIR}/subjs/${subj}/msit_bsm/results;

echo 'depth -3 directories created: ' $subj;

# cp STC and orig .nii files
cp ${MSIT_DIR}/subjs_orig/${subj}/msit_bsm/func/amsit.${subj}.func.* ${MSIT_DIR}/subjs/${subj}/msit_bsm/func/;
cp ${MSIT_DIR}/subjs_orig/${subj}/msit_bsm/func/msit.${subj}.func.* ${MSIT_DIR}/subjs/${subj}/msit_bsm/func/;

echo 'func files copied: ' $subj;

cp ${MSIT_DIR}/subjs_orig/${subj}/msit_bsm/anat/* ${MSIT_DIR}/subjs/${subj}/msit_bsm/anat/;

echo 'anat files copied: ' $subj

end
