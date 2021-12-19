#!/bin/bash

7z a \
    -tzip           `# encryption method` \
    -p              `# use password` \
    -mx=0           `# level of compression (not important at all for us)` \
    -mem=AES256     `# encryption method` \
    -mcu=on         `# use UTF-8` \
    $2 $1


