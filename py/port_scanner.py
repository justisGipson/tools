import csv
from ipaddress import ip_network
from typing import List

import nmap


def scan_ports(target: str) -> List[tuple]:
    nm = nmap.PortScanner()
    nm.scan(
        hosts=target,
        arguments="-sV",  # TCP scan all ports with version detection
        # hosts=target, arguments="-sT -p 1-65535 -T4"
    )  # TCP scan all ports with aggressive timing
    results = []

    for host in nm.all_hosts():
        for proto in nm[host].all_protocols():
            lport = nm[host][proto].keys()
            for port in lport:
                service = nm[host:str][proto:str][port:str]["state"]
                results.append(
                    (
                        host,
                        port,
                        proto,
                        service.get("name", ""),
                        service.get("state", ""),
                        service.get("product", ""),
                        service.get("extrainfo", ""),
                        service.get("reason", ""),
                        service.get("version", ""),
                        service.get("conf", ""),
                    )
                )

    return results


def write_to_file(results: List[tuple], output_file: str):
    fieldnames = [
        "host",
        "port",
        "protocol",
        "service_name",
        "state",
        "product",
        "extrainfo",
        "reason",
        "version",
        "conf",
    ]

    with open(output_file, "w", newline="") as csvfile:
        writer = csv.writer(csvfile, delimiter=",")
        writer.writerow(fieldnames)
        writer.writerows(results)


def main():
    target = input("Enter the target IP address and subnet (e.g., 192.168.1.0/24 ): ")

    try:
        ip_network(target)
    except ValueError:
        print(f"Invalid target: {target}")
        return

    output_file = f"{target.replace('/', '_')}_port_scan.csv"

    try:
        results = scan_ports(target)
        write_to_file(results, output_file)
        print(f"Scan results saved to {output_file}")
    except nmap.PortScannerError as e:
        print(f"Scan failed: {e}")
    except nmap.PortScannerHostDiscoveryError as e:
        print(f"Scan failed: {e}")
    except nmap.PortScannerTimeout as e:
        print(f"Scan timeout: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == "__main__":
    main()
