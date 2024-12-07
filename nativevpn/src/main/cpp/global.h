#ifndef MYVPNCLIENTGLOBAL_H
#define MYVPNCLIENTGLOBAL_H

#include <jni.h>

struct global_data {
    char *tmp_dir;
    char *log_dir;
    char *db_dir;
    JNIEnv *env;
    jobject thiz;
};

extern struct global_data global_data;
#define TAG "NativeVpn"

#endif
