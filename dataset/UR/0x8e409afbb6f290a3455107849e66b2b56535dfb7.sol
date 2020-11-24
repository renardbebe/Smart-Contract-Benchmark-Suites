 

pragma solidity ^ 0.4.21;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract ERC20Basic {
    function totalSupply() public view returns(uint256);
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns(uint256);
    function transferFrom(address from, address to, uint256 value) public returns(bool);
    function approve(address spender, uint256 value) public returns(bool);
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
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value != 0) && (allowed[msg.sender][_spender] != 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract Claimable is Ownable {
    address public pendingOwner;

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() onlyPendingOwner public {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

 
contract MintableToken is StandardToken, Claimable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        return _mint(_to, _amount);
    }

    function _mint(address _to, uint256 _amount) internal canMint returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

     
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

 
contract Pausable is Claimable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

 
contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }
}

 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
         
         

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

 
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    )
        internal
    {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

 
contract TokenTimelock {
    using SafeERC20 for ERC20Basic;

     
    ERC20Basic public token;

     
    address public beneficiary;

     
    uint256 public releaseTime;

    function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
         
        require(_releaseTime > block.timestamp);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    function canRelease() public view returns (bool){
        return block.timestamp >= releaseTime;
    }

     
    function release() public {
         
        require(canRelease());

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }
}

 
contract Crowdsale{
    using SafeMath for uint256;

    enum TokenLockType { TYPE_NOT_LOCK, TYPE_SEED_INVESTOR, TYPE_PRE_SALE, TYPE_TEAM}
    uint256 internal constant UINT256_MAX = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint8 internal constant SEED_INVESTOR_BONUS_RATE = 50;
    uint256 internal constant MAX_SALECOUNT_PER_ADDRESS = 30;

     
    address public wallet;

     
    uint256 public rate = 5000;

     
    uint256 public weiRaised;

    Phase[] internal phases;

    struct Phase {
        uint256 till;
        uint256 bonusRate;
    }

    uint256 public currentPhase = 0;
    mapping (address => uint256 ) public saleCount;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
     
    function Crowdsale(address _wallet) public {
        require(_wallet != address(0));

        phases.push(Phase({ till: 1527782400, bonusRate: 30 }));  
        phases.push(Phase({ till: 1531238400, bonusRate: 20 }));  
        phases.push(Phase({ till: 1533916800, bonusRate: 10 }));  
        phases.push(Phase({ till: UINT256_MAX, bonusRate: 0 }));  

        wallet = _wallet;
    }

     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        uint256 nowTime = block.timestamp;
         
        while (currentPhase < phases.length && phases[currentPhase].till < nowTime) {
            currentPhase = currentPhase.add(1);
        }

         
        if (currentPhase == 0) {
            require(weiAmount >= 1 ether);
        }

         
        uint256 tokens = _getTokenAmount(weiAmount);
         
        TokenLockType lockType = _getTokenLockType(weiAmount);

        if (lockType != TokenLockType.TYPE_NOT_LOCK) {
            require(saleCount[_beneficiary].add(1) <= MAX_SALECOUNT_PER_ADDRESS);
            saleCount[_beneficiary] = saleCount[_beneficiary].add(1);
        }

         
        weiRaised = weiRaised.add(weiAmount);

        _deliverTokens(_beneficiary, tokens, lockType);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );

        _forwardFunds();
    }

     
     
     

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(currentPhase < phases.length);
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount, TokenLockType lockType) internal {

    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 tokens = _weiAmount.mul(rate);
        uint256 bonusRate = 0;
        if (_weiAmount >= 1000 ether) {
            bonusRate = SEED_INVESTOR_BONUS_RATE;
        } else {
            bonusRate = phases[currentPhase].bonusRate;
        }
        uint256 bonus = tokens.mul(bonusRate).div(uint256(100));        
        return tokens.add(bonus);
    }

     
    function _getTokenLockType(uint256 _weiAmount) internal view returns (TokenLockType) {
        TokenLockType lockType = TokenLockType.TYPE_NOT_LOCK;
        if (_weiAmount >= 1000 ether) {
            lockType = TokenLockType.TYPE_SEED_INVESTOR;
        } else if (currentPhase == 0 ) {
            lockType = TokenLockType.TYPE_PRE_SALE;
        }
        return lockType;
    }

     
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}

