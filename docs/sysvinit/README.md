# SysVinit Cheatsheet

Traditional init system for Unix/Linux (pre-systemd). Manages system startup, shutdown, and service supervision via runlevels and shell scripts.

---

## Boot Sequence

### 1. Kernel Initialization
- Bootloader → Kernel loads
- Kernel mounts root filesystem, executes `/sbin/init` (symlink to `/lib/sysvinit/init`)

### 2. Init Process (`/sbin/init`)
- Reads `/etc/inittab` for configuration
- Defines **default runlevel** (e.g., `id:5:initdefault:`)

### 3. Runlevels (0-6)
| Runlevel | Description                                     |
|----------|-------------------------------------------------|
| 0        | Halt (system shutdown)                          |
| 1        | Single-user mode (root shell, minimal services) |
| 2        | Multi-user mode (no networking)                 |
| 3        | Multi-user mode with networking (text mode)     |
| 4        | Unused / User-defined                           |
| 5        | Multi-user mode with networking + GUI (X11)     |
| 6        | Reboot                                          |

### 4. Runlevel Execution Flow
```
/etc/inittab
    ↓
/etc/rc.d/rc.sysinit      (System initialization: mount /proc, /sys, set hostname, load modules)
    ↓
/etc/rc.d/rc <runlevel>   (Runs scripts in /etc/rc<runlevel>.d/)
    ↓
/etc/rc.d/rc.local        (Custom local commands)
```

---

## Directory Structure

```
/etc/
├── inittab                    # Main init configuration file
│
├── rc.d/
│   ├── init.d/                # Service startup/shutdown scripts (e.g., sshd, cron, networking)
│   │   ├── network
│   │   ├── sshd
│   │   ├── crond
│   │   └── ...
│   │
│   ├── rc0.d/                 # Runlevel 0 (Halt) - K* kill scripts
│   ├── rc1.d/                 # Runlevel 1 (Single-user)
│   ├── rc2.d/                 # Runlevel 2 (Multi-user, no network)
│   ├── rc3.d/                 # Runlevel 3 (Multi-user, network)
│   ├── rc4.d/                 # Runlevel 4 (User-defined)
│   ├── rc5.d/                 # Runlevel 5 (Multi-user + GUI)
│   ├── rc6.d/                 # Runlevel 6 (Reboot) - K* kill scripts
│   │
│   ├── rc.sysinit             # System initialization script
│   └── rc.local               # Custom post-boot commands
│
└── rc.local                  # (Alternative location on some systems)

/var/run/                      # PID files for running services
```

