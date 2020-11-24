 

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

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

 

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
  string public constant ROLE_ADMIN = "admin";

   
  function RBAC()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
  }

   
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

   
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

   
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

   
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

   
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
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

 

contract PausableToken is StandardToken, Pausable, RBAC {

    string public constant ROLE_ADMINISTRATOR = "administrator";

    modifier whenNotPausedOrAuthorized() {
        require(!paused || hasRole(msg.sender, ROLE_ADMINISTRATOR));
        _;
    }
     
    function addAdministrator(address _administrator) onlyOwner public returns (bool) {
        if (isAdministrator(_administrator)) {
            return false;
        } else {
            addRole(_administrator, ROLE_ADMINISTRATOR);
            return true;
        }
    }

     
    function removeAdministrator(address _administrator) onlyOwner public returns (bool) {
        if (isAdministrator(_administrator)) {
            removeRole(_administrator, ROLE_ADMINISTRATOR);
            return true;
        } else {
            return false;
        }
    }

     
    function isAdministrator(address _administrator) public view returns (bool) {
        return hasRole(_administrator, ROLE_ADMINISTRATOR);
    }

     
    function transfer(address _to, uint256 _value) public whenNotPausedOrAuthorized returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPausedOrAuthorized returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

 

contract CurrentToken is PausableToken {
    string constant public name = "CurrentCoin";
    string constant public symbol = "CUR";
    uint8 constant public decimals = 18;

    uint256 constant public INITIAL_TOTAL_SUPPLY = 1e11 * (uint256(10) ** decimals);

     
    function CurrentToken() public {
        totalSupply_ = totalSupply_.add(INITIAL_TOTAL_SUPPLY);
        balances[msg.sender] = totalSupply_;
        Transfer(address(0), msg.sender, totalSupply_);

        pause();
    }
}

 

 
contract VariableTimeBonusRate {
    using SafeMath for uint256;

     
    struct RateModifier {
         
        uint256 ratePermilles;

         
        uint256 start;
    }

    RateModifier[] private modifiers;

     
    function currentModifier() public view returns (uint256 rateModifier) {
         
        uint256 comparisonVariable = now;
        for (uint i = 0; i < modifiers.length; i++) {
            if (comparisonVariable >= modifiers[i].start) {
                rateModifier = modifiers[i].ratePermilles;
            }
        }
    }

    function getRateModifierInPermilles() public view returns (uint256) {
        return currentModifier();
    }

     
    function pushModifier(RateModifier _rateModifier) internal {
        require(modifiers.length == 0 || _rateModifier.start > modifiers[modifiers.length - 1].start);
        modifiers.push(_rateModifier);
    }
}

 

contract TokenRate is VariableTimeBonusRate {

    uint256 constant public REFERRED_BONUS_PERMILLE  = 5;
    uint256 constant public REFERRAL_BONUS_PERMILLE = 50;

    uint256 public rate;

    function TokenRate(uint256 _rate) public {
        rate = _rate;
    }

    function getCurrentBuyerRateInPermilles(bool isReferred) view public returns (uint256) {
        uint256 permillesRate = VariableTimeBonusRate.getRateModifierInPermilles();
        if (isReferred) {
            permillesRate = permillesRate.add(REFERRED_BONUS_PERMILLE);
        }
        return permillesRate.add(1000);
    }

     
    function _getTokenAmountForBuyer(uint256 _weiAmount, bool isReferred) internal view returns (uint256) {
        return _weiAmount.mul(rate).mul(getCurrentBuyerRateInPermilles(isReferred)).div(1000);
    }

    function _getTokenAmountForReferral(uint256 _weiAmount, bool isReferred) internal view returns (uint256) {
        if (isReferred) {
            return _weiAmount.mul(rate).mul(REFERRAL_BONUS_PERMILLE).div(1000);
        }
        return 0;
    }

     
    function _getWeiValueOfTokens(uint256 _tokensLeft, bool isReferred) internal view returns (uint256) {
        uint256 permillesRate = getCurrentBuyerRateInPermilles(isReferred);
        if (isReferred) {
            permillesRate = permillesRate.add(REFERRAL_BONUS_PERMILLE);
        }
        uint256 tokensToBuy = _tokensLeft.mul(1000).div(permillesRate);
        return tokensToBuy.div(rate);
    }

}

 

 
contract Whitelist is Ownable {
    mapping(address => bool) whitelist;

    uint256 public whitelistLength = 0;

       
    function addWallet(address _wallet) onlyOwner public {
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

      
    function isWhitelisted(address _wallet) constant public returns (bool) {
        return whitelist[_wallet];
    }

}

 

contract CurrentCrowdsale is Pausable, TokenRate {
    using SafeMath for uint256;

    uint256 constant private DECIMALS = 18;
    uint256 constant public HARDCAP_TOKENS_PRE_ICO = 100e6 * (10 ** DECIMALS);
    uint256 constant public HARDCAP_TOKENS_ICO = 499e8 * (10 ** DECIMALS);

    uint256 public startPhase1 = 0;
    uint256 public startPhase2 = 0;
    uint256 public startPhase3 = 0;
    uint256 public endOfPhase3 = 0;

    uint256 public maxcap = 0;

    uint256 public tokensSoldIco = 0;
    uint256 public tokensRemainingIco = HARDCAP_TOKENS_ICO;
    uint256 public tokensSoldTotal = 0;

    uint256 public weiRaisedIco = 0;
    uint256 public weiRaisedTotal = 0;

    address private withdrawalWallet;

    CurrentToken public token;
    Whitelist public whitelist;

    modifier beforeReachingHardCap() {
        require(tokensRemainingIco > 0 && weiRaisedIco < maxcap);
        _;
    }

    modifier whenWhitelisted(address _wallet) {
        require(whitelist.isWhitelisted(_wallet));
        _;
    }

     
    function CurrentCrowdsale(
        uint256 _maxcap,
        uint256 _startPhase1,
        uint256 _startPhase2,
        uint256 _startPhase3,
        uint256 _endOfPhase3,
        address _withdrawalWallet,
        uint256 _rate,
        CurrentToken _token,
        Whitelist _whitelist
    )  TokenRate(_rate) public
    {
        require(_withdrawalWallet != address(0));
        require(_token != address(0) && _whitelist != address(0));
        require(_startPhase1 >= now);
        require(_endOfPhase3 > _startPhase3);
        require(_maxcap > 0);

        token = _token;
        whitelist = _whitelist;

        startPhase1 = _startPhase1;
        startPhase2 = _startPhase2;
        startPhase3 = _startPhase3;
        endOfPhase3 = _endOfPhase3;

        withdrawalWallet = _withdrawalWallet;

        maxcap = _maxcap;
        tokensSoldTotal = HARDCAP_TOKENS_PRE_ICO;
        weiRaisedTotal = tokensSoldTotal.div(_rate.mul(2));

        pushModifier(RateModifier(200, startPhase1));
        pushModifier(RateModifier(150, startPhase2));
        pushModifier(RateModifier(100, startPhase3));
    }

     
    function() public payable {
        if (isIco()) {
            sellTokensIco();
        } else {
            revert();
        }
    }

     
    function isIco() public constant returns (bool) {
        return now >= startPhase1 && now <= endOfPhase3;
    }

    function sellTokensIco() beforeReachingHardCap whenWhitelisted(msg.sender) whenNotPaused public payable {
        sellTokens(address(0));
    }

    function sellTokensIcoWithReferal(address referral) beforeReachingHardCap whenWhitelisted(msg.sender) whenNotPaused public payable {
        if (referral != msg.sender && whitelist.isWhitelisted(referral)) {
            sellTokens(referral);
        } else {
            revert();
        }
    }

     
    function manualSendTokens(address _beneficiary, uint256 _tokensAmount) public  onlyOwner {
        require(_beneficiary != address(0));
        require(_tokensAmount > 0);

        token.transfer(_beneficiary, _tokensAmount);
        tokensSoldIco = tokensSoldIco.add(_tokensAmount);
        tokensSoldTotal = tokensSoldTotal.add(_tokensAmount);
        tokensRemainingIco = tokensRemainingIco.sub(_tokensAmount);
    }

     
    function sellTokens(address referral) beforeReachingHardCap whenWhitelisted(msg.sender) whenNotPaused internal {
        require(isIco());
        require(msg.value > 0);

        uint256 weiAmount = msg.value;
        uint256 excessiveFunds = 0;

        uint256 plannedWeiTotal = weiRaisedIco.add(weiAmount);

        if (plannedWeiTotal > maxcap) {
            excessiveFunds = plannedWeiTotal.sub(maxcap);
            weiAmount = maxcap.sub(weiRaisedIco);
        }
        bool isReferred = referral != address(0);
        uint256 tokensForUser = _getTokenAmountForBuyer(weiAmount, isReferred);
        uint256 tokensForReferral = _getTokenAmountForReferral(weiAmount, isReferred);
        uint256 tokensAmount = tokensForUser.add(tokensForReferral);

        if (tokensAmount > tokensRemainingIco) {
            uint256 weiToAccept = _getWeiValueOfTokens(tokensRemainingIco, isReferred);
            tokensForReferral = _getTokenAmountForReferral(weiToAccept, isReferred);
            tokensForUser = tokensRemainingIco.sub(tokensForReferral);
            excessiveFunds = excessiveFunds.add(weiAmount.sub(weiToAccept));

            tokensAmount = tokensRemainingIco;
            weiAmount = weiToAccept;
        }

        tokensSoldIco = tokensSoldIco.add(tokensAmount);
        tokensSoldTotal = tokensSoldTotal.add(tokensAmount);
        tokensRemainingIco = tokensRemainingIco.sub(tokensAmount);

        weiRaisedIco = weiRaisedIco.add(weiAmount);
        weiRaisedTotal = weiRaisedTotal.add(weiAmount);

        token.transfer(msg.sender, tokensForUser);
        if (isReferred) {
            token.transfer(referral, tokensForReferral);
        }

        if (excessiveFunds > 0) {
            msg.sender.transfer(excessiveFunds);
        }

        withdrawalWallet.transfer(this.balance);
    }
}