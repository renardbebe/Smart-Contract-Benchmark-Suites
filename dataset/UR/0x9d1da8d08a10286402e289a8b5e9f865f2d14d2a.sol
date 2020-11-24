 

pragma solidity ^0.4.11;

 
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

    function toUINT112(uint256 a) internal constant returns(uint112) {
    assert(uint112(a) == a);
    return uint112(a);
  }

  function toUINT120(uint256 a) internal constant returns(uint120) {
    assert(uint120(a) == a);
    return uint120(a);
  }

  function toUINT128(uint256 a) internal constant returns(uint128) {
    assert(uint128(a) == a);
    return uint128(a);
  }

  function percent(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = (b*a/100) ;
    assert(c <= a);
    return c;
  }
}

contract Owned {

    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}

 
contract ERC20Basic {
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

  struct Account {
      uint256 balances;
      uint256 rawTokens;
      uint32 lastMintedTimestamp;
    }

     
    mapping(address => Account) accounts;


   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= accounts[msg.sender].balances);

     
    accounts[msg.sender].balances = accounts[msg.sender].balances.sub(_value);
    accounts[_to].balances = accounts[_to].balances.add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return accounts[_owner].balances;
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= accounts[_from].balances);
    require(_value <= allowed[_from][msg.sender]);

    accounts[_from].balances = accounts[_from].balances.sub(_value);
    accounts[_to].balances = accounts[_to].balances.add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract Infocash is StandardToken, Owned {
    string public constant name    = "Infocash";  
    uint8 public constant decimals = 8;               
    string public constant symbol  = "ICC";
    bool public canClaimToken = false;
    uint256 public constant maxSupply  = 86000000*10**uint256(decimals);
    uint256 public constant dateInit=1514073600  ;
    uint256 public constant dateICO=dateInit + 30 days;
    uint256 public constant dateIT=dateICO + 365 days;
    uint256 public constant dateMarketing=dateIT + 365 days;
    uint256 public constant dateEco=dateMarketing + 365 days;
    uint256 public constant dateManager=dateEco + 365 days; 
    uint256 public constant dateAdmin=dateManager + 365 days;                              
    
    enum Stage {
        NotCreated,
        ICO,
        IT,
        Marketing,
        Eco,
        MgmtSystem,
        Admin,
        Finalized
    }
     
    struct Supplies {
         
         
        uint256 total;
        uint256 rawTokens;
    }

     
    struct StageRelease {
      Stage stage;
      uint256 rawTokens;
      uint256 dateRelease;
    }

    Supplies supplies;
    StageRelease public  stageICO=StageRelease(Stage.ICO, maxSupply.percent(35), dateICO);
    StageRelease public stageIT=StageRelease(Stage.IT, maxSupply.percent(18), dateIT);
    StageRelease public stageMarketing=StageRelease(Stage.Marketing, maxSupply.percent(18), dateMarketing);
    StageRelease public stageEco=StageRelease(Stage.Eco, maxSupply.percent(18), dateEco);
    StageRelease public stageMgmtSystem=StageRelease(Stage.MgmtSystem, maxSupply.percent(9), dateManager);
    StageRelease public stageAdmin=StageRelease(Stage.Admin, maxSupply.percent(2), dateAdmin);

     
    function () {
      revert();
    }
     
    function totalSupply() public constant returns (uint256 total) {
      return supplies.total;
    }
    
    function mintToken(address _owner, uint256 _amount, bool _isRaw) onlyOwner internal {
      require(_amount.add(supplies.total)<=maxSupply);
      if (_isRaw) {
        accounts[_owner].rawTokens=_amount.add(accounts[_owner].rawTokens);
        supplies.rawTokens=_amount.add(supplies.rawTokens);
      } else {
        accounts[_owner].balances=_amount.add(accounts[_owner].balances);
      }
      supplies.total=_amount.add(supplies.total);
      Transfer(0, _owner, _amount);
    }

    function transferRaw(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= accounts[msg.sender].rawTokens);
    

     
    accounts[msg.sender].rawTokens = accounts[msg.sender].rawTokens.sub(_value);
    accounts[_to].rawTokens = accounts[_to].rawTokens.add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function setClaimToken(bool approve) onlyOwner public returns (bool) {
    canClaimToken=true;
    return canClaimToken;
  }

    function claimToken(address _owner) public returns (bool amount) {
      require(accounts[_owner].rawTokens!=0);
      require(canClaimToken);

      uint256 amountToken = accounts[_owner].rawTokens;
      accounts[_owner].rawTokens = 0;
      accounts[_owner].balances = amountToken + accounts[_owner].balances;
      return true;
    }

    function balanceOfRaws(address _owner) public constant returns (uint256 balance) {
      return accounts[_owner].rawTokens;
    }

    function blockTime() constant returns (uint32) {
        return uint32(block.timestamp);
    }

    function stage() constant returns (Stage) { 
      if(blockTime()<=dateInit) {
        return Stage.NotCreated;
      }

      if(blockTime()<=dateICO) {
        return Stage.ICO;
      }
        
      if(blockTime()<=dateIT) {
        return Stage.IT;
      }

      if(blockTime()<=dateMarketing) {
        return Stage.Marketing;
      }

      if(blockTime()<=dateEco) {
        return Stage.Eco;
      }

      if(blockTime()<=dateManager) {
        return Stage.MgmtSystem;
      }

      if(blockTime()<=dateAdmin) {
        return Stage.Admin;
      }
      
      return Stage.Finalized;
    }

    function releaseStage (uint256 amount, StageRelease storage stageRelease, bool isRaw) internal returns (uint256) {
      if(stageRelease.rawTokens>0) {
        int256 remain=int256(stageRelease.rawTokens - amount);
        if(remain<0)
          amount=stageRelease.rawTokens;
        stageRelease.rawTokens=stageRelease.rawTokens.sub(amount);
        mintToken(owner, amount, isRaw);
        return amount;
      }
      return 0;
    }

    function release(uint256 amount, bool isRaw) onlyOwner public returns (uint256) {
      uint256 amountSum=0;

      if(stage()==Stage.NotCreated) {
        throw;
      }

      if(stage()==Stage.ICO) {
        releaseStage(amount, stageICO, isRaw);
        amountSum=amountSum.add(amount);
        return amountSum;
      }

      if(stage()==Stage.IT) {
        releaseStage(amount, stageIT, isRaw);
        amountSum=amountSum.add(amount);
        return amountSum;
      }

      if(stage()==Stage.Marketing) {
        releaseStage(amount, stageMarketing, isRaw);
        amountSum=amountSum.add(amount);
        return amountSum;
      }

      if(stage()==Stage.Eco) {
        releaseStage(amount, stageEco, isRaw);
        amountSum=amountSum.add(amount);
        return amountSum;
      }

      if(stage()==Stage.MgmtSystem) {
        releaseStage(amount, stageMgmtSystem, isRaw);
        amountSum=amountSum.add(amount);
        return amountSum;
      }
      
      if(stage()==Stage.Admin ) {
        releaseStage(amount, stageAdmin, isRaw);
        amountSum=amountSum.add(amount);
        return amountSum;
      }
      
      if(stage()==Stage.Finalized) {
        owner=0;
        return 0;
      }
      return amountSum;
    }
}