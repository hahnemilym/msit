clear

task='msit_bsm';
study='msit';
dir = '/autofs/space/lilli_004/users/DARPA-MSIT/msit/subjs/';
subdir = ['/' task '/' 'func' '/'];

subjects_list={'hc001','hc002','hc003','hc004','hc005','hc006','hc007','hc009','hc010',...
'hc011','hc012','hc013','hc014','hc015','hc017','hc018','hc019','hc020','hc021',...
'hc022','hc023','hc024','hc028','hc029','hc030','hc031','hc032',...
'hc033','hc034','hc035','hc036','hc038','hc042',...
'pp001','pp002','pp003','pp004','pp005','pp006','pp007','pp008','pp010',...
'pp011','pp012','pp013','pp015','pp016'};

%subjects_list={'hc008'}

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
    
    disp(['Motion regressors generated: ' subj])
end
