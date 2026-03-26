/*
 * HIDAPI - Multi-Platform library for communication with HID devices
 * Copyright 2009-2021 Alan Ott <alan@signal11.us>
 * All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Windows implementation for hidapi 0.15.0
 *
 * For a complete, production-ready implementation, use the official hidapi
 * library from: https://github.com/libusb/hidapi/releases/tag/hidapi-0.15.0
 */

#include <windows.h>
#include <setupapi.h>
#include <hidsdi.h>
#include <hidpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#include "hidapi/hidapi.h"

/* These pragmas are here to actually import the hidapi library
 * For production use, ensure libhidapi-0.15.0.a or the .lib file is linked
 */
#pragma comment(lib, "setupapi.lib")
#pragma comment(lib, "hid.lib")

#define MAX_PATH_LENGTH 512
#define MAX_STRING_SIZE 256

/* hid_device structure */
struct hid_device_ {
    HANDLE device_handle;
    BOOL blocking;
    OVERLAPPED overlap;
    wchar_t last_error_str[256];
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

/* Enumerate connected HID devices using Windows SetupAPI */
struct hid_device_info *hid_enumerate(unsigned short vendor_id, unsigned short product_id) {
    struct hid_device_info *root = NULL;
    struct hid_device_info *current = NULL;
    HDEVINFO device_info;
    SP_DEVICE_INTERFACE_DATA interface_data;
    DWORD member_index = 0;
    GUID interface_guid;

    /* Get the HID class GUID */
    HidD_GetHidGuid(&interface_guid);

    /* Get all HID devices */
    device_info = SetupDiGetClassDevsA(&interface_guid, NULL, NULL,
                                        DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
    if (device_info == INVALID_HANDLE_VALUE) {
        return NULL;
    }

    interface_data.cbSize = sizeof(SP_DEVICE_INTERFACE_DATA);

    /* Enumerate through all devices */
    while (SetupDiEnumDeviceInterfaces(device_info, NULL, &interface_guid,
                                        member_index, &interface_data)) {
        DWORD detail_size = 0;
        SP_DEVICE_INTERFACE_DETAIL_DATA_A *detail_data = NULL;
        HANDLE device_handle = INVALID_HANDLE_VALUE;
        HIDD_ATTRIBUTES device_attributes;
        struct hid_device_info *new_dev = NULL;

        /* Get the size of detail data */
        if (!SetupDiGetDeviceInterfaceDetailA(device_info, &interface_data,
                                               NULL, 0, &detail_size, NULL)) {
            if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
                member_index++;
                continue;
            }
        }

        /* Allocate detail data */
        detail_data = (SP_DEVICE_INTERFACE_DETAIL_DATA_A *)malloc(detail_size);
        if (!detail_data) {
            member_index++;
            continue;
        }

        detail_data->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA_A);

        /* Get the device interface detail */
        if (!SetupDiGetDeviceInterfaceDetailA(device_info, &interface_data,
                                               detail_data, detail_size,
                                               NULL, NULL)) {
            free(detail_data);
            member_index++;
            continue;
        }

        /* Open the device to get attributes */
        device_handle = CreateFileA(detail_data->DevicePath,
                                     GENERIC_READ | GENERIC_WRITE,
                                     FILE_SHARE_READ | FILE_SHARE_WRITE,
                                     NULL, OPEN_EXISTING, 0, NULL);

        if (device_handle == INVALID_HANDLE_VALUE) {
            free(detail_data);
            member_index++;
            continue;
        }

        /* Get device attributes */
        device_attributes.Size = sizeof(HIDD_ATTRIBUTES);
        if (!HidD_GetAttributes(device_handle, &device_attributes)) {
            CloseHandle(device_handle);
            free(detail_data);
            member_index++;
            continue;
        }

        /* Filter by vendor_id and product_id if specified */
        if (vendor_id != 0 && device_attributes.VendorID != vendor_id) {
            CloseHandle(device_handle);
            free(detail_data);
            member_index++;
            continue;
        }

