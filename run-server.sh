#!/bin/bash

while true; do

    screen
    java -Xms2G -Xmx4G -jar minecraft-server-1.19.2.jar nogui
    echo "Restarting server in 5s..."
    sleep 5s

done