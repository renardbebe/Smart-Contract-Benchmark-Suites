 

 


pragma solidity 0.4.25;


 
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


 
contract LandRegistry is Claimable {
  mapping(string => address) private landRegistry;

  event Tokenized(string eGrid, address indexed property);
  event Untokenized(string eGrid, address indexed property);

   
  function getProperty(string _eGrid) public view returns (address property) {
    property = landRegistry[_eGrid];
  }

  function tokenizeProperty(string _eGrid, address _property) public onlyOwner {
    require(bytes(_eGrid).length > 0, "eGrid must be non-empty string");
    require(_property != address(0), "property address must be non-null");
    require(landRegistry[_eGrid] == address(0), "property must not already exist in land registry");

    landRegistry[_eGrid] = _property;
    emit Tokenized(_eGrid, _property);
  }

  function untokenizeProperty(string _eGrid) public onlyOwner {
    address property = getProperty(_eGrid);
    require(property != address(0), "property must exist in land registry");

    landRegistry[_eGrid] = address(0);
    emit Untokenized(_eGrid, property);
  }
}