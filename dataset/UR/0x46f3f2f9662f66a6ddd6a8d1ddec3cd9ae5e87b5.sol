 

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 

pragma solidity ^0.5.5;

 
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

 

pragma solidity ^0.5.0;




 
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;





 
contract EpochTokenLocker {
    using SafeMath for uint256;

     
    uint32 public constant BATCH_TIME = 300;

     
    mapping(address => mapping(address => BalanceState)) private balanceStates;

     
    mapping(address => mapping(address => uint256)) public lastCreditBatchId;

    struct BalanceState {
        uint256 balance;
        PendingFlux pendingDeposits;  
        PendingFlux pendingWithdraws;  
    }

    struct PendingFlux {
        uint256 amount;
        uint32 batchId;
    }

    event Deposit(address user, address token, uint256 amount, uint256 stateIndex);

    event WithdrawRequest(address user, address token, uint256 amount, uint256 stateIndex);

    event Withdraw(address user, address token, uint256 amount);

     
    function deposit(address token, uint256 amount) public {
        updateDepositsBalance(msg.sender, token);
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
         
        balanceStates[msg.sender][token].pendingDeposits.amount = balanceStates[msg.sender][token].pendingDeposits.amount.add(
            amount
        );
        balanceStates[msg.sender][token].pendingDeposits.batchId = getCurrentBatchId();
        emit Deposit(msg.sender, token, amount, getCurrentBatchId());
    }

     
    function requestWithdraw(address token, uint256 amount) public {
        requestFutureWithdraw(token, amount, getCurrentBatchId());
    }

     
    function requestFutureWithdraw(address token, uint256 amount, uint32 batchId) public {
         
        if (hasValidWithdrawRequest(msg.sender, token)) {
            withdraw(msg.sender, token);
        }
        require(batchId >= getCurrentBatchId(), "Request cannot be made in the past");
        balanceStates[msg.sender][token].pendingWithdraws = PendingFlux({amount: amount, batchId: batchId});
        emit WithdrawRequest(msg.sender, token, amount, batchId);
    }

     
    function withdraw(address user, address token) public {
        updateDepositsBalance(user, token);  
        require(
            balanceStates[user][token].pendingWithdraws.batchId < getCurrentBatchId(),
            "withdraw was not registered previously"
        );
        require(
            lastCreditBatchId[msg.sender][token] < getCurrentBatchId(),
            "Withdraw not possible for token that is traded in the current auction"
        );
        uint256 amount = Math.min(balanceStates[user][token].balance, balanceStates[msg.sender][token].pendingWithdraws.amount);

        balanceStates[user][token].balance = balanceStates[user][token].balance.sub(amount);
        delete balanceStates[user][token].pendingWithdraws;

        SafeERC20.safeTransfer(IERC20(token), user, amount);
        emit Withdraw(user, token, amount);
    }
     

     
    function getPendingDeposit(address user, address token) public view returns (uint256, uint256) {
        PendingFlux memory pendingDeposit = balanceStates[user][token].pendingDeposits;
        return (pendingDeposit.amount, pendingDeposit.batchId);
    }

     
    function getPendingWithdraw(address user, address token) public view returns (uint256, uint256) {
        PendingFlux memory pendingWithdraw = balanceStates[user][token].pendingWithdraws;
        return (pendingWithdraw.amount, pendingWithdraw.batchId);
    }

     
    function getCurrentBatchId() public view returns (uint32) {
        return uint32(now / BATCH_TIME);
    }

     
    function getSecondsRemainingInBatch() public view returns (uint256) {
        return BATCH_TIME - (now % BATCH_TIME);
    }

     
    function getBalance(address user, address token) public view returns (uint256) {
        uint256 balance = balanceStates[user][token].balance;
        if (balanceStates[user][token].pendingDeposits.batchId < getCurrentBatchId()) {
            balance = balance.add(balanceStates[user][token].pendingDeposits.amount);
        }
        if (balanceStates[user][token].pendingWithdraws.batchId < getCurrentBatchId()) {
            balance = balance.sub(Math.min(balanceStates[user][token].pendingWithdraws.amount, balance));
        }
        return balance;
    }

     
    function hasValidWithdrawRequest(address user, address token) public view returns (bool) {
        return
            balanceStates[user][token].pendingWithdraws.batchId < getCurrentBatchId() &&
            balanceStates[user][token].pendingWithdraws.batchId > 0;
    }

     
     
    function addBalanceAndBlockWithdrawForThisBatch(address user, address token, uint256 amount) internal {
        if (hasValidWithdrawRequest(user, token)) {
            lastCreditBatchId[user][token] = getCurrentBatchId();
        }
        addBalance(user, token, amount);
    }

    function addBalance(address user, address token, uint256 amount) internal {
        updateDepositsBalance(user, token);
        balanceStates[user][token].balance = balanceStates[user][token].balance.add(amount);
    }

    function subtractBalance(address user, address token, uint256 amount) internal {
        updateDepositsBalance(user, token);
        balanceStates[user][token].balance = balanceStates[user][token].balance.sub(amount);
    }

    function updateDepositsBalance(address user, address token) private {
        if (balanceStates[user][token].pendingDeposits.batchId < getCurrentBatchId()) {
            balanceStates[user][token].balance = balanceStates[user][token].balance.add(
                balanceStates[user][token].pendingDeposits.amount
            );
            delete balanceStates[user][token].pendingDeposits;
        }
    }
}

 

