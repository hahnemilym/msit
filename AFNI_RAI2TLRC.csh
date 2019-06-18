## NOTE: This script has not been fully debugged

set subjects = (hc001)
#set rois = (dACC L_dlPFC R_dlPFC L_IFG R_IFG)
set rois = (dACC)

foreach SUBJECT ($subjects)
foreach ROI ($rois)

foreach xyz (`cat ${ROI}.csv`)

    printf 'whereami %s;\n' $xyz | tr ',' ' ' >> ${ROI}.txt

end

foreach cmd (`cat ${ROI}.txt`)
    cmd > whereami_${ROI}.txt

    cat whereami_${ROI}.txt | sed -n '7,7 p' | tr '{TLRC}' ' ' | tr ' mm [L],   ' ',' | tr ' mm [P],   ' ' ' | tr ' mm [S],   ' ' ' | tr '\t' 'f' > xyz_coords.txt;

end
end
