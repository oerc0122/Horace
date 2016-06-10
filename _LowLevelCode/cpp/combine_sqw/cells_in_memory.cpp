#include "cells_in_memory.h"
//--------------------------------------------------------------------------------------------------------------------
//---------------- BINS IN MEMORY ------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------
void cells_in_memory::init(const std::string &full_file_name, size_t bin_start_pos, size_t n_tot_bins, size_t BufferSize, bool use_multithreading) {

    this->full_file_name = full_file_name;

#ifdef STDIO
    h_data_file_bin = fopen(full_file_name.c_str(), "rb");
    bin_buffer.fpos = ftell(h_data_file_bin);
    if (!h_data_file_bin) {
        std::string error("Can not open file: ");
        error += full_file_name;
        mexErrMsgTxt(error.c_str());
    }
#else
    h_data_file_bin.rdbuf()->pubsetbuf(0, 0);
    h_data_file_bin.open(full_file_name, std::ios::in | std::ios::binary);
    if (!h_data_file_bin.is_open()) {
        std::string error("Can not open file: ");
        error += full_file_name;
        mexErrMsgTxt(error.c_str());
    }
#endif


    BUF_SIZE_STEP = BufferSize;
    BIN_BUF_SIZE = 2 * BUF_SIZE_STEP;

    nbin_buffer.resize(BIN_BUF_SIZE, 0);
    pix_pos_in_buffer.resize(BIN_BUF_SIZE, 0);
    nTotalBins = n_tot_bins;
    binFileStartPos = bin_start_pos;
    // separate read job
    this->use_multithreading = use_multithreading;
    if (this->use_multithreading) {
        this->nbin_read_buffer.resize(BIN_BUF_SIZE);
        std::thread read_bins([this]() {this->read_bins_job(); });
        read_bins_job_holder.swap(read_bins);
    }
}
//
cells_in_memory::~cells_in_memory() {
    if (this->use_multithreading) {
        this->bin_read_lock.lock();
        this->read_completed = true;
        // finish incomplete read job if it has not been finished naturally
        this->nbins_read = false;
        this->read_bins_needed.notify_one();
        this->bin_read_lock.unlock();

        read_bins_job_holder.join();
    }
#ifdef STDIO
    fclose(h_data_file_bin);
#else
    h_data_file_bin.close();
#endif

}

/* return number of pixels this bin buffer describes */
size_t cells_in_memory::num_pix_described(size_t bin_number)const {
    size_t loc_bin = bin_number - this->num_first_buf_bin;
    size_t end = this->buf_end - 1;
    size_t num_pix_start = pix_pos_in_buffer[loc_bin];
    return pix_pos_in_buffer[end] + nbin_buffer[end] - num_pix_start;

}

/* return the number of pixels described by the bins fitting the buffer of the size specified*/
size_t cells_in_memory::num_pix_to_fit(size_t bin_number, size_t buf_size)const {
    size_t n_bin = bin_number - num_first_buf_bin;
    size_t shift = pix_pos_in_buffer[n_bin];
    size_t val = buf_size + shift;
    auto begin = pix_pos_in_buffer.begin() + n_bin;
    auto end = pix_pos_in_buffer.begin() + this->buf_end;
    auto it = std::upper_bound(begin, end, val);

    --it; // went step back to value smaller then the one exceeding the threshold
    if (it == begin) {
        return this->nbin_buffer[n_bin];
    }
    else {
        return *it - shift;
    }


}


