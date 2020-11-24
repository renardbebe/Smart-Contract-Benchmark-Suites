 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
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

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping(address => bool) public frozenAccount;

  event FrozenFunds(address target, bool frozen);

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(!frozenAccount[msg.sender]);
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

   
  function freezeAccount(address target, bool freeze) public onlyOwner {
    frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
  }
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(!frozenAccount[_from]);
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
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

}


 
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

   
  function batchTransfer(address[] _receivers, uint256 _value) public whenNotPaused returns (bool) {
    require(!frozenAccount[msg.sender]);

    uint receiverCount = _receivers.length;
    require(receiverCount > 0);

    uint256 amount = _value.mul(uint256(receiverCount));
    require(_value > 0 && balances[msg.sender] >= amount);

    balances[msg.sender] = balances[msg.sender].sub(amount);
    for (uint i = 0; i < receiverCount; i++) {
        balances[_receivers[i]] = balances[_receivers[i]].add(_value);
        emit Transfer(msg.sender, _receivers[i], _value);
    }

    return true;
  }

}

contract FDN is PausableToken {
    string public constant name = "FDN";
    string public constant symbol = "FDN";
    uint8 public constant decimals = 18;
    
    function FDN() public {
      totalSupply_ = 268000000 * (10 ** uint256(decimals));
      balances[msg.sender] = 241200000 * (10 ** uint256(decimals));
      balances[0x7a24b9d025e19f8d2954858c5ccb7a0c3de0a0f3] = 2680000 * (10 ** uint256(decimals));
      balances[0x52a6524a7283ef242e085946af31562dedc3f2b5] = 5360000 * (10 ** uint256(decimals));
      balances[0x807a418aa81b2df900c15dc770aec377ed516c24] = 8040000 * (10 ** uint256(decimals));
      balances[0xacd7c6fd2ed0229d667dd5f62d6d67aa15f92cb1] = 10720000 * (10 ** uint256(decimals));
      emit Transfer(address(0), msg.sender, 241200000 * (10 ** uint256(decimals)));
      emit Transfer(address(0), 0x7a24b9d025e19f8d2954858c5ccb7a0c3de0a0f3, 2680000 * (10 ** uint256(decimals)));
      emit Transfer(address(0), 0x52a6524a7283ef242e085946af31562dedc3f2b5, 5360000 * (10 ** uint256(decimals)));
      emit Transfer(address(0), 0x807a418aa81b2df900c15dc770aec377ed516c24, 8040000 * (10 ** uint256(decimals)));
      emit Transfer(address(0), 0xacd7c6fd2ed0229d667dd5f62d6d67aa15f92cb1, 10720000 * (10 ** uint256(decimals)));
      paused = false;
  }
}