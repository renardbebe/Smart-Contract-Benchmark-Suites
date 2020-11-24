 

pragma solidity ^0.4.13;

library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

contract BurnableToken is StandardToken {

   
  address public constant BURN_ADDRESS = 0;

   
  event Burned(address burner, uint burnedAmount);

   
  function burn(uint burnAmount) {
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(burnAmount);
    totalSupply_ = totalSupply_.sub(burnAmount);
    Burned(burner, burnAmount);

     
     
     
    Transfer(burner, BURN_ADDRESS, burnAmount);
  }
}

contract LimitedTransferToken is ERC20 {

     
    modifier canTransferLimitedTransferToken(address _sender, uint256 _value) {
        require(_value <= transferableTokens(_sender, uint64(now)));
        _;
    }

     
    function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
        return balanceOf(holder);
    }
}

contract ReleasableToken is ERC20, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  modifier inReleaseState(bool releaseState) {
    if(releaseState != released) {
      revert();
    }
    _;
  }

   
  modifier onlyReleaseAgent() {
    if(msg.sender != releaseAgent) {
      revert();
    }
    _;
  }

   
  modifier canTransferReleasable(address _sender) {

    if(!released) {
        if(!transferAgents[_sender]) {
            revert();
        }
    }

    _;
  }

   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }
}

contract UpgradeAgent {

  uint public originalSupply;

   
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;
}

