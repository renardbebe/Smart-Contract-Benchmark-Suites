 

pragma solidity 0.5.0;

library UniformRandomNumber {
   
   
   
   
   
  function uniform(uint256 _entropy, uint256 _upperBound) internal pure returns (uint256) {
    uint256 min = -_upperBound % _upperBound;
    uint256 random = _entropy;
    while (true) {
      if (random >= min) {
        break;
      }
      random = uint256(keccak256(abi.encodePacked(random)));
    }
    return random % _upperBound;
  }
}

contract ICErc20 {
    address public underlying;
    function mint(uint mintAmount) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getCash() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
}


 
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







 
contract Initializable {

   
  bool private initialized;

   
  bool private initializing;

   
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

   
  function isConstructor() private view returns (bool) {
     
     
     
     
     
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

   
  uint256[50] private ______gap;
}


 
contract Ownable is Initializable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function initialize(address sender) public initializer {
        _owner = sender;
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

    uint256[50] private ______gap;
}

 



 
library SortitionSumTreeFactory {
     

    struct SortitionSumTree {
        uint K;  
         
        uint[] stack;
        uint[] nodes;
         
        mapping(bytes32 => uint) IDsToNodeIndexes;
        mapping(uint => bytes32) nodeIndexesToIDs;
    }

     

    struct SortitionSumTrees {
        mapping(bytes32 => SortitionSumTree) sortitionSumTrees;
    }

     

     
    function createTree(SortitionSumTrees storage self, bytes32 _key, uint _K) public {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        require(tree.K == 0, "Tree already exists.");
        require(_K > 1, "K must be greater than one.");
        tree.K = _K;
        tree.stack.length = 0;
        tree.nodes.length = 0;
        tree.nodes.push(0);
    }

     
    function set(SortitionSumTrees storage self, bytes32 _key, uint _value, bytes32 _ID) public {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) {  
            if (_value != 0) {  
                 
                 
                if (tree.stack.length == 0) {  
                     
                    treeIndex = tree.nodes.length;
                    tree.nodes.push(_value);

                     
                    if (treeIndex != 1 && (treeIndex - 1) % tree.K == 0) {  
                        uint parentIndex = treeIndex / tree.K;
                        bytes32 parentID = tree.nodeIndexesToIDs[parentIndex];
                        uint newIndex = treeIndex + 1;
                        tree.nodes.push(tree.nodes[parentIndex]);
                        delete tree.nodeIndexesToIDs[parentIndex];
                        tree.IDsToNodeIndexes[parentID] = newIndex;
                        tree.nodeIndexesToIDs[newIndex] = parentID;
                    }
                } else {  
                     
                    treeIndex = tree.stack[tree.stack.length - 1];
                    tree.stack.length--;
                    tree.nodes[treeIndex] = _value;
                }

                 
                tree.IDsToNodeIndexes[_ID] = treeIndex;
                tree.nodeIndexesToIDs[treeIndex] = _ID;

                updateParents(self, _key, treeIndex, true, _value);
            }
        } else {  
            if (_value == 0) {  
                 
                 
                uint value = tree.nodes[treeIndex];
                tree.nodes[treeIndex] = 0;

                 
                tree.stack.push(treeIndex);

                 
                delete tree.IDsToNodeIndexes[_ID];
                delete tree.nodeIndexesToIDs[treeIndex];

                updateParents(self, _key, treeIndex, false, value);
            } else if (_value != tree.nodes[treeIndex]) {  
                 
                bool plusOrMinus = tree.nodes[treeIndex] <= _value;
                uint plusOrMinusValue = plusOrMinus ? _value - tree.nodes[treeIndex] : tree.nodes[treeIndex] - _value;
                tree.nodes[treeIndex] = _value;

                updateParents(self, _key, treeIndex, plusOrMinus, plusOrMinusValue);
            }
        }
    }

     

     
    function queryLeafs(
        SortitionSumTrees storage self,
        bytes32 _key,
        uint _cursor,
        uint _count
    ) public view returns(uint startIndex, uint[] memory values, bool hasMore) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

         
        for (uint i = 0; i < tree.nodes.length; i++) {
            if ((tree.K * i) + 1 >= tree.nodes.length) {
                startIndex = i;
                break;
            }
        }

         
        uint loopStartIndex = startIndex + _cursor;
        values = new uint[](loopStartIndex + _count > tree.nodes.length ? tree.nodes.length - loopStartIndex : _count);
        uint valuesIndex = 0;
        for (uint j = loopStartIndex; j < tree.nodes.length; j++) {
            if (valuesIndex < _count) {
                values[valuesIndex] = tree.nodes[j];
                valuesIndex++;
            } else {
                hasMore = true;
                break;
            }
        }
    }

     
    function draw(SortitionSumTrees storage self, bytes32 _key, uint _drawnNumber) public view returns(bytes32 ID) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = 0;
        uint currentDrawnNumber = _drawnNumber % tree.nodes[0];

        while ((tree.K * treeIndex) + 1 < tree.nodes.length)   
            for (uint i = 1; i <= tree.K; i++) {  
                uint nodeIndex = (tree.K * treeIndex) + i;
                uint nodeValue = tree.nodes[nodeIndex];

                if (currentDrawnNumber >= nodeValue) currentDrawnNumber -= nodeValue;  
                else {  
                    treeIndex = nodeIndex;
                    break;
                }
            }
        
        ID = tree.nodeIndexesToIDs[treeIndex];
    }

     
    function stakeOf(SortitionSumTrees storage self, bytes32 _key, bytes32 _ID) public view returns(uint value) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) value = 0;
        else value = tree.nodes[treeIndex];
    }

     

     
    function updateParents(SortitionSumTrees storage self, bytes32 _key, uint _treeIndex, bool _plusOrMinus, uint _value) private {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        uint parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus ? tree.nodes[parentIndex] + _value : tree.nodes[parentIndex] - _value;
        }
    }
}





 
library FixidityLib {

     
    function digits() public pure returns(uint8) {
        return 24;
    }
    
     
    function fixed1() public pure returns(int256) {
        return 1000000000000000000000000;
    }

     
    function mulPrecision() public pure returns(int256) {
        return 1000000000000;
    }

     
    function maxInt256() public pure returns(int256) {
        return 57896044618658097711785492504343953926634992332820282019728792003956564819967;
    }

     
    function minInt256() public pure returns(int256) {
        return -57896044618658097711785492504343953926634992332820282019728792003956564819968;
    }

     
    function maxNewFixed() public pure returns(int256) {
        return 57896044618658097711785492504343953926634992332820282;
    }

     
    function minNewFixed() public pure returns(int256) {
        return -57896044618658097711785492504343953926634992332820282;
    }

     
    function maxFixedAdd() public pure returns(int256) {
        return 28948022309329048855892746252171976963317496166410141009864396001978282409983;
    }

     
    function maxFixedSub() public pure returns(int256) {
        return -28948022309329048855892746252171976963317496166410141009864396001978282409984;
    }

     
    function maxFixedMul() public pure returns(int256) {
        return 240615969168004498257251713877715648331380787511296;
    }

     
    function maxFixedDiv() public pure returns(int256) {
        return 57896044618658097711785492504343953926634992332820282;
    }

     
    function maxFixedDivisor() public pure returns(int256) {
        return 1000000000000000000000000000000000000000000000000;
    }

     
    function newFixed(int256 x)
        public
        pure
        returns (int256)
    {
        assert(x <= maxNewFixed());
        assert(x >= minNewFixed());
        return x * fixed1();
    }

     
    function fromFixed(int256 x)
        public
        pure
        returns (int256)
    {
        return x / fixed1();
    }

     
    function convertFixed(int256 x, uint8 _originDigits, uint8 _destinationDigits)
        public
        pure
        returns (int256)
    {
        assert(_originDigits <= 38 && _destinationDigits <= 38);
        
        uint8 decimalDifference;
        if ( _originDigits > _destinationDigits ){
            decimalDifference = _originDigits - _destinationDigits;
            return x/(uint128(10)**uint128(decimalDifference));
        }
        else if ( _originDigits < _destinationDigits ){
            decimalDifference = _destinationDigits - _originDigits;
             
             
             
             
             
             
            assert(x <= maxInt256()/uint128(10)**uint128(decimalDifference));
            assert(x >= minInt256()/uint128(10)**uint128(decimalDifference));
            return x*(uint128(10)**uint128(decimalDifference));
        }
         
        return x;
    }

     
    function newFixed(int256 x, uint8 _originDigits)
        public
        pure
        returns (int256)
    {
        return convertFixed(x, _originDigits, digits());
    }

     
    function fromFixed(int256 x, uint8 _destinationDigits)
        public
        pure
        returns (int256)
    {
        return convertFixed(x, digits(), _destinationDigits);
    }

     
    function newFixedFraction(
        int256 numerator, 
        int256 denominator
        )
        public
        pure
        returns (int256)
    {
        assert(numerator <= maxNewFixed());
        assert(denominator <= maxNewFixed());
        assert(denominator != 0);
        int256 convertedNumerator = newFixed(numerator);
        int256 convertedDenominator = newFixed(denominator);
        return divide(convertedNumerator, convertedDenominator);
    }

     
    function integer(int256 x) public pure returns (int256) {
        return (x / fixed1()) * fixed1();  
    }

     
    function fractional(int256 x) public pure returns (int256) {
        return x - (x / fixed1()) * fixed1();  
    }

     
    function abs(int256 x) public pure returns (int256) {
        if (x >= 0) {
            return x;
        } else {
            int256 result = -x;
            assert (result > 0);
            return result;
        }
    }

     
    function add(int256 x, int256 y) public pure returns (int256) {
        int256 z = x + y;
        if (x > 0 && y > 0) assert(z > x && z > y);
        if (x < 0 && y < 0) assert(z < x && z < y);
        return z;
    }

     
    function subtract(int256 x, int256 y) public pure returns (int256) {
        return add(x,-y);
    }

     
    function multiply(int256 x, int256 y) public pure returns (int256) {
        if (x == 0 || y == 0) return 0;
        if (y == fixed1()) return x;
        if (x == fixed1()) return y;

         
         
        int256 x1 = integer(x) / fixed1();
        int256 x2 = fractional(x);
        int256 y1 = integer(y) / fixed1();
        int256 y2 = fractional(y);
        
         
        int256 x1y1 = x1 * y1;
        if (x1 != 0) assert(x1y1 / x1 == y1);  
        
         
         
        int256 fixed_x1y1 = x1y1 * fixed1();
        if (x1y1 != 0) assert(fixed_x1y1 / x1y1 == fixed1());  
        x1y1 = fixed_x1y1;

        int256 x2y1 = x2 * y1;
        if (x2 != 0) assert(x2y1 / x2 == y1);  

        int256 x1y2 = x1 * y2;
        if (x1 != 0) assert(x1y2 / x1 == y2);  

        x2 = x2 / mulPrecision();
        y2 = y2 / mulPrecision();
        int256 x2y2 = x2 * y2;
        if (x2 != 0) assert(x2y2 / x2 == y2);  

         
        int256 result = x1y1;
        result = add(result, x2y1);  
        result = add(result, x1y2);  
        result = add(result, x2y2);  
        return result;
    }
    
     
    function reciprocal(int256 x) public pure returns (int256) {
        assert(x != 0);
        return (fixed1()*fixed1()) / x;  
    }

     
    function divide(int256 x, int256 y) public pure returns (int256) {
        if (y == fixed1()) return x;
        assert(y != 0);
        assert(y <= maxFixedDivisor());
        return multiply(x, reciprocal(y));
    }
}


 
contract Pool is Ownable {
  using SafeMath for uint256;

   
  event BoughtTickets(address indexed sender, int256 count, uint256 totalPrice);

   
  event Withdrawn(address indexed sender, int256 amount);

   
  event PoolLocked();

   
  event PoolUnlocked();

   
  event PoolComplete(address indexed winner);

  enum State {
    OPEN,
    LOCKED,
    UNLOCKED,
    COMPLETE
  }

  struct Entry {
    address addr;
    int256 amount;
    uint256 ticketCount;
    int256 withdrawnNonFixed;
  }

  bytes32 public constant SUM_TREE_KEY = "PoolPool";

  int256 private totalAmount;  
  uint256 private lockStartBlock;
  uint256 private lockEndBlock;
  bytes32 private secretHash;
  bytes32 private secret;
  State public state;
  int256 private finalAmount;  
  mapping (address => Entry) private entries;
  uint256 public entryCount;
  ICErc20 public moneyMarket;
  IERC20 public token;
  int256 private ticketPrice;  
  int256 private feeFraction;  
  bool private ownerHasWithdrawn;
  bool public allowLockAnytime;

  using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;
  SortitionSumTreeFactory.SortitionSumTrees internal sortitionSumTrees;

   
  constructor (
    ICErc20 _moneyMarket,
    IERC20 _token,
    uint256 _lockStartBlock,
    uint256 _lockEndBlock,
    int256 _ticketPrice,
    int256 _feeFractionFixedPoint18,
    bool _allowLockAnytime
  ) public {
    require(_lockEndBlock > _lockStartBlock, "lock end block is not after start block");
    require(address(_moneyMarket) != address(0), "money market address cannot be zero");
    require(address(_token) != address(0), "token address cannot be zero");
    require(_ticketPrice > 0, "ticket price must be greater than zero");
    require(_feeFractionFixedPoint18 >= 0, "fee must be zero or greater");
    require(_feeFractionFixedPoint18 <= 1000000000000000000, "fee fraction must be less than 1");
    feeFraction = FixidityLib.newFixed(_feeFractionFixedPoint18, uint8(18));
    ticketPrice = FixidityLib.newFixed(_ticketPrice);
    sortitionSumTrees.createTree(SUM_TREE_KEY, 4);

    state = State.OPEN;
    moneyMarket = _moneyMarket;
    token = _token;
    lockStartBlock = _lockStartBlock;
    lockEndBlock = _lockEndBlock;
    allowLockAnytime = _allowLockAnytime;
  }

   
  function buyTickets (int256 _countNonFixed) public requireOpen {
    require(_countNonFixed > 0, "number of tickets is less than or equal to zero");
    int256 count = FixidityLib.newFixed(_countNonFixed);
    int256 totalDeposit = FixidityLib.multiply(ticketPrice, count);
    uint256 totalDepositNonFixed = uint256(FixidityLib.fromFixed(totalDeposit));
    require(token.transferFrom(msg.sender, address(this), totalDepositNonFixed), "token transfer failed");

    if (_hasEntry(msg.sender)) {
      entries[msg.sender].amount = FixidityLib.add(entries[msg.sender].amount, totalDeposit);
      entries[msg.sender].ticketCount = entries[msg.sender].ticketCount.add(uint256(_countNonFixed));
    } else {
      entries[msg.sender] = Entry(
        msg.sender,
        totalDeposit,
        uint256(_countNonFixed),
        0
      );
      entryCount = entryCount.add(1);
    }

    int256 amountNonFixed = FixidityLib.fromFixed(entries[msg.sender].amount);
    sortitionSumTrees.set(SUM_TREE_KEY, uint256(amountNonFixed), bytes32(uint256(msg.sender)));

    totalAmount = FixidityLib.add(totalAmount, totalDeposit);

     
    require(totalAmount <= maxPoolSizeFixedPoint24(FixidityLib.maxFixedDiv()), "pool size exceeds maximum");

    emit BoughtTickets(msg.sender, _countNonFixed, totalDepositNonFixed);
  }

   
  function lock(bytes32 _secretHash) external requireOpen onlyOwner {
    if (allowLockAnytime) {
      lockStartBlock = block.number;
    } else {
      require(block.number >= lockStartBlock, "pool can only be locked on or after lock start block");
    }
    require(_secretHash != 0, "secret hash must be defined");
    secretHash = _secretHash;
    state = State.LOCKED;

    if (totalAmount > 0) {
      uint256 totalAmountNonFixed = uint256(FixidityLib.fromFixed(totalAmount));
      require(token.approve(address(moneyMarket), totalAmountNonFixed), "could not approve money market spend");
      require(moneyMarket.mint(totalAmountNonFixed) == 0, "could not supply money market");
    }

    emit PoolLocked();
  }

  function unlock() public requireLocked {
    if (allowLockAnytime && msg.sender == owner()) {
      lockEndBlock = block.number;
    } else {
      require(lockEndBlock < block.number, "pool cannot be unlocked yet");
    }

    uint256 balance = moneyMarket.balanceOfUnderlying(address(this));

    if (balance > 0) {
      require(moneyMarket.redeemUnderlying(balance) == 0, "could not redeem from compound");
      finalAmount = FixidityLib.newFixed(int256(balance));
    }

    state = State.UNLOCKED;

    emit PoolUnlocked();
  }

   
  function complete(bytes32 _secret) public onlyOwner {
    if (state == State.LOCKED) {
      unlock();
    }
    require(state == State.UNLOCKED, "state must be unlocked");
    require(keccak256(abi.encodePacked(_secret)) == secretHash, "secret does not match");
    secret = _secret;
    state = State.COMPLETE;

    uint256 fee = feeAmount();
    if (fee > 0) {
      require(token.transfer(owner(), fee), "could not transfer winnings");
    }

    emit PoolComplete(winnerAddress());
  }

   
  function withdraw() public {
    require(_hasEntry(msg.sender), "entrant exists");
    require(state == State.UNLOCKED || state == State.COMPLETE, "pool has not been unlocked");
    Entry storage entry = entries[msg.sender];
    int256 remainingBalanceNonFixed = balanceOf(msg.sender);
    require(remainingBalanceNonFixed > 0, "entrant has already withdrawn");
    entry.withdrawnNonFixed = entry.withdrawnNonFixed + remainingBalanceNonFixed;

    emit Withdrawn(msg.sender, remainingBalanceNonFixed);

    require(token.transfer(msg.sender, uint256(remainingBalanceNonFixed)), "could not transfer winnings");
  }

   
  function winnings(address _addr) public view returns (int256) {
    Entry storage entry = entries[_addr];
    if (entry.addr == address(0)) {  
      return 0;
    }
    int256 winningTotal = entry.amount;
    if (state == State.COMPLETE && _addr == winnerAddress()) {
      winningTotal = FixidityLib.add(winningTotal, netWinningsFixedPoint24());
    }
    return FixidityLib.fromFixed(winningTotal);
  }

   
  function balanceOf(address _addr) public view returns (int256) {
    Entry storage entry = entries[_addr];
    int256 winningTotalNonFixed = winnings(_addr);
    return winningTotalNonFixed - entry.withdrawnNonFixed;
  }

   
  function winnerAddress() public view returns (address) {
    if (totalAmount > 0) {
      return address(uint256(sortitionSumTrees.draw(SUM_TREE_KEY, randomToken())));
    } else {
      return address(0);
    }
  }

   
  function netWinnings() public view returns (int256) {
    return FixidityLib.fromFixed(netWinningsFixedPoint24());
  }

   
  function netWinningsFixedPoint24() internal view returns (int256) {
    return grossWinningsFixedPoint24() - feeAmountFixedPoint24();
  }

   
  function grossWinningsFixedPoint24() internal view returns (int256) {
    return FixidityLib.subtract(finalAmount, totalAmount);
  }

   
  function feeAmount() public view returns (uint256) {
    return uint256(FixidityLib.fromFixed(feeAmountFixedPoint24()));
  }

   
  function feeAmountFixedPoint24() internal view returns (int256) {
    return FixidityLib.multiply(grossWinningsFixedPoint24(), feeFraction);
  }

   
  function randomToken() public view returns (uint256) {
    if (block.number <= lockEndBlock) {
      return 0;
    } else {
      return _selectRandom(uint256(FixidityLib.fromFixed(totalAmount)));
    }
  }

   
  function _selectRandom(uint256 total) internal view returns (uint256) {
    return UniformRandomNumber.uniform(_entropy(), total);
  }

   
  function _entropy() internal view returns (uint256) {
    return uint256(blockhash(lockEndBlock) ^ secret);
  }

   
  function getInfo() public view returns (
    int256 entryTotal,
    uint256 startBlock,
    uint256 endBlock,
    State poolState,
    address winner,
    int256 supplyBalanceTotal,
    int256 ticketCost,
    uint256 participantCount,
    int256 maxPoolSize,
    int256 estimatedInterestFixedPoint18,
    bytes32 hashOfSecret
  ) {
    address winAddr = address(0);
    if (state == State.COMPLETE) {
      winAddr = winnerAddress();
    }
    return (
      FixidityLib.fromFixed(totalAmount),
      lockStartBlock,
      lockEndBlock,
      state,
      winAddr,
      FixidityLib.fromFixed(finalAmount),
      FixidityLib.fromFixed(ticketPrice),
      entryCount,
      FixidityLib.fromFixed(maxPoolSizeFixedPoint24(FixidityLib.maxFixedDiv())),
      FixidityLib.fromFixed(currentInterestFractionFixedPoint24(), uint8(18)),
      secretHash
    );
  }

   
  function getEntry(address _addr) public view returns (
    address addr,
    int256 amount,
    uint256 ticketCount,
    int256 withdrawn
  ) {
    Entry storage entry = entries[_addr];
    return (
      entry.addr,
      FixidityLib.fromFixed(entry.amount),
      entry.ticketCount,
      entry.withdrawnNonFixed
    );
  }

   
  function maxPoolSizeFixedPoint24(int256 _maxValueFixedPoint24) public view returns (int256) {
     
    int256 interestFraction = FixidityLib.multiply(currentInterestFractionFixedPoint24(), FixidityLib.newFixed(2));
    return FixidityLib.divide(_maxValueFixedPoint24, FixidityLib.add(interestFraction, FixidityLib.newFixed(1)));
  }

   
  function currentInterestFractionFixedPoint24() public view returns (int256) {
    int256 blockDuration = int256(lockEndBlock - lockStartBlock);
    int256 supplyRateMantissaFixedPoint24 = FixidityLib.newFixed(int256(supplyRateMantissa()), uint8(18));
    return FixidityLib.multiply(supplyRateMantissaFixedPoint24, FixidityLib.newFixed(blockDuration));
  }

   
  function supplyRateMantissa() public view returns (uint256) {
    return moneyMarket.supplyRatePerBlock();
  }

   
  function _hasEntry(address _addr) internal view returns (bool) {
    return entries[_addr].addr == _addr;
  }

  modifier requireOpen() {
    require(state == State.OPEN, "state is not open");
    _;
  }

  modifier requireLocked() {
    require(state == State.LOCKED, "state is not locked");
    _;
  }

  modifier requireComplete() {
    require(state == State.COMPLETE, "pool is not complete");
    require(block.number > lockEndBlock, "block is before lock end period");
    _;
  }
}