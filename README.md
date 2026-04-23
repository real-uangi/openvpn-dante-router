# openvpn-dante-router

基于 OpenVPN + Dante 的容器路由器镜像。容器启动后会：

- 建立 OpenVPN 隧道（`tun0`）
- 启动 Dante SOCKS5 服务（默认 `1080` 端口）
- 根据 `LOCAL_NETS` 调整路由，避免内网段走 VPN

## 运行要求

- Docker 20+（建议开启 Buildx）
- 宿主机可用 `/dev/net/tun`
- 容器需 `NET_ADMIN` 能力
- 需要挂载 OpenVPN 配置目录到 `/config`

## 关键环境变量

- `VPN_PROFILE`：必填。对应 `/config/<VPN_PROFILE>.ovpn`
- `LOCAL_NETS`：可选。逗号分隔网段，默认：
  - `10.0.0.0/8,172.16.0.0/12,192.168.0.0/16`
- `OPENVPN_AUTH_FILE`：可选。指定 OpenVPN 用户名密码文件路径
- `OPENVPN_USERNAME` / `OPENVPN_PASSWORD`：可选。未提供认证文件时可用该方式注入

## OpenVPN 认证（已去明文内置）

镜像不再内置 `auth.txt`。运行时认证来源优先级：

1. `OPENVPN_AUTH_FILE`
2. `/run/secrets/openvpn_auth`
3. `/auth.txt`（兼容旧挂载方式）
4. `OPENVPN_USERNAME` + `OPENVPN_PASSWORD`（容器内临时生成认证文件）

建议优先使用 secrets 文件挂载。

`auth.example.txt` 格式如下（两行）：

```text
YOUR_OPENVPN_USERNAME
YOUR_OPENVPN_PASSWORD
```

## 本地构建

```bash
docker build -t openvpn-dante-router:local .
```

## 本地运行示例

### 方式 1：挂载认证文件（推荐）

```bash
docker run -d --name openvpn-dante-router \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  -p 1080:1080 \
  -e VPN_PROFILE=your-profile \
  -e LOCAL_NETS='10.0.0.0/8,172.16.0.0/12,192.168.0.0/16' \
  -e OPENVPN_AUTH_FILE=/run/secrets/openvpn_auth \
  -v /path/to/ovpn:/config:ro \
  -v /path/to/openvpn-auth.txt:/run/secrets/openvpn_auth:ro \
  ghcr.io/real-uangi/openvpn-dante-router:latest
```

### 方式 2：环境变量注入账号密码

```bash
docker run -d --name openvpn-dante-router \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  -p 1080:1080 \
  -e VPN_PROFILE=your-profile \
  -e OPENVPN_USERNAME='your-username' \
  -e OPENVPN_PASSWORD='your-password' \
  -v /path/to/ovpn:/config:ro \
  ghcr.io/real-uangi/openvpn-dante-router:latest
```

## CI/CD（GitHub Actions）

工作流文件：`.github/workflows/release.yml`

- 触发：`main` 分支每次 `push`（支持手动触发）
- 自动创建并推送 Git Tag：
  - 格式：`vYYYY.MM.DD.runN`
  - `N` 为 GitHub Actions `run_number`
- 自动构建并推送 GHCR 多架构镜像：
  - `linux/amd64`
  - `linux/arm64`
- 推送标签：
  - `ghcr.io/real-uangi/openvpn-dante-router:<git-tag>`
  - `ghcr.io/real-uangi/openvpn-dante-router:latest`

## 安全建议

- 不要提交真实账号密码到仓库
- 建议定期轮换 VPN 凭据
- 若历史中曾提交过明文凭据，请立即轮换并清理相关访问权限
