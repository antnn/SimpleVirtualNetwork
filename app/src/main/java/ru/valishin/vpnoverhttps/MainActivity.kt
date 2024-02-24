package ru.valishin.vpnoverhttps

import android.content.Context
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
import ru.valishin.nativevpn.NativeVpn
import ru.valishin.nativevpn.R
import ru.valishin.vpnoverhttps.ui.theme.VpnOverHttpsTheme
import java.io.File


class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val n = NativeVpn(applicationInfo, applicationContext)
        val tmp = "$cacheDir/se_tmp"
        val args =Array<String>(1){"start"}
        n.startVpnClient(args)
        setContent {
            VpnOverHttpsTheme {
                // A surface container using the 'background' color from the theme
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    Greeting("Android")
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
    VpnOverHttpsTheme {
        Greeting("Android")
    }
}