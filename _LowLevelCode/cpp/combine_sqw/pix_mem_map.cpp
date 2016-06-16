#include "pix_mem_map.h"
//--------------------------------------------------------------------------------------------------------------------
//---------------- BINS IN MEMORY ------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------
/*Constructor */
pix_mem_map::pix_mem_map() :
    max_num_of_pixels(std::numeric_limits<size_t>::max()),

    use_streambuf_direct(true),
    prebuf_pix_num(0),
    num_first_buf_bin(0), num_last_buf_bin(0),

    _nTotalBins(0), _binFileStartPos(0),
    BIN_BUF_SIZE(1),
    //
    use_multithreading(false),
    nbins_read(false), read_completed(false)
{}
/* Destructor */
pix_mem_map::~pix_mem_map() {
    if (this->use_multithreading) {
        this->bin_read_lock.lock();
        this->read_completed = true;
        // finish incomplete read job if it has not been finished naturally
        this->nbins_read = false;
        this->read_bins_needed.notify_one();
        this->bin_read_lock.unlock();

        read_bins_job_holder.join();
    }
    h_data_file_bin.close();


}

void pix_mem_map::init(const std::string &full_file_name, size_t bin_start_pos, size_t n_tot_bins, size_t BufferSize, bool use_multithreading) {

    this->_nTotalBins = n_tot_bins;
    this->_binFileStartPos = bin_start_pos;
    this->num_first_buf_bin = 0;
    this->num_last_buf_bin  = 0;


    this->full_file_name = full_file_name;
    if (this->h_data_file_bin.is_open()) {
        this->h_data_file_bin.close();
    }
    //
    if (BufferSize != 0) {
        BIN_BUF_SIZE = BufferSize;
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
        nbin_buffer.resize(512);
    }
    h_data_file_bin.open(full_file_name, std::ios::in | std::ios::binary);
    if (!h_data_file_bin.is_open()) {
        std::string error("Can not open file: ");
        error += full_file_name;
        mexErrMsgTxt(error.c_str());
    }
    // 
    size_t n_last = nbin_buffer.size()-1;
    nbin_buffer[n_last].pix_pos = 0;
    nbin_buffer[n_last].num_bin_pixels = 0;


    /*
    // separate read job
    this->use_multithreading = use_multithreading;
    if (this->use_multithreading) {
        this->nbin_read_buffer.resize(BIN_BUF_SIZE);
        std::thread read_bins([this]() {this->read_bins_job(); });
        read_bins_job_holder.swap(read_bins);
    }
    */
}
//

/* return number of pixels this bin buffer describes starting from the bin buffer provided*/
size_t pix_mem_map::num_pix_described(size_t bin_number)const {
    if (bin_number< this->num_first_buf_bin || bin_number > this->num_last_buf_bin) {
        return 0;
    }
    size_t loc_bin = bin_number - this->num_first_buf_bin;
    auto pEnd = this->nbin_buffer.begin() + this->num_last_buf_bin;
    size_t num_pix_start = this->nbin_buffer[loc_bin].pix_pos;
    return pEnd->pix_pos + pEnd->num_bin_pixels - num_pix_start;

}
/*
* Method to read block of information about number of pixels
* stored according to bins starting with the bin number specified
* as input
* num_bin   -- first bin to read information into
* buf_start -- position of the bins to place into the bugger (default, from the beginning of the buffer)
*
* num_loc_bin -- the bin within a block to read into the buffer
Returns:
bin_end -- absolute number of last bin read into the buffer
buf_end -- last filled buffer cell (ideally equal to the buf_size, but may be smaller near eof)

*/
void pix_mem_map::_read_bins(size_t num_bin, std::vector<bin_info> &inbuf,
    size_t &bin_end, size_t &buf_end) {

    if (num_bin >= this->_nTotalBins) {
        mexErrMsgTxt("READ_SQW::read_bins =>Accessing bin out of bin range");
    }
    size_t buf_size = inbuf.size();
    bin_end = num_bin + buf_size;

    if (bin_end > this->_nTotalBins) {
        bin_end = this->_nTotalBins;
    }

    size_t tot_num_bins_to_read = bin_end - num_bin;


    std::streamoff bin_pos = this->_binFileStartPos + num_bin*BIN_SIZE_BYTES;
    auto pbuf = h_data_file_bin.rdbuf();
    pbuf->pubseekpos(bin_pos);

    if (this->use_streambuf_direct)
    {
        this->nbin_read_buffer.resize(1);
        char * buffer = reinterpret_cast<char *>(&nbin_read_buffer[0]);
        pbuf->sgetn(buffer, BIN_SIZE_BYTES);
        inbuf[0].num_bin_pixels = this->nbin_read_buffer[0];
        for (size_t i = 1; i < tot_num_bins_to_read; i++) {
            pbuf->sgetn(buffer, BIN_SIZE_BYTES);
            inbuf[i].num_bin_pixels = this->nbin_read_buffer[0];
            inbuf[i].pix_pos = inbuf[i - 1].pix_pos + inbuf[i - 1].num_bin_pixels;
        }
    }
    else {
        if (tot_num_bins_to_read > nbin_read_buffer.size()) {
            this->nbin_read_buffer.resize(tot_num_bins_to_read);
        }
        std::streamoff length = tot_num_bins_to_read*BIN_SIZE_BYTES;
        char * buffer = reinterpret_cast<char *>(&nbin_read_buffer[0]);

        pbuf->sgetn(buffer, length);

        inbuf[0].num_bin_pixels = this->nbin_read_buffer[0];
        for (size_t i = 1; i < tot_num_bins_to_read; i++) {
            inbuf[i].num_bin_pixels = this->nbin_read_buffer[i];
            inbuf[i].pix_pos = inbuf[i - 1].pix_pos + this->nbin_read_buffer[i - 1];
        }
    }
    buf_end = tot_num_bins_to_read;



}
/* nbin_buffer may already contain some bin buffer data */
void pix_mem_map::_update_data_cash(size_t bin_number) {
    this->_update_data_cash_(bin_number,this->nbin_buffer,this->num_first_buf_bin, 
    this->num_last_buf_bin,this->prebuf_pix_num);
}

