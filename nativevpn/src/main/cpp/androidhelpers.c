#include <stdlib.h>
#include <string.h>
#include <android/log.h>
#include <stdarg.h>
#include "include/androidhelpers.h"

#define TAG "NativeVpn"

extern struct global_data global_data;

extern int AndroidLog(const char* format, ...) {
    va_list args;
    va_start(args, format);
    int result = __android_log_vprint(ANDROID_LOG_INFO, TAG, format, args);
    va_end(args);
    return result;
}

/*extern void AndroidPause() {
    // Simple pause implementation
    //pause();
}*/

extern char* GetAndroidDbDir() {
    return global_data.db_dir ? strdup(global_data.db_dir) : NULL;
}

extern char* GetAndroidLogDir() {
    return global_data.log_dir ? strdup(global_data.log_dir) : NULL;
}

extern char* GetAndroidTmpDir() {
    return global_data.tmp_dir ? strdup(global_data.tmp_dir) : NULL;
}
