#!/usr/bin/env bash

echo "****************************************************************"
echo " AFNI | Generate Motion Regressors "
echo "****************************************************************"

matlab -nodesktop -nosplash -r "make_motion_regressors;exit"

echo "****************************************************************"
echo "Motion Regressors Generated"
echo "****************************************************************"

