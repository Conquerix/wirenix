{
  version = "v1";
  subnets = [
    {
      name = "disjoint1";
      endpoints = [
        {
          # No match mean match any
          port = 51820;
        }
      ];
    }
    {
      name = "disjoint2";
      endpoints = [
        {
          # No match mean match any
          port = 51821;
        }
      ];
    }
  ];
  groups = [
    # groups field is expected, but can be empty
  ];
  peers = [
    {
      name = "node1";
      subnets = {
        disjoint1 = {
          listenPort = 51820;
          # empty ipAddresses will auto generate an IPv6 address
        };
      };
      publicKey = "kdyzqV8cBQtDYeW6R1vUug0Oe+KaytHHDS7JoCp/kTE=";
      privateKeyFile = "/etc/wg-key";
      endpoints = [
        {
          # no match can be any
          ip = "node1";
        }
      ];
    }
    {
      name = "node2";
      subnets = {
        disjoint1 = {
          listenPort = 51820;
        };
        disjoint2 = {
          listenPort = 51821;
        };
      };
      publicKey = "ztdAXTspQEZUNpxUbUdAhhRWbiL3YYWKSK0ZGdcsMHE=";
      privateKeyFile = "/etc/wg-key";
      endpoints = [
        {
          # no match can be any
          ip = "node2";
        }
      ];
    }
    {
      name = "node3";
      subnets = {
        disjoint2 = {
          listenPort = 51821;
        };
      };
      publicKey = "VR5SILc/2MkWSeGOVAJ/0Ru5H4DFheNvNUiT0fPtgiI=";
      privateKeyFile = "/etc/wg-key";
      endpoints = [
        {
          # no match can be any
          ip = "node3";
        }
      ];
    }
  ];
  connections = [
    {
      a = [{type= "subnet"; rule = "is"; value = "disjoint1";}];
      b = [{type= "subnet"; rule = "is"; value = "disjoint1";}];
    }
    {
      a = [{type= "subnet"; rule = "is"; value = "disjoint2";}];
      b = [{type= "subnet"; rule = "is"; value = "disjoint2";}];
    }
  ];
}