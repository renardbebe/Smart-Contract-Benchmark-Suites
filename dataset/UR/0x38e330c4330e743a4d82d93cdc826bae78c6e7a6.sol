 

pragma solidity ^0.4.17;

 
 
 
 
 
 
 
 
 


 
 
 
contract Owned {

     
     
     
    address public owner;
    address public newOwner;

     
     
     
    function Owned() public {
        owner = msg.sender;
    }


     
     
     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


     
     
     
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }


     
     
     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
    event OwnershipTransferred(address indexed _from, address indexed _to);
}


 
 
 
contract Admined is Owned {

     
     
     
    mapping (address => bool) public admins;

     
     
     
    event AdminAdded(address addr);
    event AdminRemoved(address addr);


     
     
     
    modifier onlyAdmin() {
        require(admins[msg.sender] || owner == msg.sender);
        _;
    }


     
     
     
    function addAdmin(address addr) public onlyOwner {
        admins[addr] = true;
        AdminAdded(addr);
    }


     
     
     
    function removeAdmin(address addr) public onlyOwner {
        delete admins[addr];
        AdminRemoved(addr);
    }
}


 
 
 
contract DeveryPresaleWhitelist is Admined {

     
     
     
    bool public sealed;

     
     
     
    mapping(address => uint) public whitelist;

     
     
     
    event Whitelisted(address indexed addr, uint max);


     
     
     
    function DeveryPresaleWhitelist() public {
    }


     
     
     
    function add(address addr, uint max) public onlyAdmin {
        require(!sealed);
        require(addr != 0x0);
        whitelist[addr] = max;
        Whitelisted(addr, max);
    }


     
     
     
    function multiAdd(address[] addresses, uint[] max) public onlyAdmin {
        require(!sealed);
        require(addresses.length != 0);
        require(addresses.length == max.length);
        for (uint i = 0; i < addresses.length; i++) {
            require(addresses[i] != 0x0);
            whitelist[addresses[i]] = max[i];
            Whitelisted(addresses[i], max[i]);
        }
    }


     
     
     
    function seal() public onlyOwner {
        require(!sealed);
        sealed = true;
    }


     
     
     
    function () public {
    }
}