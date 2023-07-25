#!/bin/bash

# Install necessary tools
dpkg -s bison  &> /dev/null
if [ $? -eq 0 ]; then
    echo "bison is installed!"
else
    sudo apt-get install -y bison
fi

dpkg -s pkg-config  &> /dev/null
if [ $? -eq 0 ]; then
    echo "pkg-config is installed!"
else
    sudo apt-get install -y pkg-config
fi

dpkg -s libpng-dev  &> /dev/null
if [ $? -eq 0 ]; then
    echo "libpng-dev is installed!"
else
    sudo apt-get install -y libpng-dev
fi

dpkg -s g++ &> /dev/null
if [ $? -eq 0 ]; then
    echo "g++ is installed!"
else
    sudo apt-get install -y g++
fi

dpkg -s make  &> /dev/null
if [ $? -eq 0 ]; then
    echo "make is installed!"
else
    sudo apt-get install -y make
fi

dpkg -s gcc  &> /dev/null
if [ $? -eq 0 ]; then
    echo "gcc is installed!"
else
    sudo apt-get install -y gcc
fi

dpkg -s git &> /dev/null
if [ $? -eq 0 ]; then
    echo "git is installed!"
else
    sudo apt-get install -y git
fi

# Get RGBDS-0.6.1
if [ -d "rgbds" ]; then
  echo "rgbds already exists! Removing..."
  sudo rm -R rgbds
fi
echo "Getting the latest RGBDS compatible version!"
curl -Lo rgbds-0.6.1.tar.gz https://github.com/gbdev/rgbds/releases/download/v0.6.1/rgbds-0.6.1.tar.gz
tar xvfz rgbds-0.6.1.tar.gz
rm rgbds-0.6.1.tar.gz
echo "Building rgbds..."
cd rgbds
make clean
make
cd ..

# Build the Rom
echo "Building pokecrystal..."
make clean
make RGBDS=rgbds/
if [ ! -f "pokecrystal.gbc" ]; then
	echo "Something goes wrong during the process."    
fi
