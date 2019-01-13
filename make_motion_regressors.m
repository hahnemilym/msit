clear

task='msit_bsm';
study='msit';
dir = '/Users/emilyhahn/projects/msit/subjs/';
subdir = ['/' task '/' 'func' '/'];

subjects_list={'test_002'};

for i = 1 : length(subjects_list)
    
    subj=([subjects_list{i}]);
    
    motion=load([dir subj subdir study '.' subj '.' task '.motion.1D']);
    
    motion_d=motion.*0;

    motion_d(2:end,:)=diff(motion);

    %% Framewise Displacement
    FD=sum(abs(motion_d),2);

    %% Square of Motion Params
    motion_square=motion.*motion;

    %% Motion t-1
    motion_pre_t=motion.*0;
    motion_pre_t(2:end,:)=motion(1:end-1,:);

    %% Motion t-1 Squared
    motion_pre_t_square=motion_pre_t.*motion_pre_t;

    %% Create Censor File
    censor=ones(size(FD));
    bad=find(FD>=.4);
    censor(bad)=0;

    %% Bad TRs - Next TR bad also
    censor(bad+1)=0;
    censor=censor(1:size(motion_d,1));
    % it is possible the above line adds an extra TR, so make sure its not there

    num_TRs=sum(censor);
    if num_TRs<round(length(censor)./2)
        censor=zeros(length(censor),1);
    end

    dlmwrite([dir subj '/' subdir study '.' subj '.' task '.FD.1D'],FD,' ');
    dlmwrite([dir subj '/' subdir study '.' subj '.' task '.motion_derivative.1D'],motion_d,' ');
    dlmwrite([dir subj '/' subdir study '.' subj '.' task '.censor.1D'],censor,' ');
    dlmwrite([dir subj '/' subdir study '.' subj '.' task '.num_TRs'],num_TRs,' ');
    dlmwrite([dir subj '/' subdir study '.' subj '.' task '.motion.square.1D'],motion_square,' ');
    dlmwrite([dir subj '/' subdir study '.' subj '.' task '.motion_pre_t.1D'],motion_pre_t,' ');
    dlmwrite([dir subj '/' subdir study '.' subj '.' task '.motion_pre_t_square.1D'],motion_pre_t_square,' ');
    
end
