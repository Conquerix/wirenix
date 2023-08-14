WireNix is a Nix Flake designed to make creation of Wireguard mesh networks
easier. The simplist and most likely layout is a full mesh network, but Wirenix
can also support arbitrary graph topologies.  
# Reading the README
Due to Nix's dynamic typing, I have opted to define configurations in
psuedo-typescript to make options more legible. I have chosen typescript
because it looks somewhat like JSON and is easy to understand. Examples will
still be given in Nix EL.  

You can start by reading the "ACL Configuration" section, then reading
"Quick Start" section for how to configure your machines. Other sections
exist to provide helpful context and advanced usage, but should not be
necessary for a working setup.  

Wirenix assumes a flakes setup, that's what I use. Maybe it works without
flakes, maybe not. I'm not familiar enough with the non-flakes landscape
to provide support. I am open to making simple changes to make using this
project work without flakes if anyone has suggestions or wants to submit
a patch.  

# ACL Configuration
The ACL is a nix attrset designed to be represented in JSON for easy importing
and potential use outside of the nix ecosystem. The vast majority of all your
wirenix configuration will end up in here, with a few exceptions noted later.  

## top level acl:
```typescript
type ACL = {
  version?: str;
  subnets: subnet[];
  groups: group[];
  peers: peer[];
  connections: connection[];
  extraArgs?: attrset; // goes to intermediate config
};
```

`Version` is used to check to find the right parser and is required. Using an
older. At the moment there is only "v1" builtin.  

`extraArgs` is explained later, and can be ignored unless you are trying to
make your own integrations.  

## subnet:
```typescript
type subnet = {
  name: str;
  endpoints?: endpoint[];
  presharedKeyFile?: str;
  extraArgs?: attrset; // goes to intermediate config subnet
};
```

## Group:
```typescript
type group = {
  name: str;
  endpoints?: endpoint[];
  extraArgs?: attrset; // goes to intermediate config group
};
```

## Peer:
```typescript
type peer = {
  name: str;
  subnets: [subnetName: str]: {
    listenPort: int;
    ipAddresses?: str[];
    extraArgs?: attrset; // goes to intermediate config subnetConnection
  };
  publicKey: str;
  privateKeyFile: str; 
  groups?: str[];
  endpoints?: endpoint[];
  extraArgs?: attrset; // goes to intermediate config peer
};
```

"`[subnetName: str]: {...}`" means "`subnets`" is an attrset with
string typed keys, and values that follow the typing of the nested object
"`...`".  

## Connection:
```typescript
type connection = {
  a: filter;
  b: filter;
  subnets: str[];
  extraArgs?: attrset; // merged into intermediate config peerConnection
};
```

Connections connect all peers matching filter `a` to all peers matching
filter `b`, and all peers matching filter `b` to all peers matching filter `a`
subnets filters the connection to only be made over the subnets listed. It is
recomended to use the subnets property iff the `subnet` filter is also used
(the `subnet` filter on its own will connect all shared subnets of machines in
`a` and `b`, even subnets not mentioned in the filters if they are shared).  

## Endpoint:
```typescript
type endpoint = {
  match?: filter;
  ip?: str;
  port?: int;
  persistentKeepalive?: int;
  dynamicEndpointRefreshSeconds?: int;
  dynamicEndpointRefreshRestartSeconds?: int;
  extraArgs?: attrset; // merged to intermediate config peerConnection.endpoin
};
```

Endpoints are merged in this order: First lists of endpoints are merged top to
bottom, with the bottom endpoints overriding the top ones. Then, lists are
merged in this order: subnet -> group -> peer; with peer being the highest
priority, overriding others. A good layout is to set ports in subnet, ip in
peer, and leave group empty. group endpoints can be useful for specifying
connection details across port forwarded NATs, however.  
Note that `dynamicEndpointRefreshSeconds` and 
`dynamicEndpointRefreshRestartSeconds` are ignored for connecting networkd
peers.  

## Filter:
```typescript
type filter = {
  type: ["peer" | "group" | "subnet"];
  rule: [ "is" | "not" ];
  value: str;
}[]; // <==== Important! It's a list
```

