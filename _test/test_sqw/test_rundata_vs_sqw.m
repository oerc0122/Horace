classdef test_rundata_vs_sqw < TestCase
    % Series of tests to check work of mex files against Matlab files
    
    properties
        out_dir=tempdir();
        
        en=-80:8:760;
        par_file='map_4to1_dec09.par';
        sqw_file_single='test_build_rundata_from_sqw.sqw';
        efix=800;
        emode=1;
        alatt=[2.87,2.87,2.87];
        angdeg=[90,90,90];
        u=[1,0,0];
        v=[0,1,0];
        omega=1;dpsi=2;gl=3;gs=4;
        
        psi=4;
        
        sqw_obj=[];
        clob_ = [];
    end
    
    methods
        function this=test_rundata_vs_sqw(varargin)
            if nargin==0
                name = 'test_rundata_vs_sqw';
            else
                name = varargin{1};
            end
            this = this@TestCase(name);
            root_dir = fileparts(which('horace_init.m'));
            data_dir = fullfile(root_dir,'_test','common_data');
            this.sqw_file_single = fullfile(this.out_dir,this.sqw_file_single);
            this.par_file = fullfile(data_dir,this.par_file);
            
            
        end
        
        function this = build_test_sqw(this)
            ws = fake_sqw(this.en, this.par_file,'', this.efix,...
                this.emode, this.alatt, this.angdeg,...
                this.u, this.v, this.psi, this.omega, this.dpsi, this.gl, this.gs,...
                [10,5,5,5]);
            this.sqw_obj = ws{1};
        end
        
        function this=test_build_rundata_get_sqw(this)
            this = build_test_sqw(this);
            
            rd = rundatah(this.sqw_obj);
            
            assertEqual(rd.emode, this.emode);
            assertEqual(rd.efix, this.efix);
            
            lattice = rd.lattice;
            assertElementsAlmostEqual(lattice.alatt,this.alatt,'absolute',2e-7);
            assertElementsAlmostEqual(lattice.angdeg,this.angdeg);
            assertEqual(lattice.u,this.u);
            assertEqual(lattice.v,this.v);
            assertElementsAlmostEqual(lattice.psi,this.psi,'absolute',2e-7);
            assertElementsAlmostEqual(lattice.omega,this.omega,'absolute',2e-7);
            assertElementsAlmostEqual(lattice.dpsi,this.dpsi,'absolute',2e-7);
            assertElementsAlmostEqual(lattice.gl,this.gl,'absolute',2e-7);
            assertElementsAlmostEqual(lattice.gs,this.gs,'absolute',2e-7);
            
            det = get_par(this.par_file);
            det_par = rd.det_par;
            %
            assertElementsAlmostEqual(det_par.azim,det.azim,'absolute',7.7e-6);
            assertElementsAlmostEqual(det_par.group,det.group,'absolute',1.e-12);
            assertElementsAlmostEqual(det_par.height,det.height,'absolute',1.e-9);
            assertElementsAlmostEqual(det_par.phi,det.phi,'absolute',2.e-6);
            assertElementsAlmostEqual(det_par.width,det.width,'absolute',2.e-6);
            assertElementsAlmostEqual(det_par.x2,det.x2,'absolute',2.e-6);
            assertEqual(det_par.filename,det.filename)
            %assertEqual(det_par.filepath,det.filepath)
            %assertEqual(det_par,det);
            grid_size = size(this.sqw_obj.data.s);
            urange    = this.sqw_obj.data.urange;
            % somewhere on the way, pixels become single precision, so...
            urange(1,:) = urange(1,:)*(1+2.e-7);
            urange(2,:) = urange(2,:)*(1+2.e-7);
            
            sqw_rev = rd.calc_sqw(grid_size,urange);
            
            proj = struct('u',lattice.u,'v',lattice.v);
            [ok,mess]=is_cut_equal(this.sqw_obj,sqw_rev,proj,0.04*(urange(2,1)-urange(1,1)),0.1*(urange(2,2)-urange(1,2)),[-Inf,Inf],[-Inf,Inf]);
            assertTrue(ok,['Combining cuts from each individual sqw file and the cut from the combined sqw file not the same ',mess]);
            %assertEqual(this.sqw_obj,sqw_rev);
            
            % calculate bounding object surrounding existing data object
            bob = rd.build_bounding_obj();
            bos = bob.calc_sqw(grid_size,urange);
            assertElementsAlmostEqual(bos.data.urange,urange,'relative',1.e-6);
            
            pix_range =[min(bos.data.pix(1:4,:),[],2)'; max(bos.data.pix(1:4,:),[],2)'];
            assertElementsAlmostEqual(bos.data.urange,pix_range);
        end
        %
        function test_convert_to_lab_frame(this)
            
            alat = [1,2,3];
            angde= [90,90,90];
            psil  =0;
            lat = oriented_lattice(alat,angde,psil);
            
            rd = rundatah();
            rd.lattice = lat;
            rd.efix = 10;
            rd.emode= 1;
            rd.S=ones(3,3);
            rd.ERR=zeros(3,3);
            rd.en=-1:2;
            
            det.filename='some_file';
            det.filepath='';
            det.group = (1:3)';
            det.x2  =ones(3,1);
            det.phi  =[0,1,2];    % radians
            det.azim= [-1,0,1];   % radians
            det.width =ones(3,1)*0.1; % not used
            det.height=ones(3,1)*0.1; % not used
            
            rd.det_par = det;
            
            [urange,u_to_rlu,ucoords] = rd.convert_to_lab_frame();
            mii = min(ucoords,[],2);
            mai = max(ucoords,[],2);
            
            urange_r = [mii(1:4),mai(1:4)]';
            assertElementsAlmostEqual(urange,urange_r);
            
            u2rlu2 = diag(alat/(2*pi),0);
            assertElementsAlmostEqual(u_to_rlu,u2rlu2);
            
            uc_sample =[-0.0543 0.0557 0.1715 -0.0539  0.0560  0.1718 -0.0529  0.0570  0.1728; ...
                0      0      0      -0.0393 -0.0374 -0.0354 -0.0786 -0.0748  -0.0707; ...
                0      0      0       0       0       0      -0.0014 -0.0013  -0.0012; ...
                -0.5000 0.5000 1.5000 -0.5000  0.5000  1.5000 -0.5000  0.5000   1.5000]';
            assertElementsAlmostEqual(uc_sample,ucoords(1:4,:)','absolute',2E-4);
            
        end
        
        
    end
end
