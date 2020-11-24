 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}


 
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
contract Finder is Ownable {

    mapping(bytes32 => address) public interfacesImplemented;

    event InterfaceImplementationChanged(bytes32 indexed interfaceName, address indexed newImplementationAddress);

     
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress)
        external
        onlyOwner
    {
        interfacesImplemented[interfaceName] = implementationAddress;
        emit InterfaceImplementationChanged(interfaceName, implementationAddress);
    }
    
     
    function getImplementationAddress(bytes32 interfaceName)
        external
        view
        returns (address implementationAddress)
    {
        implementationAddress = interfacesImplemented[interfaceName];
        require(implementationAddress != address(0x0), "No implementation for interface found");
    }
}