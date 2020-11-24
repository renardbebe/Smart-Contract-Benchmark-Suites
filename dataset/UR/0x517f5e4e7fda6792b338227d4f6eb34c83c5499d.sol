 

pragma solidity ^0.5.0;

interface SwapInterface {
     
    function brokerFees(address _broker) external view returns (uint256);
    function redeemedAt(bytes32 _swapID) external view returns(uint256);

     
     
     
     
     
     
     
    function initiate(
        bytes32 _swapID,
        address payable _spender,
        bytes32 _secretLock,
        uint256 _timelock,
        uint256 _value
    ) external payable;

     
     
     
     
     
     
     
     
     
    function initiateWithFees(
        bytes32 _swapID,
        address payable _spender,
        address payable _broker,
        uint256 _brokerFee,
        bytes32 _secretLock,
        uint256 _timelock,
        uint256 _value
    ) external payable;

     
     
     
     
     
    function redeem(bytes32 _swapID, address payable _receiver, bytes32 _secretKey) external;

     
     
     
     
    function redeemToSpender(bytes32 _swapID, bytes32 _secretKey) external;

     
     
     
    function refund(bytes32 _swapID) external;

     
     
     
    function withdrawBrokerFees(uint256 _amount) external;

     
     
     
    function audit(
        bytes32 _swapID
    ) external view returns (
        uint256 timelock,
        uint256 value,
        address to, uint256 brokerFee,
        address broker,
        address from,
        bytes32 secretLock
    );

     
     
     
    function auditSecret(bytes32 _swapID) external view  returns (bytes32 secretKey);

     
     
     
    function refundable(bytes32 _swapID) external view returns (bool);

     
     
     
    function initiatable(bytes32 _swapID) external view returns (bool);

     
     
     
    function redeemable(bytes32 _swapID) external view returns (bool);

     
     
     
     
    function swapID(bytes32 _secretLock, uint256 _timelock) external pure returns (bytes32);
}

