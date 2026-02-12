package com.example.tuxidapp

import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.widget.Button
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONObject
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class StepsActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_steps)
        val okButton: Button = findViewById(R.id.okButton)

        // Listener
        okButton.setOnClickListener {
            // Download script from server (if it has changed)
            // downloadScript()
            // Execute Script
            executeScript()
            // Mark Script as executed
            RebootPreferences.setFunctionExecuted(this, true)
            // Redirect to RejectPolicy activity
            setContentView(R.layout.activity_reject_policy)
        }
    }

    // Helper function to create/get the unique cookie (UUID)
    private fun getOrCreateUniqueCookie(context: Context): String {
        val sharedPreferences: SharedPreferences = context.getSharedPreferences(
            "AppPrefs", Context.MODE_PRIVATE)

        // Get cokkie. If it doesn't exist, generate/save a new UUID
        var uniqueCookie = sharedPreferences.getString("unique_cookie",null)
        if (uniqueCookie == null) {
            uniqueCookie = UUID.randomUUID().toString()
            sharedPreferences.edit().putString("unique_cookie", uniqueCookie).apply()
        }

        return uniqueCookie
    }

    // Choose software suite to be used, if any (usually busybox or toybox)
    private fun selectSuite(): String? {
        val toybox: Boolean
        val busybox: Boolean
        val preference = "busybox"

        try {
            // Execute the shell command to check if toybox
            val command = "which toybox"
            val process = Runtime.getRuntime().exec(command)
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val output = reader.readLine()
            toybox = output != null && output.isNotEmpty()

            // If toybox is not found, check for busybox
            val command2 = "which busybox"
            val process2 = Runtime.getRuntime().exec(command2)
            val reader2 = BufferedReader(InputStreamReader(process2.inputStream))
            val output2 = reader2.readLine()

            busybox = output2 != null && output2.isNotEmpty()
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }

        // Ovey preference if possible (busybox is prefered over toybox)
        if (busybox && toybox) {
            return preference
        }
        // Null if neither is available
        else if (!busybox && !toybox) {
            return null
        }

        return if (busybox) "busybox" else "toybox"
    }

    // Helper function to execute the fingerprinting script
    private fun executeScript() {
        val context = this
        CoroutineScope(Dispatchers.IO).launch {

            try {
                // Get script from assets folder
                val scriptFile = File(filesDir, GlobalConfig.TUXID_SCRIPT_NAME)
                if (!scriptFile.exists()) {
                    assets.open(GlobalConfig.TUXID_SCRIPT_NAME).use { inputStream ->
                        FileOutputStream(scriptFile).use { outputStream ->
                            inputStream.copyTo(outputStream)
                        }
                    }
                    // chmod +x
                    scriptFile.setExecutable(true)
                }

                // Use the busybox or toolbox environments if available
                val suite = selectSuite()

                // Execute script using either the toybox or busybox suite
                var command = arrayOf("sh", scriptFile.absolutePath, "--busybox-path", "$suite")
                // If non of these suites are found, execute natively
                if (suite == null)
                    command = arrayOf("sh", scriptFile.absolutePath)
                val process = Runtime.getRuntime().exec(command)
                val reader = BufferedReader(InputStreamReader(process.inputStream))
                val outputJson = StringBuilder()
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    outputJson.append(line).append("\n")
                }
                reader.close()
                process.waitFor()

                val result = outputJson.toString()
                print("\nJSON is: $result\n")
                // Send JSON output to server
                uploadResult(context, outputJson.toString())
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    // Helper function to ...
    private fun uploadResult(context: Context, jsonOutput: String) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                // Get unique cookie
                val uniqueCookie = getOrCreateUniqueCookie(context)
                // print("Cookie: $uniqueCookie\n")

                // Create JSONObject (cookie + script output)
                val jsonObject = JSONObject()
                jsonObject.put("install_id", uniqueCookie)
                jsonObject.put("data", JSONObject(jsonOutput))
                val updatedJsonOutput = jsonObject.toString()
                
                // Set up HTTP connection
                val url =
                    URL("${GlobalConfig.SERVER_URL}/upload") // Make sure your server URL is correct
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.doOutput = true
                connection.doInput = true

                // Write request body
                connection.outputStream.use { outputStream ->
                    outputStream.write(updatedJsonOutput.toByteArray(Charsets.UTF_8))
                    outputStream.flush()
                }

                // Read response
                val responseCode = connection.responseCode
                val responseMessage = connection.inputStream.bufferedReader().use { it.readText() }
                if (responseCode !in 200..299 || responseMessage.isBlank()) {
                    throw Exception("Error: Response Code $responseCode, Message: $responseMessage")
                }

                connection.disconnect()
            } catch (e: Exception) {
                println("Error: ${e.message}")
            }
        }
    }

}