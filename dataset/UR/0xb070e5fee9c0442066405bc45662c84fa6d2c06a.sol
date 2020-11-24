 

pragma solidity ^0.4.15;

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

contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;

    ERC20Basic token;
     
    mapping (address => uint256) totalVestedAmount;

    struct Vesting {
        uint256 amount;
        uint256 vestingDate;
    }

    address[] accountKeys;
    mapping (address => Vesting[]) public vestingAccounts;

     
    event Vest(address indexed beneficiary, uint256 amount);
    event VestingCreated(address indexed beneficiary, uint256 amount, uint256 vestingDate);

     
    modifier tokenSet() {
        require(address(token) != address(0));
        _;
    }

     
    function TokenVesting(address token_address){
       require(token_address != address(0));
       token = ERC20Basic(token_address);
    }

     
    function setVestingToken(address token_address) external onlyOwner {
        require(token_address != address(0));
        token = ERC20Basic(token_address);
    }

     
    function createVestingByDurationAndSplits(address user, uint256 total_amount, uint256 startDate, uint256 durationPerVesting, uint256 times) public onlyOwner tokenSet {
        require(user != address(0));
        require(startDate >= now);
        require(times > 0);
        require(durationPerVesting > 0);
        uint256 vestingDate = startDate;
        uint256 i;
        uint256 amount = total_amount.div(times);
        for (i = 0; i < times; i++) {
            vestingDate = vestingDate.add(durationPerVesting);
            if (vestingAccounts[user].length == 0){
                accountKeys.push(user);
            }
            vestingAccounts[user].push(Vesting(amount, vestingDate));
            VestingCreated(user, amount, vestingDate);
        }
    }

     
    function getVestingAmountByNow(address user) constant returns (uint256){
        uint256 amount;
        uint256 i;
        for (i = 0; i < vestingAccounts[user].length; i++) {
            if (vestingAccounts[user][i].vestingDate < now) {
                amount = amount.add(vestingAccounts[user][i].amount);
            }
        }

    }

     
    function getAvailableVestingAmount(address user) constant returns (uint256){
        uint256 amount;
        amount = getVestingAmountByNow(user);
        amount = amount.sub(totalVestedAmount[user]);
        return amount;
    }

     
    function getAccountKeys(uint256 page) external constant returns (address[10]){
        address[10] memory accountList;
        uint256 i;
        for (i=0 + page * 10; i<10; i++){
            if (i < accountKeys.length){
                accountList[i - page * 10] = accountKeys[i];
            }
        }
        return accountList;
    }

     
    function vest() external tokenSet {
        uint256 availableAmount = getAvailableVestingAmount(msg.sender);
        require(availableAmount > 0);
        totalVestedAmount[msg.sender] = totalVestedAmount[msg.sender].add(availableAmount);
        token.transfer(msg.sender, availableAmount);
        Vest(msg.sender, availableAmount);
    }

     
    function drain() external onlyOwner {
        owner.transfer(this.balance);
        token.transfer(owner, this.balance);
    }
}