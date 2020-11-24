 

pragma solidity ^0.4.18;

 
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
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

 
contract EXOToken is StandardToken, Ownable {
    uint8 constant PERCENT_BOUNTY=3;
    uint8 constant PERCENT_TEAM=12;
    uint8 constant PERCENT_FOUNDATION=25;
    uint8 constant PERCENT_PRE_ICO=10;
    uint8 constant PERCENT_ICO=50;
    uint256 constant UNFREEZE_FOUNDATION  = 1546214400;
     
     
     
     
     
     
    mapping(address => bool) public frozenAccounts;

    string public  name;
    string public  symbol;
    uint8  public  decimals;
    uint256 public UNFREEZE_TEAM_BOUNTY = 1535760000;  

    address public accForBounty;
    address public accForTeam;
    address public accFoundation;
    address public accPreICO;
    address public accICO;
    address public currentMinter;


     
     
     
    event NewFreeze(address acc, bool isFrozen);
    event Mint(address indexed to, uint256 amount);

     
    function EXOToken(
        address _accForBounty, 
        address _accForTeam, 
        address _accFoundation, 
        address _accPreICO, 
        address _accICO) 
    public 
    {
        name = "EXOLOVER";
        symbol = "EXO";
        decimals = 18;
        totalSupply_ = 100000000 * (10 ** uint256(decimals)); 
         
        balances[_accForBounty] = totalSupply()/100*PERCENT_BOUNTY;
        balances[_accForTeam]   = totalSupply()/100*PERCENT_TEAM;
        balances[_accFoundation]= totalSupply()/100*PERCENT_FOUNDATION;
        balances[_accPreICO]    = totalSupply()/100*PERCENT_PRE_ICO;
        balances[_accICO]       = totalSupply()/100*PERCENT_ICO;
         
        accForBounty  = _accForBounty;
        accForTeam    = _accForTeam;
        accFoundation = _accFoundation;
        accPreICO     = _accPreICO;
        accICO        = _accICO;
         
        emit Transfer(address(0), _accForBounty,  totalSupply()/100*PERCENT_BOUNTY);
        emit Transfer(address(0), _accForTeam,    totalSupply()/100*PERCENT_TEAM);
        emit Transfer(address(0), _accFoundation, totalSupply()/100*PERCENT_FOUNDATION);
        emit Transfer(address(0), _accPreICO,     totalSupply()/100*PERCENT_PRE_ICO);
        emit Transfer(address(0), _accICO,        totalSupply()/100*PERCENT_ICO);

        frozenAccounts[accFoundation] = true;
        emit NewFreeze(accFoundation, true);
    }

    function isFrozen(address _acc) internal view returns(bool frozen) {
        if (_acc == accFoundation && now < UNFREEZE_FOUNDATION) 
            return true;
        return (frozenAccounts[_acc] && now < UNFREEZE_TEAM_BOUNTY);    
    }

     
    function transfer(address _to, uint256 _value) public  returns (bool) {
      require(!isFrozen(msg.sender));
      assert(msg.data.length >= 64 + 4); 
       
       
      if (msg.sender == accForBounty || msg.sender == accForTeam) {
          frozenAccounts[_to] = true;
          emit NewFreeze(_to, true);
      }
      return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool) {
      require(!isFrozen(_from));
      assert(msg.data.length >= 96 + 4);  
       if (_from == accForBounty || _from == accForTeam) {
          frozenAccounts[_to] = true;
          emit NewFreeze(_to, true);
      }
      return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public  returns (bool) {
      require(!isFrozen(msg.sender));
      return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public  returns (bool success) {
      require(!isFrozen(msg.sender));
      return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public  returns (bool success) {
      require(!isFrozen(msg.sender));
      return super.decreaseApproval(_spender, _subtractedValue);
    }

    function freezeUntil(address _acc, bool _isfrozen) external onlyOwner returns (bool success){
        require(now <= UNFREEZE_TEAM_BOUNTY); 
        frozenAccounts[_acc] = _isfrozen;
        emit NewFreeze(_acc, _isfrozen);
        return true;
    }

    function setMinter(address _minter) external onlyOwner returns (bool success) {
        currentMinter = _minter;
        return true;
    }

    function setBountyTeamUnfreezeTime(uint256 _newDate) external onlyOwner {
       UNFREEZE_TEAM_BOUNTY = _newDate;
    }

    function mintTokens(address _to, uint256 _amount) external returns (bool) {
        require(msg.sender==currentMinter);
        totalSupply_  = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true; 
    }
    
    
   
   
   
   
   
   
   

}