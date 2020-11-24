 

pragma solidity ^0.4.13;

 
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
    string private constant version = '1.0.0';

     
    uint256 public constant startTime = 1506844800;  
    uint256 public constant endTime = 1509523200;   

    uint256 public constant creationMaxCap = 300000000 * 10 ** decimals;
    uint256 public constant creationMinCap = 2500000 * 10 ** decimals;

    uint256 private constant startCreationRateOnTime = 1666;  
    uint256 private constant endCreationRateOnTime = 1000;  

    uint256 private constant quantityThreshold_10 = 10 ether;
    uint256 private constant quantityThreshold_30 = 30 ether;
    uint256 private constant quantityThreshold_100 = 100 ether;
    uint256 private constant quantityThreshold_300 = 300 ether;

    uint256 private constant quantityBonus_10 = 500;     
    uint256 private constant quantityBonus_30 = 1000;   
    uint256 private constant quantityBonus_100 = 1500;  
    uint256 private constant quantityBonus_300 = 2000;  

     
    bool public finalized = false;

     
    address public migrationAgent;
    uint256 public totalMigrated;

     
    address public exchangeAddress;

     
    address private constant mainAccount = 0xEB1D40f6DA0E77E2cA046325F6F2a76081B4c7f4;
    address private constant coreTeamMemberOne = 0xe43088E823eA7422D77E32a195267aE9779A8B07;
    address private constant coreTeamMemberTwo = 0xad00884d1E7D0354d16fa8Ab083208c2cC3Ed515;

     
    uint256 private raised = 0;

     
     
    mapping (address => uint256) private ethBalances;

    uint256 private constant divisor = 10000;

     
    event LogRefund(address indexed _from, uint256 _value);
    event LogMigrate(address indexed _from, address indexed _to, uint256 _value);
    event LogBuy(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _amount);

     
    modifier onlyWhenICOReachedCreationMinCap() {
        require( totalSupply >= creationMinCap );
        _;
    }

    function() payable {
        buy(msg.sender);
    }

    function creationRateOnTime() public constant returns (uint256) {
        uint256 currentPrice;

        if (now > endTime) {
            currentPrice = endCreationRateOnTime;
        }
        else {
             
            uint256 rateRange = startCreationRateOnTime - endCreationRateOnTime;
            uint256 timeRange = endTime - startTime;
            currentPrice = startCreationRateOnTime.sub(rateRange.mul(now.sub(startTime)).div(timeRange));
        }

        return currentPrice;
    }

     
    function calculateBDD(uint256 _ethVal) private constant returns (uint256) {
        uint256 bonus;

         
        if (_ethVal < quantityThreshold_10) {
            bonus = 0;  
        }
        else if (_ethVal < quantityThreshold_30) {
            bonus = quantityBonus_10;  
        }
        else if (_ethVal < quantityThreshold_100) {
            bonus = quantityBonus_30;  
        }
        else if (_ethVal < quantityThreshold_300) {
            bonus = quantityBonus_100;  
        }
        else {
            bonus = quantityBonus_300;  
        }

         
        return _ethVal.mul(creationRateOnTime()).mul(divisor.add(bonus)).div(divisor);
    }

     
    function buy(address _beneficiary) payable {
        require(!finalized);
        require(msg.value != 0);
        require(now <= endTime);
        require(now >= startTime);

        uint256 bbdTokens = calculateBDD(msg.value);
        uint256 additionalBBDTokensForMainAccount = bbdTokens.mul(2250).div(divisor);  
        uint256 additionalBBDTokensForCoreTeamMember = bbdTokens.mul(125).div(divisor);  

         
        uint256 checkedSupply = totalSupply.add(bbdTokens)
                                           .add(additionalBBDTokensForMainAccount)
                                           .add(2 * additionalBBDTokensForCoreTeamMember);

        require(creationMaxCap >= checkedSupply);

        totalSupply = checkedSupply;

         
        balances[_beneficiary] = balances[_beneficiary].add(bbdTokens);
        balances[mainAccount] = balances[mainAccount].add(additionalBBDTokensForMainAccount);
        balances[coreTeamMemberOne] = balances[coreTeamMemberOne].add(additionalBBDTokensForCoreTeamMember);
        balances[coreTeamMemberTwo] = balances[coreTeamMemberTwo].add(additionalBBDTokensForCoreTeamMember);

        ethBalances[_beneficiary] = ethBalances[_beneficiary].add(msg.value);

        raised += msg.value;

        if (exchangeAddress != 0x0 && totalSupply >= creationMinCap && msg.value >= 1 ether) {
             
            exchangeAddress.transfer(msg.value.mul(1000).div(divisor));  
        }

        LogBuy(msg.sender, _beneficiary, msg.value, bbdTokens);
    }

     
    function finalize() onlyOwner external {
        require(!finalized);
        require(now >= endTime || totalSupply >= creationMaxCap);

        finalized = true;

        uint256 ethForCoreMember = raised.mul(500).div(divisor);

        coreTeamMemberOne.transfer(ethForCoreMember);  
        coreTeamMemberTwo.transfer(ethForCoreMember);  
        mainAccount.transfer(this.balance);  
    }

     
    function refund() external {
        require(now > endTime);
        require(totalSupply < creationMinCap);

        uint256 bddVal = balances[msg.sender];
        require(bddVal > 0);
        uint256 ethVal = ethBalances[msg.sender];
        require(ethVal > 0);

        balances[msg.sender] = 0;
        ethBalances[msg.sender] = 0;
        totalSupply = totalSupply.sub(bddVal);

        msg.sender.transfer(ethVal);

        LogRefund(msg.sender, ethVal);
    }

     
    function migrate(uint256 _value) external {
        require(finalized);
        require(migrationAgent != 0x0);
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalMigrated = totalMigrated.add(_value);

        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);

        LogMigrate(msg.sender, migrationAgent, _value);
    }

     
    function setMigrationAgent(address _agent) onlyOwner external {
        require(finalized);
        require(migrationAgent == 0x0);

        migrationAgent = _agent;
    }

     
    function setExchangeAddress(address _exchangeAddress) onlyOwner external {
        require(exchangeAddress == 0x0);

        exchangeAddress = _exchangeAddress;
    }

    function transfer(address _to, uint _value) onlyWhenICOReachedCreationMinCap returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) onlyWhenICOReachedCreationMinCap returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function transferToExchange(address _from, uint256 _value) onlyWhenICOReachedCreationMinCap returns (bool) {
        require(msg.sender == exchangeAddress);

        balances[exchangeAddress] = balances[exchangeAddress].add(_value);
        balances[_from] = balances[_from].sub(_value);

        Transfer(_from, exchangeAddress, _value);

        return true;
    }

     
    function icoOverview() constant returns (uint256 currentlyRaised, uint256 currentlyTotalSupply, uint256 currentlyCreationRateOnTime){
        currentlyRaised = raised;
        currentlyTotalSupply = totalSupply;
        currentlyCreationRateOnTime = creationRateOnTime();
    }
}