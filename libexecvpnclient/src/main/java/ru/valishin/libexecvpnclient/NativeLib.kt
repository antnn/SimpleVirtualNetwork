package ru.valishin.libexecvpnclient

class NativeLib {

    /**
     * A native method that is implemented by the 'libexecvpnclient' native library,
     * which is packaged with this application.
     */
    external fun stringFromJNI(): String

    companion object {
        // Used to load the 'libexecvpnclient' library on application startup.
        init {
            System.loadLibrary("libexecvpnclient")
        }
    }
}