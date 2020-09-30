function pix_out = binary_op_sigvar_(obj, dnd_obj, binary_op, flip, npix)
%% BINARY_OP_SIGVAR_ perform a binary operation between this and a sigvar or
% sigvar-like object (e.g. dnd)
%
npix_cum_sum = validate_inputs(obj, dnd_obj, npix);

if nargout == 0
    pix_out = obj;
else
    pix_out = copy(obj);
end

pix_out.move_to_first_page();

end_idx = 1;
leftover_end = 0;
pg_size = pix_out.page_size;
while true

    start_idx = (end_idx - 1) + find(npix_cum_sum(end_idx:end) > 0, 1);
    leftover_begin = npix_cum_sum(start_idx);
    npix_cum_sum = npix_cum_sum - pg_size;

    end_idx = (start_idx - 1) + find(npix_cum_sum(start_idx:end) > 0, 1);
    if isempty(end_idx)
        end_idx = numel(npix);
    end

    if start_idx == end_idx
        npix_chunk = min(pix_out.page_size, npix(start_idx) - leftover_end);
    else
        npix_chunk = [leftover_begin, ...
                      reshape(npix(start_idx + 1:end_idx - 1), 1, []), ...
                      0];
        pix_in_chunk = sum(npix_chunk);
        leftover_end = pix_out.page_size - pix_in_chunk;
        npix_chunk(end) = leftover_end;
    end

    sigvar_pix = sigvar(pix_out.signal, pix_out.variance);
    if ~isequal(size(npix), [1, 1])
        sigvar_dnd = sigvar(...
            replicate_array(dnd_obj.s(start_idx:end_idx), npix_chunk(:))', ...
            replicate_array(dnd_obj.e(start_idx:end_idx), npix_chunk(:))' ...
        );
    end

    [pix_out.signal, pix_out.variance] = ...
            sigvar_binary_op_(sigvar_pix, sigvar_dnd, binary_op, flip);

    if pix_out.has_more()
        pix_out.advance();
    else
        break;
    end
end

end % function

% -----------------------------------------------------------------------------
function npix_cum_sum = validate_inputs(pix, dnd_obj, npix)
    dnd_size = sigvar_size(dnd_obj);
    if ~isequal(dnd_size, [1, 1]) && ~isequal(dnd_size, size(npix))
        error('PIXELDATA:do_binary_op', ...
            ['dnd operand must have size [1,1] or size equal to the inputted ' ...
            'npix array.\nFound dnd size %s, and npix size %s'], ...
            iarray_to_matstr(dnd_size), iarray_to_matstr(size(npix)));
    end

    npix_cum_sum = cumsum(npix(:));
    if npix_cum_sum(end) ~= pix.num_pixels
        error('PIXELDATA:binary_op_sigvar_', ...
            ['Cannot perform binary operation. Sum of ''npix'' must be ' ...
            'equal to the number of pixels in the PixelData object.\n' ...
            'Found ''%i'' pixels in npix but ''%i'' in PixelData.'], ...
            npix_cum_sum(end), pix.num_pixels);
    end
end
