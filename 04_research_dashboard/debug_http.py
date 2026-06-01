import toml
import requests

def test():
    secrets = toml.load(".streamlit/secrets.toml")
    url = secrets["supabase"]["SUPABASE_URL"]
    
    # Construct public URL
    path = "0c38de84-0fea-43ad-86b7-2689d0905aca/3e748661-763f-4d23-972e-863ecf5155fc.parquet"
    public_url = f"{url}/storage/v1/object/public/raw_uploads/{path}"
    
    print(f"Testing public URL: {public_url}")
    res = requests.get(public_url)
    print(f"Status: {res.status_code}")
    if res.status_code != 200:
        print("Response:", res.text)
        
    # Construct authenticated URL
    print(f"\nTesting authenticated URL (using anon key)...")
    auth_url = f"{url}/storage/v1/object/raw_uploads/{path}"
    headers = {
        "apikey": secrets["supabase"]["SUPABASE_KEY"],
        "Authorization": f"Bearer {secrets['supabase']['SUPABASE_KEY']}"
    }
    res2 = requests.get(auth_url, headers=headers)
    print(f"Status: {res2.status_code}")
    if res2.status_code != 200:
        print("Response:", res2.text)

if __name__ == "__main__":
    test()
