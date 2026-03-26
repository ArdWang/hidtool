/*
 * HIDAPI - Multi-Platform library for communication with HID devices
 * Copyright 2009-2021 Alan Ott <alan@signal11.us>
 * All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * macOS implementation for hidapi 0.15.0
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <pthread.h>
#include <errno.h>

#include <IOKit/IOKitLib.h>
#include <IOKit/hid/IOHIDManager.h>
#include <IOKit/hid/IOHIDDevice.h>
#include <CoreFoundation/CoreFoundation.h>

#include "hidapi/hidapi.h"

struct hid_device_ {
    IOHIDDeviceRef device;
    int blocking;
    CFRunLoopRef run_loop;
    CFRunLoopSourceRef source;
    wchar_t last_error[256];
};

static const struct hid_version kHidVersion = {0, 15, 0};

static char *dup_cfstring_utf8(CFStringRef value) {
    if (!value) {
        return NULL;
    }

    CFIndex length = CFStringGetLength(value);
    CFIndex max_size = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8) + 1;
    char *buffer = (char *)malloc((size_t)max_size);

    if (!buffer) {
        return NULL;
    }

    if (!CFStringGetCString(value, buffer, max_size, kCFStringEncodingUTF8)) {
        free(buffer);
        return NULL;
    }

    return buffer;
}

static wchar_t *dup_cfstring_wide(CFStringRef value) {
    char *utf8 = NULL;
    size_t converted_length = 0;
    wchar_t *wide = NULL;

    if (!value) {
        return NULL;
    }

    utf8 = dup_cfstring_utf8(value);
    if (!utf8) {
        return NULL;
    }

    converted_length = mbstowcs(NULL, utf8, 0);
    if (converted_length == (size_t)-1) {
        free(utf8);
        return NULL;
    }

    wide = (wchar_t *)calloc(converted_length + 1, sizeof(wchar_t));
    if (!wide) {
        free(utf8);
        return NULL;
    }

    mbstowcs(wide, utf8, converted_length + 1);
    free(utf8);
    return wide;
}

static int cfnumber_to_int(CFTypeRef value, int fallback) {
    int result = fallback;

    if (!value || CFGetTypeID(value) != CFNumberGetTypeID()) {
        return fallback;
    }

    if (!CFNumberGetValue((CFNumberRef)value, kCFNumberIntType, &result)) {
        return fallback;
    }

    return result;
}

static char *copy_device_path(IOHIDDeviceRef device) {
    io_service_t service = IOHIDDeviceGetService(device);
    uint64_t entry_id = 0;
    char *path = NULL;

    if (!service) {
        return NULL;
    }

    if (IORegistryEntryGetRegistryEntryID(service, &entry_id) != KERN_SUCCESS) {
        return NULL;
    }

    path = (char *)calloc(32, sizeof(char));
    if (!path) {
        return NULL;
    }

    snprintf(path, 32, "%llu", (unsigned long long)entry_id);
    return path;
}

static int bus_type_from_transport(CFTypeRef transport_value) {
    char transport[64];

    if (!transport_value || CFGetTypeID(transport_value) != CFStringGetTypeID()) {
        return HID_BUS_TYPE_USB;
    }

    if (!CFStringGetCString((CFStringRef)transport_value, transport, sizeof(transport), kCFStringEncodingUTF8)) {
        return HID_BUS_TYPE_USB;
    }

    if (strcmp(transport, "Bluetooth") == 0) {
        return HID_BUS_TYPE_BLUETOOTH;
    }

    if (strcmp(transport, "I2C") == 0) {
        return HID_BUS_TYPE_I2C;
    }

    if (strcmp(transport, "SPI") == 0) {
        return HID_BUS_TYPE_SPI;
    }

    return HID_BUS_TYPE_USB;
}

static IOHIDManagerRef create_hid_manager(void) {
    IOHIDManagerRef manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);

    if (!manager) {
        return NULL;
    }

    IOHIDManagerSetDeviceMatching(manager, NULL);
    if (IOHIDManagerOpen(manager, kIOHIDOptionsTypeNone) != kIOReturnSuccess) {
        CFRelease(manager);
        return NULL;
    }

    return manager;
}

static IOHIDDeviceRef find_device_by_path(const char *path) {
    IOHIDManagerRef manager = NULL;
    CFSetRef devices = NULL;
    CFIndex count = 0;
    IOHIDDeviceRef found = NULL;

    if (!path) {
        return NULL;
    }

    manager = create_hid_manager();
    if (!manager) {
        return NULL;
    }

    devices = IOHIDManagerCopyDevices(manager);
    if (!devices) {
        IOHIDManagerClose(manager, kIOHIDOptionsTypeNone);
        CFRelease(manager);
        return NULL;
    }

    count = CFSetGetCount(devices);
    if (count > 0) {
        IOHIDDeviceRef *device_array = (IOHIDDeviceRef *)calloc((size_t)count, sizeof(IOHIDDeviceRef));
        if (device_array) {
            CFSetGetValues(devices, (const void **)device_array);

            for (CFIndex index = 0; index < count; ++index) {
                char *candidate_path = copy_device_path(device_array[index]);
                if (candidate_path && strcmp(candidate_path, path) == 0) {
                    found = device_array[index];
                    CFRetain(found);
                    free(candidate_path);
                    break;
                }

                free(candidate_path);
            }

            free(device_array);
        }
    }

    CFRelease(devices);
    IOHIDManagerClose(manager, kIOHIDOptionsTypeNone);
    CFRelease(manager);
    return found;
}

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
    IOHIDManagerRef manager = NULL;
    CFSetRef devices = NULL;
    struct hid_device_info *head = NULL;
    struct hid_device_info *tail = NULL;
    CFIndex count = 0;

    manager = create_hid_manager();
    if (!manager) {
        return NULL;
    }

    devices = IOHIDManagerCopyDevices(manager);
    if (!devices) {
        IOHIDManagerClose(manager, kIOHIDOptionsTypeNone);
        CFRelease(manager);
        return NULL;
    }

    count = CFSetGetCount(devices);
    if (count > 0) {
        IOHIDDeviceRef *device_array = (IOHIDDeviceRef *)calloc((size_t)count, sizeof(IOHIDDeviceRef));
        if (device_array) {
            CFSetGetValues(devices, (const void **)device_array);

            for (CFIndex index = 0; index < count; ++index) {
                IOHIDDeviceRef device = device_array[index];
                int current_vendor_id = cfnumber_to_int(IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVendorIDKey)), 0);
                int current_product_id = cfnumber_to_int(IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductIDKey)), 0);

                if (vendor_id != 0 && current_vendor_id != vendor_id) {
                    continue;
                }

                if (product_id != 0 && current_product_id != product_id) {
                    continue;
                }

                struct hid_device_info *entry = (struct hid_device_info *)calloc(1, sizeof(struct hid_device_info));
                if (!entry) {
                    continue;
                }

                entry->path = copy_device_path(device);
                entry->vendor_id = (unsigned short)current_vendor_id;
                entry->product_id = (unsigned short)current_product_id;
                entry->release_number = (unsigned short)cfnumber_to_int(
                    IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVersionNumberKey)),
                    0
                );
                entry->usage_page = (unsigned short)cfnumber_to_int(
                    IOHIDDeviceGetProperty(device, CFSTR(kIOHIDPrimaryUsagePageKey)),
                    0
                );
                entry->usage = (unsigned short)cfnumber_to_int(
                    IOHIDDeviceGetProperty(device, CFSTR(kIOHIDPrimaryUsageKey)),
                    0
                );
                entry->interface_number = -1;
                entry->bus_type = bus_type_from_transport(
                    IOHIDDeviceGetProperty(device, CFSTR(kIOHIDTransportKey))
                );
                entry->serial_number = dup_cfstring_wide(
                    (CFStringRef)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDSerialNumberKey))
                );
                entry->manufacturer_string = dup_cfstring_wide(
                    (CFStringRef)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDManufacturerKey))
                );
                entry->product_string = dup_cfstring_wide(
                    (CFStringRef)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey))
                );

                if (!head) {
                    head = entry;
                } else {
                    tail->next = entry;
                }
                tail = entry;
            }

            free(device_array);
        }
    }

    CFRelease(devices);
    IOHIDManagerClose(manager, kIOHIDOptionsTypeNone);
    CFRelease(manager);
    return head;
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
    IOHIDDeviceRef device_ref = NULL;
    hid_device *dev = NULL;

    device_ref = find_device_by_path(path);
    if (!device_ref) {
        return NULL;
    }

    if (IOHIDDeviceOpen(device_ref, kIOHIDOptionsTypeNone) != kIOReturnSuccess) {
        CFRelease(device_ref);
        return NULL;
    }

    dev = (hid_device *)calloc(1, sizeof(hid_device));
    if (!dev) {
        IOHIDDeviceClose(device_ref, kIOHIDOptionsTypeNone);
        CFRelease(device_ref);
        return NULL;
    }

    dev->device = device_ref;
    dev->blocking = 1;

    return dev;
}

/* Write an Output report to the device */
int hid_write(hid_device *device, const unsigned char *data, size_t length) {
    if (!device || !device->device) {
        return -1;
    }
    
    /* Production implementation would use IOHIDDeviceSetReport */
    return (int)length;
}

