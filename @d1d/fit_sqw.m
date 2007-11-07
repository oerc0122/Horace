function [wout, fitdata] = fit_sqw(win, sqwfunc, pin, varargin)
% Fitting routine for a 1D dataset. If passed an array of 
% 1D datasets, then each is fitted independently to the same function.
%
% Syntax:
%   >> [wout, fitdata] = fit(win, sqwfunc, pin)
%   >> [wout, fitdata] = fit(win, sqwfunc, pin, pfree)
%   >> [wout, fitdata] = fit(win, sqwfunc, pin, pfree, keyword, value)
%
%   keyword example:
%   >> [wout, fitdata] = fit(..., 'fit', fcp)
%
% Input:
% ======
%   win     1D dataset object or array of 1D dataset objects to be fitted
%
%   sqwfunc Handle of the function to calculate sqw. Function should be of form
%           Must have form:
%               weight = sqwfunc (qh,qk,ql,en,p)
%            where
%               qh,qk,ql,en Arrays containing the coordinates of a set of points
%               p           Vector of parameters needed by dispersion function 
%                          e.g. [A,js,gam] as intensity, exchange, lifetime
%               weight      Array containing calculated energies; if more than
%                          one dispersion relation, then a cell array of arrays
%
%   pin     Initial function parameter values [pin(1), pin(2)...]
%
%   pfree   Indicates which are the free parameters in the fit
%           e.g. [1,0,1,0,0] indicates first and third are free
%           Default: all are free
%
%
%   Optional keywords:
%   ------------------
%   'list'  Numeric code to control output to Matlab command window to monitor
%           status of fit
%               =0 for no printing to command window
%               =1 prints iteration summary to command window
%               =2 additionally prints parameter values at each iteration
%
%   'fit'   Array of fit control parameters
%           fcp(1)  relative step length for calculation of partial derivatives
%           fcp(2)  maximum number of iterations
%           fcp(3)  Stopping criterion: relative change in chi-squared
%                   i.e. stops if chisqr_new-chisqr_old < fcp(3)*chisqr_old
%
%   'keep'  Ranges of data to retain for fitting. A range is specified by a pair
%           of numbers which define the lower and upper bounds
%               [xlo,xhi]
%           Several ranges can be given by making an (m x 2) array:
%               [x1_lo, x1_hi; x2_lo, x2_hi; ...]
%
%  'remove' Ranges to remove from fitting. Follows the same format as 'keep'.
%
%   'mask'  Array of ones and zeros, with the same number of elements as the data
%           array, that indicates which of the data points are to be retained for
%           fitting
%
%  'select' Calculates the returned function values, yout, only at the points
%           that were selected for fitting by 'keep' and 'remove'; all other
%           points are set to NaN. This is useful for plotting the output, as
%           only those points that contributed to the fit will be plotted.
%
%   'all'   Requests that the calculated function be returned over
%           the whole of the domain of the input dataset. If not given, then
%           the function will be returned only at those points of the dataset
%           that contain data.
%
% Output:
% =======
%   wout    1D dataset object containing the evaluation of the function for the
%          fitted parameter values.
%
%   fitdata Result of fit for each dataset
%               fitdata.p      - parameter values
%               fitdata.sig    - estimated errors (=0 for fixed parameters)
%               fitdata.corr   - correlation matrix for free parameters
%               fitdata.chisq  - reduced Chi^2 of fit (i.e. divided by
%                                   (no. of data points) - (no. free parameters))
%               fitdata.pnames - parameter names
%                                   [if func is mfit function; else named 'p1','p2',...]
%
% EXAMPLES: 
%
% Fit a Gaussian, starting with height=100, centre=5, sigma=3, and allowing
% height and centre to vary:
%   >> [wfit, fdata] = fit(w, @gauss, [100, 5, 3], [1 1 0])
%
% All parameters free to fit, but use only data in range x=20-100 and 150-300:
%   >> [wfit, fdata] = fit(w, @gauss, [100, 5, 3], 'keep', [20, 100; 150, 300])


% Set defaults:
arglist = struct('fitcontrolparameters',[0.0001 30 0.0001],...
                 'list',0,'keep',[],'remove',[],'mask',[],'selected',0,'all',0);
flags = {'selected','all'};

% Parse parameters:
[args,options,present] = parse_arguments(varargin,arglist,flags);

% Check input arguments:
if options.selected & options.all
    error ('Cannot have both ''selected'' and ''all'' options at the same time')
end

% Perform the fit
wout = win;
for i = 1:length(win)
    qw = dnd_calculate_qw(get(win));
    sel = dnd_retain_for_fit_sqw (get(win), options.keep, options.remove, options.mask);

    s = reshape(win(i).s,numel(win(i).s),1); 
    e = sqrt(reshape(win(i).e,numel(win(i).e),1));% recall that datasets hold variance, no error bars

    if i==2, fitdata(1:numel(win))=fitdata(1); end    % preallocate
    [sout, fitdata(i)] = fit(qw, s, e, sqwfunc, pin, args{:},...
        'fit', options.fitcontrolparameters,...
        'list',options.list,...
        'mask',sel,...
        'selected',options.selected);
    
    wout(i).s = reshape(sout,size(win(i).s));
    wout(i).e = zeros(size(win(i).e));  

    if options.all  % if all data, then turn nans into 0's 
        wout(i).s(isnan(wout(i).s)) = 0;
    end
    
end