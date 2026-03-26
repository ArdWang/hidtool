/*
 * HIDAPI - Multi-Platform library for communication with HID devices
 * Copyright 2009-2021, Alan Ott <alan@signal11.us>
 * All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Simplified public header used by the Flutter desktop bindings.
 */

#ifndef HIDAPI_H__
#define HIDAPI_H__

#include <stddef.h>
#include <stdint.h>
#include <wchar.h>

#if defined(_WIN32) || defined(__CYGWIN__)
#define HID_API_EXPORT __declspec(dllexport)
#define HID_API_CALL
#elif defined(__GNUC__) && __GNUC__ >= 4
#define HID_API_EXPORT __attribute__((visibility("default")))
#define HID_API_CALL
#else
#define HID_API_EXPORT
#define HID_API_CALL
#endif

#ifdef __cplusplus
extern "C" {
#endif

struct hid_device_;
typedef struct hid_device_ hid_device;

struct hid_device_info {
    char *path;
    unsigned short vendor_id;
    unsigned short product_id;
    wchar_t *serial_number;
    unsigned short release_number;
    wchar_t *manufacturer_string;
    wchar_t *product_string;
    unsigned short usage_page;
    unsigned short usage;
    int interface_number;
    int bus_type;
    struct hid_device_info *next;
};

#define HID_BUS_TYPE_USB 0
#define HID_BUS_TYPE_BLUETOOTH 1
#define HID_BUS_TYPE_I2C 2
#define HID_BUS_TYPE_SPI 3

struct hid_version {
    int major;
    int minor;
    int patch;
};

HID_API_EXPORT int HID_API_CALL hid_init(void);
HID_API_EXPORT int HID_API_CALL hid_exit(void);
HID_API_EXPORT struct hid_device_info * HID_API_CALL hid_enumerate(
    unsigned short vendor_id,
    unsigned short product_id
);
HID_API_EXPORT void HID_API_CALL hid_free_enumeration(struct hid_device_info *devs);
HID_API_EXPORT hid_device * HID_API_CALL hid_open(
    unsigned short vendor_id,
    unsigned short product_id,
    const wchar_t *serial_number
);
HID_API_EXPORT hid_device * HID_API_CALL hid_open_path(const char *path);
HID_API_EXPORT int HID_API_CALL hid_write(
    hid_device *device,
    const unsigned char *data,
    size_t length
);
HID_API_EXPORT int HID_API_CALL hid_read(
    hid_device *device,
    unsigned char *data,
    size_t length
);
HID_API_EXPORT int HID_API_CALL hid_read_timeout(
    hid_device *device,
    unsigned char *data,
    size_t length,
    int milliseconds
);
HID_API_EXPORT int HID_API_CALL hid_set_nonblocking(hid_device *device, int nonblock);
HID_API_EXPORT int HID_API_CALL hid_send_feature_report(
    hid_device *device,
    const unsigned char *data,
    size_t length
);
HID_API_EXPORT int HID_API_CALL hid_get_feature_report(
    hid_device *device,
    unsigned char *data,
    size_t length
);
HID_API_EXPORT void HID_API_CALL hid_close(hid_device *device);
HID_API_EXPORT int HID_API_CALL hid_get_manufacturer_string(
    hid_device *device,
    wchar_t *string,
    size_t maxlen
);
HID_API_EXPORT int HID_API_CALL hid_get_product_string(
    hid_device *device,
    wchar_t *string,
    size_t maxlen
);
HID_API_EXPORT int HID_API_CALL hid_get_serial_number_string(
    hid_device *device,
    wchar_t *string,
    size_t maxlen
);
HID_API_EXPORT int HID_API_CALL hid_get_indexed_string(
    hid_device *device,
    int string_index,
    wchar_t *string,
    size_t maxlen
);
HID_API_EXPORT const wchar_t * HID_API_CALL hid_error(hid_device *device);
HID_API_EXPORT int HID_API_CALL hid_get_report_descriptor(
    hid_device *device,
    unsigned char *buf,
    size_t buf_size
);
HID_API_EXPORT const struct hid_version * HID_API_CALL hid_version(void);

#ifdef __cplusplus
}
#endif

#endif /* HIDAPI_H__ */
