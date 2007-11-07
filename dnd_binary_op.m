function w = dnd_binary_op (w1, w2, binary_op, class_type, class_ndim)
% Implement binary arithmetic operations for dataset_nd
%
% >> output = dnd_binary_op(w1,w2,binary_op, class_type, class_ndim)
%
% inputs:
%       w1  -           first input
%       w2  -           second input
%       binary_op -     handle to operation
%       class_type -    Class being operated on
%       class_ndim -    Number of dimensions in class
%
% output:
%       output -        result of operation.
%
%   If w1, w2 are datasets of the same size:
%       the operation is performed element-by-element
%   if one of w1 or w2 is a double:
%        - if a scalar, apply to each element of the dataset
%        - if an array of the same size as the signal array, apply element by element
%
%   w1, w2 can be arrays:
%       - if same length, then added element-by-element
%       - if one is an array of length one, or a scalar, then take
%         difference with respect to every element of the other.
%
% On d1d and d2d datasets, operations are the same as for IXTdataset_2d and
% IXTdataset_1d in libisis. See the Libisis user documentation for advanced
% use

% Template of a binary operator that can take array-valued arguments

if strcmp(class_type,'d1d') || strcmp(class_type,'d2d') || strcmp(class_type,'d0d')
  
    libisis_w1 = convert_to_libisis(w1);
    libisis_w2 = convert_to_libisis(w2);
    libisis_w3 = binary_op(libisis_w1, libisis_w2);
  
    if isa(w1,class_type)
        w = combine_libisis(w1, libisis_w3);
    elseif isa(w2,class_type)
        w = combine_libisis(w2, libisis_w3);
    else
        error('Class of object(s) does not match given class type')
    end
    
else
    
    if isa(w1,class_type)
        dim1=size(w1);
        len1=numel(w1);
    elseif isa(w1,'double')
        if isscalar(w1)||length(size(w1))==class_ndim
            len1=1;
        elseif length(size(w1))>class_ndim
            dims=size(w1);
            inner_dims=dims(1:class_ndims);     % inner dimensions
            outer_dims=dims(class_ndims+1:end); % outer dimensions
            if length(outer_dims)==1
                dim1=[outer_dims,1];
            else
                dim1=outer_dims;
            end
            len1=prod(outer_dims);
            w1=reshape(w1,[inner_dims,len1]);
        else
            error('Invalid numeric input to first argument')
        end
    end

    if isa(w2,class_type)
        dim2=size(w2);
        len2=numel(w2);
    elseif isa(w2,'double')
        if isscalar(w2)||length(size(w2))==class_ndim
            len2=1;
        elseif length(size(w2))>class_ndim
            dims=size(w2);
            inner_dims=dims(1:class_ndims);     % inner dimensions
            outer_dims=dims(class_ndims+1:end); % outer dimensions
            if length(outer_dims)==1
                dim2=[outer_dims,1];
            else
                dim2=outer_dims;
            end
            len2=prod(outer_dims);
            w2=reshape(w2,[inner_dims,len2]);
        else
            error('Invalid numeric input to first argument')
        end
    end

    if (len1==len2 && len1==1)
        w = binary_op (w1, w2, class_type);
    elseif (len1==len2 && len1>1)
        if isa(w1,class_type); w=w1(1); else w=w2(1); end   % template for output
        w = repmat(w,dim1);
        for i=1:len1
            w(i) = binary_op (w1(i), w2(i), class_type);
        end
    elseif (len1==1 && len2>1)
        if isa(w1,class_type); w=w1(1); else w=w2(1); end   % template for output
        w = repmat(w,1,dim2);   % create empty output array
        for i=1:len2
            w(i) = binary_op (w1, w2(i), class_type);
        end
    elseif (len1>1 && len2==1)
        if isa(w1,class_type); w=w1(1); else w=w2(1); end   % template for output
        w = repmat(w,1,dim1);   % create empty output array
        for i=1:len1
            w(i) = binary_op (w1(i), w2, class_type);
        end
    else
        error ('Check lengths of array(s) of input arguments')
    end

end

