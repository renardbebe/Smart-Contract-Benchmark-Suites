 

 
pragma solidity ^0.4.25;

library SafeMath {
 
   
  function safeAdd (uint256 x, uint256 y) internal pure returns (uint256) {
    uint256 z = x + y;
    require(z >= x);
    return z;
  }

   
  function safeSub (uint256 x, uint256 y) internal pure returns (uint256) {
    require (x >= y);
    uint256 z = x - y;
    return z;
  }
}

contract Token {
   
  function totalSupply () public view returns (uint256 supply);

   
  function balanceOf (address _owner) public view returns (uint256 balance);

   
  function transfer (address _to, uint256 _value)
  public returns (bool success);

   
  function transferFrom (address _from, address _to, uint256 _value)
  public returns (bool success);

   
  function approve (address _spender, uint256 _value)
  public returns (bool success);

   
  function allowance (address _owner, address _spender)
  public view returns (uint256 remaining);

   
  event Transfer (address indexed _from, address indexed _to, uint256 _value);

   
  event Approval (
    address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract OrgonToken is Token {
    
using SafeMath for uint256;

 
uint256 constant MAX_TOKEN_COUNT =
0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

 
uint256 private constant LIFE_START_TIME = 1634559021;

 
uint256 private constant LIFE_START_TOKENS = 642118523280000000000000000;
  
 
 
constructor() public {
    owner = msg.sender;
    mint = msg.sender;
}
  
  
 
 
function name () public pure returns (string) {
    
    return "ORGON";
}

 
function symbol () public pure returns (string) {
    
    return "ORGON";
}
 
function decimals () public pure returns (uint8) {
    
    return 18;
}

 
 
  
function totalSupply () public view returns (uint256 supply) {
     
     return tokenCount;
 }

 
function totalICO () public view returns (uint256) {
     
     return tokenICO;
 }

 
function theMint () public view returns (address) {
     
     return mint;
 }
 
  
function theStage () public view returns (Stage) {
     
     return stage;
 }
 
  
function theOwner () public view returns (address) {
     
     return owner;
 }
 
 
 

 
function balanceOf (address _owner) public view returns (uint256 balance) {

    return accounts [_owner];
}


 
 
  
 function transfer (address _to, uint256 _value)
 public validDestination(_to) returns (bool success) {
    
    require (accounts [msg.sender]>=_value);
    
    uint256 fromBalance = accounts [msg.sender];
    if (fromBalance < _value) return false;
    
    if (stage != Stage.ICO){
        accounts [msg.sender] = fromBalance.safeSub(_value);
        accounts [_to] = accounts[_to].safeAdd(_value);
    }
    else if (msg.sender == owner){  
        accounts [msg.sender] = fromBalance.safeSub(_value);
        accounts [_to] = accounts[_to].safeAdd(_value);
        tokenICO = tokenICO.safeAdd(_value);
    }
    else if (_to == owner){  
        accounts [msg.sender] = fromBalance.safeSub(_value);
        accounts [_to] = accounts[_to].safeAdd(_value);
        tokenICO = tokenICO.safeSub(_value);
    }
    else if (forPartners[msg.sender] >= _value){  
        accounts [msg.sender] = fromBalance.safeSub(_value);
        forPartners [msg.sender] = forPartners[msg.sender].safeSub(_value);
        accounts [_to] = accounts[_to].safeAdd(_value);
    }
    else revert();
    
    emit Transfer (msg.sender, _to, _value);
    return true;
}


 
 
 
function transferFrom (address _from, address _to, uint256 _value)
public validDestination(_to) returns (bool success) {

    require (stage != Stage.ICO);
    require(_from!=_to);
    uint256 spenderAllowance = allowances [_from][msg.sender];
    if (spenderAllowance < _value) return false;
    uint256 fromBalance = accounts [_from];
    if (fromBalance < _value) return false;

    allowances [_from][msg.sender] =  spenderAllowance.safeSub(_value);

    if (_value > 0) {
      accounts [_from] = fromBalance.safeSub(_value);
      accounts [_to] = accounts[_to].safeAdd(_value);
    }
    emit Transfer (_from, _to, _value);
    return true;
}


 
 
 
function approve (address _spender, uint256 _value)
public returns (bool success) {
    require(_spender != address(0));
    
    allowances [msg.sender][_spender] = _value;
    emit Approval (msg.sender, _spender, _value);
    return true;
}


 
 
 
function addToPartner (address _partner, uint256 _value)
public returns (bool success) {
    
    require (msg.sender == owner);
    forPartners [_partner] = forPartners[_partner].safeAdd(_value);
    return true;
}

 

 
function subFromPartner (address _partner, uint256 _value)
public returns (bool success) {
    
    require (msg.sender == owner);
    if (forPartners [_partner] < _value) {
        forPartners [_partner] = 0;
    }
    else {
        forPartners [_partner] = forPartners[_partner].safeSub(_value);
    }
    return true;
}

 
  
 
function partners (address _partner)
public view returns (uint256 remaining) {

    return forPartners [_partner];
  }


 
 
 
function createTokens (uint256 _value) public returns (bool) {

    require (msg.sender == mint);
    
    if (_value > 0) {
        if (_value > MAX_TOKEN_COUNT.safeSub(tokenCount)) return false;
        accounts [msg.sender] = accounts[msg.sender].safeAdd(_value);
        tokenCount = tokenCount.safeAdd(_value);
        emit Transfer (address (0), msg.sender, _value);
    }
    return true;
}


 
 
 
function burnTokens (uint256 _value) public returns (bool) {

    require (msg.sender == mint);
    require (accounts [msg.sender]>=_value);
    
    if (_value > accounts [mint]) return false;
    else if (_value > 0) {
        accounts [mint] = accounts[mint].safeSub(_value);
        tokenCount = tokenCount.safeSub(_value);
        emit Transfer (mint, address (0), _value);
        return true;
    }
    else return true;
}


 
 
 
function setOwner (address _newOwner) public validDestination(_newOwner) {
 
    require (msg.sender == owner);
    
    owner = _newOwner;
    uint256 fromBalance = accounts [msg.sender];
    if (fromBalance > 0 && msg.sender != _newOwner) {
        accounts [msg.sender] = fromBalance.safeSub(fromBalance);
        accounts [_newOwner] = accounts[_newOwner].safeAdd(fromBalance);
        emit Transfer (msg.sender, _newOwner, fromBalance);
    }
}

 

 
function setMint (address _newMint) public {
 
 if (stage != Stage.LIFE && (msg.sender == owner || msg.sender == mint )){
    mint = _newMint;
 }
 else if (msg.sender == mint){
    mint = _newMint;
 }
 else revert();
}

 
 
 
function checkStage () public returns (Stage) {

    require (stage != Stage.LIFE);
    
    Stage currentStage = stage;
    if (currentStage == Stage.ICO) {
        if (block.timestamp >= LIFE_START_TIME || tokenICO > LIFE_START_TOKENS) {
            currentStage = Stage.LIFE;
            stage = Stage.LIFE;
        }
    else return currentStage;
    }
    return currentStage;
}

 

 
function changeStage () public {
    
    require (msg.sender == owner);
    require (stage != Stage.LIFE);
    if (stage == Stage.ICO) {stage = Stage.LIFEBYOWNER;}
    else stage = Stage.ICO;
}



 
 
 
function allowance (address _owner, address _spender)
public view returns (uint256 remaining) {

    return allowances [_owner][_spender];
  }

 
   
 
function increaseAllowance(address spender, uint256 addedValue) public returns (bool)
  {
    require(spender != address(0));

    allowances[msg.sender][spender] = allowances[msg.sender][spender].safeAdd(addedValue);
    emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    allowances[msg.sender][spender] = allowances[msg.sender][spender].safeSub(subtractedValue);
    emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
    return true;
  }



 
function currentTime () public view returns (uint256) {
    return block.timestamp;
}

 
uint256 private  tokenCount;

 
uint256 private  tokenICO;

 
address private  owner;

 
address private  mint;


  
enum Stage {
    ICO,  
    LIFEBYOWNER,
    LIFE 
}
  
 
Stage private stage = Stage.ICO;
  
 
mapping (address => uint256) private accounts;

 
mapping (address => uint256) private forPartners;

 
mapping (address => mapping (address => uint256)) private allowances;

modifier validDestination (address to) {
    require (to != address(0x0));
    require (to != address(this));
    _;
}

}