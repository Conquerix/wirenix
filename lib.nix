with builtins;
/** 
ACL independent functions that can be used in parsers.
*/
rec {
  /** Builtin Parsers */
  defaultParsers = {
    v1 = import ./parsers/v1.nix;
  };
  /** Builtin configurers */
  defaultConfigurers = rec {
    auto = static; # TODO: make smart
    static = import ./configurers/static.nix;
    networkd = import ./configurers/networkd.nix;
    networkmanager = import ./configurers/networkmanager.nix;
  };
  /** listOfSetsToSetByKey :: string -> list -> attrSet
  * Example: 
  * listOfSetsToSetByKey "primary" [ {primary = "foo"; secondary = 1; tertiary = "one"} {primary = "bar"; secondary = 2; tertiary = "two"} ]
  * {foo = {secondary = 1; tertiary = "one"}; bar = {secondary = 2; tertiary = "two"};}
  */
  listOfSetsToSetByKey = key: list: 
    listToAttrs (
      map (item: {
        name = item."${key}";
        value = removeAttrs item [ key ];
      }) list
    );
  /** Like listOfSetsToSetByKey, but also performs a map before dropping the key */
  mapListOfSetsToSetByKey = key: function: list: 
    mapAttrs (name: value: removeAttrs (function value) [key]) (
      listToAttrs (
        map (item: {
          name = item."${key}";
          value = item;
        }) list
      )
    );
  /** adds colons to a string every 4 characters for IPv6 shenanigans */
  addColonsToIPv6 = string: 
    if ((stringLength string) > 4) 
    then 
      ((substring 0 4 string) + ":" + (addColonsToIPv6 (substring 4 32 string)))
    else string;
    
  /** pipeMap :: [(a_(n) -> a_(n+1)] -> [a_0] -> [a_end] 
   * equivelent to `builtins.map (lib.trivial.flip lib.trivial.pipe funcList) elems`
   */
  pipeMap =
  let
    pipe = item: funcs:
      if ((length funcs) == 0)
      then item
      else pipe ((head funcs) item) (tail funcs);
    pipe' = funcs: item: pipe item funcs;
  in
    funcs: list: map (pipe' funcs) list;
  
  /** generate last 20 characters (80 bits) of the peer's IPv6 address */
  generateIPv6Suffix =  peerName: substring 0 20 (hashString "sha256" peerName);
  
  /** generate the first 10 characters of the IPV6 address for the subnet name */
  generateIPv6Prefix = subnetName: "fd" + (substring 0 10 (hashString "sha256" subnetName));
  
  /** generates a full IPv6 subnet */
  generateIPv6Subnet = subnetName: (addColonsToIPv6 (generateIPv6Prefix subnetName)) + "::/80";
  
  /** generates a full IPv6 address */
  generateIPv6Address = subnetName: peerName: (addColonsToIPv6 ((generateIPv6Prefix subnetName) + (generateIPv6Suffix peerName))) + "/80";
  
  /** 
   * makes the intermediate config non-recursive, so it can be pretty printed and
   * inspected in the repl. Also helps with testing as it forces evaluation of the config.
   */
  breakIntermediateRecursion = intermediateConfig:
    let recurse = parentName:
    mapAttrs (name: value:
      if typeOf value == "set" then 
        if elem name [ "peer" "subnet" "group" "groups" ] then
          "${name}s.${parentName}"
        else if elem parentName ["peers"] then
          "${parentName}.${name}"
        else
          recurse name value
      else
      value
    );
    in
    mapAttrs (name: value: recurse "" value) intermediateConfig;
}