#ifndef ANDROID_UTIL_H
#define ANDROID_UTIL_H
#include <stdlib.h>

extern void __attribute__((weak)) AndroidLog(char* message) {}
extern void __attribute__((weak)) AndroidPause() {
    AndroidLog("ERROR calling ((weak)) AndroidPause");
    exit(-1);
}
extern char* __attribute__((weak)) GetAndroidDbDir(){
    AndroidLog("ERROR calling ((weak)) GetAndroidDbDir");
    exit(-1);
}
extern char* __attribute__((weak)) GetAndroidLogDir(){
    AndroidLog("ERROR calling ((weak)) GetAndroidLogDir");
    exit(-1);
}

extern char* __attribute__((weak)) GetAndroidTmpDir(){
    AndroidLog("ERROR calling ((weak)) GetAndroidTempDir");
    exit(-1);
}
#endif