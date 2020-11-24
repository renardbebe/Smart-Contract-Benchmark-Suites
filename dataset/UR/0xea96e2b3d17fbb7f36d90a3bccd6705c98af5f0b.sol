 

pragma solidity ^0.4.24;

 

contract ERC223ReceiverMixin {
  function tokenFallback(address _from, uint256 _value, bytes _data) public;
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
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

 

 
 
contract ERC223Mixin is StandardToken {
  event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool) 
  {
    bytes memory empty;
    return transferFrom(
      _from, 
      _to,
      _value,
      empty);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  ) public returns (bool)
  {
    require(_value <= allowed[_from][msg.sender]);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    if (isContract(_to)) {
      return transferToContract(
        _from, 
        _to, 
        _value, 
        _data);
    } else {
      return transferToAddress(
        _from, 
        _to, 
        _value, 
        _data); 
    }
  }

  function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {
    if (isContract(_to)) {
      return transferToContract(
        msg.sender,
        _to,
        _value,
        _data); 
    } else {
      return transferToAddress(
        msg.sender,
        _to,
        _value,
        _data);
    }
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    bytes memory empty;
    return transfer(_to, _value, empty);
  }

  function isContract(address _addr) internal view returns (bool) {
    uint256 length;
     
    assembly {
       
      length := extcodesize(_addr)
    }  
    return (length>0);
  }

  function moveTokens(address _from, address _to, uint256 _value) internal returns (bool success) {
    if (balanceOf(_from) < _value) {
      revert();
    }
    balances[_from] = balanceOf(_from).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);

    return true;
  }

  function transferToAddress(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  ) internal returns (bool success) 
  {
    require(moveTokens(_from, _to, _value));
    emit Transfer(_from, _to, _value);
    emit Transfer(_from, _to, _value, _data);  
    return true;
  }
  
   
  function transferToContract(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  ) internal returns (bool success) 
  {
    require(moveTokens(_from, _to, _value));
    ERC223ReceiverMixin(_to).tokenFallback(_from, _value, _data);
    emit Transfer(_from, _to, _value);
    emit Transfer(_from, _to, _value, _data);  
    return true;
  }
}

 

 
 
 
contract RBACMixin {
   
  string constant FORBIDDEN = "Haven't enough right to access";
   
  mapping (address => bool) public owners;
   
  mapping (address => bool) public minters;

   
   
  event AddOwner(address indexed who);
   
   
  event DeleteOwner(address indexed who);

   
   
  event AddMinter(address indexed who);
   
   
  event DeleteMinter(address indexed who);

  constructor () public {
    _setOwner(msg.sender, true);
  }

   
  modifier onlyOwner() {
    require(isOwner(msg.sender), FORBIDDEN);
    _;
  }

   
  modifier onlyMinter() {
    require(isMinter(msg.sender), FORBIDDEN);
    _;
  }

   
   
   
  function isOwner(address _who) public view returns (bool) {
    return owners[_who];
  }

   
   
   
  function isMinter(address _who) public view returns (bool) {
    return minters[_who];
  }

   
   
   
   
  function addOwner(address _who) public onlyOwner returns (bool) {
    _setOwner(_who, true);
  }

   
   
   
   
  function deleteOwner(address _who) public onlyOwner returns (bool) {
    _setOwner(_who, false);
  }

   
   
   
   
  function addMinter(address _who) public onlyOwner returns (bool) {
    _setMinter(_who, true);
  }

   
   
   
   
  function deleteMinter(address _who) public onlyOwner returns (bool) {
    _setMinter(_who, false);
  }

   
   
   
   
  function _setOwner(address _who, bool _flag) private returns (bool) {
    require(owners[_who] != _flag);
    owners[_who] = _flag;
    if (_flag) {
      emit AddOwner(_who);
    } else {
      emit DeleteOwner(_who);
    }
    return true;
  }

   
   
   
   
  function _setMinter(address _who, bool _flag) private returns (bool) {
    require(minters[_who] != _flag);
    minters[_who] = _flag;
    if (_flag) {
      emit AddMinter(_who);
    } else {
      emit DeleteMinter(_who);
    }
    return true;
  }
}

 

 
 
contract RBACERC223TokenFinalization is ERC223Mixin, RBACMixin {
  event Finalize();
   
  bool public finalized;

   
  modifier isFinalized() {
    require(finalized);
    _;
  }

   
  modifier notFinalized() {
    require(!finalized);
    _;
  }

   
   
   
  function finalize() public notFinalized onlyOwner returns (bool) {
    finalized = true;
    emit Finalize();
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public isFinalized returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
   
  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public isFinalized returns (bool) {
    return super.transferFrom(_from, _to, _value, _data);  
  }

   
  function transfer(address _to, uint256 _value, bytes _data) public isFinalized returns (bool) {
    return super.transfer(_to, _value, _data);
  }

   
  function transfer(address _to, uint256 _value) public isFinalized returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function approve(address _spender, uint256 _value) public isFinalized returns (bool) {
    return super.approve(_spender, _value);
  }

   
  function increaseApproval(address _spender, uint256 _addedValue) public isFinalized returns (bool) {
    return super.increaseApproval(_spender, _addedValue);
  }

   
  function decreaseApproval(address _spender, uint256 _subtractedValue) public isFinalized returns (bool) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 

contract RBACMintableTokenMixin is StandardToken, RBACMixin {
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
    onlyMinter
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

   
  function finishMinting() onlyOwner canMint internal returns (bool) {
    mintingFinished = true;
    emit MintFinished();
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

 

 
contract StandardBurnableToken is BurnableToken, StandardToken {

   
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}

 

 
 
 
contract MustToken is StandardBurnableToken, RBACERC223TokenFinalization, RBACMintableTokenMixin {
   
   
  string constant public name = "Main Universal Standard of Tokenization"; 
   
  string constant public symbol = "MUST";  
   
  uint256 constant public decimals = 8;  
   
  uint256 constant public cap = 5 * (10 ** 6) * (10 ** decimals);  

   
   
   
   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    returns (bool) 
  {
    require(totalSupply().add(_amount) <= cap);
    return super.mint(_to, _amount);
  }

   
   
  function finalize() public returns (bool) {
    require(super.finalize());
    require(finishMinting());
    return true;
  }

   
   
  function finishMinting() internal returns (bool) {
    require(finalized == true);
    require(super.finishMinting());
    return true;
  }
}