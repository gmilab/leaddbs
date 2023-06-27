function space=ea_getspace

%prefs=ea_prefs('');
home = ea_gethome;
ea_paths('user_prefs_mat', 'init');
load(ea_paths('user_prefs_mat'), 'machine');
space = machine.space;
