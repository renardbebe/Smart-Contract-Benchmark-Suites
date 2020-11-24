 

pragma solidity ^0.4.18;
 
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

contract usingEthereumV2Erc20Consts {
    uint constant TOKEN_DECIMALS = 18;
    uint8 constant TOKEN_DECIMALS_UINT8 = 18;
    uint constant TOKEN_DECIMAL_MULTIPLIER = 10 ** TOKEN_DECIMALS;

    uint constant TEAM_TOKENS =   0 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant BOUNTY_TOKENS = 0 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant PREICO_TOKENS = 0 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant MINIMAL_PURCHASE = 0.00001 ether;

    address constant TEAM_ADDRESS = 0x78cd8f794686ee8f6644447e961ef52776edf0cb;
    address constant BOUNTY_ADDRESS = 0xff823588500d3ecd7777a1cfa198958df4deea11;
    address constant PREICO_ADDRESS = 0xff823588500d3ecd7777a1cfa198958df4deea11;
    address constant COLD_WALLET = 0x439415b03708bde585856b46666f34b65af6a5c3;

    string constant TOKEN_NAME = "Ethereum V2 Erc20";
    bytes32 constant TOKEN_SYMBOL = "ETH20";
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

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

contract EthereumV2Erc20 is usingEthereumV2Erc20Consts, MintableToken, BurnableToken {
     
    bool public paused = false;
     
    mapping(address => bool) excluded;

    function name() constant public returns (string _name) {
        return TOKEN_NAME;
    }

    function symbol() constant public returns (bytes32 _symbol) {
        return TOKEN_SYMBOL;
    }

    function decimals() constant public returns (uint8 _decimals) {
        return TOKEN_DECIMALS_UINT8;
    }

    function crowdsaleFinished() onlyOwner {
        paused = false;
        finishMinting();
    }

    function addExcluded(address _toExclude) onlyOwner {
        excluded[_toExclude] = true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        require(!paused || excluded[_from]);
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) returns (bool) {
        require(!paused || excluded[msg.sender]);
        return super.transfer(_to, _value);
    }

     
    function burnFrom(address _from, uint256 _value) returns (bool) {
        require(_value > 0);
        var allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        allowed[_from][msg.sender] = allowance.sub(_value);
        Burn(_from, _value);
        return true;
    }
}
contract EthereumV2Erc20RateProviderI {
     
    function getRate(address buyer, uint totalSold, uint amountWei) public constant returns (uint);

     
    function getRateScale() public constant returns (uint);

     
    function getBaseRate() public constant returns (uint);
}

contract EthereumV2Erc20RateProvider is usingEthereumV2Erc20Consts, EthereumV2Erc20RateProviderI, Ownable {
     
    uint constant RATE_SCALE = 1;
     
     
    
     
     
     
    
    uint constant STEP_9 =         50000 * TOKEN_DECIMAL_MULTIPLIER;            
    uint constant STEP_8 =        150000 * TOKEN_DECIMAL_MULTIPLIER;          
    uint constant STEP_7 =       1150000 * TOKEN_DECIMAL_MULTIPLIER;          
    uint constant STEP_6 =      11150000 * TOKEN_DECIMAL_MULTIPLIER;         
    uint constant STEP_5 =     111150000 * TOKEN_DECIMAL_MULTIPLIER;        
    uint constant STEP_4 =    1111150000 * TOKEN_DECIMAL_MULTIPLIER;       
    uint constant STEP_3 =   11111150000 * TOKEN_DECIMAL_MULTIPLIER;      
    uint constant STEP_2 =  111111150000 * TOKEN_DECIMAL_MULTIPLIER;     
    uint constant STEP_1 = 2000000000000 * TOKEN_DECIMAL_MULTIPLIER;    
    
    uint constant RATE_9 =   100000 * RATE_SCALE;  
    uint constant RATE_8 =    99000 * RATE_SCALE;  
    uint constant RATE_7 =    90000 * RATE_SCALE;  
    uint constant RATE_6 =    50000 * RATE_SCALE;  
    uint constant RATE_5 =    10000 * RATE_SCALE;  
    uint constant RATE_4 =    1000 * RATE_SCALE;  
    uint constant RATE_3 =    100 * RATE_SCALE;  
    uint constant RATE_2 =    10 * RATE_SCALE;  
    uint constant RATE_1 =    1 * RATE_SCALE;  
    
    
    uint constant BASE_RATE = 0 * RATE_SCALE;                                              

    struct ExclusiveRate {
         
        uint32 workUntil;
         
        uint rate;
         
        uint16 bonusPercent1000;
         
        bool exists;
    }

    mapping(address => ExclusiveRate) exclusiveRate;

    function getRateScale() public constant returns (uint) {
        return RATE_SCALE;
    }

    function getBaseRate() public constant returns (uint) {
        return BASE_RATE;
    }
    

    function getRate(address buyer, uint totalSold, uint amountWei) public constant returns (uint) {
        uint rate;
         
        if (totalSold < STEP_9) {
            rate = RATE_9;
        }
        else if (totalSold < STEP_8) {
            rate = RATE_8;
        }
        else if (totalSold < STEP_7) {
            rate = RATE_7;
        }
        else if (totalSold < STEP_6) {
            rate = RATE_6;
        }
        else if (totalSold < STEP_5) {
            rate = RATE_5;
        }
        else if (totalSold < STEP_4) {
            rate = RATE_4;
        }
        else if (totalSold < STEP_3) {
            rate = RATE_3;
        }
        else if (totalSold < STEP_2) {
            rate = RATE_2;
        }
        else if (totalSold < STEP_1) {
            rate = RATE_1;
        }
        else {
            rate = BASE_RATE;
        }
     
        if (amountWei >= 100000 ether) {
            rate += rate * 0 / 100;
        }
        else if (amountWei >= 10000 ether) {
            rate += rate * 0 / 100;
        }
        else if (amountWei >= 1000 ether) {
            rate += rate * 0 / 100;
        }
        else if (amountWei >= 100 ether) {
            rate += rate * 0 / 100;
        }
        else if (amountWei >= 10 ether) {
            rate += rate * 0 / 100;
        }
        else if (amountWei >= 1 ether) {
            rate += rate * 0 / 1000;
        }

        ExclusiveRate memory eRate = exclusiveRate[buyer];
        if (eRate.exists && eRate.workUntil >= now) {
            if (eRate.rate != 0) {
                rate = eRate.rate;
            }
            rate += rate * eRate.bonusPercent1000 / 1000;
        }
        return rate;
    }

    function setExclusiveRate(address _investor, uint _rate, uint16 _bonusPercent1000, uint32 _workUntil) onlyOwner {
        exclusiveRate[_investor] = ExclusiveRate(_workUntil, _rate, _bonusPercent1000, true);
    }

    function removeExclusiveRate(address _investor) onlyOwner {
        delete exclusiveRate[_investor];
    }
}
 
contract Crowdsale {
    using SafeMath for uint;

     
    MintableToken public token;

     
    uint32 internal startTime;
    uint32 internal endTime;

     
    address public wallet;

     
    uint public weiRaised;

     
    uint public soldTokens;

     
    uint internal hardCap;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint value, uint amount);

    function Crowdsale(uint _startTime, uint _endTime, uint _hardCap, address _wallet) {
        require(_endTime >= _startTime);
        require(_wallet != 0x0);
        require(_hardCap > 0);

        token = createTokenContract();
        startTime = uint32(_startTime);
        endTime = uint32(_endTime);
        hardCap = _hardCap;
        wallet = _wallet;
    }

     
     
    function createTokenContract() internal returns (MintableToken) {
        return new MintableToken();
    }

     
    function getRate(uint amount) internal constant returns (uint);

    function getBaseRate() internal constant returns (uint);

     
    function getRateScale() internal constant returns (uint) {
        return 1;
    }

     
    function() payable {
        buyTokens(msg.sender, msg.value);
    }

     
    function buyTokens(address beneficiary, uint amountWei) internal {
        require(beneficiary != 0x0);

         
        uint totalSupply = token.totalSupply();

         
        uint actualRate = getRate(amountWei);
        uint rateScale = getRateScale();

        require(validPurchase(amountWei, actualRate, totalSupply));

         
        uint tokens = amountWei.mul(actualRate).div(rateScale);

         
        weiRaised = weiRaised.add(amountWei);
        soldTokens = soldTokens.add(tokens);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, amountWei, tokens);

        forwardFunds(amountWei);
    }

     
     
    function forwardFunds(uint amountWei) internal {
        wallet.transfer(amountWei);
    }

     
    function validPurchase(uint _amountWei, uint _actualRate, uint _totalSupply) internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = _amountWei != 0;
        bool hardCapNotReached = _totalSupply <= hardCap;

        return withinPeriod && nonZeroPurchase && hardCapNotReached;
    }

     
    function hasEnded() public constant returns (bool) {
        return now > endTime || token.totalSupply() > hardCap;
    }

     
    function hasStarted() public constant returns (bool) {
        return now >= startTime;
    }
}

contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    event Finalized();

    function FinalizableCrowdsale(uint _startTime, uint _endTime, uint _hardCap, address _wallet)
            Crowdsale(_startTime, _endTime, _hardCap, _wallet) {
    }

     
    function finalize() onlyOwner notFinalized {
        require(hasEnded());

        finalization();
        Finalized();

        isFinalized = true;
    }

     
    function finalization() internal {
    }

    modifier notFinalized() {
        require(!isFinalized);
        _;
    }
}

contract EthereumV2Erc20Crowdsale is usingEthereumV2Erc20Consts, FinalizableCrowdsale {
    EthereumV2Erc20RateProviderI public rateProvider;

    function EthereumV2Erc20Crowdsale(
            uint _startTime,
            uint _endTime,
            uint _hardCapTokens
    )
            FinalizableCrowdsale(_startTime, _endTime, _hardCapTokens * TOKEN_DECIMAL_MULTIPLIER, COLD_WALLET) {

        token.mint(TEAM_ADDRESS, TEAM_TOKENS);
        token.mint(BOUNTY_ADDRESS, BOUNTY_TOKENS);
        token.mint(PREICO_ADDRESS, PREICO_TOKENS);

        EthereumV2Erc20(token).addExcluded(TEAM_ADDRESS);
        EthereumV2Erc20(token).addExcluded(BOUNTY_ADDRESS);
        EthereumV2Erc20(token).addExcluded(PREICO_ADDRESS);

        EthereumV2Erc20RateProvider provider = new EthereumV2Erc20RateProvider();
        provider.transferOwnership(owner);
        rateProvider = provider;
    }

     
    function createTokenContract() internal returns (MintableToken) {
        return new EthereumV2Erc20();
    }

     
    function getRate(uint _value) internal constant returns (uint) {
        return rateProvider.getRate(msg.sender, soldTokens, _value);
    }

    function getBaseRate() internal constant returns (uint) {
        return rateProvider.getRate(msg.sender, soldTokens, MINIMAL_PURCHASE);
    }

     
    function getRateScale() internal constant returns (uint) {
        return rateProvider.getRateScale();
    }

     
    function setRateProvider(address _rateProviderAddress) onlyOwner {
        require(_rateProviderAddress != 0);
        rateProvider = EthereumV2Erc20RateProviderI(_rateProviderAddress);
    }

     
    function setEndTime(uint _endTime) onlyOwner notFinalized {
        require(_endTime > startTime);
        endTime = uint32(_endTime);
    }

    function setHardCap(uint _hardCapTokens) onlyOwner notFinalized {
        require(_hardCapTokens * TOKEN_DECIMAL_MULTIPLIER > hardCap);
        hardCap = _hardCapTokens * TOKEN_DECIMAL_MULTIPLIER;
    }

    function setStartTime(uint _startTime) onlyOwner notFinalized {
        require(_startTime < endTime);
        startTime = uint32(_startTime);
    }

    function addExcluded(address _address) onlyOwner notFinalized {
        EthereumV2Erc20(token).addExcluded(_address);
    }

    function validPurchase(uint _amountWei, uint _actualRate, uint _totalSupply) internal constant returns (bool) {
        if (_amountWei < MINIMAL_PURCHASE) {
            return false;
        }
        return super.validPurchase(_amountWei, _actualRate, _totalSupply);
    }

    function finalization() internal {
        super.finalization();
        token.finishMinting();
        EthereumV2Erc20(token).crowdsaleFinished();
        token.transferOwnership(owner);
    }
}


 
contract Proxy {
     
    function () payable external {
        _fallback();
    }

     
    function _implementation() internal view returns (address);

     
    function _delegate(address implementation) internal {
        assembly {
         
         
         
            calldatacopy(0, 0, calldatasize)

         
         
            let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

         
            returndatacopy(0, 0, returndatasize)

            switch result
             
            case 0 { revert(0, returndatasize) }
            default { return(0, returndatasize) }
        }
    }

     
    function _willFallback() internal {
    }

     
    function _fallback() internal {
        _willFallback();
        _delegate(_implementation());
    }
}

 

 
library AddressUtils {

     
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}




