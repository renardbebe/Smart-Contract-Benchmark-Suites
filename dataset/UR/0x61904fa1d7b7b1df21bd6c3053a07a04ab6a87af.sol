 

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


 

contract BurnableToken is StandardToken {
    using SafeMath for uint256;

    event Burn(address indexed from, uint256 amount);
    event BurnRewardIncreased(address indexed from, uint256 value);

     
    function() public payable {
        if(msg.value > 0){
            BurnRewardIncreased(msg.sender, msg.value);    
        }
    }

     
    function burnReward(uint256 _amount) public constant returns(uint256){
        return this.balance.mul(_amount).div(totalSupply);
    }

     
    function burn(address _from, uint256 _amount) internal returns(bool){
        require(balances[_from] >= _amount);
        
        uint256 reward = burnReward(_amount);
        assert(this.balance - reward > 0);

        balances[_from] = balances[_from].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
         
        
        _from.transfer(reward);
        Burn(_from, _amount);
        Transfer(_from, address(0), _amount);
        return true;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if( (_to == address(this)) || (_to == 0) ){
            return burn(msg.sender, _value);
        }else{
            return super.transfer(_to, _value);
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if( (_to == address(this)) || (_to == 0) ){
            var _allowance = allowed[_from][msg.sender];
             
            allowed[_from][msg.sender] = _allowance.sub(_value);
            return burn(_from, _value);
        }else{
            return super.transferFrom(_from, _to, _value);
        }
    }

}
contract DNTXToken is BurnableToken, MintableToken, HasNoContracts, HasNoTokens {
    string public symbol = 'DNTX';
    string public name = 'Dentix';
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
        return BurnableToken.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool) {
        return BurnableToken.transferFrom(_from, _to, _value);
    }
}

contract DNTXCrowdsale is Ownable, Destructible {
    using SafeMath for uint256;
    
    uint8 private constant PERCENT_DIVIDER = 100;              

    event SpecialMint(address beneficiary, uint256 amount, string description);

    enum State { NotStarted, PreICO, ICO, Finished }
    State public state;          

    struct ICOBonus {
        uint32 expire;        
        uint8 percent;
    }
    ICOBonus[] public icoBonuses;     

    uint256 public baseRate;            
    uint8   public preICOBonusPercent;  
    uint32  public icoStartTimestamp;   
    uint32  public icoEndTimestamp;     
    uint256 public icoGoal;             
    uint256 public hardCap;             

    DNTXToken public token;                                 

    uint256 public icoCollected;
    uint256 public totalCollected;
    mapping(address => uint256) public icoContributions;  

    function DNTXCrowdsale() public{
        state = State.NotStarted;
        token = new DNTXToken();
        token.init(owner);
    }   

    function() public payable {
        require(msg.value > 0);
        require(isOpen());

        totalCollected = totalCollected.add(msg.value);
        if(state == State.ICO){
            require(totalCollected <= hardCap);
            icoCollected = icoCollected.add(msg.value);
            icoContributions[msg.sender] = icoContributions[msg.sender].add(msg.value);
        }

        uint256 rate = currentRate();
        assert(rate > 0);

        uint256 amount = rate.mul(msg.value);
        assert(token.mint(msg.sender, amount));
    }

    function mintTokens(address beneficiary, uint256 amount, string description) onlyOwner public {
        assert(token.mint(beneficiary, amount));
        SpecialMint(beneficiary, amount, description);
    }


    function isOpen() view public returns(bool){
        if(baseRate == 0) return false;
        if(state == State.NotStarted || state == State.Finished) return false;
        if(state == State.PreICO) return true;
        if(state == State.ICO){
            if(totalCollected >= hardCap) return false;
            return (icoStartTimestamp <= now) && (now <= icoEndTimestamp);
        }
    }
    function currentRate() view public returns(uint256){
        if(state == State.PreICO) {
            return baseRate.add( baseRate.mul(preICOBonusPercent).div(PERCENT_DIVIDER) );
        }else if(state == State.ICO){
            for(uint8 i=0; i < icoBonuses.length; i++){
                ICOBonus storage b = icoBonuses[i];
                if(now <= b.expire){
                    return baseRate.add( baseRate.mul(b.percent).div(PERCENT_DIVIDER) );
                }
            }
            return baseRate;
        }else{
            return 0;
        }
    }

    function setBaseRate(uint256 rate) onlyOwner public {
        require(state != State.ICO && state != State.Finished);
        baseRate = rate;
    }
    function setPreICOBonus(uint8 percent) onlyOwner public {
        preICOBonusPercent = percent;
    }
    function setupAndStartPreICO(uint256 rate, uint8 percent) onlyOwner external {
        setBaseRate(rate);
        setPreICOBonus(percent);
        startPreICO();
    }

    function setupICO(uint32 startTimestamp, uint32 endTimestamp, uint256 goal, uint256 cap, uint32[] expires, uint8[] percents) onlyOwner external {
        require(state != State.ICO && state != State.Finished);
        icoStartTimestamp = startTimestamp;
        icoEndTimestamp = endTimestamp;
        icoGoal = goal;
        hardCap = cap;

        require(expires.length == percents.length);
        uint32 prevExpire;
        for(uint8 i=0;  i < expires.length; i++){
            require(prevExpire < expires[i]);
            icoBonuses.push(ICOBonus({expire:expires[i], percent:percents[i]}));
            prevExpire = expires[i];
        }
    }

     
    function startPreICO() onlyOwner public {
        require(state == State.NotStarted);
        require(baseRate != 0);
        state = State.PreICO;
    }
     
    function finishPreICO() onlyOwner external {
        require(state == State.PreICO);
        require(icoStartTimestamp != 0 && icoEndTimestamp != 0);
        state = State.ICO;
    }
     
    function finalizeCrowdsale() onlyOwner external {
        state = State.Finished;
        token.finishMinting();
        token.transferOwnership(owner);
        if(icoCollected >= icoGoal && this.balance > 0) {
            claimEther();
        }
    }
     
    function claimEther() onlyOwner public {
        require(state == State.PreICO || icoCollected >= icoGoal);
        require(this.balance > 0);
        owner.transfer(this.balance);
    }

     
    function refund() public returns(bool){
        return refundTo(msg.sender);
    }
    function refundTo(address beneficiary) public returns(bool) {
        require(icoCollected < icoGoal);
        require(icoContributions[beneficiary] > 0);
        require( (state == State.Finished) || (state == State.ICO && (now > icoEndTimestamp)) );

        uint256 _refund = icoContributions[beneficiary];
        icoContributions[beneficiary] = 0;
        beneficiary.transfer(_refund);
        return true;
    }

}