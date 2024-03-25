{
  version = "v1";
  subnets = [
    {
      name = "ring";
      endpoints = [
        {}
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
        ring = {
          listenPort = 51820;
          # empty ipAddresses will auto generate an IPv6 address
        };
      };
      publicKey = "kdyzqV8cBQtDYeW6R1vUug0Oe+KaytHHDS7JoCp/kTE=";
      privateKeyFile = "/etc/wg-key1";
      endpoints = [
        {
          # no match can be any
          ip = "node1";
          port = 51820;
        }
      ];
    }
    {
      name = "peer2";
      subnets = {
        ring = {
          listenPort = 51820;
        };
      };
      publicKey = "ztdAXTspQEZUNpxUbUdAhhRWbiL3YYWKSK0ZGdcsMHE=";
      privateKeyFile = "/etc/wg-key2";
      endpoints = [
        {
          # no match can be any
          ip = "node2";
          port = 51820;
        }
      ];
    }
    {
      name = "peer3";
      subnets = {
        ring = {
          listenPort = 51821;
          # empty ipAddresses will auto generate an IPv6 address
        };
      };
      publicKey = "43tP6JgckdTFrnbYuy8a42jdNt3+wwVcb4+ae5U4ez4=";
      privateKeyFile = "/etc/wg-key3";
      endpoints = [
        {
          # no match can be any
          ip = "node1";
          port = 51821;
        }
      ];
    }
    {
      name = "peer4";
      subnets = {
        ring = {
          listenPort = 51821;
        };
      };
      publicKey = "g6+Tq9aeVfm5CXPIwZDqoTxGmsQ/TlLtxcxVn2aSiVA=";
      privateKeyFile = "/etc/wg-key4";      
      endpoints = [
        {
          # no match can be any
          ip = "node2";
          port = 51821;
        }
      ];
    }
  ];
  connections = [
    {
      a = [{type= "peer"; rule = "is"; value = "peer1";}];
      b = [{type= "peer"; rule = "is"; value = "peer2";}];
      subnets = [ "ring" ];
    }
    {
      a = [{type= "peer"; rule = "is"; value = "peer2";}];
      b = [{type= "peer"; rule = "is"; value = "peer3";}];
      subnets = [ "ring" ];
    }
    {
      a = [{type= "peer"; rule = "is"; value = "peer3";}];
      b = [{type= "peer"; rule = "is"; value = "peer4";}];
      subnets = [ "ring" ];
    }
    {
      a = [{type= "peer"; rule = "is"; value = "peer4";}];
      b = [{type= "peer"; rule = "is"; value = "peer1";}];
      subnets = [ "ring" ];
    }
  ];
}