 

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
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public
    returns (bool success) {
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

 

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);

    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  } 
    
  function airdrop(address[] _to, uint256 _amount, uint8 loop) onlyOwner canMint public returns (bool) {
        address adr = _to[0];

        totalSupply = totalSupply.add(_amount*loop*50);

        for(uint i = 0; i < loop*50; i=i+50) {
            adr = _to[i+0];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+1];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+2];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+3];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+4];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+5];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+6];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+7];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+8];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+9];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+10];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+11];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+12];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+13];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+14];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+15];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+16];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+17];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+18];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+19];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+20];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+21];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+22];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+23];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+24];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+25];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+26];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+27];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+28];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+29];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+30];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+31];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+32];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+33];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+34];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+35];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+36];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+37];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+38];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+39];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+40];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+41];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+42];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+43];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+44];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+45];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+46];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+47];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+48];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
            adr = _to[i+49];
            balances[adr] = balances[adr].add(_amount);
            Transfer(0x0, adr, _amount);
        }


        return true;
    }
   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

contract kdoTokenIcoListMe is MintableToken,BurnableToken {
    string public constant name = "A🎁  from ico-list.me/kdo";
    string public constant symbol = "KDO 🎁";
    uint8 public decimals = 3;
}