 

 

 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 

pragma solidity ^0.5.0;




 
contract ERC20 is Context, IERC20 {
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
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

     
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

     
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

 

pragma solidity ^0.5.5;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

         
         
         
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
         
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

     
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

     
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

         
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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




library UniversalERC20 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(IERC20 token, address to, uint256 amount) internal {
        universalTransfer(token, to, amount, false);
    }

    function universalTransfer(IERC20 token, address to, uint256 amount, bool mayFail) internal returns(bool) {
        if (amount == 0) {
            return true;
        }

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            if (mayFail) {
                return address(uint160(to)).send(amount);
            } else {
                address(uint160(to)).transfer(amount);
                return true;
            }
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalApprove(IERC20 token, address to, uint256 amount) internal {
        if (token != ZERO_ADDRESS && token != ETH_ADDRESS) {
            token.safeApprove(to, amount);
        }
    }

    function universalTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            require(from == msg.sender && msg.value >= amount, "msg.value is zero");
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }
}

 

pragma solidity ^0.5.0;


interface IMultiTokenArbitraryCallReceiver {

    function handleFlashLoan(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external payable;
}

 

pragma solidity ^0.5.0;






contract MultiToken is ERC20, ERC20Detailed {

    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    IERC20[] public tokens;
    mapping(address => bool) public isSubToken;

    uint256 flashLoanIndex;

    bool public initialized = false;
    bool public isShutdown = false;
    address public feeReceiver;
    address public owner;

    event Initialized(
        uint256 indexed mintAmount,
        uint256[] tokenAmounts
    );

    event Swapped(
        address indexed fromToken,
        address indexed toToken,
        address indexed who,
        uint256 amount,
        uint256 returnAmount
    );

    event FlashLoaned(
        uint256 indexed index,
        address indexed to,
        address indexed target
    );

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        IERC20[] memory _tokens,
        address _owner,
        address _feeReceiver
    )
    public ERC20Detailed(name, symbol, decimals)
    {

        require(bytes(name).length > 0, "constructor: name should not be empty");
        require(bytes(symbol).length > 0, "constructor: symbol should not be empty");
        require(_tokens.length >= 2, "Contract does not support less than 2 inner tokens");

        tokens = _tokens;
        owner = _owner;
        feeReceiver = _feeReceiver;

        for (uint i = 0; i < tokens.length; i++) {

            isSubToken[address(tokens[i])] = true;

            for (uint j = 0; j < i; j++) {

                require(tokens[i] != tokens[j], "Only unique tokens are allowed");
            }
        }
    }

    function setFeeReceiver(address _feeReceiver) public {

        require(msg.sender == owner, "Only owner is allowed");
        feeReceiver = _feeReceiver;
    }

    function setOwner(address _owner) public {

        require(msg.sender == owner, "Only owner is allowed");
        owner = _owner;
    }

    function shutdown() public {

        require(msg.sender == owner, "Only owner is allowed");
        isShutdown = true;
    }

    function init(
        uint256 mintAmount,
        uint256[] memory tokenAmounts
    ) public payable {

        require(isShutdown == false, "Contract is shutdown");
        require(initialized == false, "Already initialized");

        for (uint256 i = 0; i < tokens.length; i++) {

            require(tokenAmounts[i] != 0, "Token amount should be non-zero");

            tokens[i].universalTransferFrom(
                msg.sender,
                address(this),
                tokenAmounts[i]
            );
        }

        _mint(msg.sender, mintAmount);

        initialized = true;

        emit Initialized(
            mintAmount,
            tokenAmounts
        );
    }

    function tokensLength() public view returns (uint256) {

        return tokens.length;
    }

    function getSubTokens() public view returns (IERC20[] memory) {

        return tokens;
    }

    function mint(uint256 amount) public payable returns (bool) {

        require(amount < 1e27, "Max mint amount is 1e27");
        require(initialized == true, "Is not yet initialized");

        for (uint256 i = 0; i < tokens.length; i++) {

            tokens[i].universalTransferFrom(
                msg.sender,
                address(this),
                tokens[i].universalBalanceOf(address(this)).mul(amount).div(totalSupply())
            );
        }

        _mint(msg.sender, amount);

        return true;
    }

    function getTokenValues(uint256 amount) view public returns (uint256[] memory values) {

        values = new uint[](tokens.length);

        for (uint i = 0; i < tokens.length; i++) {

            values[i] = tokens[i].universalBalanceOf(address(this)).mul(amount).div(totalSupply());
        }
    }

    function burn(uint256 amount) public {

        for (uint i = 0; i < tokens.length; i++) {

            tokens[i].universalTransfer(
                msg.sender,
                tokens[i].universalBalanceOf(address(this)).mul(amount).div(totalSupply())
            );
        }

        _burn(msg.sender, amount);

        if (
            totalSupply() == 0 &&
            !isShutdown
        ) {

            initialized = false;
        }
    }

