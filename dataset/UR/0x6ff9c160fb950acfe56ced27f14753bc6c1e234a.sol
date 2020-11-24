 

pragma solidity ^"0.4.24";

contract VestingBase {
    using SafeMath for uint256;
    CovaToken internal cova;
    uint256 internal releaseTime;
    uint256 internal genesisTime;
    uint256 internal THREE_MONTHS = 7890000;
    uint256 internal SIX_MONTHS = 15780000;

    address internal beneficiaryAddress;

    struct Claim {
        bool fromGenesis;
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
                if((cur_claim.fromGenesis == false && (cur_claim.delay.add(releaseTime) < block.timestamp)) || (cur_claim.fromGenesis == true && (cur_claim.delay.add(genesisTime) < block.timestamp))){
                    uint256 amount = cur_claim.pct.mul(totalClaimable).div(10000);
                    require(cova.transfer(msg.sender, amount));
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

 
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
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




 

contract CovaToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private balances;
  mapping (address => mapping (address => uint256)) private allowed;

  uint256 private totalSupply_ = 65 * (10 ** (8 + 18));
  string private constant name_ = 'Covalent Token';                                  
  string private constant symbol_ = 'COVA';                                          
  uint8 private constant decimals_ = 18;                                           
  

  constructor () public {
    balances[msg.sender] = totalSupply_;
    emit Transfer(address(0), msg.sender, totalSupply_);
  }

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function name() public view returns (string) {
    return name_;
  }

   
  function symbol() public view returns (string) {
    return symbol_;
  }

   
  function decimals() public view returns (uint8) {
    return decimals_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract VestingAdvisor is VestingBase {
    using SafeMath for uint256;

    constructor(CovaToken _cova, uint256 _releaseTime) public {
        cova = _cova;
        releaseTime = _releaseTime;
        genesisTime = block.timestamp;
        beneficiaryAddress = 0xaD5Bc53f04aD23Ac217809c0276ed12F5cD80e2D;
        totalClaimable = 415520000 * (10 ** 18);
        beneficiaryClaims.push(Claim(false, 3000, SIX_MONTHS, false));
        beneficiaryClaims.push(Claim(false, 3000, THREE_MONTHS.add(SIX_MONTHS), false));
        beneficiaryClaims.push(Claim(false, 4000, THREE_MONTHS.mul(2).add(SIX_MONTHS), false));
    }
}