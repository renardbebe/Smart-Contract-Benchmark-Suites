 

pragma solidity 0.4.24;

 
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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    uint _addedValue
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
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

contract Token is StandardToken, BurnableToken, Ownable {

     
    using SafeMath for uint256;

     
    string public name = "MIMIC";
    string public symbol = "MIMIC";
    uint256 public decimals = 18;

     
    uint256 public INITIAL_SUPPLY = 900000000 * (10 ** decimals);

     
    address public constant ICO_ADDRESS        = 0x93Fc953BefEF145A92760476d56E45842CE00b2F;
    address public constant PRESALE_ADDRESS    = 0x3be448B6dD35976b58A9935A1bf165d5593F8F27;

     
    address public constant BACKUP_ONE     = 0x9146EE4eb69f92b1e59BE9C7b4718d6B75F696bE;
    address public constant BACKUP_TWO     = 0xe12F95964305a00550E1970c3189D6aF7DB9cFdd;
    address public constant BACKUP_FOUR    = 0x2FBF54a91535A5497c2aF3BF5F64398C4A9177a2;
    address public constant BACKUP_THREE   = 0xa41554b1c2d13F10504Cc2D56bF0Ba9f845C78AC;

     
    uint256 public lockStartDate = 0;
    uint256 public lockEndDate = 0;
    uint256 public lockAbsoluteDifference = 0;
    mapping (address => uint256) public initialLockedAmounts;

     
    bool public areTokensFree = false;

     
    event SetLockedAmount(address indexed owner, uint256 amount);

     
    event UpdateLockedAmount(address indexed owner, uint256 amount);

     
    event FreeTokens();

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[owner] = totalSupply_;
    }

     
    modifier canTransferBeforeEndOfIco(address _sender, address _to) {
        require(
            areTokensFree ||
            _sender == owner ||
            _sender == ICO_ADDRESS ||
            _sender == PRESALE_ADDRESS ||
            (
                _to == BACKUP_ONE ||
                _to == BACKUP_TWO ||
                _to == BACKUP_THREE || 
                _to == BACKUP_FOUR
            )
            , "Cannot transfer tokens yet"
        );

        _;
    }

     
    modifier canTransferIfLocked(address _sender, uint256 _amount) {
        uint256 afterTransfer = balances[_sender].sub(_amount);
        require(afterTransfer >= getLockedAmount(_sender), "Not enought unlocked tokens");
        
        _;
    }

     
    function getLockedAmount(address _addr) public view returns (uint256){
        if (now >= lockEndDate || initialLockedAmounts[_addr] == 0x0)
            return 0;

        if (now < lockStartDate) 
            return initialLockedAmounts[_addr];

        uint256 alpha = uint256(now).sub(lockStartDate);  
        uint256 tokens = initialLockedAmounts[_addr].sub(alpha.mul(initialLockedAmounts[_addr]).div(lockAbsoluteDifference));  

        return tokens;
    }

     
    function setLockedAmount(address _addr, uint256 _amount) public onlyOwner {
        require(_addr != address(0x0), "Cannot set locked amount to null address");

        initialLockedAmounts[_addr] = _amount;

        emit SetLockedAmount(_addr, _amount);
    }

     
    function updateLockedAmount(address _addr, uint256 _amount) public onlyOwner {
        require(_addr != address(0x0), "Cannot update locked amount to null address");
        require(_amount > 0, "Cannot add 0");

        initialLockedAmounts[_addr] = initialLockedAmounts[_addr].add(_amount);

        emit UpdateLockedAmount(_addr, _amount);
    }

     
    function freeTokens() public onlyOwner {
        require(!areTokensFree, "Tokens have already been freed");

        areTokensFree = true;

        lockStartDate = now;
         
        lockEndDate = lockStartDate + 1 days;
        lockAbsoluteDifference = lockEndDate.sub(lockStartDate);

        emit FreeTokens();
    }

     
    function transfer(address _to, uint256 _value)
        public
        canTransferBeforeEndOfIco(msg.sender, _to) 
        canTransferIfLocked(msg.sender, _value) 
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) 
        public
        canTransferBeforeEndOfIco(_from, _to) 
        canTransferIfLocked(_from, _value) 
        returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }

}

