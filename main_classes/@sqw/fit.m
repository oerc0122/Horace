function [wout, fitdata, ok, mess] = fit(win, varargin) 
% Fits a function to an sqw object, with an optional background function. 
% Synonymous with sqw method fit_func 
% 
% A background function can be added to the fit function. 
% If passed an array of datasets, then each dataset is fitted independently. 
% 
% Differs from multifit, which fits all datasets in the array 
% simultaneously but with independent backgrounds. 
% 
% For full help, read the documentation displayed when you type: 
%   >> help sqw/fit_func 
% 
% 
% Fit several datasets in succession to a given function: 
% ------------------------------------------------------- 
%   >> [wout, fitdata] = fit (w, func, pin) 
%   >> [wout, fitdata] = fit (w, func, pin, pfree) 
%   >> [wout, fitdata] = fit (w, func, pin, pfree, pbind) 
% 
% These cover the respective cases of: 
%   - All parameters free 
%   - Selected parameters free to fit 
%   - Binding of various parameters in fixed ratios 
% 
% 
% With optional background function added to the function: 
% -------------------------------------------------------- 
%   >> [wout, fitdata] = fit (..., bkdfunc, bpin) 
%   >> [wout, fitdata] = fit (..., bkdfunc, bpin, bpfree) 
%   >> [wout, fitdata] = fit (..., bkdfunc, bpin, bpfree, bpbind) 
% 
% 
% Additional keywords controlling the fit: 
% ---------------------------------------- 
% You can alter the range of data to fit, alter convergence criteria, 
% verbosity of output etc. with keywords, some of which need to be paired 
% with input values, some of which are just logical flags: 
% 
%   >> [wout, fitdata] = fit (..., keyword, value, ...) 
% 
% Keywords that are logical flags (indicated by *) take the value true 
% if the keyword is present, or their default if not. 
% 
%     Select points to fit: 
%       'keep'          Range of x values to keep. 
%       'remove'        Range of x values to remove. 
%       'mask'          Logical mask array (true for those points to keep). 
%   *   'select'        If present, calculate output function only at the 
%                      points retained for fitting. 
% 
%     Control fit and output: 
%       'fit'           Alter convergence critera for the fit etc. 
%       'list'          Level of verbosity of output during fitting (0,1,2...). 
% 
%     Evaluate at initial parameters only (i.e. no fitting): 
%   *   'evaluate'      Evaluate function at initial parameter values only 
%                      without doing a fit. Performs an argument check as well. 
%                     [Default: false] 
%   *   'foreground'    Evaluate foreground function only (if 'evaluate' is 
%                      not set then ignored). 
%   *   'background'    Evaluate background function only (if 'evaluate' is 
%                      not set then ignored). 
%   *   'chisqr'        Evaluate chi-squared at the initial parameter values 
%                      (ignored if 'evaluate' not set). 
% 
%   EXAMPLES: 
%   >> [wout, fitdata] = fit(...,'keep',[0.4,1.8],'list',2) 
% 
%   >> [wout, fitdata] = fit(...,'select') 
% 
% If unable to fit, then the program will halt and display an error message. 
% To return if unable to fit without throwing an error, call with additional 
% arguments that return status and error message: 
% 
%   >> [wout, fitdata, ok, mess] = fit (...) 
 
% <#doc_def:> 
%   first_line = {'% Fits a function to an sqw object, with an optional background function.',... 
%                 '% Synonymous with sqw method fit_func'}; 
%   main = false; 
%   method = true; 
%   synonymous = true; 
% 
%   multifit=false; 
%   func_prefix='fit'; 
%   func_suffix=''; 
%   differs_from = strcmpi(func_prefix,'multifit') || strcmpi(func_prefix,'fit') 
%   obj_name = 'sqw' 
% 
%   full_help = 'sqw/fit_func' 
% 
%   custom_keywords = false; 
% 
% <#doc_beg:> 
%   <#file:> multifit_doc:::doc_fit_short.m 
% <#doc_end:> 
 
 
% Original author: T.G.Perring 
% 
% $Revision: 998 $ ($Date: 2015-07-06 10:11:24 +0100 (Mon, 06 Jul 2015) $) 
 
 
if nargout<3 
    [wout,fitdata]=fit_func(win, varargin{:});  % forces failure if there is an error, as is the convention for fit when no ok argument 
else 
    [wout,fitdata,ok,mess]=fit_func(win, varargin{:}); 
end 
