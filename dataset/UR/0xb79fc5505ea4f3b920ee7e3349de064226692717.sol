 

pragma solidity ^0.4.21;

 
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

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Ownable {
  address public owner;
  address private myAddress = this;

   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
     
    function() payable public {
    }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
    
  }

}

contract BBDMigration {
    function migrateFrom(address _from, uint256 _value) external;
}

 
contract BBDToken is StandardToken, Ownable {

     
    string public constant name = "Blockchain Board Of Derivatives Token";
    string public constant symbol = "BBD";
    uint256 public constant decimals = 18;
    string private constant version = '2.0.0';
    
     
    address public migrationAgent;
    uint256 public totalMigrated;
    
     
    event LogMigrate(address indexed _from, address indexed _to, uint256 _value);

     
    function migrate(address _beneficiary) onlyOwner external {
        require(migrationAgent != address(0x0));
        require(balances[_beneficiary] > 0);

        uint256 value = balances[_beneficiary];
        balances[msg.sender] = 0;
        totalSupply = totalSupply.sub(value);
        totalMigrated = totalMigrated.add(value);
        
        BBDMigration(migrationAgent).migrateFrom(_beneficiary, value);
        
        emit LogMigrate(_beneficiary, migrationAgent, value);
        
    }
    
     
    function setMigrationAgent(address _agent) onlyOwner external {

        migrationAgent = _agent;
    }
   
}

contract MigrationAgent is BBDToken {
    function migrateFrom(address _from, uint256 _value) external {
    
        require(msg.sender == address(0x5CA71Ea65ACB6293e71E62c41B720698b0Aa611C));
        balances[_from] = balances[_from].add(_value.mul(100));
        totalSupply = totalSupply.add(_value.mul(100));
    }
}