    function getReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) public view returns (uint256 returnAmount) {

        require(isSubToken[address(fromToken)], "From token is not a sub token");
        require(isSubToken[address(toToken)], "To token is not a sub token");

        uint256 inputAmountWithFee = amount.mul(990);
         
        uint256 numerator = inputAmountWithFee.mul(toToken.universalBalanceOf(address(this)));
        uint256 denominator = fromToken.universalBalanceOf(address(this)).mul(1000).add(inputAmountWithFee);

        return numerator.div(denominator);
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn
    ) public returns (uint256 returnAmount) {

        return swap(
            fromToken,
            toToken,
            amount,
            minReturn,
            address(0x0)
        );
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        address referrer
    ) public returns (uint256 returnAmount) {

        returnAmount = getReturn(fromToken, toToken, amount);
        require(isShutdown == false, "Contract is shutdown");
        require(initialized == true, "Is not yet initialized");
        require(returnAmount > 0, "The return amount is zero");
        require(returnAmount >= minReturn, "The return amount is less than minReturn value");

        fromToken.universalTransferFrom(msg.sender, address(this), amount);
        toToken.universalTransfer(msg.sender, returnAmount);

        uint256 fee;

        if (referrer != address(0x0)) {

            fee = amount.mul(5).div(1000).div(2);
            fromToken.universalTransfer(referrer, fee, true);
        } else {

            fee = amount.mul(5).div(1000);
        }

        if (feeReceiver != address(this)) {

            fromToken.universalTransfer(feeReceiver, fee, true);
        }

        emit Swapped(
            address(fromToken),
            address(toToken),
            msg.sender,
            amount,
            returnAmount
        );
    }

    function flashLoan(
        IERC20[] memory loanTokens,
        uint256[] memory amounts,
        address target,
        bytes memory data
    ) public {

        require(initialized == true, "Is not yet initialized");
        require(isShutdown == false, "Contract is shutdown");

        flashLoanIndex++;

        uint256 lastFlashLoanIndex = flashLoanIndex;

         
        uint256[] memory prevAmounts = new uint[](loanTokens.length);
        uint256[] memory fees = new uint[](loanTokens.length);

        for (uint i = 0; i < loanTokens.length; i++) {

            prevAmounts[i] = loanTokens[i].universalBalanceOf(address(this));
            fees[i] = amounts[i].mul(1).div(100000);

            require(loanTokens[i].universalTransfer(target, amounts[i], true));
        }

         
        IMultiTokenArbitraryCallReceiver(target).handleFlashLoan(
            loanTokens,
            amounts,
            fees,
            data
        );

         
        for (uint i = 0; i < loanTokens.length; i++) {

            require(loanTokens[i].universalBalanceOf(address(this)) >= prevAmounts[i].add(fees[i]));

            if (feeReceiver != address(this)) {

                require(loanTokens[i].universalTransfer(feeReceiver, fees[i].div(2), true));
                 
            }
        }

        require(lastFlashLoanIndex == flashLoanIndex, "Reentrancy is not allowed");

        emit FlashLoaned(
            flashLoanIndex,
            msg.sender,
            target
        );
    }
}

 

pragma solidity ^0.5.0;


contract MultiSwap {

    event MultiTokenCreated(
        address indexed creator,
        uint256 indexed id,
        address indexed multiTokenAddress
    );

    address public owner;
    address public feeReceiver;
    MultiToken[] public multiTokens;

    constructor(
        address _owner,
        address _feeReceiver
    ) public {

        owner = _owner;
        feeReceiver = _feeReceiver;
    }

    function setFeeReceiver(address _feeReceiver) public {

        require(msg.sender == owner, "Only owner is allowed");
        feeReceiver = _feeReceiver;
    }

    function setOwner(address _owner) public {

        require(msg.sender == owner, "Only owner is allowed");
        owner = _owner;
    }

    function multiTokensLength() public view returns (uint256) {

        return multiTokens.length;
    }

    function deployMultiToken(
        string memory name,
        string memory symbol,
        uint8 decimals,
        IERC20[] memory tokens
    ) public {

        multiTokens.push(
            new MultiToken(
                name,
                symbol,
                decimals,
                tokens,
                owner,
                feeReceiver
            )
        );

        emit MultiTokenCreated(
            msg.sender,
            multiTokens.length - 1,
            address(multiTokens[multiTokens.length - 1])
        );
    }

    function findByToken(IERC20 token) public view returns (address[] memory result) {

        uint256 counter = 0;
        address[] memory tempResult = new address[](multiTokens.length);

        for (uint256 i = 0; i < multiTokens.length; i++) {

            if (multiTokens[i].isSubToken(address(token))) {

                counter++;
                tempResult[i] = address(multiTokens[i]);
            }
        }

        result = new address[](counter);

        for (uint256 i = 0; i < tempResult.length; i++) {

            if (tempResult[i] != address(0)) {

                result[--counter] = address(tempResult[i]);
            }
        }
    }

    function findByTokenPair(
        IERC20 fromToken,
        IERC20 toToken
    ) public view returns (address[] memory result) {

        uint256 counter = 0;
        address[] memory tempResult = new address[](multiTokens.length);

        for (uint256 i = 0; i < multiTokens.length; i++) {

            if (
                multiTokens[i].isSubToken(address(fromToken)) &&
                multiTokens[i].isSubToken(address(toToken))
            ) {

                counter++;
                tempResult[i] = address(multiTokens[i]);
            }
        }

        result = new address[](counter);

        for (uint256 i = 0; i < tempResult.length; i++) {

            if (tempResult[i] != address(0)) {

                result[--counter] = address(tempResult[i]);
            }
        }
    }
}