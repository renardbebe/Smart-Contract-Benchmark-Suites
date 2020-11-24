 

pragma solidity ^0.4.15;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
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

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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


   
  function Ownable() {
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

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }


}

 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}

 
contract MyFinalizableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;
   
  address public tokenWallet;

  event FinalTokens(uint256 _generated);

  function MyFinalizableCrowdsale(address _tokenWallet) {
    tokenWallet = _tokenWallet;
  }

  function generateFinalTokens(uint256 ratio) internal {
    uint256 finalValue = token.totalSupply();
    finalValue = finalValue.mul(ratio).div(1000);

    token.mint(tokenWallet, finalValue);
    FinalTokens(finalValue);
  }

}

 
contract MultiCappedCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  uint256 public softCap;
  uint256 public hardCap = 0;
  bytes32 public hardCapHash;
  uint256 public hardCapTime = 0;
  uint256 public endBuffer;
  event NotFinalized(bytes32 _a, bytes32 _b);

  function MultiCappedCrowdsale(uint256 _softCap, bytes32 _hardCapHash, uint256 _endBuffer) {
    require(_softCap > 0);
    softCap = _softCap;
    hardCapHash = _hardCapHash;
    endBuffer = _endBuffer;
  }

   
   
   
  
   
   
  function validPurchase() internal constant returns (bool) {
    if (hardCap > 0) {
      checkHardCap(weiRaised.add(msg.value));
    }
    return super.validPurchase();
  }

   
   
   

  function hashHardCap(uint256 _hardCap, uint256 _key) internal constant returns (bytes32) {
    return keccak256(_hardCap, _key);
  }

  function setHardCap(uint256 _hardCap, uint256 _key) external onlyOwner {
    require(hardCap==0);
    if (hardCapHash != hashHardCap(_hardCap, _key)) {
      NotFinalized(hashHardCap(_hardCap, _key), hardCapHash);
      return;
    }
    hardCap = _hardCap;
    checkHardCap(weiRaised);
  }



  function checkHardCap(uint256 totalRaised) internal {
    if (hardCapTime == 0 && totalRaised > hardCap) {
      hardCapTime = block.timestamp;
      endTime = block.timestamp+endBuffer;
    }
  }

}

 

contract LimitedTransferToken is ERC20 {

   
  modifier canTransfer(address _sender, uint256 _value) {
   require(_value <= transferableTokens(_sender, uint64(now)));
   _;
  }

   
  function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) public returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
  function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
    return balanceOf(holder);
  }
}

 
contract FypToken is MintableToken, LimitedTransferToken {

  string public constant name = "Flyp.me Token";
  string public constant symbol = "FYP";
  uint8 public constant decimals = 18;
  bool public isTransferable = false;

  function enableTransfers() onlyOwner {
     isTransferable = true;
  }

  function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
    if (!isTransferable) {
        return 0;
    }
    return super.transferableTokens(holder, time);
  }

  function finishMinting() onlyOwner public returns (bool) {
     enableTransfers();
     return super.finishMinting();
  }

}

 
contract FlypCrowdsale is MyFinalizableCrowdsale, MultiCappedCrowdsale {

   
  uint256 public presaleRate;
  uint256 public postSoftRate;
  uint256 public postHardRate;
  uint256 public presaleEndTime;

  function FlypCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _presaleEndTime, uint256 _rate, uint256 _rateDiff, uint256 _softCap, address _wallet, bytes32 _hardCapHash, address _tokenWallet, uint256 _endBuffer)
   MultiCappedCrowdsale(_softCap, _hardCapHash, _endBuffer)
   MyFinalizableCrowdsale(_tokenWallet)
   Crowdsale(_startTime, _endTime, _rate, _wallet)
  {
    presaleRate = _rate+_rateDiff;
    postSoftRate = _rate-_rateDiff;
    postHardRate = _rate-(2*_rateDiff);
    presaleEndTime = _presaleEndTime;
  }

   
  function pregenTokens(address beneficiary, uint256 weiAmount, uint256 tokenAmount) external onlyOwner {
    require(beneficiary != 0x0);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokenAmount);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    uint256 currentRate = rate;
    if (block.timestamp < presaleEndTime) {
        currentRate = presaleRate;
    }
    else if (hardCap > 0 && weiRaised > hardCap) {
        currentRate = postHardRate;
    }
    else if (weiRaised > softCap) {
        currentRate = postSoftRate;
    }
     
    uint256 tokens = weiAmount.mul(currentRate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
  function createTokenContract() internal returns (MintableToken) {
    return new FypToken();
  }

   
  function finalization() internal {
    if (weiRaised < softCap) {
      generateFinalTokens(1000);
    } else if (weiRaised < hardCap) {
      generateFinalTokens(666);
    } else {
      generateFinalTokens(428);
    }
    token.finishMinting();
    super.finalization();
  }

   
  function withdraw(uint256 weiValue) onlyOwner {
    wallet.transfer(weiValue);
  }

}