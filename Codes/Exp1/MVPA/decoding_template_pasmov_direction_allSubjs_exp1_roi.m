% MVPA Passive Movement Exp 1 - direction - ROI
% Gustavo Pamplona, 05.11.2021

% update 08.02.2023: ROI analysis

clear

folderName='D:\MVPA_passive_movement\Exp1';

nsubjs=19;

roi_filename = '6-sphere_5-42_-28_17_roi';

for subj=1:nsubjs
    
    cfg = decoding_defaults;

%     cfg.analysis = 'searchlight'; % standard alternatives: 'wholebrain', 'ROI' (pass ROIs in cfg.files.mask, see below)
%     cfg.searchlight.radius = 3; % use searchlight of radius 3 (by default in voxels), see more details below
    cfg.analysis = 'ROI'; % standard alternatives: 'wholebrain', 'ROI' (pass ROIs in cfg.files.mask, see below)

    if length(num2str(subj))==1
        subj_folder=[folderName '\Data\S0' num2str(subj)]; % subject folder
        cfg.results.dir = ['D:\MVPA_passive_movement\MVPA_results\Exp1\Direction\ROI_analysis_peaks_new\S0' num2str(subj) '\' roi_filename];
    else
        subj_folder=[folderName '\Data\S' num2str(subj)]; % subject folder
        cfg.results.dir = ['D:\MVPA_passive_movement\MVPA_results\Exp1\Direction\ROI_analysis_peaks_new\S' num2str(subj) '\' roi_filename];
    end

    beta_loc = [subj_folder '\1stLevel_unsmoothed'];

%     cfg.files.mask = ['D:\MVPA_passive_movement\Analysis\mask_lowerRes.nii'];
    cfg.files.mask = ['D:\MVPA_passive_movement\MVPA_results\Exp1\Direction\2ndLevel\peaks\'  roi_filename '.nii'];

    % Manual selection
    x=dir([beta_loc '\beta*.nii']);
    load([subj_folder '\1stLevel\SPM.mat'])
%     strLabels=['A1';'A2']; % amplitude
%     strLabels=['V1';'V2']; % velocity
    strLabels=['e';'f']; % direction
    
    ncat=size(strLabels,1);
    nreps=162; % exp1
%     nreps=82; % exp2
    nrepscat=16; % amplitude/velocity/direction
%     nruns=4;
    
    k=1;
    for j=1:ncat
        for i=1:2:nreps
            if length(SPM.xX.name{1,i})>8
%                 if strcmp(SPM.xX.name{1,i}(7:8),strLabels(j,:))==1 % amplitude
%                     if strcmp(SPM.xX.name{1,i}(9:10),strLabels(j,:))==1 % velocity
                if strcmp(SPM.xX.name{1,i}(11),strLabels(j,:))==1 % direction
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
    cfg.searchlight.radius = 8; % this will yield a searchlight radius of 12 units (here: mm).
    cfg.searchlight.spherical = 0;
    cfg.verbose = 1;
    cfg.decoding.method = 'classification_kernel'; % this is our default anyway.

    cfg.scale.method = 'min0max1';
    cfg.scale.estimation = 'all'; % scaling across all data is equivalent to no scaling (i.e. will yield the same results), it only changes the data range which allows libsvm to compute faster

%     cfg.plot_selected_voxels = 250; % 0: no plotting, 1: every step, 2: every second step, 100: every hundredth step...

    cfg.results.output = {'confusion_matrix'}; % 'accuracy_minus_chance' by default
%     cfg.results.output = {'accuracy_minus_chance','SVM_weights'}; % 'accuracy_minus_chance' by default
    cfg.plot_design = 0; % this will call display_design(cfg);
%     display_design(cfg);
    cfg.results.overwrite = 1;
    cfg.scale.check_datatrans_ok = true;

    results = decoding(cfg);
%     figure;imagesc(results.confusion_matrix.output{1})
    
    confmat_all(:,:,subj)=results.confusion_matrix.output{1};
    
    clear cfg
    
end

%compute mean
n_features=length(strLabels);

for i=1:n_features
    for j=1:n_features
        confmat_mean(i,j)=mean(confmat_all(i,j,:));
        confmat_std(i,j)=std(confmat_all(i,j,:));
    end
end

% bootstrapping
n=size(confmat_all,3);
mat_dim=size(confmat_all,1);
n_comb=mat_dim^2;
chance_value=100/mat_dim;
j=1;

for column=1:mat_dim
    for row=1:mat_dim
        
        for i=1:n
            r(i)=confmat_all(row,column,i);
        end
        
        % bootstrapping
        nReps = 100000;
        alpha = .05/n_comb;        %alpha value, corrected by Bonferroni
        
        myStatistic = @(r) mean(r);
        
        sampStat = myStatistic(r);
        bootstrapStat = zeros(nReps,1);
        for i=1:nReps
            sampr = r(ceil(rand(n,1)*n));
            bootstrapStat(i) = myStatistic(sampr);
        end
        
        CI = prctile(bootstrapStat,[100*alpha/2,100*(1-alpha/2)]);
        
        %Hypothesis test: Does the confidence interval cover the chance value?
        H = CI(1)>chance_value | CI(2)<chance_value;
        
        H_all(j,1)=H;
        
        j=j+1;

    end
end

% plotting
A = confmat_mean;   %sample data
[R, C] = ndgrid(1:size(A,1), 1:size(A,2));
R = R(:); C = C(:) - 1/4;
%rows are Y values, columns are X values !
figure;imagesc(A)
hold on
colormap(flipud(hot))
caxis([10 90]);
vals = A(:);
mask = vals <= chance_value;
H_str(H_all==1)={'*'};
H_str(H_all==0)={''};
text(C(mask), R(mask), [num2str(vals(mask),4) char(H_str(mask))], 'color', 'black','FontSize',20,'FontWeight','bold')
text(C(~mask), R(~mask), [num2str(vals(~mask),4) char(H_str(~mask))], 'color', 'white','FontSize',20,'FontWeight','bold')
axis off
hold off