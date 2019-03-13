#include "input_parser.h"
#include <vector>
#include <hdf5.h>


int get_byte_length(const char*error_id, const mxArray *param) {

	mxClassID category = mxGetClassID(param);

	switch (category) {
	case mxINT64_CLASS:    return 8;
	case mxUINT64_CLASS:   return 8;
	case mxDOUBLE_CLASS:   return 8;
	default: {
		std::stringstream buf;
		buf << " The input data for " << error_id << "should be of 8 bytes length digital type";
		mexErrMsgIdAndTxt("HDF_MEX_ACCESS:invalid_argument", buf.str().c_str());
		return -1;
	}
	}
}

template<typename T>
T retrieve_value(const char*err_id, const mxArray *prhs) {



	size_t m_size = mxGetM(prhs);
	size_t n_size = mxGetN(prhs);
	if (m_size != 1 || n_size != 1) {


		std::stringstream buf;
		buf << " The input for " << err_id << "should be a single value while its size is ["
			<< m_size << "x" << n_size << "] Matrix\n";
		mexErrMsgIdAndTxt("HDF_MEX_ACCESS:invalid_argument", buf.str().c_str());
	}

	auto *pVector = mxGetPr(prhs);

	return static_cast<T>(pVector[0]);
}

template<class T>
T* retrieve_vector(const char*err_id, const mxArray *prhs, size_t &vec_size, int &vec_bytes) {

	double *pPtr = mxGetPr(prhs);

	T *pVector = reinterpret_cast<T *>(pPtr);

	size_t m_size_a = mxGetM(prhs);
	size_t n_size_a = mxGetN(prhs);
	size_t m_size, n_size;
	if (n_size_a > m_size_a) {
		m_size = n_size_a;
		n_size = m_size_a;
	}
	else {
		m_size = m_size_a;
		n_size = n_size_a;
	}
	if (n_size == 1)
		vec_size = m_size;
	else {
		std::stringstream buf;
		buf << " The input for " << err_id << "should be a 1D vector while its size is ["
			<< m_size_a << "x" << n_size_a << "] Matrix\n";
		mexErrMsgIdAndTxt("HDF_MEX_ACCESS:invalid_argument", buf.str().c_str());
	}

	vec_bytes = get_byte_length(err_id, prhs);
	return pVector;
}

void retrieve_string(const mxArray *param, std::string &result, const char *ErrorPrefix) {

	mxClassID  category = mxGetClassID(param);
	if (category != mxCHAR_CLASS) {
		std::stringstream err;
		err << "The argument should be the a string: " << ErrorPrefix << " when in fact its not a string\n ";
		mexErrMsgIdAndTxt("HDF_MEX_ACCESS:invalid_argument",
			err.str().c_str());
	}
	auto buflen = mxGetNumberOfElements(param) + 1;
	result.resize(buflen);
	auto pBuf = &(result[0]);

	/* Copy the string data from string_array_ptr and place it into buf. */
	if (mxGetString(param, pBuf, buflen) != 0) {
		std::stringstream err;
		err << " Can not convert string data while processing " << ErrorPrefix << "\n";
		mexErrMsgIdAndTxt("HDF_MEX_ACCESS:invalid_argument",
			err.str().c_str());
	}
	result.erase(buflen - 1, 1);
}


