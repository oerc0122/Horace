function [iW,iPx,nPt,fst,lst,iPt,VxR] = gst_points_in_pixels_res(win,lookup,pnt,pnt_head,pnt_list)
% For all pixels in all SQW objects, determine which points of pntQE are
% within resolution, and what the value of the pixel resolution-volume 
% times the value of the pixel resolution-function is at the point 
% locations, returning the information in six vectors.
% A number of important pieces of information must be precalculated by the
% initialization function and placed in the lookup.

% Inputs:
%        win     a vector of SQW objects, needed to pull out nominal (Q,E)
%                for all pixels
%
%     lookup     the associated lookup table(s) for win, required for
%                cell_span, cell_N, QE, QE_head, QE_list, mat_hkle, and
%                ell_hkle
%
%        pnt     The full (Q,E) points to be considered, (4,[total points])
%
%   pnt_head     The head of a linked list for all (Q,E) points, (1,nCell)
%
%   pnt_list     The list of a linked list for all (Q,E) points, (1,[total points])
%
% Outputs:
%       iW      the elements of iW are the indicies of the SQW object that
%               the associated pixel came from.
%
%       iPx     the pixel indicies (within each SQW object) which give the
%               associated detector pixel. Within each constant-iW block,
%               these indicies will always be a permutation of 
%               1:[# SQW pixels] but are almost guaranteed to *not* in
%               order.
%
%       nPt     the number of points within resolution of the associated
%               detector pixel
%
%       Pt1     the first element of the output point index vector and
%               resolution probability vector associated with the 
%               associated detector pixel
%
%       iPt     A list of all points associated with all pixels in all SQW
%
%       VxR     The resolution volume of the associated pixel times the
%               value of the pixel's resolution function evaluated at its
%               associated points

nwin = numel(win);
nPx = arrayfun( @(x)(size( x.data.pix, 2)), win);
this_nPt = numel(pnt_list); % or size(pntQE,2)

iW  = zeros(1,sum(nPx));
iPx = zeros(1,sum(nPx));
nPt = zeros(1,sum(nPx));
fst = zeros(1,sum(nPx));
lst = zeros(1,sum(nPx));
iPt = zeros(1,sum(nPx)*this_nPt);
VxR = zeros(1,sum(nPx)*this_nPt);
offsetPt = 0; % offset for iPt, VxR
offsetPx = 0; % offset for iW, iPx, nPt, Pt1

spanCell = lookup.cell_span;
nCell = lookup.cell_N;
for i=1:nwin 
    % Pull predetermined values from the lookup
    % Pixel QE points and linked list arranging pixels by neighbourhood cell
    pix = lookup.QE{i};
    pix_head = lookup.QE_head{i};
    pix_list = lookup.QE_list{i};
    % Pixel (Gaussian width) resolution matrix
    pixM = lookup.mat_hkle{i};
    % Pixel constant-probability (half-width, fractional-height) ellipsoid
    pixL = lookup.ell_hkle{i};
    
    % For each pixel with (Q,E) 'pix' determine which points with 
    % (Q,E) 'pnt' are within the pixel resolution ellipsoid pixL.
    % To make things as complex as possible: 
    %   The total (Q,E) space is divided up into cells, described by
    %   spanCell and nCell, and the points and pixels are grouped into
    %   the cells using linked lists (*_head,*_list). For a given cell,
    %   only the points in that or neighbouring cells are considered for
    %   resolution-inclusion. 
    %   The output is a special set of vectors designed to avoid using
    %   MATLAB cell-arrays. (Wouldn't it be great to have Arrays of Arrays?)
    %       iPx         the pixel indicies, some permutation of 1:npix
    %       nPt         the number of points within resolution for each iPx
    %       Pt1         the first index into iPt associated with each iPx
    %       iPt         a list of point indicies (up to) npt*npix in
    %                   length, but likely less, containing all point
    %                   indicies for each pixel
    [this_iPx,this_nPt,this_fst,this_lst,this_iPt] = point_in_resolution(spanCell,nCell,pnt,pnt_head,pnt_list,pix,pixL,pix_head,pix_list);
%     fprintf('%d ',this_nPt'); fprintf('\n');
    this_VxR = zeros(size(this_iPt));
    for j=1:nPx(i)
        % the vector of indicies into iPt to determine *which* (Q,E) points
        % are included in the convolution for the iPx(j)th pixel.
        pt1n = this_fst(j):this_lst(j);
        % Calculate the probability of each included (Q,E) point being
        % measured within the resolution of pixel iPx(j). The final 'false'
        % ensures that the probability is *not* normalized by the
        % resolution volume - and therefore we get V(R(Q0,E0))*R(Q-Q0,E-E0)
        this_VxR(pt1n) = probability_of_point( pnt(:, this_iPt(pt1n)), pixM(:,:,this_iPx(j)), pix(:,this_iPx(j)), false);
    end
    k = offsetPx+(1:nPx(i)); 
    iW ( k ) = i;
    iPx( k ) = this_iPx;
    nPt( k ) = this_nPt;
    fst( k ) = this_fst + offsetPt; % must offset the first-point index into iPt, VxR;
    lst( k ) = this_lst + offsetPt; % and the last-point index
    
    f = offsetPt+(1:numel(this_iPt));
    iPt( f ) = this_iPt;
    VxR( f ) = this_VxR;
    
    offsetPx = offsetPx+nPx(i);
    offsetPt = offsetPt+numel(this_iPt);
end
% And finally truncate the variable-sized outputs
iPt = iPt(1:offsetPt);
VxR = VxR(1:offsetPt);
end