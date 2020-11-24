 

pragma solidity ^0.5.4;

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

contract LandRegistry is Ownable {
  mapping(string => address) private landRegistry;

  event Tokenized(string eGrid, address indexed property);
  event Untokenized(string eGrid, address indexed property);

   
  function getProperty(string memory _eGrid) public view returns (address property) {
    property = landRegistry[_eGrid];
  }

  function tokenizeProperty(string memory _eGrid, address _property) public onlyOwner {
    require(bytes(_eGrid).length > 0, "eGrid must be non-empty string");
    require(_property != address(0), "property address must be non-null");
    require(landRegistry[_eGrid] == address(0), "property must not already exist in land registry");

    landRegistry[_eGrid] = _property;
    emit Tokenized(_eGrid, _property);
  }

  function untokenizeProperty(string memory _eGrid) public onlyOwner {
    address property = getProperty(_eGrid);
    require(property != address(0), "property must exist in land registry");

    landRegistry[_eGrid] = address(0);
    emit Untokenized(_eGrid, property);
  }
}