 

pragma solidity ^0.4.19;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


 
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}


contract MintableAndPausableToken is PausableToken {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event MintStarted();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier cannotMint() {
        require(mintingFinished);
        _;
    }

    function mint(address _to, uint256 _amount)
        public
        onlyOwner
        canMint
        whenNotPaused
        returns (bool)
    {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function startMinting() public onlyOwner cannotMint returns (bool) {
        mintingFinished = false;
        MintStarted();
        return true;
    }
}


 
contract TokenUpgrader {
    uint public originalSupply;

     
    function isTokenUpgrader() public pure returns (bool) {
        return true;
    }

    function upgradeFrom(address _from, uint256 _value) public {}
}


contract UpgradeableToken is MintableAndPausableToken {
     
    address public upgradeMaster;
    
     
    bool private upgradesAllowed;

     
    TokenUpgrader public tokenUpgrader;

     
    uint public totalUpgraded;

     
    enum UpgradeState { Unknown, NotAllowed, Waiting, ReadyToUpgrade, Upgrading }

     
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);

     
    event TokenUpgraderIsSet(address _newToken);

    modifier onlyUpgradeMaster {
         
        require(msg.sender == upgradeMaster);
        _;
    }

    modifier notInUpgradingState {
         
        require(getUpgradeState() != UpgradeState.Upgrading);
        _;
    }

     
    function UpgradeableToken(address _upgradeMaster) public {
        upgradeMaster = _upgradeMaster;
    }

     
    function setTokenUpgrader(address _newToken)
        external
        onlyUpgradeMaster
        notInUpgradingState
    {
        require(canUpgrade());
        require(_newToken != 0x0);

        tokenUpgrader = TokenUpgrader(_newToken);

         
        require(tokenUpgrader.isTokenUpgrader());

         
        require(tokenUpgrader.originalSupply() == totalSupply_);

        TokenUpgraderIsSet(tokenUpgrader);
    }

     
    function upgrade(uint _value) public {
        UpgradeState state = getUpgradeState();
        require(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading);

         
        require(_value != 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);

         
        totalSupply_ = totalSupply_.sub(_value);
        totalUpgraded = totalUpgraded.add(_value);

         
        tokenUpgrader.upgradeFrom(msg.sender, _value);
        Upgrade(msg.sender, tokenUpgrader, _value);
    }

     
    function getUpgradeState() public view returns(UpgradeState) {
        if (!canUpgrade()) return UpgradeState.NotAllowed;
        else if (address(tokenUpgrader) == address(0)) return UpgradeState.Waiting;
        else if (totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
        else if (totalUpgraded > 0) return UpgradeState.Upgrading;
        return UpgradeState.Unknown;
    }

     
    function setUpgradeMaster(address _newMaster) public onlyUpgradeMaster {
        require(_newMaster != 0x0);
        upgradeMaster = _newMaster;
    }

     
    function allowUpgrades() public onlyUpgradeMaster {
        upgradesAllowed = true;
    }

     
    function canUpgrade() public view returns(bool) {
        return upgradesAllowed;
    }
}


contract Token is UpgradeableToken {
    string public name = "AMCHART";
    string public symbol = "AMC";
    uint8 public constant decimals = 18;

     
    uint256 public constant INITIAL_SUPPLY = 5000000 * (10 ** uint256(decimals));

    event UpdatedTokenInformation(string newName, string newSymbol);

    function Token(address amcWallet, address _upgradeMaster)
        public
        UpgradeableToken(_upgradeMaster)
    {
        totalSupply_ = INITIAL_SUPPLY;
        balances[amcWallet] = INITIAL_SUPPLY;
        Transfer(0x0, amcWallet, INITIAL_SUPPLY);
    }

     
    function setTokenInformation(string _name, string _symbol) public onlyOwner {
        name = _name;
        symbol = _symbol;

        UpdatedTokenInformation(name, symbol);
    }
}