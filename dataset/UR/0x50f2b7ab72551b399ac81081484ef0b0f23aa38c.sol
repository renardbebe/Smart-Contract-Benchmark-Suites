 

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

 
 
contract EthSwap is SwapInterface, BaseSwap {

    constructor(string memory _VERSION) BaseSwap(_VERSION) public {
    }
    
     
     
     
     
     
     
     
    function initiate(
        bytes32 _swapID,
        address payable _spender,
        bytes32 _secretLock,
        uint256 _timelock,
        uint256 _value
    ) public payable {
        require(_value == msg.value, "eth amount must match value");
        require(_spender != address(0x0), "spender must not be zero");

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
        require(_value == msg.value, "eth amount must match value");
        require(_spender != address(0x0), "spender must not be zero");

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

         
        _receiver.transfer(BaseSwap.swaps[_swapID].value);
    }

     
     
     
     
    function redeemToSpender(bytes32 _swapID, bytes32 _secretKey) public {
        BaseSwap.redeemToSpender(
            _swapID,
            _secretKey
        );

         
        swaps[_swapID].spender.transfer(BaseSwap.swaps[_swapID].value);
    }

     
     
     
    function refund(bytes32 _swapID) public {
        BaseSwap.refund(_swapID);

         
        BaseSwap.swaps[_swapID].funder.transfer(
            BaseSwap.swaps[_swapID].value + BaseSwap.swaps[_swapID].brokerFee
        );
    }

     
     
     
    function withdrawBrokerFees(uint256 _amount) public {
        BaseSwap.withdrawBrokerFees(_amount);
        msg.sender.transfer(_amount);
    }
}