contract Presale is Ownable {

     
    using SafeMath for uint256;

     
    Token public token;

     
    uint256 public rate;

     
    address public wallet;

     
    address public holder;

     
    uint256 public weiRaised;

     
    uint256 public tokenPurchased;

     
    uint256 public constant startDate = 1535994000;  

     
    uint256 public constant endDate = 1541264400;  

     
    uint256 public minimumAmount = 40 ether;

     
    uint256 public maximumAmount = 200 ether;

     
    mapping (address => uint256) public contributionAmounts;

     
    mapping (address => bool) public whitelist;

     
    event Purchase(address indexed sender, address indexed beneficiary, uint256 value, uint256 amount);

     
    event ChangeRate(uint256 rate);

     
    event ChangeMinimumAmount(uint256 amount);

     
    event ChangeMaximumAmount(uint256 amount);

     
    event Whitelist(address indexed beneficiary, bool indexed whitelisted);

     
    constructor(address _tokenAddress, uint256 _rate, address _wallet, address _holder) public {
        require(_tokenAddress != address(0), "Token Address cannot be a null address");
        require(_rate > 0, "Conversion rate must be a positive integer");
        require(_wallet != address(0), "Wallet Address cannot be a null address");
        require(_holder != address(0), "Holder Address cannot be a null address");

        token = Token(_tokenAddress);
        rate = _rate;
        wallet = _wallet;
        holder = _holder;
    }

     
    modifier canPurchase(address _beneficiary) {
        require(now >= startDate, "Presale has not started yet");
        require(now <= endDate, "Presale has finished");

        require(whitelist[_beneficiary] == true, "Your address is not whitelisted");

        uint256 amount = uint256(contributionAmounts[_beneficiary]).add(msg.value);

        require(msg.value >= minimumAmount, "Cannot contribute less than the minimum amount");
        require(amount <= maximumAmount, "Cannot contribute more than the maximum amount");
        
        _;
    }

     
    function () external payable {
        purchase(msg.sender);
    }

     
    function purchase(address _beneficiary) internal canPurchase(_beneficiary) {
        uint256 weiAmount = msg.value;

         
        require(_beneficiary != address(0), "Beneficiary Address cannot be a null address");
        require(weiAmount > 0, "Wei amount must be a positive integer");

         
        uint256 tokenAmount = _getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);
        tokenPurchased = tokenPurchased.add(tokenAmount);
        contributionAmounts[_beneficiary] = contributionAmounts[_beneficiary].add(weiAmount);

        _transferEther(weiAmount);

         
        _purchaseTokens(_beneficiary, tokenAmount);

         
        emit Purchase(msg.sender, _beneficiary, weiAmount, tokenAmount);
    }

     
    function updateConversionRate(uint256 _rate) public onlyOwner {
        require(_rate > 0, "Conversion rate must be a positive integer");

        rate = _rate;

        emit ChangeRate(_rate);
    }

     
    function updateMinimumAmount(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Minimum amount must be a positive integer");

        minimumAmount = _amount;

        emit ChangeMinimumAmount(_amount);
    }

     
    function updateMaximumAmount(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Maximum amount must be a positive integer");

        maximumAmount = _amount;

        emit ChangeMaximumAmount(_amount);
    }

     
    function setWhitelist(address _addr, bool _whitelist) public onlyOwner {
        require(_addr != address(0x0), "Whitelisted address must be valid");

        whitelist[_addr] = _whitelist;

        emit Whitelist(_addr, _whitelist);
    }

     
    function _purchaseTokens(address _beneficiary, uint256 _amount) internal {
        token.transferFrom(holder, _beneficiary, _amount);
    }

     
    function _transferEther(uint256 _amount) internal {
         
        wallet.transfer(_amount);
    }

     
    function _getTokenAmount(uint256 _wei) internal view returns (uint256) {
         
        return _wei.mul(rate.mul(130).div(100));
    }

}