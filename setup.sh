#!/bin/bash

available_server_versions=("1.19.4" "1.20.1")

echo -e "================================================================================"
echo -e " Minecraft Server Setup Script (by Kameron Ronald)"
echo -e "================================================================================\n"
echo -e " Welcome! This script will help you to set up and configure your very own"
echo -e " minecraft server. Please ensure that you run this script with sudo privileges.\n"

read -r -p " Would you like to install required packages: java [y/n]? " install_packages
while [ "$install_packages" != "y" ] && [ "$install_packages" != "n" ]; do
  echo -e " Sorry, $install_packages is not a valid option."
  read -r -p " Would you like to install required packages: java [y/n]? " install_packages
done

if [ "$install_packages" = "y" ]; then
  echo -e " Installing java ...\n"
  apt update
  apt install openjdk && echo -e "\n ** java installed **\n" || echo -e "\n ** java NOT installed **\n"
  echo -e " If any packages failed to install, you will need to install them manually.\n"
fi

echo -e " Alright, now it's time to get into the details of your new minecraft server.\n"

read -r -p " Server Name (CamelCase): " server_name
while [ -z "$server_name" ]; do
  echo -e " Sorry, $server_name is not a valid name."
  read -r -p " Server Name (CamelCase): " server_name
done

read -r -p " Server Port [default: 25565]: " server_port
if [ -z "$server_port" ]; then
  server_port=25565
fi

echo -e "\n NOTE: If you want to connect to this server from a non-local network, you will"
echo -e " forward the port $server_port. Please refer to your service provider for further"
echo -e " instructions on how to do this."

echo ""

echo -e " Ok, now we need to select a version of minecraft to run on this server. You"
echo -e " can either select from one of the provided versions or provide the path to"
echo -e " a custom server .jar file you would like to use.\n"

echo -e " Available Versions:"
for version in "${available_server_versions[@]}"; do
    echo -e "  - $version"
done

echo ""

read -r -p " Server Version [type 'custom' for custom .jar file]: " server_version
found_version_file="false"
while [ "$found_version_file" = "false" ]; do
  if [ "$server_version" = "custom" ]; then
    read -r -p " File path to custom server .jar file: " server_jar_path
    if [ -f "server_jar_path" ]; then
      echo " Found $server_jar_path"
      found_version_file="true"
      server_jar="minecraft-server-custom.jar"
      break
    else
      echo " Sorry, could not find file $server_jar_path"
      read -r -p " Server Version [type 'custom' for custom .jar file]: " server_version
    fi
  else
    server_jar_path="$PWD/server-versions/minecraft-server-$server_version.jar"
    if [ -f "$server_jar_path" ]; then
      echo " Found $server_jar_path"
      found_version_file="true"
      server_jar="minecraft-server-$server_version.jar"
      break
    else
      echo " Sorry, could not find file $server_jar_path"
      read -r -p " Server Version [type 'custom' for custom .jar file]: " server_version
    fi
  fi
done

# Get Server Minimum RAM from user
read -r -p " Minimum RAM [default: 2G]: " min_ram
if [ -z "$min_ram" ]; then
  min_ram="2G"
fi

# Get Server Maximum RAM from user
read -r -p " Maximum RAM [default: 4G]: " max_ram
if [ -z "$max_ram" ]; then
  max_ram="4G"
fi

# Review Server Properties
echo -e "\n New Minecraft Server Information"
echo "  Name:    $server_name"
echo "  Port:    $server_port"
echo "  Version: $server_version ($server_jar_path)"
echo "  Min RAM: $min_ram"
echo "  Max RAM: $max_ram"

echo -e "\n Please verify that the above information is correct."
read -r -p " Press any key to continue ..."

echo ""

# Create a 'minecraft' user & group
echo -e " Creating 'minecraft' user and group ..."

if getent group "minecraft" >/dev/null 2>&1; then
    echo " Group 'minecraft' already exists"
else
    groupadd minecraft
fi

if id "minecraft" >/dev/null 2>&1; then
    echo " User 'minecraft' already exists"
else
    useradd -m -G minecraft minecraft
fi

server_directory="/home/minecraft/$server_name"

# Create folder for server
if [ -d "$server_directory" ]; then
  echo " Whoops, seems like a server directory already exists for $server_name ($server_directory)."

  read -r -p " Would you like to overwrite this file [y/n]? " overwrite_server_directory
  while [ "$overwrite_server_directory" != "y" ] && [ "$overwrite_server_directory" != "n" ]; do
    echo " Sorry, $overwrite_server_directory is not a valid option."
    read -r -p " Would you like to overwrite this file [y/n]? " overwrite_server_directory
  done

  echo ""

  if [ "$overwrite_server_directory" = "y" ]; then
    rm -rf "$server_directory"
  else
    echo " Please rename/remove the folder $server_directory or pick a different name for your server."
  fi
