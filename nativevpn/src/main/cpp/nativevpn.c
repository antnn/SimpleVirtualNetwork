#include "nativevpn.h"
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include "global.h"

static inline int entrypoint(int argc, char *argv[]){
    //return VpnClientMain(argc, argv);
}

struct global_data global_data = {0};

static void cleanup_global_data(JNIEnv *env) {
    if (global_data.thiz) {
        (*env)->DeleteGlobalRef(env, global_data.thiz);
    }
    free(global_data.tmp_dir);
    free(global_data.log_dir);
    free(global_data.db_dir);
    memset(&global_data, 0, sizeof(global_data));
}

static jboolean init_globals(char **out, JNIEnv *env, jobject thiz, jstring dir) {
    if (!out || !env || !dir) {
        ERROR_LOG("Invalid parameters in init_globals");
        return JNI_FALSE;
    }

    const char *nativeDir = (*env)->GetStringUTFChars(env, dir, NULL);
    if (!nativeDir) {
        ERROR_LOG("Failed to get native string");
        return JNI_FALSE;
    }

    *out = strdup(nativeDir);
    (*env)->ReleaseStringUTFChars(env, dir, nativeDir);

    if (!*out) {
        ERROR_LOG(MALLOC_ERROR);
        return JNI_FALSE;
    }

    // Store env and create global reference only if not already initialized
    if (!global_data.thiz) {
        global_data.env = env;
        global_data.thiz = (*env)->NewGlobalRef(env, thiz);
        if (!global_data.thiz) {
            ERROR_LOG("Failed to create global reference");
            free(*out);
            *out = NULL;
            return JNI_FALSE;
        }
    }

    return JNI_TRUE;
}

void Java_ru_valishin_nativevpn_NativeVpn_closeFd(JNIEnv *env, jobject thiz, jint fd) {
    if (fd >= 0) {
        close(fd);
    }
}

void Java_ru_valishin_nativevpn_NativeVpn_nativeStartVpnClient(
        JNIEnv *env, jobject thiz, jobjectArray args) {
    if (!args) {
        ERROR_LOG("Null arguments array received");
        return;
    }

    jsize argc = (*env)->GetArrayLength(env, args);
    char **argv = calloc(argc + 1, sizeof(char *));
    if (!argv) {
        ERROR_LOG(MALLOC_ERROR);
        return;
    }

    jint result = -1;
    jboolean success = JNI_TRUE;

    for (jsize i = 0; i < argc && success; i++) {
        jstring arg = (jstring)(*env)->GetObjectArrayElement(env, args, i);
        if (!arg) {
            success = JNI_FALSE;
            break;
        }

        const char *nativeArg = (*env)->GetStringUTFChars(env, arg, NULL);
        if (nativeArg) {
            argv[i] = strdup(nativeArg);
            if (!argv[i]) {
                ERROR_LOG(MALLOC_ERROR);
                success = JNI_FALSE;
            }
            (*env)->ReleaseStringUTFChars(env, arg, nativeArg);
        }
        (*env)->DeleteLocalRef(env, arg);
    }

    if (success) {
        result = entrypoint(argc, argv);
    }

    for (jsize i = 0; i < argc; i++) {
        free(argv[i]);
    }
    free(argv);
}


void Java_ru_valishin_nativevpn_NativeVpn_setLogDir(JNIEnv *env, jobject thiz, jstring dir) {
    init_globals(&global_data.log_dir, env, thiz, dir);
}

void Java_ru_valishin_nativevpn_NativeVpn_setDbDir(JNIEnv *env, jobject thiz, jstring dir) {
    init_globals(&global_data.db_dir, env, thiz, dir);
}




// Add JNI_OnLoad and JNI_OnUnload for proper initialization and cleanup
jint JNI_OnLoad(JavaVM *vm, void *reserved) {
    return JNI_VERSION_1_6;
}

void JNI_OnUnload(JavaVM *vm, void *reserved) {
    JNIEnv *env;
    if ((*vm)->GetEnv(vm, (void **) &env, JNI_VERSION_1_6) == JNI_OK) {
        cleanup_global_data(env);
    }
}

JNIEXPORT void JNICALL
Java_ru_valishin_nativevpn_NativeVpn_setTmpDir(JNIEnv *env, jobject thiz, jstring dir) {
    init_globals(&global_data.tmp_dir, env, thiz, dir);
}