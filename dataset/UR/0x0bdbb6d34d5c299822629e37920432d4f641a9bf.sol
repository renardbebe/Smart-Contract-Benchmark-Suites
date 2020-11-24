 

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity >=0.4.24 ^0.5.1;


 
 
 
library Fixed192x64Math {

    enum EstimationMode { LowerBound, UpperBound, Midpoint }

     
     
    uint public constant ONE =  0x10000000000000000;
    uint public constant LN2 = 0xb17217f7d1cf79ac;
    uint public constant LOG2_E = 0x171547652b82fe177;

     
     
     
     
    function exp(int x)
        public
        pure
        returns (uint)
    {
         
         
        require(x <= 2454971259878909886679);
         
         
        if (x <= -818323753292969962227)
            return 0;

         
        (uint lower, uint upper) = pow2Bounds(x * int(ONE) / int(LN2));
        return (upper - lower) / 2 + lower;
    }

     
     
     
     
    function pow2(int x, EstimationMode estimationMode)
        public
        pure
        returns (uint)
    {
        (uint lower, uint upper) = pow2Bounds(x);
        if(estimationMode == EstimationMode.LowerBound) {
            return lower;
        }
        if(estimationMode == EstimationMode.UpperBound) {
            return upper;
        }
        if(estimationMode == EstimationMode.Midpoint) {
            return (upper - lower) / 2 + lower;
        }
        revert();
    }

     
     
     
     
     
     
    function pow2Bounds(int x)
        public
        pure
        returns (uint lower, uint upper)
    {
         
         
        require(x <= 3541774862152233910271);
         
         
        if (x < -1180591620717411303424)
            return (0, 1);

         
         
         
        int shift;
        int z;
        if (x >= 0) {
            shift = x / int(ONE);
            z = x % int(ONE);
        }
        else {
            shift = (x+1) / int(ONE) - 1;
            z = x - (int(ONE) * shift);
        }
        assert(z >= 0);
         
         
         
         
         
         
         
         
        int result = int(ONE) << 64;
        int zpow = z;
        result += 0xb17217f7d1cf79ab * zpow;
        zpow = zpow * z / int(ONE);
        result += 0xf5fdeffc162c7543 * zpow >> (66 - 64);
        zpow = zpow * z / int(ONE);
        result += 0xe35846b82505fc59 * zpow >> (68 - 64);
        zpow = zpow * z / int(ONE);
        result += 0x9d955b7dd273b94e * zpow >> (70 - 64);
        zpow = zpow * z / int(ONE);
        result += 0xaec3ff3c53398883 * zpow >> (73 - 64);
        zpow = zpow * z / int(ONE);
        result += 0xa184897c363c3b7a * zpow >> (76 - 64);
        zpow = zpow * z / int(ONE);
        result += 0xffe5fe2c45863435 * zpow >> (80 - 64);
        zpow = zpow * z / int(ONE);
        result += 0xb160111d2e411fec * zpow >> (83 - 64);
        zpow = zpow * z / int(ONE);
        result += 0xda929e9caf3e1ed2 * zpow >> (87 - 64);
        zpow = zpow * z / int(ONE);
        result += 0xf267a8ac5c764fb7 * zpow >> (91 - 64);
        zpow = zpow * z / int(ONE);
        result += 0xf465639a8dd92607 * zpow >> (95 - 64);
        zpow = zpow * z / int(ONE);
        result += 0xe1deb287e14c2f15 * zpow >> (99 - 64);
        zpow = zpow * z / int(ONE);
        result += 0xc0b0c98b3687cb14 * zpow >> (103 - 64);
        zpow = zpow * z / int(ONE);
        result += 0x98a4b26ac3c54b9f * zpow >> (107 - 64);
        zpow = zpow * z / int(ONE);
        result += 0xe1b7421d82010f33 * zpow >> (112 - 64);
        zpow = zpow * z / int(ONE);
        result += 0x9c744d73cfc59c91 * zpow >> (116 - 64);
        zpow = zpow * z / int(ONE);
        result += 0xcc2225a0e12d3eab * zpow >> (121 - 64);
        zpow = zpow * z / int(ONE);
        zpow = 0xfb8bb5eda1b4aeb9 * zpow >> (126 - 64);
        result += zpow;
        zpow = int(8 * ONE);

        shift -= 64;
        if (shift >= 0) {
            if (result >> (256-shift) == 0) {
                lower = uint(result) << shift;
                zpow <<= shift;  
                if (lower + uint(zpow) >= lower)
                    upper = lower + uint(zpow);
                else
                    upper = 2**256-1;
                return (lower, upper);
            }
            else
                return (2**256-1, 2**256-1);
        }
        zpow = (zpow >> (-shift)) + 1;
        lower = uint(result) >> (-shift);
        upper = lower + uint(zpow);
        return (lower, upper);
    }

     
     
     
    function ln(uint x)
        public
        pure
        returns (int)
    {
        (int lower, int upper) = log2Bounds(x);
        return ((upper - lower) / 2 + lower) * int(ONE) / int(LOG2_E);
    }

     
     
     
     
    function binaryLog(uint x, EstimationMode estimationMode)
        public
        pure
        returns (int)
    {
        (int lower, int upper) = log2Bounds(x);
        if(estimationMode == EstimationMode.LowerBound) {
            return lower;
        }
        if(estimationMode == EstimationMode.UpperBound) {
            return upper;
        }
        if(estimationMode == EstimationMode.Midpoint) {
            return (upper - lower) / 2 + lower;
        }
        revert();
    }

     
     
     
     
     
     
    function log2Bounds(uint x)
        public
        pure
        returns (int lower, int upper)
    {
        require(x > 0);
         
        lower = floorLog2(x);

        uint y;
        if (lower < 0)
            y = x << uint(-lower);
        else
            y = x >> uint(lower);

        lower *= int(ONE);

         
         
         
        for (int m = 1; m <= 64; m++) {
            if(y == ONE) {
                break;
            }
            y = y * y / ONE;
            if(y >= 2 * ONE) {
                lower += int(ONE >> m);
                y /= 2;
            }
        }

        return (lower, lower + 4);
    }

     
     
     
    function floorLog2(uint x)
        public
        pure
        returns (int lo)
    {
        lo = -64;
        int hi = 193;
         
        int mid = (hi + lo) >> 1;
        while((lo + 1) < hi) {
            if (mid < 0 && x << uint(-mid) < ONE || mid >= 0 && x >> uint(mid) < ONE)
                hi = mid;
            else
                lo = mid;
            mid = (hi + lo) >> 1;
        }
    }

     
     
     
    function max(int[] memory nums)
        public
        pure
        returns (int maxNum)
    {
        require(nums.length > 0);
        maxNum = -2**255;
        for (uint i = 0; i < nums.length; i++)
            if (nums[i] > maxNum)
                maxNum = nums[i];
    }
}

 

