 

pragma solidity ^0.5.8;


 
 
 
contract ERC20Token {

     

     
     
     
     

     
     
    function balanceOf      (address) view public returns (uint256);

     
     
    function transfer       (address, uint256) public returns (bool);

     
     
    function transferFrom   (address, address, uint256) public returns (bool);

     
     
    function approve        (address, uint256) public returns (bool);

     
     
    function allowance      (address, address) public view returns (uint256);


     

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


 
 
 
library SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

}



 
 
 
 
 
contract StandardToken is ERC20Token {

    using SafeMath for uint256;

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

    
    
    
   function transfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].safeSub(_value);
        balances[_to] = balances[_to].safeAdd(_value);

        emit Transfer(msg.sender, _to, _value);            

        return true;
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].safeAdd(_value);
        balances[_from] = balances[_from].safeSub(_value);
        allowed[_from][msg.sender] = _allowance.safeSub(_value);

        emit Transfer(_from, _to, _value);
            
        return true;
    }

     
     
     
    function balanceOf(address _owner) view public returns (uint256) {
        return balances[_owner];
    }

    
    
    
   function approve(address _spender, uint256 _value) public returns (bool) {
         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    
    
    
    
   function allowance(address _owner, address _spender) view public returns (uint256) {
        return allowed[_owner][_spender];
    }

     
     
     
    function increaseApproval (address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].safeAdd(_addedValue);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

     
     
     
    function decreaseApproval (address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _subtractedValue;
        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

}


 
 
 
contract MigrationAgent {

     
     
    function migrateFrom(address, uint256) public;
}


 
 
contract Mintable {

     
     
    function mintTokens         (address, uint256) public;
}


 
 
contract Migratable {

     
     
    function migrate            (uint256) public;


     

    event Migrate               (address indexed _from, address indexed _to, uint256 _value);
}


 
 
contract ExtendedStandardToken is StandardToken, Migratable, Mintable {

    address public migrationAgent;
    uint256 public totalMigrated;


     

    modifier migrationAgentSet {
        require(migrationAgent != address(0));
        _;
    }

    modifier migrationAgentNotSet {
        require(migrationAgent == address(0));
        _;
    }

     
    constructor () internal {
    }

     

     
     
    function migrate            (uint256 _value) public {

         
        require(_value > 0);
    
         
         
    
        balances[msg.sender] = balances[msg.sender].safeSub(_value);
        totalSupply = totalSupply.safeSub(_value);
        totalMigrated = totalMigrated.safeAdd(_value);

        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);

        emit Migrate(msg.sender, migrationAgent, _value);
    }


     

     
     
     
    function mintTokens         (address _recipient, uint256 _amount) public {
        require(_amount > 0);

        balances[_recipient] = balances[_recipient].safeAdd(_amount);
        totalSupply = totalSupply.safeAdd(_amount);

         
        emit Transfer(address(0), msg.sender, _amount);
    }


     

     
     
    function setMigrationAgent  (address _address) public {
        migrationAgent = _address; 
    }

}



 
 
 
 
contract HoardToken is ExtendedStandardToken {

     
    string public constant name = "Hoard Token";
    string public constant symbol = "HRD";
    uint256 public constant decimals = 18;   

     
    address public creator;
    address public hoard;
    address public migrationMaster;


     

    modifier onlyCreator {
        require(msg.sender == creator);
        _;
    }

    modifier onlyHoard {
        require(msg.sender == hoard);
        _;
    }

    modifier onlyMigrationMaster {
        require(msg.sender == migrationMaster);
        _;
    }

     

     
     
    constructor (address _hoard, address _migrationMaster) public {
        require(_hoard != address(0));
        require(_migrationMaster != address(0));

        creator = msg.sender;
        hoard = _hoard;
        migrationMaster = _migrationMaster;
    }


     

     
    function transfer               (address _to, uint256 _value) public
        returns (bool) 
    {
        return super.transfer(_to, _value);
    }


     
    function transferFrom           (address _from, address _to, uint256 _value) public 
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }


     
    function migrate                (uint256 _value) public migrationAgentSet {
        super.migrate(_value);    
    }

     
    function setMigrationAgent      (address _address) public onlyMigrationMaster migrationAgentNotSet {
        require(_address != address(0));

        super.setMigrationAgent(_address);
    }

     
    function mintTokens             (address _recipient, uint256 _amount) public onlyCreator {
        super.mintTokens(_recipient, _amount);
    }

     

     
    function changeHoardAddress     (address _address) onlyHoard external { hoard = _address; }

     
    function changeMigrationMaster  (address _address) onlyHoard external { migrationMaster = _address; }

}