#!/bin/bash

# Download latest version of Minecraft Server from Mojang
wget https://piston-data.mojang.com/v1/objects/84194a2f286ef7c14ed7ce0090dba59902951553/server.jar
mv server.jar server-versions/minecraft-server-latest.jar

# Server Configuration
JAR=server-versions/minecraft-server-latest.jar
MAXRAM=4G
MINRAM=2G

# Start Server (will need to accept EULA)
java -Xmx$MAXRAM -Xms$MINRAM -jar $JAR nogui