pragma solidity ^0.5.0;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

interface IERC1155TokenReceiver {
     
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

     
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);
}

 

pragma solidity ^0.5.0;

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 

pragma solidity ^0.5.0;


 
  contract IERC1155 is IERC165 {
     
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
    event URI(string _value, uint256 indexed _id);

     
    event Name(string _value, uint256 indexed _id);

     
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

     
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

     
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

     
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

     
    function setApprovalForAll(address _operator, bool _approved) external;

     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 

pragma solidity ^0.5.0;





 
contract ERC1155 is IERC1155
{
    using SafeMath for uint256;
    using Address for address;

    bytes4 constant public ERC1155_RECEIVED       = 0xf23a6e61;
    bytes4 constant public ERC1155_BATCH_RECEIVED = 0xbc197c81;

     
    mapping (uint256 => mapping(address => uint256)) internal balances;

     
    mapping (address => mapping(address => bool)) internal operatorApproval;

 

     
    bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

     
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool) {
         if (_interfaceId == INTERFACE_SIGNATURE_ERC165 ||
             _interfaceId == INTERFACE_SIGNATURE_ERC1155) {
            return true;
         }

         return false;
    }

 

     
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external {

        require(_to != address(0), "_to must be non-zero.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

         
         
        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to]   = _value.add(balances[_id][_to]);

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _value, _data) == ERC1155_RECEIVED);
        }
    }

     
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external {

         
        require(_to != address(0), "_to must be non-zero.");
        require(_ids.length == _values.length, "_ids and _values array lenght must match.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];

             
             
            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to]   = value.add(balances[id][_to]);
        }

         
        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

         
         
        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _values, _data) == ERC1155_BATCH_RECEIVED);
        }
    }

     
    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
         
         
         
        return balances[_id][_owner];
    }


     
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory) {

        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

     
    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApproval[_owner][_operator];
    }
}

 

