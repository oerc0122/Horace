function [wout, fitdata, ok, mess] = fit_func(win, varargin)
% *** Deprecated function ***
%   This function is no longer maintained. It is strongly recommended
%   that you use multifit_func instead. For more information about multifit_func
%   <a href="matlab:help('d4d/multifit_func');">click here</a>.
%
%   Help for the legacy operation can be <a href="matlab:help('d4d/fit_legacy_func');">found here</a>]

%-------------------------------------------------------------------------------
% <#doc_def:>
%   multifit_doc = fullfile(fileparts(which('multifit')),'_docify')
%   doc_deprecated_fit = fullfile(multifit_doc,'doc_deprecated_fit.m')
%
% -----------------------------------------------------------------------------
% <#doc_beg:> multifit
%   <#file:>  <doc_deprecated_fit>  d4d/  _func
% <#doc_end:>
%-------------------------------------------------------------------------------


[wout,fitdata,ok,mess] = fit_legacy_func(win, varargin{:});
