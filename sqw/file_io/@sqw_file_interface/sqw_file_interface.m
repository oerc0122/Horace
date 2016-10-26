classdef sqw_file_interface < dnd_binfile_common
    % Class to describe interface to access sqw files.
    %
    %   Various accessors should inherit this class, implement the
    %   abstract methods mentioned here and define protected fields, common
    %   for all sqw-file accessors
    %
    %
    % $Revision: 877 $ ($Date: 2014-06-10 12:35:28 +0100 (Tue, 10 Jun 2014) $)
    %
    properties(Access=protected)
        %
        num_contrib_files_ = 'uninitiated'
        %
        npixels_ = 'uninitiated';
    end
    properties(Dependent)
        % number of files, used to construct this class
        num_contrib_files;
        % number of pixels, contributing into this file. Empty for dnd-type
        % files
        npixels
    end
    %----------------------------------------------------------------------
    methods
        function nfiles = get.num_contrib_files(obj)
            % return number of run-files contributed into sqw object
            % provided
            nfiles = obj.num_contrib_files_;
        end
        function npix = get.npixels(obj)
            npix = obj.npixels_;
        end
        
        %-------------------------
        function obj = close(obj)
            obj.num_contrib_files_ = 'uninitiated';
            obj.npixels_ = 'uninitiated';
            close@dnd_file_interface(obj);
        end
    end
    %----------------------------------------------------------------------
    %----------------------------------------------------------------------
    methods(Abstract)
        % retrieve different parts of sqw data
        %main_header = get_main_header(obj,['-verbatim']);
        main_header = get_main_header(obj,varargin);
        %
        header      = get_header(obj,varargin);
        detpar      = get_detpar(obj,varargin);
        pix         = get_pix(obj,varargin);
        [inst,obj]  = get_instrument(obj,varargin);
        [samp,obj]  = get_sample(obj,varargin);
    end
    
end

