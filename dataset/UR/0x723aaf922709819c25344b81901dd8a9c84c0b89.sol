 

contract ESportsConstants {
    uint constant TOKEN_DECIMALS = 18;
    uint8 constant TOKEN_DECIMALS_UINT8 = uint8(TOKEN_DECIMALS);
    uint constant TOKEN_DECIMAL_MULTIPLIER = 10 ** TOKEN_DECIMALS;

    uint constant RATE = 240;  
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

     
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ESportsFreezingStorage is Ownable {
     
    uint64 public releaseTime;

     
     
    ESportsToken token;
    
    function ESportsFreezingStorage(ESportsToken _token, uint64 _releaseTime) {  
        require(_releaseTime > now);
        
        releaseTime = _releaseTime;
        token = _token;
    }

    function release(address _beneficiary) onlyOwner returns(uint) {
         
        if (now < releaseTime) return 0;

        uint amount = token.balanceOf(this);
         
        if (amount == 0)  return 0;

         
         
        bool result = token.transfer(_beneficiary, amount);
        if (!result) return 0;
        
        return amount;
    }
}

 
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State {Active, Refunding, Closed}

    mapping (address => uint256) public deposited;

    address public wallet;

    State public state;

    event Closed();

    event RefundsEnabled();

    event Refunded(address indexed beneficiary, uint256 weiAmount);

    function RefundVault(address _wallet) {
        require(_wallet != 0x0);
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) onlyOwner payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner {
        require(state == State.Active);
        state = State.Closed;
        Closed();
        wallet.transfer(this.balance);
    }

    function enableRefunds() onlyOwner {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }

    function refund(address investor, uint weiRaised) onlyOwner {
        require(state == State.Refunding);

        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        
        Refunded(investor, depositedValue);
    }
}

 
contract Crowdsale {
    using SafeMath for uint;

     
    MintableToken public token;

     
    uint32 public startTime;
    uint32 public endTime;

     
    address public wallet;

     
    uint public rate;

     
    uint public weiRaised;

     
    uint public soldTokens;

     
    uint public hardCap;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint value, uint amount);

    function Crowdsale(uint32 _startTime, uint32 _endTime, uint _rate, uint _hardCap, address _wallet, address _token) {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != 0x0);
        require(_hardCap > _rate);

         
        token = MintableToken(_token);

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        hardCap = _hardCap;
        wallet = _wallet;
    }

     
     
     
     
     

     
    function getRate() internal constant returns (uint) {
        return rate;
    }

     
    function() payable {
        buyTokens(msg.sender, msg.value);
    }

     
    function buyTokens(address beneficiary, uint amountWei) internal {
        require(beneficiary != 0x0);

         
        uint totalSupply = token.totalSupply();

         
        uint actualRate = getRate();

        require(validPurchase(amountWei, actualRate, totalSupply));

         
         
        uint tokens = amountWei.mul(actualRate);

        if (msg.value == 0) {  
            require(tokens.add(totalSupply) <= hardCap);
        }

         
        uint change = 0;

         
        if (tokens.add(totalSupply) > hardCap) {
             
            uint maxTokens = hardCap.sub(totalSupply);
            uint realAmount = maxTokens.div(actualRate);

             
            tokens = realAmount.mul(actualRate);
            change = amountWei.sub(realAmount);
            amountWei = realAmount;
        }

         
        postBuyTokens(beneficiary, tokens);

         
        weiRaised = weiRaised.add(amountWei);
        soldTokens = soldTokens.add(tokens);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, amountWei, tokens);

        if (msg.value != 0) {
            if (change != 0) {
                msg.sender.transfer(change);
            }
            forwardFunds(amountWei);
        }
    }

     
     
    function forwardFunds(uint amountWei) internal {
        wallet.transfer(amountWei);
    }

     
    function postBuyTokens(address _beneficiary, uint _tokens) internal {
    }

     
    function validPurchase(uint _amountWei, uint _actualRate, uint _totalSupply) internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = _amountWei != 0;
        bool hardCapNotReached = _totalSupply <= hardCap.sub(_actualRate);

        return withinPeriod && nonZeroPurchase && hardCapNotReached;
    }

     
    function hasEnded() public constant returns (bool) {
        return now > endTime || token.totalSupply() > hardCap.sub(getRate());
    }

     
    function hasStarted() public constant returns (bool) {
        return now >= startTime;
    }
}

 
contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    event Finalized();

    function FinalizableCrowdsale(uint32 _startTime, uint32 _endTime, uint _rate, uint _hardCap, address _wallet, address _token)
            Crowdsale(_startTime, _endTime, _rate, _hardCap, _wallet, _token) {
    }

     
    function finalize() onlyOwner {
        require(!isFinalized);
        require(hasEnded());

        isFinalized = true;

        finalization();
        Finalized();        
    }

     
    function finalization() internal {
    }
}

 
contract RefundableCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

     
    uint public goal;

     
    RefundVault public vault;

    function RefundableCrowdsale(uint32 _startTime, uint32 _endTime, uint _rate, uint _hardCap, address _wallet, address _token, uint _goal)
            FinalizableCrowdsale(_startTime, _endTime, _rate, _hardCap, _wallet, _token) {
        require(_goal > 0);
        vault = new RefundVault(wallet);
        goal = _goal;
    }

     
     
     
    function forwardFunds(uint amountWei) internal {
        if (goalReached()) {
            wallet.transfer(amountWei);
        }
        else {
            vault.deposit.value(amountWei)(msg.sender);
        }
    }

     
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender, weiRaised);
    }

     
    function finalization() internal {
        super.finalization();

        if (goalReached()) {
            vault.close();
        }
        else {
            vault.enableRefunds();
        }
    }

    function goalReached() public constant returns (bool) {
        return weiRaised >= goal;
    }
}