pragma solidity ^0.5.1;


interface OracleConsumer {
    function receiveResult(bytes32 id, bytes calldata result) external;
}

 

pragma solidity ^0.5.1;





contract PredictionMarketSystem is OracleConsumer, ERC1155 {

     
     
     
     
     
    event ConditionPreparation(bytes32 indexed conditionId, address indexed oracle, bytes32 indexed questionId, uint outcomeSlotCount);

    event ConditionResolution(bytes32 indexed conditionId, address indexed oracle, bytes32 indexed questionId, uint outcomeSlotCount, uint[] payoutNumerators);

     
    event PositionSplit(address indexed stakeholder, IERC20 collateralToken, bytes32 indexed parentCollectionId, bytes32 indexed conditionId, uint[] partition, uint amount);
     
    event PositionsMerge(address indexed stakeholder, IERC20 collateralToken, bytes32 indexed parentCollectionId, bytes32 indexed conditionId, uint[] partition, uint amount);
    event PayoutRedemption(address indexed redeemer, IERC20 indexed collateralToken, bytes32 indexed parentCollectionId, uint payout);

     
    mapping(bytes32 => uint[]) public payoutNumerators;
    mapping(bytes32 => uint) public payoutDenominator;

     
     
     
     
    function prepareCondition(address oracle, bytes32 questionId, uint outcomeSlotCount) external {
        require(outcomeSlotCount <= 256, "too many outcome slots");
        bytes32 conditionId = keccak256(abi.encodePacked(oracle, questionId, outcomeSlotCount));
        require(payoutNumerators[conditionId].length == 0, "condition already prepared");
        payoutNumerators[conditionId] = new uint[](outcomeSlotCount);
        emit ConditionPreparation(conditionId, oracle, questionId, outcomeSlotCount);
    }

     
     
     
    function receiveResult(bytes32 questionId, bytes calldata result) external {
        require(result.length > 0, "results empty");
        require(result.length % 32 == 0, "results not 32-byte aligned");
        uint outcomeSlotCount = result.length / 32;
        require(outcomeSlotCount <= 256, "too many outcome slots");
        bytes32 conditionId = keccak256(abi.encodePacked(msg.sender, questionId, outcomeSlotCount));
        require(payoutNumerators[conditionId].length == outcomeSlotCount, "number of outcomes mismatch");
        require(payoutDenominator[conditionId] == 0, "payout denominator already set");
        for (uint i = 0; i < outcomeSlotCount; i++) {
            uint payoutNum;
             
            assembly {
                payoutNum := calldataload(add(0x64, mul(0x20, i)))
            }
            payoutDenominator[conditionId] = payoutDenominator[conditionId].add(payoutNum);

            require(payoutNumerators[conditionId][i] == 0, "payout numerator already set");
            payoutNumerators[conditionId][i] = payoutNum;
        }
        require(payoutDenominator[conditionId] > 0, "payout is all zeroes");
        emit ConditionResolution(conditionId, msg.sender, questionId, outcomeSlotCount, payoutNumerators[conditionId]);
    }

     
     
     
     
     
     
    function splitPosition(IERC20 collateralToken, bytes32 parentCollectionId, bytes32 conditionId, uint[] calldata partition, uint amount) external {
        uint outcomeSlotCount = payoutNumerators[conditionId].length;
        require(outcomeSlotCount > 0, "condition not prepared yet");

        bytes32 key;

        uint fullIndexSet = (1 << outcomeSlotCount) - 1;
        uint freeIndexSet = fullIndexSet;
        for (uint i = 0; i < partition.length; i++) {
            uint indexSet = partition[i];
            require(indexSet > 0 && indexSet < fullIndexSet, "got invalid index set");
            require((indexSet & freeIndexSet) == indexSet, "partition not disjoint");
            freeIndexSet ^= indexSet;
            key = keccak256(abi.encodePacked(collateralToken, getCollectionId(parentCollectionId, conditionId, indexSet)));
            balances[uint(key)][msg.sender] = balances[uint(key)][msg.sender].add(amount);
        }

        if (freeIndexSet == 0) {
            if (parentCollectionId == bytes32(0)) {
                require(collateralToken.transferFrom(msg.sender, address(this), amount), "could not receive collateral tokens");
            } else {
                key = keccak256(abi.encodePacked(collateralToken, parentCollectionId));
                balances[uint(key)][msg.sender] = balances[uint(key)][msg.sender].sub(amount);
            }
        } else {
            key = keccak256(abi.encodePacked(collateralToken, getCollectionId(parentCollectionId, conditionId, fullIndexSet ^ freeIndexSet)));
            balances[uint(key)][msg.sender] = balances[uint(key)][msg.sender].sub(amount);
        }

        emit PositionSplit(msg.sender, collateralToken, parentCollectionId, conditionId, partition, amount);
    }

    function mergePositions(IERC20 collateralToken, bytes32 parentCollectionId, bytes32 conditionId, uint[] calldata partition, uint amount) external {
        uint outcomeSlotCount = payoutNumerators[conditionId].length;
        require(outcomeSlotCount > 0, "condition not prepared yet");

        bytes32 key;

        uint fullIndexSet = (1 << outcomeSlotCount) - 1;
        uint freeIndexSet = fullIndexSet;
        for (uint i = 0; i < partition.length; i++) {
            uint indexSet = partition[i];
            require(indexSet > 0 && indexSet < fullIndexSet, "got invalid index set");
            require((indexSet & freeIndexSet) == indexSet, "partition not disjoint");
            freeIndexSet ^= indexSet;
            key = keccak256(abi.encodePacked(collateralToken, getCollectionId(parentCollectionId, conditionId, indexSet)));
            balances[uint(key)][msg.sender] = balances[uint(key)][msg.sender].sub(amount);
        }

        if (freeIndexSet == 0) {
            if (parentCollectionId == bytes32(0)) {
                require(collateralToken.transfer(msg.sender, amount), "could not send collateral tokens");
            } else {
                key = keccak256(abi.encodePacked(collateralToken, parentCollectionId));
                balances[uint(key)][msg.sender] = balances[uint(key)][msg.sender].add(amount);
            }
        } else {
            key = keccak256(abi.encodePacked(collateralToken, getCollectionId(parentCollectionId, conditionId, fullIndexSet ^ freeIndexSet)));
            balances[uint(key)][msg.sender] = balances[uint(key)][msg.sender].add(amount);
        }

        emit PositionsMerge(msg.sender, collateralToken, parentCollectionId, conditionId, partition, amount);
    }

    function redeemPositions(IERC20 collateralToken, bytes32 parentCollectionId, bytes32 conditionId, uint[] calldata indexSets) external {
        require(payoutDenominator[conditionId] > 0, "result for condition not received yet");
        uint outcomeSlotCount = payoutNumerators[conditionId].length;
        require(outcomeSlotCount > 0, "condition not prepared yet");

        uint totalPayout = 0;
        bytes32 key;

        uint fullIndexSet = (1 << outcomeSlotCount) - 1;
        for (uint i = 0; i < indexSets.length; i++) {
            uint indexSet = indexSets[i];
            require(indexSet > 0 && indexSet < fullIndexSet, "got invalid index set");
            key = keccak256(abi.encodePacked(collateralToken, getCollectionId(parentCollectionId, conditionId, indexSet)));

            uint payoutNumerator = 0;
            for (uint j = 0; j < outcomeSlotCount; j++) {
                if (indexSet & (1 << j) != 0) {
                    payoutNumerator = payoutNumerator.add(payoutNumerators[conditionId][j]);
                }
            }

            uint payoutStake = balances[uint(key)][msg.sender];
            if (payoutStake > 0) {
                totalPayout = totalPayout.add(payoutStake.mul(payoutNumerator).div(payoutDenominator[conditionId]));
                balances[uint(key)][msg.sender] = 0;
            }
        }

        if (totalPayout > 0) {
            if (parentCollectionId == bytes32(0)) {
                require(collateralToken.transfer(msg.sender, totalPayout), "could not transfer payout to message sender");
            } else {
                key = keccak256(abi.encodePacked(collateralToken, parentCollectionId));
                balances[uint(key)][msg.sender] = balances[uint(key)][msg.sender].add(totalPayout);
            }
        }
        emit PayoutRedemption(msg.sender, collateralToken, parentCollectionId, totalPayout);
    }

     
     
     
    function getOutcomeSlotCount(bytes32 conditionId) external view returns (uint) {
        return payoutNumerators[conditionId].length;
    }

    function getCollectionId(bytes32 parentCollectionId, bytes32 conditionId, uint indexSet) private pure returns (bytes32) {
        return bytes32(
            uint(parentCollectionId) +
            uint(keccak256(abi.encodePacked(conditionId, indexSet)))
        );
    }
}

 

