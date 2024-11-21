% MVPA Passive Movement Exp 1
% Gustavo Pamplona, 05.11.2021

clear

folderName='D:\MVPA_passive_movement\Exp1';

nsubjs=19;

for subj=6:nsubjs
    
    cfg = decoding_defaults;

    cfg.analysis = 'searchlight'; % standard alternatives: 'wholebrain', 'ROI' (pass ROIs in cfg.files.mask, see below)
    cfg.searchlight.radius = 3; % use searchlight of radius 3 (by default in voxels), see more details below
%     cfg.analysis = 'ROI'; % standard alternatives: 'wholebrain', 'ROI' (pass ROIs in cfg.files.mask, see below)

    if length(num2str(subj))==1
        subj_folder=[folderName '\Data\S0' num2str(subj)]; % subject folder
        cfg.results.dir = ['D:\MVPA_passive_movement\MVPA_results\Exp1\Amplitude\1stLevel\S0' num2str(subj)];
    else
        subj_folder=[folderName '\Data\S' num2str(subj)]; % subject folder
        cfg.results.dir = ['D:\MVPA_passive_movement\MVPA_results\Exp1\Amplitude\1stLevel\S' num2str(subj)];
    end

    beta_loc = [subj_folder '\1stLevel_unsmoothed'];

    cfg.files.mask = ['D:\MVPA_passive_movement\Analysis\mask_lowerRes.nii'];
%     cfg.files.mask = 'D:\MVPA_passive_movement\MVPA_results\Exp1\Amplitude\ROI\Lpostcentral_6mm.nii';

    % Manual selection
    x=dir([beta_loc '\beta*.nii']);
    load([subj_folder '\1stLevel\SPM.mat'])
    strLabels=['A1';'A2';'A3']; % amplitude
%     strLabels=['V1';'V2';'V3']; % velocity
%     strLabels=['e';'f']; % direction
    
    ncat=size(strLabels,1);
    nreps=162;
    nrepscat=24; % amplitude/velocity
%     nrepscat=36; % direction
    nruns=4;
    
    k=1;
    for j=1:ncat
        for i=1:2:nreps
            if length(SPM.xX.name{1,i})>8
                if strcmp(SPM.xX.name{1,i}(7:8),strLabels(j,:))==1 % amplitude
%             if strcmp(SPM.xX.name{1,i}(9:10),strLabels(j,:))==1 % velocity
%                 if strcmp(SPM.xX.name{1,i}(11),strLabels(j,:))==1 % direction
                    y{1,k}=[beta_loc '\' x(i).name];
                    chunk(k,1)=str2num(SPM.xX.name{1,i}(4));
                    k=k+1;
                end
            end
        end
    end
    cfg.files.name=y';
    cfg.files.chunk=chunk;
    
    cfg.design.train=+repmat(~eye(nrepscat),ncat,1); % repmat(~eye(#repetitions),#categories,1)
    cfg.design.test=repmat(eye(nrepscat),ncat,1); % repmat(eye(#repetitions),#categories,1)
    desLabel=[];
    filesLabel=[];
    for categ=1:ncat
        desLabel=[desLabel;categ*ones(nrepscat)];
        filesLabel=[filesLabel;categ*ones(nrepscat,1)];
    end
    cfg.design.label=desLabel;
    cfg.files.label=filesLabel;
    
    cfg.design.set=ones(1,nrepscat);

    cfg.searchlight.unit = 'mm'; % comment or set to 'voxels' if you want normal voxels
    cfg.searchlight.radius = 12; % this will yield a searchlight radius of 12 units (here: mm).
    cfg.searchlight.spherical = 0;
    cfg.verbose = 1;
    cfg.decoding.method = 'classification_kernel'; % this is our default anyway.

    cfg.scale.method = 'min0max1';
    cfg.scale.estimation = 'all'; % scaling across all data is equivalent to no scaling (i.e. will yield the same results), it only changes the data range which allows libsvm to compute faster

    cfg.plot_selected_voxels = 250; % 0: no plotting, 1: every step, 2: every second step, 100: every hundredth step...

%     cfg.results.output = {'confusion_matrix'}; % 'accuracy_minus_chance' by default
    cfg.results.output = {'accuracy_minus_chance'}; % 'accuracy_minus_chance' by default
    cfg.plot_design = 1; % this will call display_design(cfg);
%     display_design(cfg);
    cfg.results.overwrite = 1;

    results = decoding(cfg);
%     figure;imagesc(results.confusion_matrix.output{1})
    
%     confmat_all(:,:,subj)=results.confusion_matrix.output{1};
    
    clear cfg
    
end