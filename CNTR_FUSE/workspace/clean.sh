docker stop slim-container fat-container
docker rm slim-container fat-container
docker rmi slim-image fat-image
docker volume prune -f