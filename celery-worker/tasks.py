from celery_app import celery_app
from supabase import create_client
import os
import pandas as pd
from io import BytesIO
from dotenv import load_dotenv
import numpy as np

# Your e2epyppg imports
from e2epyppg.ppg_sqa import sqa
from e2epyppg.ppg_reconstruction import reconstruction
from e2epyppg.ppg_clean_extraction import clean_seg_extraction
from e2epyppg.ppg_peak_detection import peak_detection
from e2epyppg.ppg_hrv_extraction import hrv_extraction



# Load Environment Variables
load_dotenv()
url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_KEY")

if not url or not key:
    print("Error: Missing SUPABASE_URL or SUPABASE_SERVICE_KEY in .env file")
    exit()

# Create Supabase client
supabase = create_client(url, key)
print(f"✅ Connected to: {url}")




#Access Supabase and the required patient information
def get_measurement_by_id(measurement_id: str):
    """
    Retrieve measurement metadata from the database
    
    Args:
        measurement_id: The ID of the measurement to retrieve
        
    Returns:
        dict: Measurement data including raw_file_path
    """
    print(f"\n--- RETRIEVING MEASUREMENT {measurement_id} ---")
    
    try:
        response = supabase.table('measurements').select('*').eq('measurement_id', measurement_id).execute()
        
        if not response.data or len(response.data) == 0:
            print(f"❌ No measurement found with ID: {measurement_id}")
            return None
        
        measurement = response.data[0]
        print(f"✅ Found measurement:")
        print(f"   User ID: {measurement.get('user_id')}")
        print(f"   Recorded at: {measurement.get('recorded_at')}")
        print(f"   Heart Rate: {measurement.get('heart_rate')}")
        print(f"   HRV Score: {measurement.get('hrv_score')}")
        print(f"   Raw File Path: {measurement.get('raw_file_path')}")
        
        return measurement
        
    except Exception as e:
        print(f"❌ Error retrieving measurement: {e}")
        return None

def download_ppg_file(raw_file_path: str , bucket_name: str = 'raw_uploads'):
    """
    Download PPG file from Supabase Storage bucket
    
    Args:
        raw_file_path: Path to the file in the bucket (e.g., 'user123/recording_20240125.csv')
        bucket_name: Name of the Supabase storage bucket
        
    Returns:
        pandas.DataFrame: The PPG signal data
    """
    print(f"\n--- DOWNLOADING FILE FROM BUCKET ---")
    print(f"   Bucket: {bucket_name}")
    print(f"   Path: {raw_file_path}")
    
    try:
        # Download file from Supabase Storage
        response = supabase.storage.from_(bucket_name).download(raw_file_path)
        
        # Convert bytes to pandas DataFrame
        if raw_file_path.endswith('.json'):
            import json
            data = json.loads(response.decode('utf-8'))
            df = pd.DataFrame(data)
        else:
            df = pd.read_parquet(BytesIO(response))
        
        print(f"✅ File downloaded successfully!")
        print(f"   Shape: {df.shape}")
        print(f"   Columns: {df.columns.tolist()}")
        print(f"\n   Preview:")
        print(df.head())
        
        return df
        
    except Exception as e:
        print(f"❌ Error downloading file: {e}")
        print(f"   Make sure the bucket '{bucket_name}' exists and the file path is correct")
        return None

def load_ppg_into_pipeline(measurement_id: str, bucket_name: str = 'raw_uploads'):
    """
    Complete workflow: Retrieve measurement metadata, download file, and load into pipeline
    
    Args:
        measurement_id: The measurement ID to process
        bucket_name: Name of the Supabase storage bucket
        
    Returns:
        tuple: (measurement_metadata, ppg_dataframe)
    """
    print("\n" + "="*60)
    print(f"LOADING PPG DATA FOR MEASUREMENT: {measurement_id}")
    print("="*60)
    
    # Step 1: Get measurement metadata from database
    measurement = get_measurement_by_id(measurement_id)
    if not measurement:
        return None, None
    
    # Step 2: Extract file path
    raw_file_path = str(measurement.get('raw_file_path')).strip()
    user_id = str(measurement.get('user_id')).strip()
    
    if not raw_file_path or raw_file_path == 'None':
        print("❌ No raw_file_path found in measurement record")
        return measurement, None
        
    # Auto-correct the path if the mobile app only saved the UUID
    if '/' not in raw_file_path:
        if raw_file_path == user_id:
            raw_file_path = f"{user_id}/{measurement_id}.json"
        else:
            raw_file_path = f"{user_id}/{raw_file_path}"
    if not raw_file_path.endswith('.parquet') and not raw_file_path.endswith('.csv') and not raw_file_path.endswith('.json'):
        raw_file_path = f"{raw_file_path}.json"
    
    # Step 3: Download and load PPG file
    ppg_df = download_ppg_file(raw_file_path, bucket_name)
    if ppg_df is None:
        return measurement, None
        
    # Step 4: Convert to Parquet if it was JSON
    if raw_file_path.endswith('.json'):
        print(f"\n--- CONVERTING JSON TO PARQUET ---")
        parquet_path = raw_file_path.replace('.json', '.parquet')
        parquet_buffer = BytesIO()
        ppg_df.to_parquet(parquet_buffer, index=False)
        parquet_buffer.seek(0)
        
        try:
            # Upload new Parquet file
            supabase.storage.from_(bucket_name).upload(
                path=parquet_path,
                file=parquet_buffer.getvalue(),
                file_options={"content-type": "application/octet-stream", "upsert": "true"}
            )
            print(f"✅ Uploaded {parquet_path}")
            
            # Delete old JSON file
            supabase.storage.from_(bucket_name).remove([raw_file_path])
            print(f"✅ Deleted old {raw_file_path}")
            
            # Update measurements table with new path
            supabase.table('measurements').update({'raw_file_path': parquet_path}).eq('measurement_id', measurement_id).execute()
            measurement['raw_file_path'] = parquet_path
            print(f"✅ Updated raw_file_path in database to {parquet_path}")
        except Exception as e:
            print(f"❌ Error during Parquet conversion/upload: {e}")
    
    print("\n" + "="*60)
    print("✅ READY FOR PROCESSING")
    print("="*60)
    
    return measurement, ppg_df





