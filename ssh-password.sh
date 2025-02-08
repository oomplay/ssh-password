#!/bin/bash

# ตรวจสอบว่ารันด้วยสิทธิ์ root หรือไม่
if [ "$EUID" -ne 0 ]; then
  echo "กรุณารันสคริปต์นี้ด้วยสิทธิ์ root หรือใช้ sudo"
  exit 1
fi

# ปิดใช้งาน SSH ก่อน
systemctl stop ssh
systemctl disable ssh

# ลบ SSH Server ออก
apt-get remove --purge -y openssh-server
apt-get autoremove -y
apt-get install -y openssh-server

# กำหนดไฟล์คอนฟิก SSH
SSH_CONFIG="/etc/ssh/sshd_config"

# แก้ไขค่า PasswordAuthentication เป็น yes หากพบ หรือเพิ่มหากไม่มี
if grep -q "^PasswordAuthentication" "$SSH_CONFIG"; then
  sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' "$SSH_CONFIG"
else
  echo "PasswordAuthentication yes" >> "$SSH_CONFIG"
fi

# ปิดใช้งานการยืนยันแบบ Public Key Authentication
if grep -q "^PubkeyAuthentication" "$SSH_CONFIG"; then
  sed -i 's/^PubkeyAuthentication .*/PubkeyAuthentication no/' "$SSH_CONFIG"
else
  echo "PubkeyAuthentication no" >> "$SSH_CONFIG"
fi

# อนุญาตให้ root เข้าใช้งาน SSH
if grep -q "^PermitRootLogin" "$SSH_CONFIG"; then
  sed -i 's/^PermitRootLogin .*/PermitRootLogin yes/' "$SSH_CONFIG"
else
  echo "PermitRootLogin yes" >> "$SSH_CONFIG"
fi

# รีสตาร์ท SSH service
systemctl restart ssh
systemctl enable ssh

# สร้างรหัสผ่านแบบสุ่มสำหรับ root
NEW_ROOT_PASS=$(openssl rand -base64 12)
echo "รหัสผ่านใหม่ของ root: $NEW_ROOT_PASS"

# เปลี่ยนรหัสผ่าน root
echo "root:$NEW_ROOT_PASS" | chpasswd

# แจ้งเตือนผู้ใช้
echo "SSH ถูกติดตั้งใหม่ เปิดใช้งาน PasswordAuthentication ปิดใช้งาน Public Key Authentication อนุญาตให้ root เข้าใช้งาน SSH และรหัสผ่าน root ถูกเปลี่ยนแล้ว"
