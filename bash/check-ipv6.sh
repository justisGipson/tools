#!/bin/sh

regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$'
echo -n "$1" | awk '$0 !~ /'"$regex"'/{print "not an ipv6=>"$0;exit 1}'
