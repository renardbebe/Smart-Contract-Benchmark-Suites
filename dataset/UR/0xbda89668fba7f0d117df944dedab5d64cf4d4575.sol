 

pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;



 
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


contract Callable {
     
     
     
    function external_call(address destination, uint value, uint dataOffset, uint dataLength, bytes memory data) internal returns (bool) {
        bool result;
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
}

contract IWETH is IERC20 {
    function withdraw(uint256 amount) external;
}

contract ApprovalHandler is Ownable {

    using SafeERC20 for IERC20;

    function transferFrom(IERC20 erc, address sender, address receiver, uint256 numTokens) external onlyOwner {
        erc.safeTransferFrom(sender, receiver, numTokens);
    }
}

contract DexTradingWithCollection is Ownable, Callable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ApprovalHandler public approvalHandler;

    event Trade(address indexed from, address indexed to, uint256 toAmount, address indexed trader, address[] exchanges, uint256 tradeType);
    event BasisPointsSet(uint256 indexed newBasisPoints);
    event BeneficiarySet(address indexed newBeneficiary);
    event DexagSet(address indexed newDexag);

    IWETH public WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address payable beneficiary;
    address payable dexag;
    uint256 public basisPoints;

    constructor(address payable _beneficiary, address payable _dexag, uint256 _basisPoints) public {
        approvalHandler = new ApprovalHandler();
        beneficiary = _beneficiary;
        dexag = _dexag;
        basisPoints = _basisPoints;
    }

    function trade(
        IERC20 from,
        IERC20 to,
        uint256 fromAmount,
        address[] memory exchanges,
        address[] memory approvals,
        bytes memory data,
        uint256[] memory offsets,
        uint256[] memory etherValues,
        uint256 limitAmount,
        uint256 tradeType
    ) public payable {
        require(exchanges.length > 0, 'No Exchanges');

         
        if (address(from) != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            approvalHandler.transferFrom(from, msg.sender, address(this), fromAmount);
        }

         
        executeTrades(from, exchanges, approvals, data, offsets, etherValues);

         
        uint256 tradeReturn = viewBalance(to, address(this));
        require(tradeReturn >= limitAmount, 'Trade returned less than the minimum amount');

         
        uint256 leftover = viewBalance(from, address(this));
        if (leftover > 0) {
            sendFunds(from, msg.sender, leftover);
        }

        sendCollectionAmount(to, tradeReturn);
        sendFunds(to, msg.sender, viewBalance(to, address(this)));

        emit Trade(address(from), address(to), tradeReturn, msg.sender, exchanges, tradeType);
    }

    function executeTrades(
        IERC20 from,
        address[] memory exchanges,
        address[] memory approvals,
        bytes memory data,
        uint256[] memory offsets,
        uint256[] memory etherValues) internal {
            for (uint i = 0; i < exchanges.length; i++) {
                 
                require(exchanges[i] != address(approvalHandler) && isContract(exchanges[i]), 'Invalid Address');
                if (approvals[i] != address(0)) {
                     
                    approve(from, approvals[i]);
                } else {
                     
                    approve(from, exchanges[i]);
                }
                 
                require(external_call(exchanges[i], etherValues[i], offsets[i], offsets[i + 1] - offsets[i], data), 'External Call Failed');
            }
        }

     

    function approve(IERC20 erc, address approvee) internal {
        if (
            address(erc) != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE &&
            erc.allowance(address(this), approvee) == 0
        ) {
            erc.safeApprove(approvee, uint256(-1));
        }
    }

    function viewBalance(IERC20 erc, address owner) internal view returns(uint256) {
        if (address(erc) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            return owner.balance;
        } else {
            return erc.balanceOf(owner);
        }
    }

    function sendFunds(IERC20 erc, address payable receiver, uint256 funds) internal {
        if (address(erc) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            receiver.transfer(funds);
        } else {
            erc.safeTransfer(receiver, funds);
        }
    }

     

    function sendCollectionAmount(IERC20 erc, uint256 tradeReturn) internal {
        uint256 collectionAmount = tradeReturn.mul(basisPoints).div(10000);
        uint256 platformFee = collectionAmount.mul(4).div(5).add(collectionAmount.div(50));

        sendFunds(erc, beneficiary, platformFee);
        sendFunds(erc, dexag, collectionAmount.sub(platformFee));
    }

     

    function setbasisPoints(uint256 _basisPoints) external onlyOwner {
        require(_basisPoints >= 1);
        basisPoints = _basisPoints;
        emit BasisPointsSet(basisPoints);
    }

    function setBeneficiary(address payable _beneficiary) external onlyOwner {
        require(_beneficiary != address(0));
        beneficiary = _beneficiary;
        emit BeneficiarySet(_beneficiary);
    }

    function setDexag(address payable _dexag) external {
        require(msg.sender == address(dexag));
        require(_dexag != address(0));
        dexag = _dexag;
        emit DexagSet(dexag);
    }

     
    function isContract(address account) internal view returns (bool) {
         
         
         
        
         
         
         
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
         
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function withdrawWeth() external {
        uint256 amount = WETH.balanceOf(address(this));
        WETH.withdraw(amount);
    }

    function () external payable {
        require(msg.sender != tx.origin);
    }
}