 

pragma solidity ^0.4.21;

 

 
contract Ownable {
  address public owner;
 
   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract MAS is StandardToken, Ownable {
     
    string  public constant name = "MAS Token";
    string  public constant symbol = "MAS";
    uint8   public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY      = 1000000000 * (10 ** uint256(decimals));
  

    address public constant TEAM_ADDR = 0xe84604ab3d44F61CFD355E6D6c87ab2a5F686318;
    uint256 public constant TEAM_SUPPLY      = 200000000 * (10 ** uint256(decimals));

    address public constant FUND_ADDR = 0xb2b9bcDfee4504BcC24cdCCA0C6C358FcD47ab4F;
    uint256 public constant FUND_SUPPLY      = 100000000 * (10 ** uint256(decimals));

    address public constant STRC_ADDR = 0x308890fE38e51C422Ae633f3a98a719caa381754;
    uint256 public constant STRC_SUPPLY      = 100000000 * (10 ** uint256(decimals));

    address public constant COMM_ADDR = 0xF1f497213792283d9576172ae9083f65Cd6DD5E0;
    uint256 public constant COMM_SUPPLY      = 50000000 * (10 ** uint256(decimals));

    address public constant AIR_1 = 0xC571218f6F5d348537e21F0Cd6D49B532FfBb486;
    uint256 public constant AIR_1_SUPPLY      = 300000000 * (10 ** uint256(decimals));

    address public constant AIR_2 = 0x7acfd48833b70C3AA1B84b4521cB16f017Ae1f3d;
    uint256 public constant AIR_2_SUPPLY      = 250000000 * (10 ** uint256(decimals));

 

    uint256 public nextFreeCount = 7000 * (10 ** uint256(decimals)) ;
   
    
    mapping(address => bool) touched;
 
    
    uint256 public buyPrice = 60000;
  
    constructor() public {
     totalSupply_ = INITIAL_SUPPLY;

     balances[TEAM_ADDR] = TEAM_SUPPLY;
     emit Transfer(0x0, TEAM_ADDR, TEAM_SUPPLY);
     balances[FUND_ADDR] = FUND_SUPPLY;
     emit Transfer(0x0, FUND_ADDR, FUND_SUPPLY);
     balances[STRC_ADDR] = STRC_SUPPLY;
     emit Transfer(0x0, STRC_ADDR, STRC_SUPPLY);
     balances[COMM_ADDR] = COMM_SUPPLY;
     emit Transfer(0x0, COMM_ADDR, COMM_SUPPLY);
     balances[AIR_1] = AIR_1_SUPPLY;
     emit Transfer(0x0, AIR_1, AIR_1_SUPPLY);
     balances[AIR_2] = AIR_2_SUPPLY;
     emit Transfer(0x0, AIR_2, AIR_2_SUPPLY);
    }

    function _transfer(address _from, address _to, uint _value) internal {     
        require (balances[_from] >= _value);                
        require (balances[_to] + _value > balances[_to]);  
   
        balances[_from] = balances[_from].sub(_value);                          
        balances[_to] = balances[_to].add(_value);                             
         
        emit Transfer(_from, _to, _value);
    }
 
    
    function () external payable {
        if (!touched[msg.sender] && msg.value == 0) {
          touched[msg.sender] = true;
          _transfer(AIR_1, msg.sender, nextFreeCount ); 
          nextFreeCount = nextFreeCount.div(100000).mul(99999);
        }

        if (msg.value > 0) {
          uint amount = msg.value ;               
          _transfer(AIR_1, msg.sender, amount.mul(buyPrice)); 
          AIR_1.transfer(amount);
        }
    }
 
}