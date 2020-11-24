 

pragma solidity ^0.4.10;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

 
contract BBDToken is StandardToken, Ownable {

     
    string public constant name = "BlockChain Board Of Derivatives Token";
    string public constant symbol = "BBD";
    uint256 public constant decimals = 18;
    string public constant version = '1.0.0';

     
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;

    bool public presaleFinalized = false;

    uint256 public constant presaleTokenCreationCap = 40000 * 10 ** decimals; 
    uint256 public constant presaleTokenCreationRate = 20000;  

     
    uint256 public saleStartTime;
    uint256 public saleEndTime;

    bool public saleFinalized = false;

    uint256 public constant totalTokenCreationCap = 240000 * 10 ** decimals;  
    uint256 public constant saleStartTokenCreationRate = 16600;  
    uint256 public constant saleEndTokenCreationRate = 10000;  

     
    address public migrationAgent;
    uint256 public totalMigrated;

     
    address public constant qtAccount = 0x87a9131485cf8ed8E9bD834b46A12D7f3092c263;
    address public constant coreTeamMemberOne = 0xe43088E823eA7422D77E32a195267aE9779A8B07;
    address public constant coreTeamMemberTwo = 0xad00884d1E7D0354d16fa8Ab083208c2cC3Ed515;

    uint256 public constant divisor = 10000;

     
    uint256 raised = 0;

     
    event Migrate(address indexed _from, address indexed _to, uint256 _value);
    event TokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _amount);

    function() payable {
        require(!presaleFinalized || !saleFinalized);  

        if (!presaleFinalized) {
            buyPresaleTokens(msg.sender);
        }
        else{
            buySaleTokens(msg.sender);
        }
    }

    function BBDToken(uint256 _presaleStartTime, uint256 _presaleEndTime, uint256 _saleStartTime, uint256 _saleEndTime) {
        require(_presaleStartTime >= now);
        require(_presaleEndTime >= _presaleStartTime);
        require(_saleStartTime >= _presaleEndTime);
        require(_saleEndTime >= _saleStartTime);

        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleEndTime;
        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;
    }

     
    function getTokenCreationRate() constant returns (uint256) {
        require(!presaleFinalized || !saleFinalized);

        uint256 creationRate;

        if (!presaleFinalized) {
             
            creationRate = presaleTokenCreationRate;
        } else {
             
            uint256 rateRange = saleStartTokenCreationRate - saleEndTokenCreationRate;
            uint256 timeRange = saleEndTime - saleStartTime;
            creationRate = saleStartTokenCreationRate.sub(rateRange.mul(now.sub(saleStartTime)).div(timeRange));
        }

        return creationRate;
    }
    
     
    function buyPresaleTokens(address _beneficiary) payable {
        require(!presaleFinalized);
        require(msg.value != 0);
        require(now <= presaleEndTime);
        require(now >= presaleStartTime);

        uint256 bbdTokens = msg.value.mul(getTokenCreationRate()).div(divisor);
        uint256 checkedSupply = totalSupply.add(bbdTokens);
        require(presaleTokenCreationCap >= checkedSupply);

        totalSupply = totalSupply.add(bbdTokens);
        balances[_beneficiary] = balances[_beneficiary].add(bbdTokens);

        raised += msg.value;
        TokenPurchase(msg.sender, _beneficiary, msg.value, bbdTokens);
    }

     
    function finalizePresale() onlyOwner external {
        require(!presaleFinalized);
        require(now >= presaleEndTime || totalSupply == presaleTokenCreationCap);

        presaleFinalized = true;

        uint256 ethForCoreMember = this.balance.mul(500).div(divisor);

        coreTeamMemberOne.transfer(ethForCoreMember);  
        coreTeamMemberTwo.transfer(ethForCoreMember);  
        qtAccount.transfer(this.balance);  
    }

     
    function buySaleTokens(address _beneficiary) payable {
        require(!saleFinalized);
        require(msg.value != 0);
        require(now <= saleEndTime);
        require(now >= saleStartTime);

        uint256 bbdTokens = msg.value.mul(getTokenCreationRate()).div(divisor);
        uint256 checkedSupply = totalSupply.add(bbdTokens);
        require(totalTokenCreationCap >= checkedSupply);

        totalSupply = totalSupply.add(bbdTokens);
        balances[_beneficiary] = balances[_beneficiary].add(bbdTokens);

        raised += msg.value;
        TokenPurchase(msg.sender, _beneficiary, msg.value, bbdTokens);
    }

     
    function finalizeSale() onlyOwner external {
        require(!saleFinalized);
        require(now >= saleEndTime || totalSupply == totalTokenCreationCap);

        saleFinalized = true;

         
        uint256 additionalBBDTokensForQTAccount = totalSupply.mul(2250).div(divisor);  
        totalSupply = totalSupply.add(additionalBBDTokensForQTAccount);
        balances[qtAccount] = balances[qtAccount].add(additionalBBDTokensForQTAccount);

        uint256 additionalBBDTokensForCoreTeamMember = totalSupply.mul(125).div(divisor);  
        totalSupply = totalSupply.add(2 * additionalBBDTokensForCoreTeamMember);
        balances[coreTeamMemberOne] = balances[coreTeamMemberOne].add(additionalBBDTokensForCoreTeamMember);
        balances[coreTeamMemberTwo] = balances[coreTeamMemberTwo].add(additionalBBDTokensForCoreTeamMember);

        uint256 ethForCoreMember = this.balance.mul(500).div(divisor);

        coreTeamMemberOne.transfer(ethForCoreMember);  
        coreTeamMemberTwo.transfer(ethForCoreMember);  
        qtAccount.transfer(this.balance);  
    }

     
    function migrate(uint256 _value) external {
        require(saleFinalized);
        require(migrationAgent != 0x0);
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalMigrated = totalMigrated.add(_value);
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }

    function setMigrationAgent(address _agent) onlyOwner external {
        require(saleFinalized);
        require(migrationAgent == 0x0);

        migrationAgent = _agent;
    }

     
    function icoOverview() constant returns (uint256 currentlyRaised, uint256 currentlyTotalSupply, uint256 currentlyTokenCreationRate){
        currentlyRaised = raised;
        currentlyTotalSupply = totalSupply;
        currentlyTokenCreationRate = getTokenCreationRate();
    }
}