pragma solidity ^0.5.0;


library IdToAddressBiMap {
    struct Data {
        mapping(uint16 => address) idToAddress;
        mapping(address => uint16) addressToId;
    }

    function hasId(Data storage self, uint16 id) public view returns (bool) {
        return self.idToAddress[id + 1] != address(0);
    }

    function hasAddress(Data storage self, address addr) public view returns (bool) {
        return self.addressToId[addr] != 0;
    }

    function getAddressAt(Data storage self, uint16 id) public view returns (address) {
        require(hasId(self, id), "Must have ID to get Address");
        return self.idToAddress[id + 1];
    }

    function getId(Data storage self, address addr) public view returns (uint16) {
        require(hasAddress(self, addr), "Must have Address to get ID");
        return self.addressToId[addr] - 1;
    }

    function insert(Data storage self, uint16 id, address addr) public returns (bool) {
         
        if (self.addressToId[addr] != 0 || self.idToAddress[id + 1] != address(0)) {
            return false;
        }
        self.idToAddress[id + 1] = addr;
        self.addressToId[addr] = id + 1;
        return true;
    }

}

 

pragma solidity ^0.5.0;


library IterableAppendOnlySet {
    struct Data {
        mapping(address => address) nextMap;
        address last;
    }

    function insert(Data storage self, address value) public returns (bool) {
        if (contains(self, value)) {
            return false;
        }
        self.nextMap[self.last] = value;
        self.last = value;
        return true;
    }

    function contains(Data storage self, address value) public view returns (bool) {
        require(value != address(0), "Inserting address(0) is not supported");
        return self.nextMap[value] != address(0) || (self.last == value);
    }

    function first(Data storage self) public view returns (address) {
        require(self.last != address(0), "Trying to get first from empty set");
        return self.nextMap[address(0)];
    }

    function next(Data storage self, address value) public view returns (address) {
        require(contains(self, value), "Trying to get next of non-existent element");
        require(value != self.last, "Trying to get next of last element");
        return self.nextMap[value];
    }

    function size(Data storage self) public view returns (uint256) {
        if (self.last == address(0)) {
            return 0;
        }
        uint256 count = 1;
        address current = first(self);
        while (current != self.last) {
            current = next(self, current);
            count++;
        }
        return count;
    }
}

 

pragma solidity ^0.5.2;

 
 
 
library GnosisMath {
     
     
    uint public constant ONE = 0x10000000000000000;
    uint public constant LN2 = 0xb17217f7d1cf79ac;
    uint public constant LOG2_E = 0x171547652b82fe177;

     
     
     
     
    function exp(int x) public pure returns (uint) {
         
         
        require(x <= 2454971259878909886679);
         
         
        if (x < -818323753292969962227) return 0;
         
        x = x * int(ONE) / int(LN2);
         
         
         
        int shift;
        uint z;
        if (x >= 0) {
            shift = x / int(ONE);
            z = uint(x % int(ONE));
        } else {
            shift = x / int(ONE) - 1;
            z = ONE - uint(-x % int(ONE));
        }
         
         
         
         
         
         
         
         
         
         
         
         
         
        uint zpow = z;
        uint result = ONE;
        result += 0xb17217f7d1cf79ab * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x3d7f7bff058b1d50 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xe35846b82505fc5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x276556df749cee5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x5761ff9e299cc4 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xa184897c363c3 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xffe5fe2c4586 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x162c0223a5c8 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1b5253d395e * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1e4cf5158b * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1e8cac735 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1c3bd650 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1816193 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x131496 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xe1b7 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x9c7 * zpow / ONE;
        if (shift >= 0) {
            if (result >> (256 - shift) > 0) return (2 ** 256 - 1);
            return result << shift;
        } else return result >> (-shift);
    }

     
     
     
    function ln(uint x) public pure returns (int) {
        require(x > 0);
         
        int ilog2 = floorLog2(x);
        int z;
        if (ilog2 < 0) z = int(x << uint(-ilog2));
        else z = int(x >> uint(ilog2));
         
         
         
         
         
        int term = (z - int(ONE)) * int(ONE) / (z + int(ONE));
        int halflnz = term;
        int termpow = term * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 3;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 5;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 7;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 9;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 11;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 13;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 15;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 17;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 19;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 21;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 23;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 25;
        return (ilog2 * int(ONE)) * int(ONE) / int(LOG2_E) + 2 * halflnz;
    }

     
     
     
    function floorLog2(uint x) public pure returns (int lo) {
        lo = -64;
        int hi = 193;
         
        int mid = (hi + lo) >> 1;
        while ((lo + 1) < hi) {
            if (mid < 0 && x << uint(-mid) < ONE || mid >= 0 && x >> uint(mid) < ONE) hi = mid;
            else lo = mid;
            mid = (hi + lo) >> 1;
        }
    }

     
     
     
    function max(int[] memory nums) public pure returns (int maxNum) {
        require(nums.length > 0);
        maxNum = -2 ** 255;
        for (uint i = 0; i < nums.length; i++) if (nums[i] > maxNum) maxNum = nums[i];
    }

     
     
     
     
    function safeToAdd(uint a, uint b) internal pure returns (bool) {
        return a + b >= a;
    }

     
     
     
     
    function safeToSub(uint a, uint b) internal pure returns (bool) {
        return a >= b;
    }

     
     
     
     
    function safeToMul(uint a, uint b) internal pure returns (bool) {
        return b == 0 || a * b / b == a;
    }

     
     
     
     
    function add(uint a, uint b) internal pure returns (uint) {
        require(safeToAdd(a, b));
        return a + b;
    }

     
     
     
     
    function sub(uint a, uint b) internal pure returns (uint) {
        require(safeToSub(a, b));
        return a - b;
    }

     
     
     
     
    function mul(uint a, uint b) internal pure returns (uint) {
        require(safeToMul(a, b));
        return a * b;
    }

     
     
     
     
    function safeToAdd(int a, int b) internal pure returns (bool) {
        return (b >= 0 && a + b >= a) || (b < 0 && a + b < a);
    }

     
     
     
     
    function safeToSub(int a, int b) internal pure returns (bool) {
        return (b >= 0 && a - b <= a) || (b < 0 && a - b > a);
    }

     
     
     
     
    function safeToMul(int a, int b) internal pure returns (bool) {
        return (b == 0) || (a * b / b == a);
    }

     
     
     
     
    function add(int a, int b) internal pure returns (int) {
        require(safeToAdd(a, b));
        return a + b;
    }

     
     
     
     
    function sub(int a, int b) internal pure returns (int) {
        require(safeToSub(a, b));
        return a - b;
    }

     
     
     
     
    function mul(int a, int b) internal pure returns (int) {
        require(safeToMul(a, b));
        return a * b;
    }
}

 

 
pragma solidity ^0.5.2;

 
contract Token {
     
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

     
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    function balanceOf(address owner) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);
    function totalSupply() public view returns (uint);
}

 

