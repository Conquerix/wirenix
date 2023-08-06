{
  subnets = [
    { name = "subnet.one"; }
    { name = "subnet.two"; }
    { name = "subnet.three"; }
  ];
  peers = [
    {
      name = "peer.zero";
      subnets = [
        
      ];
      groups = [

      ];
      connections = [
        { group = "everyoneConnectsToMe"; }
      ];
      privateKeyFile = "/not/yet";
      publicKey = "testData";
      presharedKeyFile = "testData2";
    }
    {
      name = "peer.one";
      subnets = [
        "subnet.one"
      ];
      groups = [

      ];
      connections = [
        { group = "everyoneConnectsToMe"; }
        { group = "subnet one group"; }
      ];
      privateKeyFile = "/not/yet";
      publicKey = "testData";
      presharedKeyFile = "testData2";
    }
    {
      name = "peer.two";
      subnets = [
        "subnet.one"
        "subnet.two"
      ];
      groups = [
        "everyoneConnectsToMe"
        "subnet two group"
      ];
      connections = [
        { group = "everyoneConnectsToMe"; }
        { group = "subnet two group"; }
      ];
      privateKeyFile = "/not/yet";
      publicKey = "testData";
      presharedKeyFile = "testData2";
    }
    {
      name = "peer.three";
      subnets = [
        "subnet.one"
        "subnet.two"
        "subnet.three"
      ];
      groups = [
        "everyoneConnectsToMe"
        "subnet two group"
      ];
      connections = [
        { group = "everyoneConnectsToMe"; }
        { group = "subnet two group"; }
      ];
      privateKeyFile = "/not/yet";
      publicKey = "testData";
      presharedKeyFile = "testData2";
    }
    {
      name = "peer.four";
      subnets = [
        "subnet.three"
        "subnet.one"
      ];
      groups = [
        
      ];
      connections = [
        { group = "everyoneConnectsToMe"; }
        { peer = "peer.one"; }
      ];
      privateKeyFile = "/not/yet";
      publicKey = "testData";
      presharedKeyFile = "testData2";
    }
  ];
}