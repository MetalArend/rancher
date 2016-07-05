#Run Rancher from a docker-compose file

##Rancher

- From http://rancher.com/ :
    
    "From the ground up, Rancher was designed to solve all of the critical challenges necessary to run all of your applications in containers. Rancher provides a full set of infrastructure services for containers, including networking, storage services, host management, load balancing and more. All of these services work across any infrastructure, and make it simple to reliably deploy and manage applications."

##Requirements

- Currently only tested on my development machine.
    - Mac OS X El Caption 10.11
    - Docker for Mac 1.12.0-rc2-beta18: https://docs.docker.com/docker-for-mac/

##Usage

- Run docker-compose inside this repository's directory:
    ```
    docker-compose up -d --remove-orphans && docker-compose logs -f rancher-helper
    ```
    
- Visit your local Rancher server:
    ```
    http://localhost:8080
    ```

##Roadmap

- enable secure connections (and make logs and graphs accessible again?)
- add container names
    - adding container_name disables the network domain names for the container
    - adding container name rancher-agent removes the newly started rancher-agent
- add logging: /var/lib/cattle/logs
- move /var/lib/rancher to other cached location?
- check why rancher-helper is relaunching another instance of rancher/agent

##Watched docker issues

- https://github.com/docker/docker/issues/23177 to get the host more reliably?

<!-- docker-compose stop && docker-compose rm -f && docker-compose up -d --remove-orphans && docker-compose logs -f rancher-helper -->