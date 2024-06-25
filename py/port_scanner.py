import concurrent.futures
import csv
from ipaddress import ip_network
from typing import List, Tuple

import nmap


def scan_host(host: str, port_range: str) -> List[Tuple]:
    print(f"Scanning host: {host}")
    nm = nmap.PortScanner()
    nm.scan(hosts=host, arguments=f"-sV -p {port_range}")
    results = []

    if host in nm.all_hosts():
        print(f"Host {host} is up")
        for proto in nm[host].all_protocols():
            lport = nm[host][proto].keys()
            for port in lport:
                service = nm[host][proto][port]
                print(f"Found open port: {host}:{port}")
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
    else:
        print(f"Host {host} is down")

    return results


def scan_network(target: str, port_range: str, max_workers: int = 50) -> List[Tuple]:
    network = ip_network(target)
    ip_list = [
        str(ip)
        for ip in network.hosts()
        if ip != network.network_address and ip != network.broadcast_address
    ]
    print(f"Scanning {len(ip_list)} hosts in network {target}")

    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = [executor.submit(scan_host, ip, port_range) for ip in ip_list]
        results = []
        for future in concurrent.futures.as_completed(futures):
            result = future.result()
            results.extend(result)

    return results


def write_to_file(results: List[Tuple], output_file: str):
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
    target = input("Enter the target IP address and subnet (e.g., 192.168.1.0/24): ")
    port_range = input("Enter the port range to scan (e.g., 1-1000): ")

    try:
        ip_network(target)
    except ValueError:
        print(f"Invalid target: {target}")
        return

    output_file = f"{target.replace('/', '_')}_port_scan.csv"

    results = scan_network(target, port_range)
    print(f"Scan completed, {len(results)} open ports found")
    write_to_file(results, output_file)
    print(f"Scan results saved to {output_file}")


if __name__ == "__main__":
    main()
