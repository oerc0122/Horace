function  validate_horace(opt)
% Run unit tests on Horace installation
%
%   >> validate_horace


% On exit always revert to initial Horace configuration
% ------------------------------------------------------
% (Validation must always return Horace to its initial state, regardless
%  of any changes made in the test routines)
parallell=true;
if nargin > 0 
    if strcmpi('-nopar',opt)
        parallell = false;
    end
end

cur_config=get(hor_config,'-public');   % only get the public i.e. not sealed, fields
cleanup_obj=onCleanup(@()validate_horace_cleanup(cur_config,{}));


% Turn on unit test functions if required
% ---------------------------------------
validate_herbert('-enable')     % note: does not change Herbert configuration

% Get path to unit tests:
horace_path = fileparts(which('horace_init'));
test_path=fullfile(horace_path,'_test');


% Run unit tests
% --------------
% Set Horace configuration to the default (but don't save)
% (The validation should be done starting with the defaults, otherwise an error
%  may be due to a poor choice by the user of configuration parameters)
set(hor_config,'defaults','-buffer');
set(hor_config,'horace_info_level',-1,'-buffer');    % turn off Horace informational output

% warning off all;
%==============================================================================
% Place call to tests here
% -----------------------------------------------------------------------------
% Still need to add: 'test_admin'  'test_energy_binning'  'test_transformation'
test_folders={...
    'test_ascii_column_data',...
    'test_change_crystal',...
    'test_file_input_methods',...
    'test_gen_sqw_for_powders',...
    'test_herbert_utilites',...
    'test_mslice_utilities',...
    'test_multifit',...
    'test_sqw'...
    };
%=============================================================================
test_f = cellfun(@(x)fullfile(test_path,x),test_folders,'UniformOutput',false);
cleanup_obj=onCleanup(@()validate_horace_cleanup(cur_config,test_f)); 

if license('checkout','Distrib_Computing_Toolbox') && parallell
    cores = feature('numCores');
    matlabpool(cores);   
    parfor i=numel(test_f)
        addpath(test_f{i})
        runtests(test_f{i})
        rmpath(test_f{i})        
    end
else
    for i=1:numel(test_f)
        addpath(test_f{i});    
        runtests(test_f{i})
        rmpath(test_f{i})
    end
end


% warning on all;


% Turn off unit test functions if required
% ----------------------------------------
validate_herbert('-revert')


%=================================================================================================================
function validate_horace_cleanup(cur_config,test_folders)
% Reset the configuration
set(hor_config,cur_config);
% clear up the test folders, previously placed on the path
warn = warning('off','all'); % avoid varnings on deleting non-existent path
for i=1:numel(test_folders)
    rmpath(test_folders{i});
end
warning(warn);

