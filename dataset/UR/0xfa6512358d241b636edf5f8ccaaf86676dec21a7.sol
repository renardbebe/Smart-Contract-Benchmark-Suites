 

pragma solidity ^0.4.4;

 
contract ENS {
     
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

     
    event Transfer(bytes32 indexed node, address owner);

     
    event NewResolver(bytes32 indexed node, address resolver);

     
    event NewTTL(bytes32 indexed node, uint64 ttl);

    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping(bytes32=>Record) records;

     
    modifier only_owner(bytes32 node) {
        if (records[node].owner != msg.sender) throw;
        _;
    }

     
    function ENS() {
        records[0].owner = msg.sender;
    }

     
    function owner(bytes32 node) constant returns (address) {
        return records[node].owner;
    }

     
    function resolver(bytes32 node) constant returns (address) {
        return records[node].resolver;
    }

     
    function ttl(bytes32 node) constant returns (uint64) {
        return records[node].ttl;
    }

     
    function setOwner(bytes32 node, address owner) only_owner(node) {
        Transfer(node, owner);
        records[node].owner = owner;
    }

     
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) only_owner(node) {
        var subnode = sha3(node, label);
        NewOwner(node, label, owner);
        records[subnode].owner = owner;
    }

     
    function setResolver(bytes32 node, address resolver) only_owner(node) {
        NewResolver(node, resolver);
        records[node].resolver = resolver;
    }

     
    function setTTL(bytes32 node, uint64 ttl) only_owner(node) {
        NewTTL(node, ttl);
        records[node].ttl = ttl;
    }
}

 
contract Resolver {
  function supportsInterface(bytes4 interfaceID) public pure returns (bool);
  function addr(bytes32 node) public view returns (address);
  function setAddr(bytes32 node, address addr) public;
}

contract RegistrarInterface {
  event OwnerChanged(bytes32 indexed label, address indexed oldOwner, address indexed newOwner);
  event DomainConfigured(bytes32 indexed label);
  event DomainUnlisted(bytes32 indexed label);
  event NewRegistration(bytes32 indexed label, string subdomain, address indexed owner, address indexed referrer, uint price);
  event RentPaid(bytes32 indexed label, string subdomain, uint amount, uint expirationDate);

   
  function query(bytes32 label, string subdomain) view returns(string domain, uint signupFee, uint rent, uint referralFeePPM);
  function register(bytes32 label, string subdomain, address owner, address referrer, address resolver) public payable;

  function rentDue(bytes32 label, string subdomain) public view returns(uint timestamp);
  function payRent(bytes32 label, string subdomain) public payable;
}
 
contract SubdomainRegistrar is RegistrarInterface {
   
  bytes32 constant public TLD_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

  ENS public ens;

  struct Domain {
    string name;
    address owner;
    uint price;
    uint referralFeePPM;
  }

  mapping(bytes32=>Domain) domains;

  function SubdomainRegistrar(ENS _ens) public {
    ens = _ens;
  }

   
  function owner(bytes32 label) public view returns(address ret) {
      ret = ens.owner(keccak256(TLD_NODE, label));
      if(ret == address(this)) {
        ret = domains[label].owner;
      }
  }

  modifier owner_only(bytes32 label) {
      require(owner(label) == msg.sender);
      _;
  }

   
  function transfer(string name, address newOwner) public owner_only(keccak256(name)) {
    var label = keccak256(name);
    OwnerChanged(keccak256(name), domains[label].owner, newOwner);
    domains[label].owner = newOwner;
  }

   
  function setResolver(string name, address resolver) public owner_only(keccak256(name)) {
    var label = keccak256(name);
    var node = keccak256(TLD_NODE, label);
    ens.setResolver(node, resolver);
  }

   
  function configureDomain(string name, uint price, uint referralFeePPM) public owner_only(keccak256(name)) {
    var label = keccak256(name);
    var domain = domains[label];

    if(keccak256(domain.name) != label) {
       
      domain.name = name;
    }
    if(domain.owner != msg.sender) {
      domain.owner = msg.sender;
    }
    domain.price = price;
    domain.referralFeePPM = referralFeePPM;
    DomainConfigured(label);
  }

   
  function unlistDomain(string name) public owner_only(keccak256(name)) {
    var label = keccak256(name);
    var domain = domains[label];
    DomainUnlisted(label);

    domain.name = '';
    domain.owner = owner(label);
    domain.price = 0;
    domain.referralFeePPM = 0;
  }

   
  function query(bytes32 label, string subdomain) view returns(string domain, uint price, uint rent, uint referralFeePPM) {
    var node = keccak256(TLD_NODE, label);
    var subnode = keccak256(node, keccak256(subdomain));

    if(ens.owner(subnode) != 0) {
      return ('', 0, 0, 0);
    }

    var data = domains[label];
    return (data.name, data.price, 0, data.referralFeePPM);
  }

   
  function register(bytes32 label, string subdomain, address subdomainOwner, address resolver, address referrer) public payable {
    var domainNode = keccak256(TLD_NODE, label);
    var subdomainLabel = keccak256(subdomain);

     
    require(ens.owner(keccak256(domainNode, subdomainLabel)) == address(0));

    var domain = domains[label];

     
    require(keccak256(domain.name) == label);

     
    require(msg.value >= domain.price);

     
    if(msg.value > domain.price) {
      msg.sender.transfer(msg.value - domain.price);
    }

     
    var total = domain.price;
    if(domain.referralFeePPM * domain.price > 0 && referrer != 0 && referrer != domain.owner) {
      var referralFee = (domain.price * domain.referralFeePPM) / 1000000;
      referrer.transfer(referralFee);
      total -= referralFee;
    }

     
    if(total > 0) {
      domain.owner.transfer(total);
    }

     
    if(subdomainOwner == 0) {
      subdomainOwner = msg.sender;
    }
    doRegistration(domainNode, subdomainLabel, subdomainOwner, Resolver(resolver));

    NewRegistration(label, subdomain, subdomainOwner, referrer, domain.price);
  }

  function doRegistration(bytes32 node, bytes32 label, address subdomainOwner, Resolver resolver) internal {
     
    ens.setSubnodeOwner(node, label, this);

    var subnode = keccak256(node, label);
     
    ens.setResolver(subnode, resolver);

     
    resolver.setAddr(subnode, subdomainOwner);

     
    ens.setOwner(subnode, subdomainOwner);
  }

  function supportsInterface(bytes4 interfaceID) constant returns (bool) {
    return (
         (interfaceID == 0x01ffc9a7)  
      || (interfaceID == 0xc1b15f5a)  
    );
  }

  function rentDue(bytes32 label, string subdomain) public view returns(uint timestamp) {
    return 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  }

  function payRent(bytes32 label, string subdomain) public payable {
    revert();
  }
}