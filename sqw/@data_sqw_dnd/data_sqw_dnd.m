classdef data_sqw_dnd
    % Class defines structure of the data, used by sqw&dnd objects
    %
    % Trivial implementation, wrapping around a structure
    properties
        filename=''   % Name of sqw file that is being read, excluding path
        filepath=''   % Path to sqw file that is being read, including terminating file separator
        title   =''   % Title of sqw data structure
        alatt   =[1,1,1] % Lattice parameters for data field (Ang^-1)
        angdeg  =[90,90,90]% Lattice angles for data field (degrees)
        uoffset=[0;0;0;0]  %   Offset of origin of projection axes in r.l.u. and energy ie. [h; k; l; en] [column vector]
        u_to_rlu=eye(4)    %   Matrix (4x4) of projection axes in hkle representation
        %                   u(:,1) first vector - u(1:3,1) r.l.u., u(4,1) energy etc.
        ulen=[1,1,1]            %Length of projection axes vectors in Ang^-1 or meV [row vector]
        ulabel={'','','','En'}  %Labels of the projection axes [1x4 cell array of character strings]
        iax=zeros(1,0);    %Index of integration axes into the projection axes  [row vector]
        %                  Always in increasing numerical order
        %                  e.g. if data is 2D, data.iax=[1,3] means summation has been performed along u1 and u3 axes
        iint=zeros(2,0);   %Integration range along each of the integration axes. [iint(2,length(iax))]
        %                   e.g. in 2D case above, is the matrix vector [u1_lo, u3_lo; u1_hi, u3_hi]
        pax=zeros(1,0);   %Index of plot axes into the projection axes  [row vector]
        %                Always in increasing numerical order
        %                e.g. if data is 3D, data.pax=[1,2,4] means u1, u2, u4 axes are x,y,z in any plotting
        %                2D, data.pax=[2,4]     "   u2, u4,    axes are x,y   in any plotting
        p=cell(1,0);  %  Cell array containing bin boundaries along the plot axes [column vectors]
        %                i.e. row cell array{data.p{1}, data.p{2} ...} (for as many plot axes as given by length of data.pax)
        dax=zeros(1,0)    %Index into data.pax of the axes for display purposes. For example we may have
        %                  data.pax=[1,3,4] and data.dax=[3,1,2] This means that the first plot axis is data.pax(3)=4,
        %                  the second is data.pax(1)=1, the third is data.pax(2)=3. The reason for data.dax is to allow
        %                  the display axes to be permuted but without the contents of the fields p, s,..pix needing to
        %                  be reordered [row vector]
        s=[]          %Cumulative signal.  [size(data.s)=(length(data.p1)-1, length(data.p2)-1, ...)]
        e=[]          %Cumulative variance [size(data.e)=(length(data.p1)-1, length(data.p2)-1, ...)]
        npix=[]       %No. contributing pixels to each bin of the plot axes.
        %             [size(data.pix)=(length(data.p1)-1, length(data.p2)-1, ...)]
        urange=[]  %True range of the data along each axis [urange(2,4)]
        pix=[]     %Array containing data for each pixel:
        % If npixtot=sum(npix), then pix(9,npixtot) contains:
        % u1      -|
        % u2       |  Coordinates of pixel in the projection axes
        % u3       |
        % u4      -|
        % irun        Run index in the header block from which pixel came
        % idet        Detector group number in the detector listing for the pixel
        % ien         Energy bin number for the pixel in the array in the (irun)th header
        % signal      Signal array
        % err         Error array (variance i.e. error bar squared)
        axis_caption=[] %  Reference to class, which define axis captions
        
        % Original author: T.G.Perring
        %
        % $Revision: 1019 $ ($Date: 2015-07-16 12:20:46 +0100 (Thu, 16 Jul 2015) $)
        %
        %
    end
    
    methods
        function obj = data_sqw_dnd(varargin)
            % constructor
            if nargin>0 && isa(varargin{1},'data_sqw_dnd') % handle shalow copy constructor
                obj =varargin{1};                          % its COW for Matlab anyway
            else
                [obj,mess]=make_sqw_data(obj,varargin{:});
                if ~isempty(mess)
                    error('DATA_SQW_DND:invalid_argument',mess);
                end
            end
        end
        function isit=dnd_type(obj)
            if isempty(obj.pix) || isempty(obj.urange)
                isit = true;
            else
                isit = false;
            end
        end
        function type= data_type(obj)
            % compartibility function
            %   data   Output data structure which must contain the fields listed below
            %          type 'b+'   fields: uoffset,...,s,e,npix
            %          [The following other valid structures are not created by this function
            %          type 'b'    fields: uoffset,...,s,e
            %          type 'a'    uoffset,...,s,e,npix,urange,pix
            %          type 'a-'   uoffset,...,s,e,npix,urange
            if isempty(obj.npix)
                type = 'b';
            else
                type = 'b+';
                if ~isempty(obj.urange)
                    type = 'a-';
                end
                if ~isempty(obj.pix)
                    type = 'a';
                end
            end
        end
        function obj=clear_sqw_data(obj)
            obj.pix=[];
            obj.urange=[];
        end
        function [ok, type, mess]=check_sqw_data(obj, type_in, varargin)
            % old style validator for consistency of imput data.
            %
            % only a and 'b+' types are possible as inputs and outputs
            % varargin may contain 'field_names_only' which in fact
            % disables validation
            %
            [ok, type, mess]=obj.check_sqw_data_(type_in, varargin{:});
        end
    end
end
