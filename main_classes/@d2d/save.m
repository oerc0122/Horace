function save (w, file)
% Save a sqw object to file
%
%   >> save_sqw (w)              % prompt for file
%   >> save_sqw (w, file)        % give file
%
% Input:
%   w       sqw object
%   file    [optional] File for output. if none given, then prompted for a file
%
% Output:

% Original author: T.G.Perring
%
% $Revision: 1358 $ ($Date: 2016-11-23 11:38:32 +0000 (Wed, 23 Nov 2016) $)


extension='d2d';

% ----- The following shoudld be independent of d0d, d1d,...d4d ------------
% Work via sqw class type

% Get file name - prompting if necessary
if nargin==1 
    file_internal = putfile(['*.',extension]);
    if (isempty(file_internal))
        error ('No file given')
    end
else
    [file_internal,mess]=putfile_horace(file);
    if ~isempty(mess)
        error(mess)
    end
end
if ~iscellstr(file_internal)
    file_internal=cellstr(file_internal);
end
if numel(file_internal)~=numel(w)
    error('Number of data objects in array does not match number of file names')
end

% Write data to file. TODO: OOM violation -- use local method to save. 
save(sqw(w),file_internal)
