{
  version = "v1";
  subnets = [
    {
      name = "mesh";
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
        mesh = {
          listenPort = 51820;
          # empty ipAddresses will auto generate an IPv6 address
        };
      };
      publicKey = "kdyzqV8cBQtDYeW6R1vUug0Oe+KaytHHDS7JoCp/kTE=";
      privateKey = "MIELhEc0I7BseAanhk/+LlY/+Yf7GK232vKWITExnEI=";  # path is relative to the machine
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
        mesh = {
          listenPort = 51820;
        };
      };
      publicKey = "ztdAXTspQEZUNpxUbUdAhhRWbiL3YYWKSK0ZGdcsMHE=";
      privateKey = "yG4mJiduoAvzhUJMslRbZwOp1gowSfC+wgY8B/Mul1M=";
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
        mesh = {
          listenPort = 51820;
          # empty ipAddresses will auto generate an IPv6 address
        };
      };
      publicKey = "43tP6JgckdTFrnbYuy8a42jdNt3+wwVcb4+ae5U4ez4=";
      privateKey = "yPcTvQOK9eVXQjLNapOsv2iAkbOeSzCCxlrWPMe1o0g=";  # path is relative to the machine
      endpoints = [
        {
          # no match can be any
          ip = "node3";
        }
      ];
    }
    {
      name = "node4";
      subnets = {
        mesh = {
          listenPort = 51820;
        };
      };
      publicKey = "g6+Tq9aeVfm5CXPIwZDqoTxGmsQ/TlLtxcxVn2aSiVA=";
      privateKey = "CLREBQ+oGXsGxhlQc3ufSoBd7MNFoM6KmMnNyuQ9S0E=";
      endpoints = [
        {
          # no match can be any
          ip = "node4";
        }
      ];
    }
  ];
  connections = [
    {
      a = [{type= "subnet"; rule = "is"; value = "mesh";}];
      b = [{type= "subnet"; rule = "is"; value = "mesh";}];
    }
  ];
}