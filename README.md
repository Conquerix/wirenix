WireNix is a Nix Flake designed to make creation of Wireguard mesh networks
easier. The simplist and most likely layout is a full mesh network, but Wirenix
is able to support arbitrary graph topologies.  
# Reading the README
Due to Nix's typeless nature, I have opted to define all my configurations in
psuedo-typescript to make options more legible. I have chosen typescript
because it looks somewhat like JSON and is easy to understand. Examples will
still be given in Nix EL.  

You can start by reading the `ACL Configuration` section, then reading
`Quick Start` section for how to use configure your machines. Other sections
exist to provide helpful context and advanced usage, but should not be
necessary for a working setup.  

# ACL Configuration
The ACL is a nix attrset designed to be represented in JSON for easy importing
and potential use outside of the nix ecosystem.  

## top level acl:
```typescript
type ACL = {
  version?: str;
  subnets: subnet[];
  groups: group[];
  peers: peer[];
  connections: connection[];
  extraArgs?: any; // goes to intermediate config
};
```

Version is used to check for config compatibility and is recommended. Not
specifying version will parse the configuration with the most recent parser
available and generate a warning. Using an older configuration version than
available will use the parser for that version and generate a warning. Using
a version newer than any parsers available will throw an error.  

## subnet:
```typescript
type subnet = {
  name: str;
  endpoints?: endpoint[];
  extraArgs?: any; // goes to intermediate config subnet
};
```

## Group:
```typescript
type group = {
  name: str;
  endpoints?: endpoint[];
  extraArgs?: any; // goes to intermediate config group
};
```

## Peer:
```typescript
type peer = {
  name: str;
  subnets: [subnetName: str]: {
    listenPort: int;
    ipAddresses?: str[];
    extraArgs?: any; // goes to intermediate config subnetConnection
  };
  publicKey: string;
  privateKeyFile: string; 
  groups?: str[];
  endpoints?: endpoint[];
  extraArgs?: any; // goes to intermediate config peer
};
```

## Connection:
```typescript
type connection = {
  a: filter;
  b: filter;
  subnets: str[];
  extraArgs?: any; // merged into intermediate config peerConnection
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
  extraArgs?: any; // merged to intermediate config peerConnection.endpoin
};
```

Endpoints are merged in this order: First lists of endpoints are merged top to
bottom, with the bottom endpoints overriding the top ones. Then, lists are
merged in this order: subnet -> group -> peer; with peer being the highest
priority, overriding others. A good layout is to set ports in subnet, ip in
peer, and leave group empty. group endpoints can be useful for specifying
connection details across port forwarded NATs, however.  

## Filter:
```typescript
type filter = {
  type: ["peer" | "group" | "subnet"];
  rule: [ "is" | "not" ];
  value: str;
}[]; // <==== Important! It's a list
```

## extraArgs
`extraArgs` is intentionally left alone. I promise I won't ever set
`extraArgs`, but any value in it will be forwarded on to the corresponding
section in the intermediate configuration. Because of this, it can be used to
pass data into user defined Configuration Modules. Most users can ignore
`extraArgs`.  

# Architecture
WireNix consists of 4 main components:  
1. The shared ACL Configuration  
2. Parser Modules  
3. The intermediate Configuration  
4. Configuration Modules  

