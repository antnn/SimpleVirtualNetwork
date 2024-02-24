package ru.valishin.nativevpn

import android.content.Context
import android.content.pm.ApplicationInfo
import java.io.File

class NativeVpn(applicationInfo: ApplicationInfo, context: Context) {
    private var executablePath: String =""
    init {
        val nativeLibsPath = applicationInfo.nativeLibraryDir
        executablePath = "$nativeLibsPath/libnativevpn.so"
        val cacheDir = context.cacheDir.absolutePath
        val filesDir = context.filesDir.absolutePath
        val tmp = "$cacheDir/se_tmp"
        setTmpDir(tmp)
        setLogDir(tmp)
        setDbDir("$filesDir/se_db")
        copyHamcore(context, tmp)
    }
    private fun copyHamcore(context: Context, tmp: String) {
        File(tmp).mkdirs()
        val inputStream = context.resources.openRawResource(R.raw.hamcore)
        val outputFile = File(tmp, "hamcore.se2.so")
        outputFile.createNewFile()
        outputFile.outputStream().use { outputStream ->
            inputStream.copyTo(outputStream)
        }

    }
    external fun closeFd(fd: Int)
    private external fun setTmpDir(dir: String)
    private external fun setLogDir(dir: String)
    private external fun setDbDir(dir: String)
    private external fun nativeStartVpnClient(args: Array<String>)
    fun startVpnClient() {
        val first = Array<String>(1) { executablePath }
        nativeStartVpnClient(first)
    }
    fun startVpnClient(args: Array<String>) {
        val first = Array<String>(1) { executablePath }
        val combined = first + args
        nativeStartVpnClient(combined)
    }

    companion object {
        // Used to load the 'nativevpn' library on application startup.
        init {
            System.loadLibrary("nativevpn")
        }
    }
}