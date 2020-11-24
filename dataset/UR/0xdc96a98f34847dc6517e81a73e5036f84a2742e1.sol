 

pragma solidity ^0.4.18;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
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
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
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

 

 
contract HasNoEther is Ownable {

   
  function HasNoEther() payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

 

interface Vault {
    function contributionsOf(address _addr) public constant returns (uint256);
}

contract EcoPayments is Ownable, Pausable, HasNoEther, CanReclaimToken {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256[] private payoutDates = [
        1512086400,  
        1514764800,  
        1517443200,  
        1519862400,  
        1522540800,  
        1525132800,  
        1527811200,  
        1530403200,  
        1533081600,  
        1535760000,  
        1538352000,  
        1541030400   
    ];

    ERC20 public token;
    Vault public vault;

    mapping (address => uint256) private withdrawals;

    bool public initialized = false;

    modifier whenInitialized() {
        require (initialized == true);
        _;
    }

    function EcoPayments(ERC20 _token, Vault _vault) {
        token = _token;
        vault = _vault;
    }

    function init() onlyOwner returns (uint256) {
        require(token.balanceOf(this) == 5000000 * 10**18);
        initialized = true;
    }

    function withdraw() whenInitialized whenNotPaused public {
        uint256 amount = earningsOf(msg.sender);
        require (amount > 0);
        withdrawals[msg.sender] = withdrawals[msg.sender].add(amount);
        token.safeTransfer(msg.sender, amount);
    }

    function earningsOf(address _addr) public constant returns (uint256) {
        uint256 total = 0;
        uint256 interest = vault.contributionsOf(_addr).mul(833).div(10000);

        for (uint8 i = 0; i < payoutDates.length; i++) {
            if (now < payoutDates[i]) {
                break;
            }

            total = total.add(interest);
        }

         
        total = total.sub(withdrawals[_addr]);

        return total;
    }
}