 

 

pragma solidity 0.4.25;

 
interface IContractAddressLocator {
     
    function getContractAddress(bytes32 _identifier) external view returns (address);

     
    function isContractAddressRelates(address _contractAddress, bytes32[] _identifiers) external view returns (bool);
}

 

pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

pragma solidity ^0.4.24;



 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 

pragma solidity 0.4.25;



 

 
contract ContractAddressLocatorProxy is IContractAddressLocator, Claimable {
    string public constant VERSION = "1.0.0";

    IContractAddressLocator private contractAddressLocator;

    event Upgraded(IContractAddressLocator indexed _prev, IContractAddressLocator indexed _next);

     
    function getContractAddressLocator() external view returns (IContractAddressLocator) {
        return contractAddressLocator;
    }

     
    function getContractAddress(bytes32 _identifier) external view returns (address) {
        return contractAddressLocator.getContractAddress(_identifier);
    }

     
    function isContractAddressRelates(address _contractAddress, bytes32[] _identifiers) external view returns (bool){
        return contractAddressLocator.isContractAddressRelates(_contractAddress, _identifiers);
    }

     
    function upgrade(IContractAddressLocator _contractAddressLocator) external onlyOwner {
        require(_contractAddressLocator != address(0), "locator is illegal");
        emit Upgraded(contractAddressLocator, _contractAddressLocator);
        contractAddressLocator = _contractAddressLocator;
    }
}