
# $1 sh256sum
# $2 file
verify() {
	sha256sum -c <(echo "$1" "$2") > /dev/null && echo -n "OK"
}

# $1 url
# $2 dest
# $3 sha256sum
download () {
	if [ ! -f "$2" ] || [ ! "$(verify $3 $2)" == "OK"]; then
		wget "$1" -O "$2"
		[ "$(verify $3 $2)" == "OK" ]  || exit 1
	fi
}