/** loads bin information for a pixel, which does not have this information loaded
*
* get number of pixels, stored in the bin and the position
*  of these pixels within pixel array
*
*@param bin_number -- number of bin to get pixel information for
*pix_pos_in_buffer
* Returns:
* pix_start_num -- initial position of the bin pixels in the pixels array
* num_bin_pix   -- number of pixels, stored in this bin
*/
void cells_in_memory::get_npix_for_bin(size_t bin_number, size_t &pix_start_num, size_t &num_bin_pix) {

    //
    if (bin_number >= this->buf_nbin_end) {
        this->read_all_bin_info(bin_number); // Advance cache
    }
    else if (bin_number < this->num_first_buf_bin) { // cache miss
        this->num_first_buf_bin = 0;
        this->buf_nbin_end = 0;
        this->read_all_bin_info(bin_number);
    }
    size_t  num_bin_in_buf = bin_number - this->num_first_buf_bin;
    num_bin_pix = this->nbin_buffer[num_bin_in_buf];
    pix_start_num = this->pix_before_buffer + this->pix_pos_in_buffer[num_bin_in_buf];

}
/* read bin info to describe sufficient number of pixels in buffer
bin number is already in the bin buffer and we want to read additional bins
describing more pixels  */
void cells_in_memory::expand_pixels_selection(size_t bin_number) {
    if (this->buf_nbin_end == this->nTotalBins) {
        return;
    }
    size_t  num_bin_in_buf = bin_number - this->num_first_buf_bin;
    // move bin buffer into new position
    this->num_first_buf_bin = bin_number;
    this->pix_before_buffer += this->pix_pos_in_buffer[num_bin_in_buf];
    for (size_t i = num_bin_in_buf; i < this->buf_end; i++) {
        this->nbin_buffer[i - num_bin_in_buf] = this->nbin_buffer[i];
    }
    size_t buf_start = this->buf_end - num_bin_in_buf;
    size_t buf_nbin_end, buf_end;
    if (this->use_multithreading) {
        size_t  num_buf_bins;
        calc_buf_range(bin_number, buf_start, this->BUF_SIZE_STEP, num_buf_bins, buf_nbin_end, buf_end);
        if (bin_number + buf_start == this->n_first_rbuf_bin) {
            std::unique_lock<std::mutex> lock(this->exchange_lock);
            this->bins_ready.wait(lock, [this]() {return this->nbins_read; });
            // copy bin info from read buffer to nbin buffer
            this->bin_read_lock.lock();
            for (size_t i = 0; i < num_buf_bins; i++) {
                this->nbin_buffer[buf_start + i] = this->nbin_read_buffer[i];
            }
            // set up parameters for next read job on separate thread
            this->n_first_rbuf_bin = buf_nbin_end;
            this->nbins_read = false;
            this->read_bins_needed.notify_one();
            this->bin_read_lock.unlock();

        }
        else { // should never happen
            read_bins(bin_number, buf_start, this->BUF_SIZE_STEP, this->nbin_buffer, buf_nbin_end, buf_end);
        }

    }
    else {
        read_bins(bin_number, this->buf_end - num_bin_in_buf, this->BUF_SIZE_STEP, this->nbin_buffer, buf_nbin_end, buf_end);
    }
    record_read_bins(bin_number, buf_nbin_end, buf_end, this->nbin_buffer);

}
//
void cells_in_memory::read_all_bin_info(size_t bin_number) {

    if (bin_number < this->num_first_buf_bin) { //cash missed, start reading afresh
        this->num_first_buf_bin = 0;
        this->buf_nbin_end = 0;
        this->pix_before_buffer = 0;
    }
    //------------------------------------------------------------------------------
    size_t firstNewBin = this->buf_nbin_end;
    size_t n_strides = (bin_number - firstNewBin) / this->BUF_SIZE_STEP + 1;
    for (size_t i = 0; i < n_strides; i++) {
        size_t start_bin = firstNewBin + i*this->BUF_SIZE_STEP;
        // store pixel info for all previous bins
        size_t end = this->buf_end - 1;
        this->pix_before_buffer += (this->pix_pos_in_buffer[end] + this->nbin_buffer[end]);
        size_t buf_nbin_end, buf_end;
        if (this->use_multithreading) {
            if (this->n_first_rbuf_bin != start_bin) { // cash missed
                this->bin_read_lock.lock();
                this->n_first_rbuf_bin = start_bin;
                this->nbins_read = false;
                this->read_bins_needed.notify_one();
                this->bin_read_lock.unlock();
            }
            // retrieve results
            std::unique_lock<std::mutex> lock(this->exchange_lock);
            this->bins_ready.wait(lock, [this]() {return this->nbins_read; });
            if (this->read_completed) {
                return;
            }

            this->bin_read_lock.lock();
            buf_nbin_end = this->rbuf_nbin_end;
            buf_end = this->rbuf_end;
            this->nbin_read_buffer.swap(this->nbin_buffer);
            // set up parameters for next read job
            this->n_first_rbuf_bin = buf_nbin_end;
            this->nbins_read = false;
            this->read_bins_needed.notify_one();

            this->bin_read_lock.unlock();


        }
        else {
            read_bins(start_bin, 0, this->BUF_SIZE_STEP, this->nbin_buffer, buf_nbin_end, buf_end);
        }
        record_read_bins(start_bin, buf_nbin_end, buf_end, this->nbin_buffer);
    }
}
void cells_in_memory::read_bins_job() {

    std::unique_lock<std::mutex> lock(this->exchange_lock);

    while (!this->read_completed) {
        this->read_bins_needed.wait(lock, [this]() {return !this->nbins_read; });
        if (this->read_completed) {
            this->nbins_read = true;
            this->bins_ready.notify_one();
            break;
        }

        this->bin_read_lock.lock();

        if (this->n_first_rbuf_bin < this->nTotalBins) {
            read_bins(this->n_first_rbuf_bin, 0, this->BUF_SIZE_STEP, this->nbin_read_buffer, this->rbuf_nbin_end, this->rbuf_end);
        }
        else {
            this->rbuf_nbin_end = this->nTotalBins;
            this->rbuf_end = 0;
        }
        this->nbins_read = true;
        this->bin_read_lock.unlock();

        this->bins_ready.notify_one();
    }

}
//
void cells_in_memory::calc_buf_range(size_t num_bin, size_t buf_start, size_t buf_size, size_t &tot_num_bins_to_read, size_t & bin_end, size_t & buf_end) {

    bin_end = num_bin + buf_size + buf_start;

    if (bin_end > nTotalBins) {
        bin_end = nTotalBins;
    }
    else if (bin_end + buf_size >= nTotalBins) { // finish reading extended buffer as all bins fit extended buffer 
        bin_end = nTotalBins;
    }

    tot_num_bins_to_read = bin_end - num_bin - buf_start;
    if (tot_num_bins_to_read > this->BIN_BUF_SIZE) {
        tot_num_bins_to_read = this->BIN_BUF_SIZE;
        bin_end = num_bin + this->BIN_BUF_SIZE;
    }
    buf_end = buf_start + tot_num_bins_to_read;

}
/*
* Method to read block of information about number of pixels
* stored according to bins starting with the bin number specified
* as input
*
* num_loc_bin -- the bin within a block to read into the buffer
Returns:
absolute number of last bin read into the buffer.
*/
void cells_in_memory::read_bins(size_t num_bin, size_t buf_start, size_t buf_size,
    std::vector<uint64_t> &inbuf, size_t &bin_end, size_t &buf_end) {

    if (num_bin >= this->nTotalBins) {
        mexErrMsgTxt("READ_SQW::read_bins =>Accessing bin out of bin range");
    }

    size_t  tot_num_bins_to_read;
    calc_buf_range(num_bin, buf_start, buf_size, tot_num_bins_to_read, bin_end, buf_end);

    std::streamoff bin_pos = binFileStartPos + (num_bin + buf_start)*BIN_SIZE_BYTES;
    //
    //std::lock_guard<std::mutex> lock(this->io_lock);
#ifdef STDIO
    uint64_t * buffer = reinterpret_cast<uint64_t *>(&nbin_buffer[buf_start]);
    std::streamoff length = tot_num_bins_to_read;

    bin_pos -= this->fpos;
    auto err = fseek(fReader, bin_pos, SEEK_CUR);
    if (err) {
        mexErrMsgTxt("COMBINE_SQW:read_bins seek error ");
    }
    size_t nBytes = fread(buffer, BIN_SIZE_BYTES, tot_num_bins_to_read, fReader);
    if (nBytes != tot_num_bins_to_read) {
        mexErrMsgTxt("COMBINE_SQW:read_bins Read error, can not read the number of bytes requested");
    }
    this->fpos = ftell(fReader);
#else
    std::streamoff length = tot_num_bins_to_read*BIN_SIZE_BYTES;
    char * buffer = reinterpret_cast<char *>(&inbuf[buf_start]);

    auto pbuf = h_data_file_bin.rdbuf();
    pbuf->pubseekpos(bin_pos);
    //pbuf->pubseekoff(0, istr.beg);       // rewind
    pbuf->sgetn(buffer, length);
    //pbuf->pubsync();
    /*
    h_data_file_bin.seekg(bin_pos);
    std::string err;
    try {
    h_data_file_bin.read(buffer, length);
    }
    catch (std::ios_base::failure &e) {
    err = "COMBINE_SQW:read_bins read error: " + std::string(e.what());
    }
    catch (...) {
    err = "COMBINE_SQW:read_bins unhandled read error.";

    }
    if (err.size() > 0) {
    mexErrMsgTxt(err.c_str());
    }
    */
#endif

}
/*Store results of the read operation within the class memory*/
void  cells_in_memory::record_read_bins(size_t num_bin, size_t buf_nbin_end, size_t buf_end, const std::vector<uint64_t> &buffer) {
    // Store results
    this->num_first_buf_bin = num_bin;
    this->buf_nbin_end = buf_nbin_end;
    this->buf_end = buf_end;


    this->pix_pos_in_buffer[0] = 0;
    for (size_t i = 1; i < buf_end; i++) {
        this->pix_pos_in_buffer[i] = this->pix_pos_in_buffer[i - 1] + this->nbin_buffer[i - 1];
    }

    if (this->buf_nbin_end == this->nTotalBins) {
        size_t last = buf_end - 1;
        this->max_num_of_pixels = this->pix_before_buffer + this->pix_pos_in_buffer[last] + this->nbin_buffer[last];
    }

}