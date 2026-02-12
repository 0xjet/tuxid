# Tuxid Android App
## Usage
- Make sure the backend server is up and running (see web-server/README.md) so it can capture results
- Set Public Domain/IP: modify the SERVER_URL global variable in the MainActivity.Kt file
    ```
    object GlobalConfig {
        ...
        const val SERVER_URL = "htts://public-domain.com"
    }
    ```
- Generate/Build the apk
- Install the generated apk on the desired android device: `adb install app.apk`
- Execute the Application on the device

## Notes
* Android applications require the backend server to have a public IP address. If this
is not the case, it will not be possible to upload the results to the database.
* A software suite (either toybox or busybox) will be used to execute the fingerprinting
script, if they are found on the device, as it generally gives the script the possibility
to capture most signals (if not the script will be executed natively)

