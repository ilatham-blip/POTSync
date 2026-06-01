import toml
import pandas as pd
from supabase import create_client
import io

def test():
    secrets = toml.load(".streamlit/secrets.toml")
    supabase = create_client(secrets["supabase"]["SUPABASE_URL"], secrets["supabase"]["SUPABASE_KEY"])
    
    path = "0c38de84-0fea-43ad-86b7-2689d0905aca/3e748661-763f-4d23-972e-863ecf5155fc.parquet"
    res = supabase.storage.from_("raw_uploads").download(path)
    
    df = pd.read_parquet(io.BytesIO(res))
    print("Raw DataFrame Info:")
    print("Columns:", df.columns.tolist())
    print("\nHead:")
    print(df.head())
    
    print("\nDescriptive Stats:")
    print(df.describe())

if __name__ == "__main__":
    test()
