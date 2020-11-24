 

pragma solidity ^0.4.15;

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
  
  function getOwner() view public returns (address){
    return owner;
  }
  

}



contract BitLoanex is Ownable {

  using SafeMath for uint256;
  
  string public constant name = "Bitloanex";
  string public constant symbol = "BTLX";
  uint8 public constant decimals = 8;

  uint256 public rate;
  uint256 public constant CAP = 126000;
  uint256 public constant START = 1514160000;
  uint256 public DAYS = 30;
  uint256 public days_interval = 4;
  uint[9] public deadlines = [START, START.add(1* days_interval * 1 days), START.add(2* days_interval * 1 days), START.add(3* days_interval * 1 days), START.add(4* days_interval * 1 days), START.add(5* days_interval * 1 days), START.add(6* days_interval * 1 days), START.add(7* days_interval * 1 days), START.add(8* days_interval * 1 days)  ];
  uint[9] public rates = [2000 ,1900, 1800, 1700, 1600, 1500, 1400, 1300, 1200];
  bool public initialized = true;
  uint256 public raisedAmount = 0;
  uint256 public constant INITIAL_SUPPLY = 10000000000000000;
  uint256 public totalSupply;
  address[] public investors;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event BoughtTokens(address indexed to, uint256 value);
  
  function BitLoanex() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
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

  modifier whenSaleActive() {
  assert(isActive());
  _;
  }



  function initialize(bool _val) public onlyOwner {
      
    initialized = _val;

  }


  function isActive() public constant returns (bool) {
    return(
      initialized == true &&
      now >= START &&
      now <= START.add(DAYS * 1 days) &&
      goalReached() == false
    );
  }

  function goalReached() private constant returns (bool) {
    return (raisedAmount >= CAP * 1 ether);
  }

  function () public payable {

    buyTokens();

  }

  function buyTokens() public payable {
      
    require(initialized && now <= START.add(DAYS * 1 days));
    
    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(getRate());
    
    tokens = tokens.div(1 ether);
    
    BoughtTokens(msg.sender, tokens);

    balances[msg.sender] = balances[msg.sender].add(tokens);
    balances[owner] = balances[owner].sub(tokens);
    totalSupply.sub(tokens);

    raisedAmount = raisedAmount.add(msg.value);
    
    investors.push(msg.sender) -1;
     
  }
  
  function getInvestors() view public returns (address[])
  {
      return investors;
  }

  function tokenAvailable() public constant returns (uint256){
     return totalSupply;
  }
  
  function setRate(uint256 _rate) public onlyOwner
  {
      rate = _rate;
  }
  
  function setDays(uint256 _day) public onlyOwner
  {
      DAYS = _day;
  }

  function getRate() public constant returns (uint256){
      
      if(rate > 0) return rate;
      
      for(var i = 0; i < deadlines.length; i++)
          if(now<deadlines[i])
              return rates[i];
      return rates[rates.length-1]; 
  }
  
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }


}