contract Token {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}

contract Promotion {
    mapping(address => address[]) public referrals;  
    mapping(address => address) public affiliates;  
    mapping(address => bool) public admins;  
    string[] public affiliateList;
    address public owner;

    function setOwner(address newOwner);
    function setAdmin(address admin, bool isAdmin) public;
    function assignReferral (address affiliate, address referral) public;

    function getAffiliateCount() returns (uint);
    function getAffiliate(address refferal) public returns (address);
    function getReferrals(address affiliate) public returns (address[]);
}

contract TokenList {
    function isTokenInList(address tokenAddress) public constant returns (bool);
}


contract BTC20Exchange {
    function assert(bool assertion) {
        if (!assertion) throw;
    }
    function safeMul(uint a, uint b) returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
    address public owner;
    mapping (address => uint256) public invalidOrder;

    event SetOwner(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }
    function setOwner(address newOwner) onlyOwner {
        SetOwner(owner, newOwner);
        owner = newOwner;
    }
    function getOwner() returns (address out) {
        return owner;
    }
    function invalidateOrdersBefore(address user, uint256 nonce) onlyAdmin {
        if (nonce < invalidOrder[user]) throw;
        invalidOrder[user] = nonce;
    }

    mapping (address => mapping (address => uint256)) public tokens;  

    mapping (address => bool) public admins;
    mapping (address => uint256) public lastActiveTransaction;
    mapping (bytes32 => uint256) public orderFills;
    address public feeAccount;
    uint256 public feeAffiliate;  
    uint256 public inactivityReleasePeriod;
    mapping (bytes32 => bool) public traded;
    mapping (bytes32 => bool) public withdrawn;
    uint256 public makerFee;  
    uint256 public takerFee;  
    uint256 public affiliateFee;  
    uint256 public makerAffiliateFee;  
    uint256 public takerAffiliateFee;  

    mapping (address => address) public referrer;   

    address public affiliateContract;
    address public tokenListContract;


    enum Errors {
        INVLID_PRICE,            
        INVLID_SIGNATURE,        
        TOKENS_DONT_MATCH,       
        ORDER_ALREADY_FILLED,    
        GAS_TOO_HIGH             
    }

     
     
    event Trade(
        address takerTokenBuy, uint256 takerAmountBuy,
        address takerTokenSell, uint256 takerAmountSell,
        address maker, address indexed taker,
        uint256 makerFee, uint256 takerFee,
        uint256 makerAmountTaken, uint256 takerAmountTaken,
        bytes32 indexed makerOrderHash, bytes32 indexed takerOrderHash
    );
    event Deposit(address indexed token, address indexed user, uint256 amount, uint256 balance, address indexed referrerAddress);
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance, uint256 withdrawFee);
    event FeeChange(uint256 indexed makerFee, uint256 indexed takerFee, uint256 indexed affiliateFee);
     
    event LogError(uint8 indexed errorId, bytes32 indexed makerOrderHash, bytes32 indexed takerOrderHash);
    event CancelOrder(
        bytes32 indexed cancelHash,
        bytes32 indexed orderHash,
        address indexed user,
        address tokenSell,
        uint256 amountSell,
        uint256 cancelFee
    );

    function setInactivityReleasePeriod(uint256 expiry) onlyAdmin returns (bool success) {
        if (expiry > 1000000) throw;
        inactivityReleasePeriod = expiry;
        return true;
    }

    function Exchange(address feeAccount_, uint256 makerFee_, uint256 takerFee_, uint256 affiliateFee_, address affiliateContract_, address tokenListContract_) {
        owner = msg.sender;
        feeAccount = feeAccount_;
        inactivityReleasePeriod = 100000;
        makerFee = makerFee_;
        takerFee = takerFee_;
        affiliateFee = affiliateFee_;



        makerAffiliateFee = safeMul(makerFee, affiliateFee_) / (1 ether);
        takerAffiliateFee = safeMul(takerFee, affiliateFee_) / (1 ether);

        affiliateContract = affiliateContract_;
        tokenListContract = tokenListContract_;
    }

    function setFees(uint256 makerFee_, uint256 takerFee_, uint256 affiliateFee_) onlyOwner {
        require(makerFee_ < 10 finney && takerFee_ < 10 finney);
        require(affiliateFee_ > affiliateFee);
        makerFee = makerFee_;
        takerFee = takerFee_;
        affiliateFee = affiliateFee_;
        makerAffiliateFee = safeMul(makerFee, affiliateFee_) / (1 ether);
        takerAffiliateFee = safeMul(takerFee, affiliateFee_) / (1 ether);

        FeeChange(makerFee, takerFee, affiliateFee_);
    }

    function setAdmin(address admin, bool isAdmin) onlyOwner {
        admins[admin] = isAdmin;
    }

    modifier onlyAdmin {
        if (msg.sender != owner && !admins[msg.sender]) throw;
        _;
    }

    function() external {
        throw;
    }

    function depositToken(address token, uint256 amount, address referrerAddress) {
         
        if (referrerAddress == msg.sender) referrerAddress = address(0);
        if (referrer[msg.sender] == address(0x0))   {
            if (referrerAddress != address(0x0) && Promotion(affiliateContract).getAffiliate(msg.sender) == address(0))
            {
                referrer[msg.sender] = referrerAddress;
                Promotion(affiliateContract).assignReferral(referrerAddress, msg.sender);
            }
            else
            {
                referrer[msg.sender] = Promotion(affiliateContract).getAffiliate(msg.sender);
            }
        }
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        lastActiveTransaction[msg.sender] = block.number;
        if (!Token(token).transferFrom(msg.sender, this, amount)) throw;
        Deposit(token, msg.sender, amount, tokens[token][msg.sender], referrer[msg.sender]);
    }

    function deposit(address referrerAddress) payable {
        if (referrerAddress == msg.sender) referrerAddress = address(0);
        if (referrer[msg.sender] == address(0x0))   {
            if (referrerAddress != address(0x0) && Promotion(affiliateContract).getAffiliate(msg.sender) == address(0))
            {
                referrer[msg.sender] = referrerAddress;
                Promotion(affiliateContract).assignReferral(referrerAddress, msg.sender);
            }
            else
            {
                referrer[msg.sender] = Promotion(affiliateContract).getAffiliate(msg.sender);
            }
        }
        tokens[address(0)][msg.sender] = safeAdd(tokens[address(0)][msg.sender], msg.value);
        lastActiveTransaction[msg.sender] = block.number;
        Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender], referrer[msg.sender]);
    }

    function withdraw(address token, uint256 amount) returns (bool success) {
        if (safeSub(block.number, lastActiveTransaction[msg.sender]) < inactivityReleasePeriod) throw;
        if (tokens[token][msg.sender] < amount) throw;
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        if (token == address(0)) {
            if (!msg.sender.send(amount)) throw;
        } else {
            if (!Token(token).transfer(msg.sender, amount)) throw;
        }
        Withdraw(token, msg.sender, amount, tokens[token][msg.sender], 0);
    }

    function adminWithdraw(address token, uint256 amount, address user, uint256 nonce, uint8 v, bytes32 r, bytes32 s, uint256 feeWithdrawal) onlyAdmin returns (bool success) {
        bytes32 hash = keccak256(this, token, amount, user, nonce);
        if (withdrawn[hash]) throw;
        withdrawn[hash] = true;
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) != user) throw;
        if (feeWithdrawal > 50 finney) feeWithdrawal = 50 finney;
        if (tokens[token][user] < amount) throw;
        tokens[token][user] = safeSub(tokens[token][user], amount);
        tokens[address(0)][user] = safeSub(tokens[address(0x0)][user], feeWithdrawal);
         
        tokens[address(0)][feeAccount] = safeAdd(tokens[address(0)][feeAccount], feeWithdrawal);

         
        if (token == address(0)) {
            if (!user.send(amount)) throw;
        } else {
            if (!Token(token).transfer(user, amount)) throw;
        }
        lastActiveTransaction[user] = block.number;
        Withdraw(token, user, amount, tokens[token][user], feeWithdrawal);
    }

    function balanceOf(address token, address user) constant returns (uint256) {
        return tokens[token][user];
    }

    struct OrderPair {
        uint256 makerAmountBuy;
        uint256 makerAmountSell;
        uint256 makerNonce;
        uint256 takerAmountBuy;
        uint256 takerAmountSell;
        uint256 takerNonce;
        uint256 takerGasFee;

        address makerTokenBuy;
        address makerTokenSell;
        address maker;
        address takerTokenBuy;
        address takerTokenSell;
        address taker;

        bytes32 makerOrderHash;
        bytes32 takerOrderHash;
    }

    struct TradeValues {
        uint256 qty;
        uint256 invQty;
        uint256 makerAmountTaken;
        uint256 takerAmountTaken;
        address makerReferrer;
        address takerReferrer;
    }




    function trade(
        uint8[2] v,
        bytes32[4] rs,
        uint256[7] tradeValues,
        address[6] tradeAddresses
    ) onlyAdmin returns (uint filledTakerTokenAmount)
    {

         

        OrderPair memory t  = OrderPair({
            makerAmountBuy  : tradeValues[0],
            makerAmountSell : tradeValues[1],
            makerNonce      : tradeValues[2],
            takerAmountBuy  : tradeValues[3],
            takerAmountSell : tradeValues[4],
            takerNonce      : tradeValues[5],
            takerGasFee     : tradeValues[6],

            makerTokenBuy   : tradeAddresses[0],
            makerTokenSell  : tradeAddresses[1],
            maker           : tradeAddresses[2],
            takerTokenBuy   : tradeAddresses[3],
            takerTokenSell  : tradeAddresses[4],
            taker           : tradeAddresses[5],

            makerOrderHash  : keccak256(this, tradeAddresses[0], tradeValues[0], tradeAddresses[1], tradeValues[1], tradeValues[2], tradeAddresses[2]),
            takerOrderHash  : keccak256(this, tradeAddresses[3], tradeValues[3], tradeAddresses[4], tradeValues[4], tradeValues[5], tradeAddresses[5])
        });

         
         
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", t.makerOrderHash), v[0], rs[0], rs[1]) != t.maker)
        {
            LogError(uint8(Errors.INVLID_SIGNATURE), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }
         
         
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", t.takerOrderHash), v[1], rs[2], rs[3]) != t.taker)
        {
            LogError(uint8(Errors.INVLID_SIGNATURE), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }

        if (t.makerTokenBuy != t.takerTokenSell || t.makerTokenSell != t.takerTokenBuy)
        {
            LogError(uint8(Errors.TOKENS_DONT_MATCH), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }  

        if (t.takerGasFee > 1 finney)
        {
            LogError(uint8(Errors.GAS_TOO_HIGH), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }  



        if (!(
        (t.makerTokenBuy != address(0x0) && safeMul(t.makerAmountSell, 5 finney) / t.makerAmountBuy >= safeMul(t.takerAmountBuy, 5 finney) / t.takerAmountSell)
        ||
        (t.makerTokenBuy == address(0x0) && safeMul(t.makerAmountBuy, 5 finney) / t.makerAmountSell <= safeMul(t.takerAmountSell, 5 finney) / t.takerAmountBuy)
        ))
        {
            LogError(uint8(Errors.INVLID_PRICE), t.makerOrderHash, t.takerOrderHash);
            return 0;  
        }

        TradeValues memory tv = TradeValues({
            qty                 : 0,
            invQty              : 0,
            makerAmountTaken    : 0,
            takerAmountTaken    : 0,
            makerReferrer       : referrer[t.maker],
            takerReferrer       : referrer[t.taker]
        });

        if (tv.makerReferrer == address(0x0)) tv.makerReferrer = feeAccount;
        if (tv.takerReferrer == address(0x0)) tv.takerReferrer = feeAccount;



         
        if (t.makerTokenBuy != address(0x0))
        {


            tv.qty = min(safeSub(t.makerAmountBuy, orderFills[t.makerOrderHash]), safeSub(t.takerAmountSell, safeMul(orderFills[t.takerOrderHash], t.takerAmountSell) / t.takerAmountBuy));
            if (tv.qty == 0)
            {
                LogError(uint8(Errors.ORDER_ALREADY_FILLED), t.makerOrderHash, t.takerOrderHash);
                return 0;
            }

            tv.invQty = safeMul(tv.qty, t.makerAmountSell) / t.makerAmountBuy;

            tokens[t.makerTokenSell][t.maker]           = safeSub(tokens[t.makerTokenSell][t.maker],           tv.invQty);
            tv.makerAmountTaken                         = safeSub(tv.qty, safeMul(tv.qty, makerFee) / (1 ether));
            tokens[t.makerTokenBuy][t.maker]            = safeAdd(tokens[t.makerTokenBuy][t.maker],            tv.makerAmountTaken);
            tokens[t.makerTokenBuy][tv.makerReferrer]   = safeAdd(tokens[t.makerTokenBuy][tv.makerReferrer],   safeMul(tv.qty,    makerAffiliateFee) / (1 ether));

            tokens[t.takerTokenSell][t.taker]           = safeSub(tokens[t.takerTokenSell][t.taker],           tv.qty);
            tv.takerAmountTaken                         = safeSub(safeSub(tv.invQty, safeMul(tv.invQty, takerFee) / (1 ether)), safeMul(tv.invQty, t.takerGasFee) / (1 ether));
            tokens[t.takerTokenBuy][t.taker]            = safeAdd(tokens[t.takerTokenBuy][t.taker],            tv.takerAmountTaken);
            tokens[t.takerTokenBuy][tv.takerReferrer]   = safeAdd(tokens[t.takerTokenBuy][tv.takerReferrer],   safeMul(tv.invQty, takerAffiliateFee) / (1 ether));

            tokens[t.makerTokenBuy][feeAccount]     = safeAdd(tokens[t.makerTokenBuy][feeAccount],      safeMul(tv.qty,    safeSub(makerFee, makerAffiliateFee)) / (1 ether));
            tokens[t.takerTokenBuy][feeAccount]     = safeAdd(tokens[t.takerTokenBuy][feeAccount],      safeAdd(safeMul(tv.invQty, safeSub(takerFee, takerAffiliateFee)) / (1 ether), safeMul(tv.invQty, t.takerGasFee) / (1 ether)));


            orderFills[t.makerOrderHash]            = safeAdd(orderFills[t.makerOrderHash], tv.qty);
            orderFills[t.takerOrderHash]            = safeAdd(orderFills[t.takerOrderHash], safeMul(tv.qty, t.takerAmountBuy) / t.takerAmountSell);
            lastActiveTransaction[t.maker]          = block.number;
            lastActiveTransaction[t.taker]          = block.number;

            Trade(
                t.takerTokenBuy, tv.qty,
                t.takerTokenSell, tv.invQty,
                t.maker, t.taker,
                makerFee, takerFee,
                tv.makerAmountTaken , tv.takerAmountTaken,
                t.makerOrderHash, t.takerOrderHash
            );
            return tv.qty;
        }
         
        else
        {

            tv.qty = min(safeSub(t.makerAmountSell,  safeMul(orderFills[t.makerOrderHash], t.makerAmountSell) / t.makerAmountBuy), safeSub(t.takerAmountBuy, orderFills[t.takerOrderHash]));
            if (tv.qty == 0)
            {
                LogError(uint8(Errors.ORDER_ALREADY_FILLED), t.makerOrderHash, t.takerOrderHash);
                return 0;
            }

            tv.invQty = safeMul(tv.qty, t.makerAmountBuy) / t.makerAmountSell;

            tokens[t.makerTokenSell][t.maker]           = safeSub(tokens[t.makerTokenSell][t.maker],           tv.qty);
            tv.makerAmountTaken                         = safeSub(tv.invQty, safeMul(tv.invQty, makerFee) / (1 ether));
            tokens[t.makerTokenBuy][t.maker]            = safeAdd(tokens[t.makerTokenBuy][t.maker],            tv.makerAmountTaken);
            tokens[t.makerTokenBuy][tv.makerReferrer]   = safeAdd(tokens[t.makerTokenBuy][tv.makerReferrer],   safeMul(tv.invQty, makerAffiliateFee) / (1 ether));

            tokens[t.takerTokenSell][t.taker]           = safeSub(tokens[t.takerTokenSell][t.taker],           tv.invQty);
            tv.takerAmountTaken                         = safeSub(safeSub(tv.qty,    safeMul(tv.qty, takerFee) / (1 ether)), safeMul(tv.qty, t.takerGasFee) / (1 ether));
            tokens[t.takerTokenBuy][t.taker]            = safeAdd(tokens[t.takerTokenBuy][t.taker],            tv.takerAmountTaken);
            tokens[t.takerTokenBuy][tv.takerReferrer]   = safeAdd(tokens[t.takerTokenBuy][tv.takerReferrer],   safeMul(tv.qty,    takerAffiliateFee) / (1 ether));

            tokens[t.makerTokenBuy][feeAccount]     = safeAdd(tokens[t.makerTokenBuy][feeAccount],      safeMul(tv.invQty, safeSub(makerFee, makerAffiliateFee)) / (1 ether));
            tokens[t.takerTokenBuy][feeAccount]     = safeAdd(tokens[t.takerTokenBuy][feeAccount],      safeAdd(safeMul(tv.qty,    safeSub(takerFee, takerAffiliateFee)) / (1 ether), safeMul(tv.qty, t.takerGasFee) / (1 ether)));

            orderFills[t.makerOrderHash]            = safeAdd(orderFills[t.makerOrderHash], tv.invQty);
            orderFills[t.takerOrderHash]            = safeAdd(orderFills[t.takerOrderHash], tv.qty);  

            lastActiveTransaction[t.maker]          = block.number;
            lastActiveTransaction[t.taker]          = block.number;

            Trade(
                t.takerTokenBuy, tv.qty,
                t.takerTokenSell, tv.invQty,
                t.maker, t.taker,
                makerFee, takerFee,
                tv.makerAmountTaken , tv.takerAmountTaken,
                t.makerOrderHash, t.takerOrderHash
            );
            return tv.qty;
        }
    }

    function batchOrderTrade(
        uint8[2][] v,
        bytes32[4][] rs,
        uint256[7][] tradeValues,
        address[6][] tradeAddresses
    )
    {
        for (uint i = 0; i < tradeAddresses.length; i++) {
            trade(
                v[i],
                rs[i],
                tradeValues[i],
                tradeAddresses[i]
            );
        }
    }

    function cancelOrder(
		 
	    uint8[2] v,

		 
	    bytes32[4] rs,

		 
		uint256[5] cancelValues,

		 
		address[4] cancelAddresses
    ) public onlyAdmin {
         
        bytes32 orderHash = keccak256(
	        this, cancelAddresses[0], cancelValues[0], cancelAddresses[1],
	        cancelValues[1], cancelValues[2], cancelAddresses[2]
        );
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), v[0], rs[0], rs[1]) == cancelAddresses[2]);

         
        bytes32 cancelHash = keccak256(this, orderHash, cancelAddresses[3], cancelValues[3]);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", cancelHash), v[1], rs[2], rs[3]) == cancelAddresses[3]);

         
        require(cancelAddresses[2] == cancelAddresses[3]);

         
        require(orderFills[orderHash] != cancelValues[0]);

         
        if (cancelValues[4] > 6 finney) {
            cancelValues[4] = 6 finney;
        }

         
         
        tokens[address(0)][cancelAddresses[3]] = safeSub(tokens[address(0)][cancelAddresses[3]], cancelValues[4]);

         
        orderFills[orderHash] = cancelValues[0];

         
        CancelOrder(cancelHash, orderHash, cancelAddresses[3], cancelAddresses[1], cancelValues[1], cancelValues[4]);
    }

    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
}




 
contract IToken {
     
    function totalSupply() public constant returns (uint256 supply);

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint public decimals;
    string public name;
}