contract ESportsMainCrowdsale is ESportsConstants, RefundableCrowdsale {
    uint constant OVERALL_AMOUNT_TOKENS = 60000000 * TOKEN_DECIMAL_MULTIPLIER;  
    uint constant TEAM_BEN_TOKENS = 6000000 * TOKEN_DECIMAL_MULTIPLIER;  
    uint constant TEAM_PHIL_TOKENS = 6000000 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant COMPANY_COLD_STORAGE_TOKENS = 12000000 * TOKEN_DECIMAL_MULTIPLIER;  
    uint constant INVESTOR_TOKENS = 3000000 * TOKEN_DECIMAL_MULTIPLIER;  
    uint constant BONUS_TOKENS = 3000000 * TOKEN_DECIMAL_MULTIPLIER;  
	uint constant BUFFER_TOKENS = 6000000 * TOKEN_DECIMAL_MULTIPLIER;  
    uint constant PRE_SALE_TOKENS = 12000000 * TOKEN_DECIMAL_MULTIPLIER;  

     
    address constant TEAM_BEN_ADDRESS = 0x2E352Ed15C4321f4dd7EdFc19402666dE8713cd8;
    address constant TEAM_PHIL_ADDRESS = 0x4466de3a8f4f0a0f5470b50fdc9f91fa04e00e34;
    address constant INVESTOR_ADDRESS = 0x14f8d0c41097ca6fddb6aa4fd6a3332af3741847;
    address constant BONUS_ADDRESS = 0x5baee4a9938d8f59edbe4dc109119983db4b7bd6;
    address constant COMPANY_COLD_STORAGE_ADDRESS = 0x700d6ae53be946085bb91f96eb1cf9e420236762;
    address constant PRE_SALE_ADDRESS = 0xcb2809926e615245b3af4ebce5af9fbe1a6a4321;
    
    address btcBuyer = 0x1eee4c7d88aadec2ab82dd191491d1a9edf21e9a;

    ESportsBonusProvider public bonusProvider;

    bool private isInit = false;
    
	 
    function ESportsMainCrowdsale(
        uint32 _startTime,
        uint32 _endTime,
        uint _softCapWei,  
        address _wallet,
        address _token
	) RefundableCrowdsale(
        _startTime,
        _endTime, 
        RATE,
        OVERALL_AMOUNT_TOKENS,
        _wallet,
        _token,
        _softCapWei
	) {
	}

     
    function releaseBonus() returns(uint) {
        return bonusProvider.releaseBonus(msg.sender, soldTokens);
    }

     
    function postBuyTokens(address _beneficiary, uint _tokens) internal {
        uint bonuses = bonusProvider.getBonusAmount(_beneficiary, soldTokens, _tokens, startTime);
        bonusProvider.addDelayedBonus(_beneficiary, soldTokens, _tokens);

        if (bonuses > 0) {
            bonusProvider.sendBonus(_beneficiary, bonuses);
        }
    }

     
    function init() onlyOwner public returns(bool) {
        require(!isInit);

        ESportsToken ertToken = ESportsToken(token);
        isInit = true;

        ESportsBonusProvider bProvider = new ESportsBonusProvider(ertToken, COMPANY_COLD_STORAGE_ADDRESS);
         
        bonusProvider = bProvider;

        mintToFounders(ertToken);

        require(token.mint(INVESTOR_ADDRESS, INVESTOR_TOKENS));
        require(token.mint(COMPANY_COLD_STORAGE_ADDRESS, COMPANY_COLD_STORAGE_TOKENS));
        require(token.mint(PRE_SALE_ADDRESS, PRE_SALE_TOKENS));

         
        require(token.mint(BONUS_ADDRESS, BONUS_TOKENS));
        require(token.mint(bonusProvider, BUFFER_TOKENS));  
        
        ertToken.addExcluded(INVESTOR_ADDRESS);
        ertToken.addExcluded(BONUS_ADDRESS);
        ertToken.addExcluded(COMPANY_COLD_STORAGE_ADDRESS);
        ertToken.addExcluded(PRE_SALE_ADDRESS);

        ertToken.addExcluded(address(bonusProvider));

        return true;
    }

     
    function mintToFounders(ESportsToken ertToken) internal {
        ertToken.mintTimelocked(TEAM_BEN_ADDRESS, TEAM_BEN_TOKENS.mul(20).div(100), startTime + 1 years);
        ertToken.mintTimelocked(TEAM_BEN_ADDRESS, TEAM_BEN_TOKENS.mul(30).div(100), startTime + 3 years);
        ertToken.mintTimelocked(TEAM_BEN_ADDRESS, TEAM_BEN_TOKENS.mul(30).div(100), startTime + 5 years);
        require(token.mint(TEAM_BEN_ADDRESS, TEAM_BEN_TOKENS.mul(20).div(100)));

        ertToken.mintTimelocked(TEAM_PHIL_ADDRESS, TEAM_PHIL_TOKENS.mul(20).div(100), startTime + 1 years);
        ertToken.mintTimelocked(TEAM_PHIL_ADDRESS, TEAM_PHIL_TOKENS.mul(30).div(100), startTime + 3 years);
        ertToken.mintTimelocked(TEAM_PHIL_ADDRESS, TEAM_PHIL_TOKENS.mul(30).div(100), startTime + 5 years);
        require(token.mint(TEAM_PHIL_ADDRESS, TEAM_PHIL_TOKENS.mul(20).div(100)));
    }

     
    function buyForBitcoin(address _beneficiary, uint _amountWei) public returns(bool) {
        require(msg.sender == btcBuyer);

        buyTokens(_beneficiary, _amountWei);
        
        return true;
    }

     
    function setBtcBuyer(address _newBtcBuyerAddress) onlyOwner returns(bool) {
        require(_newBtcBuyerAddress != 0x0);

        btcBuyer = _newBtcBuyerAddress;

        return true;
    }

     
    function finalization() internal {
        super.finalization();
        token.finishMinting();

        bonusProvider.releaseThisBonuses();

        if (goalReached()) {
            ESportsToken(token).allowMoveTokens();
        }
        token.transferOwnership(owner);  
    }
}

