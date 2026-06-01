import os
import toml
from supabase import create_client, Client
import pandas as pd
import io
import heartpy as hp
import numpy as np

# 1. Load Supabase Secrets
try:
    with open(".streamlit/secrets.toml", "r") as f:
        secrets = toml.load(f)
    url = secrets["supabase"]["SUPABASE_URL"]
    key = secrets["supabase"]["SUPABASE_KEY"]
except Exception as e:
    print(f"Error loading secrets: {e}")
    exit(1)

supabase: Client = create_client(url, key)

# 2. Get the specific measurement ID from the screenshot
measurement_id = "3e748661" # We will query for it

response = supabase.table('measurements').select('measurement_id, raw_file_path').execute()
target_measurement = None
for r in response.data:
    if str(r['measurement_id']).startswith(measurement_id):
        target_measurement = r
        break

if not target_measurement:
    print(f"Measurement starting with {measurement_id} not found.")
    exit(1)

print(f"Found measurement: {target_measurement['measurement_id']}")
file_path = target_measurement['raw_file_path']

# 3. Download the raw file
print(f"Downloading raw file: {file_path}")
raw_res = supabase.storage.from_("raw_uploads").download(file_path)
raw_df = pd.read_parquet(io.BytesIO(raw_res))

# 4. Process with pure HeartPy (NO TIME WARPING)
print("Processing with pure HeartPy on raw A1 channel...")
signal = raw_df['A1'].values
fs = 1000

# We filter the signal first to get clean peaks (HeartPy likes it a bit cleaner)
# But we DO NOT resample or stretch it!
import scipy.signal as sg
sos = sg.butter(4, [5.0, 80.0], btype='bandpass', fs=fs, output='sos')
filtered_signal = sg.sosfiltfilt(sos, signal)

# Run HeartPy
wd, m = hp.process(filtered_signal, sample_rate=fs, windowsize=0.75, report_time=False)

peaks = wd['peaklist']
print(f"Found {len(peaks)} peaks.")

# 5. Create new peaks DataFrame and upload
df_peaks = pd.DataFrame({'peak_index': peaks})
peaks_parquet = df_peaks.to_parquet()

print("Uploading perfectly aligned peaks to Supabase...")
supabase.storage.from_('peak_indices').update(
    path=file_path,
    file=peaks_parquet,
    file_options={"content-type": "application/octet-stream"}
)
print("Done! The database is fixed.")
