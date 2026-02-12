package com.example.tuxidapp

import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Bundle
import android.widget.Button
import androidx.appcompat.app.AppCompatActivity

object GlobalConfig {
    const val TUXID_SCRIPT_NAME = "tuxid.sh"
    const val SERVER_URL = "https://public-domain.com"
}

class MainActivity : AppCompatActivity() {

    @Override
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Don't continue if no Internet connection available
        if (!isNetworkAvailable(this)) {
            val intent = Intent(this, NoInternetActivity::class.java)
            startActivity(intent)
        } else {
            setContentView(R.layout.activity_main)
        }

        // 'I Agree' button
        val agreeButton: Button = findViewById(R.id.agreeButton)
        agreeButton.setOnClickListener {
            // Internet connection needed
            if (!isNetworkAvailable(this)) {
                val intent = Intent(this, NoInternetActivity::class.java)
                startActivity(intent)
                return@setOnClickListener
            }

            // Only one execution per boot
            if (!RebootPreferences.hasFunctionExecuted(this)) {
                // Start the StepsActivity to display next steps
                val intent = Intent(this, StepsActivity::class.java)
                startActivity(intent)
            } else {
                // Inform the user that a Reboot is needed
                val intent = Intent(this, RebootPolicyActivity::class.java)
                startActivity(intent)
            }
        }

        // 'I Disagree' button
        val disagreeButton: Button = findViewById(R.id.disagreeButton)
        disagreeButton.setOnClickListener {
            val intent = Intent(this, RejectPolicy::class.java)
            startActivity(intent)
        }
    }

    private fun isNetworkAvailable(context: Context): Boolean {
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val activeNetwork: Network? = connectivityManager.activeNetwork
        val networkCapabilities = connectivityManager.getNetworkCapabilities(activeNetwork)
        return networkCapabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
    }

}
