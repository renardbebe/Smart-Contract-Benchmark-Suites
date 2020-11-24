 

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

contract usingINHERITANCEConsts {
    uint constant TOKEN_DECIMALS = 18;
    uint8 constant TOKEN_DECIMALS_UINT8 = 18;
    uint constant TOKEN_DECIMAL_MULTIPLIER = 10 ** TOKEN_DECIMALS;

    uint constant TEAM_TOKENS =   250000000 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant BOUNTY_TOKENS = 250000000 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant PREICO_TOKENS = 250000000 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant MINIMAL_PURCHASE = 0.1 ether;

    address constant TEAM_ADDRESS = 0x78cd8f794686ee8f6644447e961ef52776edf0cb;
    address constant BOUNTY_ADDRESS = 0xff823588500d3ecd7777a1cfa198958df4deea11;
    address constant PREICO_ADDRESS = 0xff823588500d3ecd7777a1cfa198958df4deea11;
    address constant COLD_WALLET = 0x439415b03708bde585856b46666f34b65af6a5c3;

    string constant TOKEN_NAME = "INHERITANCE";
    bytes32 constant TOKEN_SYMBOL = "IEI";
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

contract INHERITANCEToken is usingINHERITANCEConsts, MintableToken, BurnableToken {
     
    bool public paused = true;
     
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
contract INHERITANCERateProviderI {
     
    function getRate(address buyer, uint totalSold, uint amountWei) public constant returns (uint);

     
    function getRateScale() public constant returns (uint);

     
    function getBaseRate() public constant returns (uint);
}

contract INHERITANCERateProvider is usingINHERITANCEConsts, INHERITANCERateProviderI, Ownable {
     
    uint constant RATE_SCALE = 1000000;
    uint constant STEP_30 = 10000000 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant STEP_20 = 50000000 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant STEP_10 = 1000000000 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant RATE_30 = 130000 * RATE_SCALE;
    uint constant RATE_20 = 120000 * RATE_SCALE;
    uint constant RATE_10 = 110000 * RATE_SCALE;
    uint constant BASE_RATE = 100000 * RATE_SCALE;

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
         
        if (totalSold < STEP_30) {
            rate = RATE_30;
        }
        else if (totalSold < STEP_20) {
            rate = RATE_20;
        }
        else if (totalSold < STEP_10) {
            rate = RATE_10;
        }
        else {
            rate = BASE_RATE;
        }

         
        if (amountWei >= 100 ether) {
            rate += rate * 100 / 100;
        }
        else if (amountWei >= 50 ether) {
            rate += rate * 100 / 100;
        }
        else if (amountWei >= 10 ether) {
            rate += rate * 300 / 100;
        }
        else if (amountWei >= 4 ether) {
            rate += rate * 100 / 100;
        }
        else if (amountWei >= 2 ether) {
            rate += rate * 40 / 100;
        }
        else if (amountWei >= 1 ether) {
            rate += rate * 150 / 1000;
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

contract INHERITANCECrowdsale is usingINHERITANCEConsts, FinalizableCrowdsale {
    INHERITANCERateProviderI public rateProvider;

    function INHERITANCECrowdsale(
            uint _startTime,
            uint _endTime,
            uint _hardCapTokens
    )
            FinalizableCrowdsale(_startTime, _endTime, _hardCapTokens * TOKEN_DECIMAL_MULTIPLIER, COLD_WALLET) {

        token.mint(TEAM_ADDRESS, TEAM_TOKENS);
        token.mint(BOUNTY_ADDRESS, BOUNTY_TOKENS);
        token.mint(PREICO_ADDRESS, PREICO_TOKENS);

        INHERITANCEToken(token).addExcluded(TEAM_ADDRESS);
        INHERITANCEToken(token).addExcluded(BOUNTY_ADDRESS);
        INHERITANCEToken(token).addExcluded(PREICO_ADDRESS);

        INHERITANCERateProvider provider = new INHERITANCERateProvider();
        provider.transferOwnership(owner);
        rateProvider = provider;
    }

     
    function createTokenContract() internal returns (MintableToken) {
        return new INHERITANCEToken();
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
        rateProvider = INHERITANCERateProviderI(_rateProviderAddress);
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
        INHERITANCEToken(token).addExcluded(_address);
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
        INHERITANCEToken(token).crowdsaleFinished();
        token.transferOwnership(owner);
    }
}