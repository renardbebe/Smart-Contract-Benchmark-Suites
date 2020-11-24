 

pragma solidity ^0.4.11;


 
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


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Haltable is Ownable {
  bool public halted = false;

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier stopNonOwnersInEmergency {
    require((msg.sender==owner) || !halted);
    _;
  }

  modifier onlyInEmergency {
    require(halted);
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

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


contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TakeProfitToken is Token, Haltable {
    using SafeMath for uint256;


    string constant public name = "TakeProfit";
    uint8 constant public decimals = 8;
    string constant public symbol = "XTP";       
    string constant public version = "1.1";


    uint256 constant public UNIT = uint256(10)**decimals;
    uint256 public totalSupply = 10**8 * UNIT;

    uint256 constant MAX_UINT256 = 2**256 - 1;  

    function TakeProfitToken() public {
        balances[owner] = totalSupply;
    }


    function transfer(address _to, uint256 _value) public stopInEmergency returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public stopInEmergency returns (bool success) {
        require(_to != address(0));
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] = allowance.sub(_value);
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public stopInEmergency returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


 
contract Presale is Haltable {
  using SafeMath for uint256;

   
  Token public token;

   
  uint256 constant public startTime = 1511892000;  
  uint256 constant public endTime =   1513641600;  

  uint256 constant public tokenCap = uint256(8*1e6*1e8);

   
  address public withdrawAddress;

   
  uint256 public default_rate = 2500000;

   
  uint256 public weiRaised;

   
  uint256 public tokenSold;

  bool public initiated = false;
  bool public finalized = false;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  mapping (address => uint256) purchasedTokens;
  mapping (address => uint256) receivedFunds;

  enum State{Unknown, Prepairing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

  function Presale(address token_address, address _withdrawAddress) public {
    require(startTime >= now);
    require(endTime >= startTime);
    require(default_rate > 0);
    require(withdrawAddress == address(0));
    require(_withdrawAddress != address(0));
    require(tokenCap>0);
    token = Token(token_address);
    require(token.totalSupply()==100*uint256(10)**(6+8));
    withdrawAddress = _withdrawAddress;
  }

  function initiate() public onlyOwner {
    require(token.balanceOf(this) >= tokenCap);
    initiated = true;
    if(token.balanceOf(this)>tokenCap)
      require(token.transfer(withdrawAddress, token.balanceOf(this).sub(tokenCap)));
  }

   
  function () public stopInEmergency payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public stopInEmergency inState(State.Funding) payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 weiAmountConsumed = 0;
    uint256 weiExcess = 0;

     
    uint256 tokens = weiAmount.div(rate());
    if(tokenSold.add(tokens)>tokenCap) {
      tokens = tokenCap.sub(tokenSold);
    }

    weiAmountConsumed = tokens.mul(rate());
    weiExcess = weiAmount.sub(weiAmountConsumed);


     
    weiRaised = weiRaised.add(weiAmountConsumed);
    tokenSold = tokenSold.add(tokens);

    purchasedTokens[beneficiary] += tokens;
    receivedFunds[msg.sender] += weiAmountConsumed;
    if(weiExcess>0) {
      msg.sender.transfer(weiExcess);
    }
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool valuablePurchase = (msg.value >= 0.1 ether);
    return valuablePurchase;
  }

  function getPurchasedTokens(address beneficiary) public constant returns (uint256) {
    return purchasedTokens[beneficiary];
  }

  function getReceivedFunds(address buyer) public constant returns (uint256) {
    return receivedFunds[buyer];
  }

  function claim() public stopInEmergency inState(State.Finalized) {
    claimTokens(msg.sender);
  }


  function claimTokens(address beneficiary) public stopInEmergency inState(State.Finalized) {
    require(purchasedTokens[beneficiary]>0);
    uint256 value = purchasedTokens[beneficiary];
    purchasedTokens[beneficiary] -= value;
    require(token.transfer(beneficiary, value));
  }

  function refund() public stopInEmergency inState(State.Refunding) {
    delegatedRefund(msg.sender);
  }

  function delegatedRefund(address beneficiary) public stopInEmergency inState(State.Refunding) {
    require(receivedFunds[beneficiary]>0);
    uint256 value = receivedFunds[beneficiary];
    receivedFunds[beneficiary] = 0;
    beneficiary.transfer(value);
  }

  function finalize() public inState(State.Success) onlyOwner stopInEmergency {
    require(!finalized);
    require(this.balance==0);
    finalized = true;
  }

  function withdraw() public  inState(State.Success) onlyOwner stopInEmergency {
    withdrawAddress.transfer(weiRaised);
  }

  function manualWithdrawal(uint256 _amount) public  inState(State.Success) onlyOwner stopInEmergency {
    withdrawAddress.transfer(_amount);
  }

  function emergencyWithdrawal(uint256 _amount) public onlyOwner onlyInEmergency {
    withdrawAddress.transfer(_amount);
  }

  function emergencyTokenWithdrawal(uint256 _amount) public onlyOwner onlyInEmergency {
    require(token.transfer(withdrawAddress, _amount));
  }

  function rate() public constant returns (uint256) {
    if (block.timestamp < startTime) return 0;
    else if (block.timestamp >= startTime && block.timestamp < (startTime + 1 weeks)) return uint256(default_rate/2);
    else if (block.timestamp >= (startTime+1 weeks) && block.timestamp < (startTime + 2 weeks)) return uint256(10*default_rate/19);
    else if (block.timestamp >= (startTime+2 weeks) && block.timestamp < (startTime + 3 weeks)) return uint256(10*default_rate/18);
    return 0;
  }

   
  function getState() public constant returns (State) {
    if(finalized) return State.Finalized;
    if(!initiated) return State.Prepairing;
    else if (block.timestamp < startTime) return State.PreFunding;
    else if (block.timestamp <= endTime && tokenSold<tokenCap) return State.Funding;
    else if (tokenSold>=tokenCap) return State.Success;
    else if (weiRaised > 0 && block.timestamp >= endTime && tokenSold<tokenCap) return State.Refunding;
    else return State.Failure;
  }

  modifier inState(State state) {
    require(getState() == state);
    _;
  }
}