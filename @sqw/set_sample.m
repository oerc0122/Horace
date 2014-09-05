function varargout = set_sample (varargin)
% Change the sample in an sqw object or array of objects
%
%   >> wout = set_sample (w, sample)
%
%
% Input:
% -----
%   w           Input sqw object or array of objects
%
%   sample      Sample object (IX_sample object) or structure
%              Note: only a single sample object can be provided. That is,
%              there is a single sample for the entire sqw data set.
%               If the sample is any empty object, then the sample is set
%              to the default empty structure.
%
% Output:
% -------
%   wout        Output sqw object with changed sample


% Original author: T.G.Perring
%
% $Revision$ ($Date$)


% This routine is also used to set the sample in sqw files, when it overwrites the input file.

% Parse input
% -----------
[w, args, mess] = horace_function_parse_input (nargout,varargin{:});
if ~isempty(mess), error(mess); end

% Perform operations
% ------------------
narg=numel(args);
if narg==0
    % Nothing to do
    if w.source_is_file
        argout={};
    else
        argout{1}=w.data;
    end
elseif narg==1
    if isscalar(args{1}) && (isstruct(args{1}) || isa(args{1},'IX_sample'))
        sample=args{1}; % single structure or IX_sample
    elseif isempty(args{1})
        sample=struct;  % empty item indicates no sample; set to default 1x1 empty structure
    else
        error('Sample must be a scalar structure or IX_sample object (or an empty argument to indicate ''no sample'')')
    end

    % Check that the data has the correct type
    if ~all(w.sqw_type(:))
        error('Sample can only be set or changed in sqw-type data')
    end
    
    % Change the sample
    if w.source_is_file
        for i=1:numel(w.data)
            % Read the header part of the data
            [h,ok,mess]=get_sqw (w.data{i},'-hisverbatim');
            if ~isempty(mess), error(mess), end
            % Change the header
            nfiles=h.main_header.nfiles;
            if nfiles>1
                tmp=h.header;   % to keep referencing to sub-fields to a minimum
                for ifiles=1:nfiles
                    tmp{ifiles}.sample=sample;
                end
                h.header=tmp;
            else
                h.header.sample=sample;
            end
            % Write back out
            [ok,mess] = put_sqw (w.data{i},h,'-his');
            if ~isempty(mess), error(['Error writing to file ',w.data{i},' - check the file is not corrupted: ',mess]), end
        end
        argout={};
    else
        wout=w.data;
        for i=1:numel(wout)
            nfiles=wout(i).main_header.nfiles;
            if nfiles>1
                tmp=wout(i).header;   % to keep referencing to sub-fields to a minimum
                for ifiles=1:nfiles
                    tmp{ifiles}.sample=sample;
                end
                wout(i).header=tmp;
            else
                wout(i).header.sample=sample;
            end
        end
        argout{1}=wout;
    end
else
    error('Check the number of input arguments')
end


% Package output arguments
% ------------------------
[varargout,mess]=horace_function_pack_output(w,argout{:});
if ~isempty(mess), error(mess), end