pragma solidity ^0.5.0;

 
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
        require(isOwner());
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
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity >=0.4.24 ^0.5.1;


 
library SignedSafeMath {
  int256 constant INT256_MIN = int256((uint256(1) << 255));

   
  function mul(int256 a, int256 b) internal pure returns (int256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert((a != -1 || b != INT256_MIN) && c / a == b);
  }

   
  function div(int256 a, int256 b) internal pure returns (int256) {
     
     
    assert(a != INT256_MIN || b != -1);
    return a / b;
  }

   
  function sub(int256 a, int256 b) internal pure returns (int256 c) {
    c = a - b;
    assert((b >= 0 && c <= a) || (b < 0 && c > a));
  }

   
  function add(int256 a, int256 b) internal pure returns (int256 c) {
    c = a + b;
    assert((b >= 0 && c >= a) || (b < 0 && c < a));
  }
}

 

pragma solidity ^0.5.1;






contract MarketMaker is Ownable, IERC1155TokenReceiver {
    using SignedSafeMath for int;
    using SafeMath for uint;
         
    uint64 public constant FEE_RANGE = 10**18;

     
    event AMMCreated(uint initialFunding);
    event AMMPaused();
    event AMMResumed();
    event AMMClosed();
    event AMMFundingChanged(int fundingChange);
    event AMMFeeChanged(uint64 newFee);
    event AMMFeeWithdrawal(uint fees);
    event AMMOutcomeTokenTrade(address indexed transactor, int[] outcomeTokenAmounts, int outcomeTokenNetCost, uint marketFees);
    
     
    PredictionMarketSystem public pmSystem;
    IERC20 public collateralToken;
    bytes32[] public conditionIds;
    uint public atomicOutcomeSlotCount;
    uint64 public fee;
    uint public funding;
    Stage public stage;
    enum Stage {
        Running,
        Paused,
        Closed
    }

     
    modifier atStage(Stage _stage) {
         
        require(stage == _stage);
        _;
    }

    constructor(PredictionMarketSystem _pmSystem, IERC20 _collateralToken, bytes32[] memory _conditionIds, uint64 _fee, uint initialFunding, address marketOwner)
        public
    {
         
        require(address(_pmSystem) != address(0) && _fee < FEE_RANGE);
        pmSystem = _pmSystem;
        collateralToken = _collateralToken;
        conditionIds = _conditionIds;
        fee = _fee;

        atomicOutcomeSlotCount = 1;
        for (uint i = 0; i < conditionIds.length; i++) {
            atomicOutcomeSlotCount *= pmSystem.getOutcomeSlotCount(conditionIds[i]);
        }
        require(atomicOutcomeSlotCount > 1, "conditions must be valid");

        require(collateralToken.transferFrom(marketOwner, address(this), initialFunding) && collateralToken.approve(address(pmSystem), initialFunding));

        splitPositionThroughAllConditions(initialFunding, conditionIds.length, 0);

        funding = initialFunding;

        stage = Stage.Running;
        emit AMMCreated(funding);
    }

    function calcNetCost(int[] memory outcomeTokenAmounts) public view returns (int netCost);

     
     
    function changeFunding(int fundingChange)
        public
        onlyOwner
        atStage(Stage.Paused)
    {
        require(fundingChange != 0, "A fundingChange of zero is not a fundingChange at all. It is unacceptable.");
         
        if (fundingChange > 0) {
            require(collateralToken.transferFrom(msg.sender, address(this), uint(fundingChange)) && collateralToken.approve(address(pmSystem), uint(fundingChange)));
            splitPositionThroughAllConditions(uint(fundingChange), conditionIds.length, 0);
            funding = funding.add(uint(fundingChange));
            emit AMMFundingChanged(fundingChange);
        }
        if (fundingChange < 0) {
            mergePositionsThroughAllConditions(uint(-fundingChange), conditionIds.length, 0);
            funding = funding.sub(uint(-fundingChange));
            require(collateralToken.transfer(owner(), uint(-fundingChange)));
            emit AMMFundingChanged(fundingChange);
        }
    }

    function pause() public onlyOwner atStage(Stage.Running) {
        stage = Stage.Paused;
        emit AMMPaused();
    }
    
    function resume() public onlyOwner atStage(Stage.Paused) {
        stage = Stage.Running;
        emit AMMResumed();
    }

    function changeFee(uint64 _fee) public onlyOwner atStage(Stage.Paused) {
        fee = _fee;
        emit AMMFeeChanged(fee);
    }

     
    function close()
        public
        onlyOwner
    {
        require(stage == Stage.Running || stage == Stage.Paused, "This Market has already been closed");
        for (uint i = 0; i < atomicOutcomeSlotCount; i++) {
            uint positionId = generateAtomicPositionId(i);
            pmSystem.safeTransferFrom(address(this), owner(), positionId, pmSystem.balanceOf(address(this), positionId), "");
        }
        stage = Stage.Closed;
        emit AMMClosed();
    }

     
     
    function withdrawFees()
        public
        onlyOwner
        returns (uint fees)
    {
        fees = collateralToken.balanceOf(address(this));
         
        require(collateralToken.transfer(owner(), fees));
        emit AMMFeeWithdrawal(fees);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function trade(int[] memory outcomeTokenAmounts, int collateralLimit)
        public
        atStage(Stage.Running)
        returns (int netCost)
    {
        require(outcomeTokenAmounts.length == atomicOutcomeSlotCount);

         
        int outcomeTokenNetCost = calcNetCost(outcomeTokenAmounts);
        int fees;
        if(outcomeTokenNetCost < 0)
            fees = int(calcMarketFee(uint(-outcomeTokenNetCost)));
        else
            fees = int(calcMarketFee(uint(outcomeTokenNetCost)));

        require(fees >= 0);
        netCost = outcomeTokenNetCost.add(fees);

        require(
            (collateralLimit != 0 && netCost <= collateralLimit) ||
            collateralLimit == 0
        );

        if(outcomeTokenNetCost > 0) {
            require(
                collateralToken.transferFrom(msg.sender, address(this), uint(netCost)) &&
                collateralToken.approve(address(pmSystem), uint(outcomeTokenNetCost))
            );

            splitPositionThroughAllConditions(uint(outcomeTokenNetCost), conditionIds.length, 0);
        }

        for (uint i = 0; i < atomicOutcomeSlotCount; i++) {
            if(outcomeTokenAmounts[i] != 0) {
                uint positionId = generateAtomicPositionId(i);
                if(outcomeTokenAmounts[i] < 0) {
                    pmSystem.safeTransferFrom(msg.sender, address(this), positionId, uint(-outcomeTokenAmounts[i]), "");
                } else {
                    pmSystem.safeTransferFrom(address(this), msg.sender, positionId, uint(outcomeTokenAmounts[i]), "");
                }

            }
        }

        if(outcomeTokenNetCost < 0) {
             
             
             
            mergePositionsThroughAllConditions(uint(-outcomeTokenNetCost), conditionIds.length, 0);
            if(netCost < 0) {
                require(collateralToken.transfer(msg.sender, uint(-netCost)));
            }
        }

        emit AMMOutcomeTokenTrade(msg.sender, outcomeTokenAmounts, outcomeTokenNetCost, uint(fees));
    }

     
     
     
    function calcMarketFee(uint outcomeTokenCost)
        public
        view
        returns (uint)
    {
        return outcomeTokenCost * fee / FEE_RANGE;
    }

    function onERC1155Received(address operator, address  , uint256  , uint256  , bytes calldata  ) external returns(bytes4) {
        if (operator == address(this)) {
            return 0xf23a6e61;
        }
        return 0x0;
    }

    function onERC1155BatchReceived(address _operator, address  , uint256[] calldata  , uint256[] calldata  , bytes calldata  ) external returns(bytes4) {
        if (_operator == address(this)) {
            return 0xf23a6e61;
        }
        return 0x0;
    }

    function generateBasicPartition(bytes32 conditionId)
        private
        view
        returns (uint[] memory partition)
    {
        partition = new uint[](pmSystem.getOutcomeSlotCount(conditionId));
        for(uint i = 0; i < partition.length; i++) {
            partition[i] = 1 << i;
        }
    }

    function generateAtomicPositionId(uint i)
        internal
        view
        returns (uint)
    {
        uint collectionId = 0;

        for(uint k = 0; k < conditionIds.length; k++) {
            uint curOutcomeSlotCount = pmSystem.getOutcomeSlotCount(conditionIds[k]);
            collectionId += uint(keccak256(abi.encodePacked(
                conditionIds[k],
                1 << (i % curOutcomeSlotCount))));
            i /= curOutcomeSlotCount;
        }
        return uint(keccak256(abi.encodePacked(
            collateralToken,
            collectionId)));
    }

    function splitPositionThroughAllConditions(uint amount, uint conditionsLeft, uint parentCollectionId)
        private
    {
        if(conditionsLeft == 0) return;
        conditionsLeft--;

        uint[] memory partition = generateBasicPartition(conditionIds[conditionsLeft]);
        pmSystem.splitPosition(collateralToken, bytes32(parentCollectionId), conditionIds[conditionsLeft], partition, amount);
        for(uint i = 0; i < partition.length; i++) {
            splitPositionThroughAllConditions(
                amount,
                conditionsLeft,
                parentCollectionId + uint(keccak256(abi.encodePacked(
                    conditionIds[conditionsLeft],
                    partition[i]))));
        }
    }

    function mergePositionsThroughAllConditions(uint amount, uint conditionsLeft, uint parentCollectionId)
        private
    {
        if(conditionsLeft == 0) return;
        conditionsLeft--;

        uint[] memory partition = generateBasicPartition(conditionIds[conditionsLeft]);
        for(uint i = 0; i < partition.length; i++) {
            mergePositionsThroughAllConditions(
                amount,
                conditionsLeft,
                parentCollectionId + uint(keccak256(abi.encodePacked(
                    conditionIds[conditionsLeft],
                    partition[i]))));
        }
        pmSystem.mergePositions(collateralToken, bytes32(parentCollectionId), conditionIds[conditionsLeft], partition, amount);
    }
}

 

pragma solidity ^0.5.1;





 
 
contract LMSRMarketMaker is MarketMaker {
    using SafeMath for uint;

     
    uint constant ONE = 0x10000000000000000;
    int constant EXP_LIMIT = 3394200909562557497344;

    constructor(PredictionMarketSystem _pmSystem, IERC20 _collateralToken, bytes32[] memory _conditionIds, uint64 _fee, uint _funding, address marketOwner)
        public
        MarketMaker(_pmSystem, _collateralToken, _conditionIds, _fee, _funding, marketOwner) {}


     
     
     
    function calcNetCost(int[] memory outcomeTokenAmounts)
        public
        view
        returns (int netCost)
    {
        require(outcomeTokenAmounts.length == atomicOutcomeSlotCount);

        int[] memory otExpNums = new int[](atomicOutcomeSlotCount);
        for (uint i = 0; i < atomicOutcomeSlotCount; i++) {
            int balance = int(pmSystem.balanceOf(address(this), generateAtomicPositionId(i)));
            require(balance >= 0);
            otExpNums[i] = outcomeTokenAmounts[i].sub(balance);
        }

        int log2N = Fixed192x64Math.binaryLog(atomicOutcomeSlotCount * ONE, Fixed192x64Math.EstimationMode.UpperBound);

        (uint sum, int offset, ) = sumExpOffset(log2N, otExpNums, 0, Fixed192x64Math.EstimationMode.UpperBound);
        netCost = Fixed192x64Math.binaryLog(sum, Fixed192x64Math.EstimationMode.UpperBound);
        netCost = netCost.add(offset);
        netCost = (netCost.mul(int(ONE)) / log2N).mul(int(funding));

         
         
        if(netCost <= 0 || netCost / int(ONE) * int(ONE) == netCost) {
            netCost /= int(ONE);
        } else {
            netCost = netCost / int(ONE) + 1;
        }
    }

     
     
     
    function calcMarginalPrice(uint8 outcomeTokenIndex)
        public
        view
        returns (uint price)
    {
        int[] memory negOutcomeTokenBalances = new int[](atomicOutcomeSlotCount);
        for (uint i = 0; i < atomicOutcomeSlotCount; i++) {
            int negBalance = -int(pmSystem.balanceOf(address(this), generateAtomicPositionId(i)));
            require(negBalance <= 0);
            negOutcomeTokenBalances[i] = negBalance;
        }

        int log2N = Fixed192x64Math.binaryLog(negOutcomeTokenBalances.length * ONE, Fixed192x64Math.EstimationMode.Midpoint);
         
         
         
        (uint sum, , uint outcomeExpTerm) = sumExpOffset(log2N, negOutcomeTokenBalances, outcomeTokenIndex, Fixed192x64Math.EstimationMode.Midpoint);
        return outcomeExpTerm / (sum / ONE);
    }

     
     
     
     
     
     
     
    function sumExpOffset(int log2N, int[] memory otExpNums, uint8 outcomeIndex, Fixed192x64Math.EstimationMode estimationMode)
        private
        view
        returns (uint sum, int offset, uint outcomeExpTerm)
    {
         
         
         

         
         
         
         
         
         

         
         
         

        require(log2N >= 0 && int(funding) >= 0);
        offset = Fixed192x64Math.max(otExpNums);
        offset = offset.mul(log2N) / int(funding);
        offset = offset.sub(EXP_LIMIT);
        uint term;
        for (uint8 i = 0; i < otExpNums.length; i++) {
            term = Fixed192x64Math.pow2((otExpNums[i].mul(log2N) / int(funding)).sub(offset), estimationMode);
            if (i == outcomeIndex)
                outcomeExpTerm = term;
            sum = sum.add(term);
        }
    }
}

 

pragma solidity ^0.5.1;


contract LMSRMarketMakerFactory {
    event LMSRMarketMakerCreation(address indexed creator, LMSRMarketMaker lmsrMarketMaker, PredictionMarketSystem pmSystem, IERC20 collateralToken, bytes32[] conditionIds, uint64 fee, uint funding);

    function createLMSRMarketMaker(PredictionMarketSystem pmSystem, IERC20 collateralToken, bytes32[] memory conditionIds, uint64 fee, uint funding)
        public
        returns (LMSRMarketMaker lmsrMarketMaker)
    {
        lmsrMarketMaker = new LMSRMarketMaker(pmSystem, collateralToken, conditionIds, fee, funding, msg.sender);
        lmsrMarketMaker.transferOwnership(msg.sender);
        emit LMSRMarketMakerCreation(msg.sender, lmsrMarketMaker, pmSystem, collateralToken, conditionIds, fee, funding);
    }
}