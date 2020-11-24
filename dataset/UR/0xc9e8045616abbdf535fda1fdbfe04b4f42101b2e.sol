 

pragma solidity ^0.4.18;


 
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




 
contract KYC is Ownable {
   
   
   
  mapping (address => mapping (bool => bool)) public registeredAddress;

   
  mapping (address => bool) public admin;

  event Registered(address indexed _addr);
  event Unregistered(address indexed _addr);
  event SetAdmin(address indexed _addr);

   
  modifier onlyRegistered(address _addr, bool _isPresale) {
    require(registeredAddress[_addr][_isPresale]);
    _;
  }

   
  modifier onlyAdmin() {
    require(admin[msg.sender]);
    _;
  }

  function KYC() public {
    admin[msg.sender] = true;
  }

   
  function setAdmin(address _addr, bool _value)
    public
    onlyOwner
    returns (bool)
  {
    require(_addr != address(0));
    require(admin[_addr] == !_value);

    admin[_addr] = _value;

    SetAdmin(_addr);

    return true;
  }

   
  function isRegistered(address _addr, bool _isPresale)
    public
    view
    returns (bool)
  {
    return registeredAddress[_addr][_isPresale];
  }

   
  function register(address _addr, bool _isPresale)
    public
    onlyAdmin
  {
    require(_addr != address(0) && registeredAddress[_addr][_isPresale] == false);

    registeredAddress[_addr][_isPresale] = true;

    Registered(_addr);
  }

   
  function registerByList(address[] _addrs, bool _isPresale)
    public
    onlyAdmin
  {
    for(uint256 i = 0; i < _addrs.length; i++) {
      register(_addrs[i], _isPresale);
    }
  }

   
  function unregister(address _addr, bool _isPresale)
    public
    onlyAdmin
    onlyRegistered(_addr, _isPresale)
  {
    registeredAddress[_addr][_isPresale] = false;

    Unregistered(_addr);
  }

   
  function unregisterByList(address[] _addrs, bool _isPresale)
    public
    onlyAdmin
  {
    for(uint256 i = 0; i < _addrs.length; i++) {
      unregister(_addrs[i], _isPresale);
    }
  }
}