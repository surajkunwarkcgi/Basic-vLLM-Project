**1. GPU machine (AWS/GCP)**

Use a GPU instance (T4/L4 or better) with a Deep Learning AMI or image, or install the NVIDIA driver.

- Open port 80 in the security group or firewall.
- Check the GPU and driver: `nvidia-smi`
- Check Docker can see the GPU: `docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi`
    - If this fails, install the NVIDIA Container Toolkit.

**2. Build**

```bash
docker build -t vllm-nexus .
```

**3. Run**

```bash
docker run -d --name vllm-nexus --gpus all \
    -p 80:80 -p 8000:8000 \
    -v ~/.cache/huggingface:/root/.cache/huggingface \
    vllm-nexus
docker logs -f vllm-nexus
```

Wait for `vLLM ready! Starting Streamlit....` The first start takes a few minutes because the model downloads.

**4. Test**

    1. vLLM health: `curl localhost:8000/health` (expect HTTP 200).
    2. Models: `curl localhost:8000/v1/models` (expect your model ID).
    3. Chat API:

```bash

curl localhost:8000/v1/chat/completions -H "Content-Type: application/json" \
    -d '{"model":"Qwen/Qwen2.5-1.5B-Instruct","messages":[{"role":"user","content":"Hi"}]}'
```

    4. UI: open `http://<server-ip>` and check that the sidebar shows SERVER ONLINE and the model is listed. Send a message and confirm the reply streams in.
    5. GPU usage: `nvidia-smi` should show memory in use.

**5. If it fails**

    - The container exits right away: run `docker logs vllm-nexus`.
    - Out-of-memory error: set `-e GPU_UTIL=0.7` or `-e MAX_MODEL_LEN=1024`.
    - UI says offline: check that port 8000 is up inside the container.


**Installing NVIDIA driver, these commands assume Ubuntu 22.04 on the instance.**

**1. NVIDIA driver**

```bash

sudo apt update && sudo apt install -y ubuntu-drivers-common
sudo ubuntu-drivers install
sudo reboot
```

After the reboot, run `nvidia-smi`. It should show your GPU.

**2. Docker**

```bash

curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
```

**3. NVIDIA Container Toolkit**

```bash

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

**4. Verify**

```bash
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
```
If you see the GPU table, you're ready to build and run the project.

The driver must support CUDA 12.x. The default from ubuntu-drivers (535 or newer) does.