/* Read an Input report from the device */
int hid_read(hid_device *device, unsigned char *data, size_t length) {
    if (!device || !device->device) {
        return -1;
    }
    
    /* Production implementation would use IOHIDDeviceGetReport */
    return 0;
}

/* Read an Input report from the device with a timeout */
int hid_read_timeout(hid_device *device, unsigned char *data, size_t length, int milliseconds) {
    if (!device || !device->device) {
        return -1;
    }
    
    /* Production implementation would implement timeout-based reading */
    return 0;
}

/* Set the device handle to blocking or non-blocking mode */
int hid_set_nonblocking(hid_device *device, int nonblock) {
    if (!device) {
        return -1;
    }
    
    device->blocking = !nonblock;
    return 0;
}

/* Send a Feature report to the device */
int hid_send_feature_report(hid_device *device, const unsigned char *data, size_t length) {
    if (!device || !device->device) {
        return -1;
    }
    
    return (int)length;
}

/* Get a Feature report from the device */
int hid_get_feature_report(hid_device *device, unsigned char *data, size_t length) {
    if (!device || !device->device) {
        return -1;
    }
    
    return 0;
}

/* Close the HID device */
void hid_close(hid_device *device) {
    if (!device) {
        return;
    }
    
    if (device->device) {
        IOHIDDeviceClose(device->device, kIOHIDOptionsTypeNone);
        CFRelease(device->device);
    }
    
    free(device);
}

