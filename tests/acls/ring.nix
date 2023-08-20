{
  version = "v1";
  subnets = [
    {
      name = "ring";
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
        ring = {
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
        ring = {
          listenPort = 51820;
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
        ring = {
          listenPort = 51820;
          # empty ipAddresses will auto generate an IPv6 address
        };
      };
      publicKey = "43tP6JgckdTFrnbYuy8a42jdNt3+wwVcb4+ae5U4ez4=";
      privateKeyFile = "/etc/wg-key";
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
        ring = {
          listenPort = 51820;
        };
      };
      publicKey = "g6+Tq9aeVfm5CXPIwZDqoTxGmsQ/TlLtxcxVn2aSiVA=";
      privateKeyFile = "/etc/wg-key";      
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
      a = [{type= "peer"; rule = "is"; value = "node1";}];
      b = [{type= "peer"; rule = "is"; value = "node2";}];
    }
    {
      a = [{type= "peer"; rule = "is"; value = "node2";}];
      b = [{type= "peer"; rule = "is"; value = "node3";}];
    }
    {
      a = [{type= "peer"; rule = "is"; value = "node3";}];
      b = [{type= "peer"; rule = "is"; value = "node4";}];
    }
    {
      a = [{type= "peer"; rule = "is"; value = "node4";}];
      b = [{type= "peer"; rule = "is"; value = "node1";}];
    }
  ];
}