 

pragma solidity ^0.4.18;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
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












 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}







 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}







 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}


contract GeocashToken is StandardToken, Destructible {
  string public name;
  string public symbol;
  uint public decimals;
  uint public buyPriceInWei;
  uint public sellPriceInWei;
  uint public minBalanceForAccounts;
  address public companyWallet;

  mapping(address => uint256) balances;
  mapping (address => bool) public frozenAccounts;
  event FrozenFunds(address target, bool frozen);

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function GeocashToken(uint256 _minBalanceForAccountsInWei, uint256 _buyPriceInWei, uint256 _sellPriceInWei, address _companyWallet) public {
    name = 'Geocash';
    symbol = 'GEO';
    decimals = 18;
    totalSupply = 500000000 * (10 ** uint256(decimals));
    balances[this] = totalSupply;
    minBalanceForAccounts = _minBalanceForAccountsInWei;
    buyPriceInWei = _buyPriceInWei;
    sellPriceInWei = _sellPriceInWei;
    companyWallet = _companyWallet;
  }


   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function isFrozen(address _owner) public view returns (bool frozen){
    return frozenAccounts[_owner];
  }




   

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(!frozenAccounts[msg.sender]);
    require(!frozenAccounts[_to]);
    require(_value <= balances[msg.sender]);
    if(msg.sender.balance < minBalanceForAccounts){
      sell((minBalanceForAccounts.sub(msg.sender.balance)).div(sellPriceInWei));
    }
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function setBuyPrice(uint _buyPriceInWei) onlyOwner public returns (bool){
    require(_buyPriceInWei > 0);
    buyPriceInWei = _buyPriceInWei;
    return true;
  }

  function setSellPrice(uint _sellPriceInWei) onlyOwner public returns (bool){
    require(_sellPriceInWei > 0);
    sellPriceInWei = _sellPriceInWei;
    return true;
  }

  function setCompanyWallet(address _wallet) onlyOwner public returns (bool){
    require(_wallet != address(0));
    companyWallet = _wallet;
    return true;
  }

  function buy() public payable returns (uint){
    require(msg.sender != address(0));
    require(msg.value >= 0);
    uint amount = msg.value.div(buyPriceInWei).mul(1 ether);
    require(amount > 0);
    require(balances[this] >= amount);
    uint oldBalance = balances[this].add(balances[msg.sender]);
    balances[this] = balances[this].sub(amount);
    balances[msg.sender] = balances[msg.sender].add(amount);
    uint newBalance = balances[this].add(balances[msg.sender]);
    assert(newBalance == oldBalance);
    Transfer(this, msg.sender, amount);
    return amount;
  }

  function sell(uint _amount) internal returns(uint revenue) {
    require(_amount > 0);
    require(balances[msg.sender]>= _amount);
    uint oldBalance =  balances[this].add(balances[msg.sender]);
    balances[this] = balances[this].add(_amount);
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    revenue = _amount.mul(sellPriceInWei).div(1 ether);
    require(revenue > 0);
    if(!msg.sender.send(revenue)){
      revert();
    }
    else {
      uint newBalance =  balances[this].add(balances[msg.sender]);
      assert(newBalance == oldBalance);
      Transfer(msg.sender, this, _amount);
      return _amount;
    }
  }

  function freezeAccount(address target, bool freeze) public onlyOwner {
    frozenAccounts[target] = freeze;
    FrozenFunds(target, freeze);
  }

  function setMinBalance(uint minimumBalanceInWei) public onlyOwner {
    minBalanceForAccounts = minimumBalanceInWei;
  }

   
  function forwardFundToCompanyWallet(uint _amount) public onlyOwner {
    companyWallet.transfer(_amount);
  }

  function distribute(address _to, uint256 _value) public onlyOwner returns (bool) {
    require(_to != address(0));
    balances[this] = balances[this].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(this, _to, _value);
    return true;
  }

   
  function () external payable {
    buy();
  }

}