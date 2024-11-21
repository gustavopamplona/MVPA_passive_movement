clear

data_folder='D:\MVPA_passive_movement\Exp1\Data';
roi_folder='D:\MVPA_passive_movement\Univariate_results\Exp1\2ndLevel_ANOVA\meAmplitude\peak_ROIs';

subject_folder=dir(data_folder);
subject_folder(1:2)=[];
n_subj=length(subject_folder);
first_subj=1;

labels={'subj' 'amplitude' 'velocity' 'direction' 'beta'};

roi_files=dir(fullfile(roi_folder, '*.mat'));
n_rois=length(roi_files);

h = waitbar(0,sprintf('running %d jobs',n_subj*n_rois)); % set up the 'waitbar'

for roi=1:n_rois
    
    Z=[];
    
    roi_file=[roi_folder filesep roi_files(roi).name(1:end-4) '.mat'];
    R  = maroi(roi_file); % Make marsbar ROI object
    
    for subj=first_subj:n_subj
        
        spmFile=[data_folder filesep subject_folder(subj).name filesep '1stLevel_smoothed' filesep 'SPM.mat'];
        
        D  = mardo(spmFile); % Make marsbar design object
        Y  = get_marsy(R, D, 'mean'); % Fetch data into marsbar data object
        xCon = get_contrasts(D); % Get contrasts from original design
        E = estimate(D, Y); % Estimate design on ROI data
        E = set_contrasts(E, xCon); % Put contrasts from original design back into design object
        b = betas(E); % get design betas
%         marsS = compute_contrasts(E, 1:n_con); % get stats and stuff for all contrasts into statistics structure

        load(spmFile)
        
        j=1;
        
        for i=1:2:length(b)
            if length(SPM.xX.name{1,i})>14
                amp_cell{j,1}=SPM.xX.name{1,i}(7:8);
                vel_cell{j,1}=SPM.xX.name{1,i}(9:10);
                dir_cell{j,1}=SPM.xX.name{1,i}(11);
                beta_cell{j,1}=b(i);
                j=j+1;
            end
        end
                
        subj_cell=num2cell(subj*ones(length(beta_cell),1));
        
        X=[subj_cell amp_cell vel_cell dir_cell beta_cell];
        
        Z=[Z;X];
        
        clear X beta_cell subj_cell
        waitbar((subj+(roi-1)*n_subj)/(n_subj*n_rois),h)
        
    end
    
    Z=[labels;Z];
    
    xlswrite(['D:\MVPA_passive_movement\Univariate_results\Exp1\2ndLevel_ANOVA\meDirection\peakTables\table_' roi_files(roi).name(1:end-4) '.xlsx'],Z);
    
end
delete(h)