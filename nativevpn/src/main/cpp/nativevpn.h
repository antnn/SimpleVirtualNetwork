//
// Created by a on 19/02/2024.
//

#ifndef SIMPLEVPN_LIBEXECVPNCLIENT_H
#define SIMPLEVPN_LIBEXECVPNCLIENT_H

#include <jni.h>

extern void Java_ru_valishin_libexecvpnclient_SEManager_closeFd(JNIEnv *env,jobject thiz, jint fd);
extern void Java_ru_valishin_libexecvpnclient_SEManager_startVpnClient(JNIEnv *env,jobject thiz,jobjectArray args);
extern int VpnClientMain(int argc, char *argv[]);

#endif //SIMPLEVPN_LIBEXECVPNCLIENT_H



