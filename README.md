# Casually Chaotic Minecraft Server

Helpful guide can be found [here](https://www.digitalocean.com/community/tutorials/how-to-create-a-minecraft-server-on-ubuntu-20-04)

## Installation

```
sudo apt update
```

1. Instal Java

```
sudo apt install openjdk-16-jre-headless
```

2. Install screen

```
sudo apt install screen
```

3. Configure firewall stuff

```
sudo ufw allow 25565
```

4. Instal latest version of minecraft [server.jar](https://www.minecraft.net/en-us/download/server/)

```
wget <install link>
```

5. Rename the .jar file if you like

```
mv server.jar minecraft-server-x.x.x.jar
```

## Configure and Run

1. Run ```screen``` to open up a new terminal

2. Launch minecraft server

```
java -Xms2G -Xmx4G -jar minecraft-server-x.x.x.jar nogui
```

3. Safely exit the terminal with ```Ctrl + A + D```

4. Reconnect to the terminal using screen

```
screen -list
screen -r <process number>
```
