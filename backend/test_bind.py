import socket

hosts = ["127.0.0.1", "0.0.0.0", "localhost", "::1"]
ports = [8000, 8080, 9000, 18000]

for host in hosts:
    for port in ports:
        try:
            s = socket.socket(socket.AF_INET if ":" not in host and host != "::1" else socket.AF_INET6, socket.SOCK_STREAM)
            s.bind((host, port))
            s.listen(1)
            print(f"✅ SUCCESS: Bound to {host}:{port}")
            s.close()
        except Exception as e:
            print(f"❌ FAILED: Bound to {host}:{port} -> {e}")
