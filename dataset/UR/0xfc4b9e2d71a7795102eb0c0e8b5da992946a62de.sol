 

pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
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
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract CouponTokenConfig {
    string public constant name = "Coupon Chain Token"; 
    string public constant symbol = "CCT";
    uint8 public constant decimals = 18;

    uint256 internal constant DECIMALS_FACTOR = 10 ** uint(decimals);
    uint256 internal constant TOTAL_COUPON_SUPPLY = 1000000000 * DECIMALS_FACTOR;

    uint8 constant USER_NONE = 0;
    uint8 constant USER_FOUNDER = 1;
    uint8 constant USER_BUYER = 2;
    uint8 constant USER_BONUS = 3;

}

 
contract CouponToken is StandardToken, Ownable, CouponTokenConfig {
    using SafeMath for uint256;

     
    uint256 public startTimeOfSaleLot4;

     
    uint256 public endSaleTime;

     
    address public couponTokenSaleAddr;

     
    address public couponTokenBountyAddr;

     
    address public couponTokenCampaignAddr;


     
    mapping(address => uint8) vestingUsers;

     
    event Mint(address indexed to, uint256 tokens);

     

    modifier canMint() {
        require(
            couponTokenSaleAddr == msg.sender ||
            couponTokenBountyAddr == msg.sender ||
            couponTokenCampaignAddr == msg.sender);
        _;
    }

    modifier onlyCallFromCouponTokenSale() {
        require(msg.sender == couponTokenSaleAddr);
        _;
    }

    modifier onlyIfValidTransfer(address sender) {
        require(isTransferAllowed(sender) == true);
        _;
    }

    modifier onlyCallFromTokenSaleOrBountyOrCampaign() {
        require(
            msg.sender == couponTokenSaleAddr ||
            msg.sender == couponTokenBountyAddr ||
            msg.sender == couponTokenCampaignAddr);
        _;
    }


     
    constructor() public {
        balances[msg.sender] = 0;
    }


     
     
    function mint(address _to, uint256 _amount) canMint public {
        
        require(totalSupply_.add(_amount) <= TOTAL_COUPON_SUPPLY);

        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

     
    function transfer(address to, uint256 value)
        public
        onlyIfValidTransfer(msg.sender)
        returns (bool) {
        return super.transfer(to, value);
    }

     
    function transferFrom(address from, address to, uint256 value)
        public
        onlyIfValidTransfer(from)
        returns (bool){

        return super.transferFrom(from, to, value);
    }

    function setContractAddresses(
        address _couponTokenSaleAddr,
        address _couponTokenBountyAddr,
        address _couponTokenCampaignAddr)
        external
        onlyOwner
    {
        couponTokenSaleAddr = _couponTokenSaleAddr;
        couponTokenBountyAddr = _couponTokenBountyAddr;
        couponTokenCampaignAddr = _couponTokenCampaignAddr;
    }


    function setSalesEndTime(uint256 _endSaleTime) 
        external
        onlyCallFromCouponTokenSale  {
        endSaleTime = _endSaleTime;
    }

    function setSaleLot4StartTime(uint256 _startTime)
        external
        onlyCallFromCouponTokenSale {
        startTimeOfSaleLot4 = _startTime;
    }


    function setFounderUser(address _user)
        public
        onlyCallFromCouponTokenSale {
         
        vestingUsers[_user] = USER_FOUNDER;
    }

    function setSalesUser(address _user)
        public
        onlyCallFromCouponTokenSale {
         
        vestingUsers[_user] = USER_BUYER;
    }

    function setBonusUser(address _user) 
        public
        onlyCallFromTokenSaleOrBountyOrCampaign {
         
        vestingUsers[_user] = USER_BONUS;
    }

    function isTransferAllowed(address _user)
        internal view
        returns (bool) {
        bool retVal = true;
        if(vestingUsers[_user] == USER_FOUNDER) {
            if(endSaleTime == 0 ||                 
                (now < (endSaleTime + 730 days)))  
                retVal = false;
        }
        else if(vestingUsers[_user] == USER_BUYER || vestingUsers[_user] == USER_BONUS) {
            if(startTimeOfSaleLot4 == 0 ||               
                (now < (startTimeOfSaleLot4 + 90 days)))
                retVal = false;
        }
        return retVal;
    }
}