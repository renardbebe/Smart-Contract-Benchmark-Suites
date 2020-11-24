 

 
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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

  mapping(address => uint256) public balances;

  uint256 public totalSupply_;

   
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

contract Freeze is Ownable {
  
  using SafeMath for uint256;

  struct Group {
    address[] holders;
    uint until;
  }
  
	 
  uint public groups;
  
  address[] public gofindAllowedAddresses;
  
	 
  mapping (uint => Group) public lockup;
  
	 
  modifier lockupEnded (address _holder, address _recipient) {
    uint index = indexOf(_recipient, gofindAllowedAddresses);
    if (index == 0) {
      bool freezed;
      uint groupId;
      (freezed, groupId) = isFreezed(_holder);
    
      if (freezed) {
        if (lockup[groupId-1].until < block.timestamp)
          _;
        else 
          revert("Your holdings are freezed, wait until transfers become allowed");
      }
      else 
        _;
    }
    else
      _;
  }
  
  function addGofindAllowedAddress (address _newAddress) public onlyOwner returns (bool) {
    require(indexOf(_newAddress, gofindAllowedAddresses) == 0, "that address already exists");
    gofindAllowedAddresses.push(_newAddress);
    return true;
  }
	
	 
  function isFreezed (address _holder) public view returns(bool, uint) {
    bool freezed = false;
    uint i = 0;
    while (i < groups) {
      uint index  = indexOf(_holder, lockup[i].holders);

      if (index == 0) {
        if (checkZeroIndex(_holder, i)) {
          freezed = true;
          i++;
          continue;
        }  
        else {
          i++;
          continue;
        }
      }
      
      if (index != 0) {
        freezed = true;
        i++;
        continue;
      }
      i++;
    }
    if (!freezed) i = 0;
    
    return (freezed, i);
  }
  
	 
  function indexOf (address element, address[] memory at) internal pure returns (uint) {
    for (uint i=0; i < at.length; i++) {
      if (at[i] == element) return i;
    }
    return 0;
  }
  
	 
  function checkZeroIndex (address _holder, uint lockGroup) internal view returns (bool) {
    if (lockup[lockGroup].holders[0] == _holder)
      return true;
        
    else 
      return false;
  }
  
	 
  function setGroup (address[] memory _holders, uint _until) public onlyOwner returns (bool) {
    lockup[groups].holders = _holders;
    lockup[groups].until   = _until;
    
    groups++;
    return true;
  }
}

 
contract PausableToken is StandardToken, Freeze {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    lockupEnded(msg.sender, _to)
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    lockupEnded(msg.sender, _to)
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    lockupEnded(msg.sender, _spender)
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    lockupEnded(msg.sender, _spender)
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    lockupEnded(msg.sender, _spender)
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}


