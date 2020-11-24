 

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

pragma solidity ^0.5.0;




 
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

 

pragma solidity ^0.5.0;

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

 

pragma solidity 0.5.11;

interface IERC20MintableBurnable {
    function mint(address account, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

 

pragma solidity 0.5.11;

interface IExchange {
    event Deposited(address payee, uint256 amount);
    event Withdrawn(address payee, uint256 amount);

    function deposit(uint256 _amount) external returns (bool);
    function depositFrom(address _source, address _destination, uint256 _amount)
        external
        returns (bool);
    function withdraw(uint256 _amount) external returns (bool);
    function withdrawFrom(address _source, address _destination, uint256 _amount)
        external
        returns (bool);
    function token() external view returns (address);
    function wrappedToken() external view returns (address);
    function supply() external view returns (uint256);
}

 

pragma solidity 0.5.11;







 
contract WrappedERC20Exchange is IExchange, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Deposited(address payee, uint amount);
    event Withdrawn(address payee, uint amount);

    IERC20 public token;
    IERC20MintableBurnable public wrappedToken;

    constructor (IERC20 _token, IERC20MintableBurnable _wrappedToken) public {
        token = _token;
        wrappedToken = _wrappedToken;
    }

     
    function deposit(uint _amount) public nonReentrant returns (bool) {
        require(_amount != 0, "Amount cannot be zero.");
        emit Deposited(msg.sender, _amount);

         
        token.safeTransferFrom(msg.sender, address(this), _amount);

         
        wrappedToken.mint(msg.sender, _amount);

        return true;
    }

     
    function depositFrom(address _source, address _destination, uint _amount) public nonReentrant returns (bool) {
        require(_amount != 0, "Amount cannot be zero.");
        require(_source != address(0), "Source address cannot be a zero address.");
        require(_destination != address(0), "Destination address cannot be a zero address.");

        emit Deposited(_source, _amount);

         
        token.safeTransferFrom(_source, address(this), _amount);

         
        wrappedToken.mint(_destination, _amount);

        return true;
    }

     
    function withdraw(uint _amount) public nonReentrant returns (bool) {
        require(_amount != 0, "Amount cannot be zero.");
        emit Withdrawn(msg.sender, _amount);

         
        wrappedToken.burnFrom(msg.sender, _amount);

         
        token.safeTransfer(msg.sender, _amount);

        return true;
    }

     
    function withdrawFrom(address _source, address _destination, uint _amount) public nonReentrant returns (bool) {
        require(_amount != 0, "Amount cannot be zero.");
        require(_source != address(0), "Source address cannot be a zero address.");
        require(_destination != address(0), "Destination address cannot be a zero address.");

        emit Withdrawn(_source, _amount);

         
        wrappedToken.burnFrom(_source, _amount);

         
        token.safeTransfer(_destination, _amount);

        return true;
    }

     
    function supply() public view returns (uint) {
        return token.balanceOf(address(this));
    }
}