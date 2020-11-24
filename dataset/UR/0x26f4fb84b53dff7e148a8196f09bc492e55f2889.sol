 

pragma solidity ^0.4.24;

contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20Interface public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  constructor(uint256 _rate, address _wallet, ERC20Interface _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

contract ERC20Interface {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Standard is ERC20Interface {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

   
  function transfer(address _to, uint256 _value) external returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) external returns (bool) {
    require(allowed[msg.sender][_spender] == 0 || _value == 0);
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function totalSupply() external view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) external view returns (uint256 balance) {
    return balances[_owner];
  }

   
  function allowance(address _owner, address _spender) external view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) external returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract ERC223Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value, bytes data) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC223ReceivingContract { 
 
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract ERC223Standard is ERC223Interface, ERC20Standard {
    using SafeMath for uint256;

     
    function transfer(address _to, uint256 _value, bytes _data) external returns(bool){
         
         
        uint256 codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value);
    }
    
     
    function transfer(address _to, uint256 _value) external returns(bool){
        uint256 codeLength;
        bytes memory empty;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
 
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
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

contract MintableToken is ERC223Standard, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract PoolAndSaleInterface {
    address public tokenSaleAddr;
    address public votingAddr;
    address public votingTokenAddr;
    uint256 public tap;
    uint256 public initialTap;
    uint256 public initialRelease;

    function setTokenSaleContract(address _tokenSaleAddr) external;
    function startProject() external;
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
     
     
     
    return a / b;
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

contract TimeLockPool{
    using SafeMath for uint256;

    struct LockedBalance {
      uint256 balance;
      uint256 releaseTime;
    }

     
    mapping (address => mapping (address => LockedBalance[])) public lockedBalances;

    event Deposit(
        address indexed owner,
        address indexed tokenAddr,
        uint256 amount,
        uint256 releaseTime
    );

    event Withdraw(
        address indexed owner,
        address indexed tokenAddr,
        uint256 amount
    );

     
     
    constructor() public {}

     
     
     
     
     
     
    function depositERC20 (
        address tokenAddr,
        address account,
        uint256 amount,
        uint256 releaseTime
    ) external returns (bool) {
        require(account != address(0x0));
        require(tokenAddr != 0x0);
        require(msg.value == 0);
        require(amount > 0);
        require(ERC20Interface(tokenAddr).transferFrom(msg.sender, this, amount));

        lockedBalances[account][tokenAddr].push(LockedBalance(amount, releaseTime));
        emit Deposit(account, tokenAddr, amount, releaseTime);

        return true;
    }

     
     
     
     
    function depositETH (
        address account,
        uint256 releaseTime
    ) external payable returns (bool) {
        require(account != address(0x0));
        address tokenAddr = address(0x0);
        uint256 amount = msg.value;
        require(amount > 0);

        lockedBalances[account][tokenAddr].push(LockedBalance(amount, releaseTime));
        emit Deposit(account, tokenAddr, amount, releaseTime);

        return true;
    }

     
     
     
     
     
     
    function withdraw (address account, address tokenAddr, uint256 index_from, uint256 index_to) external returns (bool) {
        require(account != address(0x0));

        uint256 release_amount = 0;
        for (uint256 i = index_from; i < lockedBalances[account][tokenAddr].length && i < index_to + 1; i++) {
            if (lockedBalances[account][tokenAddr][i].balance > 0 &&
                lockedBalances[account][tokenAddr][i].releaseTime <= block.timestamp) {

                release_amount = release_amount.add(lockedBalances[account][tokenAddr][i].balance);
                lockedBalances[account][tokenAddr][i].balance = 0;
            }
        }

        require(release_amount > 0);

        if (tokenAddr == 0x0) {
            if (!account.send(release_amount)) {
                revert();
            }
            emit Withdraw(account, tokenAddr, release_amount);
            return true;
        } else {
            if (!ERC20Interface(tokenAddr).transfer(account, release_amount)) {
                revert();
            }
            emit Withdraw(account, tokenAddr, release_amount);
            return true;
        }
    }

     
     
     
     
    function getAvailableBalanceOf (address account, address tokenAddr) 
        external
        view
        returns (uint256)
    {
        require(account != address(0x0));

        uint256 balance = 0;
        for(uint256 i = 0; i < lockedBalances[account][tokenAddr].length; i++) {
            if (lockedBalances[account][tokenAddr][i].releaseTime <= block.timestamp) {
                balance = balance.add(lockedBalances[account][tokenAddr][i].balance);
            }
        }
        return balance;
    }

     
     
     
     
    function getLockedBalanceOf (address account, address tokenAddr)
        external
        view
        returns (uint256) 
    {
        require(account != address(0x0));

        uint256 balance = 0;
        for(uint256 i = 0; i < lockedBalances[account][tokenAddr].length; i++) {
            if(lockedBalances[account][tokenAddr][i].releaseTime > block.timestamp) {
                balance = balance.add(lockedBalances[account][tokenAddr][i].balance);
            }
        }
        return balance;
    }

     
     
     
     
    function getNextReleaseTimeOf (address account, address tokenAddr)
        external
        view
        returns (uint256) 
    {
        require(account != address(0x0));

        uint256 nextRelease = 2**256 - 1;
        for (uint256 i = 0; i < lockedBalances[account][tokenAddr].length; i++) {
            if (lockedBalances[account][tokenAddr][i].releaseTime > block.timestamp &&
               lockedBalances[account][tokenAddr][i].releaseTime < nextRelease) {

                nextRelease = lockedBalances[account][tokenAddr][i].releaseTime;
            }
        }

         
        if (nextRelease == 2**256 - 1) {
            nextRelease = 0;
        }
        return nextRelease;
    }
}

contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  constructor(uint256 _openingTime, uint256 _closingTime) public {
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }

}

contract TokenController is Ownable {
    using SafeMath for uint256;

    MintableToken public targetToken;
    address public votingAddr;
    address public tokensaleManagerAddr;

    State public state;

    enum State {
        Init,
        Tokensale,
        Public
    }

     
     
     
    constructor (
        MintableToken _targetToken
    ) public {
        targetToken = MintableToken(_targetToken);
        state = State.Init;
    }

     
     
     
     
    function mint (address to, uint256 amount) external returns (bool) {
         

        if ((state == State.Init && msg.sender == owner) ||
            (state == State.Tokensale && msg.sender == tokensaleManagerAddr)) {
            return targetToken.mint(to, amount);
        }

        revert();
    }

     
     
     
    function openTokensale (address _tokensaleManagerAddr)
        external
        onlyOwner
        returns (bool)
    {
         
        require(MintableToken(targetToken).owner() == address(this));
        require(state == State.Init);
        require(_tokensaleManagerAddr != address(0x0));

        tokensaleManagerAddr = _tokensaleManagerAddr;
        state = State.Tokensale;
        return true;
    }

     
     
     
     
    function closeTokensale () external returns (bool) {
        require(state == State.Tokensale && msg.sender == tokensaleManagerAddr);

        state = State.Public;
        return true;
    }

     
     
    function isStateInit () external view returns (bool) {
        return (state == State.Init);
    }

     
     
    function isStateTokensale () external view returns (bool) {
        return (state == State.Tokensale);
    }

     
     
    function isStatePublic () external view returns (bool) {
        return (state == State.Public);
    }
}

contract TokenSaleManager is Ownable {
    using SafeMath for uint256;

    ERC20Interface public token;
    address public poolAddr;
    address public tokenControllerAddr;
    address public timeLockPoolAddr;
    address[] public tokenSales;
    mapping( address => bool ) public tokenSaleIndex;
    bool public isStarted = false;
    bool public isFinalized = false;

    modifier onlyDaicoPool {
        require(msg.sender == poolAddr);
        _;
    }

    modifier onlyTokenSale {
        require(tokenSaleIndex[msg.sender]);
        _;
    }

     
     
     
     
     
    constructor (
        address _tokenControllerAddr,
        address _timeLockPoolAddr,
        address _daicoPoolAddr,
        ERC20Interface _token
    ) public {
        require(_tokenControllerAddr != address(0x0));
        tokenControllerAddr = _tokenControllerAddr;

        require(_timeLockPoolAddr != address(0x0));
        timeLockPoolAddr = _timeLockPoolAddr;

        token = _token;

        poolAddr = _daicoPoolAddr;
        require(PoolAndSaleInterface(poolAddr).votingTokenAddr() == address(token));
        PoolAndSaleInterface(poolAddr).setTokenSaleContract(this);

    }

     
    function() external payable {
        revert();
    }

     
     
     
     
     
     
     
     
     
     
    function addTokenSale (
        uint256 openingTime,
        uint256 closingTime,
        uint256 tokensCap,
        uint256 rate,
        bool carryover,
        uint256 timeLockRate,
        uint256 timeLockEnd,
        uint256 minAcceptableWei
    ) external onlyOwner {
        require(!isStarted);
        require(
            tokenSales.length == 0 ||
            TimedCrowdsale(tokenSales[tokenSales.length-1]).closingTime() < openingTime
        );

        require(TokenController(tokenControllerAddr).state() == TokenController.State.Init);

        tokenSales.push(new TokenSale(
            rate,
            token,
            poolAddr,
            openingTime,
            closingTime,
            tokensCap,
            timeLockRate,
            timeLockEnd,
            carryover,
            minAcceptableWei
        ));
        tokenSaleIndex[tokenSales[tokenSales.length-1]] = true;

    }

     
     
    function initialize () external onlyOwner returns (bool) {
        require(!isStarted);
        TokenSale(tokenSales[0]).initialize(0);
        isStarted = true;
    }

     
     
     
     
     
    function mint (
        address _beneficiary,
        uint256 _tokenAmount
    ) external onlyTokenSale returns(bool) {
        require(isStarted && !isFinalized);
        require(TokenController(tokenControllerAddr).mint(_beneficiary, _tokenAmount));
        return true;
    }

     
     
     
     
     
    function mintTimeLocked (
        address _beneficiary,
        uint256 _tokenAmount,
        uint256 _releaseTime
    ) external onlyTokenSale returns(bool) {
        require(isStarted && !isFinalized);
        require(TokenController(tokenControllerAddr).mint(this, _tokenAmount));
        require(ERC20Interface(token).approve(timeLockPoolAddr, _tokenAmount));
        require(TimeLockPool(timeLockPoolAddr).depositERC20(
            token,
            _beneficiary,
            _tokenAmount,
            _releaseTime
        ));
        return true;
    }

     
     
    function addToWhitelist(address _beneficiary) external onlyOwner {
        require(isStarted);
        for (uint256 i = 0; i < tokenSales.length; i++ ) {
            WhitelistedCrowdsale(tokenSales[i]).addToWhitelist(_beneficiary);
        }
    }

     
     
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        require(isStarted);
        for (uint256 i = 0; i < tokenSales.length; i++ ) {
            WhitelistedCrowdsale(tokenSales[i]).addManyToWhitelist(_beneficiaries);
        }
    }


     
     
     
    function finalize (uint256 _indexTokenSale) external {
        require(isStarted && !isFinalized);
        TokenSale ts = TokenSale(tokenSales[_indexTokenSale]);

        if (ts.canFinalize()) {
            ts.finalize();
            uint256 carryoverAmount = 0;
            if (ts.carryover() &&
                ts.tokensCap() > ts.tokensMinted() &&
                _indexTokenSale.add(1) < tokenSales.length) {
                carryoverAmount = ts.tokensCap().sub(ts.tokensMinted());
            } 
            if(_indexTokenSale.add(1) < tokenSales.length) {
                TokenSale(tokenSales[_indexTokenSale.add(1)]).initialize(carryoverAmount);
            }
        }

    }

     
     
    function finalizeTokenSaleManager () external{
        require(isStarted && !isFinalized);
        for (uint256 i = 0; i < tokenSales.length; i++ ) {
            require(FinalizableCrowdsale(tokenSales[i]).isFinalized());
        }
        require(TokenController(tokenControllerAddr).closeTokensale());
        isFinalized = true;
        PoolAndSaleInterface(poolAddr).startProject();
    }
}

contract WhitelistedCrowdsale is Crowdsale, Ownable {

  mapping(address => bool) public whitelist;

   
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

   
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

   
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

contract TokenSale is FinalizableCrowdsale,
                      WhitelistedCrowdsale {
    using SafeMath for uint256;

    address public managerAddr; 
    address public poolAddr;
    bool public isInitialized = false;
    uint256 public timeLockRate;
    uint256 public timeLockEnd;
    uint256 public tokensMinted = 0;
    uint256 public tokensCap;
    uint256 public minAcceptableWei;
    bool public carryover;

    modifier onlyManager{
        require(msg.sender == managerAddr);
        _;
    }

     
     
     
     
     
     
     
     
     
     
     
     
    constructor (
        uint256 _rate,  
        ERC20Interface _token,
        address _poolAddr,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _tokensCap,
        uint256 _timeLockRate,
        uint256 _timeLockEnd,
        bool _carryover,
        uint256 _minAcceptableWei
    ) public Crowdsale(_rate, _poolAddr, _token) TimedCrowdsale(_openingTime, _closingTime) {
        require(_timeLockRate >= 0 && _timeLockRate <=100);
        require(_poolAddr != address(0x0));

        managerAddr = msg.sender;
        poolAddr = _poolAddr;
        timeLockRate = _timeLockRate;
        timeLockEnd = _timeLockEnd;
        tokensCap = _tokensCap;
        carryover = _carryover;
        minAcceptableWei = _minAcceptableWei;
    }

     
     
     
    function initialize(uint256 carryoverAmount) external onlyManager {
        require(!isInitialized);
        isInitialized = true;
        tokensCap = tokensCap.add(carryoverAmount);
    }

     
     
    function finalize() onlyOwner public {
         
        require(isInitialized);
        require(canFinalize());

        finalization();
        emit Finalized();

        isFinalized = true;
    }

     
     
    function canFinalize() public view returns(bool) {
        return (hasClosed() || (isInitialized && tokensCap <= tokensMinted));
    }


     
     
    function finalization() internal {
        if(address(this).balance > 0){
            poolAddr.transfer(address(this).balance);
        }
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
         
        require(tokensMinted < tokensCap);

        uint256 time_locked = _tokenAmount.mul(timeLockRate).div(100); 
        uint256 instant = _tokenAmount.sub(time_locked);

        if (instant > 0) {
            require(TokenSaleManager(managerAddr).mint(_beneficiary, instant));
        }
        if (time_locked > 0) {
            require(TokenSaleManager(managerAddr).mintTimeLocked(
                _beneficiary,
                time_locked,
                timeLockEnd
            ));
        }
  
        tokensMinted = tokensMinted.add(_tokenAmount);
    }

     
    function _forwardFunds() internal {}

     
     
     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(isInitialized);
        require(_weiAmount >= minAcceptableWei);
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
      return _weiAmount.mul(rate).div(10**18);  
    }

}