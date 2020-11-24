 

pragma solidity ^0.4.24;

 

 
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

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
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

 

 
pragma solidity ^0.4.24;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;

    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

     
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        if (item.length == 0) 
            return RLPItem(0, 0);

        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

     
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory result) {
        require(isList(item));

        uint items = numItems(item);
        result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr); 
            memPtr = memPtr + dataLen;
        }
    }

     

     
    function isList(RLPItem memory item) internal pure returns (bool) {
        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

     
    function numItems(RLPItem memory item) internal pure returns (uint) {
        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
           currPtr = currPtr + _itemLength(currPtr);  
           count++;
        }

        return count;
    }

     
    function _itemLength(uint memPtr) internal pure returns (uint len) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            return 1;
        
        else if (byte0 < STRING_LONG_START)
            return byte0 - STRING_SHORT_START + 1;

        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7)  
                memPtr := add(memPtr, 1)  
                
                 
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen)))  
                len := add(dataLen, add(byteLen, 1))
            }
        }

        else if (byte0 < LIST_LONG_START) {
            return byte0 - LIST_SHORT_START + 1;
        } 

        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen)))  
                len := add(dataLen, add(byteLen, 1))
            }
        }
    }

     
    function _payloadOffset(uint memPtr) internal pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) 
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)   
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }

     

     
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes) {
        bytes memory result = new bytes(item.len);
        
        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1, "Invalid RLPItem. Booleans are encoded in 1 byte");
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
         
        require(item.len <= 21, "Invalid RLPItem. Addresses are encoded in 20 bytes or less");

        return address(toUint(item));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;
        uint memPtr = item.memPtr + offset;

        uint result;
        assembly {
            result := div(mload(memPtr), exp(256, sub(32, len)))  
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;  
        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }


     
    function copy(uint src, uint dest, uint len) internal pure {
         
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

         
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))  
            let destpart := and(mload(dest), mask)  
            mstore(dest, or(destpart, srcpart))
        }
    }
}

 

 




contract BetStorage is Ownable {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) public bets;
    mapping(address => uint256) public betsSumByOption;
    address public wonOption;

    event BetAdded(address indexed user, address indexed option, uint256 value);
    event Finalized(address indexed option);
    event RewardClaimed(address indexed user, uint256 reward);

    function addBet(address user, address option) public payable onlyOwner {
        require(msg.value > 0, "Empty bet is not allowed");
        require(option != address(0), "Option should not be zero");

        bets[user][option] = bets[user][option].add(msg.value);
        betsSumByOption[option] = betsSumByOption[option].add(msg.value);
        emit BetAdded(user, option, msg.value);
    }

    function finalize(address option, address admin) public onlyOwner {
        require(wonOption == address(0), "Finalization could be called only once");
        require(option != address(0), "Won option should not be zero");

        wonOption = option;
        emit Finalized(option);

        if (betsSumByOption[option] == 0) {		
            selfdestruct(admin);		
        }		
    }

    function rewardFor(address user) public view returns(uint256 reward) {
        if (bets[user][wonOption] > 0) {
            reward = address(this).balance
                .mul(bets[user][wonOption])
                .div(betsSumByOption[wonOption]);
        }
    }

    function rewards(
        address user,
        address referrer,
        uint256 referrerFee,
        uint256 adminFee
    )
        public
        view
        returns(uint256 userReward, uint256 referrerReward, uint256 adminReward)
    {
        userReward = rewardFor(user);
        adminReward = userReward.sub(bets[user][wonOption]).mul(adminFee).div(100);

        if (referrer != address(0)) {
            referrerReward = adminReward.mul(referrerFee).div(100);
            adminReward = adminReward.sub(referrerReward);
        }

        userReward = userReward.sub(adminReward).sub(referrerReward);
    }

    function claimReward(
        address user,
        address admin,
        uint256 adminFee,
        address referrer,
        uint256 referrerFee
    )
        public
        onlyOwner
    {
        require(wonOption != address(0), "Round not yet finalized");

        (uint256 userReward, uint256 referrerReward, uint256 adminReward) = rewards(
            user,
            referrer,
            referrerFee,
            adminFee
        );
        require(userReward > 0, "Reward was claimed previously or never existed");
        
        betsSumByOption[wonOption] = betsSumByOption[wonOption].sub(bets[user][wonOption]);
        bets[user][wonOption] = 0;

        if (referrerReward > 0) {
            referrer.send(referrerReward);
        }

        if (adminReward > 0) {
            admin.send(adminReward);
        }

        user.transfer(userReward);
        emit RewardClaimed(user, userReward);

        if (betsSumByOption[wonOption] == 0) {
            selfdestruct(admin);
        }
    }
}

 

contract BlockHash {
    using SafeMath for uint256;
    using RLPReader for RLPReader.RLPItem;

    mapping (uint256 => bytes32) private _hashes;

    function blockhashes(
        uint256 blockNumber
    )
        public
        view
        returns(bytes32)
    {
        if (blockNumber >= block.number.sub(256)) {
            return blockhash(blockNumber);
        }

        return _hashes[blockNumber];
    }

    function addBlocks(
        uint256 blockNumber,
        bytes blocksData,
        uint256[] starts
    )
        public
    {
        require(starts.length > 0 && starts[starts.length - 1] == blocksData.length, "Wrong starts argument");

        bytes32 expectedHash = blockhashes(blockNumber);
        for (uint i = 0; i < starts.length - 1; i++) {
            uint256 offset = starts[i];
            uint256 length = starts[i + 1].sub(starts[i]);
            bytes32 result;
            uint256 ptr;
            assembly {
                ptr := add(add(blocksData, 0x20), offset)
                result := keccak256(ptr, length)
            }

            require(result == expectedHash, "Blockhash didn't match");
            expectedHash = bytes32(RLPReader.RLPItem({len: length, memPtr: ptr}).toList()[0].toUint());
        }
        
        uint256 index = blockNumber.add(1).sub(starts.length);
        if (_hashes[index] == 0) {
            _hashes[index] = expectedHash;
        }
    }
}

 

 

