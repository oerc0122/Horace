function [u] = calc_proj_matlab (c, q)
%      MATLAB-file to convert Q from spectrometer coordinates
%      to components along momentum projection axes
% 
%      Syntax:
%      >> u = calc_proj_matlab (c, q)
% 
%      c(3,3)          Matrix to convert components from
%                         spectrometer frame to projection axes
%      q(4,npix)       Coordinates of momentum  & energy transfer 
%                     in spectrometer frame
% 
%      u(4,npix)       Coordinates along projection axes
% 

% Original author: Ibon Bustinduy
%
% $Revision: 101 $ ($Date: 2007-01-25 09:10:34 +0000 (Thu, 25 Jan 2007) $)
%
% Revised TGP 4 Sep 2008 to use Matlab matrix multiplication

% Calculate projections
u = c*q(1:3,:);
u = [u;q(4,:)];