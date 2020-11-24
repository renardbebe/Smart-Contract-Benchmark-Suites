 

pragma solidity ^0.5.1;

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

interface ERC20SwapContract {
     
     
     
     
     
     
     
    function initiate(
        bytes32 _swapID,
        address _spender,
        bytes32 _secretLock,
        uint256 _timelock,
        uint256 _value
    ) external;

     
     
     
     
     
     
     
     
     
    function initiateWithFees(
        bytes32 _swapID,
        address _spender,
        address _broker,
        uint256 _brokerFee,
        bytes32 _secretLock,
        uint256 _timelock,
        uint256 _value
    ) external;

     
     
     
     
     
    function redeem(bytes32 _swapID, address _receiver, bytes32 _secretKey) external;

     
     
     
    function refund(bytes32 _swapID) external;

     
     
     
    function withdrawBrokerFees(uint256 _amount) external;

     
     
     
    function audit(bytes32 _swapID) external view returns (uint256 timelock, uint256 value, address to, uint256 brokerFee, address broker, address from, bytes32 secretLock);

     
     
     
    function auditSecret(bytes32 _swapID) external view  returns (bytes32 secretKey);

     
     
     
    function refundable(bytes32 _swapID) external view returns (bool);

     
     
     
    function initiatable(bytes32 _swapID) external view returns (bool);

     
     
     
    function redeemable(bytes32 _swapID) external view returns (bool);

     
     
     
     
    function swapID(bytes32 _secretLock, uint256 _timelock) external pure returns (bytes32);
}

 
contract WBTCSwapContract is ERC20SwapContract {
    string public VERSION;  
    address public TOKEN_ADDRESS;  

    struct Swap {
        uint256 timelock;
        uint256 value;
        uint256 brokerFee;
        bytes32 secretLock;
        bytes32 secretKey;
        address funder;
        address spender;
        address broker;
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

     
    mapping (bytes32 => Swap) private swaps;
    mapping (bytes32 => States) private swapStates;
    mapping (address => uint256) public brokerFees;
    mapping (bytes32 => uint256) public redeemedAt;

     
    modifier onlyInvalidSwaps(bytes32 _swapID) {
        require(swapStates[_swapID] == States.INVALID, "swap opened previously");
        _;
    }

     
    modifier onlyOpenSwaps(bytes32 _swapID) {
        require(swapStates[_swapID] == States.OPEN, "swap not open");
        _;
    }

     
    modifier onlyClosedSwaps(bytes32 _swapID) {
        require(swapStates[_swapID] == States.CLOSED, "swap not redeemed");
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

     
     
     
    constructor(string memory _VERSION, address _TOKEN_ADDRESS) public {
        VERSION = _VERSION;
        TOKEN_ADDRESS = _TOKEN_ADDRESS;
    }

 
     
     
     
     
     
     
    function initiate(
        bytes32 _swapID,
        address _spender,
        bytes32 _secretLock,
        uint256 _timelock,
        uint256 _value
    ) external onlyInvalidSwaps(_swapID) {
         
         
         
         
        CompatibleERC20(TOKEN_ADDRESS).transferFrom(msg.sender, address(this), _value);

         
        Swap memory swap = Swap({
            timelock: _timelock,
            value: _value,
            funder: msg.sender,
            spender: _spender,
            broker: address(0x0),
            brokerFee: 0,
            secretLock: _secretLock,
            secretKey: 0x0
        });
        swaps[_swapID] = swap;
        swapStates[_swapID] = States.OPEN;

         
        emit LogOpen(_swapID, _spender, _secretLock);
    }

     
     
     
     
     
     
     
     
     
    function initiateWithFees(
        bytes32 _swapID,
        address _spender,
        address _broker,
        uint256 _brokerFee,
        bytes32 _secretLock,
        uint256 _timelock,
        uint256 _value
    ) external onlyInvalidSwaps(_swapID) {
         
         
         
         
        CompatibleERC20(TOKEN_ADDRESS).transferFrom(msg.sender, address(this), _value);

         
        Swap memory swap = Swap({
            timelock: _timelock,
            value: _value - _brokerFee,
            funder: msg.sender,
            spender: _spender,
            broker: _broker,
            brokerFee: _brokerFee,
            secretLock: _secretLock,
            secretKey: 0x0
        });
        swaps[_swapID] = swap;
        swapStates[_swapID] = States.OPEN;

         
        emit LogOpen(_swapID, _spender, _secretLock);
    }

     
     
     
    function refund(bytes32 _swapID) external onlyOpenSwaps(_swapID) onlyExpirableSwaps(_swapID) {
         
        swapStates[_swapID] = States.EXPIRED;

         
        CompatibleERC20(TOKEN_ADDRESS).transfer(swaps[_swapID].funder, swaps[_swapID].value + swaps[_swapID].brokerFee);

         
        emit LogExpire(_swapID);
    }

     
     
     
    function withdrawBrokerFees(uint256 _amount) external {
        require(_amount <= brokerFees[msg.sender]);
        brokerFees[msg.sender] -= _amount;
        CompatibleERC20(TOKEN_ADDRESS).transfer(msg.sender, _amount);
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

     
     
     
     
    function redeem(bytes32 _swapID, address _receiver, bytes32 _secretKey) external onlyOpenSwaps(_swapID) onlyWithSecretKey(_swapID, _secretKey) onlySpender(_swapID, msg.sender) {
         
        swaps[_swapID].secretKey = _secretKey;
        swapStates[_swapID] = States.CLOSED;
         
        redeemedAt[_swapID] = now;

         
        brokerFees[swaps[_swapID].broker] += swaps[_swapID].brokerFee;

         
        CompatibleERC20(TOKEN_ADDRESS).transfer(_receiver, swaps[_swapID].value);

         
        emit LogClose(_swapID, _secretKey);
    }
    
     
     
     
    function refundable(bytes32 _swapID) external view returns (bool) {
         
        return (now >= swaps[_swapID].timelock && swapStates[_swapID] == States.OPEN);
    }

     
     
     
    function initiatable(bytes32 _swapID) external view returns (bool) {
        return (swapStates[_swapID] == States.INVALID);
    }

     
     
     
    function redeemable(bytes32 _swapID) external view returns (bool) {
        return (swapStates[_swapID] == States.OPEN);
    }

     
     
     
     
    function swapID(bytes32 _secretLock, uint256 _timelock) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_secretLock, _timelock));
    }
}