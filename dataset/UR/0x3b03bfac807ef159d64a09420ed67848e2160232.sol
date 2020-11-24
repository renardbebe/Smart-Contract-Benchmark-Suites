 

pragma solidity ^0.4.18;

 

 
contract ERC20Basic {
  uint256 public totalSupply;
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

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
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

 
contract HasNoEther is Ownable {

   
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) pure external {
    from_;
    value_;
    data_;
    revert();
  }

}

 
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
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
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}


 

contract AALMToken is MintableToken, NoOwner {  
    string public symbol = 'AALM';
    string public name = 'Alm Token';
    uint8 public constant decimals = 18;

    address founder;     
    function init(address _founder) onlyOwner public{
        founder = _founder;
    }

     
    modifier canTransfer() {
        require(mintingFinished || msg.sender == founder);
        _;
    }
    
    function transfer(address _to, uint256 _value) canTransfer public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

contract AALMCrowdsale is Ownable, CanReclaimToken, Destructible {
    using SafeMath for uint256;    

    uint32 private constant PERCENT_DIVIDER = 100;

    struct BulkBonus {
        uint256 minAmount;       
        uint32 bonusPercent;     
    }

    uint64 public startTimestamp;    
    uint64 public endTimestamp;      
    uint256 public minCap;           
    uint256 public hardCap;          
    uint256 public baseRate;         

    uint32 public maxTimeBonusPercent;   
    uint32 public referrerBonusPercent;  
    uint32 public referralBonusPercent;  
    BulkBonus[] public bulkBonuses;      
  

    uint256 public tokensMinted;     
    uint256 public tokensSold;       
    uint256 public collectedEther;   

    mapping(address => uint256) contributions;  

    AALMToken public token;
    TokenVesting public founderVestingContract;  

    bool public finalized;

    function AALMCrowdsale(uint64 _startTimestamp, uint64 _endTimestamp, uint256 _hardCap, uint256 _minCap, 
        uint256 _founderTokensImmediate, uint256 _founderTokensVested, uint256 _vestingDuration,
        uint256 _baseRate, uint32 _maxTimeBonusPercent, uint32 _referrerBonusPercent, uint32 _referralBonusPercent, 
        uint256[] bulkBonusMinAmounts, uint32[] bulkBonusPercents 
        ) public {
        require(_startTimestamp > now);
        require(_startTimestamp < _endTimestamp);
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;

        require(_hardCap > 0);
        hardCap = _hardCap;

        minCap = _minCap;

        initRatesAndBonuses(_baseRate, _maxTimeBonusPercent, _referrerBonusPercent, _referralBonusPercent, bulkBonusMinAmounts, bulkBonusPercents);

        token = new AALMToken();
        token.init(owner);

        require(_founderTokensImmediate.add(_founderTokensVested) < _hardCap);
        mintTokens(owner, _founderTokensImmediate);

        founderVestingContract = new TokenVesting(owner, endTimestamp, 0, _vestingDuration, false);
        mintTokens(founderVestingContract, _founderTokensVested);
    }

    function initRatesAndBonuses(
        uint256 _baseRate, uint32 _maxTimeBonusPercent, uint32 _referrerBonusPercent, uint32 _referralBonusPercent, 
        uint256[] bulkBonusMinAmounts, uint32[] bulkBonusPercents 
        ) internal {

        require(_baseRate > 0);
        baseRate = _baseRate;

        maxTimeBonusPercent = _maxTimeBonusPercent;
        referrerBonusPercent = _referrerBonusPercent;
        referralBonusPercent = _referralBonusPercent;

        uint256 prevBulkAmount = 0;
        require(bulkBonusMinAmounts.length == bulkBonusPercents.length);
        bulkBonuses.length = bulkBonusMinAmounts.length;
        for(uint8 i=0; i < bulkBonuses.length; i++){
            bulkBonuses[i] = BulkBonus({minAmount:bulkBonusMinAmounts[i], bonusPercent:bulkBonusPercents[i]});
            BulkBonus storage bb = bulkBonuses[i];
            require(prevBulkAmount < bb.minAmount);
            prevBulkAmount = bb.minAmount;
        }
    }

     
    function distributePreICOTokens(address[] beneficiaries, uint256[] amounts) onlyOwner public {
        require(beneficiaries.length == amounts.length);
        for(uint256 i=0; i<beneficiaries.length; i++){
            mintTokens(beneficiaries[i], amounts[i]);
        }
    }

     
    function () payable public {
        sale(msg.sender, msg.value, address(0));
    }
     
    function referralSale(address beneficiary, address referrer) payable public returns(bool) {
        sale(beneficiary, msg.value, referrer);
        return true;
    }
     
    function sale(address beneficiary, uint256 value, address referrer) internal {
        require(crowdsaleOpen());
        require(value > 0);
        collectedEther = collectedEther.add(value);
        contributions[beneficiary] = contributions[beneficiary].add(value);
        uint256 amount;
        if(referrer == address(0)){
            amount = getTokensWithBonuses(value, false);
        } else{
            amount = getTokensWithBonuses(value, true);
            uint256 referrerAmount  = getReferrerBonus(value);
            tokensSold = tokensSold.add(referrerAmount);
            mintTokens(referrer, referrerAmount);
        }
        tokensSold = tokensSold.add(amount);
        mintTokens(beneficiary, amount);
    }

     
    function saleNonEther(address beneficiary, uint256 amount, string  ) public onlyOwner {
        mintTokens(beneficiary, amount);
    }

     
    function crowdsaleOpen() view public returns(bool) {
        return (!finalized) && (tokensMinted < hardCap) && (startTimestamp <= now) && (now <= endTimestamp);
    }

     
    function getTokensLeft() view public returns(uint256) {
        return hardCap.sub(tokensMinted);
    }

     
    function getTokensWithBonuses(uint256 value, bool withReferralBonus) view public returns(uint256) {
        uint256 amount = value.mul(baseRate);
        amount = amount.add(getTimeBonus(value)).add(getBulkBonus(value));
        if(withReferralBonus){
            amount = amount.add(getReferralBonus(value));
        }
        return amount;
    }

     
    function getTimeBonus(uint256 value) view public returns(uint256) {
        uint256 maxBonus = value.mul(baseRate).mul(maxTimeBonusPercent).div(PERCENT_DIVIDER);
        return maxBonus.mul(endTimestamp - now).div(endTimestamp - startTimestamp);
    }

     
    function getBulkBonus(uint256 value) view public returns(uint256) {
        for(uint8 i=uint8(bulkBonuses.length); i > 0; i--){
            uint8 idx = i - 1;  
            if (value >= bulkBonuses[idx].minAmount) {
                return value.mul(baseRate).mul(bulkBonuses[idx].bonusPercent).div(PERCENT_DIVIDER);
            }
        }
        return 0;
    }

     
    function getReferrerBonus(uint256 value) view public returns(uint256) {
        return value.mul(baseRate).mul(referrerBonusPercent).div(PERCENT_DIVIDER);
    }
     
    function getReferralBonus(uint256 value) view public returns(uint256) {
        return value.mul(baseRate).mul(referralBonusPercent).div(PERCENT_DIVIDER);
    }

     
    function mintTokens(address beneficiary, uint256 amount) internal {
        tokensMinted = tokensMinted.add(amount);
        require(tokensMinted <= hardCap);
        assert(token.mint(beneficiary, amount));
    }

     
    function refund() public returns(bool){
        return refundTo(msg.sender);
    }
    function refundTo(address beneficiary) public returns(bool) {
        require(contributions[beneficiary] > 0);
        require(finalized || (now > endTimestamp));
        require(tokensSold < minCap);

        uint256 _refund = contributions[beneficiary];
        contributions[beneficiary] = 0;
        beneficiary.transfer(_refund);
        return true;
    }

     
    function finalizeCrowdsale() public onlyOwner {
        finalized = true;
        token.finishMinting();
        token.transferOwnership(owner);
        if(tokensSold >= minCap && this.balance > 0){
            owner.transfer(this.balance);
        }
    }
     
    function claimEther() public onlyOwner {
        require(tokensSold >= minCap);
        owner.transfer(this.balance);
    }

}