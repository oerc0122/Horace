classdef faccess_sqw_v2 < sqw_binfile_common
    % Class to access sqw Horace files written by Horace v1-v2
    %
    % The current sqw file format comes in two variants:
    %   - Horace version 1 and version 2: file format '-v2'
    %   (Autumn 2008 onwards). Does not contain instrument and sample fields in the header block.
    %
    %
    %
    % $Revision$ ($Date$)
    %
    %
    properties(Access = protected)
    end
    methods(Access=protected)
    end
    
    methods
        function obj=faccess_sqw_v2(varargin)
            % constructor, to build sqw reader/writer version 2
            %
            % Usage:
            % ld = faccess_sqw_v2() % initialize empty sqw reader/writer version 2
            %                       The class should be initialized later using
            %                       init command
            % ld = faccess_sqw_v2(filename) % initialize sqw reader/writer  version 2
            %                       to load sqw file version 2.
            %                       Throw error if the file version is not sqw
            %                       version 2.
            % ld = faccess_sqw_v2(sqw_object) % initialize sqw reader/writer version 2
            %                       to save sqw object provided. The name
            %                       of the file to save the object should
            %                       be provided separately.
            %
            obj.sqw_type_ = true;
            if nargin >0
                obj = obj.init(varargin{:});
            end
        end
        %
        function [should,objinit,mess]= should_load_stream(obj,stream,fid)
            % Check if this loader should load input data
            % Currently should any dnd object
            %Usage:
            %
            %>> [should,obj] = obj.should_load_stream(datastream,fid)
            % where
            % datastream:  structure returned by get_file_header function
            % Returns:
            % true if the loader can load these data, or false if not
            % with message explaining the reason for not loading the data
            % of should, object is initiated by appropriate file inentified
            mess = '';
            if isstruct(stream) && all(isfield(stream,{'sqw_type','version'}))
                if stream.sqw_type && ( stream.version == 2 || stream.version == 3 )
                    objinit = obj_init(fid,double(stream.num_dim));
                    should = true;
                    if stream.version == 3
                        warning('SQW_FILE_IO:legacy_data',...
                            ['should_load_stream -- Legacy sqw file version 3.0 has been discovered.\n'...
                            'Loading it as sqw version 2 file with instrument/sample block discarded'])
                    end
                else
                    should = false;
                    objinit  = obj_init();
                    mess = ['not Horace dnd  ',obj.file_version,' file'];
                end
            else
                error('SQW_FILE_IO:invalid_argument',...
                    'should_load_stream -- The input structure does not have correct format');
            end
        end
        %
        function new_obj = upgrade_file_format(obj)
            % Uprade file from format 2 to format 3
            new_obj = upgrade_file_format_(obj);
        end
        
        
        %
        %
    end
    
end