contract UpgradeableToken is StandardToken {

     
    address public upgradeMaster;

     
    UpgradeAgent public upgradeAgent;

     
    uint256 public totalUpgraded;

     
    enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

     
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);

     
    event UpgradeAgentSet(address agent);

     
    function UpgradeableToken(address _upgradeMaster) public {
        upgradeMaster = _upgradeMaster;
    }

     
    function upgrade(uint256 value) public {

        UpgradeState state = getUpgradeState();
        if (!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
             
            revert();
        }

         
        if (value == 0) revert();

        balances[msg.sender] = balances[msg.sender].sub(value);

         
        totalSupply_ = totalSupply_.sub(value);
        totalUpgraded = totalUpgraded.add(value);

         
        upgradeAgent.upgradeFrom(msg.sender, value);
        Upgrade(msg.sender, upgradeAgent, value);
    }

     
    function setUpgradeAgent(address agent) external {
        if (!canUpgrade()) {
             
            revert();
        }

        if (agent == 0x0) revert();
         
        if (msg.sender != upgradeMaster) revert();
         
        if (getUpgradeState() == UpgradeState.Upgrading) revert();

        upgradeAgent = UpgradeAgent(agent);

         
        if (!upgradeAgent.isUpgradeAgent()) revert();
         
        if (upgradeAgent.originalSupply() != totalSupply_) revert();

        UpgradeAgentSet(upgradeAgent);
    }

     
    function getUpgradeState() public constant returns (UpgradeState) {
        if (!canUpgrade()) return UpgradeState.NotAllowed;
        else if (address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
        else if (totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
        else return UpgradeState.Upgrading;
    }

     
    function setUpgradeMaster(address master) public {
        if (master == 0x0) revert();
        if (msg.sender != upgradeMaster) revert();
        upgradeMaster = master;
    }

     
    function canUpgrade() public constant returns (bool) {
        return true;
    }
}

contract CrowdsaleToken is ReleasableToken, UpgradeableToken {

   
  event UpdatedTokenInformation(string newName, string newSymbol);

  string public name;

  string public symbol;

  uint8 public decimals;

   
  function CrowdsaleToken(string _name, string _symbol, uint _initialSupply, uint8 _decimals)
    UpgradeableToken(msg.sender) public {

     
     
     
    owner = msg.sender;

    name = _name;
    symbol = _symbol;

    totalSupply_ = _initialSupply;

    decimals = _decimals;

     
    balances[owner] = totalSupply_;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    super.releaseTokenTransfer();
  }

   
  function canUpgrade() public constant returns(bool) {
    return released && super.canUpgrade();
  }

   
  function setTokenInformation(string _name, string _symbol) onlyOwner {
    name = _name;
    symbol = _symbol;

    UpdatedTokenInformation(name, symbol);
  }

}

contract VestedToken is StandardToken, LimitedTransferToken {

    uint256 MAX_GRANTS_PER_ADDRESS = 20;

    struct TokenGrant {
        address granter;      
        uint256 value;        
        uint64 cliff;
        uint64 vesting;
        uint64 start;         
        bool revokable;
        bool burnsOnRevoke;   
    }  

    mapping (address => TokenGrant[]) public grants;

    event NewTokenGrant(address indexed from, address indexed to, uint256 value, uint256 grantId);

     
    function grantVestedTokens(
        address _to,
        uint256 _value,
        uint64 _start,
        uint64 _cliff,
        uint64 _vesting,
        bool _revokable,
        bool _burnsOnRevoke
    ) public {

         
        require(_cliff >= _start && _vesting >= _cliff);

        require(tokenGrantsCount(_to) < MAX_GRANTS_PER_ADDRESS);    

        uint256 count = grants[_to].push(
            TokenGrant(
                _revokable ? msg.sender : 0,  
                _value,
                _cliff,
                _vesting,
                _start,
                _revokable,
                _burnsOnRevoke
            )
        );

        transfer(_to, _value);

        NewTokenGrant(msg.sender, _to, _value, count - 1);
    }

     
    function revokeTokenGrant(address _holder, uint256 _grantId) public {
        TokenGrant storage grant = grants[_holder][_grantId];

        require(grant.revokable);
        require(grant.granter == msg.sender);  

        address receiver = grant.burnsOnRevoke ? 0xdead : msg.sender;

        uint256 nonVested = nonVestedTokens(grant, uint64(now));

         
        delete grants[_holder][_grantId];
        grants[_holder][_grantId] = grants[_holder][grants[_holder].length.sub(1)];
        grants[_holder].length -= 1;

        balances[receiver] = balances[receiver].add(nonVested);
        balances[_holder] = balances[_holder].sub(nonVested);

        Transfer(_holder, receiver, nonVested);
    }


     
    function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
        uint256 grantIndex = tokenGrantsCount(holder);

        if (grantIndex == 0) return super.transferableTokens(holder, time);  

         
        uint256 nonVested = 0;
        for (uint256 i = 0; i < grantIndex; i++) {
            nonVested = SafeMath.add(nonVested, nonVestedTokens(grants[holder][i], time));
        }

         
        uint256 vestedTransferable = SafeMath.sub(balanceOf(holder), nonVested);

         
         
        return Math.min256(vestedTransferable, super.transferableTokens(holder, time));
    }

     
    function tokenGrantsCount(address _holder) public constant returns (uint256 index) {
        return grants[_holder].length;
    }

     
    function calculateVestedTokens(
        uint256 tokens,
        uint256 time,
        uint256 start,
        uint256 cliff,
        uint256 vesting) public pure returns (uint256)
    {
         
        if (time < cliff) return 0;
        if (time >= vesting) return tokens;

         
         
         

         
        uint256 vestedTokens = SafeMath.div(
            SafeMath.mul(
                tokens,
                SafeMath.sub(time, start)
            ),
            SafeMath.sub(vesting, start)
        );

        return vestedTokens;
    }

     
    function tokenGrant(address _holder, uint256 _grantId) public constant returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting, bool revokable, bool burnsOnRevoke) {
        TokenGrant storage grant = grants[_holder][_grantId];

        granter = grant.granter;
        value = grant.value;
        start = grant.start;
        cliff = grant.cliff;
        vesting = grant.vesting;
        revokable = grant.revokable;
        burnsOnRevoke = grant.burnsOnRevoke;

        vested = vestedTokens(grant, uint64(now));
    }

     
    function vestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
        return calculateVestedTokens(
            grant.value,
            uint256(time),
            uint256(grant.start),
            uint256(grant.cliff),
            uint256(grant.vesting)
        );
    }

     
    function nonVestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
        return grant.value.sub(vestedTokens(grant, time));
    }

     
    function lastTokenIsTransferableDate(address holder) public constant returns (uint64 date) {
        date = uint64(now);
        uint256 grantIndex = grants[holder].length;
        for (uint256 i = 0; i < grantIndex; i++) {
            date = Math.max64(grants[holder][i].vesting, date);
        }
    }
}

contract WemarkToken is CrowdsaleToken, BurnableToken, VestedToken {

    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }


    function WemarkToken() CrowdsaleToken('WemarkToken-Test', 'WMK', 135000000 * (10 ** 18), 18) public {
         
        setTransferAgent(msg.sender, true);
    }

     
    function transfer(address _to, uint _value)
        validDestination(_to)
        canTransferReleasable(msg.sender)
        canTransferLimitedTransferToken(msg.sender, _value) public returns (bool) {
         
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value)
        validDestination(_to)
        canTransferReleasable(_from)
        canTransferLimitedTransferToken(_from, _value) public returns (bool) {
         
        return super.transferFrom(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
         
        return super.approve(_spender, _value);
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
         
        return super.increaseApproval(_spender, _addedValue);
    }

     
    function canUpgrade() public constant returns(bool) {
        return released && super.canUpgrade();
    }

     
    function transferableTokensNow(address holder) public constant returns (uint) {
        return transferableTokens(holder, uint64(now));
    }

    function () payable {
         
        revert();
    }
}