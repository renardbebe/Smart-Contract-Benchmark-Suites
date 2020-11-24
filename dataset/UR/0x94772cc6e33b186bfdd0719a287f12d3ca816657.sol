 

 

pragma solidity 0.5.2;



 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 




contract MarketContractRegistryInterface {
    function addAddressToWhiteList(address contractAddress) external;
    function isAddressWhiteListed(address contractAddress) external view returns (bool);
}



 
 
contract MarketContractRegistry is Ownable, MarketContractRegistryInterface {

     
    mapping(address => bool) public isWhiteListed;
    address[] public addressWhiteList;                              
    mapping(address => bool) public factoryAddressWhiteList;        

     
    event AddressAddedToWhitelist(address indexed contractAddress);
    event AddressRemovedFromWhitelist(address indexed contractAddress);
    event FactoryAddressAdded(address indexed factoryAddress);
    event FactoryAddressRemoved(address indexed factoryAddress);

     

     
     
    function isAddressWhiteListed(address contractAddress) external view returns (bool) {
        return isWhiteListed[contractAddress];
    }

     
     
    function getAddressWhiteList() external view returns (address[] memory) {
        return addressWhiteList;
    }

     
     
     
     
    function removeContractFromWhiteList(
        address contractAddress,
        uint whiteListIndex
    ) external onlyOwner
    {
        require(isWhiteListed[contractAddress], "can only remove whitelisted addresses");
        require(addressWhiteList[whiteListIndex] == contractAddress, "index does not match address");
        isWhiteListed[contractAddress] = false;

         
        addressWhiteList[whiteListIndex] = addressWhiteList[addressWhiteList.length - 1];
        addressWhiteList.length -= 1;
        emit AddressRemovedFromWhitelist(contractAddress);
    }

     
     
     
    function addAddressToWhiteList(address contractAddress) external {
        require(isOwner() || factoryAddressWhiteList[msg.sender], "Can only be added by factory or owner");
        require(!isWhiteListed[contractAddress], "Address must not be whitelisted");
        isWhiteListed[contractAddress] = true;
        addressWhiteList.push(contractAddress);
        emit AddressAddedToWhitelist(contractAddress);
    }

     
     
    function addFactoryAddress(address factoryAddress) external onlyOwner {
        require(!factoryAddressWhiteList[factoryAddress], "address already added");
        factoryAddressWhiteList[factoryAddress] = true;
        emit FactoryAddressAdded(factoryAddress);
    }

     
     
    function removeFactoryAddress(address factoryAddress) external onlyOwner {
        require(factoryAddressWhiteList[factoryAddress], "factory address is not in the white list");
        factoryAddressWhiteList[factoryAddress] = false;
        emit FactoryAddressRemoved(factoryAddress);
    }
}