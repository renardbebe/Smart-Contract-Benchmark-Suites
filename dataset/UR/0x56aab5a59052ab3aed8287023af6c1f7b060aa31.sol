 

 

pragma solidity >=0.4.21 <0.6.0;

 



 



 


 




 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


 
 
contract CustomOwnable is Ownable {
   
  address private _trustee;

  event TrusteeAssigned(address indexed account);

   
  modifier onlyTrustee() {
    require(msg.sender == _trustee, "Access is denied.");
    _;
  }

   
   
   
  function assignTrustee(address account) external onlyOwner returns(bool) {
    require(account != address(0), "Please provide a valid address for trustee.");

    _trustee = account;
    emit TrusteeAssigned(account);
    return true;
  }

   
   
   
  function reassignOwner(address newOwner) external onlyTrustee returns(bool) {
    super._transferOwnership(newOwner);
    return true;
  }

   
   
  function getTrustee() external view returns(address) {
    return _trustee;
  }
}

 
 
 
 
 
 
contract CustomAdmin is CustomOwnable {
   
  mapping(address => bool) private _admins;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  event TrusteeAssigned(address indexed account);

   
  modifier onlyAdmin() {
    require(isAdmin(msg.sender), "Access is denied.");
    _;
  }

   
   
   
  function addAdmin(address account) external onlyAdmin returns(bool) {
    require(account != address(0), "Invalid address.");
    require(!_admins[account], "This address is already an administrator.");

    require(account != super.owner(), "The owner cannot be added or removed to or from the administrator list.");

    _admins[account] = true;

    emit AdminAdded(account);
    return true;
  }

   
   
   
  function addManyAdmins(address[] calldata accounts) external onlyAdmin returns(bool) {
    for(uint8 i = 0; i < accounts.length; i++) {
      address account = accounts[i];

       
       
       
      if(account != address(0) && !_admins[account] && account != super.owner()) {
        _admins[account] = true;

        emit AdminAdded(accounts[i]);
      }
    }

    return true;
  }

   
   
   
  function removeAdmin(address account) external onlyAdmin returns(bool) {
    require(account != address(0), "Invalid address.");
    require(_admins[account], "This address isn't an administrator.");

     
    require(account != super.owner(), "The owner cannot be added or removed to or from the administrator list.");

    _admins[account] = false;
    emit AdminRemoved(account);
    return true;
  }

   
   
   
  function removeManyAdmins(address[] calldata accounts) external onlyAdmin returns(bool) {
    for(uint8 i = 0; i < accounts.length; i++) {
      address account = accounts[i];

       
       
       
      if(account != address(0) && _admins[account] && account != super.owner()) {
        _admins[account] = false;

        emit AdminRemoved(accounts[i]);
      }
    }

    return true;
  }

   
   
  function isAdmin(address account) public view returns(bool) {
    if(account == super.owner()) {
       
      return true;
    }

    return _admins[account];
  }
}

 
 
 
 
