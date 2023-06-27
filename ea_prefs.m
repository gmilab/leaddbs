function prefs = ea_prefs(patientname, context)

if ~exist('patientname', 'var')
    patientname = '';
end

% 'normal' context by default. If context is not 'normal' (cluster run or
% exported job case), 'machine' settings will not be added to 'prefs' here.
% The value will be read from options.prefs.machines.
if ~exist('context', 'var')
    context = 'normal';
end

% get default prefs
dprefs = ea_prefs_default(patientname);
dmachine = load([ea_getearoot, 'common', filesep, 'ea_prefs_default.mat']);

% check user prefs
home = ea_gethome;

% if isdeployed
%     disp(['Running Lead-DBS in compiled mode, CTFROOT=', ea_getearoot, '; HOME=', home, '.']);
% end

userpref_m_file = ea_paths('user_prefs_m', 'init');
userpref_mat_file = ea_paths('user_prefs_mat', 'init');

% load user prefs
try
    uprefs = ea_prefs_user(patientname);  % remove janky file copying requirement for user preferences file
    umachine = load(userpref_mat_file);
catch ME
    error('Error loading lead DBS user preferences. %s', ME.message);
end


% combine default prefs and user prefs
prefs = combinestructs(dprefs, uprefs);

% add machine prefs only when lead task is not running on a cluster or with
% exported job file. In both cases, machine prefs will be defined in
% options.prefs.machine.
if strcmp(context, 'normal')
    prefs.machine = combinestructs(dmachine.machine, umachine.machine);
end

% legacy code support for gl/l normalized file differentiation:
prefs.prenii=prefs.gprenii;
prefs.tranii=prefs.gtranii;
prefs.cornii=prefs.gcornii;
prefs.sagnii=prefs.gsagnii;
prefs.ctnii=prefs.gctnii;


function prefs = combinestructs(prefs, uprefs)

ufn = fieldnames(uprefs);

% Handle struct arrays of different sizes
if length(uprefs) > length(prefs)
    prefs = cat(prefs, uprefs(length(prefs)+1:end));
end

% Iterate through struct array. Most prefs are a single struct, not an array.
for sa_ix = 1:length(uprefs)
    for fn_ix = 1:length(ufn)
        fn = ufn{fn_ix};
        if isstruct(uprefs(sa_ix).(fn)) && isfield(prefs(sa_ix), fn)
            prefs(sa_ix).(fn) = combinestructs(prefs(sa_ix).(fn), uprefs(sa_ix).(fn));
        else
            prefs(sa_ix).(fn) = uprefs(sa_ix).(fn);
        end
    end
end
