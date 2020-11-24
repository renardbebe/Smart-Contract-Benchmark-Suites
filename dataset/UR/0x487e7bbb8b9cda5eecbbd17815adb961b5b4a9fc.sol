 

pragma solidity ^0.4.11;
 


 



 
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

 




 
contract HasNoEther is Ownable {

   
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

 



 



 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 



 






 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}


 




contract PortCoin is ERC20 {

  address mayor;

  string public name = "Portland Maine Token";
  string public symbol = "PORT";
  uint public decimals = 0;

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) approvals;

  event NewMayor(address indexed oldMayor, address indexed newMayor);

  function PortCoin() public {
    mayor = msg.sender;
  }

  modifier onlyMayor() {
    require(msg.sender == mayor);
    _;
  }

  function electNewMayor(address newMayor) onlyMayor public {
    address oldMayor = mayor;
    mayor = newMayor;
    NewMayor(oldMayor, newMayor);
  }

  function issue(address to, uint256 amount) onlyMayor public returns (bool){
    totalSupply += amount;
    balances[to] += amount;
    Transfer(0x0, to, amount);
    return true;
  }

  function balanceOf(address who) public constant returns (uint256) {
    return balances[who];
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(balances[msg.sender] >= value);
    balances[to] += value;
    balances[msg.sender] -= value;
    Transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public returns (bool) {
    approvals[msg.sender][spender] = value;
    Approval(msg.sender, spender, value);
    return true;
  }

  function allowance(address owner, address spender) public constant returns (uint256) {
    return approvals[owner][spender];
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(approvals[from][msg.sender] >= value);
    require(balances[from] >= value);

    balances[to] += value;
    balances[from] -= value;
    approvals[from][msg.sender] -= value;
    Transfer(from, to, value);
    return true;
  }
}


contract PortMayor is Ownable, HasNoEther, CanReclaimToken {

  PortCoin coin;
  mapping(address => uint256) tickets;

  event Attend(address indexed attendee, uint256 ticket, address indexed eventAddress);
  event EventCreated(address eventAddress);

  function PortMayor(address portCoinAddress) public {
    coin = PortCoin(portCoinAddress);
  }

  function electNewMayor(address newMayor) onlyOwner public {
    coin.electNewMayor(newMayor);
  }

  function isEvent(address eventAddress) view public returns (bool) {
    return tickets[eventAddress] > 0;
  }

  function isValidTicket(address eventAddress, uint8 ticket) view public returns (bool){
    return (tickets[eventAddress] & (uint256(2) ** ticket)) > 0;
  }

  function createEvent(address eventAddress) onlyOwner public {
    tickets[eventAddress] = uint256(0) - 1;  
    EventCreated(eventAddress);
  }

  function stringify(uint8 v) public pure returns (string ret) {
    bytes memory data = new bytes(3);
    data[0] = bytes1(48 + (v / 100) % 10);
    data[1] = bytes1(48 + (v / 10) % 10);
    data[2] = bytes1(48 + v % 10);
    return string(data);
  }

  function attend(uint8 ticket, bytes32 r, bytes32 s, uint8 v) public {
    address eventAddress = ecrecover(keccak256("\x19Ethereum Signed Message:\n3",stringify(ticket)),v,r,s);
    require(isValidTicket(eventAddress, ticket));
    tickets[eventAddress] = tickets[eventAddress] ^ (uint256(2) ** ticket);
    coin.issue(msg.sender, 1);
    Attend(msg.sender, ticket, eventAddress);
  }

  function issue(address to, uint quantity) public onlyOwner {
    coin.issue(to, quantity);
  }
}