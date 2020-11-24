 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
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






 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
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



contract Time {
     
    function _currentTime() internal view returns (uint256) {
        return block.timestamp;
    }
}




 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    view
    public
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    view
    public
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}



 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}



contract Lockable {
     
    mapping(address => uint256) public lockedValues;

     
    function _lock(address _for, uint256 _value) internal {
        require(_for != address(0) && _value > 0, "Invalid lock operation configuration.");

        if (_value != lockedValues[_for]) {
            lockedValues[_for] = _value;
        }
    }

     
    function _unlock(address _for) internal {
        require(_for != address(0), "Invalid unlock operation configuration.");
        
        if (lockedValues[_for] != 0) {
            lockedValues[_for] = 0;
        }
    }
}











contract Operable is Ownable, RBAC {
     
    string public constant ROLE_OPERATOR = "operator";

     
    modifier hasOwnerOrOperatePermission() {
        require(msg.sender == owner || hasRole(msg.sender, ROLE_OPERATOR), "Access denied.");
        _;
    }

     
    function operator(address _operator) public view returns (bool) {
        return hasRole(_operator, ROLE_OPERATOR);
    }

     
    function addOperator(address _operator) public onlyOwner {
        addRole(_operator, ROLE_OPERATOR);
    }

     
    function removeOperator(address _operator) public onlyOwner {
        removeRole(_operator, ROLE_OPERATOR);
    }
}






contract Withdrawal is Ownable {
     
    address public withdrawWallet;

     
    event WithdrawLog(uint256 value);

     
    constructor(address _withdrawWallet) public {
        require(_withdrawWallet != address(0), "Invalid funds holder wallet.");

        withdrawWallet = _withdrawWallet;
    }

     
    function withdrawAll() external onlyOwner {
        uint256 weiAmount = address(this).balance;
      
        withdrawWallet.transfer(weiAmount);
        emit WithdrawLog(weiAmount);
    }

     
    function withdraw(uint256 _weiAmount) external onlyOwner {
        require(_weiAmount <= address(this).balance, "Not enough funds.");

        withdrawWallet.transfer(_weiAmount);
        emit WithdrawLog(_weiAmount);
    }
}








