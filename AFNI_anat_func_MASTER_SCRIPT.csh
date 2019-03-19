#foreach script (AFNI_anat_preproc_step1.csh AFNI_func_preproc_step1.csh AFNI_func_preproc_step2.5.csh AFNI_func_preproc_step2.csh AFNI_func_preproc_step3.csh AFNI_func_preproc_step4.csh AFNI_BSM_Analysis.csh transfer_results.csh transfer_bsm_results.csh)
foreach script (AFNI_BSM_Analysis.csh transfer_results.csh transfer_bsm_results.csh)

source $script;

end
