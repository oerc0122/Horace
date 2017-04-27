function wout = IX_dataset_1d (w)
% Convert 1D sqw object into IX_dataset_1d
%
%   >> wout = IX_dataset_1d (w)

% Original author: T.G.Perring
%
% $Revision$ ($Date$)


% Check input
if isempty(w)
    error('sqw object is an empty array')
end
for i=1:numel(w)
    if dimensions(w(i))~=1
        if numel(w)==1
            error('sqw object is not one dimensional')
        else
            error('Not all elements in the array of sqw objects are one dimensional')
        end
    end
end

% Fill output
wout=IX_dataset_1d;
if numel(w)>1, wout(numel(w))=wout; end  % allocate array

for i=1:numel(w)
    [title_main, title_pax] =w(i).data.data_plot_titles();   % note: axes annotations correctly account for permutation in w.data.dax
    

    s_axis = IX_axis ('Intensity');
    x_axis = IX_axis (title_pax{1});

    nopix=(w(i).data.npix==0);
    signal=w(i).data.s;
    signal(nopix)=NaN;
    err=sqrt(w(i).data.e);
    err(nopix)=0;

    wout(i) = IX_dataset_1d (title_squeeze(title_main), signal, err, s_axis, w(i).data.p{1}, x_axis, true);

end

wout=reshape(wout,size(w));