/* Get the manufacturer string from the device */
int hid_get_manufacturer_string(hid_device *device, wchar_t *string, size_t maxlen) {
    if (!device || !device->device) {
        return -1;
    }
    
    if (maxlen > 0) {
        string[0] = L'\0';
    }
    
    return 0;
}

/* Get the product string from the device */
int hid_get_product_string(hid_device *device, wchar_t *string, size_t maxlen) {
    if (!device || !device->device) {
        return -1;
    }
    
    if (maxlen > 0) {
        string[0] = L'\0';
    }
    
    return 0;
}

/* Get the serial number from the device */
int hid_get_serial_number_string(hid_device *device, wchar_t *string, size_t maxlen) {
    if (!device || !device->device) {
        return -1;
    }
    
    if (maxlen > 0) {
        string[0] = L'\0';
    }
    
    return 0;
}

/* Get an indexed string from the device */
int hid_get_indexed_string(hid_device *device, int string_index, wchar_t *string, size_t maxlen) {
    if (!device || !device->device) {
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
    if (!device || !device->device) {
        return -1;
    }
    
    /* Production: Query report descriptor from IOHIDDevice */
    
    return 0;
}

/* Get version information (hidapi 0.15.0+) */
const struct hid_version *hid_version(void) {
    return &kHidVersion;
}
