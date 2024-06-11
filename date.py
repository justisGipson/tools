from datetime import datetime, timezone

dt_str = "2023-08-03T20:26:15Z"


def datetime_to_unix_timestamp(dt_or_dt_str):
    """Convert datetime string in ISO 8601 format or datetime object to UNIX timestamp in milliseconds"""
    if isinstance(dt_or_dt_str, str):
        dt_obj = datetime.fromisoformat(dt_or_dt_str.replace("Z", "+00:00")).astimezone(
            timezone.utc
        )
    elif isinstance(dt_or_dt_str, datetime):
        dt_obj = dt_or_dt_str.astimezone(timezone.utc)
    else:
        raise ValueError("Invalid input. Expected string or datetime object.")

    unix_epoch = datetime(1970, 1, 1, tzinfo=timezone.utc)
    timestamp_milliseconds = (dt_obj - unix_epoch).total_seconds() * 1000
    return int(timestamp_milliseconds)


milliseconds_timestamp = datetime_to_unix_timestamp(dt_str)
print(milliseconds_timestamp)
print(type(milliseconds_timestamp))

"""
returns:

1691094375000
<class 'int'>

"""