contract PriceStrategy is Time, Operable {
    using SafeMath for uint256;

     
    struct Stage {
        uint256 start;
        uint256 end;
        uint256 volume;
        uint256 priceInCHF;
        uint256 minBonusVolume;
        uint256 bonus;
        bool lock;
    }

     
    struct LockupPeriod {
        uint256 expires;
        uint256 bonus;
    }

     
    Stage[] public stages;

     
    mapping(uint256 => LockupPeriod) public lockupPeriods;

     
    uint256 public constant decimalsCHF = 18;

     
    uint256 public minInvestmentInCHF;

     
    uint256 public rateETHtoCHF;

     
    event RateChangedLog(uint256 newRate);

     
    constructor(uint256 _rateETHtoCHF, uint256 _minInvestmentInCHF) public {
        require(_minInvestmentInCHF > 0, "Minimum investment can not be set to 0.");        
        minInvestmentInCHF = _minInvestmentInCHF;

        setETHtoCHFrate(_rateETHtoCHF);

         
        stages.push(Stage({
            start: 1536969600,  
            end: 1542239999,  
            volume: uint256(25000000000).mul(10 ** 18),  
            priceInCHF: uint256(2).mul(10 ** 14),  
            minBonusVolume: 0,
            bonus: 0,
            lock: false
        }));

         
        stages.push(Stage({
            start: 1542240000,  
            end: 1550188799,  
            volume: uint256(65000000000).mul(10 ** 18),  
            priceInCHF: uint256(4).mul(10 ** 14),  
            minBonusVolume: uint256(400000000).mul(10 ** 18),  
            bonus: 2000,  
            lock: true
        }));

        _setLockupPeriod(1550188799, 18, 3000);  
        _setLockupPeriod(1550188799, 12, 2000);  
        _setLockupPeriod(1550188799, 6, 1000);  
    }

     
    function setETHtoCHFrate(uint256 _rateETHtoCHF) public hasOwnerOrOperatePermission {
        require(_rateETHtoCHF > 0, "Rate can not be set to 0.");        
        rateETHtoCHF = _rateETHtoCHF;
        emit RateChangedLog(rateETHtoCHF);
    }

     
    function getTokensAmount(uint256 _wei, uint256 _lockup, uint256 _sold) public view returns (uint256 tokens, uint256 bonus) { 
        uint256 chfAmount = _wei.mul(rateETHtoCHF).div(10 ** decimalsCHF);
        require(chfAmount >= minInvestmentInCHF, "Investment value is below allowed minimum.");

        Stage memory currentStage = _getCurrentStage();
        require(currentStage.priceInCHF > 0, "Invalid price value.");        

        tokens = chfAmount.mul(10 ** decimalsCHF).div(currentStage.priceInCHF);

        uint256 bonusSize;
        if (tokens >= currentStage.minBonusVolume) {
            bonusSize = currentStage.bonus.add(lockupPeriods[_lockup].bonus);
        } else {
            bonusSize = lockupPeriods[_lockup].bonus;
        }

        bonus = tokens.mul(bonusSize).div(10 ** 4);

        uint256 total = tokens.add(bonus);
        require(currentStage.volume > _sold.add(total), "Not enough tokens available.");
    }    

     
    function _getCurrentStage() internal view returns (Stage) {
        uint256 index = 0;
        uint256 time = _currentTime();

        Stage memory result;

        while (index < stages.length) {
            Stage memory stage = stages[index];

            if ((time >= stage.start && time <= stage.end)) {
                result = stage;
                break;
            }

            index++;
        }

        return result;
    } 

     
    function _setLockupPeriod(uint256 _startPoint, uint256 _period, uint256 _bonus) private {
        uint256 expires = _startPoint.add(_period.mul(2628000));
        lockupPeriods[_period] = LockupPeriod({
            expires: expires,
            bonus: _bonus
        });
    }
}















contract BaseCrowdsale {
    using SafeMath for uint256;
    using SafeERC20 for CosquareToken;

     
    CosquareToken public token;
     
    uint256 public tokensSold;

     
    event TokensPurchaseLog(string purchaseType, address indexed beneficiary, uint256 value, uint256 tokens, uint256 bonuses);

     
    constructor(CosquareToken _token) public {
        require(_token != address(0), "Invalid token address.");
        token = _token;
    }

     
    function () external payable {
        require(msg.data.length == 0, "Should not accept data.");
        _buyTokens(msg.sender, msg.value, "ETH");
    }

     
    function buyTokens(address _beneficiary) external payable {
        _buyTokens(_beneficiary, msg.value, "ETH");
    }

     
    function _buyTokens(address _beneficiary, uint256 _amount, string _investmentType) internal {
        _preValidatePurchase(_beneficiary, _amount);

        (uint256 tokensAmount, uint256 tokenBonus) = _getTokensAmount(_beneficiary, _amount);

        uint256 totalAmount = tokensAmount.add(tokenBonus);

        _processPurchase(_beneficiary, totalAmount);
        emit TokensPurchaseLog(_investmentType, _beneficiary, _amount, tokensAmount, tokenBonus);        
        
        _postPurchaseUpdate(_beneficiary, totalAmount);
    }  

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0), "Invalid beneficiary address.");
        require(_weiAmount > 0, "Invalid investment value.");
    }

     
    function _getTokensAmount(address _beneficiary, uint256 _weiAmount) internal view returns (uint256 tokens, uint256 bonus);

     
    function _processPurchase(address _beneficiary, uint256 _tokensAmount) internal {
        _deliverTokens(_beneficiary, _tokensAmount);
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokensAmount) internal {
        token.safeTransfer(_beneficiary, _tokensAmount);
    }

     
    function _postPurchaseUpdate(address _beneficiary, uint256 _tokensAmount) internal {
        tokensSold = tokensSold.add(_tokensAmount);
    }
}



