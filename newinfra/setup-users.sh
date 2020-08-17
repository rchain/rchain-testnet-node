#!/bin/bash

create-user() {
    echo "$0:Creating user <$1>"

    # Don't create user if it already exists
    if id "$1" >/dev/null 2>&1; then
        echo "$0:User <$1> already exists!"
    else
        adduser --disabled-password --gecos '' $1
        mkdir -p /home/$1/.ssh
        echo "ssh-rsa $2 $1" >> /home/$1/.ssh/authorized_keys
        chown -R $1:$1 /home/$1/.ssh
        chmod 700 /home/$1/.ssh
        chmod 600 /home/$1/.ssh/authorized_keys
        usermod -aG adm,sudo $1
        echo "$1 ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
    fi
}
create-user rundeck "AAAAB3NzaC1yc2EAAAADAQABAAABgQDBB0d6wZVHk+E7vackEbylpV6pBeE4yY9FAwv8zyTApSE/JzRqJUEA++qZs1648t1uIiQjSVVGG054VnCiAjVJ45IkTUyeociBNrATIUhod1puJg7lRnvFjy12rKCkEtmT17qV6c+m0aUkAv1JOkHGxPSWZCiR4RyvGC6+0cSNLf102/4WRdgwtpTWK64GBmkbTFvF1NT75PsV2R2ixGz3Ft/KTpySSqcexUZPHWeUhbc9z3RQ1g35nV0M0xl5TVzGEbrPYWdCRHIa2ZW43gWfe3w4e5D/d/DFVA1N4/R13Vz6hRFrbs/++anhmqVw7wAAg2SZOlbA+tHzQpg5Kpp0MrQR0vvDN5nQkRmaCWIO+VxsTV1mtdHlopAPj/wXWJjMugebjQlsE3zTWL84TJc2JovuvH3FgRdGfWLD0QFol7j9z/YszCWcevgVeBPiFrEDM2S4nqSRnXiWc/APgfv+ARdelg6t/RtGOyaysJ2EGcOCWK8ZDES2MTaQ5GrxmKU="

create-user rchain-sre-ibm "AAAAB3NzaC1yc2EAAAADAQABAAABAQCiiPhfC24Jea6bFIraEOKUSIYQE8ZqXY+xCX/X7M2vVusmDA9nY4K7bJcaqBULMPribbJJSWydOHsnHncu2M/aWmgOotK9Rwhcb0QNeoB3nvNajviizuPgmlsqeVI+lzLwKhygcS2XQbuLCLIMzCjxjBT9zmJcsog2jYcur/INBFlYha0GTCmqzuXR2YG0noiIPkQK61/DvjBN/u3Niq82Y3BSArdMTSFpnL4bt7t+RI0fXfUEW14QAmwYBnf/RavU/C5pVG2HPtfIQUlvDFgslxWazXoJPXNFf4JohktxbyXULrKPRgLnM2pNpd8rR1lVIVhCo74iYgsp1dahxW3L"

create-user gsj "AAAAB3NzaC1yc2EAAAABJQAAAQEAt9RH/gOVhBcfK5kDK3IYhKu5+JDwS9n86iFywEjFd6bwRs99xJC5iVk8GY23tojI5TCWshTz0f6dPIJV6jdneeGbVsFgKzKrKF9EXfWd5fZwArhSZQ2++A0nwg6duKci3qPbtBX0SlV1fBS/8tpYklsKLkjW6+63Qc0KYBsRjSm4Nr3MDtTSc8bqIS8LXJZVEkjwoi0BenTYaveEAITU0ZLwCysJmx65NRpDYAq1yx2qjYB8woFxSqJMgqoqpGMQ67UP35DHB5B3IuYSpI2GnHkBF5zwpeGwk8/Jwaoi7qe3uwuc7MXaqsgOjjm5nsklbHbVX+Lw0x9uljvYsd5n/Q=="

create-user anton_chistiakov "AAAAB3NzaC1yc2EAAAADAQABAAABAQC0ViQcZMLpE8JkSV/Yo+z3LJRELGr82glqhFo3K1TzmOLMcVw9bKzzNGzSjmExM/JtjEnR5LaHCAg/ttQLUSWGsEUT5SyNBfeuQRqrL9M/FLKY5VTW9oIBuSyEw21rOfeak5dLzT2F2pOAiqztyKA61FRzLVas9+rODvDCmU7SrtYVVhX4SMN3wSdqQKj2Hxh757UcD95kJWW7vT7+2ncRuBbz3Vl5HwX1ZATAijGuuJ1yDUxgZrjS7y7fZP7XL0gTAIeQDjHgcS79ckRo+aW3+3ZU82GC4il0SCJrIGTWEAZAJyXI8qcqGajHnJCikBRDMAj8tD3h/JrNeRV1Y+Et"

create-user tgrospic "AAAAB3NzaC1yc2EAAAADAQABAAACAQDK4rx3zVZLcEnG6YyAo3UxpSbBkqLX4NDOKEnX09bzlZZnYKpsildhBMJXdCAdoR9roHrrk7NM4O6b8XEaP1txwfyBuqrnx6/OMg05viImt/wwOOwL4n8/5GPi2a9xmVB0a5LL5rqWMA8U8gg3nghfG0ZrZYn7jStEI6lEqT46rv9owEVTxl+IDh71aJeo/njY8bBVNcyO0rABlEwZsmiL7i0Hrfr0UDd8GD8Ud9yKPXtbDTeuGEoPQ5zc/bNVPF1y+SvcTITbTrpn+2PI42tr1UThQf86s9SEd27ZmaXBgGQgWr3ykGDB4otYORlDLm/uFs1xxyahSikR1yzSqKCeC/03bc24FmFRfxFOWbuHtuHD9mkTrGGV67h+P94WCSFkCUSU7RcoWmMXPOx7kDhdlDXggbrc6lIbFFrBN+mgkYHh+hmSfiusLdCyIHmd4erQd19bC9EZbeRjuQdfnZykIMewx0DF3YnWpoYnvYvoku55pRpWlJ5OtXHFiNCpp51N6mC8hkYLUwm5hQ2uD7dooqfUi8wtbNKgcWx3pBhPHw0HDU21xNrNZhMPwVDBEA/HkBXup4fC0XLTBs8q7YBpszJ76UV5/+tfh0fKhOYWJB1eJpGmTTaHQOTqn0LwcjzLaHqIsL5ma3b/Nf0lBxKYFEcaYsVfK54zOGMhHcncDw=="

create-user will "AAAAB3NzaC1yc2EAAAADAQABAAABAQC+eOJWG9DMFhvtQGaAX49x9emWwDD/lXzZQ4br37lwOEnn+0loLp73Xub2YibQ9PVZ0D8qnfVgbmhVYMSeKtPgeXdZdiEu/kWNoPij2COcT6uKVaCXVD5gKlyQ0vRzAvSlDxFrD9Z2113liLaoxF3AYQ/0S79Bnlm5eG035i3wF/xpwO86mmlwhcPXDsbYcSimN55rEEMmbqpfouwPV0UrvsMDvhr6H441MXzeIp6b1lhs8umKNCVQJ0uS8A/fr4vPZ135it+0Rc85bmPCJntmBo+ROZ6IKBhLS4eLUxonV50zj/Np/uifG01kEMfhqjsBD+H+lAS3M7QrddLppMJP"
