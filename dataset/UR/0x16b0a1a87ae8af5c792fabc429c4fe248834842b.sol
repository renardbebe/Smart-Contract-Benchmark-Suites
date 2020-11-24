 

pragma solidity ^0.4.15;

 

 
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

 

 
contract StandardToken is ERC20 {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) internal allowed;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

     
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

     
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool) {
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

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
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

 

 
contract Claimable is Ownable {
    address public pendingOwner;

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() onlyPendingOwner public {
        OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

 

 
contract ReleasableToken is ERC20, Claimable {

     
    address public releaseAgent;

     
    bool public released = false;

     
    mapping (address => bool) public transferAgents;

     
    modifier canTransfer(address _sender) {
        if(!released) {
            assert(transferAgents[_sender]);
        }
        _;
    }

     
    function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
        require(addr != 0x0);
         
        releaseAgent = addr;
    }

     
    function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
        require(addr != 0x0);
        transferAgents[addr] = state;
    }

     
    function releaseTokenTransfer() public onlyReleaseAgent {
        released = true;
    }

     
    modifier inReleaseState(bool releaseState) {
        require(releaseState == released);
        _;
    }

     
    modifier onlyReleaseAgent() {
        require(msg.sender == releaseAgent);
        _;
    }

    function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
         
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
         
        return super.transferFrom(_from, _to, _value);
    }

}

 

 
contract CrowdsaleToken is BurnableToken, ReleasableToken {
    uint public decimals;
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

     
    function UpgradeableToken(address _upgradeMaster) {
        upgradeMaster = _upgradeMaster;
    }

     
    function upgrade(uint256 value) public {
        require(value != 0);
        UpgradeState state = getUpgradeState();
        assert(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading);
        assert(value <= balanceOf(msg.sender));

        balances[msg.sender] = balances[msg.sender].sub(value);

         
        totalSupply = totalSupply.sub(value);
        totalUpgraded = totalUpgraded.add(value);

         
        upgradeAgent.upgradeFrom(msg.sender, value);
        Upgrade(msg.sender, upgradeAgent, value);
    }

     
    function setUpgradeAgent(address agent) external {
        require(agent != 0x0 && msg.sender == upgradeMaster);
        assert(canUpgrade());
        upgradeAgent = UpgradeAgent(agent);
        assert(upgradeAgent.isUpgradeAgent());
        assert(upgradeAgent.originalSupply() == totalSupply);
        UpgradeAgentSet(upgradeAgent);
    }

     
    function getUpgradeState() public constant returns(UpgradeState) {
        if(!canUpgrade()) return UpgradeState.NotAllowed;
        else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
        else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
        else return UpgradeState.Upgrading;
    }

     
    function setUpgradeMaster(address master) public {
        require(master != 0x0 && msg.sender == upgradeMaster);
        upgradeMaster = master;
    }

     
    function canUpgrade() public constant returns(bool) {
        return true;
    }

}

 

 
contract AlgoryToken is UpgradeableToken, CrowdsaleToken {

    string public name = 'Algory';
    string public symbol = 'ALG';
    uint public decimals = 18;

    uint256 public INITIAL_SUPPLY = 75000000 * (10 ** uint256(decimals));

    event UpdatedTokenInformation(string newName, string newSymbol);

    function AlgoryToken() UpgradeableToken(msg.sender) {
        owner = msg.sender;
        totalSupply = INITIAL_SUPPLY;
        balances[owner] = totalSupply;
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