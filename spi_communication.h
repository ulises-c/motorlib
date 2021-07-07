#pragma once

#include "communication.h"

class SPICommunication : public CommunicationBase {
 public:
    SPICommunication(SPIDevice &spi) : spi_(spi) {}
    int receive_data(ReceiveData * const data) {
      return spi_.receive_data(2, (uint8_t *const) data, sizeof(*data));
    }
    void send_data(const SendData &data) {
       spi_.send_data(2, reinterpret_cast<const uint8_t *>(&data), sizeof(SendData), false);
    }
    int receive_string(char * const string) {
       int count = spi_.receive_data(1, (uint8_t * const) string, 64);
       string[count] = 0;
       return count;
    }
    bool send_string(const char * const string, uint8_t length) {
       if (!spi_.tx_active(1)) {
         spi_.send_data(1, (const uint8_t * const) string, length, false);
         return true;
       }
       return false;
    }
    bool new_rx_data() { return spi_.new_rx_data(1) || spi_.new_rx_data(2); }
 private:
    SPIDevice &spi_;
    friend class System;
};

