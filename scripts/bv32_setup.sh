#!/bin/bash

# Apply the patch
wget github.com/Vocovo/asterisk-broadvoice/archive/Library-1.2.tar.gz
tar zxf Library-1.*.tar.gz
rm Library-1.*.tar.gz
cp --verbose --recursive ./asterisk-broadvoice*/* ./
patch -p0 <./bv32_pass-through.patch
patch -p0 <./bv16_pass-through.patch

# Install libraries for BroadVoice32
cd ~/Downloads/
unzip -qq ./BroadVoice32OpenSource.v1.2.zip
cd ./BroadVoice32/FloatingPoint/
patch -p0 <~/Downloads/bv32_library.patch
sudo mkdir /usr/local/include/bvcommon
sudo cp -R ./bvcommon/*.h /usr/local/include/bvcommon/
sudo mkdir /usr/local/include/bv32
sudo cp -R ./bv32/*.h /usr/local/include/bv32/
cd ./Linux/
patch -p0 <~/Downloads/bv32_makefile.patch
make
sudo cp ./libbv32.so /usr/local/lib/
cd /usr/src/asterisk*
patch -p0 <./bv32_transcoding.patch

# Define the path to the Asterisk configuration files
SIP_CONF="/etc/asterisk/sip.conf"
PJSIP_CONF="/etc/asterisk/pjsip.conf"

# Function to add the codec to the configuration
function add_codec {
    local file=$1
    local codec=$2

    # Check if the 'allow' line exists in the file
    if grep -q "^allow=" $file; then
        # If the line exists, append the codec
        sudo sed -i "/^allow=/ s/$/,$codec/" $file
    else
        # If the line does not exist, add it
        echo "allow=$codec" | sudo tee -a $file
    fi
}

# Add the BroadVoice32 codec to the configuration files
add_codec $SIP_CONF "bv32"
add_codec $PJSIP_CONF "bv32"

# Restart Asterisk to apply changes
sudo systemctl restart asterisk