pragma solidity ^0.5.2;

 
 
contract Proxied {
    address public masterCopy;
}

 
 
contract Proxy is Proxied {
     
     
    constructor(address _masterCopy) public {
        require(_masterCopy != address(0), "The master copy is required");
        masterCopy = _masterCopy;
    }

     
    function() external payable {
        address _masterCopy = masterCopy;
        assembly {
            calldatacopy(0, 0, calldatasize)
            let success := delegatecall(not(0), _masterCopy, 0, calldatasize, 0, 0)
            returndatacopy(0, 0, returndatasize)
            switch success
                case 0 {
                    revert(0, returndatasize)
                }
                default {
                    return(0, returndatasize)
                }
        }
    }
}

 

pragma solidity ^0.5.2;




 
contract StandardTokenData {
     
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    uint totalTokens;
}

 
 
contract GnosisStandardToken is Token, StandardTokenData {
    using GnosisMath for *;

     
     
     
     
     
    function transfer(address to, uint value) public returns (bool) {
        if (!balances[msg.sender].safeToSub(value) || !balances[to].safeToAdd(value)) {
            return false;
        }

        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint value) public returns (bool) {
        if (!balances[from].safeToSub(value) || !allowances[from][msg.sender].safeToSub(
            value
        ) || !balances[to].safeToAdd(value)) {
            return false;
        }
        balances[from] -= value;
        allowances[from][msg.sender] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

     
     
     
     
    function approve(address spender, uint value) public returns (bool) {
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
     
     
     
    function allowance(address owner, address spender) public view returns (uint) {
        return allowances[owner][spender];
    }

     
     
     
    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }

     
     
    function totalSupply() public view returns (uint) {
        return totalTokens;
    }
}

 

pragma solidity ^0.5.2;




contract TokenOWL is Proxied, GnosisStandardToken {
    using GnosisMath for *;

    string public constant name = "OWL Token";
    string public constant symbol = "OWL";
    uint8 public constant decimals = 18;

    struct masterCopyCountdownType {
        address masterCopy;
        uint timeWhenAvailable;
    }

    masterCopyCountdownType masterCopyCountdown;

    address public creator;
    address public minter;

    event Minted(address indexed to, uint256 amount);
    event Burnt(address indexed from, address indexed user, uint256 amount);

    modifier onlyCreator() {
         
        require(msg.sender == creator, "Only the creator can perform the transaction");
        _;
    }
     
     
    function startMasterCopyCountdown(address _masterCopy) public onlyCreator {
        require(address(_masterCopy) != address(0), "The master copy must be a valid address");

         
        masterCopyCountdown.masterCopy = _masterCopy;
        masterCopyCountdown.timeWhenAvailable = now + 30 days;
    }

     
    function updateMasterCopy() public onlyCreator {
        require(address(masterCopyCountdown.masterCopy) != address(0), "The master copy must be a valid address");
        require(
            block.timestamp >= masterCopyCountdown.timeWhenAvailable,
            "It's not possible to update the master copy during the waiting period"
        );

         
        masterCopy = masterCopyCountdown.masterCopy;
    }

    function getMasterCopy() public view returns (address) {
        return masterCopy;
    }

     
     
    function setMinter(address newMinter) public onlyCreator {
        minter = newMinter;
    }

     
     
    function setNewOwner(address newOwner) public onlyCreator {
        creator = newOwner;
    }

     
     
     
    function mintOWL(address to, uint amount) public {
        require(minter != address(0), "The minter must be initialized");
        require(msg.sender == minter, "Only the minter can mint OWL");
        balances[to] = balances[to].add(amount);
        totalTokens = totalTokens.add(amount);
        emit Minted(to, amount);
        emit Transfer(address(0), to, amount);
    }

     
     
     
    function burnOWL(address user, uint amount) public {
        allowances[user][msg.sender] = allowances[user][msg.sender].sub(amount);
        balances[user] = balances[user].sub(amount);
        totalTokens = totalTokens.sub(amount);
        emit Burnt(msg.sender, user, amount);
        emit Transfer(user, address(0), amount);
    }

    function getMasterCopyCountdown() public view returns (address, uint) {
        return (masterCopyCountdown.masterCopy, masterCopyCountdown.timeWhenAvailable);
    }
}

 

pragma solidity ^0.5.0;


 
library SafeCast {

     
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

     
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

     
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

     
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

     
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }
}

 

 

