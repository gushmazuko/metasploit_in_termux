#!/data/data/com.termux/files/usr/bin/bash
#usage: ./postgresql_ctl.sh {start|stop|restart|status}
pg_ctl -D $PREFIX/var/lib/postgresql ${1}