fi

mkdir "$server_directory"
cd "$server_directory" || ( echo " Whoops, seems like the server directory was not created correctly." | exit )

# Copy over the server.jar file
cp "$server_jar_path" "./$server_jar"

# Generate start.sh File
echo -e " Generating start.sh ..."
{
echo -e "#!/bin/bash"
echo -e ""
echo -e "# Server Configuration"
echo -e "JAR=$server_jar"
echo -e "MAXRAM=$max_ram"
echo -e "MINRAM=$min_ram"
echo -e ""
echo -e "java -Xmx\$MAXRAM -Xms\$MINRAM -jar \$JAR nogui"
} >> "start.sh"

service_name="MinecraftServer$server_name"

# Generate MinecraftServer.socket File
echo -e " Generating MinecraftServer$server_name.socket ..."
{
  echo -e "[Unit]"
  echo -e "PartOf=$service_name.service"
  echo -e ""
  echo -e "[Socket]"
  echo -e "ListenFIFO=%t/$service_name.stdin"
} >> "$service_name.socket"
cp "$service_name.socket" "/etc/systemd/system/$service_name.socket"

# Generate MinecraftServer.service File
echo -e " Generating $service_name.service ..."
{
echo -e "[Unit]"
echo -e "Description=Minecraft Server"
echo -e ""
echo -e "[Service]"
echo -e "Type=simple"
echo -e "WorkingDirectory=$server_directory"
echo -e "ExecStart=/bin/bash $server_directory/start.sh"
echo -e "User=minecraft"
echo -e "Restart=on-failure"
echo -e "Sockets=$service_name.socket"
echo -e "StandardInput=socket"
echo -e "StandardOutput=journal"
echo -e "StandardError=journal"
echo -e ""
echo -e "[Install]"
echo -e "WantedBy=multi-user.target"
} >> "$service_name.service"
cp "$service_name.service" "/etc/systemd/system/$service_name.service"
systemctl enable "$service_name.service"

# Reload systemctl daemon (in case MinecraftServer.service already existed)
systemctl daemon-reload

# Run once initially to generate server files
java -jar "$server_jar" nogui

# Update the port number in server.properties
sed -i "s/server-port=25565/server-port=$server_port/g" server.properties
sed -i "s/query.port=25565/query.port=$server_port/g" server.properties

# Update firewall settings
ufw allow "$server_port"

# Handle the EULA
echo ""
cat eula.txt
echo ""

read -r -p " You must accept the above EULA to proceed [accept/decline]: " accpet_eula
while [ "$accpet_eula" != "accept" ] && [ "$accpet_eula" != "decline" ]; do
  echo -e " Sorry, $accpet_eula is not a valid option."
  read -r -p " You must accept the above EULA to proceed [accept/decline]: " accpet_eula
done

if [ "$accpet_eula" = "accept" ]; then
  echo "eula=true" > eula.txt
else
  echo -e "\n You can manually accept the EULA at a later time, but keep in mind that the"
  echo -e " server will not be able to run until you do."
fi

# Give server files proper permissions
chown minecraft -R "$server_directory"
chgrp minecraft -R "$server_directory"
chmod ug+rwx -R "$server_directory"

read -r -p " Would you like start the server now [y/n]? " start_server
while [ "$start_server" != "y" ] && [ "$install_packages" != "n" ]; do
  echo -e " Sorry, $start_server is not a valid option."
  read -r -p " Would you like start the server now [y/n]? " start_server
done

echo ""

if [ "$start_server" = "y" ]; then
  systemctl start "$service_name.service"
else
  echo -e " To start the server, run the following command:\n"
  echo -e "  sudo systemctl start $service_name.service\n"
fi

echo -e "================================================================================\n"
echo -e " Your new minecraft server should be set up and good to go!\n"
echo -e " Server Controls:\n"
echo -e "  sudo systemctl start $service_name    # Starts the service if it wasn't running"
echo -e "  sudo systemctl stop $service_name     # Stops the service"
echo -e "  sudo systemctl restart $service_name  # Restarts the service"
echo -e "  sudo systemctl status $service_name   # Find out how the service is doing"
echo -e "  sudo journalctl -u $service_name -f   # Monitor the logs\n"
echo -e " In order to send console commands to the server, you can write commands to the"
echo -e " file /run/$service_name.stdin which will be pipelined to the server's console."
echo -e " For example,\n"
echo -e "  echo \"help\" > /run/$service_name.stdin   # Print list of available commands"
echo -e "  echo \"/stop\" > /run/$service_name.stdin  # Gracefully stop the server (save & exit)"
echo -e "  echo \"/\" > /run/$service_name.stdin      # Clear any commands stuck in the pipeline"
echo -e ""
