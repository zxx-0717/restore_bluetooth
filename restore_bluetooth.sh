#!/bin/bash

# ============================================
# Bluetooth Auto-Restore Script
# Description: Monitor and restore Bluetooth during charging period
# ============================================

# Generate log file name
log_file_name="/home/tj2022/logs_bluetooth_restore/restore_bluetooth_"$(date +%Y%m%d-%H%M%S)".log"
echo "All logs are stored at "$log_file_name
echo ""

# Configuration
bluetooth_controller="tj2022-DEFAULT-STRING"
charger_bluetooth_name="ai-thinker"
time_interval=10
pwd="tj2022"

# Flag files
core_restart_flag="/home/tj2022/map/core_restart.txt"
bluetooth_restore_flag="/home/tj2022/map/bluetooth_restore.txt"

# Function: Write log with timestamp
write_log() {
    local level=$1
    local message=$2
    echo "$(date) [${level}] ${message}" | tee -a "$log_file_name"
}

# Function: Check if Bluetooth device is available
check_bluetooth_device() {
    for i in {1..10}; do
        if hciconfig dev 2>/dev/null | grep -q "hci"; then
            return 0
        fi
        sleep 1
    done
    return 1
}

# Function: Get Bluetooth device name
get_bluetooth_device() {
    hciconfig dev 2>/dev/null | awk 'NR==1{print $1}'
}

# Function: Check if Bluetooth is powered on
check_bluetooth_power() {
    local power_status=$(timeout 5 echo "show" | bluetoothctl 2>/dev/null | grep "Powered:" | awk '{print $2}')
    if [ "$power_status" == "yes" ]; then
        return 0
    else
        return 1
    fi
}

# Function: Restore Bluetooth
restore_bluetooth() {
    local device=$(get_bluetooth_device)
    
    write_log "INFO" "=== Starting Bluetooth restoration ==="
    
    # Step 1: Turn off Bluetooth power via bluetoothctl
    write_log "INFO" "=== Step 1: Turn off Bluetooth power (bluetoothctl)"
    if timeout 10 bash -c "echo 'power off' | bluetoothctl" >/dev/null 2>&1; then
        write_log "INFO" "bluetoothctl power off success"
    else
        write_log "ERROR" "bluetoothctl power off failed"
    fi
    sleep 2
    
    # Step 2: Unblock Bluetooth (critical step)
    write_log "INFO" "=== Step 2: Unblock Bluetooth"
    if timeout 5 echo "$pwd" | sudo -S rfkill unblock bluetooth 2>/dev/null; then
        write_log "INFO" "rfkill unblock bluetooth success"
    else
        write_log "ERROR" "rfkill unblock bluetooth failed"
    fi
    sleep 1
    
    # Step 3: Remove btusb module
    write_log "INFO" "=== Step 3: Remove btusb module"
    if timeout 5 echo "$pwd" | sudo -S rmmod btusb 2>/dev/null; then
        write_log "INFO" "rmmod btusb success"
    else
        write_log "ERROR" "rmmod btusb failed, skipping..."
    fi
    sleep 1
    
    # Step 4: Load btusb module
    write_log "INFO" "=== Step 4: Load btusb module"
    if timeout 5 echo "$pwd" | sudo -S modprobe btusb 2>/dev/null; then
        write_log "INFO" "modprobe btusb success"
    else
        write_log "ERROR" "modprobe btusb failed"
        return 1
    fi
    sleep 2
    
    # Step 5: Restart bluetooth service
    write_log "INFO" "=== Step 5: Restart bluetooth service"
    if timeout 10 echo "$pwd" | sudo -S systemctl restart bluetooth.service 2>/dev/null; then
        write_log "INFO" "bluetooth.service restart success"
    else
        write_log "ERROR" "bluetooth.service restart failed"
        return 1
    fi
    sleep 3
    
    # Step 6: Ensure device is up
    write_log "INFO" "=== Step 6: Ensure Bluetooth device is up"
    if [ -n "$device" ]; then
        timeout 3 echo "$pwd" | sudo -S hciconfig "$device" up 2>/dev/null
        write_log "INFO" "hciconfig $device up executed"
    fi
    sleep 1
    
    # Step 7: Turn on Bluetooth power via bluetoothctl
    write_log "INFO" "=== Step 7: Turn on Bluetooth power (bluetoothctl)"
    if timeout 10 bash -c "echo 'power on' | bluetoothctl" >/dev/null 2>&1; then
        write_log "INFO" "bluetoothctl power on success"
    else
        write_log "ERROR" "bluetoothctl power on failed"
    fi
    sleep 2
    
    # Step 8: Verify restoration success
    write_log "INFO" "=== Step 8: Verify Bluetooth availability"
    sleep 2
    
    # Check both device existence and power status
    local device_ok=false
    local power_ok=false
    
    if check_bluetooth_device; then
        device_ok=true
        local verified_device=$(get_bluetooth_device)
        write_log "INFO" "✓ Bluetooth device found: $verified_device"
    else
        write_log "ERROR" "✗ Bluetooth device not found"
    fi
    
    if check_bluetooth_power; then
        power_ok=true
        write_log "INFO" "✓ Bluetooth power is ON"
    else
        write_log "ERROR" "✗ Bluetooth power is OFF"
        # Try to power on again
        write_log "INFO" "Attempting to power on again..."
        timeout 10 bash -c "echo 'power on' | bluetoothctl" >/dev/null 2>&1
        sleep 2
        if check_bluetooth_power; then
            power_ok=true
            write_log "INFO" "✓ Bluetooth power successfully turned ON"
        fi
    fi
    
    # Final verification
    if $device_ok && $power_ok; then
        write_log "INFO" "✓✓ Bluetooth restoration COMPLETE and SUCCESSFUL ✓✓"
        return 0
    elif $device_ok && ! $power_ok; then
        write_log "WARNING" "⚠ Bluetooth device exists but power is OFF - partial success"
        return 0  # Still consider as success since device is there
    else
        write_log "ERROR" "✗✗ Bluetooth restoration FAILED completely ✗✗"
        return 1
    fi
}

