 

pragma solidity 0.4.15;

 
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

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
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

 

contract PausableOnce is Ownable {

     
    address public pauseMaster;

    uint constant internal PAUSE_DURATION = 14 days;
    uint64 public pauseEnd = 0;

    event Paused();

     
    function setPauseMaster(address _pauseMaster) onlyOwner external returns (bool success) {
        require(_pauseMaster != address(0));
        pauseMaster = _pauseMaster;
        return true;
    }

     
    function pause() onlyPauseMaster external returns (bool success) {
        require(pauseEnd == 0);
        pauseEnd = uint64(now + PAUSE_DURATION);
        Paused();
        return true;
    }

     
    modifier whenNotPaused() {
        require(now > pauseEnd);
        _;
    }

     
    modifier onlyPauseMaster() {
        require(msg.sender == pauseMaster);
        _;
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

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
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

 
contract InterfaceUpgradeAgent {

    uint32 public revision;
    uint256 public originalSupply;

     
    function upgradeFrom(address holder, uint256 tokenQty) public;
}

 

contract UpgradableToken is StandardToken, Ownable {

    using SafeMath for uint256;

    uint32 public REVISION;

     
    address public upgradeMaster = address(0);

     
    address public upgradeAgent = address(0);

     
    uint256 public totalUpgraded;

    event Upgrade(address indexed _from, uint256 _value);
    event UpgradeEnabled(address agent);

     
    function setUpgradeMaster(address _upgradeMaster) onlyOwner external {
        require(_upgradeMaster != address(0));
        upgradeMaster = _upgradeMaster;
    }

     
    function setUpgradeAgent(address _upgradeAgent, uint32 _revision)
        onlyUpgradeMaster whenUpgradeDisabled external
    {
        require((_upgradeAgent != address(0)) && (_revision != 0));

        InterfaceUpgradeAgent agent = InterfaceUpgradeAgent(_upgradeAgent);

        require(agent.revision() == _revision);
        require(agent.originalSupply() == totalSupply);

        upgradeAgent = _upgradeAgent;
        UpgradeEnabled(_upgradeAgent);
    }

     
    function upgrade(uint256 value) whenUpgradeEnabled external {
        require(value > 0);

        uint256 balance = balances[msg.sender];
        require(balance > 0);

         
        balances[msg.sender] = balance.sub(value);
        totalSupply = totalSupply.sub(value);
        totalUpgraded = totalUpgraded.add(value);
         
        InterfaceUpgradeAgent agent = InterfaceUpgradeAgent(upgradeAgent);
        agent.upgradeFrom(msg.sender, value);

        Upgrade(msg.sender, value);
    }

     
    modifier whenUpgradeEnabled() {
        require(upgradeAgent != address(0));
        _;
    }

     
    modifier whenUpgradeDisabled() {
        require(upgradeAgent == address(0));
        _;
    }

     
    modifier onlyUpgradeMaster() {
        require(msg.sender == upgradeMaster);
        _;
    }

}

 

contract Withdrawable {

    mapping (address => uint) pendingWithdrawals;

     
    event Withdrawal(address indexed drawer, uint256 weiAmount);

     
    event Withdrawn(address indexed drawer, uint256 weiAmount);

     
    function setWithdrawal(address drawer, uint256 weiAmount) internal returns (bool success) {
        if ((drawer != address(0)) && (weiAmount > 0)) {
            uint256 oldBalance = pendingWithdrawals[drawer];
            uint256 newBalance = oldBalance + weiAmount;
            if (newBalance > oldBalance) {
                pendingWithdrawals[drawer] = newBalance;
                Withdrawal(drawer, weiAmount);
                return true;
            }
        }
        return false;
    }

     
    function withdraw() public returns (bool success) {
        uint256 weiAmount = pendingWithdrawals[msg.sender];
        require(weiAmount > 0);

        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(weiAmount);
        Withdrawn(msg.sender, weiAmount);
        return true;
    }

}

 

contract SaviorToken is UpgradableToken, PausableOnce, Withdrawable {

    using SafeMath for uint256;

    string public constant name = "Savior Token";
    string public constant symbol = "SAVI";
     
    uint8  public constant decimals = 18;

     
    address public bounty;

     
    uint256 constant internal TOTAL_LIMIT   = 100000000 * (10 ** uint256(decimals));
     
    uint256 constant internal PRE_ICO_LIMIT = 10000000 * (10 ** uint256(decimals));

     
    
    enum Phases {PreStart, PreIcoA, PreIcoB, PreIcoC, MainIcoA, MainIcoB, MainIcoC, AfterIco}

    uint64 constant internal PRE_ICO_DURATION_A = 72 hours;
    uint64 constant internal PRE_ICO_DURATION_B = 240 hours;
    uint64 constant internal PRE_ICO_DURATION_C = 408 hours;
    uint64 constant internal ICO_DURATION_A = 168 hours;
    uint64 constant internal ICO_DURATION_B = 168 hours;
    uint64 constant internal ICO_DURATION_C = 1104 hours;

    uint64 constant internal PRE_ICO_DURATION = 720 hours;
    uint64 constant internal ICO_DURATION = 1440 hours;
    uint64 constant internal RETURN_WEI_PAUSE = 30 days;

     
    uint256 constant internal PreICO_SENDER_RATE_A = 140;
    uint256 constant internal PreICO_OWNER_RATE_A  =  10;
    uint256 constant internal PreICO_BOUNTY_RATE_A =  10;
    uint256 constant internal PreICO_TOTAL_RATE_A  =   PreICO_SENDER_RATE_A + PreICO_OWNER_RATE_A + PreICO_BOUNTY_RATE_A;
     
    uint256 constant internal PreICO_SENDER_RATE_B = 130;
    uint256 constant internal PreICO_OWNER_RATE_B  =  10;
    uint256 constant internal PreICO_BOUNTY_RATE_B =  10;
    uint256 constant internal PreICO_TOTAL_RATE_B  =   PreICO_SENDER_RATE_B + PreICO_OWNER_RATE_B + PreICO_BOUNTY_RATE_B;
     
    uint256 constant internal PreICO_SENDER_RATE_C = 120;
    uint256 constant internal PreICO_OWNER_RATE_C  =  10;
    uint256 constant internal PreICO_BOUNTY_RATE_C =  10;
    uint256 constant internal PreICO_TOTAL_RATE_C  =   PreICO_SENDER_RATE_C + PreICO_OWNER_RATE_C + PreICO_BOUNTY_RATE_C;

     
    uint256 constant internal ICO_SENDER_RATE_A = 110;
    uint256 constant internal ICO_OWNER_RATE_A  =  10;
    uint256 constant internal ICO_BOUNTY_RATE_A =  10;
    uint256 constant internal ICO_TOTAL_RATE_A  =   ICO_SENDER_RATE_A + ICO_OWNER_RATE_A + ICO_BOUNTY_RATE_A;
     
    uint256 constant internal ICO_SENDER_RATE_B = 105;
    uint256 constant internal ICO_OWNER_RATE_B  =  10;
    uint256 constant internal ICO_BOUNTY_RATE_B =  10;
    uint256 constant internal ICO_TOTAL_RATE_B  =   ICO_SENDER_RATE_B + ICO_OWNER_RATE_B + ICO_BOUNTY_RATE_B;
     
    uint256 constant internal ICO_SENDER_RATE_C = 100;
    uint256 constant internal ICO_OWNER_RATE_C  =  10;
    uint256 constant internal ICO_BOUNTY_RATE_C =  10;
    uint256 constant internal ICO_TOTAL_RATE_C  =   ICO_SENDER_RATE_C + ICO_OWNER_RATE_C + ICO_BOUNTY_RATE_C;

	
    struct Rates {
        uint256 toSender;
        uint256 toOwner;
        uint256 toBounty;
        uint256 total;
    }

    event NewTokens(uint256 amount);
    event NewFunds(address funder, uint256 value);
    event NewPhase(Phases phase);

     
    Phases public phase = Phases.PreStart;

     
    uint64 public preIcoOpeningTime;   
    uint64 public icoOpeningTime;      
    uint64 public closingTime;         
    uint64 public returnAllowedTime;   

    uint256 public totalProceeds;

     
    function SaviorToken(uint64 _preIcoOpeningTime) payable {
        require(_preIcoOpeningTime > now);

        preIcoOpeningTime = _preIcoOpeningTime;
        icoOpeningTime = preIcoOpeningTime + PRE_ICO_DURATION;
        closingTime = icoOpeningTime + ICO_DURATION;
    }

     
    function () payable external {
        create();
    }

     
    function setBounty(address _bounty, uint256 bountyTokens) onlyOwner external returns (bool success) {
        require(_bounty != address(0));
        bounty = _bounty;
        
        uint256 bounties = bountyTokens * 10**18;
        
        balances[bounty] = balances[bounty].add(bounties);
        totalSupply = totalSupply.add(bounties);
        
        NewTokens(bounties);
        return true;
    }

     
    function create() payable whenNotClosed whenNotPaused public returns (bool success) {
        require(msg.value > 0);
        require(now >= preIcoOpeningTime);

        uint256 weiToParticipate = msg.value;

        adjustPhaseBasedOnTime();

        if (phase != Phases.AfterIco || weiToParticipate < (0.01 * 10**18)) {

            Rates memory rates = getRates();
            uint256 newTokens = weiToParticipate.mul(rates.total);
            uint256 requestedSupply = totalSupply.add(newTokens);

             
            totalSupply = requestedSupply;
            balances[msg.sender] 	= balances[msg.sender].add(weiToParticipate.mul(rates.toSender));
            balances[owner] 		= balances[owner].add(weiToParticipate.mul(rates.toOwner));
            balances[bounty] 		= balances[bounty].add(weiToParticipate.mul(rates.toBounty));

             
            totalProceeds = totalProceeds.add(weiToParticipate);
            
             
            NewTokens(newTokens);
            NewFunds(msg.sender, weiToParticipate);

        } else {
            setWithdrawal(owner, weiToParticipate);
        }
        return true;
    }

     
    function returnWei() onlyOwner external {
        owner.transfer(this.balance);
    }

    function adjustPhaseBasedOnTime() internal {

        if (now >= closingTime) {
            if (phase != Phases.AfterIco) {
                phase = Phases.AfterIco;
            }
        } else if (now >= icoOpeningTime + ICO_DURATION_A + ICO_DURATION_B) {
            if (phase != Phases.MainIcoC) {
                phase = Phases.MainIcoC;
            }
		} else if (now >= icoOpeningTime + ICO_DURATION_A ) {
            if (phase != Phases.MainIcoB) {
                phase = Phases.MainIcoB;
            }
        } else if (now >= icoOpeningTime ) {
            if (phase != Phases.MainIcoA) {
                phase = Phases.MainIcoA;
            }
		} else if (now >= preIcoOpeningTime + PRE_ICO_DURATION_A + PRE_ICO_DURATION_B) {
            if (phase != Phases.PreIcoC) {
                phase = Phases.PreIcoC;
            }
		} else if (now >= preIcoOpeningTime + PRE_ICO_DURATION_A ) {
            if (phase != Phases.PreIcoB) {
                phase = Phases.PreIcoB;
            }
		} else if (now >= preIcoOpeningTime ) {
            if (phase != Phases.PreIcoA) {
                phase = Phases.PreIcoA;
            }
        } else if (phase == Phases.PreStart) {
            setDefaultParamsIfNeeded();
            phase = Phases.PreIcoA;
        }
    }

    function setDefaultParamsIfNeeded() internal {
        if (bounty == address(0)) {
            bounty = owner;
        }
        if (upgradeMaster == address(0)) {
            upgradeMaster = owner;
        }
        if (pauseMaster == address(0)) {
            pauseMaster = owner;
        }
    }

    function getRates() internal returns (Rates rates) {
		if (phase == Phases.PreIcoA) {
            rates.toSender 	= PreICO_SENDER_RATE_A;
            rates.toOwner 	= PreICO_OWNER_RATE_A;
            rates.toBounty 	= PreICO_BOUNTY_RATE_A;
            rates.total 	= PreICO_TOTAL_RATE_A;
        } else if (phase == Phases.PreIcoB) {
            rates.toSender 	= PreICO_SENDER_RATE_B;
            rates.toOwner 	= PreICO_OWNER_RATE_B;
            rates.toBounty 	= PreICO_BOUNTY_RATE_B;
            rates.total 	= PreICO_TOTAL_RATE_B;
        } else if (phase == Phases.PreIcoC) {
            rates.toSender 	= PreICO_SENDER_RATE_C;
            rates.toOwner 	= PreICO_OWNER_RATE_C;
            rates.toBounty 	= PreICO_BOUNTY_RATE_C;
            rates.total 	= PreICO_TOTAL_RATE_C;
        } else if (phase == Phases.MainIcoA) {
            rates.toSender 	= ICO_SENDER_RATE_A;
            rates.toOwner 	= ICO_OWNER_RATE_A;
            rates.toBounty 	= ICO_BOUNTY_RATE_A;
            rates.total 	= ICO_TOTAL_RATE_A;
        } else if (phase == Phases.MainIcoB) {
            rates.toSender 	= ICO_SENDER_RATE_B;
            rates.toOwner 	= ICO_OWNER_RATE_B;
            rates.toBounty 	= ICO_BOUNTY_RATE_B;
            rates.total 	= ICO_TOTAL_RATE_B;
        } else {
            rates.toSender 	= ICO_SENDER_RATE_C;
            rates.toOwner 	= ICO_OWNER_RATE_C;
            rates.toBounty 	= ICO_BOUNTY_RATE_C;
            rates.total 	= ICO_TOTAL_RATE_C;
        }
        return rates;
    }

     
    function transfer(address _to, uint256 _value)
        whenNotPaused limitForOwner public returns (bool success)
    {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        whenNotPaused limitForOwner public returns (bool success)
    {
        return super.transferFrom(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value)
        whenNotPaused limitForOwner public returns (bool success)
    {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        return super.approve(_spender, _value);
    }

     
    function increaseApproval(address _spender, uint _addedValue)
        whenNotPaused limitForOwner public returns (bool success)
    {
        return super.increaseApproval(_spender, _addedValue);
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue)
        whenNotPaused limitForOwner public returns (bool success)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

     
    function withdraw() whenNotPaused public returns (bool success) {
        return super.withdraw();
    }

     
    modifier whenClosed() {
        require(phase == Phases.AfterIco);
        _;
    }

     
    modifier whenNotClosed() {
        require(phase != Phases.AfterIco);
        _;
    }

     
    modifier limitForOwner() {
        require((msg.sender != owner) || (phase == Phases.AfterIco));
        _;
    }

     
    modifier afterWithdrawPause() {
        require(now > returnAllowedTime);
        _;
    }

}