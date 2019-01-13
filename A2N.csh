#! /bin/csh

setenv dir `pwd`
set



find ./anat -name "*BRIK*" > BRIK.txt
find ./anat -name "*HEAD*" > HEAD.txt

foreach files_to_remove (BRIK HEAD)
    set files = ($dir/${files_to_remove}.txt)
    foreach img ( `cat $files` )
        #3dAFNItoNIFTI -prefix $img.nii $img
        cd $dir/anat;
        mv "$files_to_remove" "" * ;
    end
end

find ./func -name "*BRIK*" > BRIK.txt
find ./func -name "*HEAD*" > HEAD.txt

foreach files_to_remove (BRIK HEAD)
    set files = ($dir/${files_to_remove}.txt)
    foreach img ( `cat $files` )
        #3dAFNItoNIFTI -prefix $img.nii $img
        cd $dir/func;
        mv "$files_to_remove" "" * ;
    end
end
