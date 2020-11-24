 

pragma solidity ^0.4.25;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

 

 
contract VestingPrivateSale is Ownable {

    uint256 constant public sixMonth = 182 days;  
    uint256 constant public twelveMonth = 365 days;  
    uint256 constant public eighteenMonth = sixMonth + twelveMonth;

    ERC20Basic public erc20Contract;

    struct Locking {
        uint256 bucket1;
        uint256 bucket2;
        uint256 bucket3;
        uint256 startDate;
    }

    mapping(address => Locking) public lockingMap;

    event ReleaseVestingEvent(address indexed to, uint256 value);

     
    constructor(address _erc20) public {
        require(AddressUtils.isContract(_erc20), "Address is not a smart contract");

        erc20Contract = ERC20Basic(_erc20);
    }

     
    function addVested(
        address _tokenHolder, 
        uint256 _bucket1, 
        uint256 _bucket2, 
        uint256 _bucket3
    ) 
        public 
        returns (bool) 
    {
        require(msg.sender == address(erc20Contract), "ERC20 contract required");
        require(lockingMap[_tokenHolder].startDate == 0, "Address is already vested");

        lockingMap[_tokenHolder].startDate = block.timestamp;
        lockingMap[_tokenHolder].bucket1 = _bucket1;
        lockingMap[_tokenHolder].bucket2 = _bucket2;
        lockingMap[_tokenHolder].bucket3 = _bucket3;

        return true;
    }

     
    function balanceOf(
        address _tokenHolder
    ) 
        public 
        view 
        returns (uint256) 
    {
        return lockingMap[_tokenHolder].bucket1 + lockingMap[_tokenHolder].bucket2 + lockingMap[_tokenHolder].bucket3;
    }

     
    function availableBalanceOf(
        address _tokenHolder
    ) 
        public 
        view 
        returns (uint256) 
    {
        uint256 startDate = lockingMap[_tokenHolder].startDate;
        uint256 tokens = 0;
        
        if (startDate + sixMonth <= block.timestamp) {
            tokens = lockingMap[_tokenHolder].bucket1;
        }

        if (startDate + twelveMonth <= block.timestamp) {
            tokens = tokens + lockingMap[_tokenHolder].bucket2;
        }

        if (startDate + eighteenMonth <= block.timestamp) {
            tokens = tokens + lockingMap[_tokenHolder].bucket3;
        }

        return tokens;
    }

     
    function releaseBuckets() 
        public 
        returns (uint256) 
    {
        return _releaseBuckets(msg.sender);
    }

     
    function releaseBuckets(
        address _tokenHolder
    ) 
        public 
        onlyOwner
        returns (uint256) 
    {
        return _releaseBuckets(_tokenHolder);
    }

    function _releaseBuckets(
        address _tokenHolder
    ) 
        private 
        returns (uint256) 
    {
        require(lockingMap[_tokenHolder].startDate != 0, "Is not a locked address");
        uint256 startDate = lockingMap[_tokenHolder].startDate;
        uint256 tokens = 0;
        
        if (startDate + sixMonth <= block.timestamp) {
            tokens = lockingMap[_tokenHolder].bucket1;
            lockingMap[_tokenHolder].bucket1 = 0;
        }

        if (startDate + twelveMonth <= block.timestamp) {
            tokens = tokens + lockingMap[_tokenHolder].bucket2;
            lockingMap[_tokenHolder].bucket2 = 0;
        }

        if (startDate + eighteenMonth <= block.timestamp) {
            tokens = tokens + lockingMap[_tokenHolder].bucket3;
            lockingMap[_tokenHolder].bucket3 = 0;
        }
        
        require(erc20Contract.transfer(_tokenHolder, tokens), "Transfer failed");
        emit ReleaseVestingEvent(_tokenHolder, tokens);

        return tokens;
    }
}

 

 
contract VestingTreasury {

    using SafeMath for uint256;

    uint256 constant public sixMonths = 182 days;  
    uint256 constant public thirtyMonths = 912 days;  

    ERC20Basic public erc20Contract;

    struct Locking {
        uint256 startDate;       
        uint256 initialized;     
        uint256 released;        
    }

    mapping(address => Locking) public lockingMap;

    event ReleaseVestingEvent(address indexed to, uint256 value);

     
    constructor(address _erc20) public {
        require(AddressUtils.isContract(_erc20), "Address is not a smart contract");

        erc20Contract = ERC20Basic(_erc20);
    }

     
    function addVested(
        address _tokenHolder, 
        uint256 _value
    ) 
        public 
        returns (bool) 
    {
        require(msg.sender == address(erc20Contract), "ERC20 contract required");
        require(lockingMap[_tokenHolder].startDate == 0, "Address is already vested");

        lockingMap[_tokenHolder].startDate = block.timestamp + sixMonths;
        lockingMap[_tokenHolder].initialized = _value;
        lockingMap[_tokenHolder].released = 0;

        return true;
    }

     
    function balanceOf(
        address _tokenHolder
    ) 
        public 
        view 
        returns (uint256) 
    {
        return lockingMap[_tokenHolder].initialized.sub(lockingMap[_tokenHolder].released);
    }

     
    function availableBalanceOf(
        address _tokenHolder
    ) 
        public 
        view 
        returns (uint256) 
    {
        uint256 startDate = lockingMap[_tokenHolder].startDate;
        
        if (block.timestamp <= startDate) {
            return 0;
        }

        uint256 tmpAvailableTokens = 0;
        if (block.timestamp >= startDate + thirtyMonths) {
            tmpAvailableTokens = lockingMap[_tokenHolder].initialized;
        } else {
            uint256 timeDiff = block.timestamp - startDate;
            uint256 totalBalance = lockingMap[_tokenHolder].initialized;

            tmpAvailableTokens = totalBalance.mul(timeDiff).div(thirtyMonths);
        }

        uint256 availableTokens = tmpAvailableTokens.sub(lockingMap[_tokenHolder].released);
        require(availableTokens <= lockingMap[_tokenHolder].initialized, "Max value exceeded");

        return availableTokens;
    }

     
    function releaseTokens() 
        public 
        returns (uint256) 
    {
        require(lockingMap[msg.sender].startDate != 0, "Sender is not a vested address");

        uint256 tokens = availableBalanceOf(msg.sender);

        lockingMap[msg.sender].released = lockingMap[msg.sender].released.add(tokens);
        require(lockingMap[msg.sender].released <= lockingMap[msg.sender].initialized, "Max value exceeded");

        require(erc20Contract.transfer(msg.sender, tokens), "Transfer failed");
        emit ReleaseVestingEvent(msg.sender, tokens);

        return tokens;
    }
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

 
contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

 

contract LockedToken is CappedToken {
    bool public transferActivated = false;

    event TransferActivatedEvent();

    constructor(uint256 _cap) public CappedToken(_cap) {
    }

     
    function activateTransfer() 
        public 
        onlyOwner
        returns (bool) 
    {
        require(transferActivated == false, "Already activated");

        transferActivated = true;

        emit TransferActivatedEvent();
        return true;
    }

     
    function transfer(
        address _to, 
        uint256 _value
    ) 
        public 
        returns (bool) 
    {
        require(transferActivated, "Transfer is not activated");
        require(_to != address(this), "Invalid _to address");

        return super.transfer(_to, _value);
    }

     
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    ) 
        public 
        returns (bool) 
    {
        require(transferActivated, "TransferFrom is not activated");
        require(_to != address(this), "Invalid _to address");

        return super.transferFrom(_from, _to, _value);
    }
}

 

 
contract AlprockzToken is LockedToken {
    
    string public constant name = "AlpRockz";
    string public constant symbol = "APZ";
    uint8 public constant decimals = 18;
    VestingPrivateSale public vestingPrivateSale;
    VestingTreasury public vestingTreasury;

    constructor() public LockedToken(175 * 1000000 * (10 ** uint256(decimals))) {
    }

     
    function initMintVestingPrivateSale(
        address _vestingContractAddr
    ) 
        external
        onlyOwner
        returns (bool) 
    {
        require(address(vestingPrivateSale) == address(0x0), "Already initialized");
        require(address(this) != _vestingContractAddr, "Invalid address");
        require(AddressUtils.isContract(_vestingContractAddr), "Address is not a smart contract");
        
        vestingPrivateSale = VestingPrivateSale(_vestingContractAddr);
        require(address(this) == address(vestingPrivateSale.erc20Contract()), "Vesting link address not match");
        
        return true;
    }

     
    function initMintVestingTreasury(
        address _vestingContractAddr
    ) 
        external
        onlyOwner
        returns (bool) 
    {
        require(address(vestingTreasury) == address(0x0), "Already initialized");
        require(address(this) != _vestingContractAddr, "Invalid address");
        require(AddressUtils.isContract(_vestingContractAddr), "Address is not a smart contract");
        
        vestingTreasury = VestingTreasury(_vestingContractAddr);
        require(address(this) == address(vestingTreasury.erc20Contract()), "Vesting link address not match");
        
        return true;
    }

     
    function mintArray(
        address[] _recipients, 
        uint256[] _tokens
    ) 
        external
        onlyOwner 
        returns (bool) 
    {
        require(_recipients.length == _tokens.length, "Array length not match");
        require(_recipients.length <= 40, "Too many recipients");

        for (uint256 i = 0; i < _recipients.length; i++) {
            require(super.mint(_recipients[i], _tokens[i]), "Mint failed");
        }

        return true;
    }

     
    function mintPrivateSale(
        address[] _recipients, 
        uint256[] _tokens
    ) 
        external 
        onlyOwner
        returns (bool) 
    {
        require(address(vestingPrivateSale) != address(0x0), "Init required");
        require(_recipients.length == _tokens.length, "Array length not match");
        require(_recipients.length <= 10, "Too many recipients");


        for (uint256 i = 0; i < _recipients.length; i++) {

            address recipient = _recipients[i];
            uint256 token = _tokens[i];

            uint256 first;
            uint256 second; 
            uint256 third; 
            uint256 fourth;
            (first, second, third, fourth) = splitToFour(token);

            require(super.mint(recipient, first), "Mint failed");

            uint256 totalVested = second + third + fourth;
            require(super.mint(address(vestingPrivateSale), totalVested), "Mint failed");
            require(vestingPrivateSale.addVested(recipient, second, third, fourth), "Vesting failed");
        }

        return true;
    }

     
    function mintTreasury(
        address[] _recipients, 
        uint256[] _tokens
    ) 
        external 
        onlyOwner
        returns (bool) 
    {
        require(address(vestingTreasury) != address(0x0), "Init required");
        require(_recipients.length == _tokens.length, "Array length not match");
        require(_recipients.length <= 10, "Too many recipients");

        for (uint256 i = 0; i < _recipients.length; i++) {

            address recipient = _recipients[i];
            uint256 token = _tokens[i];

            require(super.mint(address(vestingTreasury), token), "Mint failed");
            require(vestingTreasury.addVested(recipient, token), "Vesting failed");
        }

        return true;
    }

    function splitToFour(
        uint256 _amount
    ) 
        private 
        pure 
        returns (
            uint256 first, 
            uint256 second, 
            uint256 third, 
            uint256 fourth
        ) 
    {
        require(_amount >= 4, "Minimum amount");

        uint256 rest = _amount % 4;

        uint256 quarter = (_amount - rest) / 4;

        first = quarter + rest;
        second = quarter;
        third = quarter;
        fourth = quarter;
    }
}