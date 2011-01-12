function varargout = head(varargin)
% Read header of a d2d object stored in a file, or objects in a set of files
% 
%   >> h=head(d2d,file)
%
% Gives the same information as display for a d2d object.
%
% Need to give first argument as an d2d object to enforce a call to this function.
% Can simply create a dummy object with a call to d2d:
%    e.g. >> head(d2d,'c:\temp\my_file.d2d')
%
% Input:
% -----
%   d2d         Dummy d2d object to enforce the execution of this method.
%               Can simply create a dummy object with a call to d2d:
%                   e.g. >> w = read(d2d,'c:\temp\my_file.d2d')
%
%   file        File name, or cell array of file names. In latter case, displays
%               summary for each d2d object
%
% Output (optional):
% ------------------
%   h           Structure with header information, or cell array of structures if
%               given a cell array of file names.

% Original author: T.G.Perring
%
% $Revision$ ($Date$)

% ----- The following shoudld be independent of d0d, d1d,...d4d ------------
% Work via sqw class type


% If data source is a filename or data_source structure, then must ensure that matches dnd type
[data_source, args, source_is_file, sqw_type, ndims, source_arg_is_filename, mess] = parse_data_source (sqw(varargin{1}), varargin{2:end});
if ~isempty(mess)
    error(mess)
end
if source_is_file   % either file names or data_source structure as input
    if any(sqw_type) || any(ndims~=dimensions(varargin{1}(1)))     % must all be the required dnd type
        error(['Data file(s) not (all) ',classname,' type i.e. no pixel information'])
    end
end

% Now call sqw head routine
if nargout==0
    if source_is_file
        head(sqw,data_source,args{:});
    else
        head(sqw(data_source),args{:});
    end
else
    if source_is_file
        argout=head(sqw,data_source,args{:});   % output is a cell array
    else
        argout=head(sqw(data_source),args{:});
    end
end

% Package output: if file data source structure then package all output arguments as a single cell array, as the output
% will be unpacked by control routine that called this method. If object data source or file name, then package as conventional
% varargout

% In this case, there is only one output argument
if nargout>0
    if source_is_file && ~source_arg_is_filename
        varargout{1}={argout};
    else
        varargout{1}=argout;
    end
end
