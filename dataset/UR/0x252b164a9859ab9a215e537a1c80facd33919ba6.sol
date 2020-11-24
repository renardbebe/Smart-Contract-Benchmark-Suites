 

pragma solidity ^0.4.24;


 
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


contract ERC20 {
  function totalSupply() public constant returns (uint256);

  function balanceOf(address _who) public constant returns (uint256);

  function allowance(address _owner, address _spender) public constant returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _fromValue,uint256 _toValue) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  
}

contract Pausable is Ownable {
  event Paused();
  event Unpaused();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Paused();
  }

  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpaused();
  }
}



contract Lambda is ERC20, Pausable {
  using SafeMath for uint256;

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  string public symbol;
  string public  name;
  uint256 public decimals;
  uint256 _totalSupply;

  constructor() public {
    symbol = "LAMB";
    name = "Lambda";
    decimals = 18;

    _totalSupply = 6*(10**27);
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }

  function totalSupply() public  constant returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address _owner) public  constant returns (uint256) {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender) public  constant returns (uint256) {
    return allowed[_owner][_spender];
  }

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _fromValue, uint256 _toValue) public whenNotPaused returns (bool) {
    require(_spender != address(0));
    require(allowed[msg.sender][_spender] ==_fromValue);
    allowed[msg.sender][_spender] = _toValue;
    emit Approval(msg.sender, _spender, _toValue);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool){
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  
}


contract LambdaLock {
    using SafeMath for uint256;
    Lambda internal LambdaToken;
    
    uint256 internal genesisTime= 1545814800; 
    

    uint256 internal ONE_MONTHS = 120;   

    address internal beneficiaryAddress;

    struct Claim {
        
        uint256 pct;
        uint256 delay;
        bool claimed;
    } 

    Claim [] internal beneficiaryClaims;
    uint256 internal totalClaimable;

    event Claimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    function claim() public returns (bool){
        require(msg.sender == beneficiaryAddress); 
        for(uint256 i = 0; i < beneficiaryClaims.length; i++){
            Claim memory cur_claim = beneficiaryClaims[i];
            if(cur_claim.claimed == false){
                if(cur_claim.delay.add(genesisTime) < block.timestamp){
        
                    uint256 amount = cur_claim.pct*(10**18);
                    require(LambdaToken.transfer(msg.sender, amount));
                    beneficiaryClaims[i].claimed = true;
                    emit Claimed(msg.sender, amount, block.timestamp);
                }
            }
        }
    }

    function getBeneficiary() public view returns (address) {
        return beneficiaryAddress;
    }

    function getTotalClaimable() public view returns (uint256) {
        return totalClaimable;
    }
}


contract lambdaTeam is LambdaLock {
    using SafeMath for uint256;
    

    constructor(Lambda _LambdaToken) public {
        LambdaToken = _LambdaToken;
        
        
        
        beneficiaryAddress = 0xB969C916B3FDc4CbC611d477b866e96ab8EcC1E2 ;
        totalClaimable = 1000000000 * (10 ** 18);
        for(uint i=0;i<36;i++){
            beneficiaryClaims.push(Claim( 27777777, ONE_MONTHS*(i+1), false));
       }
        
    
    }
}