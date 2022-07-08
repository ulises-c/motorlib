#ifndef ENCODER_H
#define ENCODER_H

#include "sensor.h"

class EncoderBase : public SensorBase {
 public:
    EncoderBase() { }
    bool init() { return false; }
    int32_t read() { return get_value(); }
    int32_t get_value() const { return 0; }
    void trigger() {}
    int32_t get_index_pos() const { return 0; }
    bool index_received() const { return false; }
    int32_t index_error(int32_t cpr) { return 0; }
 private:
};

#endif
