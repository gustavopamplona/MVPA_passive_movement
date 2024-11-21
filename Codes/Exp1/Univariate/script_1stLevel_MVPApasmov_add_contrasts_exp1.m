% Create one contrast per row of ANOVA - MVPA passive movement - Exp1

% Gustavo Pamplona, 30.08.22

clear

data_folder='D:\MVPA_passive_movement\Exp1\Data';

subject_folder=dir(data_folder);
subject_folder(1:2)=[];
n_subj=length(subject_folder);
first_subj=2;

% for subj=first_subj:n_subj
for subj=1
    
    subject_folder(subj).name
    
    % batch
    load('D:\MVPA_passive_movement\Analysis\Exp1\Univariate\batch_1stLevel_MVPApasmov_add_contrasts_exp1.mat')
    
    spmFile=[data_folder filesep subject_folder(subj).name filesep '1stLevel_smoothed' filesep 'SPM.mat'];
    
    matlabbatch{1,1}.spm.stats.con.spmmat{1,1}=spmFile;
        
    spm_jobman('run',matlabbatch);

end