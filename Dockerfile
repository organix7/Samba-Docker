FROM alpine

# Install samba
RUN apk --no-cache --no-progress upgrade && \
    apk --no-cache --no-progress add bash samba shadow tini tzdata && \
    addgroup -S smb && \
    adduser -S -D -H -h /tmp -s /sbin/nologin -G smb -g 'Samba User' smbuser &&\
    file="/etc/samba/smb.conf" && \

    sed -i 's|^;* *\(workgroup = \).*|   \1helha.lan|' $file && \
    sed -i 's|^;* *\(server role = \).*|   \1classic primary domain controller|' $file && \
    sed -i 's|^;* *\(logon path = \).*|   \1\\\\%L\\Profiles\\%U|' $file && \
    sed -i '/Share Definitions/,$d' $file && \
    echo '   logon home = \\%L\%U' >>$file && \
    echo '   domain master = yes' >>$file && \
    echo '   domain logons = yes' >>$file && \
    echo '   local master = yes' >>$file && \
    echo '   idmap config * : range = 3000-9999' >>$file && \
    echo '   idmap config helha.lan : range = 10000-99999' >>$file && \
    echo '   admin users = root' >>$file && \
    echo '' >>$file && \
    echo '[Profiles]' >> $file && \
    echo '   path = /profiles' >>$file && \
    echo '   create mask = 0600' >>$file && \
    echo '   directory mask = 0700' >>$file && \
    echo '   browseable = no' >>$file && \
    echo '   guest ok = no' >>$file && \
    echo '   writable = yes' >>$file && \
    echo '' >>$file && \
    echo '[Profiles.V2]' >>$file && \
    echo '   copy = Profiles' >>$file && \
    echo '' >>$file && \
    echo '[homes]' >>$file && \
    echo '   writable = yes' >>$file && \
    echo '   valid users = %S' >>$file && \
    echo '   browseable = no' >>$file && \
    echo '   create mask = 0600' >>$file && \
    echo '   directory mask = 0700' >>$file && \

    mkdir /profiles && \
    echo -ne "root\nroot\n" | smbpasswd -a root && \
    addgroup machines && \
    adduser -S PC$ -G machines && \
    smbpasswd -a -m PC$ &&\
    echo -ne "guigui\nguigui\n" | adduser guigui && \
    usermod guigui -G guigui,smb && \
    echo -ne "guigui\nguigui\n" | smbpasswd -a -s guigui && \
    mkdir /profiles/guigui.V2 && \
    chown guigui:guigui /profiles/guigui.V2 && \
    rm -rf /tmp/*

CMD nmbd -D && smbd -D && bash

EXPOSE 137/udp 138/udp 139 445

HEALTHCHECK --interval=60s --timeout=15s \
            CMD smbclient -L '\\localhost' -U '%' -m SMB3


