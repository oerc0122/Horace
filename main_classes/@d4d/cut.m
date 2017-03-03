function varargout = cut (varargin)
% Take a cut from a d4d object by integrating over one or more of the plot axes.
%
%   >> w = cut (data_source, p1_bin, p2_bin, p3_bin, p4_bin)
%
%   >> w = cut (..., '-save')       % Save cut to file (prompts for file)
%   >> w = cut (...,  filename)     % save cut to named file
%
%   >> cut(...)                     % save cut to file; no output workspace 
% 
% Input:
% ------
%   data_source     Data source: file name or d4d object
%                  Can also be a cell array of file names, or an array of
%                  d4d objects.
%
%   p1_bin          Binning along first plot axis
%   p2_bin          Binning along second plot axis
%   p3_bin          Binning along third plot axis
%   p4_bin          Binning along fourth plot axis
%                           
%                   For each binning entry:
%           - [] or ''          Plot axis: use bin boundaries of input data
%           - [pstep]           Plot axis: Step size pstep must be 0 or
%                              the current bin size (no other rebinning
%                              is permitted)
%           - [plo, phi]        Integration axis: range of integration.
%                              Those bin centres that lie inside this range 
%                              are included.
%           - [plo, pstep, phi] Plot axis: minimum and maximum bin centres.
%                              The step size pstep must be 0 or the current
%                              bin size (no other rebinning is permitted)
%
% Output:
% -------
%   w               Output data object (d0d, d1d, d2d, d3d or d4d depending
%                  on binning)


% Original author: T.G.Perring
%
% $Revision: 977 $ ($Date: 2015-02-21 18:58:56 +0000 (Sat, 21 Feb 2015) $)


% ----- The following shoudld be independent of d0d, d1d,...d4d ------------
% Work via sqw class type


% Parse input
% -----------
[w, args, mess] = horace_function_parse_input (nargout,varargin{:});
if ~isempty(mess), error(mess); end

% Perform operations
% ------------------
% Now call sqw cut routine. Output (if any), is a cell array, as method is passed a data source structure
argout=cut(sqw,w,args{:});
if ~isempty(argout)
    argout{1}=dnd(argout{1});   % as return argument is sqw object of dnd-type
end

% Package output arguments
% ------------------------
[varargout,mess]=horace_function_pack_output(w,argout{:});
if ~isempty(mess), error(mess), end
