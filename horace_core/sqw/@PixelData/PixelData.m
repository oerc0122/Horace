classdef PixelData
% PixelData Provides an interface for access to pixel data
%
%   This class provides getters and setters for each data column in an SQW
%   pixel array. You can access the data using the attributes listed below or
%   using Matlab's get(obj, 'attr') and set(obj, 'attr', value) methods.
%
%
% Usage
%   >> pix_data = PixelData(data)
%   >> signal = pix_data.signal;
%
%  or equivalently:
%
%   >> pix_data = PixelData()
%   >> pix_data.data = data;
%   >> signal = get(pix_data, 'signal');
%
%  To retrieve multiple fields of data, e.g. run_idx and energy_idx, for pixels 1 to 10:
%
%   >> pix_data = PixelData(data)
%   >> signal = pix_data.get_data({'run_idx', 'energy_idx'}, 1:10);
%
% Attributes:
%   data           The raw pixel data
%   coordinates    Get/set the coords in projection axes of the pixel data (4 x n array)
%   run_idx        The run index the pixel originated from (1 x n array)
%   detector_idx   The detector group number in the detector listing for the pixels (1 x n array)
%   energy_idx     The energy bin numbers (1 x n array)
%   signals        The signal array (1 x n array)
%   variance       The variance on the signal array (variance i.e. error bar squared) (1 x n array)
%   num_pixels     The number of pixels in the data block

properties (Access=private)
    PIXEL_BLOCK_COLS_ = 9;
    data_ = zeros(9, 0);
    FIELD_INDEX_MAP_ = containers.Map(...
        {'coordinates', 'run_idx', 'detector_idx', 'energy_idx', 'signals', 'variance'}, ...
        {1:4, 5, 6, 7, 8, 9})
end
properties (Dependent)
    % Returns the full raw pixel data block (9 x n array)
    data;

    % Returns the coordinates of the pixels in the projection axes, i.e.: u1,
    % u2, u3 and dE (4 x n array)
    coordinates;

    % The run index the pixel originated from (1 x n array)
    run_idx;

    % The detector group number in the detector listing for the pixels (1 x n array)
    detector_idx;

    % The energy bin numbers (1 x n array)
    energy_idx;

    % The signal array (1 x n array)
    signals;

    % The variance on the signal array (variance i.e. error bar squared) (1 x n array)
    variance;

    % The number of pixels in the data block
    num_pixels;
end

methods (Static)

    function obj = cat(varargin)
        % Concatentate the given PixelData objects' pixels
        data_cell_array = cellfun(@(p) p.data, varargin, 'UniformOutput', false);
        data = cat(2, data_cell_array{:});
        obj = PixelData(data);
    end

end

