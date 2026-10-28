#!/usr/bin/env bash
# 一键在阿里云 PAI-DSW（A10 24G 显卡）上装好 ComfyUI + MiniMax H3 图生视频 + 插帧
# 用法：在 DSW 的 Terminal 里运行  bash setup_minimax_dsw.sh
# 需要大约 55G 硬盘空间。模型从魔搭（ModelScope）下载，和 DSW 同在阿里云，速度很快。
#
# 注意：部分 DSW 环境访问 GitHub（含常见镜像）会卡住。本脚本给 git clone 加了超时；
# 若克隆失败，请按 README「GitHub 卡住时」把两个 zip 上传到 /mnt/workspace/ 后再重跑。
set -e

WORKDIR=/mnt/workspace
COMFY=$WORKDIR/ComfyUI
REPO=Comfy-Org/MiniMax-H3
GIT_TIMEOUT_SEC="${GIT_TIMEOUT_SEC:-90}"

clone_with_timeout() {
  # $1 = git url, $2 = target dir name (created under cwd)
  local url="$1"
  local dest="$2"
  if [ -d "$dest" ]; then
    echo "已存在 $dest，跳过克隆"
    return 0
  fi
  echo "克隆 $url （超时 ${GIT_TIMEOUT_SEC}s）…"
  if command -v timeout >/dev/null 2>&1; then
    if ! timeout "$GIT_TIMEOUT_SEC" git clone --depth 1 "$url" "$dest"; then
      echo "ERROR: 克隆 $dest 失败或超时。DSW 上 GitHub 常会卡住。"
      echo "请按 README 用 JupyterLab 上传对应 zip 到 $WORKDIR 后重跑本脚本。"
      return 1
    fi
  else
    git clone --depth 1 "$url" "$dest"
  fi
}

echo "== 1/5 安装 ComfyUI =="
cd "$WORKDIR"
# 若已上传 ComfyUI-master.zip / ComfyUI-main.zip 并解压成 ComfyUI，直接用
if [ ! -d "$COMFY" ]; then
  if [ -d "$WORKDIR/ComfyUI-master" ]; then
    mv "$WORKDIR/ComfyUI-master" "$COMFY"
  elif [ -d "$WORKDIR/ComfyUI-main" ]; then
    mv "$WORKDIR/ComfyUI-main" "$COMFY"
  else
    clone_with_timeout https://github.com/comfyanonymous/ComfyUI.git ComfyUI
  fi
fi
cd "$COMFY"
pip install -r requirements.txt

echo "== 2/5 安装魔搭下载工具 =="
pip install -U modelscope
# 升级 modelscope 会把 huggingface_hub 带到 2.x，和 ComfyUI 冲突，这里固定回 1.0 以下
pip install "huggingface_hub>=0.34.0,<1.0"

echo "== 3/5 下载 MiniMax H3 模型（约 50G）=="
python -m modelscope.cli.cli download --model "$REPO" \
  diffusion_models/minimax_h3_fl2va_pruned_w6a8.safetensors \
  text_encoders/qwen3vl_32b_minimax_h3_int8_convrot.safetensors \
  vae/minimax_h3_video_vae_fp16.safetensors \
  vae/minimax_h3_audio_vae_fp32.safetensors \
  loras/minimax_h3_fl2v_turbo_8step_v1.0_comfyui_bf16.safetensors \
  --local_dir "$COMFY/models"

echo "== 4/5 安装插帧节点（ComfyUI-Frame-Interpolation）=="
cd "$COMFY/custom_nodes"
FI_DIR=ComfyUI-Frame-Interpolation
if [ ! -d "$FI_DIR" ]; then
  if [ -d "$WORKDIR/ComfyUI-Frame-Interpolation-main" ]; then
    mv "$WORKDIR/ComfyUI-Frame-Interpolation-main" "$FI_DIR"
  elif [ -d "$WORKDIR/ComfyUI-Frame-Interpolation-master" ]; then
    mv "$WORKDIR/ComfyUI-Frame-Interpolation-master" "$FI_DIR"
  else
    clone_with_timeout https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git "$FI_DIR"
  fi
fi
cd "$FI_DIR"
python install.py || pip install -r requirements-no-cupy.txt

echo "== 5/5 完成 =="
echo "以后每次开机启动 ComfyUI："
echo "  cd $COMFY && python main.py --listen --port 8188 --enable-cors-header"
echo "然后按住 Ctrl 点终端里 'To see the GUI go to' 后面的链接打开界面。"
echo "提醒：工作流不会自动保存，记得按 Ctrl+S；生成的视频在 output/video/ 里。"
