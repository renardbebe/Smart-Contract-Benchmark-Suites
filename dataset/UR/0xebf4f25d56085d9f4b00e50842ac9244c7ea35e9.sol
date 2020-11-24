 

pragma solidity ^0.4.24;

 
library SafeMath {
    uint256 constant public MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) revert();
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x < y) revert();
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) revert();
        return x * y;
    }
}

 
contract Owned{
  address public owner;
  event TransferOwnerShip(address indexed previousOwner, address indexed newOwner);

  constructor() public{
    owner = msg.sender;
  }

  modifier onlyOwner{
    require(msg.sender == owner);
    _;
  }

  function transferOwnerShip(address newOwner) onlyOwner public{
      require(newOwner != address(0));
      emit TransferOwnerShip(owner, newOwner);
    owner = newOwner;
  }
}

 
contract ERC20Basic{
  function totalSupply()              public view returns (uint256);
  function balanceOf(address _owner)  public view returns (uint256 balance);
  function transfer(address _to,uint256 _value) public returns (bool success);
  function transferFrom(address _from,address _to,uint256 _value) public returns (bool success);
  function approve(address _spender,uint _value) public returns (bool success);
  function allowance(address _owner,address _spender) public view returns (uint256 remaining);

  event Transfer(address indexed _from,address indexed _to,uint256 _value);
  event Approval(address indexed _owner,address indexed _spender,uint256 _value);
}

 
contract ERC20StandardToken is ERC20Basic,Owned{
    using SafeMath for uint256;
    uint currentTotalSupply = 0;     
    uint airdropNum = 0 ether;       
    
     
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) touched;

     
     
     
     
     
     
     
     
    
    
   function _transfer(address _from,address _to, uint256 _value) internal {
    require(_to != 0x0);
    uint256 previousBalances = balances[_from].safeAdd(balances[_to]);
    balances[_from] = balances[_from].safeSub(_value);
    balances[_to]   = balances[_to].safeAdd(_value);

    emit Transfer(_from,_to,_value);
    assert(balances[_from].safeAdd(balances[_to]) == previousBalances);
   }

   
  function transfer(address _to, uint256 _value) public returns (bool success){
    _transfer(msg.sender,_to,_value);
    return true;
  }

    
  function transferFrom(address _from,address _to,uint256 _value) public returns (bool success){
    require(allowance[_from][msg.sender] >= _value);
    allowance[_from][msg.sender] = allowance[_from][msg.sender].safeSub(_value);
    
    _transfer(_from,_to,_value);
    return true;  
  }

   
  function approve(address _spender,uint256 _value) public  returns (bool success){
    require(_value > 0);
    require(_spender != 0x0);
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender,_spender,_value);
    return true;
  }
  
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowance[_owner][_spender];
    }
}

contract SLifeToken is ERC20StandardToken{
  
  string  public name;
  string  public symbol;
  uint8   public decimals;
  uint public totalSupply;

   
  event Burn(address indexed _from, uint256 _value);
  
     
  constructor(string tokenName,string tokenSymbol,uint8 decimalUints,uint256 initialSupply) public{
    totalSupply           = initialSupply * 10 ** uint256(decimalUints);   
    balances[msg.sender] = totalSupply;                                  
    name                  = tokenName;                                   
    symbol                = tokenSymbol;                                
    decimals              = decimalUints;                              
  }

   function balanceOf(address _owner) public view returns (uint256 balance){
      if (!touched[_owner] && currentTotalSupply < totalSupply && _owner != owner) {
            touched[_owner] = true;
            currentTotalSupply = currentTotalSupply.safeAdd(airdropNum);
            balances[_owner] += airdropNum;
        }
      return balances[_owner];
    }
    
   
  function totalSupply() public view returns (uint256){
     return totalSupply;
  }
  
  function batch(address []toAddr, uint256 []value) returns (bool){
    require(toAddr.length == value.length && toAddr.length >= 1);
    for(uint256 i = 0 ; i < toAddr.length; i++){
        transfer(toAddr[i], value[i]);
    }
  }


  
  function mintToken(address _to,uint256 mintedAmount) onlyOwner public returns(bool success){
    require(_to != 0x0);
    balances[_to] = balances[_to].safeAdd(mintedAmount);
    totalSupply = totalSupply.safeAdd(mintedAmount);
    emit Transfer(0,address(this),mintedAmount);
    emit Transfer(address(this),_to,mintedAmount);
    return true;
  }

    
  function burn(uint256 _value) onlyOwner public returns (bool success){
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].safeSub(_value);
    totalSupply = totalSupply.safeSub(_value);
    emit Burn(msg.sender,_value);
    return true;
  }
}