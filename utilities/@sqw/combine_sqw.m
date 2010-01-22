function wout=combine_sqw(w1,w2)
%
% wout=combine_sqw(w1,w2)
%
% Combine two sqw objects (w1 and w2) of the same dimensionality into a single
% sqw object in order to improve statistics. Note that w1 AND w2 must be
% "true" sqw object, for which pixel information has been retained.
%
% The output object will have a combined value for the integration range
% e.g. combining two 2d slices taken at L=1 and L=2 will result in an
% output for which the stated value of L is L=1.5
%
% Two objects which use different projection axes can be combined. The
% output object will have the projection axes of w1.
%
% RAE 21/1/10
%



w1=sqw(w1); w2=sqw(w2);

if ~is_sqw_type(w1) || ~is_sqw_type(w2)
    error('Horace error: input objects must be sqw type with detector pixel information');
end

[ndims1,sz1]=dimensions(w1);
[ndims2,sz2]=dimensions(w2);
if ndims1~=ndims2
    error('Horace error: the 2 input sqw objects must have the same dimensionality');
end

%========
%Determine min/max co-ordinates.

%First for the 1st dataset:
coords_rlu1=inv(w1.data.u_to_rlu) * w1.data.pix([1:4],:);
rlutrans=[(2*pi./w1.data.alatt)'; 1];
coords_rlu1=coords_rlu1./repmat(rlutrans,1,numel(coords_rlu1) /4);
%
for i=1:ndims1
    min_1{i}=min(coords_rlu1(w1.data.pax(i),:));
    max_1{i}=max(coords_rlu1(w1.data.pax(i),:));
end

%Next do the same for the 2nd dataset:
coords_rlu2=inv(w1.data.u_to_rlu) * w2.data.pix([1:4],:);%notice we put this in the co-ord
%frame of w1. We are not interested in the co-ord frame of w2, just its
%pixel info, which is in inverse Angstroms and meV
rlutrans=[(2*pi./w1.data.alatt)'; 1];
coords_rlu2_new=coords_rlu2./repmat(rlutrans,1,numel(coords_rlu2) /4);
%
for i=1:ndims1
    min_2{i}=min(coords_rlu2_new(w2.data.pax(i),:));
    max_2{i}=max(coords_rlu2_new(w2.data.pax(i),:));
end

%Now work out the full extent of the symmetrised data:
for i=1:ndims1
    min_full{i}=min([min_1{i} min_2{i}]);
    max_full{i}=max([max_1{i} max_2{i}]);
end

%The output will eventually be an sqw object, but for now we need it to be
%a structure array, since during intermediate steps it will not be
%consistent with the sqw format.
wout=get(w1);

for i=1:ndims1
    step=wout.data.p{i}(2)-wout.data.p{i}(1);
    wout.data.p{i}=[min_full{i}-step+eps:step:max_full{i}+step-eps]';
end
    
%Question - how do we deal with the fact that the integration range along
%one or more of the non-plot axes must be different for the two objects? Do
%we just take the average?? If we do not address this point then the
%integration range required by w1 will be applied to the data from w2. This
%effectively means that we are only splicing data together (e.g. sticking 2
%2-d planes together).

%We must ensure that no detector pixels are double counted when we
%combine! Can use the function "unique" to do this:
pixfull=[w1.data.pix w2.data.pix]';%(n1+n2)-by-9 array
pixfull=unique(pixfull,'rows');%keeps only non-repeated rows

%Now make this unique set of combined pixels the output pix array:
wout.data.pix=pixfull';

%We need to fiddle the integration ranges so that all of the data for the
%combined dataset is included. Can do this by looking at the minima and
%maxima of the coresponding values in the pix array.
nints=4-ndims1;
if nints>=1
    for i=1:nints
        intmin_1{i}=min(coords_rlu1(w1.data.iax(i),:));
        intmax_1{i}=max(coords_rlu1(w1.data.iax(i),:));
        intmin_2{i}=min(coords_rlu2_new(w2.data.iax(i),:));
        intmax_2{i}=max(coords_rlu2_new(w2.data.iax(i),:));
    end
end

if nints>=1
    for i=1:nints
        intmin{i}=min([intmin_1{i} intmin_2{i}]);
        intmax{i}=max([intmax_1{i} intmax_2{i}]);
    end
end

intlimits=[cell2mat(intmin); cell2mat(intmax)];
wout.data.iint=intlimits;

if nints>=1
    for i=1:nints
        wout.data.urange(:,wout.data.iax(i))=intlimits(:,i);
    end
end


%Must declare wout.data.s etc with the correct number of elements. Also
%must ensure the sum of the npix array is equal to the number of columns in
%pixfull;

horace_info_level(-Inf);
if ndims1==1
    wout.data.s=zeros(length(wout.data.p{1})-1,1);
    wout.data.e=wout.data.s;
    wout.data.npix=wout.data.s;
    wout.data.npix(1)=numel(wout.data.pix(1,:));
    wout=sqw(wout);
    wout=cut(wout,[]);
elseif ndims1==2
    wout.data.s=zeros(length(wout.data.p{1})-1,length(wout.data.p{2})-1);
    wout.data.e=wout.data.s;
    wout.data.npix=wout.data.s;
    wout.data.npix(1,1)=numel(wout.data.pix(1,:));
    wout=sqw(wout);
    wout=cut(wout,[],[]);
elseif ndims1==3
    wout.data.s=zeros(length(wout.data.p{1})-1,length(wout.data.p{2})-1,...
        length(wout.data.p{3})-1);
    wout.data.e=wout.data.s;
    wout.data.npix=wout.data.s;
    wout.data.npix(1,1,1)=numel(wout.data.pix(1,:));
    wout=sqw(wout);
    wout=cut(wout,[],[],[]);
elseif ndims1==4
    wout.data.s=zeros(length(wout.data.p{1})-1,length(wout.data.p{2})-1,...
        length(wout.data.p{3})-1,length(wout.data.p{4})-1);
    wout.data.e=wout.data.s;
    wout.data.npix=wout.data.s;
    wout.data.npix(1,1,1,1)=numel(wout.data.pix(1,:));
    wout=sqw(wout);
    wout=cut(wout,[],[],[],[]);
else
    error('ERROR: Dimensions of dataset is not integer in the range 1 to 4');
end
horace_info_level(Inf);
