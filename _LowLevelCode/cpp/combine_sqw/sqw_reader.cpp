#include "sqw_reader.h"

//--------------------------------------------------------------------------------------------------------------------
//-----------  SQW READER (FOR SINGLE SQW FILE)  ---------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------
sqw_reader::sqw_reader(size_t pix_buf_size) :
    pix_map(),
    npix_in_buf_start(0), buf_pix_end(0),
    PIX_BUF_SIZE(pix_buf_size), change_fileno(false), fileno(true),
    use_multithreading_pix(true), pix_read(false), pix_read_job_completed(false), n_first_buf_pix(0)
{}

sqw_reader::~sqw_reader() {
    if (this->use_multithreading_pix) {
        this->pix_read_lock.lock();

        this->pix_read_job_completed = true;
        // finish incomplete read job if it has not been finished naturally
        this->pix_read = false;
        this->read_pix_needed.notify_one();
        this->pix_read_lock.unlock();

        read_pix_job_holder.join();
    }

    h_data_file_pix.close();
}

/*
sqw_reader::sqw_reader(const fileParameters &fpar, bool changefileno, bool fileno_provided, size_t pix_buf_size)
    : sqw_reader(pix_buf_size)
{
    this->init(fpar, changefileno, fileno_provided, pix_buf_size);
}
*/
//
void sqw_reader::init(const fileParameters &fpar, bool changefileno, bool fileno_provided, size_t pix_buf_size, int multithreading_settings) {
    bool bin_multithreading;
    switch (multithreading_settings) {
    case(0):
        bin_multithreading = false;
        use_multithreading_pix = false;
        break;
    case(1):
        bin_multithreading = true;
        use_multithreading_pix = true;
        break;
    case(2):
        bin_multithreading = true;
        use_multithreading_pix = false;
        break;
    case(3):
        bin_multithreading = false;
        use_multithreading_pix = true;
        break;
    default:
        mexErrMsgTxt("Input multithreading parameter should be 0 (no multithreading) 1 (multithreading)"
            ", 2 (debug mode, only bin thread used for reading ) or 3 (debug mode , use pix read thread, and disable bin reading)");
    }

    this->fileDescr = fpar;

    this->pix_map.init(fpar.fileName, fpar.nbin_start_pos, fpar.total_NfileBins, pix_buf_size, bin_multithreading);

    if (pix_buf_size != 0) {
        this->PIX_BUF_SIZE = pix_buf_size;
        this->nbin_read_buffer.resize(BIN_BUF_SIZE);
        char *tBuff = reinterpret_cast<char *>(&nbin_read_buffer[0]);
        h_data_file_bin.rdbuf()->pubsetbuf(tBuff, BIN_BUF_SIZE*BIN_SIZE_BYTES);
        use_streambuf_direct = false;
        //
        nbin_buffer.resize(BIN_BUF_SIZE);
    }
    else {
        BIN_BUF_SIZE = 1;
        use_streambuf_direct = true;
        nbin_read_buffer.resize(BIN_BUF_SIZE);
        //
        this->BUF_EXTENSION_STEP = 512;
        nbin_buffer.resize(BUF_EXTENSION_STEP);
    }


    h_data_file_pix.rdbuf()->pubsetbuf(0, 0);
    h_data_file_pix.open(this->fileDescr.fileName,std::ios::in | std::ios::binary);
    if (!h_data_file_pix.is_open()) {
        std::string error("Can not open file: ");
        error += this->fileDescr.fileName;
        mexErrMsgTxt(error.c_str());

    this->change_fileno = changefileno;
    this->fileno = fileno_provided;

    this->PIX_BUF_SIZE = pix_buf_size;
    this->pix_buffer.resize(PIX_BUF_SIZE*PIX_SIZE);

    if (this->use_multithreading_pix) {
        this->thread_pix_buffer.resize(PIX_BUF_SIZE*PIX_SIZE);
        std::thread read_pix([this]() {this->read_pixels_job(); });
        read_pix_job_holder.swap(read_pix);
    }

}


/* return pixel information for the pixels stored in the bin
* @param bin_number  -- the bin number to get results for
* @param pix_info    -- the pointer to the pixel buffer where results should be placed
* @param buf_position-- position in the pix buffer where pixels should be stored
* @param pix_start_num      --calculated first bin's pixel number in the linear array of all pixels
*                             (on hdd or Horace pix array)
* @param num_bin_pix         -- number of pixels in the bin requested
* @param position_is_defined -- if true, pix_start_num and num_bin_pix are already calculated and used as input,
*                               if false, they are calculated internally and returned.
*
* @returns pix_info -- fills block of size = [9*num_bin_pix] containing pixel info
*                      for the pixels, belonging to the bin requested. The data start at buf_position
*/
void sqw_reader::get_pix_for_bin(size_t bin_number, float *const pix_info, size_t buf_position,
    size_t &pix_start_num, size_t &num_bin_pix, bool position_is_defined) {

    if (!position_is_defined) {
        this->get_npix_for_bin(bin_number, pix_start_num, num_bin_pix);
    }
    if (num_bin_pix == 0) return;

    if (pix_start_num < this->npix_in_buf_start || pix_start_num + num_bin_pix > this->buf_pix_end) {
        this->read_pixels(bin_number, pix_start_num);
    }

    size_t out_buf_start = buf_position*PIX_SIZE;
    size_t in_buf_start = (pix_start_num - this->npix_in_buf_start)*PIX_SIZE;
    for (size_t i = 0; i < num_bin_pix*PIX_SIZE; i++) {
        pix_info[out_buf_start + i] = pix_buffer[in_buf_start + i];
    }

}
/*
 read pixels information, located in the bin with the number requested

 read either all pixels in the buffer or at least the number specified

*/
void sqw_reader::read_pixels(size_t bin_number, size_t pix_start_num) {

    //check if we have loaded enough bin information to read enough
    //pixels and return enough pixels to fill - in buffer.Expand or
    // shrink if necessary
    // if we are here, nbin buffer is intact and pixel buffer is
    // invalidated
    size_t num_pix_to_read = this->check_binInfo_loaded_(bin_number, true, pix_start_num);
    if (this->use_multithreading_pix) {

        std::unique_lock<std::mutex> lock(this->pix_exchange_lock);
        this->pix_ready.wait(lock, [this]() {return this->pix_read; });
        if (this->pix_read_job_completed) {
            this->pix_read = false;
            this->read_pix_needed.notify_one();
            return;
        }

        this->thread_pix_buffer.swap(this->pix_buffer);
        this->n_first_buf_pix = pix_start_num + num_pix_to_read;
        this->pix_read = false;
        this->read_pix_needed.notify_one();

    }
    else {
        read_pix_io(pix_start_num, this->pix_buffer, num_pix_to_read);
    }
    this->npix_in_buf_start = pix_start_num;
    this->buf_pix_end = this->npix_in_buf_start + num_pix_to_read;

}
//
void sqw_reader::read_pixels_job() {

    std::unique_lock<std::mutex> lock(this->pix_exchange_lock);

    while (!this->pix_read_job_completed) {
        this->read_pix_needed.wait(lock, [this]() {return !this->pix_read; });
        if (this->pix_read_job_completed) {
            this->pix_read = true;
            this->pix_ready.notify_one();
            break;
        }

        this->pix_read_lock.lock();
        size_t n_pix_to_read = PIX_BUF_SIZE;
        if (this->n_first_buf_pix + n_pix_to_read >= this->max_num_of_pixels) {
            n_pix_to_read = this->max_num_of_pixels - this->n_first_buf_pix;
        }

        if (n_pix_to_read > 0) {
            read_pix_io(this->n_first_buf_pix, thread_pix_buffer, n_pix_to_read);
        }

        this->pix_read = true;
        this->pix_read_lock.unlock();

        this->pix_ready.notify_one();
    }

}
void sqw_reader::read_pix_io(size_t pix_start_num, std::vector<float> &pix_buffer, size_t num_pix_to_read) {

    std::streamoff pix_pos = this->fileDescr.pix_start_pos + pix_start_num*PIX_BLOCK_SIZE_BYTES;
    //std::lock_guard<std::mutex> lock(this->io_lock); <-- not necessary for separate file access
#ifdef STDIO
    if (num_pix_to_read == 0) {
        return;
    }
    void * buffer = &pix_buffer[0];

    pix_pos -= this->bin_buffer.fpos;
    auto err = fseek(h_data_file_pix, pix_pos, SEEK_CUR);
    if (err) {
        mexErrMsgTxt("COMBINE_SQW:read_pixels seek error");
    }
    size_t nBytes = fread(buffer, PIX_BLOCK_SIZE_BYTES, num_pix_to_read, h_data_file_pix);
    if (nBytes != num_pix_to_read) {
        mexErrMsgTxt("COMBINE_SQW:read_pixels Read error, can not read the number of pixels requested");
    }
    this->bin_buffer.fpos = ftell(h_data_file_pix);

#else
    char * buffer = reinterpret_cast<char *>(&pix_buffer[0]);
    size_t length = num_pix_to_read*PIX_BLOCK_SIZE_BYTES;

    //std::string err;
    //h_data_file_pix.rdbuf()->pubsetbuf(buffer, length);
    auto pbuf = h_data_file_pix.rdbuf();
    pbuf->pubseekpos(pix_pos);
    //pbuf->pubseekoff(0, istr.beg);       // rewind
    pbuf->sgetn(buffer, length);
    //pbuf->pubsync();
    /*
    h_data_file_pix.seekg(pix_pos);
    try {
    h_data_file_pix.read(buffer, length);
    }
    catch (std::ios_base::failure &e) {
    err = "COMBINE_SQW:read_pixels read error: " + std::string(e.what());
    }
    catch (...) {
    err = "COMBINE_SQW:read_pixels unhandled read error. ";
    }
    if (err.size() > 0) {
    mexErrMsgTxt(err.c_str());
    }
    */
    size_t n_read_pixels = num_pix_to_read;
    if (h_data_file_pix.eof()) {
        n_read_pixels = h_data_file_pix.gcount() / PIX_BLOCK_SIZE_BYTES;
        h_data_file_pix.clear();
    }
#endif
    if (this->change_fileno) {
        for (size_t i = 0; i < n_read_pixels; i++) {
            if (fileno) {
                pix_buffer[4 + i * 9] = float(this->fileDescr.file_id);
            }
            else {
                pix_buffer[4 + i * 9] += float(this->fileDescr.file_id);
            }
        }

    }


}
/*
% verify bin information loaded to memory and identify sufficient number
% of pixels to fill - in pixels buffer.
%
% read additional bin information if not enough bins have been
% processed
%
*/
size_t sqw_reader::check_binInfo_loaded_(size_t bin_number, bool extend_bin_buffer, size_t pix_start_num) {

    // assume bin buffer is intact with bin_number loaded and get number of pixels this bin buffer describes
    size_t num_pix_to_read = this->num_pix_described(bin_number);

    if (num_pix_to_read > this->PIX_BUF_SIZE) {
        num_pix_to_read = this->num_pix_to_fit(bin_number, this->PIX_BUF_SIZE);
        //
        if (num_pix_to_read > this->PIX_BUF_SIZE) {  // single bin still contains more pixels then pix buffer
            this->PIX_BUF_SIZE = num_pix_to_read;
            // pix buffer should be extended
            this->pix_buffer.resize(this->PIX_BUF_SIZE*PIX_SIZE);
            if (this->use_multithreading_pix) {
                this->pix_read_lock.lock();

                this->thread_pix_buffer.resize(PIX_BUF_SIZE*PIX_SIZE);
                this->n_first_buf_pix = pix_start_num;
                this->pix_read = false;
                this->read_pix_needed.notify_one();

                this->pix_read_lock.unlock();

            }
        }
    }
    else { // bin buffer should be extended
        if (extend_bin_buffer) {
            this->expand_pixels_selection(bin_number);
            return check_binInfo_loaded_(bin_number, false, pix_start_num);
        }

    }
    return num_pix_to_read;

}

