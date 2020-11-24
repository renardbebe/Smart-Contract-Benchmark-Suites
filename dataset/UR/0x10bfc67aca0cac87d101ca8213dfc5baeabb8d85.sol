 

pragma solidity ^0.4.23;

 
library SafeMath {

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
  
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
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferToVC(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval( address indexed owner, address indexed spender, uint256 value );
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;
  
  mapping(address => uint256) internal freezeBalances;
  
  mapping(address => uint256) internal transferTime;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  
  modifier checkFreeze(address _from, uint256 _value) {
    uint256 span = now.sub(transferTime[_from]);                             
    uint256 value2 = balances[_from].sub(_value);                            
    uint256 freeze = freezeBalances[_from];                                  
    require(
      freeze == 0 ||                                                         
      value2 >= freeze ||                                                    
      span > 180 days && value2 >= freeze.mul(0.7 ether).div(1 ether) ||     
      span > 210 days && value2 >= freeze.mul(0.4 ether).div(1 ether) ||     
      span > 240 days                                                        
    );
    _;
  }
  
   
  function transfer(address _to, uint256 _value) public checkFreeze(msg.sender, _value) returns (bool) {
     require(_to != address(0));
     require(_value <= balances[msg.sender]);
     balances[msg.sender] = balances[msg.sender].sub(_value);
     balances[_to] = balances[_to].add(_value);
     emit Transfer(msg.sender, _to, _value);
     return true;
  }
  
   
  function transferToVC(address _to, uint256 _value) public checkFreeze(msg.sender, _value) returns (bool) {
    transfer(_to, _value);
	freezeBalances[_to]=freezeBalances[_to].add(_value);     
	transferTime[_to] = now;     
    return true;
  }


   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
  
  function timeOf(address _owner) public view returns (uint256) {
    return transferTime[_owner];
  }
  
  function freezeBalanceOf(address _owner) public view returns (uint256) {
    return freezeBalances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom( address _from, address _to, uint256 _value ) public checkFreeze(_from, _value) returns (bool) {
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

   
  function allowance( address _owner, address _spender ) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
}

contract ABTToken is StandardToken {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor() public {
    name = "ABTToken";
    symbol = "ABT";
    decimals = 8;
    totalSupply_ = 1000000000000000000;
    balances[0xB97f41cc340899DbA210BdCc86a912ef100eFE96] = totalSupply_;
    emit Transfer(address(0), 0xB97f41cc340899DbA210BdCc86a912ef100eFE96, totalSupply_);
  }
}