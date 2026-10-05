# SOCKS5 一键安装脚本

基于 [gost](https://github.com/ginuerzh/gost)，轻量、systemd 开机自启，支持 amd64 / arm64 / armv7。

## 安装

随机账号密码（默认端口 1080）：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Roudness/socks5/main/install.sh)
```

自定义端口、账号、密码：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Roudness/socks5/main/install.sh) -p 2080 -u admin -w MySecret123
```

安装完成后会打印连接信息，并自动检测出口 IP。

## 卸载

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Roudness/socks5/main/install.sh) uninstall
```

## 验证

把账号、密码、端口换成你自己的：

```bash
curl -x socks5://用户名:密码@127.0.0.1:端口 https://api.ipify.org
```

显示服务器 IP 即成功。

## 修改配置

方法一：重新运行安装脚本，带上新的 `-p -u -w` 参数即可覆盖。

方法二：手动修改：

```bash
nano /etc/systemd/system/gost-socks5.service
```

修改这一行：

```
ExecStart=/usr/local/bin/gost -L=admin:MySecret123@:2080
```

保存后重启：

```bash
systemctl daemon-reload && systemctl restart gost-socks5
```

## 注意

- 需要 root 权限和 systemd。
- 记得在防火墙 / 云服务商安全组放行对应 TCP 端口。
- 请勿使用弱密码，仅限在自己的服务器上使用。

- 声明
仅供个人学习和自己的服务器使用，请遵守 当地法律法规。
