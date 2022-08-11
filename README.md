# Wireguard Lab (docker-compose)

## Requirements

### Linux

- Docker
- docker-compose

### Windows

- Windows 10/11
- `>= 5.4` WSL 2 Kernel
- Docker Desktop w/ WSL 2 backend
- Docker + docker-compose installed in WSL 2 distro

## Lab

### Run Stack

`sudo docker-compose up -d`

3 containers should be running:

- server1
- server2
- server3

### Setup wireguard on server1

1. Connect via SSH to server1: `ssh -p 55555 lab@localhost` (pw: s3cr3t)
2. Generate wireguard private key: `wg genkey | sudo tee /etc/wireguard/private.key`
3. Take note of the private key for server1
4. Limit permissions on private key: `sudo chmod go= /etc/wireguard/private.key`
5. Generate wireguard public key: `sudo cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key`
6. Take note of the public key for server1
7. Create wireguard interface configuration with IP 10.0.0.1: `sudo vim /etc/wireguard/wg0.conf`

#### Structure

```
[Interface]
PrivateKey = <base64 encoded private key>
SaveConfig = true
ListenPort = 51337
Address = <CIDR notation>
```

#### Example

```
[Interface]
PrivateKey = CF/WADNbVxe+G14hojxMuWtqRk4AMV+i3qSx8tih5k0=
SaveConfig = true
ListenPort = 51337
Address = 10.0.0.1/24
```

8. Get familiar with the `SaveConfig` setting by consulting the official wireguard documentation.
9. Setup interface: `sudo systemctl enable wg-quick@wg0.service`
10. Usually we would now start the service with systemctl but docker does not like systemd services :) so we just `cat` the service file and run the startup command like so: `sudo wg-quick up wg0`
11. Check if the interface is correctly configured and up:
    1. `sudo wg` output should show the interface config for wg0
    2. `ip -br a` should show an interface wg0 with the configured IP/range (state UNKNOWN is correct)

### Setup wireguard on server2

Same steps as for server1 but with server2 keys and IP address 10.0.0.2/24

### Connect server1 and server2 via wireguard tunnel

1. On server1 edit the wg0.conf file and add a new peer with the data of server2 in this format:

```
[Peer]
PublicKey = <base 64 encoded public key>
AllowedIPs = <CIDR notation>
Endpoint = <public IP>:<wireguard UDP port>
```

*Here it is important to have a /32 net mask for the AllowedIPs for the server2. This makes sure server2 can only connect with that IP!*

#### Example

```
[Peer]
PublicKey = n61suSkYmFzuwzz1e9IFuUu/TtyGnMzs0nQt5PFWf1c=
AllowedIPs = 10.0.0.2/32
Endpoint = 172.20.0.3:51337
```

2. Reload the interface configuration: `sudo bash -c 'wg syncconf wg0 <(wg-quick strip wg0)'`
3. Confirm the changes loaded successfully and `sudo wg` shows the interface together with the configured peer
4. On server2 edit the wg0.conf file in the same way as for server1 but with server1's public key, allowed IP and endpoint IP
5. Reload the config on server2

#### Confirm successful tunnel connection between server1 and server2

On server1 you should be able to ping server2 through the tunnel: `ping 10.0.0.2`

If everything is OK, `sudo wg` should now show some data was sent/received to/from the peer.

## Tasks

- Add server3 to server1 and server2 with IP address 10.0.0.3/24.

- Use tcpdump on server3 to see and compare traffic flowing to the server unencrypted (outside the tunnel) and encrypted (through the tunnel)

  *Tips*

  - it's easy to use a python server `python3 -m http.server 80` or netcat `nc -vlp 80 -s <interface-IP>` for the traffic destination on server3
  - use curl or netcat to connect from server1 or 2 to server3
  - reduce clutter in your tcpdump output by filtering ARP, SSH and potential other traffic; for example like this: `sudo tcpdump -i eth0 -s 0 -A '(port not ssh and port not domain and not arp and not llc)'`

- *Advanced:* Setup a firewall on each server container and configure it so that servers can talk to applications/ports on another server through the wireguard tunnel. **This was not tested** and it is probably not possible to setup a firewall inside the containers. If you want to invest some time, you could spin up some VMs to do this successfully.

