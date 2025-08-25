

read -s -p "Password: " password
echo 
read -p "ip(blank for 169.254.1.1): " ip
echo 
read -p "file(blank for collection-signed-private.mender): " file

if [[ -z "$ip" ]]; then
  ip="169.254.1.1"
fi
if [[ -z "$file" ]]; then
  file="collection-signed-private.mender"
fi

echo "sending app:$file to $ip"
sshpass -p "$password" scp -o 'StrictHostKeyChecking no' -P 40022 "$file" root@$ip:/srv/updates/upload/update.mender
