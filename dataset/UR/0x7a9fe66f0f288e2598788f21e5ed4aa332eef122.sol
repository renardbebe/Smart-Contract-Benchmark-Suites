 

pragma solidity ^0.4.15;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function toUINT112(uint256 a) internal pure returns(uint112) {
    assert(uint112(a) == a);
    return uint112(a);
  }

  function toUINT120(uint256 a) internal pure returns(uint120) {
    assert(uint120(a) == a);
    return uint120(a);
  }

  function toUINT128(uint256 a) internal pure returns(uint128) {
    assert(uint128(a) == a);
    return uint128(a);
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract PSIToken is StandardToken {

  string public constant name = "PSI Token";
  string public constant symbol = "PSI";
  uint8 public constant decimals = 18;


  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));

   
  function PSIToken() public {
    totalSupply = INITIAL_SUPPLY;
    

     
    balances[0xa801fcD3CDf65206F567645A3E8c4537739334A2] = 150000000 * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0xa801fcD3CDf65206F567645A3E8c4537739334A2, 150000000 * (10 ** uint256(decimals)));

     
    balances[0xE95aaFA9286337c89746c97fFBD084aD90AFF8Df] = 350000000 * (10 ** uint256(decimals));
    emit Transfer(msg.sender,0xE95aaFA9286337c89746c97fFBD084aD90AFF8Df, 350000000 * (10 ** uint256(decimals)));

    
     
    balances[0xDCe73461af69C315B87dbb015F3e1341294d72c7] = 100000000 * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0xDCe73461af69C315B87dbb015F3e1341294d72c7, 100000000 * (10 ** uint256(decimals)));

     
    balances[0x0d5A4EBbC1599006fdd7999F0e1537b3e60f0dc0] = 230000000 * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0x0d5A4EBbC1599006fdd7999F0e1537b3e60f0dc0, 230000000 * (10 ** uint256(decimals)));

     
    balances[0x63de19f0028F8402264052D9163AC66ca0c8A26c] = 120000000 * (10 ** uint256(decimals));
    emit Transfer(msg.sender,0x63de19f0028F8402264052D9163AC66ca0c8A26c, 120000000 * (10 ** uint256(decimals)));

    
     
    balances[0x403121629cfa4fC39aAc8Bf331AD627B31AbCa29] = 30000000 * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0x403121629cfa4fC39aAc8Bf331AD627B31AbCa29, 30000000 * (10 ** uint256(decimals)));


     
    balances[0xBD1acB661e8211EE462114d85182560F30BE7A94] = 20000000 * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0xBD1acB661e8211EE462114d85182560F30BE7A94, 20000000 * (10 ** uint256(decimals)));

    
  }

}