#!/usr/bin/with-contenv bashio

CONFIG_PATH="/share/SunGather/config.yaml"

# Create directory if it doesn't exist
if [ ! -d /share/SunGather ]; then
  mkdir -p /share/SunGather
fi

# Always copy fresh template, then apply UI settings on top
cp config-hassio.yaml "$CONFIG_PATH"

# Helper function to update config if value is set
update_config() {
    local path="$1"
    local value="$2"
    if [ -n "$value" ] && [ "$value" != "null" ]; then
        yq -i "$path = $value" "$CONFIG_PATH"
    fi
}

# Helper function to update config with string value
update_config_str() {
    local path="$1"
    local value="$2"
    if [ -n "$value" ] && [ "$value" != "null" ]; then
        yq -i "$path = \"$value\"" "$CONFIG_PATH"
    fi
}

# ============================================================================
# INVERTER SETTINGS
# ============================================================================
INVERTER_HOST=$(bashio::config 'host')

# Validate required settings
if [ "$INVERTER_HOST" = "CHANGE_ME" ] || [ -z "$INVERTER_HOST" ]; then
    bashio::log.fatal "Inverter IP address not configured!"
    bashio::log.fatal "Please set your inverter's IP address in the add-on configuration."
    bashio::exit.nok
fi
INVERTER_PORT=$(bashio::config 'port' '')
TIMEOUT=$(bashio::config 'timeout' '')
RETRIES=$(bashio::config 'retries' '')
SLAVE=$(bashio::config 'slave' '')
INTERVAL=$(bashio::config 'scan_interval')
CONNECTION=$(bashio::config 'connection')
MODEL=$(bashio::config 'model' '')
SERIAL=$(bashio::config 'serial' '')
SMART_METER=$(bashio::config 'smart_meter')
USE_LOCAL_TIME=$(bashio::config 'use_local_time' '')
LOG_CONSOLE=$(bashio::config 'log_console')
LOG_FILE=$(bashio::config 'log_file' '' | tr '[:lower:]' '[:upper:]')
LEVEL=$(bashio::config 'level' '')

# Apply inverter settings
update_config_str ".inverter.host" "$INVERTER_HOST"
update_config ".inverter.port" "$INVERTER_PORT"
update_config ".inverter.timeout" "$TIMEOUT"
update_config ".inverter.retries" "$RETRIES"
update_config ".inverter.slave" "$SLAVE"
update_config ".inverter.scan_interval" "$INTERVAL"
update_config_str ".inverter.connection" "$CONNECTION"
update_config_str ".inverter.model" "$MODEL"
update_config_str ".inverter.serial" "$SERIAL"
update_config ".inverter.smart_meter" "$SMART_METER"
update_config ".inverter.use_local_time" "$USE_LOCAL_TIME"
update_config_str ".inverter.log_console" "$LOG_CONSOLE"
update_config_str ".inverter.log_file" "$LOG_FILE"
update_config ".inverter.level" "$LEVEL"

# ============================================================================
# CONSOLE EXPORT
# ============================================================================
CONSOLE_ENABLED=$(bashio::config 'console_enabled')
yq -i "(.exports[] | select(.name == \"console\") | .enabled) = $CONSOLE_ENABLED" "$CONFIG_PATH"

# ============================================================================
# WEBSERVER EXPORT
# ============================================================================
WEBSERVER_ENABLED=$(bashio::config 'webserver_enabled')
WEBSERVER_PORT=$(bashio::config 'webserver_port' '')