A filter is a list of filter rules. Each filter rule has the attributes
`type`, `rule` and `value`. `type` selects what to match with, `rule`
selects whether to invert the match (`"not"`) or not (`"is"`). `Value` is
the value to search for. Multiple filter rules in the filter list combine
as the intersection. For example:
```nix
[
  {type="group"; rule="is"; value="desktops"}
  {type="peer"; rule="not"; value="joesdesktop"}
]
```
This will select all peers in the `desktop` group, except the peer named
`joesdesktop`.  

## extraArgs
`extraArgs` is intentionally left alone. I promise I won't ever set
`extraArgs`, but any value in it will be forwarded on to the corresponding
section in the intermediate configuration. Because of this, it can be used to
pass data into user defined Configuration Modules. Most users can ignore
`extraArgs`.  

# Quick Start  
1. Make your ACL according to the [ACL Configuration]](ACL Configuration) section.
You can look in the `examples/acl` folder for examples.  
2. Include the module in your flake config:
    ```nix
    ...
    inputs.wirenix.url = "sourcehut:~msalerno/wirenix";
    outputs = { self, nixpkgs, wirenix }: {
    nixosConfigurations = {
        example = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
            ./machines/example.nix
            wirenix.nixosModules.default
        ] 
        };
    };
    ```

3. Configure wirenix in your nixosConfiguration (`./machines/example.nix` in this
case):
    ```nix 
    wirenix = {
        enable = true;
        peerName = "example" # defaults to hostname otherwise
        configurer = "static" # defaults to "static", could also be "networkd"
        keyProviders = ["acl"]; # could also be ["agenix-rekey"] or ["acl" "agenix-rekey"]
        # secretsDir = ../../secrets; # only if you're using agenix-rekey
        aclConfig = import ../../acl.nix;
    };
    ```

4. Profit  

# Architecture
WireNix consists of 5 main components:  
1. The shared ACL Configuration  
2. Parser Modules  
3. The intermediate Configuration  
4. Configuration Modules
5. The Key Providers  
  

The goal of splitting WireNix into modules is both for my own sanity when
developing, and to make it hackable without requiring users to make their own
fork. Users are able to specify their own Parser Modules, enabling them to use
their own preferred ACL syntax if they desire. Users can also specify their own
configuration modules, allowing them to add compatibility to for other network
stacks or to enable their own modules. It is also possible to add new key
providers. Using both custom Parser and Configuration modules enables
essentially rewriting this flake however you see fit, all without making a fork
(although at that point I may question why you don't write your own module from
scratch).  

## ACL
The shared ACL configuration describes the full network topology. It does not
need to consist only of NixOS peers The details of this file are documented in
the  "Top Level ACL" section. You can make your own ACL configuration format so
long as you keep the "`version`" field and set it to some unique name.

## Parser Modules
Parser Modules are responsible for taking an ACL and converting it to the
intermediate configuration format. Parser modules are selected by matching the
ACL version field. A parser module must take an ACL and return the
corresponding Intermediate Configuration. A parser has the following
interface:  

```typescript
type parser = (inputs: attrset, aclConfig: ACL) => intermediateConfiguration;
```

You can register your own parser
module like so:  

```nix
wirenix.additionalParsers = {
    myParser = import ./my-parser.nix;
}
```

And then, in your ACL, set the version:  
  
```nix
...
version = "myParser";
...
```

## Intermediate Configuration
The Intermediate Configuration is a recursive attrset that is more suited for
being used in a NixOS configuration than the ACL Configuration. Unlike the ACL,
the intermediate configuration is more verbose, easier to traverse, contains
duplicate information, and is recursive. This allows cross version
compatibility so long as the intermediate configuration doesn't change. Any
changes will likely only be the addition of optional features that do not
interfere with existing intermediate configuration use, though at this stage
there are no guarentees.   
Take note while reading that certain structures may be similar to the ACL,
but they are not necessarily the same as their ACL counterparts.  

