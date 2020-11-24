 

pragma solidity 0.4.24;

 
library SafeMath {
    
   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];

    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }

    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract Role is StandardToken {
    using SafeMath for uint256;

    address public owner;
    address public admin;

    uint256 public contractDeployed = now;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event AdminshipTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

	   
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }   

     
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

     
    function transferOwnership(address _newOwner) external  onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function transferAdminship(address _newAdmin) external onlyAdmin {
        _transferAdminship(_newAdmin);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        balances[owner] = balances[owner].sub(balances[owner]);
        balances[_newOwner] = balances[_newOwner].add(balances[owner]);
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }

     
    function _transferAdminship(address _newAdmin) internal {
        require(_newAdmin != address(0));
        emit AdminshipTransferred(admin, _newAdmin);
        admin = _newAdmin;
    }
}

 
contract Pausable is Role {
  event Pause();
  event Unpause();
  event NotPausable();

  bool public paused = false;
  bool public canPause = true;

   
  modifier whenNotPaused() {
    require(!paused || msg.sender == owner);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
    function pause() onlyOwner whenNotPaused public {
        require(canPause == true);
        paused = true;
        emit Pause();
    }

   
  function unpause() onlyOwner whenPaused public {
    require(paused == true);
    paused = false;
    emit Unpause();
  }
  
   
    function notPausable() onlyOwner public{
        paused = false;
        canPause = false;
        emit NotPausable();
    }
}

contract SamToken is Pausable {
  using SafeMath for uint;

    uint256 _lockedTokens;
    uint256 _bountyLockedTokens;
    uint256 _teamLockedTokens;

    bool ownerRelease;
    bool releasedForOwner ;

     
    bool team_1_release;
    bool teamRelease;

     
    bool bounty_1_release;
    bool bountyrelase;
    
    uint256 public ownerSupply;   
    uint256 public adminSupply ;
    uint256 public teamSupply ;
    uint256 public bountySupply ;
   
     
    string public constant name = "SAM Token";
     
    string public constant symbol = "SAM";
     
    uint public constant decimals = 0;

  event Burn(address indexed burner, uint256 value);
  event CompanyTokenReleased( address indexed _company, uint256 indexed _tokens );
  event TransferTokenToTeam(
        address indexed _beneficiary,
        uint256 indexed tokens
    );

   event TransferTokenToBounty(
        address indexed bounty,
        uint256 indexed tokens
    );

  constructor(
        address _owner,
        address _admin,
        uint256 _totalsupply,
        address _development,
        address _bounty
        ) public {
    owner = _owner;
    admin = _admin;

    _totalsupply = _totalsupply;
    totalSupply_ = totalSupply_.add(_totalsupply);

    adminSupply = 450000000;
    teamSupply = 200000000;    
    ownerSupply = 100000000;
    bountySupply = 50000000;

    _lockedTokens = _lockedTokens.add(ownerSupply);
    _bountyLockedTokens = _bountyLockedTokens.add(bountySupply);
    _teamLockedTokens = _teamLockedTokens.add(teamSupply);

    balances[admin] = balances[admin].add(adminSupply);    
    balances[_development] = balances[_development].add(150000000);
    balances[_bounty] = balances[_bounty].add(50000000);
    
    emit Transfer(address(0), admin, adminSupply);
  }

  modifier onlyPayloadSize(uint numWords) {
    assert(msg.data.length >= numWords * 32 + 4);
    _;
  }

  
    function lockedTokens() public view returns (uint256) {
      return _lockedTokens;
    }

   
    function lockedBountyTokens() public view returns (uint256) {
      return _bountyLockedTokens;
    }

   
    function lockedTeamTokens() public view returns (uint256) {
      return _teamLockedTokens;
    }

   
    function isContract(address _address) private view returns (bool is_contract) {
      uint256 length;
      assembly {
       
        length := extcodesize(_address)
      }
      return (length > 0);
    }

   

  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return balances[tokenOwner];
  }

   
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }

   
  function transfer(address to, uint tokens) public whenNotPaused onlyPayloadSize(2) returns (bool success) {
    require(to != address(0));
    require(tokens > 0);
    require(tokens <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }

   
   
  function approve(address spender, uint tokens) public whenNotPaused onlyPayloadSize(2) returns (bool success) {
    require(spender != address(0));
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

 


function transferFrom(address from, address to, uint tokens) public whenNotPaused onlyPayloadSize(3) returns (bool success) {
    require(tokens > 0);
    require(from != address(0));
    require(to != address(0));
    require(allowed[from][msg.sender] > 0);
    require(balances[from]>0);

    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
}

 
function burn(uint _value) public returns (bool success) {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(msg.sender, _value);
    return true;
}

 
function burnFrom(address from, uint _value) public returns (bool success) {
    require(balances[from] >= _value);
    require(_value <= allowed[from][msg.sender]);
    balances[from] = balances[from].sub(_value);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(from, _value);
    return true;
}

function () public payable {
    revert();
}

 
function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    require(tokenAddress != address(0));
    require(isContract(tokenAddress));
    return ERC20(tokenAddress).transfer(owner, tokens);
}

 
 
function companyTokensRelease(address _company) external onlyOwner returns(bool) {
   require(_company != address(0), "Address is not valid");
   require(!ownerRelease, "owner release has already done");
    if (now > contractDeployed.add(365 days) && releasedForOwner == false ) {          
          balances[_company] = balances[_company].add(_lockedTokens);
          
          releasedForOwner = true;
          ownerRelease = true;
          emit CompanyTokenReleased(_company, _lockedTokens);
          _lockedTokens = 0;
          return true;
        }
    }

 
 
function transferToTeam(address _team) external onlyOwner returns(bool) {
        require(_team != address(0), "Address is not valid");
        require(!teamRelease, "Team release has already done");
        if (now > contractDeployed.add(365 days) && team_1_release == false) {
            balances[_team] = balances[_team].add(_teamLockedTokens);
            
            team_1_release = true;
            teamRelease = true;
            emit TransferTokenToTeam(_team, _teamLockedTokens);
            _teamLockedTokens = 0;
            return true;
        }
    }

   
  function transferToBounty(address _bounty) external onlyOwner returns(bool) {
        require(_bounty != address(0), "Address is not valid");
        require(!bountyrelase, "Bounty release already done");
        if (now > contractDeployed.add(180 days) && bounty_1_release == false) {
            balances[_bounty] = balances[_bounty].add(_bountyLockedTokens);
            bounty_1_release = true;
            bountyrelase = true;
            emit TransferTokenToBounty(_bounty, _bountyLockedTokens);
            _bountyLockedTokens = 0;
            return true;
        }
  }

}