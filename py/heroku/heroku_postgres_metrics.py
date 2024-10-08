import sys
import time
from subprocess import CalledProcessError, check_output


def convert_bytes_to_gb(bytes_value):
    return round(bytes_value / 1000000000, 2)


def convert_kb_to_gb(kb_value):
    if isinstance(kb_value, str) and kb_value.endswith("kB"):
        kb_value = int(kb_value[:-2])
    return round(kb_value / 1000000, 2)


def convert_percentage_to_percent(percentage):
    return round(percentage * 100, 2)


def get_source_type(source):
    if source == "HEROKU_POSTGRESQL_GRAY":
        return "PROD-FOLLOWER"
    else:
        return "PROD-PRIMARY"


def fetch_heroku_logs(app_name):
    try:
        logs = check_output(
            ["heroku", "logs", "-p", "heroku-postgres", "-a", app_name],
            universal_newlines=True,
        )
        return logs
    except CalledProcessError as e:
        print(f"Error fetching Heroku Postgres logs for app '{app_name}': {e}")
        return None


def parse_metrics(line):
    metrics = {}
    source = next(
        (s.split("=")[1] for s in line.split() if s.startswith("source=")), None
    )
    metrics["Source"] = get_source_type(source)

    metrics["Active Connections"] = int(
        next(
            (
                s.split("=")[1]
                for s in line.split()
                if s.startswith("sample#active-connections=")
            ),
            0,
        )
    )
    metrics["Waiting Connections"] = int(
        next(
            (
                s.split("=")[1]
                for s in line.split()
                if s.startswith("sample#waiting-connections=")
            ),
            0,
        )
    )
    metrics["Max Connections"] = int(
        next(
            (
                s.split("=")[1]
                for s in line.split()
                if s.startswith("sample#max-connections=")
            ),
            0,
        )
    )
    metrics["Connections Percentage Used"] = convert_percentage_to_percent(
        float(
            next(
                (
                    s.split("=")[1]
                    for s in line.split()
                    if s.startswith("sample#connections-percentage-used=")
                ),
                0,
            )
        )
    )

    metrics["Load Average (1m)"] = float(
        next(
            (
                s.split("=")[1]
                for s in line.split()
                if s.startswith("sample#load-avg-1m=")
            ),
            0,
        )
    )
    metrics["Load Average (5m)"] = float(
        next(
            (
                s.split("=")[1]
                for s in line.split()
                if s.startswith("sample#load-avg-5m=")
            ),
            0,
        )
    )
    metrics["Load Average (15m)"] = float(
        next(
            (
                s.split("=")[1]
                for s in line.split()
                if s.startswith("sample#load-avg-15m=")
            ),
            0,
        )
    )

    metrics["Read IOPS"] = float(
        next(
            (
                s.split("=")[1]
                for s in line.split()
                if s.startswith("sample#read-iops=")
            ),
            0,
        )
    )
    metrics["Write IOPS"] = float(
        next(
            (
                s.split("=")[1]
                for s in line.split()
                if s.startswith("sample#write-iops=")
            ),
            0,
        )
    )
    metrics["Max IOPS"] = get_max_iops(metrics["Source"])
    metrics["IOPS Percentage Used"] = convert_percentage_to_percent(
        float(
            next(
                (
                    s.split("=")[1]
                    for s in line.split()
                    if s.startswith("sample#iops-percentage-used=")
                ),
                0,
            )
        )
    )

    metrics["Temporary Disk Used"] = convert_bytes_to_gb(
        int(
            next(
                (
                    s.split("=")[1]
                    for s in line.split()
                    if s.startswith("sample#tmp-disk-used=")
                ),
                0,
            )
        )
    )
    metrics["Temporary Disk Available"] = convert_bytes_to_gb(
        int(
            next(
                (
                    s.split("=")[1]
                    for s in line.split()
                    if s.startswith("sample#tmp-disk-available=")
                ),
                0,
            )
        )
    )

    metrics["Memory Total"] = convert_kb_to_gb(
        next(
            (
                s.split("=")[1]
                for s in line.split()
                if s.startswith("sample#memory-total=")
            ),
            "0kB",
        )
    )
    metrics["Memory Free"] = convert_kb_to_gb(
        next(
            (
                s.split("=")[1]
                for s in line.split()
                if s.startswith("sample#memory-free=")
            ),
            "0kB",
        )
    )
    metrics["Memory Percentage Used"] = convert_percentage_to_percent(
        float(
            next(
                (
                    s.split("=")[1]
                    for s in line.split()
                    if s.startswith("sample#memory-percentage-used=")
                ),
                0,
            )
        )
    )
    metrics["Memory Cached"] = convert_kb_to_gb(
        next(
            (
                s.split("=")[1]
                for s in line.split()
                if s.startswith("sample#memory-cached=")
            ),
            "0kB",
        )
    )
    metrics["Memory Postgres"] = convert_kb_to_gb(
        next(
            (
                s.split("=")[1]
                for s in line.split()
                if s.startswith("sample#memory-postgres=")
            ),
            "0kB",
        )
    )

    return metrics


