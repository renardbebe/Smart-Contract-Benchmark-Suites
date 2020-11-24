 

 

pragma solidity ^0.4.24;

 











 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}






 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}






 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
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



 
contract CustomAdmin is Ownable {
   
  mapping(address => bool) public admins;

  event AdminAdded(address indexed _address);
  event AdminRemoved(address indexed _address);

   
  modifier onlyAdmin() {
    require(isAdmin(msg.sender), "Access is denied.");
    _;
  }

   
   
  function addAdmin(address _address) external onlyAdmin returns(bool) {
    require(_address != address(0), "Invalid address.");
    require(!admins[_address], "This address is already an administrator.");

    require(_address != owner, "The owner cannot be added or removed to or from the administrator list.");

    admins[_address] = true;

    emit AdminAdded(_address);
    return true;
  }

   
   
  function addManyAdmins(address[] _accounts) external onlyAdmin returns(bool) {
    for(uint8 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];

       
       
       
      if(account != address(0) && !admins[account] && account != owner) {
        admins[account] = true;

        emit AdminAdded(_accounts[i]);
      }
    }

    return true;
  }

   
   
  function removeAdmin(address _address) external onlyAdmin returns(bool) {
    require(_address != address(0), "Invalid address.");
    require(admins[_address], "This address isn't an administrator.");

     
    require(_address != owner, "The owner cannot be added or removed to or from the administrator list.");

    admins[_address] = false;
    emit AdminRemoved(_address);
    return true;
  }

   
   
  function removeManyAdmins(address[] _accounts) external onlyAdmin returns(bool) {
    for(uint8 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];

       
       
       
      if(account != address(0) && admins[account] && account != owner) {
        admins[account] = false;

        emit AdminRemoved(_accounts[i]);
      }
    }

    return true;
  }

   
  function isAdmin(address _address) public view returns(bool) {
    if(_address == owner) {
      return true;
    }

    return admins[_address];
  }
}



 
contract CustomPausable is CustomAdmin {
  event Paused();
  event Unpaused();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused, "Sorry but the contract isn't paused.");
    _;
  }

   
  modifier whenPaused() {
    require(paused, "Sorry but the contract is paused.");
    _;
  }

   
  function pause() external onlyAdmin whenNotPaused {
    paused = true;
    emit Paused();
  }

   
  function unpause() external onlyAdmin whenPaused {
    paused = false;
    emit Unpaused();
  }
}
 






 
 
 
 
contract TransferState is CustomPausable {
  bool public released = false;

  event TokenReleased(bool _state);

   
   
  modifier canTransfer(address _from) {
    if(paused || !released) {
      if(!isAdmin(_from)) {
        revert("Operation not allowed. The transfer state is restricted.");
      }
    }

    _;
  }

   
   
  function enableTransfers() external onlyAdmin whenNotPaused returns(bool) {
    require(!released, "Invalid operation. The transfer state is no more restricted.");

    released = true;

    emit TokenReleased(released);
    return true;
  }

   
  function disableTransfers() external onlyAdmin whenNotPaused returns(bool) {
    require(released, "Invalid operation. The transfer state is already restricted.");

    released = false;

    emit TokenReleased(released);
    return true;
  }
}
 







 
 
 
contract BulkTransfer is StandardToken, CustomAdmin {
  event BulkTransferPerformed(address[] _destinations, uint256[] _amounts);

   
   
   
  function bulkTransfer(address[] _destinations, uint256[] _amounts) public onlyAdmin returns(bool) {
    require(_destinations.length == _amounts.length, "Invalid operation.");

     
     
    uint256 requiredBalance = sumOf(_amounts);
    require(balances[msg.sender] >= requiredBalance, "You don't have sufficient funds to transfer amount that large.");
    
    for (uint256 i = 0; i < _destinations.length; i++) {
      transfer(_destinations[i], _amounts[i]);
    }

    emit BulkTransferPerformed(_destinations, _amounts);
    return true;
  }
  
   
   
  function sumOf(uint256[] _values) private pure returns(uint256) {
    uint256 total = 0;

    for (uint256 i = 0; i < _values.length; i++) {
      total = total.add(_values[i]);
    }

    return total;
  }
}
 










 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}




 
 
 
 
 
