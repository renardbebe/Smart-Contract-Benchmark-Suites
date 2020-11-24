 

pragma solidity ^0.4.13;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {

  address public owner;
  function Ownable() { owner = msg.sender; }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {owner = newOwner;}
}

contract ERC20Interface {

  function totalSupply() constant returns (uint256 totalSupply);

  function balanceOf(address _owner) constant returns (uint256 balance);

  function transfer(address _to, uint256 _value) returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

  function approve(address _spender, uint256 _value) returns (bool success);

  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

 }

contract GMPToken is Ownable, ERC20Interface {

   
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

   
  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;

   
  function GMPToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
      ) {
      balances[msg.sender] = initialSupply;               
      totalSupply = initialSupply;                         
      name = tokenName;                                    
      symbol = tokenSymbol;                                
      decimals = decimalUnits;                             
  }

   

  function totalSupply() constant returns (uint256 totalSupply) { return totalSupply; }

  function balanceOf(address _owner) constant returns (uint256 balance) { return balances[_owner]; }

   
  function _transfer(address _from, address _to, uint _amount) internal {
      require (_to != 0x0);                                
      require (balances[_from] > _amount);                 
      require (balances[_to] + _amount > balances[_to]);  
      balances[_from] -= _amount;                          
      balances[_to] += _amount;                             
      Transfer(_from, _to, _amount);

  }

  function transfer(address _to, uint256 _amount) returns (bool success) {
    _transfer(msg.sender, _to, _amount);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    require (_value < allowed[_from][msg.sender]);      
    allowed[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _amount) returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function mintToken(uint256 mintedAmount) onlyOwner {
      balances[Ownable.owner] += mintedAmount;
      totalSupply += mintedAmount;
      Transfer(0, Ownable.owner, mintedAmount);
  }

}


contract Crowdsale is Ownable {

  using SafeMath for uint256;

   
  GMPToken public token;

   
  bool public saleIsActive;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


   

  function Crowdsale(uint256 initialRate, address targetWallet, uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) {

     
    require(initialRate > 0);
    require(targetWallet != 0x0);

     
    token = new GMPToken(initialSupply, tokenName, decimalUnits, tokenSymbol);
    rate = initialRate;
    wallet = targetWallet;
    saleIsActive = true;

  }

  function close() onlyOwner {
    selfdestruct(owner);
  }

   
  function transferToAddress(address targetWallet, uint256 tokenAmount) onlyOwner {
    token.transfer(targetWallet, tokenAmount);
  }


   
  function enableSale() onlyOwner {
    saleIsActive = true;
  }

  function disableSale() onlyOwner {
    saleIsActive = false;
  }

  function setRate(uint256 newRate)  onlyOwner {
    rate = newRate;
  }

   
  function mintToken(uint256 mintedAmount) onlyOwner {
    token.mintToken(mintedAmount);
  }



   

  function () payable {

    require(msg.sender != 0x0);
    require(saleIsActive);
    require(msg.value > rate);

    uint256 weiAmount = msg.value;

     
    weiRaised = weiRaised.add(weiAmount);

     
    uint256 tokenAmount = weiAmount.div(rate);

     
    wallet.transfer(msg.value);

     
    token.transfer(msg.sender, tokenAmount);
    TokenPurchase(msg.sender, wallet, weiAmount, tokenAmount);

  }



}