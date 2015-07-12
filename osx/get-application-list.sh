find /Applications -iname *.app -maxdepth 3 | sed -e "s/\/Applications\///" | sed -e "s/.app//"
