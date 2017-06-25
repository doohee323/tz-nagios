#!/bin/bash

foo=`/bin/date | /bin/grep -c UTC`

if [ "${foo}" = "1" -a $? -eq 0 ]; then
        echo "Timezone is UTC"
        exit 0;
else
        foo=`/bin/date +"%Z"`
        echo "Timezone is not UTC: ${foo}"
        exit 2;
fi