### Symlink Naming Convention (in rcX.d/)
- `S##servicename` → **Start** script (## = priority, lower = earlier)
  - Example: `S20sshd` → Start SSH daemon at priority 20
- `K##servicename` → **Kill** script (## = priority, higher = later)
  - Example: `K20sshd` → Stop SSH daemon at priority 20

---

## Useful Commands

### Service Management

| Command | Description |
|---------|-------------|
| `service <name> start` | Start a service |
| `service <name> stop` | Stop a service |
| `service <name> restart` | Restart a service |
| `service <name> reload` | Reload config without full restart |
| `service <name> status` | Check service status |
| `service --status-all` | List all services and their status |

### Runlevel Management

| Command | Description |
|---------|-------------|
| `runlevel` | Show current and previous runlevel |
| `who -r` | Display current runlevel and last boot time |
| `init <level>` | Switch to specified runlevel (e.g., `init 3`) |
| `telinit <level>` | Same as `init <level>` (preferred) |
| `shutdown -h now` | Halt system (runlevel 0) |
| `shutdown -r now` | Reboot system (runlevel 6) |
| `reboot` | Reboot immediately |
| `halt` | Halt immediately |

### Service Configuration

| Command | Description |
|---------|-------------|
| `chkconfig --list` | List all services and their runlevel status |
| `chkconfig <name> on` | Enable service at default runlevels |
| `chkconfig <name> off` | Disable service at all runlevels |
| `chkconfig <name> --level 35 on` | Enable for runlevels 3 and 5 only |
| `update-rc.d <name> defaults` | Enable service with default symlinks |
| `update-rc.d <name> enable` | Enable service (Debian/Ubuntu) |
| `update-rc.d <name> disable` | Disable service (Debian/Ubuntu) |
| `update-rc.d <name> remove` | Remove all symlinks for service |

### Process and System Info

| Command | Description |
|---------|-------------|
| `ps aux | grep <name>` | Find service process |
| `pidof <name>` | Get PID of running service |
| `cat /var/run/<name>.pid` | Check PID file |
| `dmesg | tail` | View recent kernel messages |
| `cat /proc/version` | Check kernel and init version |

---

## Adding a Service

### Method 1: Using `chkconfig` (RHEL/CentOS)

```bash
# 1. Create init script in /etc/init.d/
vi /etc/init.d/myservice

# 2. Make it executable
chmod +x /etc/init.d/myservice

# 3. Add to chkconfig management (requires chkconfig header)
# Add this header to your script:
#   ### BEGIN INIT INFO
#   # Provides:          myservice
#   # Required-Start:    $network $syslog
#   # Required-Stop:     $network $syslog
#   # Default-Start:     2 3 4 5
#   # Default-Stop:      0 1 6
#   # Short-Description: My custom service
#   # Description:       A detailed description
#   ### END INIT INFO

# 4. Register the service
chkconfig --add myservice

# 5. Enable at desired runlevels
chkconfig myservice on
# OR for specific runlevels:
chkconfig --level 35 myservice on

# 6. Verify
chkconfig --list myservice
ls -la /etc/rc3.d/ | grep myservice
```

### Method 2: Using `update-rc.d` (Debian/Ubuntu)

```bash
# 1. Create init script
vi /etc/init.d/myservice
chmod +x /etc/init.d/myservice

# 2. Add LSB headers (optional but recommended)
#   ### BEGIN INIT INFO
#   # Provides:          myservice
#   # Required-Start:    $network $remote_fs $syslog
#   # Required-Stop:     $network $remote_fs $syslog
#   # Default-Start:     2 3 4 5
#   # Default-Stop:      0 1 6
#   ### END INIT INFO

# 3. Create symlinks
update-rc.d myservice defaults

# 4. Verify symlinks
ls -la /etc/rc2.d/ | grep myservice
ls -la /etc/rc3.d/ | grep myservice

# 5. Start the service
service myservice start
```

### Method 3: Manual Symlink Creation

```bash
# 1. Create init script
vi /etc/init.d/myservice
chmod +x /etc/init.d/myservice

# 2. Create symlinks manually for each runlevel
# For runlevels 2, 3, 4, 5 (start) and 0, 1, 6 (stop)
for level in 2 3 4 5; do
    ln -s ../init.d/myservice /etc/rc${level}.d/S99myservice
done
for level in 0 1 6; do
    ln -s ../init.d/myservice /etc/rc${level}.d/K01myservice
done

# 3. Verify
ls -la /etc/rc3.d/ | grep myservice
```

---

## Removing a Service

### Method 1: Using `chkconfig` (RHEL/CentOS)

```bash
# 1. Disable the service
chkconfig myservice off

# 2. Remove from chkconfig
chkconfig --del myservice

# 3. Remove init script
rm /etc/init.d/myservice

# 4. Remove symlinks manually (if any remain)
for level in 0 1 2 3 4 5 6; do
    rm -f /etc/rc${level}.d/*myservice*
done
```

### Method 2: Using `update-rc.d` (Debian/Ubuntu)

```bash
# 1. Remove symlinks
update-rc.d -f myservice remove
# OR
update-rc.d myservice disable

# 2. Remove init script
rm /etc/init.d/myservice
```

### Method 3: Manual Removal

```bash
# 1. Stop the service
service myservice stop

# 2. Remove all symlinks
for level in 0 1 2 3 4 5 6; do
    rm -f /etc/rc${level}.d/*myservice*
done

# 3. Remove init script
rm /etc/init.d/myservice

# 4. Remove PID file if exists
rm -f /var/run/myservice.pid
```

---

## Init Script Template

```bash
#!/bin/bash
#
# myservice    Startup script for MyService
#

### BEGIN INIT INFO
# Provides:          myservice
# Required-Start:    $network $syslog
# Required-Stop:     $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: My custom service
# Description:       A detailed description of what the service does
### END INIT INFO

# Source function library
. /etc/rc.d/init.d/functions

# Configuration
PROG="/usr/local/bin/myservice"
PIDFILE="/var/run/myservice.pid"
NAME="myservice"

# Check if executable exists
[ -x "$PROG" ] || exit 0

# Define LSB log functions
RETVAL=0

start() {
    echo -n "Starting $NAME: "
    daemon $PROG --daemon
    RETVAL=$?
    [ $RETVAL -eq 0 ] && touch $PIDFILE
    echo
    return $RETVAL
}

stop() {
    echo -n "Stopping $NAME: "
    killproc -p $PIDFILE $NAME
    RETVAL=$?
    [ $RETVAL -eq 0 ] && rm -f $PIDFILE
    echo
    return $RETVAL
}

status() {
    status -p $PIDFILE $NAME
    RETVAL=$?
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    reload)
        echo "Reloading $NAME: Not supported"
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|reload|status}"
        exit 1
        ;;
esac

exit $RETVAL
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Check current runlevel | `runlevel` or `who -r` |
| List all services | `service --status-all` |
| Enable service at boot | `chkconfig myservice on` (RHEL) or `update-rc.d myservice enable` (Debian) |
| Disable service at boot | `chkconfig myservice off` (RHEL) or `update-rc.d myservice disable` (Debian) |
| Start service now | `service myservice start` |
| Stop service now | `service myservice stop` |
| Check if service running | `service myservice status` |
| Switch to runlevel 3 | `telinit 3` or `init 3` |
| View boot messages | `dmesg` or `cat /var/log/boot.log` |
| List rc3.d scripts | `ls -la /etc/rc3.d/` |

---

## Notes

- SysVinit uses **sequential** startup (slower than systemd's parallel startup)
- Service dependencies must be manually managed via script ordering (S/K priorities)
- No built-in service monitoring (services that crash stay stopped)
- Modern systems use **systemd** (replace `service` with `systemctl`)
- Some systems have both SysVinit scripts and systemd unit files for compatibility
