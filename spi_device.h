#pragma once

class SPIDevice {
 public:
    SPIDevice(SPIDMA &spi) : spi_(spi) {}
    int receive_data(uint8_t address, uint8_t * const data, uint8_t length) {
        spi_.
    }
    void send_data(uint8_t address, const uint8_t * data, uint8_t length);
 private:
    SPIDMA &spi_;
};

