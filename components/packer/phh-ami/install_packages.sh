#!/bin/bash
set -e

# Update apt cache
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# -----------------------------------------------------------------------------
# Install Prerequisites
# -----------------------------------------------------------------------------
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

# -----------------------------------------------------------------------------
# Install Nginx
# -----------------------------------------------------------------------------
if [ "$INSTALL_NGINX" = "true" ]; then
  echo "Installing Nginx..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
  sudo systemctl enable nginx
  sudo systemctl start nginx
else
  echo "Skipping Nginx installation..."
fi

# -----------------------------------------------------------------------------
# Install Docker Engine & Docker Compose
# -----------------------------------------------------------------------------
if [ "$INSTALL_DOCKER" = "true" ] || [ "$INSTALL_DOCKER_COMPOSE" = "true" ]; then
  echo "Setting up Docker repository..."
  sudo mkdir -p /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  fi

  sudo apt-get update -y
  
  DOCKER_PACKAGES=""
  if [ "$INSTALL_DOCKER" = "true" ]; then
    echo "Installing Docker Engine..."
    DOCKER_PACKAGES="docker-ce docker-ce-cli containerd.io"
  fi
  
  if [ "$INSTALL_DOCKER_COMPOSE" = "true" ]; then
    echo "Installing Docker Compose Plugin..."
    DOCKER_PACKAGES="$DOCKER_PACKAGES docker-compose-plugin"
  fi

  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y $DOCKER_PACKAGES
  
  if [ "$INSTALL_DOCKER" = "true" ]; then
    sudo usermod -aG docker ubuntu
    sudo systemctl enable docker
    sudo systemctl start docker
  fi
else
  echo "Skipping Docker & Docker Compose installation..."
fi

# -----------------------------------------------------------------------------
# Install MySQL
# -----------------------------------------------------------------------------
if [ "$INSTALL_MYSQL_SERVER" = "true" ]; then
  echo "Installing MySQL Server..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
  sudo systemctl enable mysql
  sudo systemctl start mysql
else
  echo "Skipping MySQL Server installation..."
fi

if [ "$INSTALL_MYSQL_CLIENT" = "true" ]; then
  echo "Installing MySQL Client..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-client
else
  echo "Skipping MySQL Client installation..."
fi

echo "Package installation complete!"
