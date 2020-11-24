 

pragma solidity ^0.4.13;

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

   
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract CSTWallet is Ownable, Pausable {

     
    mapping (address => uint) public balances; 
  
     
    address public tokenAddress;

     
    address public emergencyWithdrawAddress;
  
     
    IERC20 tokenInstance;

    event Deposit(address from, uint amount, uint blockNumber);
    event Withdrawal(address to, uint amount, uint blockNumber);
    
    event EmergencyWithdrawERC20(address to, uint balance, address tokenTarget);
    event EmergencyWithdrawETH(address to, uint balance);
    event EmergencyAddressChanged(address account);

    constructor(address targetToken) public {
        setToken(targetToken);
        setEmergencyWithdrawAddress(msg.sender);
    }

    function depositERC20(address account, uint256 amount) public whenNotPaused{
        require(tokenAddress != address(0), "ERC20 token contract is not set. Please contact with the smart contract owner.");
        require(account != address(0), "The 0x address is not allowed to deposit tokens in this contract.");
        require(tokenInstance.allowance(account, address(this)) >= amount, "Owner did not allow this smart contract to transfer.");
        require(amount > 0, "Amount can not be zero");
        tokenInstance.transferFrom(account, address(this), amount);
        balances[account] += amount;
        emit Deposit(account, amount, block.number);
    }

    function withdrawERC20(uint amount) public whenNotPaused {
        require(tokenAddress != address(0), "ERC20 token contract is not set. Please contact with the smart contract owner.");
        require(msg.sender != address(0), "The 0x address is not allowed to withdraw tokens in this contract.");
        require(amount > 0, "Amount can not be zero");
        uint256 currentBalance = balances[msg.sender];
        require(amount <= currentBalance,  "Amount is greater than current balance.");
        balances[msg.sender] -= amount;
        require(tokenInstance.transfer(msg.sender, amount), "Error while making ERC20 transfer");
        emit Withdrawal(msg.sender, amount, block.number);
    }

    function emergencyWithdrawERC20(address tokenTarget, uint amount) public onlyOwner whenPaused {
        require(tokenTarget != address(0), "Token address can not be the zero address");
        require(emergencyWithdrawAddress != address(0), "The emergency withdraw address can not be the zero address");
        uint currentBalance = IERC20(tokenTarget).balanceOf(address(this));
        require(amount <= currentBalance, "Withdrawal amount is bigger than balance");
        IERC20(tokenTarget).transfer(emergencyWithdrawAddress, amount);
        emit EmergencyWithdrawERC20(emergencyWithdrawAddress, amount, tokenTarget);
    }

    function emergencyWithdrawETH(uint amount) public onlyOwner whenPaused {
        require(emergencyWithdrawAddress != address(0), "The emergency withdraw address can not be the zero address");
        uint currentBalance = address(this).balance;
        require(amount <= currentBalance, "Withdrawal amount is bigger than balance");
        emergencyWithdrawAddress.transfer(amount);
        emit EmergencyWithdrawETH(emergencyWithdrawAddress, amount);
    }

    function setEmergencyWithdrawAddress(address withdrawAddress) public onlyOwner {
        require(withdrawAddress != address(0), "The emergency withdraw address can not be the zero address");
        emergencyWithdrawAddress = withdrawAddress;
        emit EmergencyAddressChanged(emergencyWithdrawAddress);
    }

    function setToken(address contractAddress) public onlyOwner {
        tokenAddress = contractAddress;
        tokenInstance = IERC20(tokenAddress);
    }

    function () external {
        require(false, "Fallback function is disabled");
    }
}