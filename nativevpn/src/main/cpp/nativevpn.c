#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <android/log.h>
#include "nativevpn.h"

/**
 * https://cs.android.com/android/platform/superproject/main/+/main:frameworks/base/core/jni/android_app_NativeActivity.cpp;bpv=1;bpt=1?q=%20loadNativeCode
 * https://cs.android.com/android/platform/superproject/main/+/main:art/libnativeloader/native_loader.cpp;l=246;drc=ec89d38dce79c971ae089a174013f3ee90e41599
 * */


struct global_data {
    char* tmp_dir;
    char* log_dir;
    char* db_dir;
    JNIEnv *env;
    jobject thiz;
};
static struct global_data global_data = {0};

void Java_ru_valishin_nativevpn_NativeVpn_closeFd(JNIEnv *env, jobject thiz, jint fd) {
    close(fd);
}

void Java_ru_valishin_nativevpn_NativeVpn_nativeStartVpnClient(JNIEnv *env,
                                                           jobject thiz,
                                                           jobjectArray args) {

    jsize argc = (*env)->GetArrayLength(env, args);
    char **argv = (char **)malloc(sizeof(char *) * argc+1);

    if (argv == NULL) {
        // Handle memory allocation failure if needed
    }
    for (jsize i = 0; i < argc; i++) {
        jstring arg = (jstring)(*env)->GetObjectArrayElement(env, args, i);
        const char *nativeArg = (*env)->GetStringUTFChars(env, arg, 0);
        argv[i] = strdup(nativeArg);
        (*env)->ReleaseStringUTFChars(env, arg, nativeArg);
        (*env)->DeleteLocalRef(env, arg);
    }
    argv[argc] = NULL;

    jint result = VpnClientMain(argc, argv);

    for (jsize i = 0; i < argc; i++) {
        free(argv[i]);
    }
    free(argv);

    return;
}

extern char * GetAndroidTmpDir(){
    return strdup(global_data.tmp_dir);
}
extern char * GetAndroidLogDir(){
    return strdup(global_data.log_dir);
}
extern char * GetAndroidDbDir(){
    return strdup(global_data.db_dir);
}

extern void AndroidLog(const char* tag, const char* fmt, ...) {
    char newTag[128];
    snprintf(newTag, sizeof(newTag), "NativeVPN: %s", tag);

    va_list args;
    va_start(args, fmt);

    char message[4096];
    vsnprintf(message, sizeof(message), fmt, args);

    __android_log_print(ANDROID_LOG_DEBUG, newTag, "%s", message);

    va_end(args);
}

void signalHandler(int signal) {
    // Handle the signal if needed
}
extern void AndroidPause() {
    signal(SIGUSR1, signalHandler);
    pause();
}

void init_globals(char** out,JNIEnv *env, jobject thiz, jstring dir) {
    const char *nativeDir = (*env)->GetStringUTFChars(env, dir, 0);
    *out = strdup(nativeDir);
    (*env)->ReleaseStringUTFChars(env, dir, nativeDir);
    (*env)->DeleteLocalRef(env, dir);
    global_data.env = env;
    global_data.thiz = thiz;
}

JNIEXPORT void JNICALL
Java_ru_valishin_nativevpn_NativeVpn_setTmpDir(JNIEnv *env, jobject thiz, jstring dir) {
    init_globals(&global_data.tmp_dir,env,thiz,dir);
}

JNIEXPORT void JNICALL
Java_ru_valishin_nativevpn_NativeVpn_setLogDir(JNIEnv *env, jobject thiz, jstring dir) {
    init_globals(&global_data.log_dir,env,thiz,dir);
}
JNIEXPORT void JNICALL
Java_ru_valishin_nativevpn_NativeVpn_setDbDir(JNIEnv *env, jobject thiz, jstring dir) {
    init_globals(&global_data.db_dir,env,thiz,dir);
}
