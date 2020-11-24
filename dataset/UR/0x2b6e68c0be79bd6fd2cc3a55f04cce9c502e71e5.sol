 

pragma solidity ^0.4.18;

 
 
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

 

contract DiaToken is StandardToken {
  string public constant name = "DiaToken";
  string public constant symbol = "DIA";
  uint8 public constant decimals = 18;
  uint256 public totalRaised;
  address public ownerWallet;

  uint256 public constant TOKEN_CAP = 100000000000 * (10 ** uint256(decimals));

  function DiaToken() public {
      totalSupply_ = TOKEN_CAP;
      balances[msg.sender] = TOKEN_CAP;
      totalRaised = 0;
      ownerWallet = msg.sender;
  }

  function() public payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address beneficiary) public payable {
    uint256 weiAmount = msg.value;
    require(beneficiary != address(0));
    require(weiAmount != 0);

     
    uint256 rate = _getRate();
    uint256 amount = weiAmount.mul(rate);

    require(amount <= balances[ownerWallet]);
    balances[ownerWallet] = balances[ownerWallet].sub(amount);
    balances[beneficiary] = balances[beneficiary].add(amount);
    Transfer(ownerWallet, beneficiary, amount);

    ownerWallet.transfer(weiAmount);

     
    totalRaised = totalRaised.add(weiAmount);
  }

  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);

    if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
    return true;
  }

  function _getRate() internal view returns (uint256) {
    uint256 _val = balances[ownerWallet];
    uint256 _rate = 90000;
    if (_val > 90000000000) {
      _rate = 90000;
    } else if (_val > 80000000000) {
      _rate = 80000;
    } else if (_val > 70000000000) {
      _rate = 70000;
    } else if (_val > 60000000000) {
      _rate = 60000;
    } else if (_val > 50000000000) {
      _rate = 50000;
    } else if (_val > 40000000000) {
      _rate = 40000;
    } else if (_val > 30000000000) {
      _rate = 30000;
    } else if (_val > 20000000000) {
      _rate = 20000;
    } else if (_val > 1000000000) {
      _rate = 10000;
    } else {
      _rate = 1000;
    }

    return _rate;
  }
}