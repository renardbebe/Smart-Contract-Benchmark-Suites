 

pragma solidity ^0.4.19;

 

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    function Ownable() public {
        owner = msg.sender;
    }

   
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

   
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


contract HandleLogic is Ownable {

    uint256 public price;  

    mapping (bytes32 => mapping (bytes32 => address)) public handleIndex;  
    mapping (bytes32 => bool) public baseRegistred;  
    mapping (address => mapping (bytes32 => bool)) public ownsBase;  

    event NewBase(bytes32 _base, address indexed _address);
    event NewHandle(bytes32 _base, bytes32 _handle, address indexed _address);
    event BaseTransfered(bytes32 _base, address indexed _to);

    function registerBase(bytes32 _base) public payable {
        require(msg.value >= price);  
        require(!baseRegistred[_base]);  
        baseRegistred[_base] = true;  
        ownsBase[msg.sender][_base] = true;  
        NewBase(_base, msg.sender);
    }

    function registerHandle(bytes32 _base, bytes32 _handle, address _addr) public {
        require(baseRegistred[_base]);  
        require(_addr != address(0));  
        require(ownsBase[msg.sender][_base]);  
        handleIndex[_base][_handle] = _addr;  
        NewHandle(_base, _handle, msg.sender);
    }

    function transferBase(bytes32 _base, address _newAddress) public {
        require(baseRegistred[_base]);  
        require(_newAddress != address(0));  
        require(ownsBase[msg.sender][_base]);  
        ownsBase[msg.sender][_base] = false;  
        ownsBase[_newAddress][_base] = true;  
        BaseTransfered(_base, msg.sender);
    }

     
    function getPrice() public view returns(uint256) {
        return price;
    }

     
    function findAddress(bytes32 _base, bytes32 _handle) public view returns(address) {
        return handleIndex[_base][_handle];
    }

     
    function isRegistered(bytes32 _base) public view returns(bool) {
        return baseRegistred[_base];
    }

     
    function doesOwnBase(bytes32 _base, address _addr) public view returns(bool) {
        return ownsBase[_addr][_base];
    }
}


contract AHS is HandleLogic {

    function AHS(uint256 _price, bytes32 _ethBase, bytes32 _weldBase) public {
        price = _price;
        getBaseQuick(_ethBase);
        getBaseQuick(_weldBase);
    }

    function () public payable {}  

    function getBaseQuick(bytes32 _base) public {
        require(msg.sender == owner);  
        require(!baseRegistred[_base]);  
        baseRegistred[_base] = true;  
        ownsBase[owner][_base] = true;  
        NewBase(_base, msg.sender);
    }

    function withdraw() public {
        require(msg.sender == owner);  
        owner.transfer(this.balance);
    }

    function changePrice(uint256 _price) public {
        require(msg.sender == owner);  
        price = _price;
    }

}