contract StopableCrowdsale is Crowdsale, Claimable{

    bool public crowdsaleStopped = false;
     
    modifier onlyNotStopped {
         
        require(!crowdsaleStopped);
        _;
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view onlyNotStopped {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    function stopCrowdsale() public onlyOwner {
        require(!crowdsaleStopped);
        crowdsaleStopped = true;
    }

    function startCrowdsale() public onlyOwner {
        require(crowdsaleStopped);
        crowdsaleStopped = false;
    }
}


 
contract ISCoin is PausableToken, MintableToken, BurnableToken, StopableCrowdsale {
    using SafeMath for uint256;

    string public name = "Imperial Star Coin";
    string public symbol = "ISC";
    uint8 public decimals = 18;

    mapping (address => address[] ) public balancesLocked;

    function ISCoin(address _wallet) public Crowdsale(_wallet) {}


    function setRate(uint256 _rate) public onlyOwner onlyNotStopped {
        require(_rate > 0);
        rate = _rate;
    }

    function setWallet(address _wallet) public onlyOwner onlyNotStopped {
        require(_wallet != address(0));
        wallet = _wallet;
    }    

     
    function mintTimelocked(address _to, uint256 _amount, uint256 _releaseTime) 
    public onlyOwner canMint returns (TokenTimelock) {
        return _mintTimelocked(_to, _amount, _releaseTime);
    }

     
    function balanceOfLocked(address _owner) public view returns (uint256) {
        address[] memory timelockAddrs = balancesLocked[_owner];

        uint256 totalLockedBalance = 0;
        for (uint i = 0; i < timelockAddrs.length; i++) {
            totalLockedBalance = totalLockedBalance.add(balances[timelockAddrs[i]]);
        }
        
        return totalLockedBalance;
    }

    function releaseToken(address _owner) public {
        address[] memory timelockAddrs = balancesLocked[_owner];
        for (uint i = 0; i < timelockAddrs.length; i++) {
            TokenTimelock timelock = TokenTimelock(timelockAddrs[i]);
            if (timelock.canRelease() && balances[timelock] > 0) {
                timelock.release();
            }
        }
    }

     
    function _mintTimelocked(address _to, uint256 _amount, uint256 _releaseTime)
    internal canMint returns (TokenTimelock) {
        TokenTimelock timelock = new TokenTimelock(this, _to, _releaseTime);
        balancesLocked[_to].push(timelock);
        _mint(timelock, _amount);
        return timelock;
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount, TokenLockType lockType) internal {
        if (lockType == TokenLockType.TYPE_NOT_LOCK) {
            _mint(_beneficiary, _tokenAmount);
        } else if (lockType == TokenLockType.TYPE_SEED_INVESTOR) {
             
            _mintTimelocked(_beneficiary, _tokenAmount, now + 6 * 30 days);
        } else if (lockType == TokenLockType.TYPE_PRE_SALE) {
             
            uint256 amount1 = _tokenAmount.mul(30).div(100);     
            uint256 amount2 = _tokenAmount.mul(30).div(100);     
            uint256 amount3 = _tokenAmount.sub(amount1).sub(amount2);    
            uint256 releaseTime1 = now + 2 * 30 days;
            uint256 releaseTime2 = now + 4 * 30 days;
            uint256 releaseTime3 = now + 6 * 30 days;
            _mintTimelocked(_beneficiary, amount1, releaseTime1);
            _mintTimelocked(_beneficiary, amount2, releaseTime2);
            _mintTimelocked(_beneficiary, amount3, releaseTime3);
        }
    }
}