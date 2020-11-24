 

pragma solidity ^0.4.18;
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract Ownable {
  address public owner;
   
  function Ownable() {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}
 
contract KYC is Ownable {
   
  mapping (address => bool) public registeredAddress;
   
  mapping (address => bool) public admin;
  event Registered(address indexed _addr);
  event Unregistered(address indexed _addr);
  event NewAdmin(address indexed _addr);
  event ClaimedTokens(address _token, address owner, uint256 balance);
   
  modifier onlyRegistered(address _addr) {
    require(registeredAddress[_addr]);
    _;
  }
   
  modifier onlyAdmin() {
    require(admin[msg.sender]);
    _;
  }
  function KYC() {
    admin[msg.sender] = true;
  }
   
  function setAdmin(address _addr)
    public
    onlyOwner
  {
    require(_addr != address(0) && admin[_addr] == false);
    admin[_addr] = true;
    NewAdmin(_addr);
  }
   
  function register(address _addr)
    public
    onlyAdmin
  {
    require(_addr != address(0) && registeredAddress[_addr] == false);
    registeredAddress[_addr] = true;
    Registered(_addr);
  }
   
  function registerByList(address[] _addrs)
    public
    onlyAdmin
  {
    for(uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != address(0) && registeredAddress[_addrs[i]] == false);
      registeredAddress[_addrs[i]] = true;
      Registered(_addrs[i]);
    }
  }
   
  function unregister(address _addr)
    public
    onlyAdmin
    onlyRegistered(_addr)
  {
    registeredAddress[_addr] = false;
    Unregistered(_addr);
  }
   
  function unregisterByList(address[] _addrs)
    public
    onlyAdmin
  {
    for(uint256 i = 0; i < _addrs.length; i++) {
      require(registeredAddress[_addrs[i]]);
      registeredAddress[_addrs[i]] = false;
      Unregistered(_addrs[i]);
    }
  }
  function claimTokens(address _token) public onlyOwner {
    if (_token == 0x0) {
        owner.transfer(this.balance);
        return;
    }
    ERC20Basic token = ERC20Basic(_token);
    uint256 balance = token.balanceOf(this);
    token.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }
}