 

pragma solidity >=0.5.1;


 
contract ERC20Basic {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
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



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

   
  function _transfer(address _from, address _to, uint256 _value) internal {
      require(_to != address(0));
      require(_value <= balances[_from]);
  
      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      emit Transfer(_from, _to, _value);
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
    hasMintPermission
    canMint
    public
    returns (bool)
  {
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


contract FreezableToken is StandardToken {
     
    mapping (bytes32 => uint64) internal chains;
     
    mapping (bytes32 => uint) internal freezings;
     
    mapping (address => uint) internal freezingBalance;

     
    mapping (bytes32 => uint64) internal reducibleChains;
     
    mapping (bytes32 => uint) internal reducibleFreezings;
     
    mapping (address => uint) internal reducibleFreezingBalance;

    event Freezed(address indexed to, uint64 release, uint amount);
    event Released(address indexed owner, uint amount);
    event FreezeReduced(address indexed owner, uint64 release, uint amount);

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner) + freezingBalance[_owner] + reducibleFreezingBalance[_owner];
    }

     
    function actualBalanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner);
    }

    function freezingBalanceOf(address _owner) public view returns (uint256 balance) {
        return freezingBalance[_owner];
    }

    function reducibleFreezingBalanceOf(address _owner) public view returns (uint256 balance) {
        return reducibleFreezingBalance[_owner];
    }

     
    function freezingCount(address _addr) public view returns (uint count) {
        uint64 release = chains[toKey(_addr, 0)];
        while (release != 0) {
            count++;
            release = chains[toKey(_addr, release)];
        }
    }

     
    function reducibleFreezingCount(address _addr, address _sender) public view returns (uint count) {
        uint64 release = reducibleChains[toKey2(_addr, _sender, 0)];
        while (release != 0) {
            count++;
            release = reducibleChains[toKey2(_addr, _sender, release)];
        }
    }

     
    function getFreezing(address _addr, uint _index) public view returns (uint64 _release, uint _balance) {
        for (uint i = 0; i < _index + 1; i++) {
            _release = chains[toKey(_addr, _release)];
            if (_release == 0) {
                return (0, 0);
            }
        }
        _balance = freezings[toKey(_addr, _release)];
    }

     
    function getReducibleFreezing(address _addr, address _sender, uint _index) public view returns (uint64 _release, uint _balance) {
        for (uint i = 0; i < _index + 1; i++) {
            _release = reducibleChains[toKey2(_addr, _sender, _release)];
            if (_release == 0) {
                return (0, 0);
            }
        }
        _balance = reducibleFreezings[toKey2(_addr, _sender, _release)];
    }

     
    function freezeTo(address _to, uint _amount, uint64 _until) public {
        _freezeTo(msg.sender, _to, _amount, _until);
    }

     
    function _freezeTo(address _from, address _to, uint _amount, uint64 _until) internal {
        require(_to != address(0));
        require(_amount <= balances[_from]);

        balances[_from] = balances[_from].sub(_amount);

        bytes32 currentKey = toKey(_to, _until);
        freezings[currentKey] = freezings[currentKey].add(_amount);
        freezingBalance[_to] = freezingBalance[_to].add(_amount);

        freeze(_to, _until);
        emit Transfer(_from, _to, _amount);
        emit Freezed(_to, _until, _amount);
    }

     
    function reducibleFreezeTo(address _to, uint _amount, uint64 _until) public {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        require(_until > block.timestamp);

        balances[msg.sender] = balances[msg.sender].sub(_amount);

        bytes32 currentKey = toKey2(_to, msg.sender, _until);
        reducibleFreezings[currentKey] = reducibleFreezings[currentKey].add(_amount);
        reducibleFreezingBalance[_to] = reducibleFreezingBalance[_to].add(_amount);

        reducibleFreeze(_to, _until);
        emit Transfer(msg.sender, _to, _amount);
        emit Freezed(_to, _until, _amount);
    }

     
    function reduceFreezingTo(address _to, uint _amount, uint64 _until, uint64 _newUntil) public {
        require(_to != address(0));

         
        require(_newUntil < _until);

        bytes32 currentKey = toKey2(_to, msg.sender, _until);
        uint amount = reducibleFreezings[currentKey];
        require(amount > 0);

        if (_amount >= amount) {
             

             
            delete reducibleFreezings[currentKey];

            uint64 next = reducibleChains[currentKey];
            bytes32 parent = toKey2(_to, msg.sender, uint64(0));
            while (reducibleChains[parent] != _until) {
                parent = toKey2(_to, msg.sender, reducibleChains[parent]);
            }

             
            if (next == 0) {
                delete reducibleChains[parent];
            }
            else {
                reducibleChains[parent] = next;
            }

             
            if (_newUntil <= block.timestamp) {
                balances[_to] = balances[_to].add(amount);
                reducibleFreezingBalance[_to] = reducibleFreezingBalance[_to].sub(amount);

                emit Released(_to, amount);
            }
            else {
                 
                bytes32 newKey = toKey2(_to, msg.sender, _newUntil);
                reducibleFreezings[newKey] = reducibleFreezings[newKey].add(amount);

                reducibleFreeze(_to, _newUntil);

                emit FreezeReduced(_to, _newUntil, amount);
            }
        }
        else {
            reducibleFreezings[currentKey] = reducibleFreezings[currentKey].sub(_amount);
            if (_newUntil <= block.timestamp) {
                 
                balances[_to] = balances[_to].add(_amount);
                 
                reducibleFreezingBalance[_to] = reducibleFreezingBalance[_to].sub(_amount);

                emit Released(_to, _amount);
            }
            else {
                 
                bytes32 newKey = toKey2(_to, msg.sender, _newUntil);
                reducibleFreezings[newKey] = reducibleFreezings[newKey].add(_amount);

                reducibleFreeze(_to, _newUntil);

                emit FreezeReduced(_to, _newUntil, _amount);
            }
        }
    }

     
    function releaseOnce() public {
        bytes32 headKey = toKey(msg.sender, 0);
        uint64 head = chains[headKey];
        require(head != 0);
        require(uint64(block.timestamp) > head);
        bytes32 currentKey = toKey(msg.sender, head);

        uint64 next = chains[currentKey];

        uint amount = freezings[currentKey];
        delete freezings[currentKey];

        balances[msg.sender] = balances[msg.sender].add(amount);
        freezingBalance[msg.sender] = freezingBalance[msg.sender].sub(amount);

        if (next == 0) {
            delete chains[headKey];
        } else {
            chains[headKey] = next;
            delete chains[currentKey];
        }
        emit Released(msg.sender, amount);
    }

     
    function releaseReducibleFreezingOnce(address _sender) public {
        bytes32 headKey = toKey2(msg.sender, _sender, 0);
        uint64 head = reducibleChains[headKey];
        require(head != 0);
        require(uint64(block.timestamp) > head);
        bytes32 currentKey = toKey2(msg.sender, _sender, head);

        uint64 next = reducibleChains[currentKey];

        uint amount = reducibleFreezings[currentKey];
        delete reducibleFreezings[currentKey];

        balances[msg.sender] = balances[msg.sender].add(amount);
        reducibleFreezingBalance[msg.sender] = reducibleFreezingBalance[msg.sender].sub(amount);

        if (next == 0) {
            delete reducibleChains[headKey];
        } else {
            reducibleChains[headKey] = next;
            delete reducibleChains[currentKey];
        }
        emit Released(msg.sender, amount);
    }

     
    function releaseAll() public returns (uint tokens) {
        uint release;
        uint balance;
        (release, balance) = getFreezing(msg.sender, 0);
        while (release != 0 && block.timestamp > release) {
            releaseOnce();
            tokens += balance;
            (release, balance) = getFreezing(msg.sender, 0);
        }
    }

     
    function reducibleReleaseAll(address _sender) public returns (uint tokens) {
        uint release;
        uint balance;
        (release, balance) = getReducibleFreezing(msg.sender, _sender, 0);
        while (release != 0 && block.timestamp > release) {
            releaseReducibleFreezingOnce(_sender);
            tokens += balance;
            (release, balance) = getReducibleFreezing(msg.sender, _sender, 0);
        }
    }

    function toKey(address _addr, uint _release) internal pure returns (bytes32 result) {
        result = 0x5749534800000000000000000000000000000000000000000000000000000000;
        assembly {
            result := or(result, mul(_addr, 0x10000000000000000))
            result := or(result, _release)
        }
    }

    function toKey2(address _addr1, address _addr2, uint _release) internal pure returns (bytes32 result) {
        bytes32 key1 = 0x5749534800000000000000000000000000000000000000000000000000000000;
        bytes32 key2 = 0x8926457892347780720546870000000000000000000000000000000000000000;
        assembly {
            key1 := or(key1, mul(_addr1, 0x10000000000000000))
            key1 := or(key1, _release)
            key2 := or(key2, _addr2)
        }
        result = keccak256(abi.encodePacked(key1, key2));
    }

    function freeze(address _to, uint64 _until) internal {
        require(_until > block.timestamp);
        bytes32 key = toKey(_to, _until);
        bytes32 parentKey = toKey(_to, uint64(0));
        uint64 next = chains[parentKey];

        if (next == 0) {
            chains[parentKey] = _until;
            return;
        }

        bytes32 nextKey = toKey(_to, next);
        uint parent;

        while (next != 0 && _until > next) {
            parent = next;
            parentKey = nextKey;

            next = chains[nextKey];
            nextKey = toKey(_to, next);
        }

        if (_until == next) {
            return;
        }

        if (next != 0) {
            chains[key] = next;
        }

        chains[parentKey] = _until;
    }

    function reducibleFreeze(address _to, uint64 _until) internal {
        require(_until > block.timestamp);
        bytes32 key = toKey2(_to, msg.sender, _until);
        bytes32 parentKey = toKey2(_to, msg.sender, uint64(0));
        uint64 next = reducibleChains[parentKey];

        if (next == 0) {
            reducibleChains[parentKey] = _until;
            return;
        }

        bytes32 nextKey = toKey2(_to, msg.sender, next);
        uint parent;

        while (next != 0 && _until > next) {
            parent = next;
            parentKey = nextKey;

            next = reducibleChains[nextKey];
            nextKey = toKey2(_to, msg.sender, next);
        }

        if (_until == next) {
            return;
        }

        if (next != 0) {
            reducibleChains[key] = next;
        }

        reducibleChains[parentKey] = _until;
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


contract FreezableMintableToken is FreezableToken, MintableToken {
     
    function mintAndFreeze(address _to, uint _amount, uint64 _until) public onlyOwner canMint returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);

        bytes32 currentKey = toKey(_to, _until);
        freezings[currentKey] = freezings[currentKey].add(_amount);
        freezingBalance[_to] = freezingBalance[_to].add(_amount);

        freeze(_to, _until);
        emit Mint(_to, _amount);
        emit Freezed(_to, _until, _amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
}

contract Consts {
    uint public constant TOKEN_DECIMALS = 18;
    uint8 public constant TOKEN_DECIMALS_UINT8 = 18;
    uint public constant TOKEN_DECIMAL_MULTIPLIER = 10 ** TOKEN_DECIMALS;
    string public constant TOKEN_NAME = "MindsyncAI";
    string public constant TOKEN_SYMBOL = "MAI";
    uint public constant INITIAL_SUPPLY = 150000000 * TOKEN_DECIMAL_MULTIPLIER;
}


contract MindsyncToken is Consts, FreezableMintableToken, BurnableToken, Pausable
{
    uint256 startdate;

    address beneficiary1;
    address beneficiary2;
    address beneficiary3;
    address beneficiary4;
    address beneficiary5;
    address beneficiary6;

    event Initialized();
    bool public initialized = false;

    constructor() public {
        init();
    }

    function name() public pure returns (string memory) {
        return TOKEN_NAME;
    }

    function symbol() public pure returns (string memory) {
        return TOKEN_SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return TOKEN_DECIMALS_UINT8;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success) {
        require(!paused);
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool _success) {
        require(!paused);
        return super.transfer(_to, _value);
    }

    function init() private {
        require(!initialized);
        initialized = true;


         
        uint256 amount = INITIAL_SUPPLY;

         
        mint(address(this), amount);
        finishMinting();

         
        startdate = 1569888000;

        beneficiary1 = 0x52e3d3FDaed694B36E938748B689bbC16fd8a2FC;  
        beneficiary2 = 0xD520445Db9CdEb0B8c2e964832Db38e25E3D90ED;  
        beneficiary3 = 0xaC7585745623595DD66Cdb7019AeA540BaE2EB8E;  
        beneficiary4 = 0xB5E880ECCCDCaf9e0AC485D0165d7B3700fbFB3d;  
        beneficiary5 = 0x8c6C39302F09e478d5Fa13E486355a64047F3765;  
        beneficiary6 = 0x8c6C39302F09e478d5Fa13E486355a64047F3765;  

         
        _transfer(address(this), beneficiary1, totalSupply().mul(50).div(100));

         
        _freezeTo(address(this), beneficiary2, totalSupply().mul(15).div(100).div(4), uint64(startdate + 183 days));
        _freezeTo(address(this), beneficiary2, totalSupply().mul(15).div(100).div(4), uint64(startdate + 274 days));
        _freezeTo(address(this), beneficiary2, totalSupply().mul(15).div(100).div(4), uint64(startdate + 366 days));
        _freezeTo(address(this), beneficiary2, totalSupply().mul(15).div(100).div(4), uint64(startdate + 458 days));

         
        _freezeTo(address(this), beneficiary3, totalSupply().mul(5).div(100).div(4), uint64(startdate + 183 days));
        _freezeTo(address(this), beneficiary3, totalSupply().mul(5).div(100).div(4), uint64(startdate + 274 days));
        _freezeTo(address(this), beneficiary3, totalSupply().mul(5).div(100).div(4), uint64(startdate + 366 days));
        _freezeTo(address(this), beneficiary3, totalSupply().mul(5).div(100).div(4), uint64(startdate + 458 days));

         
        _transfer(address(this), beneficiary4, totalSupply().mul(2).div(100));

         
         
        _freezeTo(address(this), beneficiary5, totalSupply().mul(20).div(100).div(4), uint64(startdate + 91 days));

         
        _freezeTo(address(this), beneficiary6, totalSupply().mul(8).div(100).div(4), uint64(startdate + 365 days));

        emit Initialized();
    }
}