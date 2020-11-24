 

pragma solidity ^0.4.18;

 

 
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

 

 
contract Pausable is Ownable {
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
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

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
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

 

contract Token is StandardToken, Pausable {
    string constant public name = "Bace Token";
    string constant public symbol = "BACE";
    uint8 constant public decimals =  18;

    uint256 constant public INITIAL_TOTAL_SUPPLY = 100 * 1E6 * (uint256(10) ** (decimals));

    address private addressIco;

    modifier onlyIco() {
        require(msg.sender == addressIco);
        _;
    }

     
    function Token(address _ico) public {
        require(_ico != address(0));
        addressIco = _ico;

        totalSupply = totalSupply.add(INITIAL_TOTAL_SUPPLY);
        balances[_ico] = balances[_ico].add(INITIAL_TOTAL_SUPPLY);
        Transfer(address(0), _ico, INITIAL_TOTAL_SUPPLY);

        pause();
    }

     
    function transfer(address _to, uint256 _value) whenNotPaused public returns (bool) {
        super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool) {
        super.transferFrom(_from, _to, _value);
    }

     
    function transferFromIco(address _to, uint256 _value) onlyIco public returns (bool) {
        super.transfer(_to, _value);
    }

     
    function burnFromIco() onlyIco public {
        uint256 remainingTokens = balanceOf(addressIco);
        balances[addressIco] = balances[addressIco].sub(remainingTokens);
        totalSupply = totalSupply.sub(remainingTokens);
        Transfer(addressIco, address(0), remainingTokens);
    }

     
    function refund(address _to, uint256 _value) onlyIco public {
        require(_value <= balances[_to]);

        address addr = _to;
        balances[addr] = balances[addr].sub(_value);
        balances[addressIco] = balances[addressIco].add(_value);
        Transfer(_to, addressIco, _value);
    }
}

 

 
contract Whitelist is Ownable {
    mapping(address => bool) whitelist;

    uint256 public whitelistLength = 0;
	
	address private addressApi;
	
	modifier onlyPrivilegeAddresses {
        require(msg.sender == addressApi || msg.sender == owner);
        _;
    }

     
    function setApiAddress(address _api) onlyOwner public {
        require(_api != address(0));

        addressApi = _api;
    }


       
    function addWallet(address _wallet) onlyPrivilegeAddresses public {
        require(_wallet != address(0));
        require(!isWhitelisted(_wallet));
        whitelist[_wallet] = true;
        whitelistLength++;
    }

       
    function removeWallet(address _wallet) onlyOwner public {
        require(_wallet != address(0));
        require(isWhitelisted(_wallet));
        whitelist[_wallet] = false;
        whitelistLength--;
    }

      
    function isWhitelisted(address _wallet) view public returns (bool) {
        return whitelist[_wallet];
    }

}

 

 


contract Whitelistable {
    Whitelist public whitelist;

    modifier whenWhitelisted(address _wallet) {
        require(whitelist.isWhitelisted(_wallet));
        _;
    }

     
    function Whitelistable() public {
        whitelist = new Whitelist();
    }
}

 

contract Crowdsale is Pausable, Whitelistable {
    using SafeMath for uint256;

     
     
     
     
    uint256 constant private DECIMALS = 18;
     
    uint256 constant public BACE_ETH = 1800;
     
    uint256 constant public PREICO_BONUS = 20;
     
    uint256 constant public RESERVED_TOKENS_BACE_TEAM = 20 * 1E6 * (10 ** DECIMALS);
     
    uint256 constant public RESERVED_TOKENS_ANGLE = 10 * 1E6 * (10 ** DECIMALS);
     
    uint256 constant public HARDCAP_TOKENS_PRE_ICO = 10 * 1E6 * (10 ** DECIMALS);
     
    uint256 constant public HARDCAP_TOKENS_ICO = 70 * 1E6 * (10 ** DECIMALS);
     
    uint256 constant public MINCAP_TOKENS = 5 * 1E6 * (10 ** DECIMALS);
     

     
     
     
    uint256 public maxInvestments;

    uint256 public minInvestments;

     
    bool private testMode;

     
    Token public token;

     
    uint256 public preIcoStartTime;

     
    uint256 public preIcoFinishTime;

     
    uint256 public icoStartTime;

     
    uint256 public icoFinishTime;

     
    bool public icoInstalled;

     
    address private backendWallet;

     
    address private withdrawalWallet;

     
    uint256 public guardInterval;
     

     
     
     
     
    mapping(address => uint256) public preIcoInvestors;

     
    address[] public preIcoInvestorsAddresses;

     
    mapping(address => uint256) public icoInvestors;

     
    address[] public icoInvestorsAddresses;

     
    uint256 public preIcoTotalCollected;

     
    uint256 public icoTotalCollected;
     

     
     
     

     
    mapping(address => uint256) public preIcoTokenHolders;

     
    address[] public preIcoTokenHoldersAddresses;

     
    mapping(address => uint256) public icoTokenHolders;

     
    address[] public icoTokenHoldersAddresses;

     
    uint256 public minCap;

     
    uint256 public hardCapPreIco;

     
    uint256 public hardCapIco;

     
    uint256 public preIcoSoldTokens;

     
    uint256 public icoSoldTokens;

     
    uint256 public exchangeRatePreIco;

     
    uint256 public exchangeRateIco;

     
    bool burnt;
     

     
    function Crowdsale (
        uint256 _startTimePreIco,
        uint256 _endTimePreIco,
        address _angelInvestorsWallet,
        address _foundersWallet,
        address _backendWallet,
        address _withdrawalWallet,
        uint256 _maxInvestments,
        uint256 _minInvestments,
        bool _testMode
    ) public Whitelistable()
    {
        require(_angelInvestorsWallet != address(0) && _foundersWallet != address(0) && _backendWallet != address(0) && _withdrawalWallet != address(0));
        require(_startTimePreIco >= now && _endTimePreIco > _startTimePreIco);
        require(_maxInvestments != 0 && _minInvestments != 0 && _maxInvestments > _minInvestments);

         
         
         
        testMode = _testMode;
        token = new Token(this);
        maxInvestments = _maxInvestments;
        minInvestments = _minInvestments;
        preIcoStartTime = _startTimePreIco;
        preIcoFinishTime = _endTimePreIco;
        icoStartTime = 0;
        icoFinishTime = 0;
        icoInstalled = false;
        guardInterval = uint256(86400).mul(7);  
         

         
         
        preIcoTotalCollected = 0;
        icoTotalCollected = 0;
         

         
         
         
        minCap = MINCAP_TOKENS;
        hardCapPreIco = HARDCAP_TOKENS_PRE_ICO;
        hardCapIco = HARDCAP_TOKENS_ICO;
        preIcoSoldTokens = 0;
        icoSoldTokens = 0;
        exchangeRateIco = BACE_ETH;
        exchangeRatePreIco = exchangeRateIco.mul(uint256(100).add(PREICO_BONUS)).div(100);
        burnt = false;
         

        backendWallet = _backendWallet;
        withdrawalWallet = _withdrawalWallet;

        whitelist.transferOwnership(msg.sender);

        token.transferFromIco(_angelInvestorsWallet, RESERVED_TOKENS_ANGLE);
        token.transferFromIco(_foundersWallet, RESERVED_TOKENS_BACE_TEAM);
        token.transferOwnership(msg.sender);
    }

    modifier isTestMode() {
        require(testMode);
        _;
    }

     
    function isIcoFailed() public view returns (bool) {
        return isIcoFinish() && icoSoldTokens.add(preIcoSoldTokens) < minCap;
    }

     
    function isIcoSuccess() public view returns (bool) {
        return isIcoFinish() && icoSoldTokens.add(preIcoSoldTokens) >= minCap;
    }

     
    function isPreIcoStage() public view returns (bool) {
        return now > preIcoStartTime && now < preIcoFinishTime;
    }

     
    function isIcoStage() public view returns (bool) {
        return icoInstalled && now > icoStartTime && now < icoFinishTime;
    }

     
    function isPreIcoFinish() public view returns (bool) {
        return now > preIcoFinishTime;
    }

     
    function isIcoFinish() public view returns (bool) {
        return icoInstalled && now > icoFinishTime;
    }

     
    function guardIntervalFinished() public view returns (bool) {
        return now > icoFinishTime.add(guardInterval);
    }

     
    function setStartTimeIco(uint256 _startTimeIco, uint256 _endTimeIco) onlyOwner public {
        require(_startTimeIco >= now && _endTimeIco > _startTimeIco && _startTimeIco > preIcoFinishTime);

        icoStartTime = _startTimeIco;
        icoFinishTime = _endTimeIco;
        icoInstalled = true;
    }

     
    function tokensRemainingPreIco() public view returns(uint256) {
        if (isPreIcoFinish()) {
            return 0;
        }
        return hardCapPreIco.sub(preIcoSoldTokens);
    }

     
    function tokensRemainingIco() public view returns(uint256) {
        if (burnt) {
            return 0;
        }
        if (isPreIcoFinish()) {
            return hardCapIco.sub(icoSoldTokens).sub(preIcoSoldTokens);
        }
        return hardCapIco.sub(hardCapPreIco).sub(icoSoldTokens);
    }

     
    function addInvestInfoPreIco(address _addr,  uint256 _weis, uint256 _tokens) private {
        if (preIcoTokenHolders[_addr] == 0) {
            preIcoTokenHoldersAddresses.push(_addr);
        }
        preIcoTokenHolders[_addr] = preIcoTokenHolders[_addr].add(_tokens);
        preIcoSoldTokens = preIcoSoldTokens.add(_tokens);
        if (_weis > 0) {
            if (preIcoInvestors[_addr] == 0) {
                preIcoInvestorsAddresses.push(_addr);
            }
            preIcoInvestors[_addr] = preIcoInvestors[_addr].add(_weis);
            preIcoTotalCollected = preIcoTotalCollected.add(_weis);
        }
    }

     
    function addInvestInfoIco(address _addr,  uint256 _weis, uint256 _tokens) private {
        if (icoTokenHolders[_addr] == 0) {
            icoTokenHoldersAddresses.push(_addr);
        }
        icoTokenHolders[_addr] = icoTokenHolders[_addr].add(_tokens);
        icoSoldTokens = icoSoldTokens.add(_tokens);
        if (_weis > 0) {
            if (icoInvestors[_addr] == 0) {
                icoInvestorsAddresses.push(_addr);
            }
            icoInvestors[_addr] = icoInvestors[_addr].add(_weis);
            icoTotalCollected = icoTotalCollected.add(_weis);
        }
    }

     
    function() public payable {
        acceptInvestments(msg.sender, msg.value);
    }

     
    function sellTokens() public payable {
        acceptInvestments(msg.sender, msg.value);
    }

     
    function acceptInvestments(address _addr, uint256 _amount) private whenWhitelisted(msg.sender) whenNotPaused {
        require(_addr != address(0) && _amount >= minInvestments);

        bool preIco = isPreIcoStage();
        bool ico = isIcoStage();

        require(preIco || ico);
        require((preIco && tokensRemainingPreIco() > 0) || (ico && tokensRemainingIco() > 0));

        uint256 intermediateEthInvestment;
        uint256 ethSurrender = 0;
        uint256 currentEth = preIco ? preIcoInvestors[_addr] : icoInvestors[_addr];

        if (currentEth.add(_amount) > maxInvestments) {
            intermediateEthInvestment = maxInvestments.sub(currentEth);
            ethSurrender = ethSurrender.add(_amount.sub(intermediateEthInvestment));
        } else {
            intermediateEthInvestment = _amount;
        }

        uint256 currentRate = preIco ? exchangeRatePreIco : exchangeRateIco;
        uint256 intermediateTokenInvestment = intermediateEthInvestment.mul(currentRate);
        uint256 tokensRemaining = preIco ? tokensRemainingPreIco() : tokensRemainingIco();
        uint256 currentTokens = preIco ? preIcoTokenHolders[_addr] : icoTokenHolders[_addr];
        uint256 weiToAccept;
        uint256 tokensToSell;

        if (currentTokens.add(intermediateTokenInvestment) > tokensRemaining) {
            tokensToSell = tokensRemaining;
            weiToAccept = tokensToSell.div(currentRate);
            ethSurrender = ethSurrender.add(intermediateEthInvestment.sub(weiToAccept));
        } else {
            tokensToSell = intermediateTokenInvestment;
            weiToAccept = intermediateEthInvestment;
        }

        if (preIco) {
            addInvestInfoPreIco(_addr, weiToAccept, tokensToSell);
        } else {
            addInvestInfoIco(_addr, weiToAccept, tokensToSell);
        }

        token.transferFromIco(_addr, tokensToSell);

        if (ethSurrender > 0) {
            msg.sender.transfer(ethSurrender);
        }
    }

     
    function thirdPartyInvestments(address _addr, uint256 _value) public  whenWhitelisted(_addr) whenNotPaused {
        require(msg.sender == backendWallet || msg.sender == owner);
        require(_addr != address(0) && _value > 0);

        bool preIco = isPreIcoStage();
        bool ico = isIcoStage();

        require(preIco || ico);
        require((preIco && tokensRemainingPreIco() > 0) || (ico && tokensRemainingIco() > 0));

        uint256 currentRate = preIco ? exchangeRatePreIco : exchangeRateIco;
        uint256 currentTokens = preIco ? preIcoTokenHolders[_addr] : icoTokenHolders[_addr];

        require(maxInvestments.mul(currentRate) >= currentTokens.add(_value));
        require(minInvestments.mul(currentRate) <= _value);

        uint256 tokensRemaining = preIco ? tokensRemainingPreIco() : tokensRemainingIco();

        require(tokensRemaining >= _value);

        if (preIco) {
            addInvestInfoPreIco(_addr, 0, _value);
        } else {
            addInvestInfoIco(_addr, 0, _value);
        }

        token.transferFromIco(_addr, _value);
    }

     
    function forwardFunds(uint256 _weiAmount) public onlyOwner {
        require(isIcoSuccess() || (isIcoFailed() && guardIntervalFinished()));
        withdrawalWallet.transfer(_weiAmount);
    }

     
    function refund() public {
        require(isIcoFailed() && !guardIntervalFinished());

        uint256 ethAmountPreIco = preIcoInvestors[msg.sender];
        uint256 ethAmountIco = icoInvestors[msg.sender];
        uint256 ethAmount = ethAmountIco.add(ethAmountPreIco);

        uint256 tokensAmountPreIco = preIcoTokenHolders[msg.sender];
        uint256 tokensAmountIco = icoTokenHolders[msg.sender];
        uint256 tokensAmount = tokensAmountPreIco.add(tokensAmountIco);

        require(ethAmount > 0 && tokensAmount > 0);

        preIcoInvestors[msg.sender] = 0;
        icoInvestors[msg.sender] = 0;
        preIcoTokenHolders[msg.sender] = 0;
        icoTokenHolders[msg.sender] = 0;

        msg.sender.transfer(ethAmount);
        token.refund(msg.sender, tokensAmount);
    }

     
    function setWithdrawalWallet(address _addr) public onlyOwner {
        require(_addr != address(0));

        withdrawalWallet = _addr;
    }

     
    function setBackendWallet(address _addr) public onlyOwner {
        require(_addr != address(0));

        backendWallet = _addr;
    }

     
    function burnUnsoldTokens() onlyOwner public {
        require(isIcoFinish());
        token.burnFromIco();
        burnt = true;
    }

     
    function setMinCap(uint256 _newMinCap) public onlyOwner isTestMode {
        require(now < preIcoFinishTime);
        minCap = _newMinCap;
    }

     
    function setPreIcoHardCap(uint256 _newPreIcoHardCap) public onlyOwner isTestMode {
        require(now < preIcoFinishTime);
        require(_newPreIcoHardCap <= hardCapIco);
        hardCapPreIco = _newPreIcoHardCap;
    }

     
    function setIcoHardCap(uint256 _newIcoHardCap) public onlyOwner isTestMode {
        require(now < preIcoFinishTime);
        require(_newIcoHardCap > hardCapPreIco);
        hardCapIco = _newIcoHardCap;
    }

     
    function getIcoTokenHoldersAddressesCount() public view returns(uint256) {
        return icoTokenHoldersAddresses.length;
    }

     
    function getPreIcoTokenHoldersAddressesCount() public view returns(uint256) {
        return preIcoTokenHoldersAddresses.length;
    }

     
    function getIcoInvestorsAddressesCount() public view returns(uint256) {
        return icoInvestorsAddresses.length;
    }

     
    function getPreIcoInvestorsAddressesCount() public view returns(uint256) {
        return preIcoInvestorsAddresses.length;
    }

     
    function getBackendWallet() public view returns(address) {
        return backendWallet;
    }

     
    function getWithdrawalWallet() public view returns(address) {
        return withdrawalWallet;
    }
}

 

contract Factory {
    Crowdsale public crowdsale;

    function createCrowdsale (
        uint256 _startTimePreIco,
        uint256 _endTimePreIco,
        address _angelInvestorsWallet,
        address _foundersWallet,
        address _backendWallet,
        address _withdrawalWallet,
        uint256 _maxInvestments,
        uint256 _minInvestments,
        bool _testMode
    ) public
    {
        crowdsale = new Crowdsale(
            _startTimePreIco,
            _endTimePreIco,
            _angelInvestorsWallet,
            _foundersWallet,
            _backendWallet,
            _withdrawalWallet,
            _maxInvestments,
            _minInvestments,
            _testMode
        );

        Whitelist whitelist = crowdsale.whitelist();
        whitelist.transferOwnership(msg.sender);

        Token token = crowdsale.token();
        token.transferOwnership(msg.sender);

        crowdsale.transferOwnership(msg.sender);
    }
}