% Compute contrasts for smoothed images in MVPA passive movement study - Exp 1
% Gustavo Pamplona, 30.08.2022

clear

folderName='D:\MVPA_passive_movement\Exp1';

nsubjs=19;

for subj=1:nsubjs
    
    subj
    
    load('D:\MVPA_passive_movement\Analysis\Exp1\Univariate\batch_anova_contrasts_exp1.mat')
    
    if length(num2str(subj))==1
        matlabbatch{1,1}.spm.stats.con.spmmat{1,1}=[folderName '\Data\S0' num2str(subj) '\1stLevel_smoothed\SPM.mat'];
    else
        matlabbatch{1,1}.spm.stats.con.spmmat{1,1}=[folderName '\Data\S' num2str(subj) '\1stLevel_smoothed\SPM.mat'];
    end
    
    spm_jobman('run',matlabbatch);
    
end