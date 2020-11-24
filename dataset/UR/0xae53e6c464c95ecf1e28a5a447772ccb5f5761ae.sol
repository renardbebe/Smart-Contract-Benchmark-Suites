 

pragma solidity ^0.4.24;

 
contract ERC20 {
  address public owner;
  string public name;
  string public symbol;
  uint256 public decimals;
  uint256 public totalSupply;

  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  function allowance(address _owner, address _spender) public view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract ERC20MetaInfo {
  address public owner;
  mapping (address => mapping (string => string)) keyValues;

   
  constructor() public {
    owner = msg.sender;
  }

   
  function setKeyValue(ERC20 _token, string _key, string _value) public returns (bool) {
     
     
     
    require(bytes(keyValues[_token][_key]).length == 0 || owner == msg.sender || _token.owner() == msg.sender);
    keyValues[_token][_key] = _value;
    return true;
  }

   
  function getKeyValue(address _token, string _key) public view returns (string _value) {
    return keyValues[_token][_key];
  }
}