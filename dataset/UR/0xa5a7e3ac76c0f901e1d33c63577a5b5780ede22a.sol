 

pragma solidity 0.4.18;

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
    require(newOwner != address(0) && newOwner != owner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);  
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
}

 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

contract UserTokensControl is Ownable, Pausable{
  address companyReserve;
  address founderReserve;
  address deedSaftReserve;
  bool public isSwapDone = false;

  modifier isUserAbleToTransferCheck() {
    if(msg.sender == owner){
      _;
    }else{
      if(msg.sender == deedSaftReserve){
        isSwapDone = true;
      }

      if(isSwapDone){
        _;
      }else{
        if(paused){     
          revert();
        }else{
          _;
        }
      }
    }
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic, UserTokensControl {
  using SafeMath for uint256;
  bool isDistributeToFounders=false;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public isUserAbleToTransferCheck whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(_value >= 0);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferByOwnerContract(address _to, uint256 _value) public onlyOwner returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(_value >= 0);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public isUserAbleToTransferCheck whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value >= 0);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_spender != address(0));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    require(_owner != address(0));
    require(_spender != address(0));
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract DeedCoin is StandardToken,Destructible {
  string public constant name = "Deedcoin";
  uint public constant decimals = 18;
  string public constant symbol = "DEED";

  function DeedCoin()  public {
    totalSupply=132857135 *(10**decimals);   
    owner = msg.sender;
    companyReserve = 0xbBE0805F7660aE0C4C7484dBee097398329eD5f2;
    founderReserve = 0x63547A5423652ABaF323c5B4fae848C7686B28Bf; 
    deedSaftReserve = 0x3EA6F9f6D21CEEf6ce84dA606754887b3e6AAFf6; 
    balances[msg.sender] = 36999996 * (10**decimals);
    balances[companyReserve] = 19928570 * (10**decimals); 
    balances[founderReserve] = 19928570 * (10**decimals);
    balances[deedSaftReserve] = 55999999 * (10 ** decimals);
  }

  function() public {
     revert();
  }
}