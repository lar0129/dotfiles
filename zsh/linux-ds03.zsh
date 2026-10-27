bindkey '^I^I' forward-word

export UV_CACHE_DIR="/data2/lar/.cache/uv"
export HF_HOME="/data2/lar/.cache/huggingface"
export HF_HUB_CACHE="$HF_HOME/hub"
export HUGGINGFACE_HUB_CACHE="$HF_HOME/hub"
export TRANSFORMERS_CACHE="$HF_HOME/transformers"
export HF_DATASETS_CACHE="$HF_HOME/datasets"
export LLAMA_CACHE="/data2/lar/.cache/llama.cpp"

export TMPDIR="/data2/lar/tmp"
export TMP="$TMPDIR"
export TEMP="$TMPDIR"

path=(/data2/lar/utils/bin /data2/lar/utils/node/bin /usr/local/cuda-12.4/bin $path)
export LD_LIBRARY_PATH="/usr/local/cuda-12.4/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

proxy() {
  case "${1:-status}" in
    on)
      ipads_proxy_on
      ;;
    off)
      proxy_off
      ;;
    status)
      if [[ -n ${http_proxy:-}${https_proxy:-}${HTTP_PROXY:-}${HTTPS_PROXY:-}${all_proxy:-}${ALL_PROXY:-} ]]; then
        print -r -- "代理已开启"
      else
        print -r -- "代理已关闭"
      fi
      ;;
    *)
      print -u2 -r -- "用法: proxy {on|off|status}"
      return 1
      ;;
  esac
}

if [[ -n "${IPADS_PROXY_URL:-}" ]]; then
  ipads_proxy_on
fi
