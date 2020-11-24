 

pragma solidity ^0.4.23;
 
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


   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  address master;

  bool public paused;

  modifier isMaster {
      require(msg.sender == master);
      _;
  }

  modifier isPause {
   require(paused == true);
   _;
 }

  modifier isNotPause {
   require(paused == false);
   _;
  }

   
  function transfer(address _to, uint256 _value) public isNotPause returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public isNotPause
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

   
  function approve(address _spender, uint256 _value) public isNotPause returns (bool) {
    require(_spender != address(0));
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
    public isNotPause
    returns (bool)
  {
    require(_spender != address(0));
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public isNotPause
    returns (bool)
  {
    require(_spender != address(0));
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


contract DHCToken is StandardToken {

  string public constant name = "DigItal Homo Sapiens Coin";
  string public constant symbol = "DHC";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));

  address private constant coinbase_address       = 0x66b37a85019E149Cc7882695F4E824DE2b237d55;
  uint8 private constant coinbase_percent         = 100;

   
  constructor(address _master) public {
   require(_master != address(0));
   totalSupply_ = INITIAL_SUPPLY;
   master = _master;
   paused = false;
   balances[coinbase_address]  = INITIAL_SUPPLY * coinbase_percent / 100;
 }

  function batchTransfer(address[] _to, uint256[] _amount) public isNotPause returns (bool) {
     for (uint i = 0; i < _to.length; i++) {
       transfer(_to[i] , _amount[i]);
     }
     return true;
   }

   function setPause() public isMaster isNotPause{
     paused = true;
   }

   function setResume() public isMaster isPause{
     paused = false;
   }

   function pauseStatus() public view isMaster returns (bool){
     return paused;
   }



}