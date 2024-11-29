```bash
CMAKE_DIR="$HOME/Android/cmake"
LATEST_CMAKE=$(ls -d $CMAKE_DIR/*/ | sort -V | tail -n 1)
CMAKE_BIN="$LATEST_CMAKE/bin/cmake"
PROJECTS_DIR="projects"
PNAME="SimpleVirtualNetwork"
MODULE_NAME="nativevpn"
WORK_DIR="$HOME/$PROJECTS_DIR/$PNAME/$MODULE_NAME/src/main/cpp/deps"

$CMAKE_BIN -H"$WORK_DIR" \
           -C "$WORK_DIR/build_deps.cmake" \
           -B "$WORk_DIR/build"

```
