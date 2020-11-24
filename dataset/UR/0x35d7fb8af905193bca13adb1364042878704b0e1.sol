 

pragma solidity 0.4.24;









 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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



 
contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}













 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}



 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}



 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

}






 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}



 
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
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




 





contract CustomWhitelist is Ownable {
  mapping(address => bool) public whitelist;
  uint256 public numberOfWhitelists;

  event WhitelistedAddressAdded(address _addr);
  event WhitelistedAddressRemoved(address _addr);

   
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender] || msg.sender == owner);
    _;
  }

  constructor() public {
    whitelist[msg.sender] = true;
    numberOfWhitelists = 1;
    emit WhitelistedAddressAdded(msg.sender);
  }
   
  function addAddressToWhitelist(address _addr) onlyWhitelisted  public {
    require(_addr != address(0));
    require(!whitelist[_addr]);

    whitelist[_addr] = true;
    numberOfWhitelists++;

    emit WhitelistedAddressAdded(_addr);
  }

   
  function removeAddressFromWhitelist(address _addr) onlyWhitelisted  public {
    require(_addr != address(0));
    require(whitelist[_addr]);
     
    require(_addr != owner);

    whitelist[_addr] = false;
    numberOfWhitelists--;

    emit WhitelistedAddressRemoved(_addr);
  }

}



 
contract CustomPausable is CustomWhitelist {
  event Pause();
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyWhitelisted whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyWhitelisted whenPaused public {
    paused = false;
    emit Unpause();
  }
}


 
contract VibeoToken is StandardToken, BurnableToken, NoOwner, CustomPausable {
  string public constant name = "Vibeo";
  string public constant symbol = "VBEO";
  uint8 public constant decimals = 18;

  uint256 public constant MAX_SUPPLY = 950000000 * (10 ** uint256(decimals));  

   
  bool public transfersEnabled;

   
  bool public softCapReached;

  mapping(bytes32 => bool) private mintingList;

   
  mapping(address => bool) private transferAgents;

   
  uint256 public icoEndDate;
  uint256 private year = 365 * 1 days;

  event TransferAgentSet(address agent, bool state);
  event BulkTransferPerformed(address[] _destinations, uint256[] _amounts);

  constructor() public {
    mintTokens(msg.sender, 453000000);
    setTransferAgent(msg.sender, true);
  }

   
   
  modifier canTransfer(address _from) {
    if (!transfersEnabled && !transferAgents[_from]) {
      revert();
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

   
   
  function setICOEndDate(uint256 _date) public whenNotPaused onlyWhitelisted {
    require(icoEndDate == 0);
    icoEndDate = _date;
  }

   
   
  function setSoftCapReached() public onlyWhitelisted {
    require(!softCapReached);
    softCapReached = true;
  }

   
  function enableTransfers() public onlyWhitelisted {
    require(icoEndDate > 0);
    require(now >= icoEndDate);
    require(!transfersEnabled);
    transfersEnabled = true;
  }

   
  function disableTransfers() public onlyWhitelisted {
    require(transfersEnabled);
    transfersEnabled = false;
  }

   
   
   
  function mintOnce(string _key, address _to, uint256 _amount) private whenNotPaused whenNotMinted(_key) {
    mintTokens(_to, _amount);
    mintingList[computeHash(_key)] = true;
  }

   
   
  function mintTeamTokens() public onlyWhitelisted {
    require(icoEndDate > 0);
    require(softCapReached);
    
    if(now < icoEndDate + year) {
      revert("Access is denied. The team tokens are locked for 1 year from the ICO end date.");
    }

    mintOnce("team", msg.sender, 50000000);
  }

   
   
  function mintTreasuryTokens() public onlyWhitelisted {
    require(icoEndDate > 0);
    require(softCapReached);

    mintOnce("treasury", msg.sender, 90000000);
  }

   
   
  function mintAdvisorTokens() public onlyWhitelisted {
    require(icoEndDate > 0);

    if(now < icoEndDate + year) {
      revert("Access is denied. The advisor tokens are locked for 1 year from the ICO end date.");
    }

    mintOnce("advisorsTokens", msg.sender, 80000000);
  }

   
   
  function mintPartnershipTokens() public onlyWhitelisted {
    require(softCapReached);
    mintOnce("partnerships", msg.sender, 60000000);
  }

   
   
  function mintCommunityRewards() public onlyWhitelisted {
    require(softCapReached);
    mintOnce("communityRewards", msg.sender, 90000000);
  }

   
   
  function mintUserAdoptionTokens() public onlyWhitelisted {
    require(icoEndDate > 0);
    require(softCapReached);

    mintOnce("useradoption", msg.sender, 95000000);
  }

   
   
  function mintMarketingTokens() public onlyWhitelisted {
    require(softCapReached);
    mintOnce("marketing", msg.sender, 32000000);
  }

   
   
   
   
   
  function setTransferAgent(address _agent, bool _state) public whenNotPaused onlyWhitelisted {
    transferAgents[_agent] = _state;
    emit TransferAgentSet(_agent, _state);
  }

   
   
   
  function isTransferAgent(address _address) public constant onlyWhitelisted returns(bool) {
    return transferAgents[_address];
  }

   
   
   
   
   
  function transfer(address _to, uint256 _value) public whenNotPaused canTransfer(msg.sender) returns (bool) {
    require(_to != address(0));
    return super.transfer(_to, _value);
  }

   
   
   
   
   
  function mintTokens(address _to, uint256 _value) private {
    require(_to != address(0));
    _value = _value.mul(10 ** uint256(decimals));
    require(totalSupply_.add(_value) <= MAX_SUPPLY);

    totalSupply_ = totalSupply_.add(_value);
    balances[_to] = balances[_to].add(_value);
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

   
   
   
   
  function decreaseApproval(address _spender, uint256 _subtractedValue) public canTransfer(msg.sender) whenNotPaused returns (bool) {
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

   
   
   
  function bulkTransfer(address[] _destinations, uint256[] _amounts) public onlyWhitelisted {
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