contract ClashHash is Ownable {
    using SafeMath for uint256;
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    struct Round {
        BetStorage records;
        uint256 betsCount;
        uint256 totalReward;
        address winner;
    }

    uint256 public minBet = 0.001 ether;
    uint256 constant public MIN_BLOCKS_BEFORE_ROUND = 10;
    uint256 constant public MIN_BLOCKS_AFTER_ROUND = 10;
    uint256 constant public MAX_BLOCKS_AFTER_ROUND = 256;

    uint256 public adminFee = 5;
    uint256 public referrerFee = 50;

    mapping(address => address) public referrers;
    mapping(uint256 => Round) public rounds;
    BlockHash public _blockStorage;

     

    event RoundCreated(uint256 indexed blockNumber, address contractAddress);
    event RoundBetAdded(uint256 indexed blockNumber, address indexed user, address indexed option, uint256 value);
    event RoundFinalized(uint256 indexed blockNumber, address indexed option);
    event RewardClaimed(uint256 indexed blockNumber, address indexed user, address indexed winner, uint256 reward);

    event NewReferral(address indexed user, address indexed referrer);
    event ReferralReward(address indexed user, address indexed referrer, uint256 value);

    event AdminFeeUpdate(uint256 oldFee, uint256 newFee);
    event ReferrerFeeUpdate(uint256 oldFee, uint256 newFee);
    event MinBetUpdate(uint256 oldMinBet, uint256 newMinBet);

     

    constructor (BlockHash blockStorage) public {
        _blockStorage = blockStorage;
    }

     

    function setReferrerFee(uint256 newFee) public onlyOwner {
        emit ReferrerFeeUpdate(referrerFee, newFee);
        referrerFee = newFee;
    }

    function setAdminFee(uint256 newFee) public onlyOwner {
        emit AdminFeeUpdate(adminFee, newFee);
        adminFee = newFee;
    }

    function setMinBet(uint256 newMinBet) public onlyOwner {
        emit MinBetUpdate(minBet, newMinBet);
        minBet = newMinBet;
    }

     
    function addReferral(address referrer) public {
        require(referrer != address(0), "Invalid referrer address");
        require(referrer != msg.sender, "Different addresses required");
        require(referrers[msg.sender] == address(0), "User has referrer already");

        referrers[msg.sender] = referrer;
        emit NewReferral(msg.sender, referrer);
    }

    function addBet(uint256 blockNumber, address option) public payable {
        require(msg.value >= minBet, "Bet amount is too low");
        require(block.number <= blockNumber.sub(MIN_BLOCKS_BEFORE_ROUND), "It's too late");

        Round storage round = rounds[blockNumber];
        if (round.records == address(0)) {
            round.records = new BetStorage();
            emit RoundCreated(blockNumber, round.records);
        }

        round.betsCount += 1;
        round.totalReward = round.totalReward.add(msg.value);
        round.records.addBet.value(msg.value)(msg.sender, option);

        emit RoundBetAdded(
            blockNumber,
            msg.sender,
            option,
            msg.value
        );
    }

    function addBetWithReferrer(
        uint256 blockNumber,
        address option,
        address referrer
    )
        public
        payable
    {
        addReferral(referrer);
        addBet(blockNumber, option);
    }

    function claimRewardWithBlockData(uint256 blockNumber, bytes blockData) public {
        if (blockData.length > 0 && rounds[blockNumber].winner == address(0)) {
            addBlockData(blockNumber, blockData);
        }

        claimRewardForUser(blockNumber, msg.sender);
    }

    function claimRewardForUser(uint256 blockNumber, address user) public {
        Round storage round = rounds[blockNumber];
        require(round.winner != address(0), "Round not yet finished");
        require(address(round.records).balance > 0, "Round prizes are already distributed");

        (uint256 userReward, uint256 referrerReward,) = round.records.rewards(
            user,
            referrers[user],
            referrerFee,
            adminFee
        );
        round.records.claimReward(user, owner(), adminFee, referrers[user], referrerFee);

        emit RewardClaimed(blockNumber, user, round.winner, userReward);

        if (referrerReward > 0) {
            emit ReferralReward(user, referrers[user], referrerReward);
        }
    }

    function addBlockData(uint256 blockNumber, bytes blockData) public {
        Round storage round = rounds[blockNumber];

        require(round.winner == address(0), "Winner was already submitted");
        require(block.number <= blockNumber.add(MAX_BLOCKS_AFTER_ROUND), "It's too late, 256 blocks gone");
        require(block.number >= blockNumber.add(MIN_BLOCKS_AFTER_ROUND), "Wait at least 10 blocks");

        address blockBeneficiary = _readBlockBeneficiary(blockNumber, blockData);

        round.winner = blockBeneficiary;
        round.records.finalize(blockBeneficiary, owner());
        emit RoundFinalized(blockNumber, blockBeneficiary);
    }

    function _readBlockBeneficiary(
        uint256 blockNumber,
        bytes blockData
    )
        internal
        view
        returns(address)
    {
        require(keccak256(blockData) == _blockStorage.blockhashes(blockNumber), "Block data isn't valid");
        RLPReader.RLPItem[] memory items = blockData.toRlpItem().toList();
        return items[2].toAddress();
    }
}