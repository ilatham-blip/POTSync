import time
import pandas as pd
import numpy as np
import scipy.signal as sg
import heartpy as hp

from e2epyppg.ppg_sqa import sqa
from e2epyppg.ppg_reconstruction import reconstruction
from e2epyppg.ppg_clean_extraction import clean_seg_extraction
from e2epyppg.ppg_peak_detection import peak_detection
from e2epyppg.ppg_hrv_extraction import hrv_extraction

time_start = time.time()

# 1. Load local Parquet file directly
file_path = r"C:\Users\tobyt\Imperial\Year 3 Group Project\Gitrepo\AntiGravity_HBrepo\heartbeat\02_data_analysis\data\opensignals3(1000hz).parquet"
print(f"Loading data from: {file_path}")

try:
    data = pd.read_parquet(file_path)
except Exception as e:
    print(f"Failed to load parquet file. Make sure it exists at the path. Error: {e}")
    exit(1)

A1 = data['A1'].values

sampling_rate = 1000
skip_seconds = 5
skip_samples = skip_seconds * sampling_rate

# Skip first 5 seconds
A1 = A1[skip_samples:]
print(pd.DataFrame(A1))

input_sig = A1

# =====================================================================
# PART 1: VISUAL PEAKS (Pure HeartPy, No Time-Warping)
# =====================================================================
print("\nExtracting perfectly aligned global peaks using pure HeartPy...")
sos_hp = sg.butter(4, [0.5, 8.0], btype='bandpass', fs=sampling_rate, output='sos')
sig_for_hp = sg.sosfiltfilt(sos_hp, input_sig)

try:
    wd, _ = hp.process(sig_for_hp, sample_rate=sampling_rate, windowsize=0.75, report_time=False)
    # Add the skipped samples back so the indices are global coordinates!
    flat_peaks = np.array(wd['peaklist']) + skip_samples
except Exception as e:
    print(f"Visual HeartPy processing failed: {e}")
    flat_peaks = np.array([])

# 4. Create a pandas DataFrame with the peaks
df_peaks = pd.DataFrame({
    'Peak_Sample': flat_peaks
})

# 5. Export to Parquet
output_filename = "HP3105N2_extracted_peaks.parquet"
df_peaks.to_parquet(output_filename, index=False)
print(f"Successfully saved {len(flat_peaks)} perfect peaks to {output_filename}")


# =====================================================================
# PART 2: ML HRV ANALYSIS (e2epyppg for advanced noise rejection)
# =====================================================================
print("\nRunning advanced e2epyppg ML analysis...")
window_length_sec = 150
filter_signal = True

print("Running SQA...")
clean_indices, noisy_indices = sqa(input_sig, sampling_rate, filter_signal)

print("Running Reconstruction...")
ppg_reconstructed, updated_clean_indices, updated_noisy_indices = reconstruction(
    input_sig, clean_indices, noisy_indices, sampling_rate, filter_signal
)

window_length = window_length_sec * sampling_rate
print("Running Clean Segment Extraction...")
clean_segments = clean_seg_extraction(ppg_reconstructed, updated_noisy_indices, window_length)

peak_detection_method = 'heartpy'
print(f"Running Peak Detection (Method: {peak_detection_method})...")
peaks = peak_detection(clean_segments, sampling_rate, peak_detection_method)

if not peaks:
    print("No peaks detected for HRV extraction.")
else:
    print("Running HRV Extraction...")
    hrv_data = hrv_extraction(clean_segments=clean_segments, peaks=peaks, sampling_rate=sampling_rate, window_length=window_length)
    hrv_data = hrv_data[['HR', 'HRV_MeanNN', 'HRV_RMSSD', 'HRV_LF', 'HRV_HF', 'HRV_LFHF']]
    print("\nHR and HRV parameters:")
    print(hrv_data)

print(f"\nTotal processing time: {time.time() - time_start:.2f} seconds")
