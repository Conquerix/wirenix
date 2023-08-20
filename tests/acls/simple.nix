{
  version = "v1";
  subnets = [
    {
      name = "simple";
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
        simple = {
          listenPort = 51820;
          # empty ipAddresses will auto generate an IPv6 address
        };
      };
      publicKey = "kdyzqV8cBQtDYeW6R1vUug0Oe+KaytHHDS7JoCp/kTE=";
      privateKey = "MIELhEc0I7BseAanhk/+LlY/+Yf7GK232vKWITExnEI=";  # path is relative to the machine
      endpoints = [
        {
          # no match can be any
          ip = "192.168.1.2";
        }
      ];
    }
    {
      name = "peer2";
      subnets = {
        simple = {
          listenPort = 51820;
        };
      };
      publicKey = "ztdAXTspQEZUNpxUbUdAhhRWbiL3YYWKSK0ZGdcsMHE=";
      privateKey = "yG4mJiduoAvzhUJMslRbZwOp1gowSfC+wgY8B/Mul1M=";
      endpoints = [
        {
          # no match can be any
          ip = "192.168.1.3";
        }
      ];
    }
  ];
  connections = [
    {
      a = [{type= "subnet"; rule = "is"; value = "simple";}];
      b = [{type= "subnet"; rule = "is"; value = "simple";}];
    }
  ];
}