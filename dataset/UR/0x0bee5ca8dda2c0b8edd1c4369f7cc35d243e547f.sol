 

pragma solidity ^0.4.19;

 

	 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

	 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

	 
contract VCA_Token is StandardToken, Ownable {
  string public constant name = "Virtual Cash";
  string public constant symbol = "VCA";
  uint256 public constant decimals = 8;

  uint256 public constant UNIT = 10 ** decimals;

  address public companyWallet;
  address public admin;

  uint256 public tokenPrice = 0.00025 ether;
  uint256 public maxSupply = 20000000 * UNIT;
  uint256 public totalSupply = 0;
  uint256 public totalWeiReceived = 0;

  uint256 startDate  = 1517443260;  
  uint256 endDate    = 1522537260;  

  uint256 bonus35end = 1517702460;  
  uint256 bonus32end = 1517961660;  
  uint256 bonus29end = 1518220860;  
  uint256 bonus26end = 1518480060;  
  uint256 bonus23end = 1518825660;  
  uint256 bonus20end = 1519084860;  
  uint256 bonus17end = 1519344060;  
  uint256 bonus14end = 1519603260;  
  uint256 bonus11end = 1519862460;  
  uint256 bonus09end = 1520121660;  
  uint256 bonus06end = 1520380860;  
  uint256 bonus03end = 1520640060;  

	 
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  event NewSale();

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  function VCA_Token(address _companyWallet, address _admin) public {
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
	              uint256 bonusPercentage = 35;
    if (now > bonus35end) bonusPercentage = 32;
    if (now > bonus32end) bonusPercentage = 29;
    if (now > bonus29end) bonusPercentage = 26;
    if (now > bonus26end) bonusPercentage = 23;
    if (now > bonus23end) bonusPercentage = 20;
    if (now > bonus20end) bonusPercentage = 17;
    if (now > bonus17end) bonusPercentage = 14;
    if (now > bonus14end) bonusPercentage = 11;
    if (now > bonus11end) bonusPercentage = 9;
    if (now > bonus09end) bonusPercentage = 6;
    if (now > bonus06end) bonusPercentage = 3;
    if (now > bonus03end) bonusPercentage = 0;
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
    require(now < endDate);
    require(now >= startDate);
    require(totalSupply + tokens * UNIT <= maxSupply);

    uint256 amount = tokens * UNIT;
    balances[receiver] += amount;
    totalSupply += amount;
    Transfer(address(0x0), receiver, amount);
  }

}