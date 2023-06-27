function rval = ea_paths(varargin)
% Return paths to the various folders used by the toolbox.
paths = struct();
paths.user_prefs_m = fullfile(userpath, 'ea_prefs_user.m');
paths.user_prefs_mat = fullfile(userpath, 'ea_prefs_user.mat');

if nargin == 0
    rval = paths;
else
    rval = paths.(varargin{1});
end

if nargin == 2 && strcmp(varargin{2}, 'init')
    defaults = struct();
    defaults.user_prefs_m = [ea_getearoot, 'common', filesep, 'ea_prefs_default', ea_prefsext];
    defaults.user_prefs_mat = [ea_getearoot, 'common', filesep, 'ea_prefs_default.mat'];

    if ~exist(rval, 'file')
        try
            % try copying using MATLAB's copyfile function
            copyfile(defaults.(varargin{1}), rval);
        catch
            try
                % try copying using system cp
                system(['cp "', defaults.(varargin{1}) '" "', rval, '"']);
            catch
                error('Copy user preference file from %s to %s', defaults.(varargin{1}), rval);
            end
        end
    end
end
