
PUBLIC_LOCAL_KEY_PATH="./menderkeys/localkeys-public.key"
read -s -p "Password: " password
echo 
read -p "ip(blank for 169.254.1.1): " ip

if [[ -z "$ip" ]]; then
  ip="169.254.1.1"
fi
echo "sending public key:$PUBLIC_LOCAL_KEY_PATH to $ip"
sshpass -p "$password" scp -o 'StrictHostKeyChecking no' -P 40022 "$PUBLIC_LOCAL_KEY_PATH" root@$ip:/var/volatile/transient_keys/edgeenabler.pem