yq -i "(.exports[] | select(.name == \"webserver\") | .enabled) = $WEBSERVER_ENABLED" "$CONFIG_PATH"
if [ -n "$WEBSERVER_PORT" ] && [ "$WEBSERVER_PORT" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"webserver\") | .port) = $WEBSERVER_PORT" "$CONFIG_PATH"
fi

# ============================================================================
# MQTT EXPORT
# ============================================================================
CUSTOM_MQTT_SERVER=$(bashio::config 'custom_mqtt_server')
MQTT_HOST=$(bashio::config 'mqtt_host' '')
MQTT_PORT=$(bashio::config 'mqtt_port' '')
MQTT_USER=$(bashio::config 'mqtt_username' '')
MQTT_PASS=$(bashio::config 'mqtt_password' '')
MQTT_TOPIC=$(bashio::config 'mqtt_topic' '')
MQTT_CLIENT_ID=$(bashio::config 'mqtt_client_id' '')
MQTT_HA=$(bashio::config 'mqtt_homeassistant')
MQTT_HA_SENSORS=$(bashio::config 'mqtt_ha_sensors' '')

if [ "$CUSTOM_MQTT_SERVER" = true ]; then
    bashio::log.info "Using custom MQTT server configuration"
    # Apply custom MQTT settings
    if [ -n "$MQTT_HOST" ] && [ "$MQTT_HOST" != "null" ]; then
        yq -i "(.exports[] | select(.name == \"mqtt\") | .enabled) = true" "$CONFIG_PATH"
        yq -i "(.exports[] | select(.name == \"mqtt\") | .host) = \"$MQTT_HOST\"" "$CONFIG_PATH"
    fi
    if [ -n "$MQTT_PORT" ] && [ "$MQTT_PORT" != "null" ]; then
        yq -i "(.exports[] | select(.name == \"mqtt\") | .port) = $MQTT_PORT" "$CONFIG_PATH"
    fi
    if [ -n "$MQTT_USER" ] && [ "$MQTT_USER" != "null" ]; then
        yq -i "(.exports[] | select(.name == \"mqtt\") | .username) = \"$MQTT_USER\"" "$CONFIG_PATH"
    fi
    if [ -n "$MQTT_PASS" ] && [ "$MQTT_PASS" != "null" ]; then
        yq -i "(.exports[] | select(.name == \"mqtt\") | .password) = \"$MQTT_PASS\"" "$CONFIG_PATH"
    fi
else
    # Auto-discover MQTT from Home Assistant
    if bashio::services.available "mqtt"; then
        MQTT_HOST=$(bashio::services mqtt "host")
        MQTT_PORT=$(bashio::services mqtt "port")
        MQTT_USER=$(bashio::services mqtt "username")
        MQTT_PASS=$(bashio::services mqtt "password")

        yq -i "
            (.exports[] | select(.name == \"mqtt\") | .enabled) = true |
            (.exports[] | select(.name == \"mqtt\") | .host) = \"$MQTT_HOST\" |
            (.exports[] | select(.name == \"mqtt\") | .port) = $MQTT_PORT |
            (.exports[] | select(.name == \"mqtt\") | .username) = \"$MQTT_USER\" |
            (.exports[] | select(.name == \"mqtt\") | .password) = \"$MQTT_PASS\"
        " "$CONFIG_PATH"
        bashio::log.info "MQTT auto-configured from Home Assistant"
    else
        bashio::log.warning "No MQTT broker found. MQTT export disabled."
        yq -i "(.exports[] | select(.name == \"mqtt\") | .enabled) = false" "$CONFIG_PATH"
    fi
fi

# Common MQTT settings
if [ -n "$MQTT_TOPIC" ] && [ "$MQTT_TOPIC" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"mqtt\") | .topic) = \"$MQTT_TOPIC\"" "$CONFIG_PATH"
fi
if [ -n "$MQTT_CLIENT_ID" ] && [ "$MQTT_CLIENT_ID" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"mqtt\") | .client_id) = \"$MQTT_CLIENT_ID\"" "$CONFIG_PATH"
fi
yq -i "(.exports[] | select(.name == \"mqtt\") | .homeassistant) = $MQTT_HA" "$CONFIG_PATH"

# Custom HA sensors (YAML text field)
if [ -n "$MQTT_HA_SENSORS" ] && [ "$MQTT_HA_SENSORS" != "null" ]; then
    echo "$MQTT_HA_SENSORS" > /tmp/ha_sensors.yaml
    yq -i "(.exports[] | select(.name == \"mqtt\") | .ha_sensors) = load(\"/tmp/ha_sensors.yaml\")" "$CONFIG_PATH"
    rm -f /tmp/ha_sensors.yaml
fi

# ============================================================================
# HOME ASSISTANT DIRECT INTEGRATION
# ============================================================================
# Disabled - hassio.py export has a bug (references undefined url_base)
# MQTT with homeassistant discovery handles HA integration instead

# ============================================================================
# INFLUXDB EXPORT
# ============================================================================
INFLUXDB_ENABLED=$(bashio::config 'influxdb_enabled')
INFLUXDB_URL=$(bashio::config 'influxdb_url' '')
INFLUXDB_TOKEN=$(bashio::config 'influxdb_token' '')
INFLUXDB_USER=$(bashio::config 'influxdb_username' '')
INFLUXDB_PASS=$(bashio::config 'influxdb_password' '')
INFLUXDB_ORG=$(bashio::config 'influxdb_org' '')
INFLUXDB_BUCKET=$(bashio::config 'influxdb_bucket' '')
INFLUXDB_MEASUREMENTS=$(bashio::config 'influxdb_measurements' '')

yq -i "(.exports[] | select(.name == \"influxdb\") | .enabled) = $INFLUXDB_ENABLED" "$CONFIG_PATH"
if [ -n "$INFLUXDB_URL" ] && [ "$INFLUXDB_URL" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"influxdb\") | .url) = \"$INFLUXDB_URL\"" "$CONFIG_PATH"
fi
if [ -n "$INFLUXDB_TOKEN" ] && [ "$INFLUXDB_TOKEN" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"influxdb\") | .token) = \"$INFLUXDB_TOKEN\"" "$CONFIG_PATH"
fi
if [ -n "$INFLUXDB_USER" ] && [ "$INFLUXDB_USER" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"influxdb\") | .username) = \"$INFLUXDB_USER\"" "$CONFIG_PATH"
fi
if [ -n "$INFLUXDB_PASS" ] && [ "$INFLUXDB_PASS" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"influxdb\") | .password) = \"$INFLUXDB_PASS\"" "$CONFIG_PATH"
fi
if [ -n "$INFLUXDB_ORG" ] && [ "$INFLUXDB_ORG" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"influxdb\") | .org) = \"$INFLUXDB_ORG\"" "$CONFIG_PATH"
fi
if [ -n "$INFLUXDB_BUCKET" ] && [ "$INFLUXDB_BUCKET" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"influxdb\") | .bucket) = \"$INFLUXDB_BUCKET\"" "$CONFIG_PATH"
fi

# Custom measurements (YAML text field)
if [ -n "$INFLUXDB_MEASUREMENTS" ] && [ "$INFLUXDB_MEASUREMENTS" != "null" ]; then
    echo "$INFLUXDB_MEASUREMENTS" > /tmp/influxdb_measurements.yaml
    yq -i "(.exports[] | select(.name == \"influxdb\") | .measurements) = load(\"/tmp/influxdb_measurements.yaml\")" "$CONFIG_PATH"
    rm -f /tmp/influxdb_measurements.yaml
fi

# ============================================================================
# PVOUTPUT EXPORT
# ============================================================================
PVOUTPUT_ENABLED=$(bashio::config 'pvoutput_enabled')
PVOUTPUT_API=$(bashio::config 'pvoutput_api' '')
PVOUTPUT_SID=$(bashio::config 'pvoutput_sid' '')
PVOUTPUT_JOIN_TEAM=$(bashio::config 'pvoutput_join_team')
PVOUTPUT_RATE_LIMIT=$(bashio::config 'pvoutput_rate_limit' '')
PVOUTPUT_CUMULATIVE_FLAG=$(bashio::config 'pvoutput_cumulative_flag' '')
PVOUTPUT_BATCH_POINTS=$(bashio::config 'pvoutput_batch_points' '')
PVOUTPUT_PARAMETERS=$(bashio::config 'pvoutput_parameters' '')

# Always apply enabled (has default in config.yaml)
yq -i "(.exports[] | select(.name == \"pvoutput\") | .enabled) = $PVOUTPUT_ENABLED" "$CONFIG_PATH"
yq -i "(.exports[] | select(.name == \"pvoutput\") | .join_team) = $PVOUTPUT_JOIN_TEAM" "$CONFIG_PATH"
if [ -n "$PVOUTPUT_API" ] && [ "$PVOUTPUT_API" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"pvoutput\") | .api) = \"$PVOUTPUT_API\"" "$CONFIG_PATH"
fi
if [ -n "$PVOUTPUT_SID" ] && [ "$PVOUTPUT_SID" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"pvoutput\") | .sid) = \"$PVOUTPUT_SID\"" "$CONFIG_PATH"
fi
if [ -n "$PVOUTPUT_RATE_LIMIT" ] && [ "$PVOUTPUT_RATE_LIMIT" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"pvoutput\") | .rate_limit) = $PVOUTPUT_RATE_LIMIT" "$CONFIG_PATH"
fi
if [ -n "$PVOUTPUT_CUMULATIVE_FLAG" ] && [ "$PVOUTPUT_CUMULATIVE_FLAG" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"pvoutput\") | .cumulative_flag) = $PVOUTPUT_CUMULATIVE_FLAG" "$CONFIG_PATH"
fi
if [ -n "$PVOUTPUT_BATCH_POINTS" ] && [ "$PVOUTPUT_BATCH_POINTS" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"pvoutput\") | .batch_points) = $PVOUTPUT_BATCH_POINTS" "$CONFIG_PATH"
fi

# Custom parameters (YAML text field)
if [ -n "$PVOUTPUT_PARAMETERS" ] && [ "$PVOUTPUT_PARAMETERS" != "null" ]; then
    echo "$PVOUTPUT_PARAMETERS" > /tmp/pvoutput_parameters.yaml
    yq -i "(.exports[] | select(.name == \"pvoutput\") | .parameters) = load(\"/tmp/pvoutput_parameters.yaml\")" "$CONFIG_PATH"
    rm -f /tmp/pvoutput_parameters.yaml
fi

# ============================================================================
# CHARGEHQ EXPORT
# ============================================================================
CHARGEHQ_ENABLED=$(bashio::config 'chargehq_enabled')
CHARGEHQ_API_KEY=$(bashio::config 'chargehq_api_key' '')
CHARGEHQ_PUSH_INTERVAL=$(bashio::config 'chargehq_push_interval' '')
CHARGEHQ_REG_PRODUCTION=$(bashio::config 'chargehq_register_production' '')
CHARGEHQ_REG_CONSUMPTION=$(bashio::config 'chargehq_register_consumption' '')
CHARGEHQ_REG_NET_IMPORT=$(bashio::config 'chargehq_register_net_import' '')
CHARGEHQ_REG_BATTERY_POWER=$(bashio::config 'chargehq_register_battery_power' '')
CHARGEHQ_REG_BATTERY_SOC=$(bashio::config 'chargehq_register_battery_soc' '')
CHARGEHQ_INVERT_NET_IMPORT=$(bashio::config 'chargehq_invert_net_import')

# Always apply booleans that have defaults
yq -i "(.exports[] | select(.name == \"chargehq\") | .enabled) = $CHARGEHQ_ENABLED" "$CONFIG_PATH"
yq -i "(.exports[] | select(.name == \"chargehq\") | .invert_net_import) = $CHARGEHQ_INVERT_NET_IMPORT" "$CONFIG_PATH"
if [ -n "$CHARGEHQ_API_KEY" ] && [ "$CHARGEHQ_API_KEY" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"chargehq\") | .api_key) = \"$CHARGEHQ_API_KEY\"" "$CONFIG_PATH"
fi
if [ -n "$CHARGEHQ_PUSH_INTERVAL" ] && [ "$CHARGEHQ_PUSH_INTERVAL" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"chargehq\") | .push_interval) = $CHARGEHQ_PUSH_INTERVAL" "$CONFIG_PATH"
fi
if [ -n "$CHARGEHQ_REG_PRODUCTION" ] && [ "$CHARGEHQ_REG_PRODUCTION" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"chargehq\") | .register_production) = \"$CHARGEHQ_REG_PRODUCTION\"" "$CONFIG_PATH"
fi
if [ -n "$CHARGEHQ_REG_CONSUMPTION" ] && [ "$CHARGEHQ_REG_CONSUMPTION" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"chargehq\") | .register_consumption) = \"$CHARGEHQ_REG_CONSUMPTION\"" "$CONFIG_PATH"
fi
if [ -n "$CHARGEHQ_REG_NET_IMPORT" ] && [ "$CHARGEHQ_REG_NET_IMPORT" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"chargehq\") | .register_net_import) = \"$CHARGEHQ_REG_NET_IMPORT\"" "$CONFIG_PATH"
fi
if [ -n "$CHARGEHQ_REG_BATTERY_POWER" ] && [ "$CHARGEHQ_REG_BATTERY_POWER" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"chargehq\") | .register_battery_power) = \"$CHARGEHQ_REG_BATTERY_POWER\"" "$CONFIG_PATH"
fi
if [ -n "$CHARGEHQ_REG_BATTERY_SOC" ] && [ "$CHARGEHQ_REG_BATTERY_SOC" != "null" ]; then
    yq -i "(.exports[] | select(.name == \"chargehq\") | .register_battery_soc) = \"$CHARGEHQ_REG_BATTERY_SOC\"" "$CONFIG_PATH"
fi
# ============================================================================
# START SUNGATHER
# ============================================================================
bashio::log.info "Starting SunGather..."
source ./venv/bin/activate
exec python3 /sungather.py -c "$CONFIG_PATH" -l /share/SunGather/
