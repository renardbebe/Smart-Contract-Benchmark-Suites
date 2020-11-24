 

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

 
contract ERC20  {
   
  using SafeMath for uint256;
   
  uint256 totalSupply_;
   
  mapping(address => uint256) balances;
   
  mapping (address => mapping (address => uint256)) internal allowed;
  
   
  event Transfer(address indexed from, address indexed to, uint256 value);
  
   
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
  
   
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
  
   
  function transferFrom(address _from, address _to,
    uint256 _value ) public returns (bool) {
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

   
  function allowance( address _owner, address _spender) 
  public view returns (uint256)  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender,
    uint256 _addedValue)
    public returns (bool) {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  
   
  function decreaseApproval(address _spender,
    uint256 _subtractedValue)
    public returns (bool) {
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


 
contract NewToken is ERC20 {
    address public admin;  
    string public name = "AARK";  
    string public symbol = "AARK";  
    uint8 public decimals = 18;  
    uint256 public INITIAL_SUPPLY = 0;  


     
    modifier onlyAdmin(){
        if (msg.sender == admin) _;
    }

     
    constructor(uint256 _INITIAL_SUPPLY,
                string _name,
                string _symbol,
                address _admin) public {
        require(_INITIAL_SUPPLY>0);
        name = _name;
        symbol = _symbol;
        INITIAL_SUPPLY = _INITIAL_SUPPLY;
        totalSupply_ = INITIAL_SUPPLY;
        admin = _admin;
        balances[admin] = INITIAL_SUPPLY;
    }



     
    function changeAdmin( address _newAdmin )
    onlyAdmin public returns (bool)  {
        balances[_newAdmin] = balances[_newAdmin].add(balances[admin]);
        balances[admin] = 0;
        admin = _newAdmin;
        return true;
    }
     
    function generateToken( address _target, uint256 _amount)
    onlyAdmin public returns (bool)  {
        balances[_target] = balances[_target].add(_amount);
        totalSupply_ = totalSupply_.add(_amount);
        INITIAL_SUPPLY = totalSupply_;
        return true;
    }


     
    function multiTransfer( address[] _tos, uint256[] _values)
    public returns (bool) {

        require(_tos.length == _values.length);
        uint256 len = _tos.length;
        require(len > 0);
        uint256 amount = 0;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            amount = amount.add(_values[i]);
        }
        require(amount <= balances[msg.sender]);
        for (uint256 j = 0; j < len; j = j.add(1)) {
            address _to = _tos[j];
            require(_to != address(0));
            balances[_to] = balances[_to].add(_values[j]);
            balances[msg.sender] = balances[msg.sender].sub(_values[j]);
            emit Transfer(msg.sender, _to, _values[j]);
        }
        return true;
    }

     
    function transfer(address _to, uint256 _value )
    public returns (bool) {

        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
    function transferFrom(address _from,address _to,
    uint256 _value)
    public returns (bool)
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


    

    
     
    function setName ( string _value )
    onlyAdmin  public returns (bool) {
        name = _value;
        return true;
    }
    
     
    function setSymbol ( string _value )
    onlyAdmin public returns (bool) {
        symbol = _value;
        return true;
    }


    



}