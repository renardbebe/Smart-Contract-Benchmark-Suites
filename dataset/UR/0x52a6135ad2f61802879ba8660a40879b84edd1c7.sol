 

pragma solidity 0.5.8;

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

contract ERC20AtomicSwapper {

    struct Swap {
        uint256 outAmount;
        uint256 expireHeight;
        bytes32 randomNumberHash;
        uint64  timestamp;
        address sender;
        address recipientAddr;
    }

    enum States {
        INVALID,
        OPEN,
        COMPLETED,
        EXPIRED
    }

     
    event HTLT(address indexed _msgSender, address indexed _recipientAddr, bytes32 indexed _swapID, bytes32 _randomNumberHash, uint64 _timestamp, bytes20 _bep2Addr, uint256 _expireHeight, uint256 _outAmount, uint256 _bep2Amount);
    event Refunded(address indexed _msgSender, address indexed _recipientAddr, bytes32 indexed _swapID, bytes32 _randomNumberHash);
    event Claimed(address indexed _msgSender, address indexed _recipientAddr, bytes32 indexed _swapID, bytes32 _randomNumberHash, bytes32 _randomNumber);

     
    mapping (bytes32 => Swap) private swaps;
    mapping (bytes32 => States) private swapStates;

    address public ERC20ContractAddr;

     
    modifier onlyOpenSwaps(bytes32 _swapID) {
        require(swapStates[_swapID] == States.OPEN, "swap is not opened");
        _;
    }

     
    modifier onlyAfterExpireHeight(bytes32 _swapID) {
        require(block.number >= swaps[_swapID].expireHeight, "swap is not expired");
        _;
    }

     
    modifier onlyBeforeExpireHeight(bytes32 _swapID) {
        require(block.number < swaps[_swapID].expireHeight, "swap is already expired");
        _;
    }

     
    modifier onlyWithRandomNumber(bytes32 _swapID, bytes32 _randomNumber) {
        require(swaps[_swapID].randomNumberHash == sha256(abi.encodePacked(_randomNumber, swaps[_swapID].timestamp)), "invalid randomNumber");
        _;
    }

    constructor() public {
        ERC20ContractAddr = address(0x1b22C32cD936cB97C28C5690a0695a82Abf688e6);
    }

     
     
     
     
     
     
     
     
     
     
    function htlt(
        bytes32 _randomNumberHash,
        uint64  _timestamp,
        uint256 _heightSpan,
        address _recipientAddr,
        bytes20 _bep2SenderAddr,
        bytes20 _bep2RecipientAddr,
        uint256 _outAmount,
        uint256 _bep2Amount
    ) external returns (bool) {
        bytes32 swapID = calSwapID(_randomNumberHash, msg.sender, _bep2SenderAddr);
        require(swapStates[swapID] == States.INVALID, "swap is opened previously");
         
         
        require(_heightSpan >= 60 && _heightSpan <= 60480, "_heightSpan should be in [60, 60480]");
        require(_recipientAddr != address(0), "_recipientAddr should not be zero");
        require(_outAmount > 0, "_outAmount must be more than 0");
        require(_timestamp > now - 1800 && _timestamp < now + 900, "Timestamp can neither be 15 minutes ahead of the current time, nor 30 minutes later");
         
        Swap memory swap = Swap({
            outAmount: _outAmount,
            expireHeight: _heightSpan + block.number,
            randomNumberHash: _randomNumberHash,
            timestamp: _timestamp,
            sender: msg.sender,
            recipientAddr: _recipientAddr
        });

        swaps[swapID] = swap;
        swapStates[swapID] = States.OPEN;

         
        require(ERC20(ERC20ContractAddr).transferFrom(msg.sender, address(this), _outAmount), "failed to transfer client asset to swap contract address");

         
        emit HTLT(
            msg.sender,
            _recipientAddr,
            swapID,
            _randomNumberHash,
            _timestamp,
            _bep2RecipientAddr,
            swap.expireHeight,
            _outAmount,
            _bep2Amount);
        return true;
    }

     
     
     
     
    function claim(bytes32 _swapID, bytes32 _randomNumber) external onlyOpenSwaps(_swapID) onlyBeforeExpireHeight(_swapID) onlyWithRandomNumber(_swapID, _randomNumber) returns (bool) {
         
        swapStates[_swapID] = States.COMPLETED;

        address recipientAddr = swaps[_swapID].recipientAddr;
        uint256 outAmount = swaps[_swapID].outAmount;
        bytes32 randomNumberHash = swaps[_swapID].randomNumberHash;
         
        delete swaps[_swapID];

         
        require(ERC20(ERC20ContractAddr).transfer(recipientAddr, outAmount), "Failed to transfer locked asset to recipient");

         
        emit Claimed(msg.sender, recipientAddr, _swapID, randomNumberHash, _randomNumber);

        return true;
    }

     
     
     
    function refund(bytes32 _swapID) external onlyOpenSwaps(_swapID) onlyAfterExpireHeight(_swapID) returns (bool) {
         
        swapStates[_swapID] = States.EXPIRED;

        address swapSender = swaps[_swapID].sender;
        uint256 outAmount = swaps[_swapID].outAmount;
        bytes32 randomNumberHash = swaps[_swapID].randomNumberHash;
         
        delete swaps[_swapID];

         
        require(ERC20(ERC20ContractAddr).transfer(swapSender, outAmount), "Failed to transfer locked asset back to swap creator");

         
        emit Refunded(msg.sender, swapSender, _swapID, randomNumberHash);

        return true;
    }

     
     
     
    function queryOpenSwap(bytes32 _swapID) external view returns(bytes32 _randomNumberHash, uint64 _timestamp, uint256 _expireHeight, uint256 _outAmount, address _sender, address _recipient) {
        Swap memory swap = swaps[_swapID];
        return (
            swap.randomNumberHash,
            swap.timestamp,
            swap.expireHeight,
            swap.outAmount,
            swap.sender,
            swap.recipientAddr
        );
    }

     
     
     
    function isSwapExist(bytes32 _swapID) external view returns (bool) {
        return (swapStates[_swapID] != States.INVALID);
    }

     
     
     
    function refundable(bytes32 _swapID) external view returns (bool) {
        return (block.number >= swaps[_swapID].expireHeight && swapStates[_swapID] == States.OPEN);
    }

     
     
     
    function claimable(bytes32 _swapID) external view returns (bool) {
        return (block.number < swaps[_swapID].expireHeight && swapStates[_swapID] == States.OPEN);
    }

     
     
     
     
     
    function calSwapID(bytes32 _randomNumberHash, address _swapSender, bytes20 _bep2SenderAddr) public pure returns (bytes32) {
        if (_bep2SenderAddr == bytes20(0)) {
            return sha256(abi.encodePacked(_randomNumberHash, _swapSender));
        }
        return sha256(abi.encodePacked(_randomNumberHash, _swapSender, _bep2SenderAddr));
    }
}