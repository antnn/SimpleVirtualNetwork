// helpers.h
#ifndef HELPERS_H
#define HELPERS_H
extern int __attribute__((weak)) AndroidLog(const char* format, ...);
extern void __attribute__((weak)) AndroidPause();
extern char* __attribute__((weak)) GetAndroidDbDir();
extern char* __attribute__((weak)) GetAndroidLogDir();
extern char* __attribute__((weak)) GetAndroidTmpDir();
#endif
