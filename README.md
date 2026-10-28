# MiniMax H3 on 阿里云 PAI-DSW（一键脚本）

给没有强力显卡、想用 ComfyUI 跑 MiniMax H3 图生视频的人：在阿里云 PAI-DSW（推荐 A10 24G）的 Terminal 里跑这一条，装好 ComfyUI、模型和下帧插帧节点。

## 你需要什么

- 一台 PAI-DSW 实例（上海区域较方便；A10 规格约每小时 7 算力时）
- 大约 55G 空闲磁盘（模型主要从魔搭 ModelScope 下，和 DSW 同在阿里云，一般比较快）
- 本仓库里的 `setup_minimax_dsw.sh`

免费试用或代金券够用时，很适合先把流程跑通，再给朋友轮流用（每个账号的磁盘是分开的，换账号就要重装；所以才做了这个脚本）。

## 怎么用

在 DSW Terminal 里：

```bash
bash setup_minimax_dsw.sh
```

脚本会依次：

1. 克隆并安装 ComfyUI  
2. 安装 / 校正 `modelscope` 与 `huggingface_hub`（避免和 ComfyUI 冲突）  
3. 从 `Comfy-Org/MiniMax-H3` 下载 w6a8 UNet、文本编码器、视频/音频 VAE、turbo LoRA  
4. 安装 `ComfyUI-Frame-Interpolation` 插帧节点  

## GitHub 卡住时（PAI-DSW 常见）

有的 DSW 访问 GitHub（含常见加速镜像）会一直挂住。脚本给 `git clone` 加了超时；失败时请：

1. 在能正常下 GitHub 的电脑上下这两个源码 zip：  
   - ComfyUI：https://github.com/comfyanonymous/ComfyUI/archive/refs/heads/master.zip  
   - 插帧：https://github.com/Fannovel16/ComfyUI-Frame-Interpolation/archive/refs/heads/main.zip  
2. 用 JupyterLab 左侧文件栏上传到 `/mnt/workspace/`，在 Terminal 里解压  
3. 解压后目录名一般是 `ComfyUI-master` 和 `ComfyUI-Frame-Interpolation-main`；脚本会自动认并挪到正确位置  
4. 再跑一次 `bash setup_minimax_dsw.sh`（模型仍走魔搭，不受 GitHub 影响）

## 每次开机启动

```bash
cd /mnt/workspace/ComfyUI && python main.py --listen --port 8188 --enable-cors-header
```

然后按住 Ctrl，点终端里 `To see the GUI go to` 后面的链接打开界面（直接把代理 URL 粘到网址栏常会登录失败）。

## 图生视频工作流注意

模板路径：模板 → 搜索 `MiniMax H3` → `MiniMax H3：图生视频`。

模板默认常是 int8_convrot 那一套。若你下的是本脚本的 **w6a8** 权重，请改成：

- UNet：`minimax_h3_fl2va_pruned_w6a8.safetensors`
- 文本编码：`qwen3vl_32b_minimax_h3_int8_convrot.safetensors`（本脚本会下这份；缺模型弹窗先关掉，不要乱下）
- VAE：`minimax_h3_video_vae_fp16.safetensors`（旧驱动上 int8 VAE 解码常会挂，用 fp16）

角色图放进 `first_frame` 的 load-image。生成视频在 `output/video/`。工作流不会自动保存，改完按 Ctrl+S。

## 开源说明

欢迎拿去帮同样缺好电脑、只想先做出 AI 视频的人。改脚本或文档时请保持步骤可复制、少坑。
