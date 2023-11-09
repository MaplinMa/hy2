#!/bin/bash

# 下载并运行hysteria2脚本
bash <(curl -fsSL https://get.hy2.sh/)

# 生成证书
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=bing.com" -days 36500 && sudo chown hysteria /etc/hysteria/server.key && sudo chown hysteria /etc/hysteria/server.crt

# 将20000:50000端口范围加入端口跳跃
# IPv4
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 20000:50000 -j DNAT --to-destination :443
# IPv6
ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport 20000:50000 -j DNAT --to-destination :443

# 提示输入配置文件名
echo "请输入你的配置文件名"
read file_name
echo "你的配置文件名是：$file_name"

# 提示输入域名
echo "请输入你的域名，需要先解析到服务器ip"
read domain
echo "你的域名是：$domain"

# 提示输入邮箱
echo "请输入你的邮箱"
read email
echo "你的邮箱是：$email"

# 提示输入密码
echo "请输入你的密码"
read password
echo "你的密码是：$password"

cat << EOF > /etc/hysteria/config.yaml
listen: :443 #监听端口

#使用CA证书
acme:
  domains:
    - $domain #你的域名，需要先解析到服务器ip
  email: $email #你的邮箱

#使用自签证书
#tls:
#  cert: /etc/hysteria/server.crt
#  key: /etc/hysteria/server.key

auth:
  type: password
  password: $password #设置认证密码
  
masquerade:
  type: proxy
  proxy:
    url: https://bing.com #伪装网址
    rewriteHost: true

outbounds:
  - name: default
    type: direct
#   - name: isp
#     type: socks5
#     socks5:
#       addr:  # 填入IP:PORT
#       username:  #填入用户名
#       password:  #填入密码
#   # - name: isp
#   #   type: http
#   #   http: 
#   #     url:  #填入完整链接, 格式为 http://username:password@ip:port
#   #     insecure: false   
# acl:      
#   inline:
#     - isp(openai.com)
#     - isp(*.openai.com)
#     - isp(myip.ipip.net) 
#     - isp(*adobe*)
#     - isp(bing.com)
#     - isp(*.bing.com)
#     - isp(tiktok.com)
#     - isp(*.tiktok.com)
#     - isp(*.ibytedtos.com)
#     - isp(*.ttwstatic.com)
    
EOF

# 生成v2rayN配置文件
cat << EOF > /etc/hysteria/login_info/$file_name.yaml

server: $domain:443,20000-50000
auth: $password

bandwidth:
  up: 40 mbps
  down: 200 mbps
  
tls:
  sni: $domain
  insecure: false #使用自签时需要改成true

socks5:
  listen: 127.0.0.1:10808
http:
  listen: 127.0.0.1:10809

transport:
  type: udp
  udp:
    hopInterval: 10s 

EOF
echo "V2rayN配置文件："
cat /etc/hysteria/login_info/$file_name.yaml

# 生成nekobox配置链接
cat << EOF > /etc/hysteria/login_info/nekobox.txt
hy2://$password@$domain:443/?mport=443%2C20000-50000#$file_name
EOF
echo "Nekobox配置链接："
cat /etc/hysteria/login_info/nekobox.txt

# 生成shadowrocket配置链接
cat << EOF > /etc/hysteria/login_info/shadowrocket.txt
hysteria2://$password@$domain?peer=$domain&obfs=none&mport=443,20000-50000&fastopen=1#$file_name
EOF
echo "Shadowrocket配置链接："
cat /etc/hysteria/login_info/shadowrocket.txt

# 将hysteria2服务设置为开机启动
systemctl enable hysteria-server.service

#重启Hysteria2
systemctl restart hysteria-server.service


# #查看Hysteria2状态
# systemctl status hysteria-server.service