methods

    function obj = PixelData(data)
        % Construct a PixelData object from the given data. Default
        % construction initialises the underlying data as an empty (9 x 0)
        % array.
        %
        % Arguments:
        %   data    A 9 x n matrix, where each row corresponds to a pixel and
        %           the columns correspond to the following:
        %             col 1: u1
        %             col 2: u2
        %             col 3: u3
        %             col 4: u4
        %             col 5: irun
        %             col 6: detector_idx
        %             col 7: energy_idx
        %             col 8: signals
        %             col 9: variance
        %
        if nargin == 1
            if isa(data, 'PixelData')
                obj.data = data.data;
            else
                obj.data = data;
            end
        end
    end

    function is_empty = isempty(obj)
        % Return true if the PixelData object holds no pixel data
        is_empty = isempty(obj.data);
    end

    function s = size(obj, varargin)
        % Return the size of the PixelData
        %   Axis 1 gives the number of columns, axis 2 gives the number of
        %   pixels

        % For the time being, the number of columns is equal to the number of
        % columns in the underlying pix data block. When we start allowing
        % additional columns to be added, the number of columns of a PixelData
        % object may not equal the number in the main underlying data
        % structure.
        % This overload should always return the number of columns in the
        % underlying structure + the number of additional columns
        s = size(obj.data, varargin{:});
    end

    function nel = numel(obj)
        % Return the number of data points in the pixel data block
        nel = numel(obj.data);
    end

    function data = get_data(obj, fields, pix_indices)
        % Retrive data for a field, or fields, for the given pixel indices. If
        % no pixel indices are given, all pixels are returned.
        %
        % This method provides a convinient way of retrieving multiple fields
        % of data from the pixel block. When retrieving multiple fields, the
        % columns of data will be ordered corresponding to the order the fields
        % appear in the inputted cell array.
        %
        % Arguments:
        %   fields      The name of a field, or a cell array of field names
        %   pix_indices The pixel indices to retrieve, if not given, get full range
        %
        % Usage:
        %   >> sig_and_err = pix.get_data({'signals', 'variance'})
        %        retrives the signals and variance over the whole range of pixels
        %
        %   >> run_det_id_range = pix.get_data({'run_idx', 'detector_idx'}, 4:10);
        %        retrives the run and detector IDs for pixels 4 to 10
        %
        if ~isa(fields, 'cell')
            fields = {fields};
        end
        try
            field_indices = cell2mat(obj.FIELD_INDEX_MAP_.values(fields));
        catch ME
            switch ME.identifier
            case 'MATLAB:Containers:Map:NoKey'
                error('PIXELDATA:get_data', 'Invalid field requested.')
            otherwise
                rethrow(ME)
            end
        end

        if nargin < 3
            % No pixel indices given, return them all
            data = obj.data(field_indices, :);
        else
            data = obj.data(field_indices, pix_indices);
        end
    end

    function pixels = get_pixels(obj, pix_indices)
        % Retrieve the pixels at the given indices.
        %
        % Inputs:
        %   pix_indices     1-D array of pixel indices to retrieve
        %
        % Outputs:
        %   pixels      PixelData object containing a subset of pixels
        %
        pixels = PixelData(obj.data(:, pix_indices));
    end

    % --- Getters / Setters ---
    function pixel_data = get.data(obj)
        pixel_data = obj.data_;
    end

    function obj = set.data(obj, pixel_data)
        if size(pixel_data, 1) ~= obj.PIXEL_BLOCK_COLS_
            msg = ['Cannot set pixel data, invalid dimensions. Axis 1 must '...
                   'have length %i, found ''%i''.'];
            error('PIXELDATA:data', msg, obj.PIXEL_BLOCK_COLS_, ...
                  size(pixel_data, 1));
        elseif ~isnumeric(pixel_data)
            msg = ['Cannot set pixel data, invalid type. Data must have a '...
                   'numeric type, found ''%i'''];
            error('PIXELDATA:data', msg, class(pixel_data));
        end
        obj.data_ = pixel_data;
    end

    function coord_data = get.coordinates(obj)
        coord_data = obj.data(obj.FIELD_INDEX_MAP_('coordinates'), :);
    end

    function obj = set.coordinates(obj, coordinates)
        obj.data(obj.FIELD_INDEX_MAP_('coordinates'), :) = coordinates;
    end

    function run_index = get.run_idx(obj)
        run_index = obj.data(obj.FIELD_INDEX_MAP_('run_idx'), :);
    end

    function obj = set.run_idx(obj, iruns)
        obj.data(obj.FIELD_INDEX_MAP_('run_idx'), :) = iruns;
    end

    function detector_index = get.detector_idx(obj)
       detector_index = obj.data(obj.FIELD_INDEX_MAP_('detector_idx'), :);
    end

    function obj = set.detector_idx(obj, detector_indices)
       obj.data(obj.FIELD_INDEX_MAP_('detector_idx'), :) = detector_indices;
    end

    function detector_index = get.energy_idx(obj)
       detector_index = obj.data(obj.FIELD_INDEX_MAP_('energy_idx'), :);
    end

    function obj = set.energy_idx(obj, energies)
        obj.data(obj.FIELD_INDEX_MAP_('energy_idx'), :) = energies;
     end

    function signals = get.signals(obj)
       signals = obj.data(obj.FIELD_INDEX_MAP_('signals'), :);
    end

    function obj = set.signals(obj, signals)
        obj.data(obj.FIELD_INDEX_MAP_('signals'), :) = signals;
     end

    function variance = get.variance(obj)
       variance = obj.data(obj.FIELD_INDEX_MAP_('variance'), :);
    end

    function obj = set.variance(obj, variance)
        obj.data(obj.FIELD_INDEX_MAP_('variance'), :) = variance;
     end

    function num_pix = get.num_pixels(obj)
        num_pix = size(obj.data, 2);
    end

end

end
