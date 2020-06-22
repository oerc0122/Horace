classdef test_PixelData < TestCase

properties
    raw_pix_data = rand(9, 10);
    pixel_data_obj;
end

methods (Access = private)

    function pix_data = get_random_pix_data_(~, rows)
        data = rand(9, rows);
        pix_data = PixelData(data);
    end

end

methods

    function obj = test_PixelData(~)
        obj = obj@TestCase('test_PixelData');

        obj.pixel_data_obj = PixelData(obj.raw_pix_data);
    end

    function test_default_construction_sets_empty_pixel_data(~)
        pix_data = PixelData();
        num_cols = 9;
        assertEqual(pix_data.data, zeros(num_cols, 0));
    end

    function test_PIXELDATA_raised_on_construction_with_data_with_lt_9_cols(~)
        f = @() PixelData(ones(3, 3));
        assertExceptionThrown(f, 'PIXELDATA:data')
    end

    function test_PIXELDATA_raised_on_construction_with_data_with_gt_9_cols(~)
        f = @() PixelData(ones(10, 3));
        assertExceptionThrown(f, 'PIXELDATA:data')
    end

    function test_coordinates_returns_empty_array_if_pixel_data_empty(~)
        pix_data = PixelData();
        assertTrue(isempty(pix_data.coordinates));
    end

    function test_pixel_data_is_set_to_input_data_on_construction(obj)
        assertEqual(obj.pixel_data_obj.data, obj.raw_pix_data);
    end

    function test_u1_returns_first_dim_in_coordinates_array(obj)
        u1 = obj.pixel_data_obj.u1;
        assertEqual(u1, obj.pixel_data_obj.coordinates(1, :));
    end

    function test_u1_sets_the_first_dim_in_coordinates_array(obj)
        pix_data_obj = obj.get_random_pix_data_(10);
        pix_data_obj.u1 = 1;
        assertEqual(pix_data_obj.coordinates(1, :), ones(1, 10));
    end

    function test_u2_returns_second_dim_in_coordinates_array(obj)
        u2 = obj.pixel_data_obj.u2;
        assertEqual(u2, obj.pixel_data_obj.coordinates(2, :));
    end

    function test_u2_sets_the_second_dim_in_coordinates_array(obj)
        pix_data_obj = obj.get_random_pix_data_(10);
        pix_data_obj.u2 = 1;
        assertEqual(pix_data_obj.coordinates(2, :), ones(1, 10));
    end

    function test_u3_returns_third_dim_in_coordinates_array(obj)
        u3 = obj.pixel_data_obj.u3;
        assertEqual(u3, obj.pixel_data_obj.coordinates(3, :));
    end

    function test_u3_sets_the_third_dim_in_coordinates_array(obj)
        pix_data_obj = obj.get_random_pix_data_(10);
        pix_data_obj.u3 = 1;
        assertEqual(pix_data_obj.coordinates(3, :), ones(1, 10));
    end

    function test_dE_returns_fourth_dim_in_coordinates_array(obj)
        dE = obj.pixel_data_obj.dE;
        assertEqual(dE, obj.pixel_data_obj.coordinates(4, :));
    end

    function test_dE_sets_the_fourth_dim_in_coordinates_array(obj)
        pix_data_obj = obj.get_random_pix_data_(10);
        pix_data_obj.dE = 1;
        assertEqual(pix_data_obj.coordinates(4, :), ones(1, 10));
    end

    function test_q_coordinates_returns_first_3_dims_of_coordinates(obj)
        q_coords = obj.pixel_data_obj.q_coordinates;
        assertEqual(q_coords, obj.pixel_data_obj.q_coordinates);
    end

    function test_setting_q_coordinates_updates_u1_u2_and_u3(obj)
        pix_data_obj = obj.get_random_pix_data_(10);
        pix_data_obj.q_coordinates = ones(3, 10);
        assertEqual(pix_data_obj.u1, ones(1, 10));
        assertEqual(pix_data_obj.u2, ones(1, 10));
        assertEqual(pix_data_obj.u3, ones(1, 10));
    end

    function test_get_coordinates_returns_coordinate_data(obj)
        coord_data = obj.raw_pix_data(1:4, :);
        assertEqual(obj.pixel_data_obj.coordinates, coord_data);
    end

    function test_run_idx_returns_run_index_data(obj)
        run_indices = obj.raw_pix_data(5, :);
        assertEqual(obj.pixel_data_obj.run_idx, run_indices)
    end

    function test_detector_idx_returns_detector_index_data(obj)
        detector_indices = obj.raw_pix_data(6, :);
        assertEqual(obj.pixel_data_obj.detector_idx, detector_indices)
    end

    function test_energy_idx_returns_energy_bin_number_data(obj)
        energy_bin_nums = obj.raw_pix_data(7, :);
        assertEqual(obj.pixel_data_obj.energy_idx, energy_bin_nums)
    end

    function test_signal_returns_signal_array(obj)
        signal_array = obj.raw_pix_data(8, :);
        assertEqual(obj.pixel_data_obj.signal, signal_array)
    end

    function test_variance_returns_variance_array(obj)
        variance_array = obj.raw_pix_data(9, :);
        assertEqual(obj.pixel_data_obj.variance, variance_array)
    end

    function test_PIXELDATA_error_raised_if_setting_data_with_lt_9_cols(~)
        f = @(x) PixelData(zeros(x, 10));
        for i = [-10, -5, 0, 5]
            assertExceptionThrown(@() f(i), 'PIXELDATA:data');
        end
    end

    function test_num_pixels_returns_the_number_of_rows_in_the_data_block(obj)
        assertEqual(obj.pixel_data_obj.num_pixels, 10);
    end

    function test_coordinate_data_is_settable(obj)
        num_rows = 10;
        pix_data_obj = obj.get_random_pix_data_(num_rows);

        new_coord_data = ones(4, num_rows);
        pix_data_obj.coordinates = new_coord_data;
        assertEqual(pix_data_obj.coordinates, new_coord_data);
        assertEqual(pix_data_obj.data(1:4, :), new_coord_data);
    end

    function test_error_raised_if_setting_coordinates_with_wrong_num_rows(obj)
        num_rows = 10;
        pix_data_obj = obj.get_random_pix_data_(num_rows);
        new_coord_data = ones(4, num_rows - 1);

        function set_coordinates(data)
            pix_data_obj.coordinates = data;
        end

        f = @() (set_coordinates(new_coord_data));
        assertExceptionThrown(f, 'MATLAB:subsassigndimmismatch')
    end

    function test_error_raised_if_setting_coordinates_with_wrong_num_cols(obj)
        num_rows = 10;
        pix_data_obj = obj.get_random_pix_data_(num_rows);

        function set_coordinates(data)
            pix_data_obj.coordinates = data;
        end

        new_coord_data = ones(3, num_rows);
        f = @() set_coordinates(new_coord_data);
        assertExceptionThrown(f, 'MATLAB:subsassigndimmismatch')
    end

    function test_size_of_PixelData_object_returns_underlying_data_size(obj)
        % This may no longer be true if we start adding additional columns that
        % are not part of the underlying pixel block
        assertEqual(size(obj.pixel_data_obj), [9, 10]);
        assertEqual(size(obj.pixel_data_obj, 1), 9);
        assertEqual(size(obj.pixel_data_obj, 2), 10);
    end

    function test_PixelData_object_with_underlying_data_is_not_empty(obj)
        assertFalse(isempty(obj.pixel_data_obj));
    end

    function test_default_PixelData_object_is_empty(~)
        pix_data_obj = PixelData();
        assertTrue(isempty(pix_data_obj));
    end

    function test_PIXELDATA_error_if_constructed_with_non_numeric_type(~)
        f = @() PixelData('non_numeric');
        assertExceptionThrown(f, 'PIXELDATA:data')
    end

    function test_PIXELDATA_error_if_data_set_with_non_numeric_type(~)
        pix_data_obj = PixelData();

        function set_data(data)
            pix_data_obj.data = data;
        end

        f = @() set_data({1, 'abc'});
        assertExceptionThrown(f, 'PIXELDATA:data')
    end

    function test_numel_returns_the_number_of_elements_in_the_data(obj)
        assertEqual(numel(obj.pixel_data_obj), numel(obj.pixel_data_obj.data));
    end

    function test_can_construct_from_another_PixelData_object(obj)
        pixel_data_obj_copy = PixelData(obj.pixel_data_obj);
        assertEqual(pixel_data_obj_copy.data, obj.pixel_data_obj.data);
    end

    function test_get_data_returns_coordinates_for_given_index_range(obj)
        pix_data_obj = obj.get_random_pix_data_(10);
        coords = pix_data_obj.get_data({'coordinates'}, 2:6);
        assertEqual(coords, pix_data_obj.coordinates(:, 2:6));
    end

    function test_get_data_returns_multiple_fields_for_given_index_range(obj)
        pix_data_obj = obj.get_random_pix_data_(10);
        coord_sig = pix_data_obj.get_data({'coordinates', 'signal'}, 4:9);
        expected_coord_sig = [pix_data_obj.coordinates(:, 4:9); ...
                              pix_data_obj.signal(4:9)];
        assertEqual(coord_sig, expected_coord_sig);
    end

    function test_get_data_returns_full_pixel_range_if_no_range_given(obj)
        pix_data_obj = obj.get_random_pix_data_(10);
        coord_sig = pix_data_obj.get_data({'coordinates', 'signal'});
        expected_coord_sig = [pix_data_obj.coordinates; pix_data_obj.signal];
        assertEqual(coord_sig, expected_coord_sig);
    end

    function test_get_data_allows_data_retrieval_for_single_field(obj)
        fields = {'u1', 'u2', 'u3', 'dE', 'coordinates', 'q_coordinates', ...
                  'run_idx', 'detector_idx', 'energy_idx', 'signal', ...
                  'variance'};
        for i = 1:numel(fields)
            field_data = obj.pixel_data_obj.get_data(fields{i});
            assertEqual(field_data, obj.pixel_data_obj.(fields{i}));
        end
    end

    function test_get_data_throws_PIXELDATA_on_non_valid_field_name(obj)
        f = @() obj.pixel_data_obj.get_data('not_a_field');
        assertExceptionThrown(f, 'PIXELDATA:get_data');
    end

    function test_get_data_orders_columns_corresponding_to_input_cell_array(obj)
        pix_data_obj = obj.get_random_pix_data_(10);
        data_subset = pix_data_obj.get_data({'detector_idx', 'signal', 'run_idx'});
        assertEqual(data_subset(1, :), pix_data_obj.detector_idx);
        assertEqual(data_subset(2, :), pix_data_obj.signal);
        assertEqual(data_subset(3, :), pix_data_obj.run_idx);
    end

    function test_cat_combines_given_PixelData_objects(obj)
        pix_data_obj1 = obj.get_random_pix_data_(10);
        pix_data_obj2 = obj.get_random_pix_data_(5);

        combined_pix = PixelData.cat(pix_data_obj1, pix_data_obj2);

        assertEqual(combined_pix.num_pixels, 15);
        assertEqual(combined_pix.data, ...
                    horzcat(pix_data_obj1.data, pix_data_obj2.data));
    end

    function test_get_pixels_returns_PixelData_obj_with_given_pix_indices(~)
        data = rand(9, 10);
        pix = PixelData(data);
        sub_pix = pix.get_pixels([3, 5, 7]);
        assertTrue(isa(pix, 'PixelData'));
        assertEqual(sub_pix.data, data(:, [3, 5, 7]));
    end

    function test_get_pixels_returns_PixelData_with_equal_num_cols(obj)
        pix = obj.get_random_pix_data_(10);
        orignal_size = size(pix.data, 1);
        sub_pix = pix.get_pixels(1:5);
        assertEqual(size(sub_pix.data, 1), orignal_size);
    end

    function test_load_obj_returns_equivalent_object(~)
        pix = PixelData.loadobj(PixelData(ones(9, 10)));
        assertEqual(pix.data, ones(9, 10));
    end

    function test_construction_with_int_fills_underlying_data_with_zeros(~)
        npix = 20;
        pix = PixelData(npix);
        assertEqual(pix.num_pixels, npix);
        assertEqual(pix.data, zeros(9, npix));
        assertEqual(pix.variance, zeros(1, npix));
    end

    function test_construction_with_float_raises_PIXELDATA_error(~)
        f = @() PixelData(1.2);
        assertExceptionThrown(f, 'PIXELDATA:data');
    end

    function test_construction_with_char_raises_PIXELDATA_error(~)
        f = @() PixelData('1');
        assertExceptionThrown(f, 'PIXELDATA:data');
    end

end

end