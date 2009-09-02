function varargout=function_dnd(infile,func,varargin)
% Generic function to take file input sqw or d0d,d1d,...d4d data source to Horace functions.
% If sqw-type data (i.e. include pixel information), this ignored and the data is treated as
% the equivalend d0d,d1d,...d4d-type.
%
%   >> varargout=function_horace(infile,@some_function,args)
%
% Input:
% ------
%   infile  Name of input data file
%   func    Handle to function to be executed. The input and output arguments must have particular form
%               [out1,out2,...]  = some_function(data_source_obj,data_source_struct,arg1,arg2,...)
%           where
%               data_source_obj     sqw or d0d, d1d,...d4d object
%               dnd_obj             d0d, d1d,...d4d object
%               data_source_struct  structure of form:
%                   data_source_struct.keyword     '$file_data'
%                   data_source_struct.file        Input file name
%                   data_source_struct.sqw_type    How to read data file: =true if sqw_type, =false if dnd_type
%                   data_source_struct.ndims       Dimensions of the sqw object
%               arg1,arg2,...       Input arguments
%               out1,out2,...       Output arguments
%                                  If file input, then out1,out2,... must be packaged into a single
%                                  cell array as the sole output argument. See @sqw/read for an example.
%               
%   args        Cell array of arguments to be passed to the Horace function
%
% Output:
% -------
%   varargout   Cell array of output arguments rom the Horace function
%
% NOTE:
%   data_source_struct.sqw_type is not necessarily the same as the type of data in the file.
%  if sqw_type data in the file, we may still set the flag so that it is read as dnd-type data.

% Original author: T.G.Perring
%
% $Revision$ ($Date$)


[sqw_type, nd, data_source, mess] = is_sqw_type_file(sqw,infile);
if ~isempty(mess), error(mess), end
data_source.sqw_type=false;     % enforce reading as dnd object

% Branch on type of data in the file, and if there are output arguments or not
% Recall that if the input data source was a file, we demand that all output
% arguments from the function being called are returned in a cell array.
% Consequently we can pass the output straight to the output of this function.
% We check the case of no output arguments as this can be significant - for example,
% in the cut method for sqw object, no output means that the output is written to file
% and so cuts that are far too large to be held in the matlab workspace can be performed.


if nd==0
    if nargout==0
        func(d0d,data_source,varargin{:});
    else
        varargout = func(d0d,data_source,varargin{:});
    end
elseif nd==1
    if nargout==0
        func(d1d,data_source,varargin{:});
    else
        varargout = func(d1d,data_source,varargin{:});
    end
elseif nd==2
    if nargout==0
        func(d2d,data_source,varargin{:});
    else
        varargout = func(d2d,data_source,varargin{:});
    end
elseif nd==3
    if nargout==0
        func(d3d,data_source,varargin{:});
    else
        varargout = func(d3d,data_source,varargin{:});
    end
elseif nd==4
    if nargout==0
        func(d4d,data_source,varargin{:});
    else
        varargout = func(d4d,data_source,varargin{:});
    end
else
    error('Dimensionality of dnd object must be 0,1,2..4')
end
