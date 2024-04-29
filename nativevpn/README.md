```bash

export CMAKE_BIN="$HOME/Android/Sdk/cmake/3.22.1/bin/cmake";
export MODULE_DIR="$HOME/AndroidStudioProjects/VpnOverHttps/nativevpn/src/main/cpp/deps"
$CMAKE_BIN -H"$MODULE_DIR" \
-C "$MODULE_DIR/build_deps.cmake" \
-B "$MODULE_DIR/build"

```
