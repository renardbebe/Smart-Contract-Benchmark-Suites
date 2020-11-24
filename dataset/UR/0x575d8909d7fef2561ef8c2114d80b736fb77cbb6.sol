 

pragma solidity ^0.4.25;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
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

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
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

contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

contract ABChainRTBtoken is StandardToken {
  using SafeMath for uint256;

  string public name = "AB-CHAIN RTB token";
  string public symbol = "RTB";
  uint256 public decimals = 18;
  uint256 public INITIAL_SUPPLY = 100000000 * 1 ether;
  uint256 public burnedCount = 0;
  uint256 public burnedAfterSaleCount = 0;
  address public contractOwner = 0;
  address public migrationAgent = 0;

  event Burn(address indexed burner, uint256 value);
  event Migrate(address indexed migrator, uint256 value);
  
  function ABChainRTBtoken() {
      burnedCount = 0;
      burnedAfterSaleCount = 0;
      totalSupply = INITIAL_SUPPLY;
      balances[msg.sender] = INITIAL_SUPPLY;
      contractOwner = msg.sender;
  }
  
  function migrate() {
        require(migrationAgent != 0);
        uint256 _value = balances[msg.sender];
        require(_value > 0);
        burn(_value);
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, _value);
    }

    function setMigrationAgent(address _agent) {
        require(msg.sender == contractOwner);
        migrationAgent = _agent;
    }

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    burnedCount = burnedCount.add(_value);
    Burn(burner, _value);
    }
   
  function burnaftersale(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    burnedAfterSaleCount = burnedAfterSaleCount.add(_value);
    Burn(burner, _value);
    }
    
     
    function () payable {
        require(migrationAgent != 0 && msg.value == 0);
        migrate();
    }
}

 
contract ABChainNetContract_v5 {
    using SafeMath for uint256;
    
    address public contractOwner = 0;
    address public tokenAddress = 0xEC491c1088Eae992B7A214efB0a266AD0927A72A;
    address public ABChainRevenueAddress = 0x651Ccecc133dEa9635c84FC2C17707Ee18729f62;
    address public ABChainPBudgetsAddress = 0x5B16ce4534c1a746cffE95ae18083969e9e1F5e9;
    uint256 public tokenBurningPercentage = 500;  
    uint256 public revenuePercentage = 500;  
    uint256 public processedRTBs = 0;
    uint256 public burnedRTBs = 0;
    uint256 public netRevenueRTBs = 0;
    uint256 public publrsBudgRTBs = 0;
    uint256 public processingCallsCount = 0;
    
     
    event RTBProcessing(
        address indexed sender,
        uint256 balanceBefore,
        uint256 burned,
        uint256 sendedToPBudgets,
        uint256 sendedToRevenue,
        address indexed curABChainRevenueAddress,
        address indexed curABChainPBudgetsAddress,
        uint256 curRevPerc,
        uint256 curTokenBurningPerc,
        address curContractOwner
    );
    
    constructor () public {
        contractOwner = msg.sender;
    }
    
    function unprocessedRTBBalance() public view returns (uint256) {
        return ABChainRTBtoken(tokenAddress).balanceOf(address(this));
    }
    
     
    function changeOwner(address _owner) public {
        require(msg.sender == contractOwner);
        contractOwner = _owner;
    }
    
     
    function changeTokenAddress(address _tokenAddress) public {
        require(msg.sender == contractOwner);
        tokenAddress = _tokenAddress;
    }
    
     
    function changeABChainRevenueAddress(address _ABChainRevenueAddress) public {
        require(msg.sender == contractOwner);
        ABChainRevenueAddress = _ABChainRevenueAddress;
    }
    
     
    function changeABChainPBudgetsAddress(address _ABChainPBudgetsAddress) public {
        require(msg.sender == contractOwner);
        ABChainPBudgetsAddress = _ABChainPBudgetsAddress;
    }
    
     
    function changeTokenBurningPercentage(uint256 _tokenBurningPercentage) public {
        require(msg.sender == contractOwner);
        tokenBurningPercentage = _tokenBurningPercentage;
    }
    
     
    function changeRevenuePercentage(uint256 _revenuePercentage) public {
        require(msg.sender == contractOwner);
        revenuePercentage = _revenuePercentage;
    }
    
     
    function rtbPaymentsProcessing() public {
        uint256 _balance = ABChainRTBtoken(tokenAddress).balanceOf(address(this));
        require(_balance > 0);
        
        processingCallsCount = processingCallsCount.add(1);
        
        uint256 _forBurning = uint256(_balance.div(10000)).mul(tokenBurningPercentage);
        
        uint256 _forRevenue = uint256(_balance.div(10000)).mul(revenuePercentage);
        
        uint256 _forPBudgets = uint256(_balance.sub(_forBurning)).sub(_forRevenue);
        
        ABChainRTBtoken(tokenAddress).transfer(ABChainPBudgetsAddress, _forPBudgets);
        
        ABChainRTBtoken(tokenAddress).transfer(ABChainRevenueAddress, _forRevenue);
        
        ABChainRTBtoken(tokenAddress).burn(_forBurning);
        
        processedRTBs = processedRTBs.add(_balance);
        burnedRTBs = burnedRTBs.add(_forBurning);
        publrsBudgRTBs = publrsBudgRTBs.add(_forPBudgets);
        netRevenueRTBs = netRevenueRTBs.add(_forRevenue);

        emit RTBProcessing(
            msg.sender,
            _balance,
            _forBurning,
            _forPBudgets,
            _forRevenue,
            ABChainRevenueAddress,
            ABChainPBudgetsAddress,
            revenuePercentage,
            tokenBurningPercentage,
            contractOwner
        );
    }

     
    function () payable public {
        require(msg.value == 0);
    }
}