pragma solidity ^0.5.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
             
             
            tempBytes := mload(0x40)

             
             
            let length := mload(_preBytes)
            mstore(tempBytes, length)

             
             
             
            let mc := add(tempBytes, 0x20)
             
             
            let end := add(mc, length)

            for {
                 
                 
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                 
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                 
                 
                mstore(mc, mload(cc))
            }

             
             
             
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

             
             
            mc := end
             
             
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

             
             
             
             
             
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31)  
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
             
             
             
            let fslot := sload(_preBytes_slot)
             
             
             
             
             
             
             
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
             
             
             
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                 
                 
                 
                sstore(
                    _preBytes_slot,
                     
                     
                    add(
                         
                         
                        fslot,
                        add(
                            mul(
                                div(
                                     
                                    mload(add(_postBytes, 0x20)),
                                     
                                    exp(0x100, sub(32, mlength))
                                ),
                                 
                                 
                                exp(0x100, sub(32, newlength))
                            ),
                             
                             
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                 
                 
                 
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                 
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                 
                 
                 
                 
                 
                 
                 
                 

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                 
                mstore(0x0, _preBytes_slot)
                 
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                 
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                 
                 
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))
                
                for { 
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint _start,
        uint _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                 
                 
                tempBytes := mload(0x40)

                 
                 
                 
                 
                 
                 
                 
                 
                let lengthmod := and(_length, 31)

                 
                 
                 
                 
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                     
                     
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                 
                 
                mstore(0x40, and(add(mc, 31), not(31)))
            }
             
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint _start) internal  pure returns (uint8) {
        require(_bytes.length >= (_start + 1));
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint _start) internal  pure returns (uint16) {
        require(_bytes.length >= (_start + 2));
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint _start) internal  pure returns (uint32) {
        require(_bytes.length >= (_start + 4));
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint _start) internal  pure returns (uint64) {
        require(_bytes.length >= (_start + 8));
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint _start) internal  pure returns (uint96) {
        require(_bytes.length >= (_start + 12));
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint _start) internal  pure returns (uint128) {
        require(_bytes.length >= (_start + 16));
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint _start) internal  pure returns (bytes32) {
        require(_bytes.length >= (_start + 32));
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

             
            switch eq(length, mload(_postBytes))
            case 1 {
                 
                 
                 
                 
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                 
                 
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                     
                    if iszero(eq(mload(mc), mload(cc))) {
                         
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                 
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
             
            let fslot := sload(_preBytes_slot)
             
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

             
            switch eq(slength, mlength)
            case 1 {
                 
                 
                 
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                         
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                             
                            success := 0
                        }
                    }
                    default {
                         
                         
                         
                         
                        let cb := 1

                         
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                         
                         
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                 
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                 
                success := 0
            }
        }

        return success;
    }
}

 

pragma solidity ^0.5.0;

 
library SignedSafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

 

