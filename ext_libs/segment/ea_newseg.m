function ea_newseg(directory,files,dartel,options,del,force)
% SPM NewSegment
% we cannot generate the TPM from the SPM TPM anymore since
% we use the enhanced TPM by Lorio / Draganski:
% http://unil.ch/lren/home/menuinst/data--utilities.html

% keep the 'y_*' and 'iy_*' file by default
if ~exist('del', 'var')
    del = 0;
end
if ~exist('force', 'var')
    force = 0;
end
if ischar(files)
    files = {files};
end

ea_create_tpm_darteltemplate; % function will check if needs to run (again).

if (~dartel && exist([directory, 'c1', files{1}], 'file') || dartel && exist([directory, 'rc1', files{1}], 'file')) && (~force)
    disp('Segmentation already done!');
else
    disp('Segmentation...');

    load([ea_getearoot,'ext_libs',filesep,'segment',filesep,'segjob12']);
    tpminf = [ea_space,'TPM.nii'];
    for fi=1:length(files) % add channels for multispectral segmentation
        job.channel(fi).vols = {[directory, files{fi}, ',1']};
        job.channel(fi).biasreg = 0.001;
        job.channel(fi).biasfwhm = 60;
        job.channel(fi).write = [0 0];
    end
    
    job.warp.reg=job.warp.reg*options.prefs.machine.normsettings.spmnewseg_scalereg;

    tpmHdr = ea_open_vol(tpminf);
    tpmnum = tpmHdr.volnum;

    for tpm=1:tpmnum
        job.tissue(tpm).tpm = [tpminf, ',', num2str(tpm)];
        if tpm <= 3 && dartel
            job.tissue(tpm).native = [1 1];
        end
        if tpm >= 4
            if force==2
                job.tissue(tpm).native = [1 0];
            else
                job.tissue(tpm).native = [0 0];
            end
        end
    end

    job.tissue(tpm+1:end) = [];
    if del
        job.warp.write = [0,0];
    else
        job.warp.write = [1,1];
    end

    spm_preproc_run(job); % run "Segment" in SPM 12 (Old "Segment" is now referred to as "Old Segment").
    % delete unused files
    [~,fn] = fileparts(files{1});
    ea_delete([directory, fn, '_seg8.mat']);

    if dartel && any(ea_detvoxsize([directory, 'rc1', files{1}]) ~= tpmHdr.voxsize)
        %  SPM may have a bug since r7055 which makes the generated "Dartel
        %  Imported" (rc*) images always having the voxel size of 1.5 as in
        %  SPM's TPM.nii rather than the voxel size of user speficied TPM.
        %
        %  More specifically, new job fields 'warp.bb' and 'warp.vox' are
        %  introduced in 'spm_preproc_run' and set to certain default
        %  values (NaNs and 1.5). However, the two settings are not present
        %  in 'spm_cfg_preproc8'. So one has no control to the settings
        %  from outside. To fix the issue, they either should be properly
        %  exposed or the default value of 'job.warp.vox' needs to be
        %  changed (to NaN).
        %
        %  Workaround: reslice the rc* images to make them consistent with
        %  Lead's TPM.nii in order to do normalization with using SPM
        %  Dartel and Shoot.

        ea_reslice_nii([directory, 'rc1', files{1}], [directory, 'rc1', files{1}], tpmHdr.voxsize);
        ea_reslice_nii([directory, 'rc2', files{1}], [directory, 'rc2', files{1}], tpmHdr.voxsize);
        ea_reslice_nii([directory, 'rc3', files{1}], [directory, 'rc3', files{1}], tpmHdr.voxsize);
    end

    disp('Done.');
end
