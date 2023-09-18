{
  version = "v1";
  subnets = [
    {
      name = "manual-ipv6";
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
      name = "node1";
      subnets = {
        manual-ipv6 = {
          ipAddresses = [
            "fc00::1"
          ];
          listenPort = 51820;
        };
      };
      publicKey = "kdyzqV8cBQtDYeW6R1vUug0Oe+KaytHHDS7JoCp/kTE=";
      privateKeyFile = "/etc/wg-key";
      #privateKey = "MIELhEc0I7BseAanhk/+LlY/+Yf7GK232vKWITExnEI=";  # path is relative to the machine
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
        manual-ipv6 = {
          ipAddresses = [
            "fc00::2"
          ];
          listenPort = 51820;
        };
      };
      publicKey = "ztdAXTspQEZUNpxUbUdAhhRWbiL3YYWKSK0ZGdcsMHE=";
      privateKeyFile = "/etc/wg-key";
      #privateKey = "yG4mJiduoAvzhUJMslRbZwOp1gowSfC+wgY8B/Mul1M=";
      endpoints = [
        {
          # no match can be any
          ip = "node2";
        }
      ];
    }
  ];
  connections = [
    {
      a = [{type= "subnet"; rule = "is"; value = "manual-ipv6";}];
      b = [{type= "subnet"; rule = "is"; value = "manual-ipv6";}];
    }
  ];
}