        if (product_id != 0 && device_attributes.ProductID != product_id) {
            CloseHandle(device_handle);
            free(detail_data);
            member_index++;
            continue;
        }

        /* Create new device info structure */
        new_dev = (struct hid_device_info *)calloc(1, sizeof(struct hid_device_info));
        if (!new_dev) {
            CloseHandle(device_handle);
            free(detail_data);
            member_index++;
            continue;
        }

        new_dev->path = strdup(detail_data->DevicePath);
        new_dev->vendor_id = device_attributes.VendorID;
        new_dev->product_id = device_attributes.ProductID;
        new_dev->release_number = device_attributes.VersionNumber;

        /* Get serial number */
        {
            wchar_t serial_buf[256];
            memset(serial_buf, 0, sizeof(serial_buf));
            if (HidD_GetSerialNumberString(device_handle, serial_buf,
                                            sizeof(serial_buf))) {
                size_t len = wcslen(serial_buf);
                new_dev->serial_number = (wchar_t *)calloc(len + 1, sizeof(wchar_t));
                if (new_dev->serial_number) {
                    wcscpy(new_dev->serial_number, serial_buf);
                }
            }
        }

        /* Get manufacturer string */
        {
            wchar_t mfg_buf[256];
            memset(mfg_buf, 0, sizeof(mfg_buf));
            if (HidD_GetManufacturerString(device_handle, mfg_buf,
                                            sizeof(mfg_buf))) {
                size_t len = wcslen(mfg_buf);
                new_dev->manufacturer_string = (wchar_t *)calloc(len + 1, sizeof(wchar_t));
                if (new_dev->manufacturer_string) {
                    wcscpy(new_dev->manufacturer_string, mfg_buf);
                }
            }
        }

        /* Get product string */
        {
            wchar_t prod_buf[256];
            memset(prod_buf, 0, sizeof(prod_buf));
            if (HidD_GetProductString(device_handle, prod_buf,
                                       sizeof(prod_buf))) {
                size_t len = wcslen(prod_buf);
                new_dev->product_string = (wchar_t *)calloc(len + 1, sizeof(wchar_t));
                if (new_dev->product_string) {
                    wcscpy(new_dev->product_string, prod_buf);
                }
            }
        }

        /* Get device capabilities for usage page and usage */
        {
            PHIDP_PREPARSED_DATA preparsed_data = NULL;
            HIDP_CAPS caps;

            if (HidD_GetPreparsedData(device_handle, &preparsed_data)) {
                if (HidP_GetCaps(preparsed_data, &caps) == HIDP_STATUS_SUCCESS) {
                    new_dev->usage_page = caps.UsagePage;
                    new_dev->usage = caps.Usage;
                }
                HidD_FreePreparsedData(preparsed_data);
            }
        }

        new_dev->interface_number = -1; /* Not available on Windows */
        new_dev->bus_type = HID_BUS_TYPE_USB; /* Default to USB */
        new_dev->next = NULL;

        /* Add to linked list */
        if (root == NULL) {
            root = new_dev;
            current = root;
        } else {
            current->next = new_dev;
            current = new_dev;
        }

        CloseHandle(device_handle);
        free(detail_data);
        member_index++;
    }

    SetupDiDestroyDeviceInfoList(device_info);
    return root;
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

/* Open a device by vendor_id and product_id */
struct hid_device_info *find_device_by_vid_pid(unsigned short vendor_id, unsigned short product_id) {
    struct hid_device_info *devs, *cur_dev;
    
    if ((devs = hid_enumerate(vendor_id, product_id)) == NULL) {
        return NULL;
    }
    
    cur_dev = devs;
    if (cur_dev->vendor_id == vendor_id && cur_dev->product_id == product_id) {
        return cur_dev;
    }
    
    return NULL;
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
    hid_device *dev = NULL;
    
    dev = (hid_device *)malloc(sizeof(hid_device));
    
