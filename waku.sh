#!/bin/bash
while true
do

# Menu

PS3='Select an action: '
options=("Docker" "Download the components" "Create the configuration" "Run Node" "Update Node" "Logs" "Uninstall" "Exit")
select opt in "${options[@]}"
               do
                   case $opt in                          

"Docker")
#docker
. <(wget -qO- https://raw.githubusercontent.com/mgpwnz/VS/main/docker.sh)

break
;;

"Download the components")
# Clone repository
cd $HOME
git clone https://github.com/waku-org/nwaku-compose
cd nwaku-compose
cp .env.example .env 
break
;;
"Create the configuration")
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
if [ ! $RPC ]; then
		read -p "Enter RPC : " RPC
		echo 'export RPC='${RPC} >> $HOME/.bash_profile
	fi
if [ ! $EPK ]; then
		read -p "Enter EVM private key : " EPK
		echo 'export EPK='${EPK} >> $HOME/.bash_profile
	fi
if [ ! $PASS ]; then
		read -p "Enter password : " PASS
		echo 'export PASS='${PASS} >> $HOME/.bash_profile
	fi
 . $HOME/.bash_profile
sed -i -e "s%ETH_CLIENT_ADDRESS=.*%ETH_CLIENT_ADDRESS=${RPC}%g" $HOME/nwaku-compose/.env
sed -i -e "s%ETH_TESTNET_KEY=.*%ETH_TESTNET_KEY=${EPK}%g" $HOME/nwaku-compose/.env
sed -i -e "s%RLN_RELAY_CRED_PASSWORD=.*%RLN_RELAY_CRED_PASSWORD=${PASS}%g" $HOME/nwaku-compose/.env
sed -i 's/0\.0\.0\.0:3000:3000/0.0.0.0:3003:3000/g' $HOME/nwaku-compose/docker-compose.yml
bash $HOME/nwaku-compose/register_rln.sh
break
;;
"Run Node")
cd $HOME/nwaku-compose/
docker compose up -d 
docker compose logs -f
break
;;

"Update Node")
cd $HOME/nwaku-compose/
git pull
rm .env && cp .env.example .env
if [ ! $RPC ]; then
		read -p "Enter RPC : " RPC
		echo 'export RPC='${RPC} >> $HOME/.bash_profile
	fi
if [ ! $EPK ]; then
		read -p "Enter EVM private key : " EPK
		echo 'export EPK='${EPK} >> $HOME/.bash_profile
	fi
if [ ! $PASS ]; then
		read -p "Enter password : " PASS
		echo 'export PASS='${PASS} >> $HOME/.bash_profile
	fi
. $HOME/.bash_profile
sed -i -e "s%ETH_CLIENT_ADDRESS=.*%ETH_CLIENT_ADDRESS=${RPC}%g" $HOME/nwaku-compose/.env
sed -i -e "s%ETH_TESTNET_KEY=.*%ETH_TESTNET_KEY=${EPK}%g" $HOME/nwaku-compose/.env
sed -i -e "s%RLN_RELAY_CRED_PASSWORD=.*%RLN_RELAY_CRED_PASSWORD=${PASS}%g" $HOME/nwaku-compose/.env
sed -i 's/0\.0\.0\.0:3000:3000/0.0.0.0:3003:3000/g' $HOME/nwaku-compose/docker-compose.yml
sleep 2
docker compose restart
break
;;
"Logs")
docker compose -f $HOME/nwaku-compose/docker-compose.yml  logs -f --tail 1000
break
;;

"Uninstall")
if [ ! -d "$HOME/nwaku-compose" ]; then
    break
fi
read -r -p "Wipe all DATA? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY]) 
cd $HOME/nwaku-compose && docker compose down -v
rm -rf $HOME/nwaku-compose
        ;;
    *)
	echo Canceled
	break
        ;;
esac
break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done