 

pragma solidity ^0.4.24;

 

 

 
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
     
     
     
    return a / b;
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

 

 

 
contract ERC20Interface {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
 
 
contract TimeLockPool{
    using SafeMath for uint256;

    struct LockedBalance {
      uint256 balance;
      uint256 releaseTime;
    }

     
    mapping (address => mapping (address => LockedBalance[])) public lockedBalances;

    event Deposit(
        address indexed owner,
        address indexed tokenAddr,
        uint256 amount,
        uint256 releaseTime
    );

    event Withdraw(
        address indexed owner,
        address indexed tokenAddr,
        uint256 amount
    );

     
     
    constructor() public {}

     
     
     
     
     
     
    function depositERC20 (
        address tokenAddr,
        address account,
        uint256 amount,
        uint256 releaseTime
    ) external returns (bool) {
        require(account != address(0x0));
        require(tokenAddr != 0x0);
        require(msg.value == 0);
        require(amount > 0);
        require(ERC20Interface(tokenAddr).transferFrom(msg.sender, this, amount));

        lockedBalances[account][tokenAddr].push(LockedBalance(amount, releaseTime));
        emit Deposit(account, tokenAddr, amount, releaseTime);

        return true;
    }

     
     
     
     
    function depositETH (
        address account,
        uint256 releaseTime
    ) external payable returns (bool) {
        require(account != address(0x0));
        address tokenAddr = address(0x0);
        uint256 amount = msg.value;
        require(amount > 0);

        lockedBalances[account][tokenAddr].push(LockedBalance(amount, releaseTime));
        emit Deposit(account, tokenAddr, amount, releaseTime);

        return true;
    }

     
     
     
     
     
    function withdraw (address account, address tokenAddr, uint256 max_count) external returns (bool) {
        require(account != address(0x0));

        uint256 release_amount = 0;
        for (uint256 i = 0; i < lockedBalances[account][tokenAddr].length && i < max_count; i++) {
            if (lockedBalances[account][tokenAddr][i].balance > 0 &&
                lockedBalances[account][tokenAddr][i].releaseTime <= block.timestamp) {

                release_amount = release_amount.add(lockedBalances[account][tokenAddr][i].balance);
                lockedBalances[account][tokenAddr][i].balance = 0;
            }
        }

        require(release_amount > 0);

        if (tokenAddr == 0x0) {
            if (!account.send(release_amount)) {
                revert();
            }
            emit Withdraw(account, tokenAddr, release_amount);
            return true;
        } else {
            if (!ERC20Interface(tokenAddr).transfer(account, release_amount)) {
                revert();
            }
            emit Withdraw(account, tokenAddr, release_amount);
            return true;
        }
    }

     
     
     
     
    function getAvailableBalanceOf (address account, address tokenAddr) 
        external
        view
        returns (uint256)
    {
        require(account != address(0x0));

        uint256 balance = 0;
        for(uint256 i = 0; i < lockedBalances[account][tokenAddr].length; i++) {
            if (lockedBalances[account][tokenAddr][i].releaseTime <= block.timestamp) {
                balance = balance.add(lockedBalances[account][tokenAddr][i].balance);
            }
        }
        return balance;
    }

     
     
     
     
    function getLockedBalanceOf (address account, address tokenAddr)
        external
        view
        returns (uint256) 
    {
        require(account != address(0x0));

        uint256 balance = 0;
        for(uint256 i = 0; i < lockedBalances[account][tokenAddr].length; i++) {
            if(lockedBalances[account][tokenAddr][i].releaseTime > block.timestamp) {
                balance = balance.add(lockedBalances[account][tokenAddr][i].balance);
            }
        }
        return balance;
    }

     
     
     
     
    function getNextReleaseTimeOf (address account, address tokenAddr)
        external
        view
        returns (uint256) 
    {
        require(account != address(0x0));

        uint256 nextRelease = 2**256 - 1;
        for (uint256 i = 0; i < lockedBalances[account][tokenAddr].length; i++) {
            if (lockedBalances[account][tokenAddr][i].releaseTime > block.timestamp &&
               lockedBalances[account][tokenAddr][i].releaseTime < nextRelease) {

                nextRelease = lockedBalances[account][tokenAddr][i].releaseTime;
            }
        }

         
        if (nextRelease == 2**256 - 1) {
            nextRelease = 0;
        }
        return nextRelease;
    }
}