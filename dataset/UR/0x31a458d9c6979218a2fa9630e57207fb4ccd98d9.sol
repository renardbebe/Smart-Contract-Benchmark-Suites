 

pragma solidity ^0.5.11;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


 
library Math {
     
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

     
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


 
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


contract DepositorRole {
  using Roles for Roles.Role;

  event DepositorAdded(address indexed account);
  event DepositorRemoved(address indexed account);

  Roles.Role private depositors;

  constructor() internal {
    _addDepositor(msg.sender);
  }

  modifier onlyDepositor() {
    require(isDepositor(msg.sender));
    _;
  }

  function isDepositor(address account) public view returns (bool) {
    return depositors.has(account);
  }

  function addDepositor(address account) public onlyDepositor {
    _addDepositor(account);
  }

  function renounceDepositor() public {
    _removeDepositor(msg.sender);
  }

  function _addDepositor(address account) internal {
    depositors.add(account);
    emit DepositorAdded(account);
  }

  function _removeDepositor(address account) internal {
    depositors.remove(account);
    emit DepositorRemoved(account);
  }
}


contract TraderRole {
  using Roles for Roles.Role;

  event TraderAdded(address indexed account);
  event TraderRemoved(address indexed account);

  Roles.Role private traders;

  constructor() internal {
    _addTrader(msg.sender);
  }

  modifier onlyTrader() {
    require(isTrader(msg.sender));
    _;
  }

  function isTrader(address account) public view returns (bool) {
    return traders.has(account);
  }

  function addTrader(address account) public onlyTrader {
    _addTrader(account);
  }

  function renounceTrader() public {
    _removeTrader(msg.sender);
  }

  function _addTrader(address account) internal {
    traders.add(account);
    emit TraderAdded(account);
  }

  function _removeTrader(address account) internal {
    traders.remove(account);
    emit TraderRemoved(account);
  }
}


 
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
        require(isOwner());
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


 
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}


 
contract TokenBank is Ownable, DepositorRole, TraderRole {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

     
    IERC20 public bindedToken;

     
    mapping(address => uint256) public deposited;

     
    address public feeCollector;
   
    event TokenBinded(
        address indexed binder,
        address indexed previousToken,
        address indexed newToken
    );

    event FeeCollectorSet(
        address indexed setter,
        address indexed previousFeeCollector,
        address indexed newFeeCollector
    );

    event FeeCollected(
        address indexed collector,
        address indexed collectTo,
        uint256 amount
    );

    event Deposited(
        address indexed depositor,
        address indexed receiver,
        uint256 amount,
        uint256 balance
    );

    event BulkDeposited(
        address indexed trader,
        uint256 totalAmount,
        uint256 requestNum
    );

    event Withdrawn(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 fee,
        uint256 balance
    );

    event BulkWithdrawn(
        address indexed trader,
        uint256 requestNum
    );

    event Transferred(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 fee,
        uint256 balance
    );

    event BulkTransferred(
        address indexed trader,
        uint256 requestNum
    );

     
    constructor(
        address[] memory addrs
    )
        public
    {
        bindedToken = IERC20(addrs[0]);
        feeCollector = addrs[1];
    }

     
    function bindToken(address token) external onlyOwner {
        emit TokenBinded(msg.sender, address(bindedToken), token);
        bindedToken = IERC20(token);
    }

     
    function setFeeCollector(address collector) external onlyOwner {
        emit FeeCollectorSet(msg.sender, feeCollector, collector);
        feeCollector = collector;
    }

     
    function collectFee() external onlyOwner {
        uint256 amount = deposited[feeCollector];
        deposited[feeCollector] = 0;
        emit FeeCollected(msg.sender, feeCollector, amount);
        bindedToken.safeTransfer(feeCollector, amount);
    }

     
    function depositTo(address receiver, uint256 amount) external onlyDepositor {
        deposited[receiver] = deposited[receiver].add(amount);
        emit Deposited(msg.sender, receiver, amount, deposited[receiver]);
        bindedToken.safeTransferFrom(msg.sender, address(this), amount);
    }

     
    function bulkDeposit(
        address[] calldata receivers,
        uint256[] calldata amounts
    )
        external
        onlyDepositor
    {
        require(
            receivers.length == amounts.length,
            "Failed to bulk deposit due to illegal arguments."
        );

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i = i.add(1)) {
             
            totalAmount = totalAmount.add(amounts[i]);
             
            deposited[receivers[i]] = deposited[receivers[i]].add(amounts[i]);
            emit Deposited(
                msg.sender, 
                receivers[i], 
                amounts[i],
                deposited[receivers[i]]
            );
        }
        emit BulkDeposited(msg.sender, totalAmount, receivers.length);

         
        bindedToken.safeTransferFrom(msg.sender, address(this), totalAmount);  
    }

     
    function _withdraw(address from, address to, uint256 amount, uint256 fee) private {
        deposited[feeCollector] = deposited[feeCollector].add(fee);
        uint256 total = amount.add(fee);
        deposited[from] = deposited[from].sub(total);
        emit Withdrawn(from, to, amount, fee, deposited[from]);
        bindedToken.safeTransfer(to, amount);
    }

     
    function bulkWithdraw(
        uint256[] calldata nums,
        address[] calldata addrs,
        bytes32[] calldata rsSigParams
    )
        external
        onlyTrader
    {
         
        uint256 total = nums.length.div(4);
        require(
            (total > 0) 
            && (total.mul(4) == nums.length)
            && (total.mul(2) == addrs.length)
            && (total.mul(2) == rsSigParams.length),
            "Failed to bulk withdraw due to illegal arguments."
        );

         
        for (uint256 i = 0; i < total; i = i.add(1)) {
            _verifyWithdrawSigner(
                addrs[i.mul(2)],                
                addrs[(i.mul(2)).add(1)],       
                nums[i.mul(4)],                 
                nums[(i.mul(4)).add(1)],        
                nums[(i.mul(4)).add(2)],        
                nums[(i.mul(4)).add(3)],        
                rsSigParams[i.mul(2)],          
                rsSigParams[(i.mul(2)).add(1)]  
            );

            _withdraw(
                addrs[i.mul(2)],           
                addrs[(i.mul(2)).add(1)],  
                nums[i.mul(4)],            
                nums[(i.mul(4)).add(1)]    
            );
        }
        emit BulkWithdrawn(msg.sender, total);
    }

     
    function _verifyWithdrawSigner(
        address from,
        address to,
        uint256 amount,
        uint256 fee,
        uint256 timestamp,
        uint256 v,
        bytes32 r,
        bytes32 s
    )
        private
        view
    {
        bytes32 hashed = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", 
                keccak256(
                    abi.encodePacked(
                        address(this), 
                        from, 
                        to, 
                        amount,
                        fee,
                        timestamp
                    )
                )
            )
        );

        require(
            ecrecover(hashed, uint8(v), r, s) == from,
            "Failed to withdraw due to request was not signed by singer."
        );
    }

     
    function bulkTransfer(
        uint256[] calldata nums,
        address[] calldata addrs,
        bytes32[] calldata rsSigParams
    )
        external
        onlyTrader
    {
         
        uint256 total = nums.length.div(4);
        require(
            (total > 0) 
            && (total.mul(4) == nums.length)
            && (total.mul(2) == addrs.length)
            && (total.mul(2) == rsSigParams.length),
            "Failed to bulk transfer due to illegal arguments."
        );

         
        for (uint256 i = 0; i < total; i = i.add(1)) {
            _verifyTransferSigner(
                addrs[i.mul(2)],                
                addrs[(i.mul(2)).add(1)],       
                nums[i.mul(4)],                 
                nums[(i.mul(4)).add(1)],        
                nums[(i.mul(4)).add(2)],        
                nums[(i.mul(4)).add(3)],        
                rsSigParams[i.mul(2)],          
                rsSigParams[(i.mul(2)).add(1)]  
            );

            _transfer(
                addrs[i.mul(2)],           
                addrs[(i.mul(2)).add(1)],  
                nums[i.mul(4)],            
                nums[(i.mul(4)).add(1)]    
            );
        }
        emit BulkTransferred(msg.sender, total);
    }

     
    function transfer(
        address from,
        address to,
        uint256 amount,
        uint256 fee
    )
        external
        onlyOwner
    {
        _transfer(from, to, amount, fee);
    }

     
    function _transfer(
        address from,
        address to,
        uint256 amount,
        uint256 fee
    )
        private
    {
        require(to != address(0));
        uint256 total = amount.add(fee);
        require(total <= deposited[from]);
        deposited[from] = deposited[from].sub(total);
        deposited[feeCollector] = deposited[feeCollector].add(fee);
        deposited[to] = deposited[to].add(amount);
        emit Transferred(from, to, amount, fee, deposited[from]);
    }

     
    function _verifyTransferSigner(
        address from,
        address to,
        uint256 amount,
        uint256 fee,
        uint256 timestamp,
        uint256 v,
        bytes32 r,
        bytes32 s
    )
        private
        view
    {
        bytes32 hashed = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", 
                keccak256(
                    abi.encodePacked(
                        address(this), 
                        from, 
                        to, 
                        amount,
                        fee,
                        timestamp
                    )
                )
            )
        );

        require(
            ecrecover(hashed, uint8(v), r, s) == from,
            "Failed to transfer due to request was not signed by singer."
        );
    }
}