The goal of splitting WireNix into modules is both for my own sanity when
developing, and to make it hackable without requiring users to make their own
fork. Users are able to specify their own Parser Modules, enabling them to use
their own preferred ACL syntax if they desire. Users can also specify their own
configuration modules, allowing them to add compatibility to for other network
stacks or to enable their own modules. Using both custom Parser and
Configuration modules enables essentially rewriting this flake however you see
fit, all without making a fork (although at that point I may question why you
don't write your own module from scratch).  

## ACL
The shared ACL configuration should describe the full network topology. It does
not need to consist only of NixOS peers (although at the moment, other peers
will have to be configured manually to conform to the expected settings). The
details of this file are documented in the  `Top Level ACL` section.
You can make your own ACL configuration format so long as you keep the
`version` field and set it to some unique name.

## Parser Modules
Parser Modules are responsible for taking an ACL and converting it to the
intermediate configuration format. Parser modules are selected by matching the
ACL version field. A parser module must take an ACL and return the
corresponding Intermediate Configuration You can register your own parser
module like so:  

```nix
modules.wirenix.additionalParsers = {
    myParser = import ./my-parser.nix;
}
```

and then in your acl, set the version:  
  
```nix
...
version = "myConfigurer";
...
```

## Intermediate Configuration
The Intermediate Configuration is a recursive attrset that is more suited for
being used in a NixOS configuration than the ACL Configuration.  
Unlike the ACL, the intermediate configuration is more verbose, easier to
traverse, repeats itself often, and is recursive. This allows cross version
compatibility so long as the intermediate configuration doesn't change. Any
changes will likely only be the addition of optional features that do not
interfere with existing intermediate configuration use, though at this stage
there are no guarentees.  
It can be assumed that all types mentioned are types for the intermediate
connection and NOT the related to types in the ACL. The intermediate
configuration has the following structure:  

### Root Structure
```typescript
type intermediateConfiguration = {
    peers: {[peerName: string]: peer};
    subnets: {[subnetName: string]: subnet};
    groups: {[groupName: string]: group};
}
```

### Peer

```typescript
type peer = {
    subnetConnections: {[subnetName: string]: subnetConnection};
    groups: {[groupName: string]: group}
    publicKey: string;
    privateKeyFile: string; 
    extraArgs?: any;
};
```


### Subnet

```typescript
type subnet = {
    peers: {[peerName: string]: peer};
    extraArgs?: any;
};
```

### Group

```typescript
type group = {
    peers: {[peerName: string]: peer};
    extraArgs?: any;
};
```

### Peer Connection

```typescript
type peerConnection = {
    peer: peer;
    ipAddresses: string[];
    endpoint: endpoint;
    extraArgs?: any;
};
```

### Subnet Connection

```typescript
type subnetConnection = {
    subnet: subnet;
    ipAddresses: string[];
    listenPort: int;
    peerConnections: {[peerName: string]: peerConnection};
    extraArgs?: any;
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
   extraArgs?: any;
};
```

Unlike the ACL, this structure is recursive, resembling an arbitrary graph.
This graph can be traversed back and forth in circles until you run out of
stack space.  

## Configuration Modules
Configuration Modules take the Intermediate Configuration and produce NixOS
configurations from them. By default, there exist configuration modules for
setting up wireguard with the static network configuration, networkd, and
Network Manager. There is a fourth, "default" configuration module that
intelligently selects which module to use (with priority being networkd >
network manager > static configuration). However, you can manually override
which module is used (or use your own module) in your flake.nix file:  

```nix
modules.wirenix.configurer = "v0"; # there is no v0, this is just an example
```

or for your own module:  

```nix
modules.wirenix.additionalConfigurers.myConfigurer = import ./my-parser.nix;
modules.wirenix.configurer = "myConfigurer";
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

$ nix-repl> parse = wirenix.lib.defaultParsers.v1 {inherit lib;}

$ nix-repl> configure = wirenix.lib.defaultConfigurers.static {inherit lib;}

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
$ nix-repl> :p wirenix.lib.breakIntermediateRecursion intConfig
> { a bunch of hard to read data }
# you can get a string and paste it into echo -e for pretty printing
$ nix-repl> lib.generators.toPretty {} (wirenix.lib.breakIntermediateRecursion intConfig)
> "even uglier result but it copy pastes well"
```

In your terminal:  

```sh
$ echo -e "paste the big text result from nix repl in here"
> a nice result
```

# Integrations:
By default, WireNix supports setting wireguard keypairs with agenix-rekey.
WireNix also supports networkd, network manager, and the nixos static network
configuration (default).  

Using networkd:  

```nix
TODO
```

Using network manager:  

```nix
TODO
```

Using static configuration:  

```nix
TODO
```

Using agenix-rekey (assuming it's already set up properly)  

```nix
TODO
```

# Current Issues / Drawbacks
- WireNix does not do NAT traversal, it's up to you to forward the correct
ports on your NAT device(s) and apply the correct firewall rules on your
router(s).  
- WireNix does not allow for dynamic addition of peers. If you need something
more dynamic, look into Tailscale/Headscale.  
- Peers cannot have multiple keys. If this is a desirable feature I may think
of adding it, but I cannot think of a good reason for it.  

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