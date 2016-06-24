#include "sqw_reader.h"

//--------------------------------------------------------------------------------------------------------------------
//-----------  SQW READER (FOR SINGLE SQW FILE)  ---------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------
sqw_reader::sqw_reader() :
    pix_map(),
    _nPixInFile(0),
    npix_in_buf_start(0), buf_pix_end(0), 
    PIX_BUF_SIZE(1024), change_fileno(false), fileno(true),
    n_first_threadbuf_pix(0),
    use_multithreading_pix(true), pix_read(false), pix_read_job_completed(false)
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
    if (h_data_file_pix.is_open()) {
        h_data_file_pix.close();
    }
    _nPixInFile = 0;
    npix_in_buf_start = 0;
    buf_pix_end = 0;

    this->pix_map.init(fpar.fileName, fpar.nbin_start_pos, fpar.total_NfileBins, pix_buf_size, bin_multithreading);

    if (pix_buf_size != 0) {
        this->PIX_BUF_SIZE = pix_buf_size;
        this->pix_buffer.resize(PIX_BUF_SIZE*PIX_SIZE);
        char *tBuff = reinterpret_cast<char *>(&pix_buffer[0]);
        h_data_file_pix.rdbuf()->pubsetbuf(tBuff, PIX_BUF_SIZE*PIX_SIZE_BYTES);
        this->use_streambuf_direct = false;
        //
    }
    else {
        this->use_streambuf_direct = true;
        this->use_multithreading_pix = false;
        //this->PIX_BUF_SIZE = this->PIX_BUF_DEFAULT_SIZE;
        //this->pix_buffer.resize(PIX_BUF_SIZE*PIX_SIZE);
    }


    //h_data_file_pix.rdbuf()->pubsetbuf(0, 0);
    h_data_file_pix.open(this->fileDescr.fileName, std::ios::in | std::ios::binary);
    if (!h_data_file_pix.is_open()) {
        std::string error("Can not open file: ");
        error += this->fileDescr.fileName;
        mexErrMsgTxt(error.c_str());
    } else {
        this->change_fileno = changefileno;
        this->fileno = fileno_provided;

        // read number of pixels defined in the file
        std::streamoff pix_pos = this->fileDescr.pix_start_pos - 8;
        auto pbuf = h_data_file_pix.rdbuf();
        pbuf->pubseekpos(pix_pos);
        char *buffer = reinterpret_cast<char *>(&_nPixInFile);
        pbuf->sgetn(buffer, 8);
        if (this->_nPixInFile == 0) {
            return; // file does not have pixels. 
        }


        if (this->use_multithreading_pix) {
            this->thread_pix_buffer.resize(PIX_BUF_SIZE*PIX_SIZE);
            std::thread read_pix([this]() {this->read_pixels_job(); });
            read_pix_job_holder.swap(read_pix);
        }

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
*                      within pix_info array
*/
void sqw_reader::get_pix_for_bin(size_t bin_number, float *const pix_info, size_t buf_position,
    size_t &pix_start_num, size_t &num_bin_pix, bool position_is_defined) {

    size_t out_buf_start = buf_position*PIX_SIZE;

    if (!position_is_defined) {
        this->pix_map.get_npix_for_bin(bin_number, pix_start_num, num_bin_pix);
    }
    if (num_bin_pix == 0) return;

    if (pix_start_num < this->npix_in_buf_start || pix_start_num + num_bin_pix > this->buf_pix_end) {
        this->_update_cash(bin_number, pix_start_num, num_bin_pix,pix_info+ out_buf_start);
    }
    if (!this->use_streambuf_direct){ // copy data from buffer to the destination
        size_t in_buf_start = (pix_start_num - this->npix_in_buf_start)*PIX_SIZE;
        for (size_t i = 0; i < num_bin_pix*PIX_SIZE; i++) {
            pix_info[out_buf_start + i] = pix_buffer[in_buf_start + i];
        }
    }
}
/*
 read pixels information, located in the bin with the number requested

 read either all pixels in the buffer or at least the number specified
*/
void sqw_reader::_update_cash(size_t bin_number, size_t pix_start_num,size_t num_pix_in_bin, float *const pix_info) {

    //check if we have loaded enough bin information to read enough
    //pixels and return enough pixels to fill - in buffer.Expand or
    // shrink if necessary
    // if we are here, nbin buffer is intact and pixel buffer is
    // invalidated
    size_t num_pix_to_read;
    if (use_streambuf_direct) {
        num_pix_to_read = num_pix_in_bin;
    } else {
        size_t pix_buf_size;
        bool end_of_pixmap_reached;
        //check_binInfo_loaded_(bin_number, true, pix_start_num);
        if (this->use_streambuf_direct ) {
            pix_buf_size = num_pix_in_bin;
        }else{
            pix_buf_size = this->pix_buffer.size()/ PIX_SIZE;
        }
        num_pix_to_read = this->pix_map.check_expand_pix_map(bin_number, pix_buf_size, end_of_pixmap_reached);
    }

    if (this->use_multithreading_pix) {

        std::unique_lock<std::mutex> lock(this->pix_exchange_lock);
        this->pix_ready.wait(lock, [this]() {return this->pix_read; });
        if (this->pix_read_job_completed) {
            this->pix_read = false;
            this->read_pix_needed.notify_one();
            return;
        }

        this->thread_pix_buffer.swap(this->pix_buffer);
        this->n_first_threadbuf_pix = pix_start_num + num_pix_to_read;
        this->pix_read = false;
        this->read_pix_needed.notify_one();

    }
    else {
        if (use_streambuf_direct) {
            this->_read_pix(pix_start_num, pix_info, num_pix_to_read);
        } else {
            if (this->pix_buffer.size() < num_pix_to_read*PIX_SIZE) {
                this->pix_buffer.resize(num_pix_to_read*PIX_SIZE);
            }
            this->_read_pix(pix_start_num, &pix_buffer[0], num_pix_to_read);
        }

    }
    this->npix_in_buf_start = pix_start_num;
    this->buf_pix_end = this->npix_in_buf_start + num_pix_to_read;


}
//

void sqw_reader::read_pixels_job() {
    /*
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
    */
}



/* Read specified number of pixels into the pixel buffer provided */
void sqw_reader::_read_pix(size_t pix_start_num, float *const pix_buffer, size_t num_pix_to_read) {


    if (pix_start_num + num_pix_to_read > this->_nPixInFile) {
        if (pix_start_num > this->_nPixInFile) {
            mexErrMsgTxt("SQW_READER::_read_pix =>Trying to read pixel outside of the pixel range");
        }
        num_pix_to_read = this->_nPixInFile - pix_start_num;
    }

    std::streamoff pix_pos = this->fileDescr.pix_start_pos + pix_start_num*PIX_SIZE_BYTES;
    auto pbuf = h_data_file_pix.rdbuf();
    pbuf->pubseekpos(pix_pos);

    //
    char * buffer = reinterpret_cast<char *>(pix_buffer);
    std::streamoff length = num_pix_to_read*PIX_SIZE_BYTES;
    pbuf->sgetn(buffer, length);


    if (this->change_fileno) {
        for (size_t i = 0; i < num_pix_to_read; i++) {
            if (fileno) {
                *(pix_buffer+4 + i * 9)   = float(this->fileDescr.file_id);
            }
            else {
                *(pix_buffer + 4 + i * 9) += float(this->fileDescr.file_id);
            }
        }

    }

}

