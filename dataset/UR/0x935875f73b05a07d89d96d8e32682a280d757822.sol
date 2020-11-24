 

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

 





 
contract Loche is CappedToken, BurnableToken
{
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public transferFee = 100000000;
    uint256 public tokensPerEther = 10000000000;

    mapping( address => bool ) public freezed;

    event Freeze(address indexed acc );
    event Unfreeze(address indexed acc );
    event MintResumed();
    event TokenPurchase( address indexed purchaser, uint256 value, uint256 amount );

    modifier notFreezed() {
        require(!freezed[msg.sender], "This account is freezed!");
        _;
    }

    constructor( uint256 _totalSupply, string _name, uint8 _decimals, string _symbol )
        CappedToken(_totalSupply.mul(2))
        public
    {
        balances[msg.sender] = _totalSupply;               
        totalSupply = _totalSupply;                         
        name = _name;                                    
        symbol = _symbol;                                
        decimals = _decimals;                             
    }

    function freeze(address _acc) public onlyOwner
    {
        freezed[_acc] = true;
        emit Freeze(_acc);
    }

    function unfreeze(address _acc) public onlyOwner
    {
        require(freezed[_acc], "Account must be freezed!");
        delete freezed[_acc];
        emit Unfreeze(_acc);
    }

    function setTransferFee(uint256 _value) public onlyOwner
    {
        transferFee = _value;
    }

    function transfer(address _to, uint256 _value) public notFreezed returns (bool)
    {
        return super.transfer(_to, _value);
    }

     
    function feedTransfer( address _from, address _to, uint256 _value ) public onlyOwner returns(bool)
    {    
        require(_value <= balances[msg.sender], "Not enough balance");
        require(_to != address(0), "Receiver address cannot be zero");

        require(!freezed[_from], "Sender account is freezed!");
        require(!freezed[_to], "Receiver account is freezed!");
        require(_value > transferFee, "Value must greater than transaction fee");

        uint256 transferValue = _value.sub(transferFee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(transferValue);
        balances[msg.sender] = balances[msg.sender].add(transferFee);

        emit Transfer(_from, _to, transferValue);
        emit Transfer(_from, msg.sender, transferFee);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool)
    {
        require(!freezed[_from], "Spender account is freezed!");
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool)
    {
        require(!freezed[_spender], "Spender account is freezed!");
        return super.approve(_spender, _value);
    }

    function purchase() public payable
    {
        require(msg.value != 0, "Value must greater than zero");
        uint256 weiAmount = msg.value;
        uint256 tokenAmount = tokensPerEther.mul(weiAmount).div(1 ether);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);
        totalSupply_ = totalSupply_.add(tokenAmount);

        emit TokenPurchase(msg.sender, msg.value, tokenAmount);
        emit Transfer(address(0), msg.sender, tokenAmount);
    }

     
    function withdrawEther() public onlyOwner
    {
        owner.transfer(address(this).balance);
    }

     
    function resumeMint() public onlyOwner returns(bool)
    {
        require(mintingFinished, "Minting is running!");
        mintingFinished = false;
        emit MintResumed();
        return true;
    }
}