contract LockableCrowdsale is Time, Lockable, Operable, PriceStrategy, BaseCrowdsale {
    using SafeMath for uint256;

     
    function lockNextPurchase(address _beneficiary, uint256 _lockupPeriod) external hasOwnerOrOperatePermission {
        require(_lockupPeriod == 6 || _lockupPeriod == 12 || _lockupPeriod == 18, "Invalid lock interval");
        Stage memory currentStage = _getCurrentStage();
        require(currentStage.lock, "Lock operation is not allowed.");
        _lock(_beneficiary, _lockupPeriod);      
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokensAmount) internal {
        super._processPurchase(_beneficiary, _tokensAmount);
        uint256 lockedValue = lockedValues[_beneficiary];

        if (lockedValue > 0) {
            uint256 expires = lockupPeriods[lockedValue].expires;
            token.lock(_beneficiary, _tokensAmount, expires);
        }
    }

     
    function _getTokensAmount(address _beneficiary, uint256 _weiAmount) internal view returns (uint256 tokens, uint256 bonus) { 
        (tokens, bonus) = getTokensAmount(_weiAmount, lockedValues[_beneficiary], tokensSold);
    }

     
    function _postPurchaseUpdate(address _beneficiary, uint256 _tokensAmount) internal {
        super._postPurchaseUpdate(_beneficiary, _tokensAmount);

        _unlock(_beneficiary);
    }
}










contract Whitelist is RBAC, Operable {
     
    string public constant ROLE_WHITELISTED = "whitelist";

     
    modifier onlyIfWhitelisted(address _operator) {
        checkRole(_operator, ROLE_WHITELISTED);
        _;
    }

     
    function addAddressToWhitelist(address _operator) public hasOwnerOrOperatePermission {
        addRole(_operator, ROLE_WHITELISTED);
    }

     
    function whitelist(address _operator) public view returns (bool) {
        return hasRole(_operator, ROLE_WHITELISTED);
    }

     
    function addAddressesToWhitelist(address[] _operators) public hasOwnerOrOperatePermission {
        for (uint256 i = 0; i < _operators.length; i++) {
            addAddressToWhitelist(_operators[i]);
        }
    }

     
    function removeAddressFromWhitelist(address _operator) public hasOwnerOrOperatePermission {
        removeRole(_operator, ROLE_WHITELISTED);
    }

     
    function removeAddressesFromWhitelist(address[] _operators) public hasOwnerOrOperatePermission {
        for (uint256 i = 0; i < _operators.length; i++) {
            removeAddressFromWhitelist(_operators[i]);
        }
    }
}



