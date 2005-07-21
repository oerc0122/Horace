function wout = section (win, varargin)
% Takes a section out of a 3-dimensional dataset.
%
% Syntax:
%   >> wout = section (win, [ax_1_lo, ax_1_hi], [ax_2_lo, ax_2_hi], [ax_3_lo, ax_3_hi])
%
% Input:
% ------
%   win                 3-dimensional dataset.
%
%   [ax_1_lo, ax_1_hi]  Lower and upper limits for the first axis.
%                       To retain the limits of the input structure, type the scalar '0'
%
%   [ax_2_lo, ax_2_hi]  Lower and upper limits for the second axis
%
%   [ax_3_lo, ax_3_hi]  Lower and upper limits for the third axis
%                       
%
% Output:
% -------
%   wout                Output dataset.
%
%
% Example: to alter the limits of the first and third axes:
%   >> wout = section (win, [1.9,2.1], 0, [-0.55,-0.45])
%                                                           

% Original author: T.G.Perring
%
% $Revision$ ($Date$)
%
% Horace v0.1   J.Van Duijn, T.G.Perring

if nargin==1
    wout = dnd_create(dnd_section(get(win)));
else
    wout = dnd_create(dnd_section(get(win), varargin));
end