classdef test_serialize_deserialize< TestCase
    %
    % Validate fast sqw reader used in combining sqw
    %
    %
    % $Revision: 877 $ ($Date: 2014-06-10 12:35:28 +0100 (Tue, 10 Jun 2014) $)
    %
    %
    properties
        working_dir;
    end
    methods(Static)
        function clean_file(fid)
            fname = fopen(fid);
            fclose(fid);
            delete(fname);
        end
    end
    
    methods
        
        %The above can now be read into the test routine directly.
        function this=test_serialize_deserialize(varargin)
            if nargin > 0
                name = varargin{1};
            else
                name= mfilename('class');
            end
            this=this@TestCase(name);
            
            this.working_dir = tempdir;
            
        end
        % tests
        function obj = test_serialize(obj)
            test_data = struct('double_v',9,...
                'int_a1',int32([1,2,3]),...
                'double_a2',[1,2,3;4,5,6],...
                'int32_v',int32(10),'uint64_t',100,...
                'string_v','bla_blaE','string_v2','',...
                'vararray_single',[1,2,3],'cellarray_str','',...
                'vararray_single2',[1,2,3;5,6,7],...
                'carray_single',ones(1,10)*10);
            test_data.cellarray_str = {'aaaa';'nn';'ccc'}';
            
            test_format = struct('double_v',double(1),...
                'int_a1',int32([1,3]),'double_a2',[2,3],...
                'int32_v',int32(1),'uint64_t',uint64(1),'string_v','','string_v2','',...
                'vararray_single',field_var_array(1),'cellarray_str',...
                field_cellarray_of_strings(),'vararray_single2',field_var_array(2),...
                'carray_single_size',field_not_in_structure('carray_single'),...
                'carray_single',field_const_array_dependent('carray_single_size'));
            
            
            
            ser = sqw_serializer();
            [struc_pos,pos] = ser.calculate_positions(test_format,test_data);
            assertEqual(pos-1,208);
            
            bytes = ser.serialize(test_data,test_format);
            assertEqual(numel(bytes),pos-1);
            
            [test_pos,pos1] =  ser.calculate_positions(test_format,bytes);
            assertEqual(pos,pos1);
            assertEqual(struc_pos,test_pos);
            
            [recov,pos] = ser.deserialize_bytes(bytes,test_format);
            assertEqual(pos-1,numel(bytes));
            assertTrue(isa(recov.uint64_t,'uint64'));
            test_data.uint64_t = uint64(test_data.uint64_t);
            assertTrue(isa(recov.vararray_single,'single'));
            assertTrue(isa(recov.vararray_single2,'single'));
            test_data.vararray_single = single(test_data.vararray_single);
            test_data.vararray_single2 = single(test_data.vararray_single2);
            assertTrue(isa(recov.carray_single,'single'))
            recov.carray_single = double(recov.carray_single);
            fn = fieldnames(recov);
            for i=1:numel(fn)
                assertEqual(class(recov.(fn{i})),class(test_data.(fn{i})),...
                    ['incorrect field types: ',fn{i}]);
                assertEqual(recov.(fn{i}),test_data.(fn{i}),...
                    ['unequal values for field: ',fn{i}])
            end
            
            
            
        end
        %
        function obj = test_serialize_data(obj)
            test_format = struct(...
                'npax',field_not_in_structure('pax'),...
                'iax',field_iax(),...
                'iint',field_iint(),...
                'pax',field_const_array_dependent('npax',1,'int32'),...
                'p_size',field_p_size(),...
                'p',field_cellarray_of_axis('npax'),...
                'dax',field_const_array_dependent('npax',1,'int32'),...
                's',field_img(),'e',field_img(),'npix',field_img('uint64'),...
                'dummy',field_not_in_structure('pax'),...
                'pix',field_pix());
            test_data1 = struct(...
                'iax',[],'iint',[],...
                'pax',[1,2,3,4],...
                'p','',...
                'dax',[3,2,4,1],...
                's',4*ones(9,9,4,10),'e',ones(9,9,4,10),'npix',2*ones(9,9,4,10),...
                'pix',ones(9,100));
            test_data1.p = {(1:10)',(2:2:20)',(1:5)',(5:5:55)'};
            
            ser = sqw_serializer();
            [struc_pos,pos] = ser.calculate_positions(test_format,test_data1);
            assertEqual(pos-1,55648);
            
            bytes = ser.serialize(test_data1,test_format);
            assertEqual(numel(bytes),pos-1);
            
            [test_pos,pos1] =  ser.calculate_positions(test_format,bytes);
            assertEqual(pos,pos1);
            assertEqual(struc_pos,test_pos);
            
            [recov,pos] = ser.deserialize_bytes(bytes,test_format);
            assertEqual(pos-1,numel(bytes));
            
            assertTrue(isa(recov.pax,'int32'));
            assertTrue(isa(recov.dax,'int32'));
            recov.pax = double(recov.pax);
            recov.dax = double(recov.dax);
            assertTrue(isa(recov.s,'single'));
            assertTrue(isa(recov.e,'single'));
            assertTrue(isa(recov.npix,'uint64'));
            recov.s = double(recov.s);
            recov.e = double(recov.e);
            recov.npix = double(recov.npix);
            assertTrue(isa(recov.pix,'single'));
            recov.pix = double(recov.pix);
            
            fn = fieldnames(recov);
            for i=1:numel(fn)
                assertEqual(class(recov.(fn{i})),class(test_data1.(fn{i})),...
                    ['incorrect field types: ',fn{i}]);
            end
            
            
            assertEqual(test_data1,recov);
            %-------------------------------------------------------------
            test_data2 = struct(...
                'iax',[1,2,3,4],'iint',[1,2,1,5;10,20,5,55],...
                'pax',[],...
                'p',[],...
                'dax',[],...
                's',4,'e',5,'npix',100,...
                'pix',ones(9,100));
            test_data2.p ={};
            
            ser = sqw_serializer();
            [struc_pos,pos] = ser.calculate_positions(test_format,test_data2);
            assertEqual(pos-1,3680);
            
            bytes = ser.serialize(test_data2,test_format);
            assertEqual(numel(bytes),pos-1);
            
            [test_pos,pos1] =  ser.calculate_positions(test_format,bytes);
            assertEqual(pos,pos1);
            assertEqual(struc_pos,test_pos);
            
            [recov,pos] = ser.deserialize_bytes(bytes,test_format);
            assertEqual(pos-1,numel(bytes));
            
            assertTrue(isa(recov.iax,'double'));
            assertTrue(isa(recov.iint,'single'));
            recov.iax = double(recov.iax);
            recov.iint = double(recov.iint);
            assertTrue(isa(recov.s,'single'));
            assertTrue(isa(recov.e,'single'));
            assertTrue(isa(recov.npix,'uint64'));
            recov.s = double(recov.s);
            recov.e = double(recov.e);
            recov.npix = double(recov.npix);
            assertTrue(isa(recov.pix,'single'));
            recov.pix = double(recov.pix);
            
            fn = fieldnames(recov);
            for i=1:numel(fn)
                assertEqual(class(recov.(fn{i})),class(test_data2.(fn{i})),...
                    ['incorrect field types: ',fn{i}]);
            end
            
            assertEqual(test_data2,recov);
            
            %-------------------------------------------------------------
            test_data3 = struct(...
                'iax',[1,3],'iint',[1,1;10,5],...
                'pax',[2,4],...
                'p',[],...
                'dax',[4,2],...
                's',4*ones(9,10),'e',3*ones(9,10),'npix',10*ones(9,10),...
                'pix',ones(9,100));
            test_data3.p = {(2:2:20)',(5:5:55)'};
            
            ser = sqw_serializer();
            [struc_pos,pos] = ser.calculate_positions(test_format,test_data3);
            assertEqual(pos-1,5188);
            
            bytes = ser.serialize(test_data3,test_format);
            assertEqual(numel(bytes),pos-1);
            
            [test_pos,pos1] =  ser.calculate_positions(test_format,bytes);
            assertEqual(pos,pos1);
            assertEqual(struc_pos,test_pos);
            
            [recov,pos] = ser.deserialize_bytes(bytes,test_format);
            assertEqual(pos-1,numel(bytes));
            
            assertTrue(isa(recov.iax,'double'));
            assertTrue(isa(recov.iint,'single'));
            assertTrue(isa(recov.pax,'int32'));
            assertTrue(isa(recov.dax,'int32'));
            recov.pax = double(recov.pax);
            recov.dax = double(recov.dax);
            recov.iax = double(recov.iax);
            recov.iint = double(recov.iint);
            assertTrue(isa(recov.s,'single'));
            assertTrue(isa(recov.e,'single'));
            assertTrue(isa(recov.npix,'uint64'));
            recov.s = double(recov.s);
            recov.e = double(recov.e);
            recov.npix = double(recov.npix);
            assertTrue(isa(recov.pix,'single'));
            recov.pix = double(recov.pix);
            
            fn = fieldnames(recov);
            for i=1:numel(fn)
                assertEqual(class(recov.(fn{i})),class(test_data3.(fn{i})),...
                    ['incorrect field types: ',fn{i}]);
            end
            
            
            assertEqual(test_data3,recov);
            
            
        end
        function obj = test_serialize_classes_v3(obj)
            test_data = struct('double_v',9,...
                'int_a1',int32([1,2,3]),...
                'int_a1p',uint32([1,2,3])',...
                'double_a2',[1,2,3;4,5,6],...
                'int32_v',int32(10),'uint64_t',100,...
                'double_a1',[1,2,3],...
                'carray_single',ones(1,10)*10);
            test_format = struct('double_v',field_simple_class_hv3(),...
                'int_a1',field_simple_class_hv3(),...
                'int_a1p',field_simple_class_hv3(),...
                'double_a2',field_simple_class_hv3(),...
                'int32_v',field_simple_class_hv3(),'uint64_t',field_simple_class_hv3(),...
                'double_a1',field_simple_class_hv3(),...
                'carray_single',field_simple_class_hv3());
            
            ser = sqw_serializer();
            [struc_pos,pos] = ser.calculate_positions(test_format,test_data);
            assertEqual(pos-1,498);
            
            bytes = ser.serialize(test_data,test_format);
            assertEqual(numel(bytes),pos-1);
            
            [test_pos,pos1] =  ser.calculate_positions(test_format,bytes);
            assertEqual(pos,pos1);
            assertEqual(struc_pos,test_pos);
            
            [recov,pos] = ser.deserialize_bytes(bytes,test_format);
            assertEqual(pos-1,numel(bytes));
            %
            fn = fieldnames(recov);
            for i=1:numel(fn)
                assertEqual(class(recov.(fn{i})),class(test_data.(fn{i})),...
                    ['incorrect field types: ',fn{i}]);
                assertEqual(recov.(fn{i}),test_data.(fn{i}),...
                    ['unequal values for field: ',fn{i}])
            end
            
            
        end
        function obj = test_serialize_general_v3(obj)
            test_data = struct('double_v',9,...
                'int_a1',int32([1,2,3]),...
                'int_a1p',uint32([1,2,3])',...
                'double_a2',[1,2,3;4,5,6],...
                'int32_v',int32(10),'uint64_t',100,...
                'double_a1',[1,2,3],...
                'carray_single',ones(1,10)*10);
            
            test_format = field_generic_class_hv3();
            
            ser = sqw_serializer();
            [struc_pos,pos] = ser.calculate_positions(test_format,test_data);
            assertEqual(pos-1,675);
            
            bytes = ser.serialize(test_data,test_format);
            assertEqual(numel(bytes),pos-1);
            
            [test_pos,pos1] =  ser.calculate_positions(test_format,bytes);
            assertEqual(pos,pos1);
            assertEqual(struc_pos,test_pos);
            
            [recov,pos] = ser.deserialize_bytes(bytes,test_format);
            assertEqual(pos-1,numel(bytes));
            
            %
            fn = fieldnames(recov);
            for i=1:numel(fn)
                assertEqual(class(recov.(fn{i})),class(test_data.(fn{i})),...
                    ['incorrect field types: ',fn{i}]);
                assertEqual(recov.(fn{i}),test_data.(fn{i}),...
                    ['unequal values for field: ',fn{i}])
            end
        end
        %
        function obj = test_serialize_general_v3_with_file(obj)
            test_data = struct('double_v',9,...
                'int_a1',int32([1,2,3]),...
                'int_a1p',uint32([1,2,3])',...
                'double_a2',[1,2,3;4,5,6],...
                'int32_v',int32(10),'uint64_t',100,...
                'double_a1',[1,2,3],...
                'carray_single',ones(1,10)*10);
            
            test_format = field_generic_class_hv3();
            
            ser = sqw_serializer();
            [struc_pos,pos] = ser.calculate_positions(test_format,test_data);
            assertEqual(pos-1,675);
            
            bytes = ser.serialize(test_data,test_format);
            assertEqual(numel(bytes),pos-1);
            
            tf = fullfile(tempdir,'serialize_test_serialize_general_v3_with_file.bin');
            fid = fopen(tf,'w+');
            assertTrue(fid>0);
            clob = onCleanup(@()obj.clean_file(fid));
            sz = fwrite(fid,bytes,'uint8');
            assertEqual(sz,pos-1);
            
            [test_pos,pos1] =  ser.calculate_positions(test_format,fid);
            % file operations calculate positions from 0 while array
            % operations -- from 1. Bad Matlab inconsistency
            test_pos.start_pos_ = test_pos.start_pos_+1;
            assertEqual(pos-1,pos1);
            assertEqual(struc_pos,test_pos);
            
            fseek(fid,0,'bof');
            sz = pos1;
            r_bytes = fread(fid,sz,'*uint8');
            assertEqual(bytes,r_bytes');
            
            [recov,pos] = ser.deserialize_bytes(r_bytes,test_format);
            assertEqual(pos-1,numel(bytes));
            
            %
            fn = fieldnames(recov);
            for i=1:numel(fn)
                assertEqual(class(recov.(fn{i})),class(test_data.(fn{i})),...
                    ['incorrect field types: ',fn{i}]);
                assertEqual(recov.(fn{i}),test_data.(fn{i}),...
                    ['unequal values for field: ',fn{i}])
            end
            
            
        end
        %
        function obj = test_serialize_instr(obj)
            test_data = struct('double_v',9,...
                'int_a1',int32([1,2,3]),...
                'int_a1p',uint32([1,2,3])',...
                'double_a2',[1,2,3;4,5,6],...
                'int32_v',int32(10),'uint64_t',100,...
                'double_a1',[1,2,3],...
                'carray_single',ones(1,10)*10,...
                'some_string','bla_bla','empty_str','');
            
            test_format = field_instr_or_sample_v3('instrument');
            td.instrument = test_data;
            
            ser = sqw_serializer();
            [struc_pos,pos] = ser.calculate_positions(test_format,td);
            assertEqual(pos-1,1016);
            
            bytes = ser.serialize(td,test_format);
            assertEqual(numel(bytes),pos-1);
            
            [test_pos,pos1] =  ser.calculate_positions(test_format,bytes);
            assertEqual(pos,pos1);
            assertEqual(struc_pos,test_pos);
            
            [recov,pos] = ser.deserialize_bytes(bytes,test_format);
            assertEqual(pos-1,numel(bytes));
            
            assertTrue(isfield(recov,'block_descr'));
            recov = rmfield(recov,'block_descr');
            
            assertEqual(recov,td)
            recov = recov.instrument;
            %
            fn = fieldnames(recov);
            for i=1:numel(fn)
                assertEqual(class(recov.(fn{i})),class(test_data.(fn{i})),...
                    ['incorrect field types: ',fn{i}]);
                assertEqual(recov.(fn{i}),test_data.(fn{i}),...
                    ['unequal values for field: ',fn{i}])
            end
            
            
        end
        %
        function obj = test_serialize_2instr(obj)
            test_data1 = struct('double_v',9,...
                'int_a1',int32([1,2,3]),...
                'int_a1p',uint32([1,2,3])',...
                'double_a2',[1,2,3;4,5,6],...
                'int32_v',int32(10),'uint64_t',100,...
                'double_a1',[1,2,3],...
                'carray_single',ones(1,10)*10,...
                'some_string','bla_bla','empty_str','');
            test_data2 = test_data1;
            test_data2.int_a1=int32([4,5,6]);
            
            test_format = field_instr_or_sample_v3('instrument');
            td = struct('instrument',{test_data1,test_data2});
            
            ser = sqw_serializer();
            [struc_pos,pos] = ser.calculate_positions(test_format,td);
            assertEqual(pos-1,1870);
            
            bytes = ser.serialize(td,test_format);
            assertEqual(numel(bytes),pos-1);
            
            [test_pos,pos1] =  ser.calculate_positions(test_format,bytes);
            assertEqual(pos,pos1);
            assertEqual(struc_pos,test_pos);
            
            [recov,pos] = ser.deserialize_bytes(bytes,test_format);
            assertEqual(pos-1,numel(bytes));
            
            assertTrue(isfield(recov,'block_descr'));
            recov = rmfield(recov,'block_descr');
            
            assertEqual(recov,td)
            inst1 = recov(1).instrument;
            inst2 = recov(2).instrument;
            %
            fn = fieldnames(inst1);
            for i=1:numel(fn)
                assertEqual(class(inst1.(fn{i})),class(test_data1.(fn{i})),...
                    ['incorrect field types: ',fn{i}]);
                assertEqual(inst1.(fn{i}),test_data1.(fn{i}),...
                    ['unequal values for field: ',fn{i}])
                assertEqual(class(inst2.(fn{i})),class(test_data2.(fn{i})),...
                    ['incorrect field types: ',fn{i}]);
                assertEqual(inst2.(fn{i}),test_data2.(fn{i}),...
                    ['unequal values for field: ',fn{i}])
                
            end
            
        end
        
    end
end
