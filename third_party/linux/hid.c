/*
 * HIDAPI - Multi-Platform library for communication with HID devices
 * Copyright 2009-2021 Alan Ott <alan@signal11.us>
 * All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Linux implementation for hidapi 0.15.0
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <wchar.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <linux/hidraw.h>
#include <linux/input.h>
#include <libudev.h>

#include "hidapi/hidapi.h"

struct hid_device_ {
    int device_handle;
    int blocking;
    wchar_t last_error[256];
};

static const struct hid_version kHidVersion = {0, 15, 0};

/* Initialize the hidapi library */
int hid_init(void) {
    return 0;
}

/* Finalize the hidapi library */
int hid_exit(void) {
    return 0;
}

/* Enumerate connected HID devices */
struct hid_device_info *hid_enumerate(unsigned short vendor_id, unsigned short product_id) {
    /* This is a stub implementation for Linux.
     * Production use should:
     * 1. Use libudev to discover hidraw devices
     * 2. Filter by vendor_id and product_id
     * 3. Query device properties using ioctl HIDIOCGINFO
     * 4. Build hid_device_info linked list
     */
    return NULL;
}

/* Free the array of hid_device_info structures */
void hid_free_enumeration(struct hid_device_info *devs) {
    struct hid_device_info *current = devs;
    
    while (current) {
        struct hid_device_info *next = current->next;
        
        free(current->path);
        free(current->serial_number);
        free(current->manufacturer_string);
        free(current->product_string);
        free(current);
        
        current = next;
    }
}

/* Open a device by vendor ID, product ID, and serial number */
hid_device *hid_open(unsigned short vendor_id, unsigned short product_id, const wchar_t *serial_number) {
    struct hid_device_info *devs, *cur_dev;
    const char *path_to_open = NULL;
    
    devs = hid_enumerate(vendor_id, product_id);
    cur_dev = devs;
    
    if (!devs) {
        return NULL;
    }
    
    while (cur_dev) {
        if (cur_dev->vendor_id == vendor_id && cur_dev->product_id == product_id) {
            if (!serial_number || wcscmp(serial_number, cur_dev->serial_number) == 0) {
                path_to_open = cur_dev->path;
                break;
            }
        }
        cur_dev = cur_dev->next;
    }
    
    if (!path_to_open) {
        hid_free_enumeration(devs);
        return NULL;
    }
    
    hid_device *dev = hid_open_path(path_to_open);
    
    hid_free_enumeration(devs);
    
    return dev;
}

/* Open a device by its path name */
hid_device *hid_open_path(const char *path) {
    hid_device *dev = (hid_device *)malloc(sizeof(hid_device));
    
    if (!dev) {
        return NULL;
    }
    
    dev->device_handle = open(path, O_RDWR | O_NONBLOCK);
    
    if (dev->device_handle < 0) {
        free(dev);
        return NULL;
    }
    
    dev->blocking = 1;
    
    return dev;
}

/* Write an Output report to the device */
int hid_write(hid_device *device, const unsigned char *data, size_t length) {
    int write_result;
    
    if (!device || device->device_handle < 0) {
        return -1;
    }
    
    write_result = write(device->device_handle, data, length);
    
    return write_result;
}

/* Read an Input report from the device */
int hid_read(hid_device *device, unsigned char *data, size_t length) {
    ssize_t read_result;
    
    if (!device || device->device_handle < 0) {
        return -1;
    }
    
    read_result = read(device->device_handle, data, length);
    
    return read_result;
}

/* Read an Input report from the device with a timeout */
int hid_read_timeout(hid_device *device, unsigned char *data, size_t length, int milliseconds) {
    if (!device || device->device_handle < 0) {
        return -1;
    }
    
    /* This is a stub. Production implementation would use select() or poll() */
    
    return -1;
}

/* Set the device handle to blocking or non-blocking mode */
int hid_set_nonblocking(hid_device *device, int nonblock) {
    int flags;
    
    if (!device || device->device_handle < 0) {
        return -1;
    }
    
    flags = fcntl(device->device_handle, F_GETFL, 0);
    
    if (nonblock) {
        flags |= O_NONBLOCK;
    } else {
        flags &= ~O_NONBLOCK;
    }
    
    fcntl(device->device_handle, F_SETFL, flags);
    
    device->blocking = !nonblock;
    
    return 0;
}

/* Send a Feature report to the device */
int hid_send_feature_report(hid_device *device, const unsigned char *data, size_t length) {
    int report_result;
    
    if (!device || device->device_handle < 0) {
        return -1;
    }
    
    report_result = ioctl(device->device_handle, HIDIOCSFEATURE(length), data);
    
    return report_result;
}

/* Get a Feature report from the device */
int hid_get_feature_report(hid_device *device, unsigned char *data, size_t length) {
    int report_result;
    
    if (!device || device->device_handle < 0) {
        return -1;
    }
    
    report_result = ioctl(device->device_handle, HIDIOCGFEATURE(length), data);
    
    return report_result;
}

/* Close the HID device */
void hid_close(hid_device *device) {
    if (!device) {
        return;
    }
    
    if (device->device_handle >= 0) {
        close(device->device_handle);
    }
    
    free(device);
}

/* Get the manufacturer string from the device */
int hid_get_manufacturer_string(hid_device *device, wchar_t *string, size_t maxlen) {
    if (!device || device->device_handle < 0) {
        return -1;
    }
    
    if (maxlen > 0) {
        string[0] = L'\0';
    }
    
    return 0;
}

/* Get the product string from the device */
int hid_get_product_string(hid_device *device, wchar_t *string, size_t maxlen) {
    if (!device || device->device_handle < 0) {
        return -1;
    }
    
    if (maxlen > 0) {
        string[0] = L'\0';
    }
    
    return 0;
}

/* Get the serial number from the device */
int hid_get_serial_number_string(hid_device *device, wchar_t *string, size_t maxlen) {
    if (!device || device->device_handle < 0) {
        return -1;
    }
    
    if (maxlen > 0) {
        string[0] = L'\0';
    }
    
    return 0;
}

/* Get an indexed string from the device */
int hid_get_indexed_string(hid_device *device, int string_index, wchar_t *string, size_t maxlen) {
    if (!device || device->device_handle < 0) {
        return -1;
    }
    
    if (maxlen > 0) {
        string[0] = L'\0';
    }
    
    return 0;
}

/* Get the last error string from the device */
const wchar_t *hid_error(hid_device *device) {
    if (device) {
        return device->last_error;
    }
    
    return L"No device";
}

/* Get the report descriptor (hidapi 0.15.0+) */
int hid_get_report_descriptor(hid_device *device, unsigned char *buf, size_t buf_size) {
    if (!device || device->device_handle < 0) {
        return -1;
    }
    
    /* Production: Use HIDIOCGRDESC ioctl to get raw report descriptor */
    
    return 0;
}

/* Get version information (hidapi 0.15.0+) */
const struct hid_version *hid_version(void) {
    return &kHidVersion;
}
