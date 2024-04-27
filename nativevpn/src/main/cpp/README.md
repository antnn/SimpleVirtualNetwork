 ```bash
 (cd deps;
    bash download.sh
    bash hamcorebuilder.sh
    (cd external;
      git apply ../../softether.patch
    ) 
    bash build_deps.sh
 )
