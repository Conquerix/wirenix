{
  version = "1";
  subnets = [
    { name = "subnet.one"; defaultPort = 51820; }
    { name = "subnet.two"; defaultPort = 51821; }
    { name = "subnet.three"; defaultPort = 51822; }
  ];
  peers = [
    {
      name = "peer.zero";
      endpoints = [
        {match = {group = "subnet two group";}; ip = "1.1.1.1"; port = 51820;}
        {match = {peer = "peer.one";}; ip = "2.2.2.2"; port = 51820;}
        {match = {}; ip = "3.3.3.3"; port = 51820;}
      ];
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
      endpoints = [
        {match = {group = "subnet two group";}; ip = "1.1.1.1"; port = 51820; persistentKeepalive = 15;}
        {match = {peer = "peer.one";}; ip = "2.2.2.2"; port = 51820;}
        {match = {}; ip = "3.3.3.3"; port = 51820;}
      ];
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
      endpoints = [
        {match = {group = "subnet two group";}; ip = "1.1.1.1"; port = 51820;}
        {match = {peer = "peer.one";}; ip = "2.2.2.2"; port = 51820;}
        {match = {}; ip = "3.3.3.3"; port = 51820;}
      ];
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
      endpoints = [
        {match = {group = "subnet two group";}; ip = "1.1.1.1"; port = 51820;}
        {match = {peer = "peer.one";}; ip = "2.2.2.2"; port = 51820;}
        {match = {}; ip = "3.3.3.3"; port = 51820;}
      ];
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
      endpoints = [
        {match = {group = "subnet two group";}; ip = "1.1.1.1"; port = 51820;}
        {match = {peer = "peer.one";}; ip = "2.2.2.2"; port = 51820;}
        {match = {}; ip = "3.3.3.3"; port = 51820;}
      ];
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