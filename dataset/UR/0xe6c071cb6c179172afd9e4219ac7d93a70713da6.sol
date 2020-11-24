 

pragma solidity 0.4.21;

 

 
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

 

 
contract Pausable is Ownable {
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 

 
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

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 

 
contract ChipTreasury is Pausable {
  using SafeMath for uint256;

  mapping(uint => Chip) public chips;
  uint                  public numChipsMinted;
  uint                  public numChipsClaimed;

  struct Chip {
    bytes32 hash;
    bool claimed;
  }

  event Deposit(address indexed sender, uint value);
  event Withdrawal(address indexed to, uint value);
  event TokenWithdrawal(address indexed to, address indexed token, uint value);

  event ChipMinted(uint indexed chipId);
  event ChipClaimAttempt(address indexed sender, uint indexed chipId);
  event ChipClaimSuccess(address indexed sender, uint indexed chipId);

  function ChipTreasury () public {
    paused = true;
  }

  function () public payable {
    if (msg.value > 0) emit Deposit(msg.sender, msg.value);
  }

  function claimChip (uint chipId, string password) public whenNotPaused {
    emit ChipClaimAttempt(msg.sender, chipId);
     
    require(isClaimed(chipId) == false);        
    require(isChipPassword(chipId, password));  

     
    uint chipValue = getChipValue();            
    numChipsClaimed = numChipsClaimed.add(1);   
    chips[chipId].claimed = true;               

     
    msg.sender.transfer(chipValue);             
    emit ChipClaimSuccess(msg.sender, chipId);
  }

   
  function mintChip (bytes32 hash) public onlyOwner {
    chips[numChipsMinted] = Chip(hash, false);
    emit ChipMinted(numChipsMinted);
    numChipsMinted = numChipsMinted.add(1);
  }

  function withdrawFunds (uint value) public onlyOwner {
    owner.transfer(value);
    emit Withdrawal(owner, value);
  }

  function withdrawTokens (address token, uint value) public onlyOwner {
    StandardToken(token).transfer(owner, value);
    emit TokenWithdrawal(owner, token, value);
  }

  function isClaimed (uint chipId) public constant returns(bool) {
    return chips[chipId].claimed;
  }

  function getNumChips () public constant returns(uint) {
    return numChipsMinted.sub(numChipsClaimed);
  }

  function getChipIds (bool isChipClaimed) public constant returns(uint[]) {
    uint[] memory chipIdsTemp = new uint[](numChipsMinted);
    uint count = 0;
    uint i;

     
    for (i = 0; i < numChipsMinted; i++) {
      if (isChipClaimed == chips[i].claimed) {
        chipIdsTemp[count] = i;
        count += 1;
      }
    }

     
    uint[] memory _chipIds = new uint[](count);
    for (i = 0; i < count; i++) _chipIds[i] = chipIdsTemp[i];
    return _chipIds;
  }

  function getChipValue () public constant returns(uint) {
    uint numChips = getNumChips();
    if (numChips > 0) return address(this).balance.div(numChips);
    return 0;
  }

  function isChipPassword (uint chipId, string password) internal constant returns(bool) {
    return chips[chipId].hash == keccak256(password);
  }

}