#!/bin/bash
while true
do

# Menu

PS3='Select an action: '
options=("Docker" "Download the components" "Create the configuration" "Run Node" "Update Node" "Upgrade Node" "Logs" "Check health" "Uninstall" "Exit")
#options=("Docker" "Download the components" "Create the configuration" "Run Node" "Update Node" "Upgrade Node" "Logs" "Uninstall" "Exit")
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
sed -i -e "s%RLN_RELAY_ETH_CLIENT_ADDRESS=.*%RLN_RELAY_ETH_CLIENT_ADDRESS=${RPC}%g" $HOME/nwaku-compose/.env
sed -i -e "s%ETH_TESTNET_KEY=.*%ETH_TESTNET_KEY=${EPK}%g" $HOME/nwaku-compose/.env
sed -i -e "s%RLN_RELAY_CRED_PASSWORD=.*%RLN_RELAY_CRED_PASSWORD=${PASS}%g" $HOME/nwaku-compose/.env
sed -i -e "s%STORAGE_SIZE=.*%STORAGE_SIZE=50GB%g" $HOME/nwaku-compose/.env
sed -i -e "s%NWAKU_IMAGE=.*%NWAKU_IMAGE=wakuorg/nwaku:v0.35.1%g" $HOME/nwaku-compose/.env
grep -q '^POSTGRES_SHM=' "$HOME/nwaku-compose/.env" || echo 'POSTGRES_SHM=4g' >> "$HOME/nwaku-compose/.env"
sed -i 's/0\.0\.0\.0:3000:3000/0.0.0.0:3003:3000/g' $HOME/nwaku-compose/docker-compose.yml
sed -i 's/8000:8000/8004:8000/g' $HOME/nwaku-compose/docker-compose.yml
sed -i 's/80:80/81:80/g' $HOME/nwaku-compose/docker-compose.yml
sed -i 's/127.0.0.1:8003:8003/127.0.0.1:8005:8003/g' $HOME/nwaku-compose/docker-compose.yml
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
#update
cd $HOME/nwaku-compose/
docker compose down
if [ ! -f $HOME/backup_nwaku/keystore.json ]; then
  mkdir -p $HOME/backup_nwaku
  cp $HOME/nwaku-compose/keystore/keystore.json $HOME/backup_nwaku/keystore.json
fi
git pull origin master
#bash $HOME/nwaku-compose/set_storage_retention.sh
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
sed -i -e "s%RLN_RELAY_ETH_CLIENT_ADDRESS=.*%RLN_RELAY_ETH_CLIENT_ADDRESS=${RPC}%g" $HOME/nwaku-compose/.env
sed -i -e "s%ETH_TESTNET_KEY=.*%ETH_TESTNET_KEY=${EPK}%g" $HOME/nwaku-compose/.env
sed -i -e "s%RLN_RELAY_CRED_PASSWORD=.*%RLN_RELAY_CRED_PASSWORD=${PASS}%g" $HOME/nwaku-compose/.env
sed -i -e "s%STORAGE_SIZE=.*%STORAGE_SIZE=50GB%g" $HOME/nwaku-compose/.env
grep -q '^POSTGRES_SHM=' "$HOME/nwaku-compose/.env" || echo 'POSTGRES_SHM=4g' >> "$HOME/nwaku-compose/.env"
sed -i 's/0\.0\.0\.0:3000:3000/0.0.0.0:3003:3000/g' $HOME/nwaku-compose/docker-compose.yml
sed -i 's/8000:8000/8004:8000/g' $HOME/nwaku-compose/docker-compose.yml
sed -i -e "s%NWAKU_IMAGE=.*%NWAKU_IMAGE=wakuorg/nwaku:v0.35.1%g" $HOME/nwaku-compose/.env
sed -i 's/80:80/81:80/g' $HOME/nwaku-compose/docker-compose.yml
sed -i 's/127.0.0.1:8003:8003/127.0.0.1:8005:8003/g' $HOME/nwaku-compose/docker-compose.yml
sleep 2
docker compose up -d
break
;;
"Check health")
bash $HOME/nwaku-compose/chkhealth.sh
break
;;
"Upgrade Node")
#upgrade
cd $HOME/nwaku-compose/
docker compose down
if [ ! -f $HOME/backup_nwaku/keystore.json ]; then
  mkdir -p $HOME/backup_nwaku
  cp $HOME/nwaku-compose/keystore/keystore.json $HOME/backup_nwaku/keystore.json
fi
#git stash push --include-untracked
#git pull https://github.com/waku-org/nwaku-compose.git
rm -r keystore rln_tree
git pull origin master
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
sed -i -e "s%RLN_RELAY_ETH_CLIENT_ADDRESS=.*%RLN_RELAY_ETH_CLIENT_ADDRESS=${RPC}%g" $HOME/nwaku-compose/.env
sed -i -e "s%ETH_TESTNET_KEY=.*%ETH_TESTNET_KEY=${EPK}%g" $HOME/nwaku-compose/.env
sed -i -e "s%RLN_RELAY_CRED_PASSWORD=.*%RLN_RELAY_CRED_PASSWORD=${PASS}%g" $HOME/nwaku-compose/.env
sed -i 's/0\.0\.0\.0:3000:3000/0.0.0.0:3003:3000/g' $HOME/nwaku-compose/docker-compose.yml
sed -i 's/8000:8000/8004:8000/g' $HOME/nwaku-compose/docker-compose.yml
sed -i -e "s%NWAKU_IMAGE=.*%NWAKU_IMAGE=wakuorg/nwaku:v0.35.1%g" $HOME/nwaku-compose/.env
sed -i -e "s%STORAGE_SIZE=.*%STORAGE_SIZE=50GB%g" $HOME/nwaku-compose/.env
grep -q '^POSTGRES_SHM=' "$HOME/nwaku-compose/.env" || echo 'POSTGRES_SHM=4g' >> "$HOME/nwaku-compose/.env"
sed -i 's/80:80/81:80/g' $HOME/nwaku-compose/docker-compose.yml
sed -i 's/127.0.0.1:8003:8003/127.0.0.1:8005:8003/g' $HOME/nwaku-compose/docker-compose.yml
bash $HOME/nwaku-compose/register_rln.sh
sleep 2
docker compose up -d
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