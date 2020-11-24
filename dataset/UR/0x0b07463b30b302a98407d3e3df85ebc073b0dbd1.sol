 

pragma solidity ^0.4.17;

 

 
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

    mapping (bytes32 => Record) records;

     
    modifier only_owner(bytes32 node) {
        if (records[node].owner != msg.sender) throw;
        _;
    }

     
    function ENS() public {
        records[0].owner = msg.sender;
    }

     
    function owner(bytes32 node) public constant returns (address) {
        return records[node].owner;
    }

     
    function resolver(bytes32 node) public constant returns (address) {
        return records[node].resolver;
    }

     
    function ttl(bytes32 node) public constant returns (uint64) {
        return records[node].ttl;
    }

     
    function setOwner(bytes32 node, address owner) public only_owner(node) {
        Transfer(node, owner);
        records[node].owner = owner;
    }

     
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public only_owner(node) {
        var subnode = sha3(node, label);
        NewOwner(node, label, owner);
        records[subnode].owner = owner;
    }

     
    function setResolver(bytes32 node, address resolver) public only_owner(node) {
        NewResolver(node, resolver);
        records[node].resolver = resolver;
    }

     
    function setTTL(bytes32 node, uint64 ttl) public only_owner(node) {
        NewTTL(node, ttl);
        records[node].ttl = ttl;
    }
}

 

contract Deed {
    address public owner;
    address public previousOwner;
}

contract HashRegistrarSimplified {
    enum Mode { Open, Auction, Owned, Forbidden, Reveal, NotYetAvailable }

    bytes32 public rootNode;

    function entries(bytes32 _hash) public view returns (Mode, address, uint, uint, uint);
    function transfer(bytes32 _hash, address newOwner) public;
}

 

