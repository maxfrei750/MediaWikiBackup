# MediaWiki Backup
This project is a docker image for backing up a MediaWiki installation (file dump and database dump).

## Setup
### Prerequisites
* Docker
* Docker Compose

### Installation
1. Clone this repository
2. Copy `env.example` to `.env` and adjust the values.
3. Place `ssh_key` file in the root directory of this project. This file will be used to authenticate with the remote server.
4. Optional: Adjust the `docker-compose.yml` file to your needs. If you want to change the path, where snapshots are saved, make sure that the corresponding host directory already exists.


## Usage
```bash
docker-compose up -d
```

## Acknowledgements
This project is based on the work of
* https://github.com/helmuthb/rsnapshot-docker
