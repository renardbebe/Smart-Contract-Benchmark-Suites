 

pragma solidity 0.4.24;

 
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
    require(admins[msg.sender] || msg.sender == owner);
    _;
  }

   
   
  function addAdmin(address _address) external onlyAdmin {
    require(_address != address(0));
    require(!admins[_address]);

     
    require(_address != owner);

    admins[_address] = true;

    emit AdminAdded(_address);
  }

   
   
  function addManyAdmins(address[] _accounts) external onlyAdmin {
    for(uint8 i=0; i<_accounts.length; i++) {
      address account = _accounts[i];

       
       
       
      if(account != address(0) && !admins[account] && account != owner){
        admins[account] = true;

        emit AdminAdded(_accounts[i]);
      }
    }
  }

   
   
  function removeAdmin(address _address) external onlyAdmin {
    require(_address != address(0));
    require(admins[_address]);

     
    require(_address != owner);

    admins[_address] = false;
    emit AdminRemoved(_address);
  }

  function isAdmin(address _account) view public returns(bool) {
    return admins[_account] || _account == owner;
  }

   
   
  function removeManyAdmins(address[] _accounts) external onlyAdmin {
    for(uint8 i=0; i<_accounts.length; i++) {
      address account = _accounts[i];

       
       
       
      if(account != address(0) && admins[account] && account != owner){
        admins[account] = false;

        emit AdminRemoved(_accounts[i]);
      }
    }
  }
}

 








 
contract CustomPausable is CustomAdmin {
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

   
  function pause() external onlyAdmin whenNotPaused {
    paused = true;
    emit Paused();
  }

   
  function unpause() external onlyAdmin whenPaused {
    paused = false;
    emit Unpaused();
  }
}

 







 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract VRHToken is StandardToken, CustomPausable, BurnableToken {
  uint8 public constant decimals = 18;
  string public constant name = "Virtual Rehab";
  string public constant symbol = "VRH";

  uint public constant MAX_SUPPLY = 400000000 * (10 ** uint256(decimals));
  uint public constant INITIAL_SUPPLY = (400000000 - 1650000 - 2085000 - 60000000) * (10 ** uint256(decimals));

  bool public released = false;
  uint public ICOEndDate;


  mapping(bytes32 => bool) private mintingList;

  event Mint(address indexed to, uint256 amount);
  event BulkTransferPerformed(address[] _destinations, uint256[] _amounts);
  event TokenReleased(bool _state);
  event ICOEndDateSet(uint256 _date);

   
   
  modifier canTransfer(address _from) {
    if(paused || !released) {
      if(!isAdmin(_from)) {
        revert();
      }
    }

    _;
  }

   
   
  function computeHash(string _key) private pure returns(bytes32){
    return keccak256(abi.encodePacked(_key));
  }

   
   
  modifier whenNotMinted(string _key) {
    if(mintingList[computeHash(_key)]) {
      revert();
    }

    _;
  }

  constructor() public {
    mintTokens(msg.sender, INITIAL_SUPPLY);
  }



   
   
  function releaseTokenForTransfer() public onlyAdmin whenNotPaused {
    require(!released);

    released = true;

    emit TokenReleased(released);
  }

   
  function disableTokenTransfers() public onlyAdmin whenNotPaused {
    require(released);

    released = false;

    emit TokenReleased(released);
  }

   
   
  function setICOEndDate(uint _date) public onlyAdmin {
    require(ICOEndDate == 0);
    require(_date > now);

    ICOEndDate = _date;

    emit ICOEndDateSet(_date);
  }

   
   
   
   
   
  function mintTokens(address _to, uint _value) private {
    require(_to != address(0));
    require(totalSupply_.add(_value) <= MAX_SUPPLY);

    balances[_to] = balances[_to].add(_value);
    totalSupply_ = totalSupply_.add(_value);

    emit Mint(_to, _value);
    emit Transfer(address(0), _to, _value);
  }

   
   
   
   
  function mintOnce(string _key, address _to, uint256 _amount) private whenNotPaused whenNotMinted(_key) {
    _amount = _amount * (10 ** uint256(decimals));
    mintTokens(_to, _amount);
    mintingList[computeHash(_key)] = true;
  }

   
   
  function mintTokensForAdvisors() public onlyAdmin {
    require(ICOEndDate != 0);

    require(now > (ICOEndDate + 365 days));
    mintOnce("advisors", msg.sender, 1650000);
  }

   
   
  function mintTokensForFounders() public onlyAdmin {
    require(ICOEndDate != 0);
    require(now > (ICOEndDate + 720 days));

    mintOnce("founders", msg.sender, 60000000);
  }

   
   
  function mintTokensForServices() public onlyAdmin  {
    require(ICOEndDate != 0);
    require(now > (ICOEndDate + 60 days));

    mintOnce("services", msg.sender, 2085000);
  }

   
   
   
   
   
  function transfer(address _to, uint256 _value) public canTransfer(msg.sender) returns (bool) {
    require(_to != address(0));
    return super.transfer(_to, _value);
  }

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from) public returns (bool) {
    require(_to != address(0));
    return super.transferFrom(_from, _to, _value);
  }

   
   
   
   
  function approve(address _spender, uint256 _value) public canTransfer(msg.sender) returns (bool) {
    require(_spender != address(0));
    return super.approve(_spender, _value);
  }


   
   
   
   
  function increaseApproval(address _spender, uint256 _addedValue) public canTransfer(msg.sender) returns(bool) {
    require(_spender != address(0));
    return super.increaseApproval(_spender, _addedValue);
  }

   
   
   
   
  function decreaseApproval(address _spender, uint256 _subtractedValue) public canTransfer(msg.sender) returns (bool) {
    require(_spender != address(0));
    return super.decreaseApproval(_spender, _subtractedValue);
  }

   
   
  function sumOf(uint256[] _values) private pure returns(uint256) {
    uint256 total = 0;

    for (uint256 i = 0; i < _values.length; i++) {
      total = total.add(_values[i]);
    }

    return total;
  }

   
   
   
  function bulkTransfer(address[] _destinations, uint256[] _amounts) public onlyAdmin {
    require(_destinations.length == _amounts.length);

     
     
    uint256 requiredBalance = sumOf(_amounts);
    require(balances[msg.sender] >= requiredBalance);

    for (uint256 i = 0; i < _destinations.length; i++) {
     transfer(_destinations[i], _amounts[i]);
    }

    emit BulkTransferPerformed(_destinations, _amounts);
  }

   
   
   
  function burn(uint256 _value) public whenNotPaused {
    super.burn(_value);
  }
}