{
  version = "v1";
  subnets = [
    {
      name = "myMesh";
      endpoints = [
        {
          # No match mean match any
          port = 51820;
        }
      ];
    }
  ];
  groups = [
    # groups field is expected, but can be empty
  ];
  peers = [
    {
      name = "peer1";
      subnets = {
        myMesh = {
          listenPort = 51820;
          # empty ipAddresses will auto generate an IPv6 address
        };
      };
      publicKey = "t2kmvyJbDle433HCUlP48HxGlLdd8HyiRi2y8aYvTV8=";
      privateKeyFile = "/path/to/private/key";  # path is relative to the machine
      endpoints = [
        {
          # no match can be any
          ip = "192.168.1.11";
        }
      ];
    }
    {
      name = "peer2";
      subnets = {
        myMesh = {
          listenPort = 51820;
        };
      };
      publicKey = "xTiftEK/lzqxJYtbH8tt8yINEnSq7tTEN46hXTr9X2M=";
      privateKeyFile = "/path/to/private/key";
      endpoints = [
        {
          # no match can be any
          ip = "192.168.1.12";
        }
      ];
    }
    {
      name = "peer3";
      subnets = {
        myMesh = {
          listenPort = 51820;
        };
      };
      endpoints = [
      {
        # no match can be any
        ip = "192.168.1.13";
      }
      ];
      publicKey = "jSp9uutNwpNHn1XjeQb9ixCixBSjvsRi2uYIiM2LORE=";
      privateKeyFile = "/path/to/private/key";
    }
  ];
  connections = [
    {
      a = [{type= "subnet"; rule = "is"; value = "myMesh";}];
      b = [{type= "subnet"; rule = "is"; value = "myMesh";}];
    }
  ];
}