pragma solidity ^0.5.0;


 
library TokenConservation {
    using SignedSafeMath for int256;

     
    function init(uint16[] memory tokenIdsForPrice) internal pure returns (int256[] memory) {
        return new int256[](tokenIdsForPrice.length + 1);
    }

     
    function feeTokenImbalance(int256[] memory self) internal pure returns (int256) {
        return self[0];
    }

     
    function updateTokenConservation(
        int256[] memory self,
        uint16 buyToken,
        uint16 sellToken,
        uint16[] memory tokenIdsForPrice,
        uint128 buyAmount,
        uint128 sellAmount
    ) internal pure {
        uint256 buyTokenIndex = findPriceIndex(buyToken, tokenIdsForPrice);
        uint256 sellTokenIndex = findPriceIndex(sellToken, tokenIdsForPrice);
        self[buyTokenIndex] = self[buyTokenIndex].sub(int256(buyAmount));
        self[sellTokenIndex] = self[sellTokenIndex].add(int256(sellAmount));
    }

     
    function checkTokenConservation(int256[] memory self) internal pure {
        require(self[0] > 0, "Token conservation at 0 must be positive.");
        for (uint256 i = 1; i < self.length; i++) {
            require(self[i] == 0, "Token conservation does not hold");
        }
    }

     
    function checkPriceOrdering(uint16[] memory tokenIdsForPrice) internal pure returns (bool) {
        for (uint256 i = 1; i < tokenIdsForPrice.length; i++) {
            if (tokenIdsForPrice[i] <= tokenIdsForPrice[i - 1]) {
                return false;
            }
        }
        return true;
    }

     
    function findPriceIndex(uint16 tokenId, uint16[] memory tokenIdsForPrice) private pure returns (uint256) {
         
        if (tokenId == 0) {
            return 0;
        }
         
        uint256 leftValue = 0;
        uint256 rightValue = tokenIdsForPrice.length - 1;
        while (rightValue >= leftValue) {
            uint256 middleValue = leftValue + (rightValue - leftValue) / 2;
            if (tokenIdsForPrice[middleValue] == tokenId) {
                 
                return middleValue + 1;
            } else if (tokenIdsForPrice[middleValue] < tokenId) {
                leftValue = middleValue + 1;
            } else {
                rightValue = middleValue - 1;
            }
        }
        revert("Price not provided for token");
    }
}

 

