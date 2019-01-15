function general_multiband_slice_timing(subjects, conditions, runs )
% This is a simple wrapper function that does slice timing corrections for
% the Deckersbach group for their multi-band imaging scans. Assumes a scan
% with 63 slices collected in an interleaved fashion (odds-first) across
% three volumes.
% go to matlab and open spm then type the exact function. SPM will open a window which will 
% allow you to select your exact files etc..

%% Example Commands: 

% 1. general_multiband_slice_timing({'hc001', 'hc003'},{'msit','ecr'},{1})
% 2. general_multiband_slice_timing({'hc001', 'hc003'},{'arc_rer'},{1,2,3})

% Note: arc_rer can only be processed by itself. 
% Other tasks may be processed together.

%% Specify root directory and subjects.
addpath '/autofs/cluster/pubsw/1/pubsw/common/spm/spm8';
spm('defaults', 'FMRI');
spm_jobman('initcfg');
spm_get_defaults('cmdline',true);

numSub = length(subjects);
numConds = length(conditions);
numRuns = length(runs);

%% Select nii file.
for subIdx = 1:numSub
    for condIdx = 1:numConds
        for runIdx = 1:numRuns
            %% Specify TR and Task Directory.
            switch conditions{condIdx}
                case 'msit'
                    TR = 1750
                    dir = '/space/lilli/4/users/DARPA-MSIT/msit';
            end

            %% Specify Run Directory.
	    func_dir = 'func'
	    analysis_dir = 'msit_bsm'
            run_dir = [dir filesep 'subjs' filesep subjects{subIdx} filesep analysis_dir filesep func_dir]
	    disp(run_dir)

            %% Select functional files.
            msg = ['Select files for ' subjects{subIdx}]   
            P = spm_select(Inf,'image',msg,[],run_dir,'func.nii','1:1000');

            %% Cue for TR.
    %         TR = inputdlg(['TR:','Please enter TR for ' conditions{condIdx}]);
    %         TR = str2double(TR);

            %% Define parameters.
            % Define slice orders.
            sliceorder = [1:2:21 2:2:21; 22:2:42 23:2:42; 43:2:63 44:2:63]';

            % Define reference slice.
            refslice = 1;

            % Timing
            nSlices = 21;
            TA = TR - (TR/nSlices);
            timing(1) = TA / (nSlices - 1);
            timing(2) = TR - TA;

            % Prefix
            prefix = 'a';

            %% Perform slice timing.
            try
                spm_mbst(P, sliceorder, refslice, timing, prefix);
            catch
                1+1;
            continue
            end
        end
    end
end

end

