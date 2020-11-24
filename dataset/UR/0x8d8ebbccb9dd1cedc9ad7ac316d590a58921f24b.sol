 

pragma solidity ^0.4.15;

 

 
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

 

contract GRAD {
    using SafeMath for uint256;

    string public name = "Gadus";

    string public symbol = "GRAD";

    uint public decimals = 18;

    uint256 public totalSupply;

    address owner;

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);

    event Mint (address indexed to, uint256  amount);

    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function GRAD() public{
        owner = msg.sender;
    }

      

    function mint(address _to, uint256 _value) onlyOwner public returns (bool){
        balances[_to] = balances[_to].add(_value);
        totalSupply = totalSupply.add(_value);
        Mint(_to, _value);
        return true;
    }

     
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 

 
contract Sale is Ownable{
  using SafeMath for uint256;

   
  GRAD public token;

   
  uint256 public startBlock;
  uint256 public endBlock;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

  bool private isSaleActive;
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Sale(uint256 _startBlock, uint256 _rate, address _wallet) public {
    require(_startBlock >= block.number);
    require(_rate > 0);
    require(_wallet != 0x0);

    owner = msg.sender;
    token = createTokenContract();
    startBlock = _startBlock;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (GRAD) {
    return new GRAD();
  }


   
  function () payable public {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable public {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

    uint256 bonus = calclulateBonus(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens.add(bonus));
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens.add(bonus));

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function calclulateBonus(uint256 _weiAmount) internal pure returns (uint256) {
    uint256 weiAmount = _weiAmount;
     
     
     
    if (weiAmount >= 1e18 * 10) {
      return (weiAmount.mul(7)).div(100);
    } else if (weiAmount >= 1e18 * 5) {
      return (weiAmount.mul(5)).div(100);
    } else if (weiAmount >= 1e17 * 25) {
      return (weiAmount.mul(3)).div(100);
    } else {
      return 0;
    }

  }

   
  function validPurchase() internal constant returns (bool) {
    uint256 current = block.number;
    bool withinPeriod = current >= startBlock;
    bool withinSaleRunning = isSaleActive;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase && withinSaleRunning;
  }


   
  function disableSale() onlyOwner() public returns (bool) {
    require(isSaleActive == true);
    isSaleActive = false;
    return true;
  }

   
  function enableSale()  onlyOwner() public returns (bool) {
    require(isSaleActive == false);
    isSaleActive = true;
    return true;
  }

   
  function saleStatus() public constant returns (bool){
    return isSaleActive;
  }

}