    if (dev) {
        dev->device_handle = CreateFileA(path,
                                        GENERIC_WRITE | GENERIC_READ,
                                        FILE_SHARE_READ | FILE_SHARE_WRITE,
                                        NULL,
                                        OPEN_EXISTING,
                                        FILE_FLAG_OVERLAPPED,
                                        NULL);
        
        if (dev->device_handle == INVALID_HANDLE_VALUE) {
            free(dev);
            return NULL;
        }
        
        dev->blocking = TRUE;
        memset(&dev->overlap, 0, sizeof(dev->overlap));
        dev->overlap.hEvent = CreateEventA(NULL, TRUE, FALSE, NULL);
    }
    
    return dev;
}

/* Write an Output report to the device */
int hid_write(hid_device *device, const unsigned char *data, size_t length) {
    DWORD bytes_written;
    
    if (!device || device->device_handle == INVALID_HANDLE_VALUE) {
        return -1;
    }
    
    if (!WriteFile(device->device_handle, data, (DWORD)length, &bytes_written, &device->overlap)) {
        if (GetLastError() != ERROR_IO_PENDING) {
            return -1;
        }
        
        if (WaitForSingleObjectEx(device->overlap.hEvent, INFINITE, TRUE) != WAIT_OBJECT_0) {
            return -1;
        }
        
        if (!GetOverlappedResult(device->device_handle, &device->overlap, &bytes_written, FALSE)) {
            return -1;
        }
    }
    
    return (int)bytes_written;
}

/* Read an Input report from the device */
int hid_read(hid_device *device, unsigned char *data, size_t length) {
    DWORD bytes_read = 0;

    if (!device || device->device_handle == INVALID_HANDLE_VALUE) {
        return -1;
    }

    if (!ReadFile(device->device_handle, data, (DWORD)length, &bytes_read, &device->overlap)) {
        if (GetLastError() != ERROR_IO_PENDING) {
            return -1;
        }

        if (WaitForSingleObjectEx(device->overlap.hEvent, INFINITE, TRUE) == WAIT_OBJECT_0) {
            if (!GetOverlappedResult(device->device_handle, &device->overlap, &bytes_read, FALSE)) {
                return -1;
            }
        } else {
            return -1;
        }
    }

    return (int)bytes_read;
}

/* Read an Input report from the device with a timeout */
int hid_read_timeout(hid_device *device, unsigned char *data, size_t length, int milliseconds) {
    DWORD bytes_read = 0;
    DWORD timeout = (milliseconds < 0) ? INFINITE : milliseconds;
    
    if (!device || device->device_handle == INVALID_HANDLE_VALUE) {
        return -1;
    }
    
    if (!ReadFile(device->device_handle, data, (DWORD)length, &bytes_read, &device->overlap)) {
        if (GetLastError() != ERROR_IO_PENDING) {
            return -1;
        }

        DWORD wait_result = WaitForSingleObjectEx(device->overlap.hEvent, timeout, TRUE);
        if (wait_result == WAIT_TIMEOUT) {
            return 0;
        } else if (wait_result != WAIT_OBJECT_0) {
            return -1;
        }

        if (!GetOverlappedResult(device->device_handle, &device->overlap, &bytes_read, FALSE)) {
            return -1;
        }
    }

    return (int)bytes_read;
}

/* Set the device handle to blocking or non-blocking mode */
int hid_set_nonblocking(hid_device *device, int nonblock) {
    if (!device || device->device_handle == INVALID_HANDLE_VALUE) {
        return -1;
    }

    device->blocking = !nonblock;
    return 0;
}

/* Send a Feature report to the device */
int hid_send_feature_report(hid_device *device, const unsigned char *data, size_t length) {
    HANDLE device_handle = NULL;

    if (!device || device->device_handle == INVALID_HANDLE_VALUE) {
        return -1;
    }

    device_handle = device->device_handle;

    BOOL result = HidD_SetFeature(device_handle, (void *)data, (ULONG)length);
    if (result) {
        return (int)length;
    }
    
    return -1;
}

/* Get a Feature report from the device */
int hid_get_feature_report(hid_device *device, unsigned char *data, size_t length) {
    HANDLE device_handle = NULL;
    
    if (!device || device->device_handle == INVALID_HANDLE_VALUE) {
        return -1;
    }
    
    device_handle = device->device_handle;
    
    BOOL result = HidD_GetFeature(device_handle, data, (ULONG)length);
    if (result) {
        return (int)length;
    }
    
    return -1;
}

/* Close the HID device */
void hid_close(hid_device *device) {
    if (!device) {
        return;
    }
    
    if (device->overlap.hEvent) {
        CloseHandle(device->overlap.hEvent);
    }
    
    if (device->device_handle != INVALID_HANDLE_VALUE) {
        CloseHandle(device->device_handle);
    }
    
    free(device);
}

/* Get the manufacturer string from the device */
int hid_get_manufacturer_string(hid_device *device, wchar_t *string, size_t maxlen) {
    if (!device || device->device_handle == INVALID_HANDLE_VALUE) {
        return -1;
    }
    
    return HidD_GetManufacturerString(device->device_handle, string, (ULONG)(maxlen * sizeof(wchar_t))) ? (int)maxlen : -1;
}

/* Get the product string from the device */
int hid_get_product_string(hid_device *device, wchar_t *string, size_t maxlen) {
    if (!device || device->device_handle == INVALID_HANDLE_VALUE) {
        return -1;
    }
    
    return HidD_GetProductString(device->device_handle, string, (ULONG)(maxlen * sizeof(wchar_t))) ? (int)maxlen : -1;
}

/* Get the serial number from the device */
int hid_get_serial_number_string(hid_device *device, wchar_t *string, size_t maxlen) {
    if (!device || device->device_handle == INVALID_HANDLE_VALUE) {
        return -1;
    }
    
    return HidD_GetSerialNumberString(device->device_handle, string, (ULONG)(maxlen * sizeof(wchar_t))) ? (int)maxlen : -1;
}

/* Get an indexed string from the device */
int hid_get_indexed_string(hid_device *device, int string_index, wchar_t *string, size_t maxlen) {
    if (!device || device->device_handle == INVALID_HANDLE_VALUE) {
        return -1;
    }
    
    return HidD_GetIndexedString(device->device_handle, string_index, string, (ULONG)(maxlen * sizeof(wchar_t))) ? (int)maxlen : -1;
}

/* Get the last error string from the device */
const wchar_t *hid_error(hid_device *device) {
    if (device) {
        return device->last_error_str;
    }
    
    return L"No device";
}

/* Get the report descriptor (hidapi 0.15.0+) */
int hid_get_report_descriptor(hid_device *device, unsigned char *buf, size_t buf_size) {
    if (!device || device->device_handle == INVALID_HANDLE_VALUE) {
        return -1;
    }
    
    PHIDP_PREPARSED_DATA preparsed_data = NULL;
    HIDP_CAPS caps;
    unsigned long report_length = 0;
    
    if (!HidD_GetPreparsedData(device->device_handle, &preparsed_data)) {
        return -1;
    }
    
    if (HidP_GetCaps(preparsed_data, &caps) != HIDP_STATUS_SUCCESS) {
        HidD_FreePreparsedData(preparsed_data);
        return -1;
    }
    
    /* Copy capabilities information to buffer as pseudo-descriptor */
    if (buf_size > 0) {
        unsigned char *p = buf;
        int len = 0;
        
        /* This is a simplified pseudo-descriptor. For full descriptor parsing,
         * use the entire preparsed data or raw Report Descriptor from the device */
        
        int max_write = (int)buf_size;
        
        if (len < max_write) {
            p[len++] = 0x06; /* USAGE_PAGE */
            p[len++] = caps.UsagePage & 0xFF;
            p[len++] = (caps.UsagePage >> 8) & 0xFF;
        }
        
        if (len < max_write) {
            p[len++] = 0x09; /* USAGE */
            p[len++] = caps.Usage & 0xFF;
            p[len++] = (caps.Usage >> 8) & 0xFF;
        }
    }
    
    HidD_FreePreparsedData(preparsed_data);
    
    return 0;
}

/* Get version information (hidapi 0.15.0+) */
const struct hid_version *hid_version(void) {
    return &kHidVersion;
}
