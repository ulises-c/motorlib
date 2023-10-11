#ifndef UNHUMAN_MOTORLIB_UTIL_H_
#define UNHUMAN_MOTORLIB_UTIL_H_

#include "../st_device.h"
#include "core_cm4.h"
#include <cstring>

#define US_TO_CPU(t_us) (t_us*(CPU_FREQUENCY_HZ/1000000))
extern volatile uint32_t * const cpu_clock;
extern volatile uint32_t uptime;

static inline volatile uint32_t get_clock() { return *cpu_clock; }
static inline uint8_t get_cpi_count() { return DWT->CPICNT; }
static inline uint8_t get_lsu_count() { return DWT->LSUCNT; }
static inline volatile uint32_t get_uptime() { return uptime; }

void ms_delay(uint16_t ms);
void us_delay(uint16_t us);
void ns_delay(uint16_t ns);

extern char _estack;
extern uint32_t _Min_Stack_Size;
inline uint32_t get_stack_free() {
    char *start = &_estack - (uint32_t) &_Min_Stack_Size; 
    char *count = start;
    while(!*count++); // assume zero filled
    return (count - start);
}
inline uint32_t get_stack_used() {
    return (uint32_t) &_Min_Stack_Size - get_stack_free();
}

extern char _end;
extern uint32_t _Min_Heap_Size;
inline uint32_t get_heap_free() {
    char *start = &_end + (uint32_t) &_Min_Heap_Size; 
    char *count = start;
    while(!*count--); // assume zero filled
    return (start - count);
}
inline uint32_t get_heap_used() {
    return (uint32_t) &_Min_Heap_Size - get_heap_free();
}

//void fast_memcpy(void* dest, const void* src, size_t num);

inline void fast_memcpy(void* dest, const void* src, size_t num) {
    int chunks = num >> 6;
    size_t offset = 0;
    for (int i=0; i<(chunks-1); i++) {
        std::memcpy(dest+offset, src+offset, 64);
        offset += 64;
    }
    std::memcpy(dest+offset, src+offset, num-offset);
}

#define wait_while_false(condition) while(!(condition))
#define wait_while_true(condition) while(condition)

// true for success, false for timed out
// gcc syntax
// max timeout 4e9/170 = 23s
#define wait_while_false_with_timeout_us(condition, timeout_us) ({ \
    uint32_t wait_while_false_with_timeout_us_t_start = get_clock(); \
    bool wait_while_false_with_timeout_us_retval; \
    bool wait_while_false_with_timeout_us_timeout; \
    do { \
        wait_while_false_with_timeout_us_retval = condition; \
        wait_while_false_with_timeout_us_timeout = (get_clock() - wait_while_false_with_timeout_us_t_start < timeout_us*(CPU_FREQUENCY_HZ/1000000)); \
    } while( !wait_while_false_with_timeout_us_retval && wait_while_false_with_timeout_us_timeout); \
    wait_while_false_with_timeout_us_retval; });
#define wait_while_true_with_timeout_us(condition, timeout_us) wait_while_false_with_timeout_us(!condition, timeout_us)

#define while_timeout_ms(condition, ms) while((condition) && ((get_clock() - t_start) < ms*CPU_FREQUENCY_HZ/1000))
#define timed_out(ms) ((get_clock() - t_start) > ms*CPU_FREQUENCY_HZ/1000)

#ifdef __cplusplus
#include <string>
#include <vector>
class FrequencyLimiter {
 public:
    FrequencyLimiter(float rate_seconds) {
        t_diff_ = CPU_FREQUENCY_HZ/rate_seconds;
        last_time_ = get_clock();
    }
    // returns true once for each time it is allowed to run
    bool run() {
        uint32_t time = get_clock();
        if (time - last_time_ > t_diff_) {
            last_time_ = time; //todo needs to account for time after t_diff
            return true;
        }
        return false;
    }
    bool ready() const {
        uint32_t time = get_clock();
        if (time - last_time_ > t_diff_) {
            return true;
        }
        return false;
    }
 private:
    uint32_t t_diff_, last_time_;
};

template <typename T, unsigned B>
inline T signextend(const T x)
{
  struct {T x:B;} s;
  return s.x = x;
}

std::vector<char> hex_to_bytes(const std::string& hex);
std::string byte_to_hex(const uint8_t byte);
std::string u16_to_hex(const uint16_t w);
std::string u32_to_hex(const uint32_t w);
std::string bytes_to_hex(const std::vector<char>& bytes);
std::string bytes_to_hex(const std::vector<uint8_t>& bytes);
std::string bytes_to_hex(const uint8_t bytes[], const uint8_t length);

#endif  // __cplusplus
#endif  // UNHUMAN_MOTORLIB_UTIL_H_