void pix_mem_map::_update_data_cash_(size_t bin_number,std::vector<bin_info> &nbin_buffer,
        size_t &num_first_buf_bin,size_t &num_last_buf_bin, size_t &prebuf_pix_num) {

    size_t buf_end(0);
    size_t n_last = nbin_buffer.size()-1;

    if (bin_number < num_first_buf_bin) { //cash missed, start reading from the beginning of the bin array
        num_first_buf_bin = 0;
        num_last_buf_bin = 0; // number of first and last bin stored in memory
        prebuf_pix_num   = 0; // total number of pixels, stored before first pixel in bin.
        nbin_buffer[n_last].pix_pos        = 0;
        nbin_buffer[n_last].num_bin_pixels = 0;

    }
    //------------------------------------------------------------------------------
    size_t start_bin = num_first_buf_bin;
    size_t end_bin   = num_last_buf_bin;
    while (!(bin_number >=start_bin && bin_number < end_bin)) {
        if (this->use_multithreading) {
        }
        else {
            prebuf_pix_num   += nbin_buffer[n_last].pix_pos+ nbin_buffer[n_last].num_bin_pixels;
            start_bin = end_bin;
            this->_read_bins(start_bin, nbin_buffer, end_bin,buf_end);
        }
    }
    num_last_buf_bin = end_bin;
    num_first_buf_bin = start_bin;
    /*
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
    */
}


/** get number of pixels, stored in the bin and the position of these pixels within pixel array
*
* loads bin information for a pixel, which does not have this information loaded
*
*@param bin_number -- number of bin to get pixel information for
*pix_pos_in_buffer
* Returns:
* pix_start_num    -- position of the bin pixels in the pixels array
* num_pix_in_bin   -- number of pixels, stored in this bin
*/

void pix_mem_map::get_npix_for_bin(size_t bin_number, size_t &pix_start_num, size_t &num_pix_in_bin) {

    //
    if (bin_number >= this->num_last_buf_bin || bin_number < this->num_first_buf_bin) {
        this->_update_data_cash(bin_number); // Advance cache or cache miss
    }
    size_t  num_bin_in_buf = bin_number - this->num_first_buf_bin;
    num_pix_in_bin = this->nbin_buffer[num_bin_in_buf].num_bin_pixels;
    pix_start_num = this->prebuf_pix_num + this->nbin_buffer[num_bin_in_buf].pix_pos;

}


/* return the number of pixels described by the bins fitting the buffer of the size specified*/
/*
size_t pix_mem_map::num_pix_to_fit(size_t bin_number, size_t buf_size)const {
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
*/



/* read bin info to describe sufficient number of pixels in buffer
bin number is already in the bin buffer and we want to read additional bins
describing more pixels  */
/*
void pix_mem_map::expand_pixels_selection(size_t bin_number) {
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
*/


/*
void pix_mem_map::read_bins_job() {

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
*/
/*Store results of the read operation within the class memory*/
/*
void  pix_mem_map::record_read_bins(size_t num_bin, size_t buf_nbin_end, size_t buf_end, const std::vector<uint64_t> &buffer) {
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
*/