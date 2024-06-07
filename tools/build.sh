if [ "$1" == "all" ]; then

    scons platform=macos target=template_release
    scons platform=macos target=template_debug

    scons platform=windows target=template_release
    scons platform=windows target=template_debug

    scons platform=web target=template_release
    scons platform=web target=template_debug

    scons platform=android target=template_release arch=arm64
    scons platform=android target=template_debug arch=arm64

elif [ "$1" == "android" ]; then

    scons platform=android target=template_release arch=arm64
    scons platform=android target=template_debug arch=arm64

elif [ "$1" == "macos" ]; then
    
    scons platform=macos target=template_release
    scons platform=macos target=template_debug

elif [ "$1" == "windows" ]; then

    scons platform=windows target=template_release
    scons platform=windows target=template_debug

elif [ "$1" == "web" ]; then

    scons platform=web target=template_release
    scons platform=web target=template_debug

elif [ "$1" == "" ]; then

    echo "No parameter detected. Example : all, android, macos, windows, web"

fi