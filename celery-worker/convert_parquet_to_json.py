import os
from io import BytesIO
import json
import pandas as pd
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

supabase_url = os.getenv("SUPABASE_URL") or "https://lxagctltenlyhoyfpegd.supabase.co"
supabase_key = os.getenv("SUPABASE_SERVICE_KEY")

if not supabase_key:
    print("[Error] SUPABASE_SERVICE_KEY environment variable is not set.")
    print("Please run this script in the terminal where your Celery worker environment is configured.")
    exit(1)

supabase = create_client(supabase_url, supabase_key)
bucket_name = "raw_uploads"

def convert():
    print("Fetching measurements with parquet files...")
    res = supabase.table("measurements").select("measurement_id, raw_file_path").execute()
    measurements = res.data or []
    
    converted_count = 0
    for m in measurements:
        measurement_id = m.get("measurement_id")
        path = m.get("raw_file_path")
        
        # We only want to convert user raw uploads, skip test files like test_signal.parquet
        if path and path.endswith(".parquet") and "test_signal" not in path:
            json_path = path.replace(".parquet", ".json")
            print(f"\nProcessing {path} -> {json_path}...")
            
            try:
                # 1. Download parquet file
                res_download = supabase.storage.from_(bucket_name).download(path)
                df = pd.read_parquet(BytesIO(res_download))
                
                # Convert the dataframe back to a flat list
                if df.shape[1] > 0:
                    first_col = df.columns[0]
                    data_list = df[first_col].astype(float).tolist()
                else:
                    data_list = []
                
                # 2. Upload JSON file
                json_bytes = json.dumps(data_list).encode('utf-8')
                supabase.storage.from_(bucket_name).upload(
                    path=json_path,
                    file=json_bytes,
                    file_options={"content-type": "application/json", "upsert": "true"}
                )
                print(f"[OK] Uploaded {json_path}")
                
                # 3. Delete Parquet file
                supabase.storage.from_(bucket_name).remove([path])
                print(f"[OK] Deleted old {path}")
                
                # 4. Update measurements raw_file_path
                supabase.table("measurements").update({"raw_file_path": json_path}).eq("measurement_id", measurement_id).execute()
                print(f"[OK] Updated measurements raw_file_path to JSON")
                
                # 5. Update referencing check-ins (wrap filters in double quotes for JSONB)
                json_filter_val = f'"{path}"' # matches the parquet path currently in checkins
                
                # Update morning_checkins
                res_m_ppg = supabase.table("morning_checkins").update({"ppg_data": json_path}).eq("ppg_data", json_filter_val).execute()
                if res_m_ppg.data:
                    print("   Updated morning_checkins ppg_data")
                res_m_ecg = supabase.table("morning_checkins").update({"ecg_data": json_path}).eq("ecg_data", json_filter_val).execute()
                if res_m_ecg.data:
                    print("   Updated morning_checkins ecg_data")
                    
                # Update evening_checkins
                res_e_ppg = supabase.table("evening_checkins").update({"ppg_data": json_path}).eq("ppg_data", json_filter_val).execute()
                if res_e_ppg.data:
                    print("   Updated evening_checkins ppg_data")
                res_e_ecg = supabase.table("evening_checkins").update({"ecg_data": json_path}).eq("ecg_data", json_filter_val).execute()
                if res_e_ecg.data:
                    print("   Updated evening_checkins ecg_data")
                    
                converted_count += 1
                
            except Exception as e:
                print(f"[ERROR] Error processing {path}: {str(e)}")
                
    print(f"\nFinished! Converted {converted_count} files back to JSON.")

if __name__ == "__main__":
    convert()
