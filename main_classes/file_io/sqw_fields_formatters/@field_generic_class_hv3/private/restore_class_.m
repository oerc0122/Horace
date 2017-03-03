function [var,sz] = restore_class_(obj,bytes,names,type,shape,pos,sz)
% Convert sequence of bytes into  array of custom classes
%
%
var = make_object_(type,shape);
if ~isempty(var)     % not recognised as an object
    tmpvar=cell2struct(cell(numel(names),1),names,1);
    for i=1:prod(shape)
        for j=1:numel(names)
            [tmpvar.(names{j}),szi]=obj.field_from_bytes(bytes,pos);
            sz = sz + szi;
            pos = pos + szi;
        end
        var(i)=make_object_(type,tmpvar);
    end
else
    disp(['WARNING: unable to create object of type ''',type,'''. Creating structure instead.'])
    var=repmat(cell2struct(cell(numel(names),1),names,1),shape);
    for i=1:prod(shape)
        for j=1:numel(names)
            [var(i).(names{j}),szi]=obj.field_from_bytes(bytes,pos);
            sz = sz + szi;
            pos = pos + szi;            
        end
    end
end

function this=make_object_(classname,arg)
% Create an instance of the object with provided name.
%
%   >> this=make_object(classname)          % default object (scalar)
%   >> this=make_object(classname,sz)       % array of default objects with given size
%   >> this=make_object(classname,struct)   % single instance filled from a structure
%
% Assumes
%   - the constructor returns a valid object if given no input arguments,
%   - the constructor can create a single instance from a structure
fh=str2func(classname);
if nargin==2 && isstruct(arg)
    this=fh(arg);
else
    try
        this=fh();
    catch
        this=[];
        return
    end
    if nargin==2
        try
            this=repmat(this,arg');
        catch
            % Generic way of making an array of objects - I think
            % (works with libisis objects, for which repmat doesn't work)
            this(arg)=this;
        end
    end
end



