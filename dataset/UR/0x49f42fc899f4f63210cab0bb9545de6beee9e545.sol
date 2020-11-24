 

pragma solidity 0.5.8;

interface ENS {

     
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

     
    event Transfer(bytes32 indexed node, address owner);

     
    event NewResolver(bytes32 indexed node, address resolver);

     
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);

}

 
interface Resolver{
    event AddrChanged(bytes32 indexed node, address a);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexedKey, string key);
    event ContenthashChanged(bytes32 indexed node, bytes hash);
     
    event ContentChanged(bytes32 indexed node, bytes32 hash);

    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
    function addr(bytes32 node) external view returns (address);
    function contenthash(bytes32 node) external view returns (bytes memory);
    function dnsrr(bytes32 node) external view returns (bytes memory);
    function name(bytes32 node) external view returns (string memory);
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
    function text(bytes32 node, string calldata key) external view returns (string memory);
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);

    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external;
    function setAddr(bytes32 node, address addr) external;
    function setContenthash(bytes32 node, bytes calldata hash) external;
    function setDnsrr(bytes32 node, bytes calldata data) external;
    function setName(bytes32 node, string calldata _name) external;
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;
    function setText(bytes32 node, string calldata key, string calldata value) external;
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external;

    function supportsInterface(bytes4 interfaceID) external pure returns (bool);

     
    function content(bytes32 node) external view returns (bytes32);
    function multihash(bytes32 node) external view returns (bytes memory);
    function setContent(bytes32 node, bytes32 hash) external;
    function setMultihash(bytes32 node, bytes calldata hash) external;
}

interface IClock {
  function getTime() view external returns (uint256);
}

contract Clock is IClock {
  function getTime() view public returns (uint256) {
    return block.timestamp;
  }
}

 
contract EthvaultENSRegistrar is Clock {
   
  bytes32 public constant RESOLVER_NODE = keccak256(abi.encodePacked(bytes32(0), keccak256("resolver")));

   
  event Registration(address claimant, bytes32 label, address owner, uint256 value);

  ENS public ens;

   
  bytes32 public rootNode;

   
  mapping(address => bool) public isClaimant;

  constructor(ENS _ens, bytes32 _rootNode) public {
    ens = _ens;
    rootNode = _rootNode;

    isClaimant[msg.sender] = true;
  }

   
  modifier claimantOnly() {
    if (!isClaimant[msg.sender]) {
      revert("unauthorized - must be from claimant");
    }

    _;
  }

   
  function addClaimants(address[] calldata claimants) external claimantOnly {
    for (uint i = 0; i < claimants.length; i++) {
      isClaimant[claimants[i]] = true;
    }
  }

   
  function removeClaimants(address[] calldata claimants) external claimantOnly {
    for (uint i = 0; i < claimants.length; i++) {
      isClaimant[claimants[i]] = false;
    }
  }

   
  function namehash(bytes32 label) view public returns (bytes32) {
    return keccak256(abi.encodePacked(rootNode, label));
  }

   
  function getReleaseSignData(bytes32 label, uint256 expirationTimestamp) pure public returns (bytes32) {
    return keccak256(abi.encodePacked(label, expirationTimestamp));
  }

   
  function recover(bytes32 _hash, bytes memory _sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (_sig.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(_hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 _hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
    );
  }

   
   
  function release(bytes32 label, uint256 expirationTimestamp, bytes calldata signature) external {
    bytes32 subnode = namehash(label);

    address currentOwner = ens.owner(subnode);

    if (currentOwner == address(0)) {
       
      return;
    }

    address signer = recover(
      toEthSignedMessageHash(getReleaseSignData(label, expirationTimestamp)),
      signature
    );

    if (signer == address(0)) {
      revert("invalid signature");
    }

    if (signer != currentOwner) {
      revert("signature is not from current owner");
    }

    if (expirationTimestamp < getTime()) {
      revert("the signature has expired");
    }

    ens.setSubnodeOwner(rootNode, label, address(0));
  }

   
  function getPublicResolver() view public returns (Resolver) {
    address resolverAddr = ens.resolver(RESOLVER_NODE);
    
    if (resolverAddr == address(0)) {
      revert("failed to get resolver address");
    }

    Resolver resolver = Resolver(resolverAddr);

    address publicResolver = resolver.addr(RESOLVER_NODE);
    if (publicResolver == address(0)) {
      revert("resolver had address zero for node");
    }

    return Resolver(publicResolver);
  }

   
  function register(bytes32[] calldata labels, address payable[] calldata owners, uint256[] calldata values) external payable claimantOnly {
    if (labels.length != owners.length || owners.length != values.length) {
      revert("must pass the same number of labels and owners");
    }

    uint256 dispersedTotal = 0;

    for (uint i = 0; i < owners.length; i++) {
      bytes32 label = labels[i];
      address payable owner = owners[i];
      uint256 value = values[i];

       
      bytes32 subnode = namehash(label);

       
      address currentOwner = ens.owner(subnode);

       
      if (currentOwner != address(0) && currentOwner != owner) {
        revert("the label owner may not be changed");
      }

       
      if (currentOwner == owner) {
        continue;
      }

      Resolver publicResolver = getPublicResolver();

       
      ens.setSubnodeOwner(rootNode, label, address(this));

       
      ens.setResolver(subnode, address(publicResolver));

       
      publicResolver.setAddr(subnode, owner);

       
      ens.setSubnodeOwner(rootNode, label, owner);

      if (value > 0) {
        dispersedTotal = dispersedTotal + value;
        owner.transfer(value);
      }

      emit Registration(msg.sender, label, owner, value);
    }

    if (dispersedTotal < msg.value) {
      msg.sender.transfer(msg.value - dispersedTotal);
    }
  }

}