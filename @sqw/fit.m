function [wout, fitdata] = fit(win, func_handle, pin, varargin)
% Fits a function to an sqw object. If passed an array of 
% sqw objects, then each is fitted independently to the same function.
%
% Syntax:
%   >> [wout, fitdata] = fit(win, func_handle, pin)
%   >> [wout, fitdata] = fit(win, func_handle, pin, pfree)
%   >> [wout, fitdata] = fit(win, func_handle, pin, pfree, pbind)
%   >> [wout, fitdata] = fit(..., keyword, value)
%
%   keyword example:
%   >> [wout, fitdata] = fit(..., 'fit', fcp)
%
% Input:
% ======
%   win     sqw object or array of sqw objects to be fitted
%
%   func_handle    
%           Function handle to function to be fitted e.g. @gauss
%           Must have form:
%               y = my_function (x1,x2,... ,xn,p)
%
%            or, more generally:
%               y = my_function (x1,x2,... ,xn,p,c1,c2,...)
%
%               - p         a vector of numeric parameters that can be fitted
%               - c1,c2,... any further arguments needed by the function e.g.
%                          they could be the filenames of lookup tables for
%                          resolution effects)
%           
%           e.g. Two dimensional Gaussian:
%               function y = gauss2d(x1,x2,p)
%               y = p(1).*exp(-0.5*(((x1 - p(2))/p(4)).^2+((x2 - p(3))/p(5)).^2);
%
%   pin     Initial function parameter values [pin(1), pin(2)...]
%            - If the function my_function takes just a numeric array of parameters, p, then this
%             contains the initial values [pin(1), pin(2)...]
%            - If further parameters are needed by my_function, then wrap as a cell array
%               {[pin(1), pin(2)...], c1, c2, ...}  
%
%   pfree   [Optional] Indicates which are the free parameters in the fit
%           e.g. [1,0,1,0,0] indicates first and third are free
%           Default: all are free
%
%   pbind   [Optional] Cell array that indicates which of the free parameters are bound to other parameters
%           in a fixed ratio determined by the initial parameter values contained in pin:
%             pbind={1,3}               parameter 1 is bound to parameter 3.
%             pbind={{1,3},{4,3},{5,6}} parameter 1 bound to 3, 4 bound to 3, and 5 bound to 6
%                                       In this case, parmaeters 1,3,4,5,6 must all be free in pfree.
%           To explicity give the ratio, ignoring that determined from pin:
%             pbind=(1,3,0,7.4)         parameter 1 is bound to parameter 3, ratio 7.4 (the extra '0' is required)
%             pbind={{1,3,0,7.4},{4,3,0,0.023},{5,6}}
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
%   'keep'  Ranges of x and y to retain for fitting. A range is specified by two 
%           pairs of numbers which define a rectangle:
%               [xlo, xhi, ylo, yhi]
%           Several ranges can be defined by making an (m x 4) array:
%               [xlo(1), xhi(1), ylo(1), yhi(1); xlo(2), xhi(2), ylo(2), yhi(2); ...]
%
%  'remove' Ranges to remove from fitting. Follows the same format as 'keep'.
%
%   'mask'  Array of ones and zeros, with the same number of elements as the data
%           array, that indicates which of the data points are to be retained for
%           fitting
%
%  'select' Calculates the returned function values, yout, only at the points
%           that were selected for fitting by 'keep', 'remove' and 'mask'.
%           This is useful for plotting the output, as only those points that
%           contributed to the fit will be plotted.
%
% Output:
% =======
%   wout    sqw object containing the evaluation of the function for the
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
% Fit a 2D Gaussian, allowing only height and position to vary:
%   >> ht=100; x0=1; y0=3; sigx=2; sigy=1.5;
%   >> [wfit, fdata] = fit(w, @gauss2d, [ht,x0,y0,sigx,0,sigy], [1,1,1,0,0,0])
%
% Allow all parameters to vary, but remove two rectangles from the data
%   >> ht=100; x0=1; y0=3; sigx=2; sigy=1.5;
%   >> [wfit, fdata] = fit(w, @gauss2d, [ht,x0,y0,sigx,0,sigy], ...
%                               'remove',[0.2,0.5,2,0.7; 1,2,1.4,3])


% Original author: T.G.Perring
%
% $Revision: 101 $ ($Date: 2007-01-25 09:10:34 +0000 (Thu, 25 Jan 2007) $)


% Check if any objects are zero dimensional before evaluating fuction, to save on possible expensive computations
% before a 0D object is found in the array
for i = 1:numel(win)
    if isempty(win(i).data.pax)
        error('func_eval not supported for zero dimensional objects');
    end
end

% Evaluate function for each element of the array of sqw objects
wout=win;
if ~iscell(pin), pin={pin}; end  % make a cell for convenience
for i = 1:numel(win)    % use numel so no assumptions made about shape of input array
    if i==1
        [wout(i),fitdata] = multifit (win(i), @func_eval, {func_handle, pin{:}}, varargin{:});
        if numel(win)>1
            fitdata=repmat(fitdata,size(win));  % preallocate
        end
    else
        [wout(i),fitdata(i)] = multifit (win(i), @func_eval, {func_handle, pin{:}}, varargin{:});
    end
end