@celery_app.task(name='process_ppg_measurement')
def ppg_processing(measurement_id):
    """
    Celery task to process PPG measurement with e2epyppg
    
    Args:
        measurement_id: UUID of the measurement to process
    """

    measurement, ppg_df = load_ppg_into_pipeline(measurement_id)

    data = ppg_df

    A1 = data['A1'].values
    input_sig = A1
    
    # Bitalino raw ECG sampling rate is 1000 Hz
    sampling_rate = 1000

    import heartpy as hp
    import scipy.signal as sg
    import numpy as np
    
    # =====================================================================
    # PART 1: VISUAL PEAKS FOR DASHBOARD (Pure HeartPy, No Time-Warping)
    # =====================================================================
    # Filter the signal to remove baseline wander, optimal for peak finding
    sos_hp = sg.butter(4, [0.5, 8.0], btype='bandpass', fs=sampling_rate, output='sos')
    sig_for_hp = sg.sosfiltfilt(sos_hp, input_sig)
    
    try:
        wd, _ = hp.process(sig_for_hp, sample_rate=sampling_rate, windowsize=0.75, report_time=False)
        flat_peaks = np.array(wd['peaklist'])
    except Exception as e:
        print(f"Visual HeartPy processing failed: {e}")
        flat_peaks = np.array([])

    df_peaks = pd.DataFrame({'Peak Sample': flat_peaks})

    user_id = measurement.get('user_id')
    peaks_filename = f"{user_id}/{measurement_id}_peaks.parquet"
    peaks_buffer = BytesIO()
    df_peaks.to_parquet(peaks_buffer, index=False)
    peaks_buffer.seek(0)

    supabase.storage.from_('peak_indices').upload(
        path=peaks_filename,
        file=peaks_buffer.getvalue(),
        file_options={"content-type": "application/octet-stream"}
    )

    # =====================================================================
    # PART 2: ML HRV ANALYSIS (e2epyppg for advanced noise rejection)
    # =====================================================================
    print("Running e2epyppg ML models for advanced HRV analysis...")
    from e2epyppg.ppg_sqa import sqa
    from e2epyppg.ppg_reconstruction import reconstruction
    from e2epyppg.ppg_clean_extraction import clean_seg_extraction
    from e2epyppg.ppg_peak_detection import peak_detection
    from e2epyppg.ppg_hrv_extraction import hrv_extraction
    
    window_length_sec = 120
    filter_signal = True
    
    try:
        clean_indices, noisy_indices = sqa(input_sig, sampling_rate, filter_signal)
        ppg_reconstructed, updated_clean_indices, updated_noisy_indices = reconstruction(input_sig, clean_indices, noisy_indices, sampling_rate, filter_signal)
        
        window_length = window_length_sec * sampling_rate
        clean_segments = clean_seg_extraction(ppg_reconstructed, updated_noisy_indices, window_length)
        
        e2e_peaks = peak_detection(clean_segments, sampling_rate, 'heartpy')
        
        if not e2e_peaks:
            raise ValueError("No peaks detected in clean segments.")
            
        hrv_data = hrv_extraction(clean_segments=clean_segments, peaks=e2e_peaks, sampling_rate=sampling_rate, window_length=window_length)
        
        print("Uploading advanced e2epyppg metrics to database.")
        supabase.table('measurements').update({
            'heart_rate': float(hrv_data['HR'][0]) if pd.notna(hrv_data['HR'][0]) else None,
            'mean_nn': float(hrv_data['HRV_MeanNN'][0]) if pd.notna(hrv_data['HRV_MeanNN'][0]) else None,
            'rmssd': float(hrv_data['HRV_RMSSD'][0]) if pd.notna(hrv_data['HRV_RMSSD'][0]) else None,
            'lf': float(hrv_data['HRV_LF'][0]) if pd.notna(hrv_data['HRV_LF'][0]) else None,
            'hf': float(hrv_data['HRV_HF'][0]) if pd.notna(hrv_data['HRV_HF'][0]) else None,
            'lf_hf_ratio': float(hrv_data['HRV_LFHF'][0]) if pd.notna(hrv_data['HRV_LFHF'][0]) else None,
            'peaks_file_path': peaks_filename,
        }).eq('measurement_id', measurement_id).execute()  
        
    except Exception as e:
        print(f"e2epyppg HRV analysis failed: {e}")




  

