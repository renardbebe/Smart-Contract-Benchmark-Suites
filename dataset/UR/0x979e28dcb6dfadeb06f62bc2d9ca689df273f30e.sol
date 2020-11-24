 

pragma solidity ^0.4.24;


 
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


contract Allow is Ownable {
    mapping(address => bool) public allowedMap;
    address[] public allowedArray;

    event AddressAllowed(address _handler, address _address);
    event AddressDenied(address _handler, address _address);

    constructor() public {

    }

    modifier allow() {
        require(allowedMap[msg.sender] == true);
        _;
    }

    function allowAccess(address _address) onlyOwner public {
        allowedMap[_address] = true;
        bool exists = false;
        for(uint i = 0; i < allowedArray.length; i++) {
            if(allowedArray[i] == _address) {
                exists = true;
                break;
            }
        }
        if(!exists) {
            allowedArray.push(_address);
        }
        emit AddressAllowed(msg.sender, _address);
    }

    function denyAccess(address _address) onlyOwner public {
        allowedMap[_address] = false;
        emit AddressDenied(msg.sender, _address);
    }
}


contract Copyright is Allow {
    bytes32[] public list;

    event SetLog(bytes32 hash, uint256 id);

    constructor() public  {
    }

    function save(bytes32 _hash) allow public {
        list.push(_hash);

        emit SetLog(_hash, list.length-1);
    }

    function count() public view returns(uint256) {
        return list.length;
    }
}