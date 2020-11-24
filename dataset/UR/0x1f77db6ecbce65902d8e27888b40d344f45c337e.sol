 

pragma solidity ^0.4.16;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
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






contract WHSCoin is StandardToken, Ownable {
  string public constant name = "White Stone Coin";
  string public constant symbol = "WHS";
  uint256 public constant decimals = 18;

  uint256 public constant UNIT = 10 ** decimals;

  address public companyWallet;
  address public admin;

  uint256 public tokenPrice = 0.01 ether;
  uint256 public maxSupply = 10000000 * UNIT;
  uint256 public totalSupply = 0;
  uint256 public totalWeiReceived = 0;

  uint256 startDate  = 1516856400;  
  uint256 endDate    = 1522731600;  

  uint256 bonus30end = 1518066000;  
  uint256 bonus15end = 1519794000;  
  uint256 bonus5end  = 1521003600;  

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  event NewSale();

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  function WHSCoin(address _companyWallet, address _admin) public {
    companyWallet = _companyWallet;
    admin = _admin;
    balances[companyWallet] = 5000000 * UNIT;
    totalSupply = totalSupply.add(5000000 * UNIT);
    Transfer(address(0x0), _companyWallet, 5000000 * UNIT);
  }

  function setAdmin(address _admin) public onlyOwner {
    admin = _admin;
  }

  function calcBonus(uint256 _amount) internal view returns (uint256) {
    uint256 bonusPercentage = 30;
    if (now > bonus30end) bonusPercentage = 15;
    if (now > bonus15end) bonusPercentage = 5;
    if (now > bonus5end) bonusPercentage = 0;
    return _amount * bonusPercentage / 100;
  }

  function buyTokens() public payable {
    require(now < endDate);
    require(now >= startDate);
    require(msg.value > 0);

    uint256 amount = msg.value * UNIT / tokenPrice;
    uint256 bonus = calcBonus(msg.value) * UNIT / tokenPrice;
    
    totalSupply = totalSupply.add(amount);
    
    require(totalSupply <= maxSupply);

    totalWeiReceived = totalWeiReceived.add(msg.value);

    balances[msg.sender] = balances[msg.sender].add(amount);
    
    TokenPurchase(msg.sender, msg.sender, msg.value, amount);
    
    Transfer(address(0x0), msg.sender, amount);

    if (bonus > 0) {
      Transfer(companyWallet, msg.sender, bonus);
      balances[companyWallet] -= bonus;
      balances[msg.sender] = balances[msg.sender].add(bonus);
    }

    companyWallet.transfer(msg.value);
  }

  function() public payable {
    buyTokens();
  }

   
  function sendTokens(address receiver, uint256 tokens) public onlyAdmin {
    require(totalSupply + tokens <= maxSupply);

    balances[receiver] += tokens;
    totalSupply += tokens;
    Transfer(address(0x0), receiver, tokens);
  }

  function sendBonus(address receiver, uint256 bonus) public onlyAdmin {
    Transfer(companyWallet, receiver, bonus);
    balances[companyWallet] = balances[companyWallet].sub(bonus);
    balances[receiver] = balances[receiver].add(bonus);
  }

}