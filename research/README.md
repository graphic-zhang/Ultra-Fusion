# Ultra-Fusion 研究与复现计划

> 记录目标、环境现状、复现路线和代码管理约定。随研究进展持续更新。

## 1. 项目是什么

[sjtuyinjie/Ultra-Fusion](https://github.com/sjtuyinjie/Ultra-Fusion) 是一个**多传感器融合 SLAM 框架**（智能交通系统方向），在一个可配置的滑窗优化框架内统一支持 WIO / VIO / LIO / LVIO，可选轮式里程计与 GNSS 融合，并针对传感器退化（暗光、LiDAR 退化、车轮打滑、GNSS 丢失）和时间/外参扰动做了可靠性设计。

关键事实（2026-08-01 核对）：

- 当前以 **ROS1 Noetic（v0.1.3，Ubuntu 20.04）** 和 **ROS2 Humble（v0.2.2，Ubuntu 22.04）** 两个运行时发布**预编译二进制（.deb）+ YAML 配置**；**完整源码要等论文接收后放出**。
- 论文 PDF 已在仓库内：`paper/Ultra-Fusion.pdf`。
- 基准数据集：M3DGR（轮式）、M2DGR-Plus（轮式）、KAIST Complex Urban（车载）、GrandTour（足式）、MARS-LVIG（空中）。
- 运行时是 CPU 型（Ceres 优化 + PCL/OpenCV），不依赖 GPU。

## 2. 本机环境现状（已核查）

| 项目 | 状态 |
| --- | --- |
| Windows | 11 22H2 (build 19045) |
| WSL | 发行版 Ubuntu 22.04.5，**已成功转换为 WSL2**（内核 6.18.33.2-microsoft-standard-WSL2，systemd + WSLg 可用） |
| 硬件 | 12 核 / 15 GiB 内存；WSL 根文件系统余 ~39 GB，E: 盘余 ~218 GB |
| 工具链（WSL） | git 2.34.1、python3 3.10.12；**无 docker、无 gh、无 ROS** |
| 代理 | Clash @ 127.0.0.1:7897，GitHub/Google 均可达（见 §5） |
| Git 身份 | graphic-zhang / zhangxiang941211@gmail.com（WSL 全局已配置） |
| SSH | ed25519 密钥**已绑定 GitHub**，SSH 经代理认证通过 |
| GitHub | 已 fork 到 `graphic-zhang/Ultra-Fusion`；`origin`=fork，`upstream`=原仓库；研究提交已推送 |
| 虚拟机平台 | VirtualMachinePlatform 已启用，WSL2 转换完成（2026-08-01） |

> 注意：系统“默认 WSL 版本”显示为 2，但**虚拟机平台功能/BIOS 虚拟化未启用**，所以当前发行版只能以 WSL1 运行。

## 3. 复现路线

### 路线 A：WSL2 + Docker（推荐，最贴近上游文档）

1. 管理员 PowerShell：启用虚拟机平台并重启
   ```powershell
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```
   （如 BIOS 中虚拟化未开，需先进入 BIOS 开启 VT-x/AMD-V）
2. 转换现有发行版（Ubuntu 22.04 保持不动，镜像会迁移）：
   ```powershell
   wsl --set-version Ubuntu-22.04 2
   ```
3. 安装 Docker（推荐 Docker Desktop + WSL2 backend，或用 WSL2 内 `apt install docker.io`）。
4. 按上游文档运行（见 `docs/ros2_humble_m3dgr.md`）：
   ```bash
   docker pull maotiandocker/ultrafusion-ros2:0.2.1
   docker run --rm -it --net=host --ipc=host -e DISPLAY="${DISPLAY}" \
     -e QT_X11_NO_MITSHM=1 -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
     -v "$(pwd)":/workspace maotiandocker/ultrafusion-ros2:0.2.1
   cd /workspace && ./scripts/install_ultrafusion_ros2_deb.sh
   ```
   GUI（RViz2）由 WSLg 直接提供。

### 路线 B：WSL1 原生安装 ROS2 Humble（无需重启）

```bash
cd /mnt/e/Ultra-Fusion-WS
bash research/scripts/proxy_env.sh          # 先开代理
./scripts/install_native_ros2_deps.sh       # 需要 sudo；安装 ROS2 + 编译 Ceres 2.1.0/yaml-cpp 0.8.0
./scripts/install_ultrafusion_ros2_deb.sh
source /opt/ros/humble/setup.bash
uf_node /path/to/config.yaml --ros-args -p use_sim_time:=true
```

注意：WSL1 **没有 WSLg**，RViz2 需要 Windows 端 X server（如 VcXsrv）并把 `DISPLAY=:0` 导出；也可以只跑 `uf_node` 无 GUI 验证。

### 数据准备

M3DGR 的 bag 最小序列约 1.5–2 GB（Occlusion01 1.46 GB、Occlusion02 1.48 GB、Dynamic01 2.14 GB、Dark01 2.21 GB 等），OneDrive / 阿里云盘下载，放 `/media/` 或任意目录后按 §2 运行说明 `rosbag play ... --clock`。完整序列表见 `research/notes/m3dgr_sequences.txt`。

> 实测（2026-08-01）：OneDrive 分享链接被微软按代理节点 IP 拦截（“The request is blocked”），阿里云盘公开 API 需要登录签名。**最省事的做法：用阿里云盘 App/网页下载 Occlusion01**（1.46 GB，国内直连快），存到 `research/downloads/data/`。分享链接：https://www.alipan.com/s/r3P6Bcxj7Tu

## 7. 当前进度（2026-08-01）

- ✅ WSL2 转换完成（内核 6.18.33.2-microsoft-standard-WSL2，systemd + WSLg）
- ✅ 代理适配 WSL2 NAT（自动探测宿主机 IP，`proxy_env.sh` / `.bashrc` / `~/.ssh/config` 均已更新）
- ✅ GitHub fork + SSH 推送打通（`origin`=graphic-zhang/Ultra-Fusion）
- ✅ Docker Engine 安装（docker.io 29.1.3，systemd 托管）
- ✅ ROS2 运行时镜像 `maotiandocker/ultrafusion-ros2:0.2.0` 拉取完成（digest `ccc3b91f...` 与官方公布的 0.2.1 一致；Docker Hub 直连被墙，走代理；ACR 仓库已改为需要认证、不可用）
- ✅ Ultra-Fusion ROS2 v0.2.2 `.deb` 已下载并校验 SHA256（GitHub 走代理，3.6 MB）；镜像缺少 `ros-humble-ros2service`、`ros-humble-std-srvs`，容器内 `apt-get install` 补装后安装成功，`uf_node` 可用
- ✅ M3DGR Occlusion01 bag 已下载（阿里云盘 1.46 GB，实际是 7z-SFX 自解压包 `Occlusion01.exe`，已用 `research/scripts/extract_sfx.py` 解出 `Occlusion01.bag`）
- ✅ ROS1→ROS2 转换完成（`scripts/convert_m3dgr_ros1_to_ros2_common.py` → `research/downloads/data/occlusion01_ros2`，142 s、6 个主题）
- ✅ **首次运行成功（headless 验证）**：`uf_node`（LVWIO）+ `ros2 bag play` 处理完整序列，**UFEstimate 1360 次调用 0 失败**、雷达匹配 1380 帧、无致命错误
- ✅ 发现并修复两个数据侧问题（已沉淀为配置/脚本）：
  1. 转换后雷达时间戳恒定早 100 ms（Livox 头戳 vs bag 录制时间戳）→ 研究版配置 `initial_lidar_to_imu_dt_sec: 0.1`（[research/configs/uf_m3dgr_ros2_lvwio_dt0p1.yaml](research/configs/uf_m3dgr_ros2_lvwio_dt0p1.yaml)）
  2. bag 开头 ~0.12 s 轮速流未启动，锚定帧缺左边界 → 回放加 `ros2 bag play --start-offset 2`
- ⬜ 交互式 demo（RViz2 可视化）：`bash research/scripts/run_uf_ros2.sh`

> 注：headless 后台运行下 SIGINT/SIGTERM 未触发 TUM 轨迹保存（该构建的节点只在自身退出路径写盘）；交互式 Ctrl+C 一般正常。需要轨迹时可 `ros2 topic list` 找位姿主题录制，或后续研究。
- ⬜ 首次运行 demo（`uf_node` + `ros2 bag play` + RViz2）

## 4. 代码管理与 GitHub 推送

**结论：git 在 WSL 中管理；代码放 Windows 盘 E:\Ultra-Fusion-WS（WSL 中为 /mnt/e/Ultra-Fusion-WS）；VSCode 用 WSL 远程扩展打开。**

- Windows 上未安装 git；WSL 内 git 2.34.1 + SSH 密钥 + 代理齐备，因此 git 全部在 WSL 内执行。
- 仓库已克隆到工作目录，`origin` 指向上游；准备 fork 到你自己的 GitHub 账号后，用脚本一键改指向：
  ```bash
  bash research/scripts/github_setup.sh <你的GitHub用户名>
  ```
  该脚本会：打印公钥（需先到 GitHub → Settings → SSH and GPG keys 添加）、写入 `~/.ssh/config` 让 SSH 走代理、把 `origin` 改到你的 fork、保留 `upstream` 用于同步上游。
- 之后研究笔记/脚本的改动：`git add research/ ... && git commit && git push origin main`。
- VSCode：Windows 侧安装 “WSL” 扩展，`Ctrl+Shift+P` → `WSL: Open Folder` → 输入 `/mnt/e/Ultra-Fusion-WS`。这样编辑器在 Windows 显示、终端和 git 都在 WSL 里。若直接用 Windows 打开 E:\Ultra-Fusion-WS，VSCode 的 git 面板会因找不到 Windows git 而不可用（除非另装 Git for Windows）。

## 5. 代理速查

> ⚠️ WSL2 默认是 **NAT 网络**，`127.0.0.1` 不再直达 Windows 上的 Clash；代理主机已改为**自动探测**（WSL2 下取默认网关 IP，如 `172.26.48.1:7897`；WSL1/mirrored 模式回落到 `127.0.0.1:7897`）。

- 交互式终端：`source ~/.bashrc && proxy_on && bash ~/test_proxy.sh`（`.bashrc` 已打补丁，自动探测）
- 非交互/脚本：`source research/scripts/proxy_env.sh`
- git push/SSH：走 `~/.ssh/config` + `~/.ssh/ssh_proxy.sh`（已配置，无需手动设变量）
- 如需手动覆盖：`export PROXY_HOST=127.0.0.1`

## 6. 关键文件索引

| 文件 | 用途 |
| --- | --- |
| `README.md` | 上游文档（安装/运行/配置） |
| `paper/Ultra-Fusion.pdf` | 论文 |
| `docs/ros2_humble_m3dgr.md` | ROS2 运行指南（含 ROS1→ROS2 bag 转换） |
| `docs/visual_life_d360.md` | UFO（全景多相机）示例 |
| `scripts/install_native_ros2_deps.sh` | 原生安装 ROS2 依赖 |
| `scripts/install_ultrafusion_ros2_deb.sh` | 下载并安装 .deb |
| `research/scripts/proxy_env.sh` | 代理开关（可 source） |
| `research/scripts/env_check.sh` | 环境诊断 |
| `research/scripts/github_setup.sh` | 一键配置 fork + SSH 推送 |
| `research/notes/m3dgr_sequences.txt` | M3DGR 序列与下载链接 |