/** process input values and extract parameters, necessary for the reader to work in the form the program requests
*Inputs:
nlhs  --   number of mex file left hand side parameters
plhs  -- array of pointers to left hand side parameters
nrhs  --  number of mex file right hand side parameters
prhs  --  array of pointers to right hand side parameters
*
*Ouptuts:
new_file          -- the structure, containing filename and datafolder to process.
block_positions   -- pointer to the array of the posisions of the blocks to read
block_sizes       -- pointer to the array of the posisions of the blocks to read
n_blocks_provided -- the size of the block positions and block sizes array
n_bytes           -- the size of the pointer of block_positions and block_size array


returns:
pointer to Matlab class handler to share
*/
template<class T>
class_handle<T>* parse_inputs(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[],
	input_types &work_mode,
	double *&block_pos, double *&block_size, size_t &n_blocks_provided, int &n_bytes,
	std::vector<pix_block_processor> &block_split_info, size_t &npix_to_read) {

	input_types input_kind;

	// get correct file name and the group name
	std::string mex_mode;
	retrieve_string(prhs[initInputs::mode_name], mex_mode, "describing mex_mode");

	if (mex_mode.compare("init") == 0) {
		work_mode = init_access;
	}
	else if (mex_mode.compare("read") == 0) {
		work_mode = read_data;
	}
	else if (mex_mode.compare("close") == 0) {
		work_mode = close_access;
	}
	else if (mex_mode.compare("get_filename") == 0) {
		work_mode = get_filename;
	}
	else {
		std::stringstream err;
		err << " Unknow operation mode: " << mex_mode;
		mexErrMsgIdAndTxt("HDF_MEX_ACCESS:invalid_argument", err.str().c_str());
	}

	switch (work_mode)
	{
	case(init_access): {
		if (nrhs != initInputs::N_INPUT_Arguments || nrhs != initInputs::N_INPUT_Arguments - 1 || nlhs != Init_Outputs::N_OUTPUT_Arguments) {
			std::stringstream err;
			err << " mex in init mode needs " << initInputs::N_INPUT_Arguments
				<< " or " << initInputs::N_INPUT_Arguments - 1
				<< " inputs and 1 output but got " << (short)nrhs
				<< " input(s) and " << (short)nlhs << " output(s)\n";
			mexErrMsgIdAndTxt("HDF_MEX_ACCESS:invalid_argument",
				err.str().c_str());
		}

		std::string filename, groupname;
		retrieve_string(prhs[initInputs::filename], filename,  "describing filename");
		retrieve_string(prhs[initInputs::pixel_group_name], groupname, "describing pixel dataset group_name");

		class_handle<hdf_pix_reader> *reader = new class_handle<hdf_pix_reader>();
		reader->class_ptr->init(filename, groupname);
		reader->filename = filename;
		reader->groupname = groupname;

		if (nrhs == initInputs::N_INPUT_Arguments) {
			reader->n_threads = retrieve_value<size_t>("number_of_threads", prhs[initInputs::num_threads]);
		}

		block_pos = nullptr;
		block_size = nullptr;
		npix_to_read = 0;
		n_blocks_provided = 0;
		n_bytes = 0;
		//n_blocks_2_read = 0;
		block_split_info.resize(1);

		return reader;
	}case(read_data): {
		if (nrhs != readInputs::N_INPUT_Arguments || nlhs > 3 || nlhs < 1) {
			std::stringstream err;
			err << " mex in read mode needs " << (short)readInputs::N_INPUT_Arguments
				<< " inputs and 1-3 outputs but got " << (short)nrhs
				<< " input(s) and " << (short)nlhs << " output(s)\n";
			mexErrMsgIdAndTxt("HDF_MEX_ACCESS:invalid_argument",
				err.str().c_str());
		}
		class_handle<hdf_pix_reader> *reader = get_handler_fromMatlab<hdf_pix_reader>(plhs[readInputs::io_class_ptr]);
		size_t num_first_block = reader->n_first_block;
		size_t pos_in_the_first_block = reader->pos_in_first_block;

		size_t n_blocks;
		block_pos = retrieve_vector<double>("block_positions", prhs[readInputs::block_positions], n_blocks, n_bytes);
		block_size = retrieve_vector<double>("block_sizes", prhs[readInputs::block_sizes], n_blocks_provided, n_bytes);
		if (n_blocks != n_blocks_provided) {
			mexErrMsgIdAndTxt("HDF_MEX_ACCESS:invalid_argument",
				" sizes of pix positions array and block sizes array should be equal but they are not");
		}
		size_t buf_size = retrieve_value<size_t>("pixel_buffer_size", prhs[readInputs::pix_buf_size]);

		if (n_blocks_provided == 0 || buf_size == 0 || num_first_block >= n_blocks) { // nothing to do. 
			return reader;
		}
		break;
	}case(close_access): case(get_filename): {
		if (nrhs != closeOrGetFnInputs::N_INPUT_Arguments) {
			std::stringstream err;
			err << " mex in " << mex_mode << " mode needs " << (short)closeOrGetFnInputs::N_INPUT_Arguments
				<< " inputs but got " << (short)nrhs
				<< " input(s)\n";
			mexErrMsgIdAndTxt("HDF_MEX_ACCESS:invalid_argument",
				err.str().c_str());
		}
		class_handle<hdf_pix_reader> *reader = get_handler_fromMatlab<hdf_pix_reader>(plhs[readInputs::io_class_ptr]);
		return reader;
	}
	default:
		break;
	}
	// here we are processing the pixel read option now

	// calculate number of pixels defined to read and compare it with the size of the buffer dedicated to read data
	npix_to_read = static_cast<uint64_t>(block_size[num_first_block]) - pos_in_the_first_block;
	if (npix_to_read > buf_size) {
		if (1.1*npix_to_read > buf_size)
			npix_to_read = buf_size;
		else
			buf_size = npix_to_read;
	}
	else {
		for (size_t i = num_first_block + 1; i < n_blocks; ++i) {
			if (n_bytes == 8)
				npix_to_read += static_cast<uint64_t>(block_size[i]);
			else
				npix_to_read += static_cast<uint32_t>(block_size[i]);
			if (npix_to_read >= buf_size) {
				npix_to_read = buf_size;
				break;
			}
		}

		if (npix_to_read < buf_size)
			buf_size = npix_to_read;
		else if (npix_to_read > buf_size)
			npix_to_read = buf_size;
	}

	block_split_info = pix_block_processor::split_pix_block(block_pos, block_size, n_blocks, num_first_block, pos_in_the_first_block, buf_size, n_threads);
	return reader;
}