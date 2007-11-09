function data=get_spe(filename)
% Load VMS format ASCII .spe file
%   >> data = get_spe(filename)
%
% data has following fields:
%   data.filename   Name of file excluding path
%   data.filepath   Path to file including terminating file separator
%   data.S          [ne x ndet] array of signal values
%   data.ERR        [ne x ndet] array of error values (st. dev.)
%   data.en         Column vector of energy bin boundaries

% T.G.Perring   13/6/07

% If no input parameter given, return
if ~exist('filename','var')
    help get_spe;
    return
end

% Remove blanks from beginning and end of filename
filename=strtrim(filename);

% Get file name and path (incl. final separator)
[path,name,ext,ver]=fileparts(filename);
data.filename=[name,ext,ver];
data.filepath=[path,filesep];

% Read spe file using fortran routine
disp(['Fortran loading of .spe file : ' filename]);
[data.S,data.ERR,data.en]=get_spe_fortran(filename);
[ne,ndet]=size(data.S);
disp([num2str(ndet) ' detector(s) and ' num2str(ne) ' energy bin(s)']);