contract CustomPausable is CustomAdmin {
  event Paused();
  event Unpaused();

  bool private _paused = false;

   
  modifier whenNotPaused() {
    require(!_paused, "Sorry but the contract is paused.");
    _;
  }

   
  modifier whenPaused() {
    require(_paused, "Sorry but the contract isn't paused.");
    _;
  }

   
  function pause() external onlyAdmin whenNotPaused {
    _paused = true;
    emit Paused();
  }

   
  function unpause() external onlyAdmin whenPaused {
    _paused = false;
    emit Unpaused();
  }

   
   
  function isPaused() external view returns(bool) {
    return _paused;
  }
}
 







 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}







 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


 
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC20 token, bytes memory data) private {
         
         

         
         
         
         
         
        require(address(token).isContract(), "SafeERC20: call to non-contract");

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {  
             
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

 





 
 
 
contract CappedTransfer is CustomPausable {
  event CapChanged(uint256 maximumTransfer, uint256 maximumTransferWei, uint256 oldMaximumTransfer, uint256 oldMaximumTransferWei);

   
  uint256 private _maximumTransfer = 0;
  uint256 private _maximumTransferWei = 0;

   
   
   
  function checkIfValidTransfer(uint256 amount) public view returns(bool) {
    require(amount > 0, "Access is denied.");

    if(_maximumTransfer > 0) {
      require(amount <= _maximumTransfer, "Sorry but the amount you're transferring is too much.");
    }

    return true;
  }

   
   
   
  function checkIfValidWeiTransfer(uint256 amount) public view returns(bool) {
    require(amount > 0, "Access is denied.");

    if(_maximumTransferWei > 0) {
      require(amount <= _maximumTransferWei, "Sorry but the amount you're transferring is too much.");
    }

    return true;
  }

   
   
  function setCap(uint256 cap, uint256 weiCap) external onlyOwner whenNotPaused returns(bool) {
    emit CapChanged(cap, weiCap, _maximumTransfer, _maximumTransferWei);

    _maximumTransfer = cap;
    _maximumTransferWei = weiCap;
    return true;
  }

   
   
  function getCap() external view returns(uint256, uint256) {
    return (_maximumTransfer, _maximumTransferWei);
  }
}

 
 
 
contract TransferBase is CappedTransfer {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  event TransferPerformed(address indexed token, address indexed transferredBy, address indexed destination, uint256 amount);
  event EtherTransferPerformed(address indexed transferredBy, address indexed destination, uint256 amount);

   
   
   
   
   
  function transferTokens(address token, address destination, uint256 amount)
  external onlyAdmin whenNotPaused
  returns(bool) {
    require(checkIfValidTransfer(amount), "Access is denied.");

    ERC20 erc20 = ERC20(token);

    require
    (
      erc20.balanceOf(address(this)) >= amount,
      "You don't have sufficient funds to transfer amount that large."
    );


    erc20.safeTransfer(destination, amount);


    emit TransferPerformed(token, msg.sender, destination, amount);
    return true;
  }

   
   
   
   
  function transferEthers(address payable destination, uint256 amount)
  external onlyAdmin whenNotPaused
  returns(bool) {
    require(checkIfValidWeiTransfer(amount), "Access is denied.");

    require
    (
      address(this).balance >= amount,
      "You don't have sufficient funds to transfer amount that large."
    );


    destination.transfer(amount);


    emit EtherTransferPerformed(msg.sender, destination, amount);
    return true;
  }

   
  function tokenBalanceOf(address token) external view returns(uint256) {
    ERC20 erc20 = ERC20(token);
    return erc20.balanceOf(address(this));
  }

   
  function () external payable whenNotPaused {
     
  }
}

 
 
 
 
contract BulkTransfer is TransferBase {
  event BulkTransferPerformed(address indexed token, address indexed transferredBy, uint256 length, uint256 totalAmount);
  event EtherBulkTransferPerformed(address indexed transferredBy, uint256 length, uint256 totalAmount);

   
   
   
  function sumOf(uint256[] memory values) private pure returns(uint256) {
    uint256 total = 0;

    for (uint256 i = 0; i < values.length; i++) {
      total = total.add(values[i]);
    }

    return total;
  }


   
   
   
   
   
  function bulkTransfer(address token, address[] calldata destinations, uint256[] calldata amounts)
  external onlyAdmin whenNotPaused
  returns(bool) {
    require(destinations.length == amounts.length, "Invalid operation.");

     
     
    uint256 requiredBalance = sumOf(amounts);

     
    require(checkIfValidTransfer(requiredBalance), "Access is denied.");

    ERC20 erc20 = ERC20(token);

    require
    (
      erc20.balanceOf(address(this)) >= requiredBalance,
      "You don't have sufficient funds to transfer amount this big."
    );


    for (uint256 i = 0; i < destinations.length; i++) {
      erc20.safeTransfer(destinations[i], amounts[i]);
    }

    emit BulkTransferPerformed(token, msg.sender, destinations.length, requiredBalance);
    return true;
  }


   
   
   
   
  function bulkTransferEther(address[] calldata destinations, uint256[] calldata amounts)
  external onlyAdmin whenNotPaused
  returns(bool) {
    require(destinations.length == amounts.length, "Invalid operation.");

     
     
    uint256 requiredBalance = sumOf(amounts);

     
    require(checkIfValidWeiTransfer(requiredBalance), "Access is denied.");

    require
    (
      address(this).balance >= requiredBalance,
      "You don't have sufficient funds to transfer amount this big."
    );


    for (uint256 i = 0; i < destinations.length; i++) {
      address payable beneficiary = address(uint160(destinations[i]));
      beneficiary.transfer(amounts[i]);
    }


    emit EtherBulkTransferPerformed(msg.sender, destinations.length, requiredBalance);
    return true;
  }
}
 








 
 
 
 
 
contract Reclaimable is CustomPausable {
  using SafeERC20 for ERC20;

   
  function reclaimEther() external whenNotPaused onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

   
   
  function reclaimToken(address token) external whenNotPaused onlyOwner {
    ERC20 erc20 = ERC20(token);
    uint256 balance = erc20.balanceOf(address(this));
    erc20.safeTransfer(msg.sender, balance);
  }
}

contract CYBRSharedWallet is BulkTransfer, Reclaimable {
}