contract ESportsBonusProvider is ESportsConstants, Ownable {
     
     

    using SafeMath for uint;

    ESportsToken public token;
    address public returnAddressBonuses;
    mapping (address => uint256) investorBonuses;

    uint constant FIRST_WEEK = 7 days;
    uint constant BONUS_THRESHOLD_ETR = 20000 * RATE * TOKEN_DECIMAL_MULTIPLIER;  

    function ESportsBonusProvider(ESportsToken _token, address _returnAddressBonuses) {
        token = _token;
        returnAddressBonuses = _returnAddressBonuses;
    }

    function getBonusAmount(
        address _buyer,
        uint _totalSold,
        uint _amountTokens,
        uint32 _startTime
    ) onlyOwner public constant returns (uint) {
        uint bonus = 0;
        
         
        if (now < _startTime + FIRST_WEEK && now >= _startTime) {
            bonus = bonus.add(_amountTokens.div(10));  
        }

        return bonus;
    }

    function addDelayedBonus(
        address _buyer,
        uint _totalSold,
        uint _amountTokens
    ) onlyOwner public returns (uint) {
        uint bonus = 0;

        if (_totalSold < BONUS_THRESHOLD_ETR) {
            uint amountThresholdBonus = _amountTokens.div(10);  
            investorBonuses[_buyer] = investorBonuses[_buyer].add(amountThresholdBonus); 
            bonus = bonus.add(amountThresholdBonus);
        }

        return bonus;
    }

    function releaseBonus(address _buyer, uint _totalSold) onlyOwner public returns (uint) {
        require(_totalSold >= BONUS_THRESHOLD_ETR);
        require(investorBonuses[_buyer] > 0);

        uint amountBonusTokens = investorBonuses[_buyer];
        investorBonuses[_buyer] = 0;
        require(token.transfer(_buyer, amountBonusTokens));

        return amountBonusTokens;
    }

    function getDelayedBonusAmount(address _buyer) public constant returns(uint) {
        return investorBonuses[_buyer];
    }

    function sendBonus(address _buyer, uint _amountBonusTokens) onlyOwner public {
        require(token.transfer(_buyer, _amountBonusTokens));
    }

    function releaseThisBonuses() onlyOwner public {
        uint remainBonusTokens = token.balanceOf(this);  
        require(token.transfer(returnAddressBonuses, remainBonusTokens));
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  	function allowance(address owner, address spender) constant returns (uint256);
  	function transferFrom(address from, address to, uint256 value) returns (bool);
  	function approve(address spender, uint256 value) returns (bool);
  	event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) balances;

     
    function transfer(address _to, uint256 _value) returns (bool) {
        require(_to != address(0));

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        require(_to != address(0));

        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
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

     
    function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract ESportsToken is ESportsConstants, MintableToken {
    using SafeMath for uint;

    event Burn(address indexed burner, uint value);
    event MintTimelocked(address indexed beneficiary, uint amount);

     
    bool public paused = true;
     
    mapping(address => bool) excluded;

    mapping (address => ESportsFreezingStorage[]) public frozenFunds;

    function name() constant public returns (string _name) {
        return "ESports Token";
    }

    function symbol() constant public returns (string _symbol) {
        return "ERT";
    }

    function decimals() constant public returns (uint8 _decimals) {
        return TOKEN_DECIMALS_UINT8;
    }
    
    function allowMoveTokens() onlyOwner {
        paused = false;
    }

    function addExcluded(address _toExclude) onlyOwner {
        addExcludedInternal(_toExclude);
    }
    
    function addExcludedInternal(address _toExclude) private {
        excluded[_toExclude] = true;
    }

     
    function transferFrom(address _from, address _to, uint _value) returns (bool) {
        require(!paused || excluded[_from]);

        return super.transferFrom(_from, _to, _value);
    }

     
    function transfer(address _to, uint _value) returns (bool) {
        require(!paused || excluded[msg.sender]);

        return super.transfer(_to, _value);
    }

     
    function mintTimelocked(address _to, uint _amount, uint32 _releaseTime)
            onlyOwner canMint returns (ESportsFreezingStorage) {
        ESportsFreezingStorage timelock = new ESportsFreezingStorage(this, _releaseTime);
        mint(timelock, _amount);

        frozenFunds[_to].push(timelock);
        addExcludedInternal(timelock);

        MintTimelocked(_to, _amount);

        return timelock;
    }

     
    function returnFrozenFreeFunds() public returns (uint) {
        uint total = 0;
        ESportsFreezingStorage[] storage frozenStorages = frozenFunds[msg.sender];
         
         
         
         
         
        for (uint x = 0; x < frozenStorages.length; x++) {
            uint amount = frozenStorages[x].release(msg.sender);
            total = total.add(amount);
        }
        
        return total;
    }

     
    function burn(uint _value) public {
        require(!paused || excluded[msg.sender]);
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        
        Burn(msg.sender, _value);
    }
}