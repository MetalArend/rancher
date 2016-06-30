#Docker-compose for Rancher

- Run Rancher locally with a single command:
    ```
    docker-compose stop && docker-compose rm -f && docker-compose build && docker-compose up -d && docker-compose logs -f rancher-agent
    ```