### Root Structure
```typescript
type intermediateConfiguration = {
    peers: {[peerName: str]: peer};
    subnets: {[subnetName: str]: subnet};
    groups: {[groupName: str]: group};
    extraArgs?: attrset;
}
```

### Peer

```typescript
type peer = {
    subnetConnections: {[subnetName: str]: subnetConnection};
    publicKey: str;
    privateKeyFile: str; 
    groups?: {[groupName: str]: group}    
    extraArgs?: attrset;
};
```


### Subnet

```typescript
type subnet = {
    peers: {[peerName: str]: peer};
    presharedKeyFile?: str;
    extraArgs?: attrset;
};
```

### Group

```typescript
type group = {
    peers: {[peerName: str]: peer};
    extraArgs?: attrset;
};
```

### Subnet Connection

```typescript
type subnetConnection = {
    subnet: subnet;
    ipAddresses: str[];
    listenPort: int;
    peerConnections: {[peerName: str]: peerConnection};
    extraArgs?: attrset;
};
```

### Peer Connection

```typescript
type peerConnection = {
    peer: peer;
    ipAddresses: str[];
    endpoint: endpoint;
    extraArgs?: attrset;
};
```

### Endpoint

```typescript
type endpoint = {
   ip: str;
   port: int;
   persistentKeepalive?: int;
   dynamicEndpointRefreshSeconds?: int;
   dynamicEndpointRefreshRestartSeconds?: int;
   extraArgs?: attrset;
};
```

## Configuration Modules
Configuration Modules take the Key provider list and Intermediate Configuration
to produce NixOS configurations. By default, there exist configuration modules
for setting up wireguard with the static network configuration (default) or
networkd configuration. A configurer has the following interface:  

```typescript
type configurer = (inputs: attrset, keyProviders: keyProvider[], intermediateConfig: intermediateConfiguration) => nixosConfiguration;
```

You can set which module is used (or use your 
own module) in your flake.nix file:  

```nix
wirenix.configurer = "networkd"; 
```

or for your own module:  

```nix
wirenix.additionalConfigurers.myConfigurer = import ./my-configurer.nix;
wirenix.configurer = "myConfigurer";
```

## Key Providers
Configurers require a list of key providers to query for information about
wireguard key pairs. The providers in the list are queried in order, moving on
to the next provider if `null` is returned. This allows keeping key pairs
in multiple places, but most likely the key provider list will be a singleton.
Key Providers have the following stracture:  

```typescript
type keyProvider = {
    config: nixosConfig;
    getPeerPubKey: (otherPeerName: str) => str;
    getPrivKeyFile: str;
    getSubnetPSKFile: (subnetName: str) => str;
};
```

You can add your own key providers like so:  
```nix
wirenix.additionalKeyProviders.myKeyProvider = import ./my-key-provider.nix;
wirenix.keyProviders = ["myKeyProvider"];
```

