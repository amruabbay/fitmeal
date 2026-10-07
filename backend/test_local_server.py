import requests

def test_server():
    url = "http://localhost:8000/search?q=nasi&page=0&limit=10"
    try:
        resp = requests.get(url)
        print("Status Code:", resp.status_code)
        print("Response JSON:", resp.json())
    except Exception as e:
        print("Failed to request server:", e)

if __name__ == '__main__':
    test_server()
