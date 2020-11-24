 

pragma solidity ^0.5.1;

 
 
contract EthSwapContract {
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

     
     
     
    constructor(string memory _VERSION) public {
        VERSION = _VERSION;
    }

     
     
     
     
     
     
     
     
     
    function initiateWithFees(
        bytes32 _swapID,
        address _spender,
        address _broker,
        uint256 _brokerFee,
        bytes32 _secretLock,
        uint256 _timelock,
        uint256 _value
    ) external onlyInvalidSwaps(_swapID) payable {
        require(_value == msg.value && _value >= _brokerFee);
         
        Swap memory swap = Swap({
            timelock: _timelock,
            brokerFee: _brokerFee,
            value: _value - _brokerFee,
            funder: address(uint160(msg.sender)),
            spender: address(uint160(_spender)),
            broker: address(uint160(_broker)),
            secretLock: _secretLock,
            secretKey: 0x0
        });
        swaps[_swapID] = swap;
        swapStates[_swapID] = States.OPEN;

         
        emit LogOpen(_swapID, _spender, _secretLock);
    }

     
     
     
     
     
     
     
    function initiate(
        bytes32 _swapID,
        address _spender,
        bytes32 _secretLock,
        uint256 _timelock,
        uint256 _value
    ) external onlyInvalidSwaps(_swapID) payable {
        require(_value == msg.value);
         
        Swap memory swap = Swap({
            timelock: _timelock,
            brokerFee: 0,
            value: _value,
            funder: address(uint160(msg.sender)),
            spender: address(uint160(_spender)),
            broker: address(0x0),
            secretLock: _secretLock,
            secretKey: 0x0
        });
        swaps[_swapID] = swap;
        swapStates[_swapID] = States.OPEN;

         
        emit LogOpen(_swapID, _spender, _secretLock);
    }

     
     
     
     
     
    function redeem(bytes32 _swapID, address _receiver, bytes32 _secretKey) external onlyOpenSwaps(_swapID) onlyWithSecretKey(_swapID, _secretKey) onlySpender(_swapID, msg.sender) {
        address payable receiver = address(uint160(_receiver));

         
        swaps[_swapID].secretKey = _secretKey;
        swapStates[_swapID] = States.CLOSED;
         
        redeemedAt[_swapID] = now;

         
        brokerFees[swaps[_swapID].broker] += swaps[_swapID].brokerFee;

         
        receiver.transfer(swaps[_swapID].value);

         
        emit LogClose(_swapID, _secretKey);
    }

     
     
     
    function refund(bytes32 _swapID) external onlyOpenSwaps(_swapID) onlyExpirableSwaps(_swapID) {
         
        swapStates[_swapID] = States.EXPIRED;

         
        swaps[_swapID].funder.transfer(swaps[_swapID].value + swaps[_swapID].brokerFee);

         
        emit LogExpire(_swapID);
    }

     
     
     
    function withdrawBrokerFees(uint256 _amount) external {
        require(_amount <= brokerFees[msg.sender]);
        brokerFees[msg.sender] -= _amount;
        msg.sender.transfer(_amount);
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