{
  version = "v1";
  subnets = [
    {
      name = "manual";
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
        manual = {
          ipAddresses = [
            "auto" # "auto" explicitly generates an ipv6 address, opposed to implicitly via not having an `ipAddresses` property
          ];
          listenPort = 51820;
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
        manual = {
          ipAddresses = [
            "auto"
          ];
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
  ];
  connections = [
    {
      a = [{type= "subnet"; rule = "is"; value = "manual";}];
      b = [{type= "subnet"; rule = "is"; value = "manual";}];
    }
  ];
}