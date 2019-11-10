import datetime
import socket
from influxdb import InfluxDBClient
from pyhocon import ConfigFactory
import sys

def reportInfluxDBMetric(metric, value, host, port, db):
    json_body = {
        "tags": {
            "host": socket.gethostname()
        },
        "time": datetime.datetime.now().isoformat(),
        "points": [{
            "measurement": metric,
            "fields": {
                "value": value
            }
        }]
    }
    client = InfluxDBClient(host=host, database=db, use_udp=True, udp_port=port)
    client.send_packet(json_body)

if __name__ == '__main__':
    metric = str(sys.argv[1])
    value = float(sys.argv[2])
    config_path = str(sys.argv[3])

    conf = ConfigFactory.parse_file(config_path)
    influx_host = conf['influx_host']
    influx_port = conf['influx_port']
    influx_db = conf['influx_db']

    reportInfluxDBMetric(metric, value, influx_host, influx_port, influx_db)