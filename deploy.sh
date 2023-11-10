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

# 生成furious配置链接
cat << EOF > /etc/hysteria/login_info/furious.txt
hysteria2://$password@$domain:443,20000-50000/?insecure=0&sni=$domain
EOF
echo "Furious配置链接："
cat /etc/hysteria/login_info/furious.txt

# 生成连接操作SOP
cat << EOF > /etc/hysteria/login_info/sop.md 
# Windows客户端

1. 如果之前装过v2rayN软件, 请删除旧的v2rayN文件

2. 请将v2rayN压缩包解压到D:\Program Files

3. 进入文件夹, 将v2rayN.exe固定到开始菜单

4. 按win键进入开始菜单, 右键单击v2rayN图标, 点击更多-打开文件位置

5. 在新出现的文件夹, 右键点击v2rayN, 点击属性-高级-用管理员身份运行-确定

6. 如果之前没安装过v2rayN, 则需要先安装 windowsdesktop-runtime-6.0.15-win-x64

7. 点击开始菜单V2rayN图标（然后会有一个页面闪现并自动关闭）

8. 左键双击右下角工具栏v2rayN图标, 唤出主界面

9. 在主界面, 依次点击 设置-参数设置-v2rayn设置-开机启动-确定

10. 在主界面, 系统代理选择自动配置系统代理, 路由选择绕过大陆

11. 至此安装完成, 可以开始使用了. 浏览器如果安装过SwitchyOmega插件, 请将代理模式设置为系统代理, 或者卸载SwitchyOmega插件.


# Android客户端

1. 下载安装Nekobox软件

2. 复制nekobox配置链接: hy2://$password@$domain:443/?mport=443%2C20000-50000#$file_name

3. 在Nekobox软件中, 点击右上角加号, 再点击从剪贴板导入

4. 点击正下方纸飞机符号启用代理配置


# iOS客户端

1. 删除9月以前安装的Shadowrocket软件

2. 点击appstore图标, 点击右上角头像, 拉到最底下, 点击退出当前的apple id

3. 登陆美区ID

4. 搜索并下载Shadowrocket软件

5. 退出美区ID, 登陆旧ID

6. 复制shadowrocket配置链接: hysteria2://$password@$domain?peer=$domain&obfs=none&mport=443,20000-50000&fastopen=1#$file_name

7. 在Shadowrocket软件中, 点击右上角加号, 再点击从剪贴板导入

8. 在shadowrocket软件主界面, 启用该服务器


# Mac客户端

1. 下载安装furious软件

2. 复制furious配置链接: hysteria2://$password@$domain:443,20000-50000/?insecure=0&sni=$domain

3. 在furious软件启用服务器


EOF

# 将hysteria2服务设置为开机启动
systemctl enable hysteria-server.service

#重启Hysteria2
systemctl restart hysteria-server.service


# #查看Hysteria2状态
# systemctl status hysteria-server.service
