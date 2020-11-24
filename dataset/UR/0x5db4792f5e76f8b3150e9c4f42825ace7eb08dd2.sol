 

pragma solidity ^0.4.18;

 

 
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

 

contract DividendContract {
  using SafeMath for uint256;
  event Dividends(uint256 round, uint256 value);
  event ClaimDividends(address investor, uint256 value);

  uint256 totalDividendsAmount = 0;
  uint256 totalDividendsRounds = 0;
  uint256 totalUnPayedDividendsAmount = 0;
  mapping(address => uint256) payedDividends;


  function getTotalDividendsAmount() public constant returns (uint256) {
    return totalDividendsAmount;
  }

  function getTotalDividendsRounds() public constant returns (uint256) {
    return totalDividendsRounds;
  }

  function getTotalUnPayedDividendsAmount() public constant returns (uint256) {
    return totalUnPayedDividendsAmount;
  }

  function dividendsAmount(address investor) public constant returns (uint256);
  function claimDividends() payable public;

  function payDividends() payable public {
    require(msg.value > 0);
    totalDividendsAmount = totalDividendsAmount.add(msg.value);
    totalUnPayedDividendsAmount = totalUnPayedDividendsAmount.add(msg.value);
    totalDividendsRounds += 1;
    Dividends(totalDividendsRounds, msg.value);
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

contract ESlotsICOToken is ERC20, DividendContract {

    string public constant name = "Ethereum Slot Machine Token";
    string public constant symbol = "EST";
    uint8 public constant decimals = 18;

    function maxTokensToSale() public view returns (uint256);
    function availableTokens() public view returns (uint256);
    function completeICO() public;
    function connectCrowdsaleContract(address crowdsaleContract) public;
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

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
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

 

 
contract ESlotsToken is Ownable, StandardToken, ESlotsICOToken {

  event Burn(address indexed burner, uint256 value);

  enum State { ActiveICO, CompletedICO }
  State public state;

  uint256 public constant INITIAL_SUPPLY = 50000000 * (10 ** uint256(decimals));

  address founders = 0x7b97B31E12f7d029769c53cB91c83d29611A4F7A;
  uint256 public constant foundersStake = 10;  
  uint256 public constant dividendRoundsBeforeFoundersStakeUnlock = 4;
  uint256 maxFoundersTokens;
  uint256 tokensToSale;

  uint256 transferGASUsage;

   
  function ESlotsToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    maxFoundersTokens = INITIAL_SUPPLY.mul(foundersStake).div(100);
    tokensToSale = INITIAL_SUPPLY - maxFoundersTokens;
    balances[msg.sender] = tokensToSale;
    Transfer(0x0, msg.sender, balances[msg.sender]);
    state = State.ActiveICO;
    transferGASUsage = 21000;
  }

  function maxTokensToSale() public view returns (uint256) {
    return tokensToSale;
  }

  function availableTokens() public view returns (uint256) {
    return balances[owner];
  }

  function setGasUsage(uint256 newGasUsage) public onlyOwner {
    transferGASUsage = newGasUsage;
  }

   
  function connectCrowdsaleContract(address crowdsaleContract) public onlyOwner {
    approve(crowdsaleContract, balances[owner]);
  }

   
  function completeICO() public onlyOwner {
    require(state == State.ActiveICO);
    state = State.CompletedICO;
    uint256 soldTokens = tokensToSale.sub(balances[owner]);
    uint256 foundersTokens = soldTokens.mul(foundersStake).div(100);
    if(foundersTokens > maxFoundersTokens) {
       
      foundersTokens = maxFoundersTokens;
    }
    BasicToken.transfer(founders, foundersTokens);
    totalSupply_ = soldTokens.add(foundersTokens);
    balances[owner] = 0;
    Burn(msg.sender, INITIAL_SUPPLY.sub(totalSupply_));
  }


   
  function transfer(address _to, uint256 _value) public returns (bool) {
    if(msg.sender == founders) {
       
      require(totalDividendsAmount > 0 && totalDividendsRounds > dividendRoundsBeforeFoundersStakeUnlock);
    }
     
    require(payedDividends[msg.sender] == totalDividendsAmount);
    require(balances[_to] == 0 || payedDividends[_to] == totalDividendsAmount);
    bool res =  BasicToken.transfer(_to, _value);
    if(res && payedDividends[_to] != totalDividendsAmount) {
      payedDividends[_to] = totalDividendsAmount;
    }
    return res;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    if(msg.sender == founders) {
       
      require(totalDividendsAmount > 0 && totalDividendsRounds > dividendRoundsBeforeFoundersStakeUnlock);
    }
     
    require(payedDividends[_from] == totalDividendsAmount);
    require(balances[_to] == 0 || payedDividends[_to] == totalDividendsAmount);
    bool res = StandardToken.transferFrom(_from, _to, _value);
    if(res && payedDividends[_to] != totalDividendsAmount) {
      payedDividends[_to] = totalDividendsAmount;
    }
    return res;
  }

   

  modifier onlyThenCompletedICO {
    require(state == State.CompletedICO);
    _;
  }

  function dividendsAmount(address investor) public onlyThenCompletedICO constant returns (uint256)  {
    if(totalSupply_ == 0) {return 0;}
    if(balances[investor] == 0) {return 0;}
    if(payedDividends[investor] >= totalDividendsAmount) {return 0;}
    return (totalDividendsAmount - payedDividends[investor]).mul(balances[investor]).div(totalSupply_);
  }

  function claimDividends() payable public onlyThenCompletedICO {
     
    sendDividends(msg.sender, 0);

  }

   
  function pushDividends(address investor) payable public onlyThenCompletedICO {
     
    sendDividends(investor, transferGASUsage.mul(tx.gasprice));
  }

  function sendDividends(address investor, uint256 gasUsage) internal {
    uint256 value = dividendsAmount(investor);
    require(value > gasUsage);
    payedDividends[investor] = totalDividendsAmount;
    totalUnPayedDividendsAmount = totalUnPayedDividendsAmount.sub(value);
    investor.transfer(value.sub(gasUsage));
    ClaimDividends(investor, value);
  }

  function payDividends() payable public onlyThenCompletedICO {
    DividendContract.payDividends();
  }
}