contract WhitelistedCrowdsale is Whitelist, BaseCrowdsale {
     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyIfWhitelisted(_beneficiary) {
        super._preValidatePurchase(_beneficiary, _weiAmount);
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}




contract PausableCrowdsale is Pausable, BaseCrowdsale {
     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal whenNotPaused {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}










 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
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




 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}






contract CosquareToken is Time, StandardToken, DetailedERC20, Ownable {
    using SafeMath for uint256;

     
    struct LockedBalance {
        uint256 expires;
        uint256 value;
    }

     
    mapping(address => LockedBalance[]) public lockedBalances;

     
    address public saleWallet;
     
    address public reserveWallet;
     
    address public teamWallet;
     
    address public strategicWallet;

     
    uint256 public lockEndpoint;

     
    event LockLog(address indexed who, uint256 value, uint256 expires);

     
    constructor(address _saleWallet, address _reserveWallet, address _teamWallet, address _strategicWallet, uint256 _lockEndpoint) 
      DetailedERC20("cosquare", "CSQ", 18) public {
        require(_lockEndpoint > 0, "Invalid global lock end date.");
        lockEndpoint = _lockEndpoint;

        _configureWallet(_saleWallet, 65000000000000000000000000000);  
        saleWallet = _saleWallet;
        _configureWallet(_reserveWallet, 15000000000000000000000000000);  
        reserveWallet = _reserveWallet;
        _configureWallet(_teamWallet, 15000000000000000000000000000);  
        teamWallet = _teamWallet;
        _configureWallet(_strategicWallet, 5000000000000000000000000000);  
        strategicWallet = _strategicWallet;
    }

     
    function _configureWallet(address _wallet, uint256 _amount) private {
        require(_wallet != address(0), "Invalid wallet address.");

        totalSupply_ = totalSupply_.add(_amount);
        balances[_wallet] = _amount;
        emit Transfer(address(0), _wallet, _amount);
    }

     
    modifier notLocked(address _who, uint256 _value) {
        uint256 time = _currentTime();

        if (lockEndpoint > time) {
            uint256 index = 0;
            uint256 locked = 0;
            while (index < lockedBalances[_who].length) {
                if (lockedBalances[_who][index].expires > time) {
                    locked = locked.add(lockedBalances[_who][index].value);
                }

                index++;
            }

            require(_value <= balances[_who].sub(locked), "Not enough unlocked tokens");
        }        
        _;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public notLocked(_from, _value) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public notLocked(msg.sender, _value) returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function lockedBalanceOf(address _owner, uint256 _expires) external view returns (uint256) {
        uint256 time = _currentTime();
        uint256 index = 0;
        uint256 locked = 0;

        if (lockEndpoint > time) {       
            while (index < lockedBalances[_owner].length) {
                if (_expires > 0) {
                    if (lockedBalances[_owner][index].expires == _expires) {
                        locked = locked.add(lockedBalances[_owner][index].value);
                    }
                } else {
                    if (lockedBalances[_owner][index].expires >= time) {
                        locked = locked.add(lockedBalances[_owner][index].value);
                    }
                }

                index++;
            }
        }

        return locked;
    }

     
    function lock(address _who, uint256 _value, uint256 _expires) public onlyOwner {
        uint256 time = _currentTime();
        require(_who != address(0) && _value <= balances[_who] && _expires > time, "Invalid lock configuration.");

        uint256 index = 0;
        bool exist = false;
        while (index < lockedBalances[_who].length) {
            if (lockedBalances[_who][index].expires == _expires) {
                exist = true;
                break;
            }

            index++;
        }

        if (exist) {
            lockedBalances[_who][index].value = lockedBalances[_who][index].value.add(_value);
        } else {
            lockedBalances[_who].push(LockedBalance({
                expires: _expires,
                value: _value
            }));
        }

        emit LockLog(_who, _value, _expires);
    }
}


contract Crowdsale is Lockable, Operable, Withdrawal, PriceStrategy, LockableCrowdsale, WhitelistedCrowdsale, PausableCrowdsale {
    using SafeMath for uint256;

     
    constructor(uint256 _rateETHtoCHF, uint256 _minInvestmentInCHF, address _withdrawWallet, CosquareToken _token)
        PriceStrategy(_rateETHtoCHF, _minInvestmentInCHF)
        Withdrawal(_withdrawWallet)
        BaseCrowdsale(_token) public {
    }  

     
    function distributeTokensForInvestment(address _beneficiary, uint256 _ethAmount, string _type) public hasOwnerOrOperatePermission {
        _buyTokens(_beneficiary, _ethAmount, _type);
    }

     
    function distributeTokensManual(address _beneficiary, uint256 _tokensAmount) external hasOwnerOrOperatePermission {
        _preValidatePurchase(_beneficiary, _tokensAmount);

        _deliverTokens(_beneficiary, _tokensAmount);
        emit TokensPurchaseLog("MANUAL", _beneficiary, 0, _tokensAmount, 0);

        _postPurchaseUpdate(_beneficiary, _tokensAmount);
    }
}