pragma solidity ^0.5.0;








 
contract BatchExchange is EpochTokenLocker {
    using SafeCast for uint256;
    using SafeMath for uint128;
    using BytesLib for bytes32;
    using BytesLib for bytes;
    using TokenConservation for int256[];
    using TokenConservation for uint16[];
    using IterableAppendOnlySet for IterableAppendOnlySet.Data;

     
    uint256 public constant MAX_TOUCHED_ORDERS = 25;

     
    uint256 public constant FEE_FOR_LISTING_TOKEN_IN_OWL = 10 ether;

     
    uint256 public constant AMOUNT_MINIMUM = 10**4;

     
    uint256 public constant IMPROVEMENT_DENOMINATOR = 100;  

     
     
    uint256 public MAX_TOKENS;

     
    uint16 public numTokens;

     
    uint128 public feeDenominator;

     
    TokenOWL public feeToken;

     
    mapping(address => Order[]) public orders;

     
    mapping(uint16 => uint128) public currentPrices;

     
    SolutionData public latestSolution;

     
    IterableAppendOnlySet.Data private allUsers;
    IdToAddressBiMap.Data private registeredTokens;

    struct Order {
        uint16 buyToken;
        uint16 sellToken;
        uint32 validFrom;  
        uint32 validUntil;  
        uint128 priceNumerator;
        uint128 priceDenominator;
        uint128 usedAmount;  
    }

    struct TradeData {
        address owner;
        uint128 volume;
        uint16 orderId;
    }

    struct SolutionData {
        uint32 batchId;
        TradeData[] trades;
        uint16[] tokenIdsForPrice;
        address solutionSubmitter;
        uint256 feeReward;
        uint256 objectiveValue;
    }

    event OrderPlacement(
        address owner,
        uint256 index,
        uint16 buyToken,
        uint16 sellToken,
        uint32 validFrom,
        uint32 validUntil,
        uint128 priceNumerator,
        uint128 priceDenominator
    );

     
    event OrderCancelation(address owner, uint256 id);

     
    event OrderDeletion(address owner, uint256 id);

     
    event Trade(address indexed owner, uint256 indexed orderIds, uint256 executedSellAmount, uint256 executedBuyAmount);

     
    event TradeReversion(address indexed owner, uint256 indexed orderIds, uint256 executedSellAmount, uint256 executedBuyAmount);

     
    constructor(uint256 maxTokens, uint128 _feeDenominator, address _feeToken) public {
         
         
        currentPrices[0] = 1 ether;
        MAX_TOKENS = maxTokens;
        feeToken = TokenOWL(_feeToken);
         
         
        feeToken.approve(address(this), uint256(-1));
        feeDenominator = _feeDenominator;
        addToken(_feeToken);  
    }

     
    function addToken(address token) public {
        require(numTokens < MAX_TOKENS, "Max tokens reached");
        if (numTokens > 0) {
             
            feeToken.burnOWL(msg.sender, FEE_FOR_LISTING_TOKEN_IN_OWL);
        }
        require(IdToAddressBiMap.insert(registeredTokens, numTokens, token), "Token already registered");
        numTokens++;
    }

     
    function placeOrder(uint16 buyToken, uint16 sellToken, uint32 validUntil, uint128 buyAmount, uint128 sellAmount)
        public
        returns (uint256)
    {
        return placeOrderInternal(buyToken, sellToken, getCurrentBatchId(), validUntil, buyAmount, sellAmount);
    }

     
    function placeValidFromOrders(
        uint16[] memory buyTokens,
        uint16[] memory sellTokens,
        uint32[] memory validFroms,
        uint32[] memory validUntils,
        uint128[] memory buyAmounts,
        uint128[] memory sellAmounts
    ) public returns (uint256[] memory orderIds) {
        orderIds = new uint256[](buyTokens.length);
        for (uint256 i = 0; i < buyTokens.length; i++) {
            orderIds[i] = placeOrderInternal(
                buyTokens[i],
                sellTokens[i],
                validFroms[i],
                validUntils[i],
                buyAmounts[i],
                sellAmounts[i]
            );
        }
    }

     
    function cancelOrders(uint256[] memory ids) public {
        for (uint256 i = 0; i < ids.length; i++) {
            if (!checkOrderValidity(orders[msg.sender][ids[i]], getCurrentBatchId() - 1)) {
                delete orders[msg.sender][ids[i]];
                emit OrderDeletion(msg.sender, ids[i]);
            } else {
                orders[msg.sender][ids[i]].validUntil = getCurrentBatchId() - 1;
                emit OrderCancelation(msg.sender, ids[i]);
            }
        }
    }

     
    function replaceOrders(
        uint256[] memory cancellations,
        uint16[] memory buyTokens,
        uint16[] memory sellTokens,
        uint32[] memory validFroms,
        uint32[] memory validUntils,
        uint128[] memory buyAmounts,
        uint128[] memory sellAmounts
    ) public returns (uint256[] memory orderIds) {
        cancelOrders(cancellations);
        return placeValidFromOrders(buyTokens, sellTokens, validFroms, validUntils, buyAmounts, sellAmounts);
    }

     
    function submitSolution(
        uint32 batchIndex,
        uint256 claimedObjectiveValue,
        address[] memory owners,
        uint16[] memory orderIds,
        uint128[] memory buyVolumes,
        uint128[] memory prices,
        uint16[] memory tokenIdsForPrice
    ) public returns (uint256) {
        require(acceptingSolutions(batchIndex), "Solutions are no longer accepted for this batch");
        require(
            isObjectiveValueSufficientlyImproved(claimedObjectiveValue),
            "Claimed objective doesn't sufficiently improve current solution"
        );
        require(verifyAmountThreshold(prices), "At least one price lower than AMOUNT_MINIMUM");
        require(tokenIdsForPrice[0] != 0, "Fee token has fixed price!");
        require(tokenIdsForPrice.checkPriceOrdering(), "prices are not ordered by tokenId");
        require(owners.length <= MAX_TOUCHED_ORDERS, "Solution exceeds MAX_TOUCHED_ORDERS");
        burnPreviousAuctionFees();
        undoCurrentSolution();
        updateCurrentPrices(prices, tokenIdsForPrice);
        delete latestSolution.trades;
        int256[] memory tokenConservation = TokenConservation.init(tokenIdsForPrice);
        uint256 utility = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            Order memory order = orders[owners[i]][orderIds[i]];
            require(checkOrderValidity(order, batchIndex), "Order is invalid");
            (uint128 executedBuyAmount, uint128 executedSellAmount) = getTradedAmounts(buyVolumes[i], order);
            require(executedBuyAmount >= AMOUNT_MINIMUM, "buy amount less than AMOUNT_MINIMUM");
            require(executedSellAmount >= AMOUNT_MINIMUM, "sell amount less than AMOUNT_MINIMUM");
            tokenConservation.updateTokenConservation(
                order.buyToken,
                order.sellToken,
                tokenIdsForPrice,
                executedBuyAmount,
                executedSellAmount
            );
            require(getRemainingAmount(order) >= executedSellAmount, "executedSellAmount bigger than specified in order");
             
             
            require(
                executedSellAmount.mul(order.priceNumerator) <= executedBuyAmount.mul(order.priceDenominator),
                "limit price not satisfied"
            );
             
            utility = utility.add(evaluateUtility(executedBuyAmount, order));
            updateRemainingOrder(owners[i], orderIds[i], executedSellAmount);
            addBalanceAndBlockWithdrawForThisBatch(owners[i], tokenIdToAddressMap(order.buyToken), executedBuyAmount);
            emit Trade(owners[i], orderIds[i], executedSellAmount, executedBuyAmount);
        }
         
        for (uint256 i = 0; i < owners.length; i++) {
            Order memory order = orders[owners[i]][orderIds[i]];
            (, uint128 executedSellAmount) = getTradedAmounts(buyVolumes[i], order);
            subtractBalance(owners[i], tokenIdToAddressMap(order.sellToken), executedSellAmount);
        }
        uint256 disregardedUtility = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            disregardedUtility = disregardedUtility.add(evaluateDisregardedUtility(orders[owners[i]][orderIds[i]], owners[i]));
        }
        uint256 burntFees = uint256(tokenConservation.feeTokenImbalance()) / 2;
         
        uint256 objectiveValue = utility.add(burntFees).sub(disregardedUtility);
        checkAndOverrideObjectiveValue(objectiveValue);
        grantRewardToSolutionSubmitter(burntFees);
        tokenConservation.checkTokenConservation();
        documentTrades(batchIndex, owners, orderIds, buyVolumes, tokenIdsForPrice);
        return (objectiveValue);
    }
     

     
    function tokenAddressToIdMap(address addr) public view returns (uint16) {
        return IdToAddressBiMap.getId(registeredTokens, addr);
    }

     
    function tokenIdToAddressMap(uint16 id) public view returns (address) {
        return IdToAddressBiMap.getAddressAt(registeredTokens, id);
    }

     
    function hasToken(address addr) public view returns (bool) {
        return IdToAddressBiMap.hasAddress(registeredTokens, addr);
    }

     
    function getEncodedUserOrders(address user) public view returns (bytes memory elements) {
        for (uint256 i = 0; i < orders[user].length; i++) {
            elements = elements.concat(
                encodeAuctionElement(user, getBalance(user, tokenIdToAddressMap(orders[user][i].sellToken)), orders[user][i])
            );
        }
        return elements;
    }

     
    function getEncodedOrders() public view returns (bytes memory elements) {
        if (allUsers.size() > 0) {
            address user = allUsers.first();
            bool stop = false;
            while (!stop) {
                elements = elements.concat(getEncodedUserOrders(user));
                if (user == allUsers.last) {
                    stop = true;
                } else {
                    user = allUsers.next(user);
                }
            }
        }
        return elements;
    }

    function acceptingSolutions(uint32 batchIndex) public view returns (bool) {
        return batchIndex == getCurrentBatchId() - 1 && getSecondsRemainingInBatch() >= 1 minutes;
    }

     
    function getCurrentObjectiveValue() public view returns (uint256) {
        if (latestSolution.batchId == getCurrentBatchId() - 1) {
            return latestSolution.objectiveValue;
        } else {
            return 0;
        }
    }
     

    function placeOrderInternal(
        uint16 buyToken,
        uint16 sellToken,
        uint32 validFrom,
        uint32 validUntil,
        uint128 buyAmount,
        uint128 sellAmount
    ) private returns (uint256) {
        require(buyToken != sellToken, "Exchange tokens not distinct");
        require(validFrom >= getCurrentBatchId(), "Orders can't be placed in the past");
        orders[msg.sender].push(
            Order({
                buyToken: buyToken,
                sellToken: sellToken,
                validFrom: validFrom,
                validUntil: validUntil,
                priceNumerator: buyAmount,
                priceDenominator: sellAmount,
                usedAmount: 0
            })
        );
        uint256 orderIndex = orders[msg.sender].length - 1;
        emit OrderPlacement(msg.sender, orderIndex, buyToken, sellToken, validFrom, validUntil, buyAmount, sellAmount);
        allUsers.insert(msg.sender);
        return orderIndex;
    }

     
    function grantRewardToSolutionSubmitter(uint256 feeReward) private {
        latestSolution.feeReward = feeReward;
        addBalanceAndBlockWithdrawForThisBatch(msg.sender, tokenIdToAddressMap(0), feeReward);
    }

     
    function burnPreviousAuctionFees() private {
        if (!currentBatchHasSolution()) {
            feeToken.burnOWL(address(this), latestSolution.feeReward);
        }
    }

     
    function updateCurrentPrices(uint128[] memory prices, uint16[] memory tokenIdsForPrice) private {
        for (uint256 i = 0; i < latestSolution.tokenIdsForPrice.length; i++) {
            currentPrices[latestSolution.tokenIdsForPrice[i]] = 0;
        }
        for (uint256 i = 0; i < tokenIdsForPrice.length; i++) {
            currentPrices[tokenIdsForPrice[i]] = prices[i];
        }
    }

     
    function updateRemainingOrder(address owner, uint256 orderId, uint128 executedAmount) private {
        orders[owner][orderId].usedAmount = orders[owner][orderId].usedAmount.add(executedAmount).toUint128();
    }

     
    function revertRemainingOrder(address owner, uint256 orderId, uint128 executedAmount) private {
        orders[owner][orderId].usedAmount = orders[owner][orderId].usedAmount.sub(executedAmount).toUint128();
    }

     
    function documentTrades(
        uint32 batchIndex,
        address[] memory owners,
        uint16[] memory orderIds,
        uint128[] memory volumes,
        uint16[] memory tokenIdsForPrice
    ) private {
        latestSolution.batchId = batchIndex;
        for (uint256 i = 0; i < owners.length; i++) {
            latestSolution.trades.push(TradeData({owner: owners[i], orderId: orderIds[i], volume: volumes[i]}));
        }
        latestSolution.tokenIdsForPrice = tokenIdsForPrice;
        latestSolution.solutionSubmitter = msg.sender;
    }

     
    function undoCurrentSolution() private {
        if (currentBatchHasSolution()) {
            for (uint256 i = 0; i < latestSolution.trades.length; i++) {
                address owner = latestSolution.trades[i].owner;
                uint256 orderId = latestSolution.trades[i].orderId;
                Order memory order = orders[owner][orderId];
                (, uint128 sellAmount) = getTradedAmounts(latestSolution.trades[i].volume, order);
                addBalance(owner, tokenIdToAddressMap(order.sellToken), sellAmount);
            }
            for (uint256 i = 0; i < latestSolution.trades.length; i++) {
                address owner = latestSolution.trades[i].owner;
                uint256 orderId = latestSolution.trades[i].orderId;
                Order memory order = orders[owner][orderId];
                (uint128 buyAmount, uint128 sellAmount) = getTradedAmounts(latestSolution.trades[i].volume, order);
                revertRemainingOrder(owner, orderId, sellAmount);
                subtractBalance(owner, tokenIdToAddressMap(order.buyToken), buyAmount);
                emit TradeReversion(owner, orderId, sellAmount, buyAmount);
            }
             
            subtractBalance(latestSolution.solutionSubmitter, tokenIdToAddressMap(0), latestSolution.feeReward);
        }
    }

     
    function checkAndOverrideObjectiveValue(uint256 newObjectiveValue) private {
        require(
            isObjectiveValueSufficientlyImproved(newObjectiveValue),
            "New objective doesn't sufficiently improve current solution"
        );
        latestSolution.objectiveValue = newObjectiveValue;
    }

     
     
    function evaluateUtility(uint128 execBuy, Order memory order) private view returns (uint256) {
         
        uint256 execSellTimesBuy = getExecutedSellAmount(execBuy, currentPrices[order.buyToken], currentPrices[order.sellToken])
            .mul(order.priceNumerator);

        uint256 roundedUtility = execBuy.sub(execSellTimesBuy.div(order.priceDenominator)).mul(currentPrices[order.buyToken]);
        uint256 utilityError = execSellTimesBuy.mod(order.priceDenominator).mul(currentPrices[order.buyToken]).div(
            order.priceDenominator
        );
        return roundedUtility.sub(utilityError).toUint128();
    }

     
    function evaluateDisregardedUtility(Order memory order, address user) private view returns (uint256) {
        uint256 leftoverSellAmount = Math.min(getRemainingAmount(order), getBalance(user, tokenIdToAddressMap(order.sellToken)));
        uint256 limitTermLeft = currentPrices[order.sellToken].mul(order.priceDenominator);
        uint256 limitTermRight = order.priceNumerator.mul(currentPrices[order.buyToken]).mul(feeDenominator).div(
            feeDenominator - 1
        );
        uint256 limitTerm = 0;
        if (limitTermLeft > limitTermRight) {
            limitTerm = limitTermLeft.sub(limitTermRight);
        }
        return leftoverSellAmount.mul(limitTerm).div(order.priceDenominator).toUint128();
    }

     
    function getExecutedSellAmount(uint128 executedBuyAmount, uint128 buyTokenPrice, uint128 sellTokenPrice)
        private
        view
        returns (uint128)
    {
        return
            uint256(executedBuyAmount)
                .mul(buyTokenPrice)
                .div(feeDenominator - 1)
                .mul(feeDenominator)
                .div(sellTokenPrice)
                .toUint128();
    }

     
    function currentBatchHasSolution() private view returns (bool) {
        return latestSolution.batchId == getCurrentBatchId() - 1;
    }

     
     
    function getTradedAmounts(uint128 executedBuyAmount, Order memory order) private view returns (uint128, uint128) {
        uint128 executedSellAmount = getExecutedSellAmount(
            executedBuyAmount,
            currentPrices[order.buyToken],
            currentPrices[order.sellToken]
        );
        return (executedBuyAmount, executedSellAmount);
    }

     
    function isObjectiveValueSufficientlyImproved(uint256 objectiveValue) private view returns (bool) {
        return (objectiveValue.mul(IMPROVEMENT_DENOMINATOR) > getCurrentObjectiveValue().mul(IMPROVEMENT_DENOMINATOR + 1));
    }

     
     
    function checkOrderValidity(Order memory order, uint256 batchIndex) private pure returns (bool) {
        return order.validFrom <= batchIndex && order.validUntil >= batchIndex;
    }

     
    function getRemainingAmount(Order memory order) private pure returns (uint128) {
        return order.priceDenominator - order.usedAmount;
    }

     
    function encodeAuctionElement(address user, uint256 sellTokenBalance, Order memory order)
        private
        pure
        returns (bytes memory element)
    {
        element = abi.encodePacked(user);
        element = element.concat(abi.encodePacked(sellTokenBalance));
        element = element.concat(abi.encodePacked(order.buyToken));
        element = element.concat(abi.encodePacked(order.sellToken));
        element = element.concat(abi.encodePacked(order.validFrom));
        element = element.concat(abi.encodePacked(order.validUntil));
        element = element.concat(abi.encodePacked(order.priceNumerator));
        element = element.concat(abi.encodePacked(order.priceDenominator));
        element = element.concat(abi.encodePacked(getRemainingAmount(order)));
        return element;
    }

     
    function verifyAmountThreshold(uint128[] memory amounts) private pure returns (bool) {
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] < AMOUNT_MINIMUM) {
                return false;
            }
        }
        return true;
    }
}