function d = smooth_dnd (din, varargin)
% Smooths a 1,2,3 or 4 dimensional dataset
%
%Syntax:
%   >> d = smooth_dnd (din, width, shape)
%
% Input:
% ------
%   din     Input dataset structure
%   width   Vector that sets the extent of the smoothing along each dimension.
%          The interpretation of width depends on the argument 'shape' described
%          below.
%           If width is scalar, then the value is applied to all dimensions
%
%           e.g. if din is a 3-dimensional dataset, valid arguments for width might be:
%                width = [2,4,5]    % 2, 3, 5 along the 1st, 2nd and 3rd dimensions
%                width = 4.5        % 4.5 applied to all dimensions
%           Invalid choices for 3-dimensions are
%                width = [2,3]      % invalid number of dimensions
%
%   shape   Shape of smoothing function
%               'hat'           Hat function
%                                   - width gives FWHH along each dimension in pixels
%                                   - width = 1,3,5,...;  n=0 or 1 => no smoothing
%               'gaussian'      Gaussian; width gives FWHH along each dimension in pixels
%                                   - elements where more than 2% of peak intensity
%                                     are retained
%
%               'resolution'    Correlated Gaussian - 2D only (suitable for e.g. powder data)
%
% Output:
% -------
%   dout    Smoothed data structure

% Original author: T.G.Perring
%
% $Revision: 1062 $ ($Date: 2015-09-17 15:40:19 +0100 (Thu, 17 Sep 2015) $)
%
% Horace v0.1   J. van Duijn, T.G.Perring

% List available functions and set defaults. If more functions are to be
% added as smoothing options, then place in the Horace private directory
shapes = {'hat'; 'gaussian'; 'resolution'};       % internally available functions for convolution
shape_handle = {@smooth_func_hat; @smooth_func_gaussian; @smooth_func_resolution};    % corresponding function handles
width_default = 3;
shape_default = 'hat';
ishape_default = 1;

% Check input parameters
ndim = length(din.pax);   % no. dimensions of the data

width = width_default*ones(1,ndim);
shape = shape_default;
ishape= ishape_default;

if nargin>=2
    width = varargin{1};
end

if nargin>=3
    shape = varargin{2};
    if ~isempty(shape) && is_string(shape)
        ishape = stringmatchi (shape,shapes);
        if numel(ishape)>1
            error ('Ambiguous convolution function name')
        elseif isempty(ishape)
            error (['Function ''',shape,''' is not recognised as an available option'])
        end
    else
        error ('Argument ''shape'' must be a character string')
    end
end

% Check width parameters against the shape function
if strcmp(shape,'resolution') && ~(ndim==2 && numel(width)==3)
    error ('Smoothing option ''resolution'' only available for 2D data sets with three width parameters')
elseif ~(isa_size(width,[1,ndim],'double') || isa_size(width,[1,1],'double'))
    error ('ERROR: argument ''width'' must be a scalar or vector with length equal to the dimensions of the dataset')
elseif isa_size(width,[1,1],'double')
    width = width*ones(1,ndim); % if input is scalar, expand to dimension of dataset
end
    
% Catch trivial case of zero dimensional dataset
if ndim==0
    d = din;
    return
end

% Create convolution array
c = shape_handle{ishape}(width);    % use function handles to create matrix - can add further functions above wihout altering remaining code

% Smooth data structure
m=warning('off','MATLAB:divideByZero');     % turn off divide by zero messages, saving present state

index = din.npix~=0;                        % elements with non-zero counts
weight = convn(double(index),c,'same');     % weight function including only points where there is data
% Not all algorithms correctly ensure s=e=0 for bins where npix=0, so because here it matters
% so much, explicitly ensure
signal=din.s; signal(~index)=0;
signal = convn(signal,c,'same')./weight;     % points with no data (i.e. signal = 0) do not contribute to convolution
err=din.e; err(~index)=0;
err = convn(err,c.^2,'same')./(weight.^2);

warning(m.state,'MATLAB:divideByZero');     % return to previous divide by zero message state

signal(~index) = 0;     % restore zero signal to those bins with no data
err(~index) = 0;
clear weight            % save memory (may be critical for 4D datasets)

% Create output structure (NOTE: leave d.npix unaltered from input)
d = din;
d.s = signal;
d.e = err;