contract BaseSwap is SwapInterface {
    string public VERSION;  

    struct Swap {
        uint256 timelock;
        uint256 value;
        uint256 brokerFee;
        bytes32 secretLock;
        bytes32 secretKey;
        address payable funder;
        address payable spender;
        address payable broker;
    }

    enum States {
        INVALID,
        OPEN,
        CLOSED,
        EXPIRED
    }

     
    event LogOpen(bytes32 _swapID, address _spender, bytes32 _secretLock);
    event LogExpire(bytes32 _swapID);
    event LogClose(bytes32 _swapID, bytes32 _secretKey);

     
    mapping (bytes32 => Swap) internal swaps;
    mapping (bytes32 => States) private _swapStates;
    mapping (address => uint256) private _brokerFees;
    mapping (bytes32 => uint256) private _redeemedAt;

     
    modifier onlyInvalidSwaps(bytes32 _swapID) {
        require(_swapStates[_swapID] == States.INVALID, "swap opened previously");
        _;
    }

     
    modifier onlyOpenSwaps(bytes32 _swapID) {
        require(_swapStates[_swapID] == States.OPEN, "swap not open");
        _;
    }

     
    modifier onlyClosedSwaps(bytes32 _swapID) {
        require(_swapStates[_swapID] == States.CLOSED, "swap not redeemed");
        _;
    }

     
    modifier onlyExpirableSwaps(bytes32 _swapID) {
         
        require(now >= swaps[_swapID].timelock, "swap not expirable");
        _;
    }

     
    modifier onlyWithSecretKey(bytes32 _swapID, bytes32 _secretKey) {
        require(swaps[_swapID].secretLock == sha256(abi.encodePacked(_secretKey)), "invalid secret");
        _;
    }

     
    modifier onlySpender(bytes32 _swapID, address _spender) {
        require(swaps[_swapID].spender == _spender, "unauthorized spender");
        _;
    }

     
     
     
    constructor(string memory _VERSION) public {
        VERSION = _VERSION;
    }

     
     
     
     
     
     
     
    function initiate(
        bytes32 _swapID,
        address payable _spender,
        bytes32 _secretLock,
        uint256 _timelock,
        uint256 _value
    ) public onlyInvalidSwaps(_swapID) payable {
         
        Swap memory swap = Swap({
            timelock: _timelock,
            brokerFee: 0,
            value: _value,
            funder: msg.sender,
            spender: _spender,
            broker: address(0x0),
            secretLock: _secretLock,
            secretKey: 0x0
        });
        swaps[_swapID] = swap;
        _swapStates[_swapID] = States.OPEN;

         
        emit LogOpen(_swapID, _spender, _secretLock);
    }

     
     
     
     
     
     
     
     
     
    function initiateWithFees(
        bytes32 _swapID,
        address payable _spender,
        address payable _broker,
        uint256 _brokerFee,
        bytes32 _secretLock,
        uint256 _timelock,
        uint256 _value
    ) public onlyInvalidSwaps(_swapID) payable {
        require(_value >= _brokerFee, "fee must be less than value");

         
        Swap memory swap = Swap({
            timelock: _timelock,
            brokerFee: _brokerFee,
            value: _value - _brokerFee,
            funder: msg.sender,
            spender: _spender,
            broker: _broker,
            secretLock: _secretLock,
            secretKey: 0x0
        });
        swaps[_swapID] = swap;
        _swapStates[_swapID] = States.OPEN;

         
        emit LogOpen(_swapID, _spender, _secretLock);
    }

     
     
     
     
     
    function redeem(bytes32 _swapID, address payable _receiver, bytes32 _secretKey) public onlyOpenSwaps(_swapID) onlyWithSecretKey(_swapID, _secretKey) onlySpender(_swapID, msg.sender) {
        require(_receiver != address(0x0), "invalid receiver");

         
        swaps[_swapID].secretKey = _secretKey;
        _swapStates[_swapID] = States.CLOSED;
         
        _redeemedAt[_swapID] = now;

         
        _brokerFees[swaps[_swapID].broker] += swaps[_swapID].brokerFee;

         
        emit LogClose(_swapID, _secretKey);
    }

     
     
     
     
    function redeemToSpender(bytes32 _swapID, bytes32 _secretKey) public onlyOpenSwaps(_swapID) onlyWithSecretKey(_swapID, _secretKey) {
         
        swaps[_swapID].secretKey = _secretKey;
        _swapStates[_swapID] = States.CLOSED;
         
        _redeemedAt[_swapID] = now;

         
        _brokerFees[swaps[_swapID].broker] += swaps[_swapID].brokerFee;

         
        emit LogClose(_swapID, _secretKey);
    }

     
     
     
    function refund(bytes32 _swapID) public onlyOpenSwaps(_swapID) onlyExpirableSwaps(_swapID) {
         
        _swapStates[_swapID] = States.EXPIRED;

         
        emit LogExpire(_swapID);
    }

     
     
     
    function withdrawBrokerFees(uint256 _amount) public {
        require(_amount <= _brokerFees[msg.sender], "insufficient withdrawable fees");
        _brokerFees[msg.sender] -= _amount;
    }

     
     
     
    function audit(bytes32 _swapID) external view returns (uint256 timelock, uint256 value, address to, uint256 brokerFee, address broker, address from, bytes32 secretLock) {
        Swap memory swap = swaps[_swapID];
        return (
            swap.timelock,
            swap.value,
            swap.spender,
            swap.brokerFee,
            swap.broker,
            swap.funder,
            swap.secretLock
        );
    }

     
     
     
    function auditSecret(bytes32 _swapID) external view onlyClosedSwaps(_swapID) returns (bytes32 secretKey) {
        return swaps[_swapID].secretKey;
    }

     
     
     
    function refundable(bytes32 _swapID) external view returns (bool) {
         
        return (now >= swaps[_swapID].timelock && _swapStates[_swapID] == States.OPEN);
    }

     
     
     
    function initiatable(bytes32 _swapID) external view returns (bool) {
        return (_swapStates[_swapID] == States.INVALID);
    }

     
     
     
    function redeemable(bytes32 _swapID) external view returns (bool) {
        return (_swapStates[_swapID] == States.OPEN);
    }

    function redeemedAt(bytes32 _swapID) external view returns (uint256) {
        return _redeemedAt[_swapID];
    }

    function brokerFees(address _broker) external view returns (uint256) {
        return _brokerFees[_broker];
    }

     
     
     
     
    function swapID(bytes32 _secretLock, uint256 _timelock) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_secretLock, _timelock));
    }
}

 
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

 
 
 
 
 
 
 
 
 
 
 
 
 
 
