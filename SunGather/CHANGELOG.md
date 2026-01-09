# Changelog

## 0.1.5

- Expose all SunGather configuration options in the Home Assistant add-on UI
- Add human-readable field names and descriptions via translations
- Support for all export modules: Console, Webserver, MQTT, InfluxDB, PVOutput, ChargeHQ
- Add YAML text fields for custom sensors, measurements, and parameters
- Improve error message when inverter IP not configured
- Disable hassio export (has upstream bug, MQTT handles HA integration)
- Default use_local_time to true

## 0.1.4

- Move to Python virtual environment (venv) for better dependency isolation
- Update dependencies

## 0.1.3

- Fix missing SungrowClient
- Add support for SG8.0RS

## 0.1.1

- Pull SunGather v0.4.1
- Add custom MQTT server support

## 0.1.0

- Initial Home Assistant Add-on release
- MQTT auto-discovery support
- Web UI via ingress