pragma solidity ^0.4.17;


 
library LSafeMath {

    uint256 constant WAD = 1 ether;
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a == b)
            return c;
        revert();
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > 0) { 
            uint256 c = a / b;
            return c;
        }
        revert();
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b <= a)
            return a - b;
        revert();
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        if (c >= a) 
            return c;
        revert();
    }

    function wmul(uint a, uint b) internal pure returns (uint256) {
        return add(mul(a, b), WAD / 2) / WAD;
    }

    function wdiv(uint a, uint b) internal pure returns (uint256) {
        return add(mul(a, WAD), b / 2) / b;
    }
}

 
contract Tokenchange {
  
  using LSafeMath for uint;
  
  struct SpecialTokenBalanceFeeTake {
      bool exist;
      address token;
      uint256 balance;
      uint256 feeTake;
  }
  
  uint constant private MAX_SPECIALS = 10;

   
  address public admin;  
  address public feeAccount;  
  uint public feeTake;  
  bool private depositingTokenFlag;  
  mapping (address => mapping (address => uint)) public tokens;  
  mapping (address => mapping (bytes32 => uint)) public orderFills;  
  SpecialTokenBalanceFeeTake[] public specialFees;
  

   
  event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
  event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);

   
  modifier isAdmin() {
      require(msg.sender == admin);
      _;
  }

   
  function Coinchangex(address admin_, address feeAccount_, uint feeTake_) public {
    admin = admin_;
    feeAccount = feeAccount_;
    feeTake = feeTake_;
    depositingTokenFlag = false;
  }

   
  function() public {
    revert();
  }

   
  function changeAdmin(address admin_) public isAdmin {
    require(admin_ != address(0));
    admin = admin_;
  }

   
  function changeFeeAccount(address feeAccount_) public isAdmin {
    feeAccount = feeAccount_;
  }

   
  function changeFeeTake(uint feeTake_) public isAdmin {
     
    feeTake = feeTake_;
  }
  
   
  function addSpecialFeeTake(address token, uint256 balance, uint256 feeTake) public isAdmin {
      uint id = specialFees.push(SpecialTokenBalanceFeeTake(
          true,
          token,
          balance,
          feeTake
      ));
  }
  
   
  function chnageSpecialFeeTake(uint id, address token, uint256 balance, uint256 feeTake) public isAdmin {
      require(id < specialFees.length);
      specialFees[id] = SpecialTokenBalanceFeeTake(
          true,
          token,
          balance,
          feeTake
      );
  }
  
     
   function removeSpecialFeeTake(uint id) public isAdmin {
       if (id >= specialFees.length) revert();

        uint last = specialFees.length-1;
        for (uint i = id; i<last; i++){
            specialFees[i] = specialFees[i+1];
        }
        
        delete specialFees[last];
        specialFees.length--;
  } 
  
   
  function TotalSpecialFeeTakes() public constant returns(uint)  {
      return specialFees.length;
  }
  
  
   
   
   

   
  function deposit() public payable {
    tokens[0][msg.sender] = tokens[0][msg.sender].add(msg.value);
    Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
  }

   
  function withdraw(uint amount) public {
    require(tokens[0][msg.sender] >= amount);
    tokens[0][msg.sender] = tokens[0][msg.sender].sub(amount);
    msg.sender.transfer(amount);
    Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
  }

   
  function depositToken(address token, uint amount) public {
    require(token != 0);
    depositingTokenFlag = true;
    require(IToken(token).transferFrom(msg.sender, this, amount));
    depositingTokenFlag = false;
    tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
    Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
 }

   
  function tokenFallback( address sender, uint amount, bytes data) public returns (bool ok) {
      if (depositingTokenFlag) {
         
        return true;
      } else {
         
         
        revert();
      }
  }
  
   
  function withdrawToken(address token, uint amount) public {
    require(token != 0);
    require(tokens[token][msg.sender] >= amount);
    tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
    require(IToken(token).transfer(msg.sender, amount));
    Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
  }

   
  function balanceOf(address token, address user) public constant returns (uint) {
    return tokens[token][user];
  }

   
   
   

   
  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) public {
    bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    require((
      (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) &&
      block.number <= expires &&
      orderFills[user][hash].add(amount) <= amountGet
    ));
    tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
    orderFills[user][hash] = orderFills[user][hash].add(amount);
    Trade(tokenGet, amount, tokenGive, amountGive.mul(amount) / amountGet, user, msg.sender);
  }

   
  function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {
    
    uint256 feeTakeXfer = calculateFee(amount);
    
    tokens[tokenGet][msg.sender] = tokens[tokenGet][msg.sender].sub(amount.add(feeTakeXfer));
    tokens[tokenGet][user] = tokens[tokenGet][user].add(amount);
    tokens[tokenGet][feeAccount] = tokens[tokenGet][feeAccount].add(feeTakeXfer);
    tokens[tokenGive][user] = tokens[tokenGive][user].sub(amountGive.mul(amount).div(amountGet));
    tokens[tokenGive][msg.sender] = tokens[tokenGive][msg.sender].add(amountGive.mul(amount).div(amountGet));
  }
  
   
  function calculateFee(uint amount) private constant returns(uint256)  {
    uint256 feeTakeXfer = 0;
    
    uint length = specialFees.length;
    bool applied = false;
    for(uint i = 0; length > 0 && i < length; i++) {
        SpecialTokenBalanceFeeTake memory special = specialFees[i];
        if(special.exist && special.balance <= tokens[special.token][msg.sender]) {
            applied = true;
            feeTakeXfer = amount.mul(special.feeTake).div(1 ether);
            break;
        }
        if(i >= MAX_SPECIALS)
            break;
    }
    
    if(!applied)
        feeTakeXfer = amount.mul(feeTake).div(1 ether);
    
    
    return feeTakeXfer;
  }

   
  function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) public constant returns(bool) {
    if (!(
      tokens[tokenGet][sender] >= amount &&
      availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount
      )) { 
      return false;
    } else {
      return true;
    }
  }

   
  function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) public constant returns(uint) {
    bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    if (!(
      (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) &&
      block.number <= expires
      )) {
      return 0;
    }
    uint[2] memory available;
    available[0] = amountGet.sub(orderFills[user][hash]);
    available[1] = tokens[tokenGive][user].mul(amountGet) / amountGive;
    if (available[0] < available[1]) {
      return available[0];
    } else {
      return available[1];
    }
  }

   
  function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) public constant returns(uint) {
    bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    return orderFills[user][hash];
  }

   
  function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) public {
    bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    require ((ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == msg.sender));
    orderFills[msg.sender][hash] = amountGet;
    Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
  }

  
   
  function depositForUser(address user) public payable {
    require(user != address(0));
    require(msg.value > 0);
    tokens[0][user] = tokens[0][user].add(msg.value);
  }
  
   
  function depositTokenForUser(address token, uint amount, address user) public {
    require(token != address(0));
    require(user != address(0));
    require(amount > 0);
    depositingTokenFlag = true;
    require(IToken(token).transferFrom(msg.sender, this, amount));
    depositingTokenFlag = false;
    tokens[token][user] = tokens[token][user].add(amount);
  }
  
}