contract RegistrarInterface {
    event OwnerChanged(bytes32 indexed label, address indexed oldOwner, address indexed newOwner);
    event DomainConfigured(bytes32 indexed label);
    event DomainUnlisted(bytes32 indexed label);
    event NewRegistration(bytes32 indexed label, string subdomain, address indexed owner, address indexed referrer, uint price);
    event RentPaid(bytes32 indexed label, string subdomain, uint amount, uint expirationDate);

     
    function query(bytes32 label, string subdomain) public view returns (string domain, uint signupFee, uint rent, uint referralFeePPM);
    function register(bytes32 label, string subdomain, address owner, address referrer, address resolver) public payable;

    function rentDue(bytes32 label, string subdomain) public view returns (uint timestamp);
    function payRent(bytes32 label, string subdomain) public payable;
}

 

 
contract Resolver {
    function supportsInterface(bytes4 interfaceID) public pure returns (bool);
    function addr(bytes32 node) public view returns (address);
    function setAddr(bytes32 node, address addr) public;
}

 

 
contract SubdomainRegistrar is RegistrarInterface {

     
    bytes32 constant public TLD_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    bool public stopped = false;
    address public registrarOwner;
    address public migration;

    ENS public ens;
    HashRegistrarSimplified public hashRegistrar;

    struct Domain {
        string name;
        address owner;
        address transferAddress;
        uint price;
        uint referralFeePPM;
    }

    mapping (bytes32 => Domain) domains;

    modifier new_registrar() {
        require(ens.owner(TLD_NODE) != address(hashRegistrar));
        _;
    }

    modifier owner_only(bytes32 label) {
        require(owner(label) == msg.sender);
        _;
    }

    modifier not_stopped() {
        require(!stopped);
        _;
    }

    modifier registrar_owner_only() {
        require(msg.sender == registrarOwner);
        _;
    }

    event TransferAddressSet(bytes32 indexed label, address addr);
    event DomainTransferred(bytes32 indexed label, string name);

    function SubdomainRegistrar(ENS _ens) public {
        ens = _ens;
        hashRegistrar = HashRegistrarSimplified(ens.owner(TLD_NODE));
        registrarOwner = msg.sender;
    }

     
    function owner(bytes32 label) public view returns (address) {

        if (domains[label].owner != 0x0) {
            return domains[label].owner;
        }

        Deed domainDeed = deed(label);
        if (domainDeed.owner() != address(this)) {
            return 0x0;
        }

        return domainDeed.previousOwner();
    }

     
    function transfer(string name, address newOwner) public owner_only(keccak256(name)) {
        bytes32 label = keccak256(name);
        OwnerChanged(keccak256(name), domains[label].owner, newOwner);
        domains[label].owner = newOwner;
    }

     
    function setResolver(string name, address resolver) public owner_only(keccak256(name)) {
        bytes32 label = keccak256(name);
        bytes32 node = keccak256(TLD_NODE, label);
        ens.setResolver(node, resolver);
    }

     
    function configureDomain(string name, uint price, uint referralFeePPM) public {
        configureDomainFor(name, price, referralFeePPM, msg.sender, 0x0);
    }

     
    function configureDomainFor(string name, uint price, uint referralFeePPM, address _owner, address _transfer) public owner_only(keccak256(name)) {
        bytes32 label = keccak256(name);
        Domain storage domain = domains[label];

         
        require(domain.transferAddress == 0 || _transfer == 0 || domain.transferAddress == _transfer);

        if (domain.owner != _owner) {
            domain.owner = _owner;
        }

        if (keccak256(domain.name) != label) {
             
            domain.name = name;
        }

        domain.price = price;
        domain.referralFeePPM = referralFeePPM;

        if (domain.transferAddress != _transfer && _transfer != 0) {
            domain.transferAddress = _transfer;
            TransferAddressSet(label, _transfer);
        }

        DomainConfigured(label);
    }

     
    function setTransferAddress(string name, address transfer) public owner_only(keccak256(name)) {
        bytes32 label = keccak256(name);
        Domain storage domain = domains[label];

        require(domain.transferAddress == 0x0);

        domain.transferAddress = transfer;
        TransferAddressSet(label, transfer);
    }

     
    function unlistDomain(string name) public owner_only(keccak256(name)) {
        bytes32 label = keccak256(name);
        Domain storage domain = domains[label];
        DomainUnlisted(label);

        domain.name = '';
        domain.owner = owner(label);
        domain.price = 0;
        domain.referralFeePPM = 0;
    }

     
    function query(bytes32 label, string subdomain) public view returns (string domain, uint price, uint rent, uint referralFeePPM) {
        bytes32 node = keccak256(TLD_NODE, label);
        bytes32 subnode = keccak256(node, keccak256(subdomain));

        if (ens.owner(subnode) != 0) {
            return ('', 0, 0, 0);
        }

        Domain data = domains[label];
        return (data.name, data.price, 0, data.referralFeePPM);
    }

     
    function register(bytes32 label, string subdomain, address subdomainOwner, address referrer, address resolver) public not_stopped payable {
        bytes32 domainNode = keccak256(TLD_NODE, label);
        bytes32 subdomainLabel = keccak256(subdomain);

         
        require(ens.owner(keccak256(domainNode, subdomainLabel)) == address(0));

        Domain storage domain = domains[label];

         
        require(keccak256(domain.name) == label);

         
        require(msg.value >= domain.price);

         
        if (msg.value > domain.price) {
            msg.sender.transfer(msg.value - domain.price);
        }

         
        uint256 total = domain.price;
        if (domain.referralFeePPM * domain.price > 0 && referrer != 0 && referrer != domain.owner) {
            uint256 referralFee = (domain.price * domain.referralFeePPM) / 1000000;
            referrer.transfer(referralFee);
            total -= referralFee;
        }

         
        if (total > 0) {
            domain.owner.transfer(total);
        }

         
        if (subdomainOwner == 0) {
            subdomainOwner = msg.sender;
        }
        doRegistration(domainNode, subdomainLabel, subdomainOwner, Resolver(resolver));

        NewRegistration(label, subdomain, subdomainOwner, referrer, domain.price);
    }

    function doRegistration(bytes32 node, bytes32 label, address subdomainOwner, Resolver resolver) internal {
         
        ens.setSubnodeOwner(node, label, this);

        bytes32 subnode = keccak256(node, label);
         
        ens.setResolver(subnode, resolver);

         
        resolver.setAddr(subnode, subdomainOwner);

         
        ens.setOwner(subnode, subdomainOwner);
    }

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return (
            (interfaceID == 0x01ffc9a7)  
            || (interfaceID == 0xc1b15f5a)  
        );
    }

    function rentDue(bytes32 label, string subdomain) public view returns (uint timestamp) {
        return 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }

     
    function upgrade(string name) public owner_only(keccak256(name)) new_registrar {
        bytes32 label = keccak256(name);
        address transfer = domains[label].transferAddress;

        require(transfer != 0x0);

        delete domains[label];

        hashRegistrar.transfer(label, transfer);
        DomainTransferred(label, name);
    }


     
    function stop() public not_stopped registrar_owner_only {
        stopped = true;
    }

     
    function setMigrationAddress(address _migration) public registrar_owner_only {
        require(stopped);
        migration = _migration;
    }

     
    function migrate(string name) public owner_only(keccak256(name)) {
        require(stopped);
        require(migration != 0x0);

        bytes32 label = keccak256(name);
        Domain storage domain = domains[label];

        hashRegistrar.transfer(label, migration);

        SubdomainRegistrar(migration).configureDomainFor(
            domain.name,
            domain.price,
            domain.referralFeePPM,
            domain.owner,
            domain.transferAddress
        );

        delete domains[label];

        DomainTransferred(label, name);
    }

    function transferOwnership(address newOwner) public registrar_owner_only {
        registrarOwner = newOwner;
    }

    function payRent(bytes32 label, string subdomain) public payable {
        revert();
    }

    function deed(bytes32 label) internal view returns (Deed) {
        var (,deedAddress,,,) = hashRegistrar.entries(label);
        return Deed(deedAddress);
    }
}