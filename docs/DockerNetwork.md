
# Change default Docker address pool

Add to (or create) the file  `/etc/docker/daemon.json`

```
{
  "bip": "192.168.32.1/24",
  "default-address-pools" : [
      {
          "base" : "192.168.33.0/24",
          "size" : 24
      }
   ]
}
```
`bip`: Bridge IP (`bip`) must not overlap with the `default-address-pools`.
