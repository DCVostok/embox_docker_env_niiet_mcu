# Embox docker environment for niiet mcu
This repo has proxy Makefile for building, uploading and debug embox using docker container.  

Supported:  
* K1921VG015

## Using

### Clone
```
git clone --recurse-submodules
```

### Build docker 
```
make docker_build
```

### Build embox with K1921VG015

```
sudo make confload-platform/vostok/vostok_vg015_dev
sudo make -j
```

### Uploading

```
sudo make upload
```

### Open embox shell

```
sudo make monitor
```