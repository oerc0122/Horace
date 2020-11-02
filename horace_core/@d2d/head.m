function varargout = head (varargin)
% Display a summary of a d2d object or file containing d2d information.
% 
%   >> head(w)              % Summary for object (or array of objects)
%   >> head(d2d,filename)   % Summary for named file (or array of names)
%
% To return header information in a structure, without displaying to screen:
%
%   >> h=head(...)          % Fetch principal header information
%
%
% The facility to get head information from file(s) is included for completeness, but
% more usually you would use the function:
%   >> head_horace(filename)
%   >> h=head_horace(filename)
%
%
% Input:
% -----
%   w           d2d object or array of d2d objects
%       *OR*
%   d2d         Dummy d2d object to enforce the execution of this method.
%               Can simply create a dummy object with a call to d2d:
%                   e.g. >> w = head(d2d,'c:\temp\my_file.d2d')
%
%   file        File name, or cell array of file names. In latter case, displays
%               summary for each sqw object
%
% Output (optional):
% ------------------
%   h           Structure with header information, or cell array of structures if
%               given a cell array of file names.

% Original author: T.G.Perring
%
% $Revision:: 1759 ($Date:: 2020-02-10 16:06:00 +0000 (Mon, 10 Feb 2020) $)

% ----- The following shoudld be independent of d0d, d1d,...d4d ------------
% Work via sqw class type


% Parse input
% -----------
[w, args, mess] = horace_function_parse_input (nargout,varargin{:},'$obj_and_file_ok');
if ~isempty(mess), error(mess); end

% Perform operations
% ------------------
% Now call sqw cut routine. Output (if any), is a cell array, as method is passed a data source structure
argout=head(sqw_old,w,args{:});

% Package output arguments
% ------------------------
[varargout,mess]=horace_function_pack_output(w,argout{:});
if ~isempty(mess), error(mess), end

