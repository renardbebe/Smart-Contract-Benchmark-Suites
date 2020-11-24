 

pragma solidity 0.5.10;

 
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

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
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

interface IGST2 {

    function freeUpTo(uint256 value) external returns (uint256 freed);

    function balanceOf(address who) external view returns (uint256);
}

 
contract AugustusSwapper is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

     
    address constant private ETH_ADDRESS = address(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );

     
     
    mapping(address => bool) private _whitelisteds;

     
    uint256 private _fee;

    address payable private _feeWallet;

    IGST2 private _gasToken;

    event WhitelistAdded(address indexed account);
    event WhitelistRemoved(address indexed account);
    event Swapped(
        address indexed user,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount
    );

    modifier onlySelf() {
        require(
            msg.sender == address(this),
            "AugustusSwapper: Invalid access!!"
        );
        _;
    }

     
    constructor(address payable feeWallet, address gasToken) public {
        require(feeWallet != address(0), "Invalid address!!");
        require(gasToken != address(0), "Invalid gas token!!");

        _feeWallet = feeWallet;
        _gasToken = IGST2(gasToken);

        _whitelisteds[address(this)] = true;
        emit WhitelistAdded(address(this));
    }

     
    function() external payable {
        address account = msg.sender;
        require(
            account.isContract(),
            "Sender is not a contract!!"
        );
    }

     
    function changeFeeWallet(address payable feeWallet) external onlyOwner {
        _feeWallet = feeWallet;
    }

     
    function getFeeWallet() external view returns(address) {
        return _feeWallet;
    }

     
    function changeFee(uint256 fee) external onlyOwner {
        _fee = fee;
    }

     
    function getFee() external view returns(uint256) {
        return _fee;
    }

     
    function addWhitelisted (address account) external onlyOwner {
        _whitelisteds[account] = true;
        emit WhitelistAdded(account);
    }

     
    function removeWhitelistes(address account) external onlyOwner {
        _whitelisteds[account] = false;
        emit WhitelistRemoved(account);
    }

     
    function addWhitelistedBulk(
        address[] calldata accounts
    )
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelisteds[accounts[i]] = true;
            emit WhitelistAdded(accounts[i]);
        }
    }

     
    function approve(
        address token,
        address to,
        uint256 amount
    )
        external
        onlySelf
    {
        require(amount > 0, "Amount should be greater then 0!!");
         
        require(
            isWhitelisted(to),
            "AugustusSwapper: Not a whitelisted address!!"
        );

         
        if (token != ETH_ADDRESS){
             
            IERC20 _token = IERC20(token);
            _token.safeApprove(to, amount);
        }

    }

     
    function performSwap(
        address sourceToken,
        address destinationToken,
        uint256 sourceAmount,
        uint256 minDestinationAmount,
        address[] memory callees,
        bytes memory exchangeData,
        uint256[] memory startIndexes,
        uint256[] memory values,
        uint256 mintPrice
    )
        public
        payable
        nonReentrant
    {
         
        require(callees.length > 0, "No callee provided!!");
        require(
            callees.length + 1 == startIndexes.length,
            "Start indexes must be 1 greater then number of callees!!"
        );
        require(sourceToken != address(0), "Invalid source token!!");
        require(destinationToken != address(0), "Inavlid destination address");

        uint initialGas = gasleft();

         
         
        if (sourceToken != ETH_ADDRESS){
            IERC20(sourceToken).safeTransferFrom(msg.sender, address(this), sourceAmount);
        }

        for (uint256 i = 0; i < callees.length; i++) {

            require(isWhitelisted(callees[i]), "Callee is not whitelisted!!");

            bool result = externalCall(
                callees[i], 
                values[i], 
                startIndexes[i], 
                startIndexes[i+1].sub(startIndexes[i]), 
                exchangeData 
            );
            require(result, "External call failed!!");
        }
        uint256 receivedAmount = tokenBalance(destinationToken, address(this));

        require(
            receivedAmount >= minDestinationAmount,
            "Received amount of tokens are less then expected!!"
        );

        uint256 fee = calculateFee(
            sourceToken,
            receivedAmount,
            callees.length
        );

        if (fee > 0) {
            receivedAmount = receivedAmount.sub(fee);
            transferTokens(destinationToken, _feeWallet, fee);
        }

        transferTokens(destinationToken, msg.sender, receivedAmount);

        emit Swapped(
            msg.sender,
            sourceToken,
            destinationToken,
            sourceAmount,
            receivedAmount
        );

        if (mintPrice > 0){
            refundGas(initialGas, mintPrice);
        }
    }

     
    function isWhitelisted(address account) public view returns(bool) {
        return _whitelisteds[account];
    }

     
    function refundGas(uint256 initialGas, uint256 mintPrice) private {

        uint256 mintBase = 32254;
        uint256 mintToken = 36543;
        uint256 freeBase = 14154;
        uint256 freeToken = 6870;
        uint256 reimburse = 24000;

        uint256 tokens = initialGas.sub(
            gasleft()).add(freeBase).div(reimburse.mul(2).sub(freeToken)
        );

        uint256 mintCost = mintBase.add(tokens.mul(mintToken));
        uint256 freeCost = freeBase.add(tokens.mul(freeToken));
        uint256 maxreimburse = tokens.mul(reimburse);

        uint256 efficiency = maxreimburse.mul(tx.gasprice).mul(100).div(
            mintCost.mul(mintPrice).add(freeCost.mul(tx.gasprice))
        );

        if (efficiency > 100) {
            freeGasTokens(tokens);
        }
    }

     
    function freeGasTokens(uint256 tokens) private {

        uint256 tokensToFree = tokens;
        uint256 safeNumTokens = 0;
        uint256 gas = gasleft();

        if (gas >= 27710) {
            safeNumTokens = gas.sub(27710).div(1148 + 5722 + 150);
		}

        if (tokensToFree > safeNumTokens) {
            tokensToFree = safeNumTokens;
		}

        uint256 gasTokenBal = _gasToken.balanceOf(address(this));

        if (tokensToFree > 0 && gasTokenBal >= tokensToFree) {
            _gasToken.freeUpTo(tokensToFree);
		}

    }

     
    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    )
        private
    {
        if (token == ETH_ADDRESS) {
            destination.transfer(amount);
        }
        else{
            IERC20(token).safeTransfer(destination, amount);
        }
    }

     
    function calculateFee(
        address sourceToken,
        uint256 receivedAmount,
        uint256 calleesLength
    )
        private
        view
        returns(uint256)
    {
        uint256 fee = 0;
        if (sourceToken == ETH_ADDRESS && calleesLength == 1){
            return 0;
        }

        else if (sourceToken != ETH_ADDRESS && calleesLength == 2){
            return 0;
        }

        if (_fee > 0) {
            fee = receivedAmount.mul(_fee).div(10000);
        }
        return fee;
    }

     
    function externalCall(
        address destination,
        uint256 value,
        uint256 dataOffset,
        uint dataLength,
        bytes memory data
    )
        private
        returns (bool)
    {
        bool result = false;
        assembly {
            let x := mload(0x40)    

            let d := add(data, 32)  
            result := call(
                sub(gas, 34710),    
                                    
                                    
                destination,
                value,
                add(d, dataOffset),
                dataLength,         
                x,
                0                   
            )
        }
        return result;
    }

     
    function tokenBalance(
        address token,
        address account
    )
        private
        view
        returns(uint256)
    {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }
}