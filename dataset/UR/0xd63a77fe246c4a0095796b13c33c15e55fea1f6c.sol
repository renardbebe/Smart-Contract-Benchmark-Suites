 

pragma solidity ^0.4.24;

 
library AddrSet {
     
     
    struct Data { mapping(address => bool) flags; }

     
     
     
     
     
     
    function insert(Data storage self, address value) internal returns (bool) {
        if (self.flags[value]) {
            return false;  
        }
        self.flags[value] = true;
        return true;
    }

    function remove(Data storage self, address value) internal returns (bool) {
        if (!self.flags[value]) {
            return false;  
        }
        self.flags[value] = false;
        return true;
    }

    function contains(Data storage self, address value) internal view returns (bool) {
        return self.flags[value];
    }
}

contract Owned {
    
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

 
 
 

 
contract KYC is Owned {

     
     
     
     
     
    enum Status {
        unknown,
        approved,
        suspended
    }

     
    event ProviderAdded(address indexed addr);
    event ProviderRemoved(address indexed addr);
    event AddrApproved(address indexed addr, address indexed by);
    event AddrSuspended(address indexed addr, address indexed by);

     
    AddrSet.Data private kycProviders;
    mapping(address => Status) public kycStatus;

     
    function registerProvider(address addr) public onlyOwner {
        require(AddrSet.insert(kycProviders, addr));
        emit ProviderAdded(addr);
    }

     
    function removeProvider(address addr) public onlyOwner {
        require(AddrSet.remove(kycProviders, addr));
        emit ProviderRemoved(addr);
    }

     
    function isProvider(address addr) public view returns (bool) {
        return addr == owner || AddrSet.contains(kycProviders, addr);
    }

     
    function getStatus(address addr) public view returns (Status) {
        return kycStatus[addr];
    }

     
     
    function approveAddr(address addr) public onlyAuthorized {
        Status status = kycStatus[addr];
        require(status != Status.approved);
        kycStatus[addr] = Status.approved;
        emit AddrApproved(addr, msg.sender);
    }

     
     
    function suspendAddr(address addr) public onlyAuthorized {
        Status status = kycStatus[addr];
        require(status != Status.suspended);
        kycStatus[addr] = Status.suspended;
        emit AddrSuspended(addr, msg.sender);
    }

     
    modifier onlyAuthorized() {
        require(msg.sender == owner || AddrSet.contains(kycProviders, msg.sender));
        _;
    }
}