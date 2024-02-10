package ru.valishin.simplevpn

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import ru.valishin.simplevpn.ui.theme.SimpleVPNTheme
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        var hello =""
        val m = Thread {
            val nativeLibsPath = applicationInfo.nativeLibraryDir
            val pb = ProcessBuilder("$nativeLibsPath/libsoftethervpnclient.so")
            val f = File("$nativeLibsPath/libsoftethervpnclient.so")
            val env = pb.environment()
            val tmp = "$cacheDir/se_tmp"
            env["SE_TMPDIR"] = tmp
            env["SE_LOGDIR"] = tmp
            env["SE_DBDIR"] = "$filesDir/se_db"

            env["LD_LIBRARY_PATH"] = nativeLibsPath
            env["LD_PRELOAD"] = "$nativeLibsPath/libncurses.so:" +
                    "$nativeLibsPath/libreadline.so:$nativeLibsPath/libform.so"
            val process = pb.start()

            val stdoutThread = Thread {
                val reader = BufferedReader(InputStreamReader(process.inputStream))
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    hello += line
                }
            }
//CANNOT LINK EXECUTABLE "/data/app/~~bTHffYMEOntsj-hvg_Frkg==/ru.valishin.VPN_over_HTTP-vELIlbR40D-pHohGtBcOAQ==/lib/arm64/libexecvpnclient.so": library "libncurses.so.6" not found: needed by main executable
// Read stderr in a separate thread
            val stderrThread = Thread {
                val reader = BufferedReader(InputStreamReader(process.errorStream))
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    System.err.println("stderr: $line")
                }
            }

// Start the threads
            stdoutThread.start()
            stderrThread.start()

// Wait for the process to complete
            val exitCode = process.waitFor()

// Wait for the threads to finish
            stdoutThread.join()
            stderrThread.join()
            println("Process exited with code $exitCode")
        }
        m.start()
        m.join()

        setContent {
            SimpleVPNTheme {
                // A surface container using the 'background' color from the theme
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    Greeting(hello)
                }
            }
        }
    }
}

@Composable
fun Greeting(name: String, modifier: Modifier = Modifier) {
    Text(
        text = "Hello $name!",
        modifier = modifier
    )
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    SimpleVPNTheme {
        Greeting("Android")
    }
}