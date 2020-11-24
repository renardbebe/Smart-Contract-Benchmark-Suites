 

pragma solidity 0.4.24;

 

 
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

 

 
contract CoyToken is CappedToken, BurnableToken, DetailedERC20, Pausable {
    using SafeMath for uint256;
    using SafeMath for uint8;
    
    string private constant COY_NAME = "CoinAnalyst";
    string private constant COY_SYMBOL = "COY";
    uint8 private constant COY_DECIMALS = 18;
    
     
    uint256 private constant TOKEN_UNIT = 10 ** uint256(COY_DECIMALS);
    uint256 private constant COY_CAP = (3.75 * 10 ** 9) * TOKEN_UNIT;
    
     
    address public minter;
    address public assigner;
    address public burner;

     
    constructor(address _minter, address _assigner, address _burner) 
        CappedToken(COY_CAP) 
        DetailedERC20(COY_NAME, COY_SYMBOL, COY_DECIMALS)
        public
    {
        require(_minter != address(0), "Minter must be a valid non-null address");
        require(_assigner != address(0), "Assigner must be a valid non-null address");
        require(_burner != address(0), "Burner must be a valid non-null address");

        minter = _minter;
        assigner = _assigner;
        burner = _burner;
    }

    event MinterTransferred(address indexed _minter, address indexed _newMinter);
    event AssignerTransferred(address indexed _assigner, address indexed _newAssigner);
    event BurnerTransferred(address indexed _burner, address indexed _newBurner);
    event BatchMint(uint256 _totalMintedTokens, uint256 _batchMintId);
    event Assign(address indexed _to, uint256 _amount);
    event BatchAssign(uint256 _totalAssignedTokens, uint256 _batchAssignId);
    event BatchTransfer(uint256 _totalTransferredTokens, uint256 _batchTransferId);
    
     
    modifier hasMintPermission() {
        require(msg.sender == minter, "Only the minter can do this.");
        _;
    }
    
     
    modifier hasAssignPermission() {
        require(msg.sender == assigner, "Only the assigner can do this.");
        _;
    }
    
     
    modifier hasBurnPermission() {
        require(msg.sender == burner, "Only the burner can do this.");
        _;
    }
    
     
    modifier whenMintingFinished() {
        require(mintingFinished, "Minting has to be finished.");
        _;
    }


     
    function setMinter(address _newMinter) external 
        canMint
        onlyOwner 
        returns(bool) 
    {
        require(_newMinter != address(0), "New minter must be a valid non-null address");
        require(_newMinter != minter, "New minter has to differ from previous minter");

        emit MinterTransferred(minter, _newMinter);
        minter = _newMinter;
        return true;
    }
    
     
    function setAssigner(address _newAssigner) external 
        onlyOwner 
        canMint
        returns(bool) 
    {
        require(_newAssigner != address(0), "New assigner must be a valid non-null address");
        require(_newAssigner != assigner, "New assigner has to differ from previous assigner");

        emit AssignerTransferred(assigner, _newAssigner);
        assigner = _newAssigner;
        return true;
    }
    
     
    function setBurner(address _newBurner) external 
        onlyOwner 
        returns(bool) 
    {
        require(_newBurner != address(0), "New burner must be a valid non-null address");
        require(_newBurner != burner, "New burner has to differ from previous burner");

        emit BurnerTransferred(burner, _newBurner);
        burner = _newBurner;
        return true;
    }
    
     
    function batchMint(address[] _to, uint256[] _amounts, uint256 _batchMintId) external
        canMint
        hasMintPermission
        returns (bool) 
    {
        require(_to.length == _amounts.length, "Input arrays must have the same length");
        
        uint256 totalMintedTokens = 0;
        for (uint i = 0; i < _to.length; i++) {
            mint(_to[i], _amounts[i]);
            totalMintedTokens = totalMintedTokens.add(_amounts[i]);
        }
        
        emit BatchMint(totalMintedTokens, _batchMintId);
        return true;
    }
    
     
    function assign(address _to, uint256 _amount) public 
        canMint
        hasAssignPermission 
        returns(bool) 
    {
         
         
         
        uint256 delta = 0;
        if (balances[_to] < _amount) {
             
            delta = _amount.sub(balances[_to]);
            totalSupply_ = totalSupply_.add(delta);
            require(totalSupply_ <= cap, "Total supply cannot be higher than cap");
            emit Transfer(address(0), _to, delta);  
        } else {
             
            delta = balances[_to].sub(_amount);
            totalSupply_ = totalSupply_.sub(delta);
            emit Transfer(_to, address(0), delta);  
        }
        
        require(delta > 0, "Delta should not be zero");

        balances[_to] = _amount;
        emit Assign(_to, _amount);
        return true;
    }
    
     
    function batchAssign(address[] _to, uint256[] _amounts, uint256 _batchAssignId) external
        canMint
        hasAssignPermission
        returns (bool) 
    {
        require(_to.length == _amounts.length, "Input arrays must have the same length");
        
        uint256 totalAssignedTokens = 0;
        for (uint i = 0; i < _to.length; i++) {
            assign(_to[i], _amounts[i]);
            totalAssignedTokens = totalAssignedTokens.add(_amounts[i]);
        }
        
        emit BatchAssign(totalAssignedTokens, _batchAssignId);
        return true;
    }
    
     
    function burn(uint256 _value) public
        hasBurnPermission
    {
        super.burn(_value);
    }

     
    function transfer(address _to, uint256 _value) public
        whenMintingFinished
        whenNotPaused
        returns (bool) 
    {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public
        whenMintingFinished
        whenNotPaused
        returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }
    
     
    function transferInBatches(address[] _to, uint256[] _amounts, uint256 _batchTransferId) public
        whenMintingFinished
        whenNotPaused
        returns (bool) 
    {
        require(_to.length == _amounts.length, "Input arrays must have the same length");
        
        uint256 totalTransferredTokens = 0;
        for (uint i = 0; i < _to.length; i++) {
            transfer(_to[i], _amounts[i]);
            totalTransferredTokens = totalTransferredTokens.add(_amounts[i]);
        }
        
        emit BatchTransfer(totalTransferredTokens, _batchTransferId);
        return true;
    }
}