# ============================================
# Main Script
# ============================================

write_log "INFO" "=== Bluetooth restore monitor started ==="
write_log "INFO" "=== Initial delay 20s for device/service to be ready ==="
sleep 20

# Main monitoring loop
while true; do
    # Check if in charging period (monitoring enabled)
    if [ -f "$core_restart_flag" ] && cat "$core_restart_flag" 2>/dev/null | grep -q 1; then
        
        # Check if Bluetooth restore is triggered
        if [ -f "$bluetooth_restore_flag" ] && cat "$bluetooth_restore_flag" 2>/dev/null | grep -q 1; then
            
            write_log "INFO" "=== Bluetooth restore triggered ==="
            
            # Attempt to restore Bluetooth
            if restore_bluetooth; then
                # Reset restore flag to signal upper layer that restoration is complete
                write_log "INFO" "=== Resetting bluetooth_restore flag (signaling reconnection allowed)"
                echo 0 > "$bluetooth_restore_flag" 2>/dev/null
                
                if [ $? -eq 0 ]; then
                    write_log "INFO" "✓ bluetooth_restore flag reset to 0"
                else
                    write_log "ERROR" "Failed to reset bluetooth_restore flag"
                fi
            else
                write_log "ERROR" "=== Bluetooth restoration failed, will retry on next trigger ==="
                # Do NOT reset bluetooth_restore_flag to allow retry
            fi
            
        else
            # Monitoring but no trigger
            write_log "DEBUG" "=== Monitoring mode: waiting for restore trigger (bluetooth_restore=0)"
        fi
        
    else
        # Not in charging period
        write_log "DEBUG" "=== Monitoring disabled (not in charging period)"
    fi
    
    # Wait before next iteration
    sleep $time_interval
done