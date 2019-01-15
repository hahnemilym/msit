addpath /home/ajames/matlab/NIFTI_20100413/
filein=['/home/aprivratsky/DOP/scripts/var_names_for_expand'];
fid=fopen(filein,'r');
filename=textscan(fid,'%s');
fclose(fid);
rootpath=char(filename{1}(1));
study=char(filename{1}(2));
subj=char(filename{1}(3));
task=char(filename{1}(4));
scan=char(filename{1}(5));
day=char(filename{1}(6));

cd([rootpath '/' subj '/' day '/' task '/' scan])
eval('!rm temp+*')
expand_nii_scan_interrupted([study '.' subj '.' task '.' scan '.nii'])
eval(['!rm ' study '.' subj '.' task '.' scan '*nii'])