{
  version = "v1";
  subnets = [
    {
      name = "mySpoke";
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
      name = "central";
      subnets = {
        mySpoke = {
          listenPort = 51820;
          # empty ipAddresses will auto generate an IPv6 address
        };
      };
      publicKey = "whST3RRJziiQTIizeQW6z8fCtoiBfHK559WCY2RS4GQ=";
      privateKeyFile = "/path/to/private/key";  # path is relative to the machine
      endpoints = [
        {
          # no match can be any
          ip = "192.168.1.11";
        }
      ];
    }
    {
      name = "leaf1";
      subnets = {
        mySpoke = {
          listenPort = 51820;
        };
      };
      publicKey = "AgsXp89XUz545KRZiNzCYw1Jr6WC5zIfKZnq5M+UUkM=";
      privateKeyFile = "/path/to/private/key";
      endpoints = [
        {
          # no match can be any
          ip = "192.168.1.12";
        }
      ];
    }
    {
      name = "leaf2";
      subnets = {
        mySpoke = {
          listenPort = 51820;
        };
      };
      endpoints = [
      {
        # no match can be any
        ip = "192.168.1.13";
      }
      ];
      publicKey = "1fn/kD11tWPc5VFAZn30PDM4nPoZoGPBEoVFnQdx62o=";
      privateKeyFile = "/path/to/private/key";
    }
    {
      name = "leaf3";
      subnets = {
        mySpoke = {
          listenPort = 51820;
        };
      };
      publicKey = "z5IfD9joAexurf2TyoKd49LrRFRN4JyCCPBAOJXqlGc=";
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
      a = [{type= "subnet"; rule = "is"; value = "mySpoke";}];
      b = [{type= "peer"; rule = "is"; value = "central";}];
    }
  ];
}