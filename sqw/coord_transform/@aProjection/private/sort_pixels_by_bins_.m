function [s,e,npix,pix,pix_range] = sort_pixels_by_bins_(obj,pix,pix_transf,pix_range)
% Bin pixels into 4D grid, defined by aProjection in the range defined by
% pix_range if present or projection range
%

%
% $Revision: 1471 $ ($Date: 2017-04-24 10:26:58 +0100 (Mon, 24 Apr 2017) $)
%

% Flag if grid is in fact just a box i.e. 1x1x1x1
grid_is_unity = all(obj.grid_size == [1,1,1,1]);

% Set urange, and determine if all the data is on the surface or within the box defined by the ranges
urange = obj.img_range;
%
if isempty(pix_range)
    data_in_range = true;
    pix_range = urange;
else
    if any(pix_range(1,:)<urange(1,:)) || any(pix_range(2,:)>urange(2,:))
        data_in_range = false;
    else
        data_in_range = true;
    end
end
% If grid that is other than 1x1x1x1, or range was given, then sort pixels
if grid_is_unity && data_in_range   % the most work we have to do is just change the bin boundary fields
    s=sum(pix(8,:));
    e = sum(pix(9,:)); % take advantage of the squaring that has already been done for pix array
    npix=size(pix,2);
else
    [use_mex,nThreads,hor_log_level]=config_store.instance().get_value('hor_config',...
        'use_mex','threads','log_level');
    
    if hor_log_level>0
        disp('Sorting pixels ...')
    end
    use_mex = false; %TODO: for the time being
    if use_mex
        try
            % Verify the grid consistency and build axes along the grid dimensions,
            % c-program does not check the grid consistency;
            
            sqw_fields   =cell(1,4);
            sqw_fields{1}=nThreads;
            %sqw_fields{1}=8;
            sqw_fields{2}=urange;
            sqw_fields{3}=obj.grid_size;
            sqw_fields{4}=pix_transf;
            
            out_fields=bin_pixels_c(sqw_fields);
            
            s   = out_fields{1};
            e   = out_fields{2};
            npix= out_fields{3};
            pix = out_fields{4};
        catch Er
            warning('HORACE:using_mex','calc_sqw->Error: ''%s'' received from C-routine to rebin data, using matlab functions',Er.message);
            use_mex=false;
        end
    end
    if ~use_mex
        % sort pixels according their bins
        grid_size = obj.grid_size;
        [ix,npix,ibin]=sort_pixels_(pix_transf(1:4,:),urange,grid_size);
        
        pix=pix(:,ix);
        %se =pix_transf(8:9,ix);
        
        s=reshape(accumarray(ibin,pix(8,:),[prod(grid_size),1]),grid_size);
        e=reshape(accumarray(ibin,pix(9,:),[prod(grid_size),1]),grid_size);
        npix=reshape(npix,grid_size);      % All we do is write to file, but reshape for consistency with definition of sqw data structure
        s=s./npix;       % normalise data
        e=e./npix.^2;  % normalise variance
        clear ix ibin   % biggish arrays no longer needed
        nopix=(npix==0);
        s(nopix)=0;
        e(nopix)=0;
        
        clear nopix     % biggish array no longer needed
    end
    
    % If changed urange to something less than the range of the data, then must update true range
    if ~data_in_range
        pix_range(1,:)=min(pix(1:4,:),[],2)';
        pix_range(2,:)=max(pix(1:4,:),[],2)';
    end
end


