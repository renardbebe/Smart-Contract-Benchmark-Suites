 

 

pragma solidity ^0.5.0;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

     

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

pragma solidity ^0.5.0;



 

 
contract ChimpToken is IERC20 {
  using SafeMath for uint256;

   
  string public name = 'Chimpion';
  string public symbol = 'BNANA';
  uint8 public constant decimals = 18;
  uint256 public constant decimalFactor = 10 ** uint256(decimals);
  uint256 public constant totalSupply = 100000000000 * decimalFactor;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

   
  constructor (address _ChimpDistributionContractAddress) public {
    require(_ChimpDistributionContractAddress != address(0));
    balances[_ChimpDistributionContractAddress] = totalSupply;
    emit Transfer(address(0), address(_ChimpDistributionContractAddress), totalSupply);
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
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

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
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

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;





 
contract ChimpDistribution is Ownable {
  using SafeMath for uint256;

  ChimpToken public BNANA;

  uint256 private constant decimalFactor = 10**uint256(18);
  enum AllocationType { AIRDROP, MERCHANT, PAYROLL, MARKETING, PARTNERS, ADVISORS, RESERVE }
  uint256 public constant INITIAL_SUPPLY   = 100000000000 * decimalFactor;
  uint256 public AVAILABLE_TOTAL_SUPPLY    = 100000000000 * decimalFactor;

  uint256 public AVAILABLE_AIRDROP_SUPPLY  =      20000000 * decimalFactor; 
  uint256 public AVAILABLE_MERCHANT_SUPPLY =   30000000000 * decimalFactor; 
  uint256 public AVAILABLE_PAYROLL_SUPPLY =    12200000000 * decimalFactor; 
  uint256 public AVAILABLE_MARKETING_SUPPLY =    210000000 * decimalFactor; 
  uint256 public AVAILABLE_PARTNERS_SUPPLY =    5000000000 * decimalFactor; 
  uint256 public AVAILABLE_ADVISORS_SUPPLY =     750000000 * decimalFactor; 
  uint256 public AVAILABLE_RESERVE_SUPPLY  =   51820000000 * decimalFactor; 


  uint256 public grandTotalClaimed = 0;
  uint256 public startTime;

   
  struct Allocation {
    uint8 AllocationSupply;  
    uint256 endCliff;        
    uint256 endVesting;      
    uint256 totalAllocated;  
    uint256 amountClaimed;   
  }
  mapping (address => Allocation) public allocations;

   
  mapping (address => bool) public airdropAdmins;

   
  mapping (address => bool) public airdrops;

  modifier onlyOwnerOrAdmin() {
    require(isOwner() || airdropAdmins[msg.sender]);
    _;
  }

  event LogNewAllocation(address indexed _recipient, AllocationType indexed _fromSupply, uint256 _totalAllocated, uint256 _grandTotalAllocated);
  event LogBNANAClaimed(address indexed _recipient, uint8 indexed _fromSupply, uint256 _amountClaimed, uint256 _totalAllocated, uint256 _grandTotalClaimed);

   
  constructor (uint256 _startTime) public {
    require(_startTime >= now);
    require(AVAILABLE_TOTAL_SUPPLY == AVAILABLE_AIRDROP_SUPPLY.add(AVAILABLE_MERCHANT_SUPPLY).add(AVAILABLE_PAYROLL_SUPPLY).add(AVAILABLE_MARKETING_SUPPLY).add(AVAILABLE_PARTNERS_SUPPLY).add(AVAILABLE_ADVISORS_SUPPLY).add(AVAILABLE_RESERVE_SUPPLY));
    startTime = _startTime;
    BNANA = new ChimpToken(address(this));
  }

   
function setAllocation (address _recipient, uint256 _totalAllocated, AllocationType _supply) onlyOwner public {
      require(allocations[_recipient].totalAllocated == 0 && _totalAllocated > 0);
      require(_supply >= AllocationType.AIRDROP && _supply <= AllocationType.RESERVE);
      require(_recipient != address(0));

      if (_supply == AllocationType.AIRDROP) {
        AVAILABLE_AIRDROP_SUPPLY = AVAILABLE_AIRDROP_SUPPLY.sub(_totalAllocated);
        allocations[_recipient] = Allocation(uint8(AllocationType.AIRDROP), 0, 0, _totalAllocated, 0);

      } else if (_supply == AllocationType.MERCHANT) {
        AVAILABLE_MERCHANT_SUPPLY = AVAILABLE_MERCHANT_SUPPLY.sub(_totalAllocated);
        allocations[_recipient] = Allocation(uint8(AllocationType.MERCHANT), 0, 0, _totalAllocated, 0);

      } else if (_supply == AllocationType.PAYROLL) {
        AVAILABLE_PAYROLL_SUPPLY = AVAILABLE_PAYROLL_SUPPLY.sub(_totalAllocated);
        allocations[_recipient] = Allocation(uint8(AllocationType.PAYROLL), 0, 0, _totalAllocated, 0);

      } else if (_supply == AllocationType.MARKETING) {
        AVAILABLE_MARKETING_SUPPLY = AVAILABLE_MARKETING_SUPPLY.sub(_totalAllocated);
        allocations[_recipient] = Allocation(uint8(AllocationType.MARKETING), 0, 0, _totalAllocated, 0);

      } else if (_supply == AllocationType.PARTNERS) {
        AVAILABLE_PARTNERS_SUPPLY = AVAILABLE_PARTNERS_SUPPLY.sub(_totalAllocated);
        allocations[_recipient] = Allocation(uint8(AllocationType.PARTNERS), 0, 0, _totalAllocated, 0);

      } else if (_supply == AllocationType.ADVISORS) {
        AVAILABLE_ADVISORS_SUPPLY = AVAILABLE_ADVISORS_SUPPLY.sub(_totalAllocated);
        allocations[_recipient] = Allocation(uint8(AllocationType.ADVISORS), 0, 0, _totalAllocated, 0);

      } else if (_supply == AllocationType.RESERVE) {
        AVAILABLE_RESERVE_SUPPLY = AVAILABLE_RESERVE_SUPPLY.sub(_totalAllocated);
        allocations[_recipient] = Allocation(uint8(AllocationType.RESERVE), 0, 0, _totalAllocated, 0);

      }
      AVAILABLE_TOTAL_SUPPLY = AVAILABLE_TOTAL_SUPPLY.sub(_totalAllocated);
      emit LogNewAllocation(_recipient, _supply, _totalAllocated, grandTotalAllocated());
    }
    
   
  function setAirdropAdmin(address _admin, bool _isAdmin) public onlyOwner {
    airdropAdmins[_admin] = _isAdmin;
  }

   
  function airdropTokens(address[] memory _recipient, uint256[] memory _airdropAmount) public onlyOwnerOrAdmin {
    require(now >= startTime);
    uint airdropped;
    for(uint256 i = 0; i< _recipient.length; i++)
    {
        if (!airdrops[_recipient[i]]) {
          airdrops[_recipient[i]] = true;
          require(BNANA.transfer(_recipient[i], _airdropAmount[i] * decimalFactor));
          airdropped = airdropped.add(_airdropAmount[i] * decimalFactor);
        }
    }
    AVAILABLE_AIRDROP_SUPPLY = AVAILABLE_AIRDROP_SUPPLY.sub(airdropped);
    AVAILABLE_TOTAL_SUPPLY = AVAILABLE_TOTAL_SUPPLY.sub(airdropped);
    grandTotalClaimed = grandTotalClaimed.add(airdropped);
  }

   
  function transferTokens (address _recipient) public {
    require(allocations[_recipient].amountClaimed < allocations[_recipient].totalAllocated);
    require(now >= allocations[_recipient].endCliff);
     
    uint256 newAmountClaimed;
    if (allocations[_recipient].endVesting > now) {
       
      newAmountClaimed = allocations[_recipient].totalAllocated.mul(now.sub(startTime)).div(allocations[_recipient].endVesting.sub(startTime));
    } else {
       
      newAmountClaimed = allocations[_recipient].totalAllocated;
    }
    uint256 tokensToTransfer = newAmountClaimed.sub(allocations[_recipient].amountClaimed);
    allocations[_recipient].amountClaimed = newAmountClaimed;
    require(BNANA.transfer(_recipient, tokensToTransfer));
    grandTotalClaimed = grandTotalClaimed.add(tokensToTransfer);
    emit LogBNANAClaimed(_recipient, allocations[_recipient].AllocationSupply, tokensToTransfer, newAmountClaimed, grandTotalClaimed);
  }

   
  function grandTotalAllocated() public view returns (uint256) {
    return INITIAL_SUPPLY - AVAILABLE_TOTAL_SUPPLY;
  }

   
  function refundTokens(address _recipient, address _token) public onlyOwner {
    require(_token != address(BNANA));
    IERC20 token = IERC20(_token);
    uint256 balance = token.balanceOf(address(this));
    require(token.transfer(_recipient, balance));
  }
}