def get_max_iops(source_type):
    if source_type == "PROD-PRIMARY":
        return 12000
    elif source_type == "PROD-FOLLOWER":
        return 3000
    else:
        return 0


def main():
    if len(sys.argv) != 3:
        print(
            "Usage: python heroku_postgres_metrics.py <app_name> <duration_in_minutes>"
        )
        return

    app_name = sys.argv[1]
    duration_in_minutes = int(sys.argv[2])
    output_file = f"heroku_postgres_metrics_{app_name}_{duration_in_minutes}min.txt"

    start_time = time.time()
    end_time = start_time + (duration_in_minutes * 60)

    primary_metrics_data = []
    follower_metrics_data = []

    while time.time() < end_time:
        logs = fetch_heroku_logs(app_name)
        if logs:
            for line in logs.splitlines():
                if "sample#" in line:
                    metrics = parse_metrics(line)
                    if metrics["Source"] == "PROD-PRIMARY":
                        primary_metrics_data.append(metrics)
                    elif metrics["Source"] == "PROD-FOLLOWER":
                        follower_metrics_data.append(metrics)

        time.sleep(10)

    with open(output_file, "w") as f:
        f.write("Heroku Postgres Metrics Summary:\n")
        f.write("- Source: MIXED\n\n")

        if primary_metrics_data:
            f.write("Primary Database:\n")
            for metric, values in calculate_metrics(primary_metrics_data).items():
                if metric != "Source" and metric != "Max IOPS":
                    f.write(f"  - {metric}:\n")
                    f.write(f"    - Average: {values['average']}\n")
                    f.write(f"    - Minimum: {values['minimum']}\n")
                    f.write(f"    - Maximum: {values['maximum']}\n")
            f.write(f"  - Max IOPS: {get_max_iops('PROD-PRIMARY')}\n\n")

        if follower_metrics_data:
            f.write("Follower Database:\n")
            for metric, values in calculate_metrics(follower_metrics_data).items():
                if metric != "Source" and metric != "Max IOPS":
                    f.write(f"  - {metric}:\n")
                    f.write(f"    - Average: {values['average']}\n")
                    f.write(f"    - Minimum: {values['minimum']}\n")
                    f.write(f"    - Maximum: {values['maximum']}\n")
            f.write(f"  - Max IOPS: {get_max_iops('PROD-FOLLOWER')}\n\n")

        f.write(f"Metrics collected over {duration_in_minutes} minutes.\n")

    print(f"Heroku Postgres metrics have been saved to '{output_file}'.")


def calculate_metrics(metrics_data):
    result = {}
    for metric in metrics_data[0].keys():
        if metric != "Source" and metric != "Max IOPS" and metric != "Max Connections":
            values = [d[metric] for d in metrics_data]
            numeric_values = [v for v in values if isinstance(v, (int, float))]
            result[metric] = {
                "average": sum(numeric_values) / len(numeric_values),
                "minimum": min(numeric_values),
                "maximum": max(numeric_values),
            }
    return result


if __name__ == "__main__":
    main()
