 

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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
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

 

 
contract SimpleToken is StandardToken {

  string public constant name = "SimpleToken";  
  string public constant symbol = "SIM";  
  uint8 public constant decimals = 18;  

  uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** uint256(decimals));

   
  function SimpleToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    Transfer(0x0, msg.sender, INITIAL_SUPPLY);
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

 

 



contract LockedOutTokens is Ownable {

    address public wallet;
    uint8 public tranchesCount;
    uint256 public trancheSize;
    uint256 public period;

    uint256 public startTimestamp;
    uint8 public tranchesPayedOut = 0;

    ERC20Basic internal token;
    
    function LockedOutTokens(
        address _wallet,
        address _tokenAddress,
        uint256 _startTimestamp,
        uint8 _tranchesCount,
        uint256 _trancheSize,
        uint256 _periodSeconds
    ) {
        require(_wallet != address(0));
        require(_tokenAddress != address(0));
        require(_startTimestamp > 0);
        require(_tranchesCount > 0);
        require(_trancheSize > 0);
        require(_periodSeconds > 0);

        wallet = _wallet;
        tranchesCount = _tranchesCount;
        startTimestamp = _startTimestamp;
        trancheSize = _trancheSize;
        period = _periodSeconds;

        token = ERC20Basic(_tokenAddress);
    }

    function grant()
        public
    {
        require(wallet == msg.sender);
        require(tranchesPayedOut < tranchesCount);
        require(startTimestamp > 0);
        require(now >= startTimestamp + (period * (tranchesPayedOut + 1)));

        tranchesPayedOut = tranchesPayedOut + 1;
        token.transfer(wallet, trancheSize);
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

 

contract TiqpitToken is StandardToken, Pausable {
    using SafeMath for uint256;

    string constant public name = "Tiqpit Token";
    string constant public symbol = "PIT";
    uint8 constant public decimals = 18;

    string constant public smallestUnitName = "TIQ";

    uint256 constant public INITIAL_TOTAL_SUPPLY = 500e6 * (uint256(10) ** decimals);

    address private addressIco;

    modifier onlyIco() {
        require(msg.sender == addressIco);
        _;
    }
    
     
    function TiqpitToken (address _ico) public {
        require(_ico != address(0));

        addressIco = _ico;

        totalSupply_ = totalSupply_.add(INITIAL_TOTAL_SUPPLY);
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

     
    function burnFromAddress(address _from) onlyIco public {
        uint256 amount = balances[_from];

        require(_from != address(0));
        require(amount > 0);
        require(amount <= balances[_from]);

        balances[_from] = balances[_from].sub(amount);
        totalSupply_ = totalSupply_.sub(amount);
        Transfer(_from, address(0), amount);
    }
}

 

 
contract Whitelist is Ownable {
    mapping(address => bool) whitelist;

    uint256 public whitelistLength = 0;

    address public backendAddress;

       
    function addWallet(address _wallet) public onlyPrivilegedAddresses {
        require(_wallet != address(0));
        require(!isWhitelisted(_wallet));
        whitelist[_wallet] = true;
        whitelistLength++;
    }

       
    function removeWallet(address _wallet) public onlyOwner {
        require(_wallet != address(0));
        require(isWhitelisted(_wallet));
        whitelist[_wallet] = false;
        whitelistLength--;
    }

      
    function isWhitelisted(address _wallet) constant public returns (bool) {
        return whitelist[_wallet];
    }

     
    function setBackendAddress(address _backendAddress) public onlyOwner {
        require(_backendAddress != address(0));
        backendAddress = _backendAddress;
    }

     
    modifier onlyPrivilegedAddresses() {
        require(msg.sender == owner || msg.sender == backendAddress);
        _;
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

 

contract TiqpitCrowdsale is Pausable, Whitelistable {
    using SafeMath for uint256;

    uint256 constant private DECIMALS = 18;
    
    uint256 constant public RESERVED_TOKENS_BOUNTY = 10e6 * (10 ** DECIMALS);
    uint256 constant public RESERVED_TOKENS_FOUNDERS = 25e6 * (10 ** DECIMALS);
    uint256 constant public RESERVED_TOKENS_ADVISORS = 25e5 * (10 ** DECIMALS);
    uint256 constant public RESERVED_TOKENS_TIQPIT_SOLUTIONS = 625e5 * (10 ** DECIMALS);

    uint256 constant public MIN_INVESTMENT = 200 * (10 ** DECIMALS);
    
    uint256 constant public MINCAP_TOKENS_PRE_ICO = 1e6 * (10 ** DECIMALS);
    uint256 constant public MAXCAP_TOKENS_PRE_ICO = 75e5 * (10 ** DECIMALS);
    
    uint256 constant public MINCAP_TOKENS_ICO = 5e6 * (10 ** DECIMALS);    
    uint256 constant public MAXCAP_TOKENS_ICO = 3925e5 * (10 ** DECIMALS);

    uint256 public tokensRemainingIco = MAXCAP_TOKENS_ICO;
    uint256 public tokensRemainingPreIco = MAXCAP_TOKENS_PRE_ICO;

    uint256 public soldTokensPreIco = 0;
    uint256 public soldTokensIco = 0;
    uint256 public soldTokensTotal = 0;

    uint256 public preIcoRate = 2857;         

     
    uint256 public firstRate = 2500;          
    uint256 public secondRate = 2222;         
    uint256 public thirdRate = 2000;          

    uint256 public startTimePreIco = 0;
    uint256 public endTimePreIco = 0;

    uint256 public startTimeIco = 0;
    uint256 public endTimeIco = 0;

    uint256 public weiRaisedPreIco = 0;
    uint256 public weiRaisedIco = 0;
    uint256 public weiRaisedTotal = 0;

    TiqpitToken public token = new TiqpitToken(this);

     
    mapping (address => address) private lockedList;

    address private tiqpitSolutionsWallet;
    address private foundersWallet;
    address private advisorsWallet;
    address private bountyWallet;

    address public backendAddress;

    bool private hasPreIcoFailed = false;
    bool private hasIcoFailed = false;

    bool private isInitialDistributionDone = false;

    struct Purchase {
        uint256 refundableWei;
        uint256 burnableTiqs;
    }

    mapping(address => Purchase) private preIcoPurchases;
    mapping(address => Purchase) private icoPurchases;

     
    function TiqpitCrowdsale(
        uint256 _startTimePreIco,
        uint256 _endTimePreIco,
        uint256 _startTimeIco,
        uint256 _endTimeIco,
        address _foundersWallet,
        address _advisorsWallet,
        address _tiqpitSolutionsWallet,
        address _bountyWallet
    ) Whitelistable() public
    {
        require(_bountyWallet != address(0) && _foundersWallet != address(0) && _tiqpitSolutionsWallet != address(0) && _advisorsWallet != address(0));
        
        require(_startTimePreIco >= now && _endTimePreIco > _startTimePreIco);
        require(_startTimeIco >= _endTimePreIco && _endTimeIco > _startTimeIco);

        startTimePreIco = _startTimePreIco;
        endTimePreIco = _endTimePreIco;

        startTimeIco = _startTimeIco;
        endTimeIco = _endTimeIco;

        tiqpitSolutionsWallet = _tiqpitSolutionsWallet;
        advisorsWallet = _advisorsWallet;
        foundersWallet = _foundersWallet;
        bountyWallet = _bountyWallet;

        whitelist.transferOwnership(msg.sender);
        token.transferOwnership(msg.sender);
    }

     
    function() public payable {
        sellTokens();
    }

     
    function isPreIco() public view returns (bool) {
        return now >= startTimePreIco && now <= endTimePreIco;
    }

     
    function isIco() public view returns (bool) {
        return now >= startTimeIco && now <= endTimeIco;
    }

     
    function burnRemainingTokens() onlyOwner public {
        require(tokensRemainingIco > 0);
        require(now > endTimeIco);

        token.burnFromAddress(this);

        tokensRemainingIco = 0;
    }

     
    function initialDistribution() onlyOwner public {
        require(!isInitialDistributionDone);

        token.transferFromIco(bountyWallet, RESERVED_TOKENS_BOUNTY);

        token.transferFromIco(advisorsWallet, RESERVED_TOKENS_ADVISORS);
        token.transferFromIco(tiqpitSolutionsWallet, RESERVED_TOKENS_TIQPIT_SOLUTIONS);
        
        lockTokens(foundersWallet, RESERVED_TOKENS_FOUNDERS, 1 years);

        isInitialDistributionDone = true;
    }

     
    function getIcoPurchase(address _address) view public returns(uint256 weis, uint256 tokens) {
        return (icoPurchases[_address].refundableWei, icoPurchases[_address].burnableTiqs);
    }

     
    function getPreIcoPurchase(address _address) view public returns(uint256 weis, uint256 tokens) {
        return (preIcoPurchases[_address].refundableWei, preIcoPurchases[_address].burnableTiqs);
    }

     
    function refundPreIco() public {
        require(hasPreIcoFailed);

        require(preIcoPurchases[msg.sender].burnableTiqs > 0 && preIcoPurchases[msg.sender].refundableWei > 0);
        
        uint256 amountWei = preIcoPurchases[msg.sender].refundableWei;
        msg.sender.transfer(amountWei);

        preIcoPurchases[msg.sender].refundableWei = 0;
        preIcoPurchases[msg.sender].burnableTiqs = 0;

        token.burnFromAddress(msg.sender);
    }

     
    function refundIco() public {
        require(hasIcoFailed);

        require(icoPurchases[msg.sender].burnableTiqs > 0 && icoPurchases[msg.sender].refundableWei > 0);
        
        uint256 amountWei = icoPurchases[msg.sender].refundableWei;
        msg.sender.transfer(amountWei);

        icoPurchases[msg.sender].refundableWei = 0;
        icoPurchases[msg.sender].burnableTiqs = 0;

        token.burnFromAddress(msg.sender);
    }

     
    function burnTokens(address _address) onlyOwner public {
        require(hasIcoFailed);

        require(icoPurchases[_address].burnableTiqs > 0 || preIcoPurchases[_address].burnableTiqs > 0);

        icoPurchases[_address].burnableTiqs = 0;
        preIcoPurchases[_address].burnableTiqs = 0;

        token.burnFromAddress(_address);
    }

     
    function manualSendTokens(address _address, uint256 _tokensAmount) whenWhitelisted(_address) public onlyPrivilegedAddresses {
        require(_tokensAmount > 0);
        
        if (isPreIco() && _tokensAmount <= tokensRemainingPreIco) {
            token.transferFromIco(_address, _tokensAmount);

            addPreIcoPurchaseInfo(_address, 0, _tokensAmount);
        } else if (isIco() && _tokensAmount <= tokensRemainingIco && soldTokensPreIco >= MINCAP_TOKENS_PRE_ICO) {
            token.transferFromIco(_address, _tokensAmount);

            addIcoPurchaseInfo(_address, 0, _tokensAmount);
        } else {
            revert();
        }
    }

     
    function getLockedContractAddress(address wallet) public view returns(address) {
        return lockedList[wallet];
    }

     
    function triggerFailFlags() onlyOwner public {
        if (!hasPreIcoFailed && now > endTimePreIco && soldTokensPreIco < MINCAP_TOKENS_PRE_ICO) {
            hasPreIcoFailed = true;
        }

        if (!hasIcoFailed && now > endTimeIco && soldTokensIco < MINCAP_TOKENS_ICO) {
            hasIcoFailed = true;
        }
    }

     
    function currentIcoRate() public view returns(uint256) {     
        if (now > startTimeIco && now <= startTimeIco + 5 days) {
            return firstRate;
        }

        if (now > startTimeIco + 5 days && now <= startTimeIco + 10 days) {
            return secondRate;
        }

        if (now > startTimeIco + 10 days) {
            return thirdRate;
        }
    }

     
    function sellTokens() whenWhitelisted(msg.sender) whenNotPaused public payable {
        require(msg.value > 0);
        
        bool preIco = isPreIco();
        bool ico = isIco();

        if (ico) {require(soldTokensPreIco >= MINCAP_TOKENS_PRE_ICO);}
        
        require((preIco && tokensRemainingPreIco > 0) || (ico && tokensRemainingIco > 0));
        
        uint256 currentRate = preIco ? preIcoRate : currentIcoRate();
        
        uint256 weiAmount = msg.value;
        uint256 tokensAmount = weiAmount.mul(currentRate);

        require(tokensAmount >= MIN_INVESTMENT);

        if (ico) {
             
            if (tokensRemainingPreIco > 0) {
                tokensRemainingIco = tokensRemainingIco.add(tokensRemainingPreIco);
                tokensRemainingPreIco = 0;
            }
        }
       
        uint256 tokensRemaining = preIco ? tokensRemainingPreIco : tokensRemainingIco;
        if (tokensAmount > tokensRemaining) {
            uint256 tokensRemainder = tokensAmount.sub(tokensRemaining);
            tokensAmount = tokensAmount.sub(tokensRemainder);
            
            uint256 overpaidWei = tokensRemainder.div(currentRate);
            msg.sender.transfer(overpaidWei);

            weiAmount = msg.value.sub(overpaidWei);
        }

        token.transferFromIco(msg.sender, tokensAmount);

        if (preIco) {
            addPreIcoPurchaseInfo(msg.sender, weiAmount, tokensAmount);

            if (soldTokensPreIco >= MINCAP_TOKENS_PRE_ICO) {
                owner.transfer(this.balance);
            }
        }

        if (ico) {
            addIcoPurchaseInfo(msg.sender, weiAmount, tokensAmount);

            if (soldTokensIco >= MINCAP_TOKENS_ICO) {
                owner.transfer(this.balance);
            }
        }
    }

     
    function addPreIcoPurchaseInfo(address _address, uint256 _amountWei, uint256 _amountTokens) internal {
        preIcoPurchases[_address].refundableWei = preIcoPurchases[_address].refundableWei.add(_amountWei);
        preIcoPurchases[_address].burnableTiqs = preIcoPurchases[_address].burnableTiqs.add(_amountTokens);

        soldTokensPreIco = soldTokensPreIco.add(_amountTokens);
        tokensRemainingPreIco = tokensRemainingPreIco.sub(_amountTokens);

        weiRaisedPreIco = weiRaisedPreIco.add(_amountWei);

        soldTokensTotal = soldTokensTotal.add(_amountTokens);
        weiRaisedTotal = weiRaisedTotal.add(_amountWei);
    }

     
    function addIcoPurchaseInfo(address _address, uint256 _amountWei, uint256 _amountTokens) internal {
        icoPurchases[_address].refundableWei = icoPurchases[_address].refundableWei.add(_amountWei);
        icoPurchases[_address].burnableTiqs = icoPurchases[_address].burnableTiqs.add(_amountTokens);

        soldTokensIco = soldTokensIco.add(_amountTokens);
        tokensRemainingIco = tokensRemainingIco.sub(_amountTokens);

        weiRaisedIco = weiRaisedIco.add(_amountWei);

        soldTokensTotal = soldTokensTotal.add(_amountTokens);
        weiRaisedTotal = weiRaisedTotal.add(_amountWei);
    }

     
    function lockTokens(address _wallet, uint256 _amount, uint256 _time) internal {
        LockedOutTokens locked = new LockedOutTokens(_wallet, token, endTimePreIco, 1, _amount, _time);
        lockedList[_wallet] = locked;
        token.transferFromIco(locked, _amount);
    }

     
    function setBackendAddress(address _backendAddress) public onlyOwner {
        require(_backendAddress != address(0));
        backendAddress = _backendAddress;
    }

     
    modifier onlyPrivilegedAddresses() {
        require(msg.sender == owner || msg.sender == backendAddress);
        _;
    }
}