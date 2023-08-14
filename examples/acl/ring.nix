{
  version = "v1";
  subnets = [
    {
      name = "myRing";
      endpoints = [
        {
          # No match means match any
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
        myRing = {
          listenPort = 51820;
          # empty ipAddresses will auto generate an IPv6 address
        };
      };
      publicKey = "2CMNhw0CU2iFwKZvKT3dnqviBTKbJtuq5SNZvQpXCDY=";
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
        myRing = {
          listenPort = 51820;
        };
      };
      publicKey = "nU97PJin1r+g/jk4Jm9+xd0ibZKErESNeav4VjOQKlc=";
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
        myRing = {
          listenPort = 51820;
        };
      };
      endpoints = [
      {
        # no match can be any
        ip = "192.168.1.13";
      }
      ];
      publicKey = "FNdLup5glVp5dlynS4ker75i+fIIJPs4ri5vQ+9sGnE=";
      privateKeyFile = "/path/to/private/key";
    }
    {
      name = "peer4";
      subnets = {
        myRing = {
          listenPort = 51820;
        };
      };
      publicKey = "Xa+AhcRbAdOufv5mEwR8V5GDkJ+AiRMxTjtAwmWBCVI=";
      privateKeyFile = "/path/to/private/key";
      endpoints = [
        {
          # no match can be any
          ip = "192.168.1.14";
        }
      ];
    }
  ];
  connections = [
    {
      # Connections go both ways, no need to do a = peer2 and b = peer1
      a = [{type= "peer"; rule = "is"; value = "peer1";}];
      b = [{type= "peer"; rule = "is"; value = "peer2";}];
    }
    {
      # Connections go both ways, no need to do a = peer2 and b = peer1
      a = [{type= "peer"; rule = "is"; value = "peer2";}];
      b = [{type= "peer"; rule = "is"; value = "peer3";}];
    }
    {
      # Connections go both ways, no need to do a = peer2 and b = peer1
      a = [{type= "peer"; rule = "is"; value = "peer3";}];
      b = [{type= "peer"; rule = "is"; value = "peer4";}];
    }
    {
      # Connections go both ways, no need to do a = peer2 and b = peer1
      a = [{type= "peer"; rule = "is"; value = "peer4";}];
      b = [{type= "peer"; rule = "is"; value = "peer1";}];
    }
  ];
}