library CompatibleERC20Functions {
    using SafeMath for uint256;

     
    function safeTransfer(CompatibleERC20 self, address to, uint256 amount) internal {
        self.transfer(to, amount);
        require(previousReturnValue(), "transfer failed");
    }

     
    function safeTransferFrom(CompatibleERC20 self, address from, address to, uint256 amount) internal {
        self.transferFrom(from, to, amount);
        require(previousReturnValue(), "transferFrom failed");
    }

     
    function safeApprove(CompatibleERC20 self, address spender, uint256 amount) internal {
        self.approve(spender, amount);
        require(previousReturnValue(), "approve failed");
    }

     
     
    function safeTransferFromWithFees(CompatibleERC20 self, address from, address to, uint256 amount) internal returns (uint256) {
        uint256 balancesBefore = self.balanceOf(to);
        self.transferFrom(from, to, amount);
        require(previousReturnValue(), "transferFrom failed");
        uint256 balancesAfter = self.balanceOf(to);
        return Math.min(amount, balancesAfter.sub(balancesBefore));
    }

     
     
     
    function previousReturnValue() private pure returns (bool)
    {
        uint256 returnData = 0;

        assembly {  
             
            switch returndatasize

             
            case 0 {
                returnData := 1
            }

             
            case 32 {
                 
                returndatacopy(0, 0, 32)

                 
                returnData := mload(0)
            }

             
            default { }
        }

        return returnData != 0;
    }
}

 
 
interface CompatibleERC20 {
     
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 value) external;

     
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract ERC20Swap is SwapInterface, BaseSwap {
    using CompatibleERC20Functions for CompatibleERC20;

    address public TOKEN_ADDRESS;  

     
     
     
    constructor(string memory _VERSION, address _TOKEN_ADDRESS) BaseSwap(_VERSION) public {
        TOKEN_ADDRESS = _TOKEN_ADDRESS;
    }

     
     
     
     
     
     
     
    function initiate(
        bytes32 _swapID,
        address payable _spender,
        bytes32 _secretLock,
        uint256 _timelock,
        uint256 _value
    ) public payable {
         
         
        require(msg.value == 0, "eth value must be zero");
        require(_spender != address(0x0), "spender must not be zero");

         
         
         
         
        CompatibleERC20(TOKEN_ADDRESS).safeTransferFrom(msg.sender, address(this), _value);

        BaseSwap.initiate(
            _swapID,
            _spender,
            _secretLock,
            _timelock,
            _value
        );
    }

     
     
     
     
     
     
     
     
     
    function initiateWithFees(
        bytes32 _swapID,
        address payable _spender,
        address payable _broker,
        uint256 _brokerFee,
        bytes32 _secretLock,
        uint256 _timelock,
        uint256 _value
    ) public payable {
         
         
        require(msg.value == 0, "eth value must be zero");
        require(_spender != address(0x0), "spender must not be zero");

         
         
         
         
        CompatibleERC20(TOKEN_ADDRESS).safeTransferFrom(msg.sender, address(this), _value);

        BaseSwap.initiateWithFees(
            _swapID,
            _spender,
            _broker,
            _brokerFee,
            _secretLock,
            _timelock,
            _value
        );
    }

     
     
     
     
    function redeem(bytes32 _swapID, address payable _receiver, bytes32 _secretKey) public {
        BaseSwap.redeem(
            _swapID,
            _receiver,
            _secretKey
        );

         
        CompatibleERC20(TOKEN_ADDRESS).safeTransfer(_receiver, swaps[_swapID].value);
    }

     
     
     
     
    function redeemToSpender(bytes32 _swapID, bytes32 _secretKey) public {
        BaseSwap.redeemToSpender(
            _swapID,
            _secretKey
        );

         
        CompatibleERC20(TOKEN_ADDRESS).safeTransfer(swaps[_swapID].spender, swaps[_swapID].value);
    }

     
     
     
    function refund(bytes32 _swapID) public {
        BaseSwap.refund(_swapID);

         
        CompatibleERC20(TOKEN_ADDRESS).safeTransfer(swaps[_swapID].funder, swaps[_swapID].value + swaps[_swapID].brokerFee);
    }

     
     
     
    function withdrawBrokerFees(uint256 _amount) public {
        BaseSwap.withdrawBrokerFees(_amount);

        CompatibleERC20(TOKEN_ADDRESS).safeTransfer(msg.sender, _amount);
    }
}