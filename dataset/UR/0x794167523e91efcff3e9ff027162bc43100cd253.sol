 

pragma solidity ^0.4.20;
 
 
 
 
 
contract TokenERC20
{
   
  string public name;
   
  string public symbol;
   
  uint8 public decimals;
   
  uint256 _decimals;
   
  uint256 public tokenReward;
   
  uint256 public totalSupply;
   
  address public owner;
   
  string public status;
   
  uint256 public start_token_time;
   
  uint256 public stop_token_time;
   
  uint256 public transferLock;

   
  modifier isOwner
  {
    assert(owner == msg.sender);
    _;
  }

   
  mapping (address => uint256) public balanceOf;

   
  event Transfer(address indexed from, address indexed to, uint256 value);
  event token_Burn(address indexed from, uint256 value);
  event token_Add(address indexed from, uint256 value);
  event Deposit(address _sender, uint amount ,string status);
  event change_Owner(string newOwner);
  event change_Status(string newStatus);
  event change_Name(string newName);
  event change_Symbol(string newSymbol);
  event change_TokenReward(uint256 newTokenReward);
  event change_Time_Stamp(uint256 change_start_time_stamp,uint256 change_stop_time_stamp);

   
  function TokenERC20() public
  {
     
    name = "GMB";
     
    symbol = "MAS";
     
    decimals = 18;
     
    _decimals = 10 ** uint256(decimals);
     
    tokenReward = 0;
     
    totalSupply =  _decimals * 10000000000;  
     
    status = "Private";
     
    start_token_time = 1514732400;
     
    stop_token_time = 1546268399;
     
    owner = msg.sender;
     
    balanceOf[msg.sender] = totalSupply;
     
    transferLock = 1;  
  }
   
  function() payable public
  {
     
    uint256 cal;
     
    require(start_token_time < block.timestamp);
     
    require(stop_token_time > block.timestamp);
     
    emit Deposit(msg.sender, msg.value, status);
     
    cal = (msg.value)*tokenReward;
     
    require(balanceOf[owner] >= cal);
     
    require(balanceOf[msg.sender] + cal >= balanceOf[msg.sender]);
     
    balanceOf[owner] -= cal;
     
    balanceOf[msg.sender] += cal;
     
    emit Transfer(owner, msg.sender, cal);
  }
   
  function transfer(address _to, uint256 _value) public
  {
     
    require(transferLock == 0);  
     
    require(balanceOf[msg.sender] >= _value);
     
    require((balanceOf[_to] + _value) >= balanceOf[_to]);
     
    balanceOf[msg.sender] -= _value;
     
    balanceOf[_to] += _value;
     
    emit Transfer(msg.sender, _to, _value);
  }
   
  function admin_transfer(address _to, uint256 _value) public isOwner
  {
     
     
    require(balanceOf[msg.sender] >= _value*_decimals);
     
    require(balanceOf[_to] + (_value *_decimals)>= balanceOf[_to]);
     
    balanceOf[msg.sender] -= _value*_decimals;
     
    balanceOf[_to] += _value*_decimals;
     
    emit Transfer(msg.sender, _to, _value*_decimals);
  }
   
  function admin_from_To_transfer(address _from, address _to, uint256 _value) public isOwner
  {
     
     
    require(balanceOf[_from] >= _value*_decimals);
     
    require(balanceOf[_to] + (_value *_decimals)>= balanceOf[_to]);
     
    balanceOf[_from] -= _value*_decimals;
     
    balanceOf[_to] += _value*_decimals;
     
    emit Transfer(_from, _to, _value*_decimals);
  }
   
  function admin_token_burn(uint256 _value) public isOwner returns (bool success)
  {
     
    require(balanceOf[msg.sender] >= _value*_decimals);
     
    balanceOf[msg.sender] -= _value*_decimals;
     
    totalSupply -= _value*_decimals;
     
    emit token_Burn(msg.sender, _value*_decimals);
    return true;
  }
   
  function admin_token_add(uint256 _value) public  isOwner returns (bool success)
  {
    require(balanceOf[msg.sender] >= _value*_decimals);
     
    balanceOf[msg.sender] += _value*_decimals;
     
    totalSupply += _value*_decimals;
     
    emit token_Add(msg.sender, _value*_decimals);
    return true;
  }
   
  function change_name(string _tokenName) public isOwner returns (bool success)
  {
     
    name = _tokenName;
     
    emit change_Name(name);
    return true;
  }
   
  function change_symbol(string _symbol) public isOwner returns (bool success)
  {
     
    symbol = _symbol;
     
    emit change_Symbol(symbol);
    return true;
  }
   
  function change_status(string _status) public isOwner returns (bool success)
  {
     
    status = _status;
     
    emit change_Status(status);
    return true;
  }
   
  function change_tokenReward(uint256 _tokenReward) public isOwner returns (bool success)
  {
     
    tokenReward = _tokenReward;
     
    emit change_TokenReward(tokenReward);
    return true;
  }
   
  function ETH_withdraw(uint256 amount) public isOwner returns(bool)
  {
     
    owner.transfer(amount);
     
    return true;
  }
   
  function change_time_stamp(uint256 _start_token_time,uint256 _stop_token_time) public isOwner returns (bool success)
  {
     
    start_token_time = _start_token_time;
     
    stop_token_time = _stop_token_time;

     
    emit change_Time_Stamp(start_token_time,stop_token_time);
    return true;
  }
   
  function change_owner(address to_owner) public isOwner returns (bool success)
  {
     
    owner = to_owner;
     
    emit change_Owner("Owner_change");
    return true;
  }
   
  function setTransferLock(uint256 transferLock_status) public isOwner returns (bool success)
  {
     
    transferLock = transferLock_status;
     
    return true;
  }
   
  function change_time_stamp_status(uint256 _start_token_time,uint256 _stop_token_time,string _status) public isOwner returns (bool success)
  {
     
    start_token_time = _start_token_time;
     
    stop_token_time = _stop_token_time;
     
    status = _status;
     
    emit change_Time_Stamp(start_token_time,stop_token_time);
     
    emit change_Status(status);
    return true;
  }
}