contract SingleToken is PausableToken {

  string  public constant name      = "Gofind XR"; 

  string  public constant symbol    = "XR";

  uint32  public constant decimals  = 8;

  uint256 public constant maxSupply = 13E16;
  
  constructor() public {
    totalSupply_ = totalSupply_.add(maxSupply);
    balances[msg.sender] = balances[msg.sender].add(maxSupply);
  }
}
contract Leasing is Ownable {
    
    using SafeMath for uint256;
    
    address XR = address(0);  
    SingleToken token;
    
    struct Stakes {
        uint256 stakingCurrency;  
        uint256 stakingAmount;
        bytes coordinates;
    }
    
    struct Tenant {
        uint256 ids;
        Stakes[] stakes;
    }
    
    uint256 public tokenRate = 0;
    address public companyWallet = 0x553654Ad7808625B36F6AB29DdB41140300E024F;
    
    mapping (address => Tenant) public tenants;
    
    
    event Deposit(address indexed user, uint256 indexed amount, string indexed currency, uint256 timestamp);
    event Withdraw(address indexed user, uint256 indexed amount, string indexed currency, uint256 timestamp);
    
    constructor (address _xr) public {
        XR = _xr;
    }
    
    function () payable external {
        require(1 == 0);
        
    }
    

     
    function projectStage (uint256 _stage) public onlyOwner returns (bool) {
        if (_stage == 0) 
            tokenRate = 1500;
        if (_stage == 1)
            tokenRate = 1000;
        if (_stage == 2)
            tokenRate = 0;
    }
    

     
    function oracleSetPrice (uint256 _rate) public onlyOwner returns (bool) {
        tokenRate = _rate;
        return true;
    }
    
    
    function stakeEth (bytes memory _coordinates) payable public returns (bool) {
        require(msg.value != 0);
        require(tokenRate != 0, "XR is on exchange, need to get price");
        
        uint256 fee = msg.value * 10 / 110;
        address(0x553654Ad7808625B36F6AB29DdB41140300E024F).transfer(fee);
        uint256 afterFee = msg.value - fee;
        
        Stakes memory stake = Stakes(0, afterFee, _coordinates);
        tenants[msg.sender].stakes.push(stake);
        
        tenants[msg.sender].ids = tenants[msg.sender].ids.add(1);
        
        emit Deposit(msg.sender, afterFee, "ETH", block.timestamp);
        return true;
    }
    
    
    function returnEth (uint256 _id) public returns (bool) {
        require(_id != 0, "always invalid id");
        require(tenants[msg.sender].ids != 0, "nothing to return");
        require(tenants[msg.sender].ids >= _id, "no staking data with such id");
        require(tenants[msg.sender].stakes[_id-1].stakingCurrency == 0, 'use returnXR');
        require(tokenRate != 0, "XR is on exchange, need to get price");
        
        uint256 indexify = _id-1;
        uint256 ethToReturn = tenants[msg.sender].stakes[indexify].stakingAmount;
        
        removeStakeById(indexify);

        ethToReturn = ethToReturn * 9 / 10;
        uint256 tokenAmountToReturn = ethToReturn * tokenRate / 10E9;
        
        require(SingleToken(XR).transferFrom(companyWallet, msg.sender, tokenAmountToReturn), "can not transfer tokens");
    
        emit Withdraw(msg.sender, tokenAmountToReturn, "ETH", block.timestamp);
        return true;
    }
    
    
    function returnTokens (uint256 _id) public returns (bool){
        require(_id != 0, "always invalid id");
        require(tenants[msg.sender].ids != 0, "nothing to return");
        require(tenants[msg.sender].ids >= _id, "no staking data with such id");
        require(tenants[msg.sender].stakes[_id-1].stakingCurrency == 1, 'use returnETH');

        uint256 indexify = _id-1;
        uint256 tokensToReturn = tenants[msg.sender].stakes[indexify].stakingAmount;
    
        SingleToken _instance = SingleToken(XR);
        
        removeStakeById(indexify);
        
        _instance.transfer(msg.sender, tokensToReturn);
        
        emit Withdraw(msg.sender, tokensToReturn, "XR", block.timestamp);
        return true;
    }
    
   
    function stakeTokens (uint256 amount, bytes memory _coordinates) public returns (bool) {
        require(amount != 0, "staking can not be 0");
        
        Stakes memory stake = Stakes(1, amount, _coordinates);
        tenants[msg.sender].stakes.push(stake);
        
        tenants[msg.sender].ids = tenants[msg.sender].ids.add(1);
        
        require(SingleToken(XR).transferFrom(msg.sender, address(this), amount), "can not transfer tokens");
        
        emit Deposit(msg.sender, amount, "XR", block.timestamp);
        return true;
    }
    
    
    function removeStakeById (uint256 _id) internal returns (bool) {
        for (uint256 i = _id; i < tenants[msg.sender].stakes.length-1; i++) {
            tenants[msg.sender].stakes[i] = tenants[msg.sender].stakes[i+1];
        }
        tenants[msg.sender].stakes.length--;
        tenants[msg.sender].ids = tenants[msg.sender].ids.sub(1);
        
        return true;
    }
    
    
    function getStakeById (uint256 _id) public view returns (string memory, uint256, bytes memory) {
        require(_id != 0, "always invalid id");
        require(tenants[msg.sender].ids != 0, "no staking data");
        require(tenants[msg.sender].ids >= _id, "no staking data with such id");
        
        uint256 indexify = _id-1;
        string memory currency;
        if (tenants[msg.sender].stakes[indexify].stakingCurrency == 0)
            currency = "ETH";
        else 
            currency = "XR";
        
        return (currency, tenants[msg.sender].stakes[indexify].stakingAmount, tenants[msg.sender].stakes[indexify].coordinates);
    }
    
    
    function getStakingStructLength () public view returns (uint256) {
        return tenants[msg.sender].stakes.length;
    }
}