contract Reclaimable is CustomAdmin {
  using SafeERC20 for ERC20;

   
  function reclaimEther() external onlyAdmin {
    msg.sender.transfer(address(this).balance);
  }

   
   
  function reclaimToken(address _token) external onlyAdmin {
    ERC20 erc20 = ERC20(_token);
    uint256 balance = erc20.balanceOf(this);
    erc20.safeTransfer(msg.sender, balance);
  }
}


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract TokenBase is StandardToken, TransferState, BulkTransfer, Reclaimable, BurnableToken {
   
  uint8 public constant decimals = 18;
  string public constant name = "CYBR Token";
  string public constant symbol = "CYBR";
   

  uint256 internal constant MILLION = 1000000 * 1 ether; 
  uint256 internal constant BILLION = 1000000000 * 1 ether; 
  uint256 public constant MAX_SUPPLY = 1 * BILLION;
  uint256 public constant INITIAL_SUPPLY = 510 * MILLION; 

  event Mint(address indexed to, uint256 amount);

  constructor() public {
    mintTokens(msg.sender, INITIAL_SUPPLY);
  }

   
   
   
   
   
  function transfer(address _to, uint256 _value) public canTransfer(msg.sender) returns(bool) {
    require(_to != address(0), "Invalid address.");
    return super.transfer(_to, _value);
  }

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) public canTransfer(_from) returns(bool) {
    require(_to != address(0), "Invalid address.");
    return super.transferFrom(_from, _to, _value);
  }

   
   
   
   
  function approve(address _spender, uint256 _value) public canTransfer(msg.sender) returns(bool) {
    require(_spender != address(0), "Invalid address.");
    return super.approve(_spender, _value);
  }

   
   
   
   
  function increaseApproval(address _spender, uint256 _addedValue) public canTransfer(msg.sender) returns(bool) {
    require(_spender != address(0), "Invalid address.");
    return super.increaseApproval(_spender, _addedValue);
  }

   
   
   
   
  function decreaseApproval(address _spender, uint256 _subtractedValue) public canTransfer(msg.sender) returns(bool) {
    require(_spender != address(0), "Invalid address.");
    return super.decreaseApproval(_spender, _subtractedValue);
  }
  
   
   
   
  function burn(uint256 _value) public whenNotPaused {
    super.burn(_value);
  }

   
   
   
   
   
  function mintTokens(address _to, uint _value) internal returns(bool) {
    require(_to != address(0), "Invalid address.");
    require(totalSupply_.add(_value) <= MAX_SUPPLY, "Sorry but the total supply can't exceed the maximum supply.");

    balances[_to] = balances[_to].add(_value);
    totalSupply_ = totalSupply_.add(_value);

    emit Transfer(address(0), _to, _value);
    emit Mint(_to, _value);

    return true;
  }
}


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
   
 
 
 
 
 
 
 
 
 
 
 
contract CYBRToken is TokenBase {
   
   

  uint256 public icoEndDate;

  uint256 public constant ALLOCATION_FOR_FOUNDERS = 100 * MILLION; 
  uint256 public constant ALLOCATION_FOR_TEAM = 100 * MILLION; 
  uint256 public constant ALLOCATION_FOR_RESERVE = 100 * MILLION; 
  uint256 public constant ALLOCATION_FOR_INITIAL_PARTNERSHIPS = 50 * MILLION; 
  uint256 public constant ALLOCATION_FOR_PARTNERSHIPS = 50 * MILLION; 
  uint256 public constant ALLOCATION_FOR_ADVISORS = 60 * MILLION; 
  uint256 public constant ALLOCATION_FOR_PROMOTION = 30 * MILLION; 

  bool public targetReached = false;

  mapping(bytes32 => bool) private mintingList;

  event ICOEndDateSet(uint256 _date);
  event TargetReached();

   
   
  modifier whenNotMinted(string _key) {
    if(mintingList[computeHash(_key)]) {
      revert("Duplicate minting key supplied.");
    }

    _;
  }

   
   
  function setSuccess() external onlyAdmin returns(bool) {
    require(!targetReached, "Access is denied.");
    targetReached = true;

    emit TargetReached();
  }

   
   
   
  function setICOEndDate(uint _date) external onlyAdmin returns(bool) {
    require(icoEndDate == 0, "The ICO end date was already set.");

    icoEndDate = _date;
    
    emit ICOEndDateSet(_date);
    return true;
  }

   
   
  function mintTokensForFounders() external onlyAdmin returns(bool) {
    require(targetReached, "Sorry, you can't mint at this time because the target hasn't been reached yet.");
    require(icoEndDate != 0, "You need to specify the ICO end date before minting the tokens.");
    require(now > (icoEndDate + 548 days), "Access is denied, it's too early to mint founder tokens.");

    return mintOnce("founders", msg.sender, ALLOCATION_FOR_FOUNDERS);
  }

   
   
  function mintTokensForTeam() external onlyAdmin returns(bool) {
    require(targetReached, "Sorry, you can't mint at this time because the target hasn't been reached yet.");
    require(icoEndDate != 0, "You need to specify the ICO end date before minting the tokens.");
    require(now > (icoEndDate + 365 days), "Access is denied, it's too early to mint team tokens.");

    return mintOnce("team", msg.sender, ALLOCATION_FOR_TEAM);
  }

   
   
  function mintReserveTokens() external onlyAdmin returns(bool) {
    require(targetReached, "Sorry, you can't mint at this time because the target hasn't been reached yet.");
    require(icoEndDate != 0, "You need to specify the ICO end date before minting the tokens.");
    require(now > (icoEndDate + 365 days), "Access is denied, it's too early to mint the reserve tokens.");

    return mintOnce("reserve", msg.sender, ALLOCATION_FOR_RESERVE);
  }

   
   
  function mintTokensForInitialPartnerships() external onlyAdmin returns(bool) {
    return mintOnce("initialPartnerships", msg.sender, ALLOCATION_FOR_INITIAL_PARTNERSHIPS);
  }

   
   
  function mintTokensForPartnerships() external onlyAdmin returns(bool) {
    require(targetReached, "Sorry, you can't mint at this time because the target hasn't been reached yet.");
    require(icoEndDate != 0, "You need to specify the ICO end date before minting the tokens.");
    require(now > (icoEndDate + 182 days), "Access is denied, it's too early to mint the partnership tokens.");

    return mintOnce("partnerships", msg.sender, ALLOCATION_FOR_PARTNERSHIPS);
  }

   
   
  function mintTokensForAdvisors() external onlyAdmin returns(bool) {
    require(targetReached, "Sorry, you can't mint at this time because the target hasn't been reached yet.");
    require(icoEndDate != 0, "You need to specify the ICO end date before minting the tokens.");
    require(now > (icoEndDate + 365 days), "Access is denied, it's too early to mint advisory tokens.");

    return mintOnce("advisors", msg.sender, ALLOCATION_FOR_ADVISORS);
  }

   
   
  function mintTokensForPromotion() external onlyAdmin returns(bool) {
    require(targetReached, "Sorry, you can't mint at this time because the target hasn't been reached yet.");
    require(icoEndDate != 0, "You need to specify the ICO end date before minting the tokens.");
    require(now > icoEndDate, "Access is denied, it's too early to mint the promotion tokens.");

    return mintOnce("promotion", msg.sender, ALLOCATION_FOR_PROMOTION);
  }

   
   
  function computeHash(string _key) private pure returns(bytes32) {
    return keccak256(abi.encodePacked(_key));
  }

   
   
   
   
  function mintOnce(string _key, address _to, uint256 _amount) private whenNotPaused whenNotMinted(_key) returns(bool) {
    mintingList[computeHash(_key)] = true;
    return mintTokens(_to, _amount);
  }
}