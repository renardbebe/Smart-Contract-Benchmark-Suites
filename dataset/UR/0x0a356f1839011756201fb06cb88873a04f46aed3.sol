 

pragma solidity ^0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    emit Approval(_from, msg.sender, allowed[_from][msg.sender]);
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

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    onlyOwner
    canMint
    returns (bool)
  {
    _mint(_to,_amount);
    return true;
  }

  function _mint(
    address _to,
    uint256 _amount
  )
    internal
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

contract QueenBeeCompanyToken is StandardToken, BurnableToken, Ownable, MintableToken {
    using SafeMath for uint256;

    event LockAccount(address addr, uint256 amount);
    event UnlockAccount(address addr);
    event ChangeAdmin(
      address indexed previousAdmin,
      address indexed newAdmin
    );
    event EnableTransfer();
    event DisableTransfer();


    string public constant symbol = "QBZ";
    string public constant name = "QBEE";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY            = 8000000000 * (10 ** uint256(decimals));
    uint256 public constant INITIAL_SUPPLY_15PERCENT  = 1200000000 * (10 ** uint256(decimals));
    uint256 public constant INITIAL_SUPPLY_40PERCENT  = 3200000000 * (10 ** uint256(decimals));

    address public constant earlyFoundation     = 0x1980C8271Ba6BFaF1D5C43e8dAe655de8CFaBdBe;
    address public constant advisorTeam         = 0xE65A71a07d0D431d01CE6342Ba56BB3A2f634165;
    address public constant business            = 0x8A8f70f546c81EF8B178BBc4544d1F008C88096c;
    address public constant publicAddr          = 0xC1486038AA29bF676478e2bB787F97298900E08b;
    address public constant reserveAffiliates   = 0x086b779Eb55744A8518708f016fd5530493ecab5;

     
    address public adminAddr;

     
    bool public transferEnabled = true;

     
    mapping(address => uint256) private lockedAccounts;

     

     
    modifier onlyWhenTransferAllowed() {
        require(transferEnabled == true
			|| msg.sender == owner
            || msg.sender == adminAddr);
        _;
    }

    modifier onlyAllowedAmount(address from, uint256 amount) {
        require(balances[from].sub(amount) >= lockedAccounts[from]);
        _;
    }
     
    constructor(address _adminAddr) public {
        _mint(earlyFoundation, INITIAL_SUPPLY_15PERCENT);
        _mint(advisorTeam, INITIAL_SUPPLY_15PERCENT);
        _mint(business, INITIAL_SUPPLY_15PERCENT);
        _mint(publicAddr, INITIAL_SUPPLY_40PERCENT);
        _mint(reserveAffiliates, INITIAL_SUPPLY_15PERCENT);

         
        allowed[earlyFoundation][msg.sender] = INITIAL_SUPPLY_15PERCENT;
        
        address beneficiary_1 = 0xf559b5A8910183E9B5ca7DFA5A30e3CC38177056;
        address beneficiary_2 = 0x8E39AAF968D65c2040f51145777700147B8025AB;
        address beneficiary_3 = 0x34B400774388b922E42b1339b6DB8Df623D60ca4;
        address beneficiary_4 = 0x4593E0a3bBEA7CEeb892e8ba8BBE808a3c8d3478;
        address beneficiary_5 = 0x5068c0bDBe8c92F5fd4D346d1072C59359623de7;
        address beneficiary_6 = 0xB2b588Ad768373b36109825871E65e99FEAc441B;
        address beneficiary_7 = 0x9B82b4D087928497cb6728402f68e0C33DA5205C;

        uint256 token_1 = 16000000 * 10**uint256(decimals);
        uint256 token_2 = 16000000 * 10**uint256(decimals);
        uint256 token_3 =  8000000 * 10**uint256(decimals);
        uint256 token_4 =  8000000 * 10**uint256(decimals);
        uint256 token_5 =  4000000 * 10**uint256(decimals);
        uint256 token_6 =  2000000 * 10**uint256(decimals);
        uint256 token_7 =  2000000 * 10**uint256(decimals);
        
        transferFrom(earlyFoundation, beneficiary_1, token_1);
        transferFrom(earlyFoundation, beneficiary_2, token_2);
        transferFrom(earlyFoundation, beneficiary_3, token_3);
        transferFrom(earlyFoundation, beneficiary_4, token_4);
        transferFrom(earlyFoundation, beneficiary_5, token_5);
        transferFrom(earlyFoundation, beneficiary_6, token_6);
        transferFrom(earlyFoundation, beneficiary_7, token_7);
        
        allowed[earlyFoundation][msg.sender] = 0; 
        adminAddr = _adminAddr;
    }

     
    function changeAdmin(address _adminAddr) public onlyOwner {
        emit ChangeAdmin(adminAddr, _adminAddr);
        adminAddr = _adminAddr;
    }


     
    function enableTransfer() external onlyOwner {
        transferEnabled = true;
        emit EnableTransfer();
    }

     
    function disableTransfer() external onlyOwner {
	      transferEnabled = false;
        emit DisableTransfer();
    }

     
    function transfer(address to, uint256 value)
        public
        onlyWhenTransferAllowed
        onlyAllowedAmount(msg.sender, value)
        returns (bool)
    {
        return super.transfer(to, value);
    }

     
    function transferFrom(address from, address to, uint256 value)
        public
        onlyWhenTransferAllowed
        onlyAllowedAmount(from, value)
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }

     
    function burn(uint256 value) public onlyOwner {
         
        super.burn(value);
    }

    function mint(address to, uint256 value) public onlyOwner returns(bool) {
         
        require(totalSupply().add(value) <= INITIAL_SUPPLY);
        super.mint(to, value);
    }

     
    function lockAccount(address addr, uint256 amount)
        external
        onlyOwner
    {
        require(amount > 0 && amount <= balanceOf(addr));
        lockedAccounts[addr] = amount;
        emit LockAccount(addr, amount);
    }

     

    function unlockAccount(address addr)
        external
        onlyOwner
    {
        lockedAccounts[addr] = 0;
        emit UnlockAccount(addr);
    }
    
    function lockedValue(address addr) public view returns(uint256) {
        return lockedAccounts[addr];
    }
}