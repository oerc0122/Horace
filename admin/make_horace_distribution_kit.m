function make_horace_distribution_kit(varargin)
% function creates Horace distribution kit packing all files necessary for
% Horace to work into single zip file
%
%Usage:
%>>make_horace_distribution_kin(['-reveal_code','-compact'])
%
%where optional arguments are:
%'-reveal_code'  -- if present, do not request p-code Horace; default pCode
%                    the private Horace folders
%'-compact'      -- if present, request dropping the demo and test files
%                   with test folders, default -- compress demo and tests
%                   together with main code.
%'-noherbert'    -- do not pack Herbert together with Horace
%
% excludes (not copies to distribution) all files and subfolders of a folder where 
% _exclude_all.txt file is found
%
% excludes (not copies to distribution) all files of a folder where 
% _exclude_files.txt file is found but keeps subfolders of this folder and 
% processes the files of the subfolder.
%
% To use Horace  one has to unpack the resulting zip file and add the folder
% where the function Horace_init.m resides to the Matlab search path.
% alternatively, you can edit the file Horace_on.template, file and
% replace the variable $herbert_path$ and $Horathe_path$ by the actual
% folders  where the files Horace_init.m and libisis_init.m or herbert_init reside
% (Horace needs Libisis or Herbert to work)
% and add to the search path the file Horace_on.m,
% after renaming the file Horace_on.m.template to horace_on.m.
%
%
% $Revision$ ($Date$)
%
%
% known keys
keys = {'-reveal_code','-compact','-noherbert'};
% default key values
reveal_code = false;
no_demo     = false;
no_herbert  = false;
if nargin>0
    if ~all(ismember(varargin,keys))
        non_member=~ismember(varargin,keys);
        for i=1:nargin
            if non_member(i)
                disp(['Unrecognized key: ',varargin{i}]);
            end
        end
        error('MAKE_HORACE_DISTRIBUTION_KIT:invalid_argument',' unknown or unsupported key %s %s %s',varargin{non_member});
    end
    % interpret existing keys
    if ismember('-reveal_code',varargin)
        reveal_code =true;
    end
    if ismember('-compact',varargin)
        no_demo=true;
    end
    if ismember('-noherbert',varargin)
        no_herbert  = true;
    end
    
end

rootpath = fileparts(which('horace_init')); % MUST have rootpath so that horace_init, horace_off are included
%
disp('!===================================================================!')
disp('!==> Preparing HORACE distribution kit  ============================!')
disp('!    Start collecting the Horace program files =====================!')
%
dir_to_return_to='';
current_dir  = pwd;
root_dir     = current_dir;
% if inside Horace package dir, go avay from there:
if strncmpi(rootpath,current_dir,numel(rootpath))
    dir_to_return_to = current_dir;
    cd(rootpath);
    cd('../');
    current_dir  = pwd;
    root_dir     = current_dir;
end

target_Dir=[root_dir,'/ISIS'];
horace_dir = [target_Dir,'/Horace'];
% copy everything, which can be found under root Horace folder
copy_files_list(rootpath,horace_dir);
% copy source code files from system directory
copy_files_list(fullfile(rootpath,'_LowLevelCode'),fullfile(horace_dir,'_LowLevelCode'),...
    '+_','h','cpp','c','sln','vcproj');


% remove sqw and intermediate working file if they are there
if exist(fullfile(horace_dir,'demo','fe_demo.sqw'),'file')
    delete(fullfile(horace_dir,'demo','fe_demo.sqw'))
end
delete(fullfile(horace_dir,'demo','*.spe'));
delete(fullfile(horace_dir,'demo','*.nxspe'));
delete(fullfile(horace_dir,'demo','*.spe_h5'));
delete(fullfile(horace_dir,'demo','*.tmp'));

% Delete unwanted directories (with all their sub-directories)
% ------------------------------------------------------------
deldir{1}='_developer_only';
deldir{2}='_work';
for i=1:numel(deldir)
    diry = fullfile(horace_dir,deldir{i});
    if exist(diry,'dir')
        rmdir(diry,'s');
    end
end

% if necessary, remove demo and test folders
if no_demo
    if exist(fullfile(horace_dir,'demo'),'dir')
        rmdir(fullfile(horace_dir,'demo'),'s');
    end
    if exist(fullfile(horace_dir,'test'),'dir')
        rmdir(fullfile(horace_dir,'test'),'s');
    end
    delete(fullfile(horace_dir,'admin','validate_horace.m'));
else
    % copy source code files from system directory
    copy_files_list(fullfile(rootpath,'_test'),fullfile(horace_dir,'_test'),'+_')
end
% copy the file which should initiate Horace (after minor modifications)
% copyfile('horace_on.mt',[target_Dir '/horace_on.mt'],'f');
% copyfile('start_app.m',[target_Dir '/start_app.m'],'f');
install_script=which('horace_on.m.template');
copyfile(install_script,fullfile(target_Dir,'horace_on.m.template'),'f');
%
disp('!    The HORACE program files collected successfully ==============!')
if(~reveal_code)
    disp('!    p-coding private Horace parts and deleting unnecessary folders=!')
    pCode_Horace_kit(horace_dir);
    disp('!    Horace p-coding completed =====================================!')
end

% if Herbert used, add Herbert distribution kit to the distribution
if ~no_herbert
    argi{1}='-run_by_horace';
    if no_demo
        argi{2} = '-compact';
    end
    make_herbert_distribution_kit(target_Dir,argi{:});
    pref='';
else
    pref='_only';
end
%
%
disp('!    Start compressing all necessary files together ================!')
%
if no_demo
    horace_file_name=['Horace',pref,'_nodemo.zip'];
else
    horace_file_name= ['horace',pref,'_distribution_kit.zip'];
end
horace_file_name=fullfile(current_dir,horace_file_name);
if(exist(horace_file_name,'file'))
    delete(horace_file_name);
end

cd(current_dir);
zip(horace_file_name,target_Dir);
if ~isempty(dir_to_return_to)
    [dir,hor_shortname,ext]=fileparts(horace_file_name);
    [err,mess]=movefile(horace_file_name,fullfile(dir_to_return_to,[hor_shortname,ext]),'f');
    if err
        disp(['Error copying file to destination: ',mess]);
        warning('MAKE_HORACE_DISTRIBUTION_KIT:copy_file',...
            ' can not move distributive into target folder %s\n left it in the folder %s\n',...
            dir_to_return_to,dir);
    end
    cd(dir_to_return_to);
end

%[err,mess]=movefile(horace_file_name,current_dir);
%cd(current_dir);
%
disp('!    Files compressed. Deleting the auxiliary files and directories=!')
source_len = numel(rootpath);
if ~strncmp(horace_dir,rootpath,source_len)
    rmdir(horace_dir,'s');
end
if ~strcmpi(target_Dir,current_dir)
    rmdir(target_Dir,'s');
end

disp('!    All done folks ================================================!')
sound(-1:0.001:1);

disp('!===================================================================!')
