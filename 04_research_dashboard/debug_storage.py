import toml
from supabase import create_client

def test():
    try:
        secrets = toml.load(".streamlit/secrets.toml")
        supabase = create_client(secrets["supabase"]["SUPABASE_URL"], secrets["supabase"]["SUPABASE_KEY"])
        print("Connected to Supabase")
        
        print("\n--- Listing raw_uploads ---")
        try:
            res = supabase.storage.from_("raw_uploads").list("0c38de84-0fea-43ad-86b7-2689d0905aca")
            print("raw_uploads:")
            for item in res:
                print(f"  - {item['name']}")
        except Exception as e:
            print("Error listing raw_uploads:", e)
            
        print("\n--- Listing peak_indices ---")
        try:
            res = supabase.storage.from_("peak_indices").list("0c38de84-0fea-43ad-86b7-2689d0905aca")
            print("peak_indices:")
            for item in res:
                print(f"  - {item['name']}")
        except Exception as e:
            print("Error listing peak_indices:", e)
            
        print("\n--- Testing Download ---")
        # Let's try what we think the path is:
        path = "0c38de84-0fea-43ad-86b7-2689d0905aca/3e748661-763f-4d23-972e-863ecf5155fc.parquet"
        try:
            file_res = supabase.storage.from_("raw_uploads").download(path)
            print(f"Successfully downloaded {path}! Size: {len(file_res)} bytes")
        except Exception as e:
            print(f"Failed to download {path}:", e)
            
    except Exception as e:
        print("Setup error:", e)

if __name__ == "__main__":
    test()
