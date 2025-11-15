# some scripts for esp32 programming on linux.

### ~~container_list.bash~~
~~When building project using idf.py, we use docker.
This script shows the list of docker images in docker hub.
Need chromium-brouser to scrape the "https://hub.docker.com"~~

_container_list.bash is obsoleted_

### esp_containers.bash
When building project using idf.py, we use podman(docker).
This script shows the list of docker images in docker hub.
Need wget/curlto scrape the "https://hub.docker.com"
