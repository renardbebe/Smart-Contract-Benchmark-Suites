 

 
 
contract Owned {

     
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

     
    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

     
     
    function changeOwner(address _newOwner) onlyOwner {
        if(msg.sender == owner) {
            owner = _newOwner;
        }
    }
}




 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}


contract AccountOwnership is Owned {
  using SafeMath for uint256;
  
  mapping (address => uint256) public transfers;
  address public depositAddress;
  
  event RefundTransfer(uint256 date, uint256 paid, uint256 refunded, address user);
  
  function AccountOwnership() payable {
  }

  function withdrawEther (address _to) onlyOwner {
    _to.transfer(this.balance);
  }

  function setDepositAddress(address _depositAddress) onlyOwner {
    depositAddress = _depositAddress;
  }

  function ()  payable {
    require(msg.value > 0);
    if (depositAddress != msg.sender) {
      transfers[msg.sender] = msg.value;
      msg.sender.transfer(msg.value);
      RefundTransfer(now, msg.value, msg.value, msg.sender);
    }
  }
}