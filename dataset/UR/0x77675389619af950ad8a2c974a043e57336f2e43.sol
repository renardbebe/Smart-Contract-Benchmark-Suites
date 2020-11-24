 

pragma solidity ^0.5.8;


 
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

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}


contract IssuerRole {
    using Roles for Roles.Role;

    event IssuerAdded(address indexed account);
    event IssuerRemoved(address indexed account);

    Roles.Role private _issuers;

    constructor () internal {
        _addIssuer(msg.sender);
    }

    modifier onlyIssuer() {
        require(isIssuer(msg.sender));
        _;
    }

    function isIssuer(address account) public view returns (bool) {
        return _issuers.has(account);
    }

    function addIssuer(address account) public onlyIssuer {
        _addIssuer(account);
    }

    function renounceIssuer() public {
        _removeIssuer(msg.sender);
    }

    function _addIssuer(address account) internal {
        _issuers.add(account);
        emit IssuerAdded(account);
    }

    function _removeIssuer(address account) internal {
        _issuers.remove(account);
        emit IssuerRemoved(account);
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


 
interface IUnsafeERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external;

  function approve(address spender, uint256 value) external;

  function transferFrom(address from, address to, uint256 value) external;
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


 
contract TokenBank is IssuerRole, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

     
    IERC20 public bindedToken;

     
    mapping(address => uint256) public deposited;

    event Deposited(
        address indexed depositor,
        address indexed receiver,
        uint256 amount,
        uint256 balance
    );

    event Withdrawn(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 balance
    );

    event InterestIssued(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount
    );

     
    constructor(address token) public {
        bindedToken = IERC20(token);
    }

     
    function depositTo(address receiver, uint256 amount) external {
        deposited[receiver] = deposited[receiver].add(amount);
        emit Deposited(msg.sender, receiver, amount, deposited[receiver]);
        bindedToken.safeTransferFrom(msg.sender, address(this), amount);
    }

     
    function withdrawTo(address to, uint256 amount) external {
        deposited[msg.sender] = deposited[msg.sender].sub(amount);
        emit Withdrawn(msg.sender, to, amount, deposited[msg.sender]);
        bindedToken.safeTransfer(to, amount);
    }

     
    function bulkIssueInterests(
        bool safe,
        address paidToken,
        address fromWallet,
        uint256[] calldata interests,
        address[] calldata receivers
    )
        external
        onlyIssuer
    {
        require(
            interests.length == receivers.length,
            "Failed to bulk issue interests due to illegal arguments."
        );

        if (safe) {
            IERC20 token = IERC20(paidToken);
             
            for (uint256 i = 0; i < receivers.length; i = i.add(1)) {
                emit InterestIssued(
                    paidToken,
                    fromWallet,
                    receivers[i],
                    interests[i]
                );
                token.safeTransferFrom(fromWallet, receivers[i], interests[i]);
            }
        } else {
            IUnsafeERC20 token = IUnsafeERC20(paidToken);
             
            for (uint256 i = 0; i < receivers.length; i = i.add(1)) {
                emit InterestIssued(
                    paidToken,
                    fromWallet,
                    receivers[i],
                    interests[i]
                );
                token.transferFrom(fromWallet, receivers[i], interests[i]);
            }
        }
    }
}