# Integrations:
By default, WireNix supports setting wireguard keypairs with
[agenix-rekey](https://github.com/oddlama/agenix-rekey).
WireNix also supports using either networkd or the nixos static network
configuration (default).  

Using networkd:  
```nix
systemd.network.enable = true;
wirenix = {
  enable = true;
  configurer = "networkd"
  aclConfig = import ./my-acl.nix;
};
```

Using static configuration:  
```nix
wirenix = {
  enable = true;
  configurer = "static"
  aclConfig = import ./my-acl.nix;
};
```

Using agenix-rekey (assuming it's already set up properly)  
```nix
wirenix = {
  enable = true;
  keyProviders = ["agenix-rekey"];
  secretsDir = ../../secrets;
  aclConfig = import ./my-acl.nix;
};
```

Using the ACL's keypairs if specified, otherwise using agenix-rekey
(reverse order not possible)  
```nix
wirenix = {
  enable = true;
  keyProviders = ["acl" "agenix-rekey"];
  secretsDir = ../../secrets;
  aclConfig = import ./my-acl.nix;
};
```

# Troubleshooting
Wirenix tries to stay seperated from the inner working of your config for as
long as possible. As a result, you can do most of your troubleshooting in the
nix repl:  

```sh
$ nix repl
$ nix-repl> :l <nixpkgs>
> Added 17766 variables.

$ nix-repl> :lf "sourcehut:~msalerno/wirenix"
> Added 11 variables.
# named the wirenix lib 'wnlib' to prevent issues with nixpkgs.lib in the repl
$ nix-repl> parse = wnlib.defaultParsers.v1 {inherit lib;}

$ nix-repl> keyProviders = [wnlib.defaultKeyProviders.acl]

$ nix-repl> configure = wnlib.defaultConfigurers.static {inherit lib;} keyProviders

$ nix-repl> acl = import ./examples/fullMesh/acl.nix # replace with your acl

# get intermediate config
$ nix-repl> intConfig = parse acl
# you can explore the structure
$ nix-repl> intConfig
> { groups = { ... }; peers = { ... }; subnets = { ... }; }
# we can also see what the generated network config would be
$ nix-repl> genPeerConfig = configure intConfig
# `configure` is only partially applied, and genPeerConfig still needs a peer name
$ nix-repl> genPeerConfig
> «lambda @ /nix/store/h8gyjv62yddarvr533vi8f2rh5w0wh1p-source/configurers/static.nix:1:33»

# we can then inspect the result
$ nix-repl> :p genPeerConfig "peer1"
> { networking = { wireguard = { interfaces = { ... }; }; }

# printing the intermediate config with :p will cause a stack overflow
# but we have a helper function for this
$ nix-repl> :p wnlib.breakIntermediateRecursion intConfig
> { a bunch of hard to read data }
# you can get a string and paste it into echo -e for pretty printing
$ nix-repl> lib.generators.toPretty {} (wnlib.breakIntermediateRecursion intConfig)
> "even uglier result but it copy pastes well"
```

In your terminal:  

```sh
$ echo -e "paste the big text result from nix repl in here"
> a nice result
```

# Current Issues / Drawbacks
- WireNix does not do NAT traversal, it's up to you to forward the correct
ports on your NAT device(s) and apply the correct firewall rules on your
router(s).  
- WireNix does not allow for dynamic addition of peers. If you need something
more dynamic, look into Tailscale/Headscale.  
- Peers cannot have multiple keys. If this is a desirable feature I may think
of adding it, but I cannot think of a good reason for it.  
- There's no testing infrastructure in place right now, and plenty of untested
scenarios.
- Currently this will create empty `sops` and `age` top level attributes in your
config if you don't already have them. It has to do with some terrible hackery
I did in `wire.nix` to prevent infinite recursion. If any wizards out there
want to send in a patch it would be mutch appreciated!  

# License  
This project is licensed under the MPL 2.0  

# Glosary
## ACL
Access Control List: 
This is your shared configuration for the network.  

## Subnet
In Wirenix, the word subnet represents any network of connected peers.
In the implementation, subnets are keyed by their `name` property. Subnet names
define the initial 32 bits after `fd` in of an the IPv6 addresses peers
connecting to the subnet will use. Generally speaking, one subnet = one
wireguard interface for each client on the subnet.  

## Peer
 In Wirenix, peer is any machine with a unique public key In the
 implementation, peer names define last 80 bits of their IPv6 address.  

## Group
In Wirenix, a group is just a tag that peers can have. These are used for
matching peers and can contain arbitrary names.  

## Endpoint
In wirenix, an endpoint specifies external IP of a peer that other peers should
connect to.  
In the ACL configuration, endpoints can exist on subnets, groups, and peers,
but these are just for convenience. Think of adding an endpoint to a subnet or
group as being the same as adding the endpoint to all peers in the subnet or
group.  
Endpoints have filters, which can specify for which connecting clients the
endpoint will apply to.  

## Filter 
In Wirenix, a filter is used to select peers by their subnets, groups, and
names. A filter is made up of filter rules, specifying multiple rules will
yield the intersection of those rules.  
Note that selecting by peer name will always return a list of 1 or 0 entries,
on account of names needing to be unique.  