 

pragma solidity ^0.4.24;

 

 
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

 

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 

 
contract KYCWhitelist is Claimable {

    mapping(address => bool) public whitelist;

     
    modifier isWhitelisted(address _beneficiary) {
        require(whitelist[_beneficiary]);
        _;
    }

     
    function validateWhitelisted(address _beneficiary) internal view {
        require(whitelist[_beneficiary]);
    }

     
    function addToWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = true;
        emit addToWhiteListE(_beneficiary);
    }
    
     

    event addToWhiteListE(address _beneficiary);

     


     
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

     
    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = false;
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

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract PrivatePreSale is Claimable, KYCWhitelist, Pausable {
    using SafeMath for uint256;

  
     
    address public FUNDS_WALLET = 0xDc17D222Bc3f28ecE7FCef42EDe0037C739cf28f;
     
    address public TOKEN_WALLET = 0x1EF91464240BB6E0FdE7a73E0a6f3843D3E07601;
     
    ERC20 public TOKEN = ERC20(0x6737fE98389Ffb356F64ebB726aA1a92390D94Fb);
     
    address public LOCKUP_WALLET = 0xaB18B66F75D13a38158f9946662646105C3bC45D;
     
    uint256 public constant TOKENS_PER_ETH = 650;
     
    uint256 public MAX_TOKENS = 20000000 * (10**18);
     
    uint256 public MIN_TOKEN_INVEST = 97500 * (10**18);
     
    uint256 public START_DATE = 1542888000;

     
     
     

     
    uint256 public weiRaised;
     
    uint256 public tokensIssued;
     
    bool public closed;

     
     
     

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


     
    constructor() public {
        assert(FUNDS_WALLET != address(0));
        assert(TOKEN != address(0));
        assert(TOKEN_WALLET != address(0));
        assert(LOCKUP_WALLET != address(0));
        assert(MAX_TOKENS > 0);
        assert(MIN_TOKEN_INVEST >= 0);
    }

     
     
     

     
    function capReached() public view returns (bool) {
        return tokensIssued >= MAX_TOKENS;
    }

     
    function closeSale() public onlyOwner {
        assert(!closed);
        closed = true;
    }

     
    function getTokenAmount(uint256 _weiAmount) public pure returns (uint256) {
         
        return _weiAmount.mul(TOKENS_PER_ETH);
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
     
     

     
    function buyTokens(address _beneficiary) internal whenNotPaused {

        uint256 weiAmount = msg.value;

         
        uint256 tokenAmount = getTokenAmount(weiAmount);

         
        preValidateChecks(_beneficiary, weiAmount, tokenAmount);
        
        

         
        tokensIssued = tokensIssued.add(tokenAmount);
        weiRaised = weiRaised.add(weiAmount);

         
        TOKEN.transferFrom(TOKEN_WALLET, LOCKUP_WALLET, tokenAmount);       

         
        FUNDS_WALLET.transfer(msg.value);

         
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokenAmount);
    }

     
    function preValidateChecks(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) internal view {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(now >= START_DATE);
        require(!closed);

         
        validateWhitelisted(_beneficiary);

         
        require(_tokenAmount >= MIN_TOKEN_INVEST);

         
        require(tokensIssued.add(_tokenAmount) <= MAX_TOKENS);
    }
}