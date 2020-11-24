 

pragma solidity 0.5.2;

 

 
interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract ERC20WithSymbol is ERC20 {
    function symbol() external view returns (string memory _symbol);
}

 

contract PermissionGroups {

    address public admin;
    address public pendingAdmin;
    mapping(address=>bool) internal operators;
    mapping(address=>bool) internal alerters;
    address[] internal operatorsGroup;
    address[] internal alertersGroup;
    uint constant internal MAX_GROUP_SIZE = 50;

    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Operation limited to admin");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Operation limited to operator");
        _;
    }

    modifier onlyAlerter() {
        require(alerters[msg.sender], "Operation limited to alerter");
        _;
    }

    function getOperators () external view returns(address[] memory) {
        return operatorsGroup;
    }

    function getAlerters () external view returns(address[] memory) {
        return alertersGroup;
    }

    event TransferAdminPending(address pendingAdmin);

     
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "admin address cannot be 0");
        emit TransferAdminPending(pendingAdmin);
        pendingAdmin = newAdmin;
    }

     
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "admin address cannot be 0");
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    event AdminClaimed( address newAdmin, address previousAdmin);

     
    function claimAdmin() public {
        require(pendingAdmin == msg.sender, "admin address cannot be 0");
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    event AlerterAdded (address newAlerter, bool isAdd);

    function addAlerter(address newAlerter) public onlyAdmin {
         
        require(!alerters[newAlerter], "alerter already configured");
        require(
            alertersGroup.length < MAX_GROUP_SIZE,
            "alerter group exceeding maximum size"
        );

        emit AlerterAdded(newAlerter, true);
        alerters[newAlerter] = true;
        alertersGroup.push(newAlerter);
    }

    function removeAlerter (address alerter) public onlyAdmin {
        require(alerters[alerter], "alerter not configured");
        alerters[alerter] = false;

        for (uint i = 0; i < alertersGroup.length; ++i) {
            if (alertersGroup[i] == alerter) {
                alertersGroup[i] = alertersGroup[alertersGroup.length - 1];
                alertersGroup.length--;
                emit AlerterAdded(alerter, false);
                break;
            }
        }
    }

    event OperatorAdded(address newOperator, bool isAdd);

    function addOperator(address newOperator) public onlyAdmin {
         
        require(!operators[newOperator], "operator already configured");
        require(
            operatorsGroup.length < MAX_GROUP_SIZE,
            "operator group exceeding maximum size"
        );

        emit OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator (address operator) public onlyAdmin {
        require(operators[operator], "operator not configured");
        operators[operator] = false;

        for (uint i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.length -= 1;
                emit OperatorAdded(operator, false);
                break;
            }
        }
    }
}

 

 
contract Withdrawable is PermissionGroups {

    event TokenWithdraw(
        ERC20 indexed token,
        uint amount,
        address indexed sendTo
    );

     
    function withdrawToken(
      ERC20 token,
      uint amount,
      address sendTo
    )
        external
        onlyAdmin
    {
        require(token.transfer(sendTo, amount), "Could not transfer tokens");
        emit TokenWithdraw(token, amount, sendTo);
    }

    event EtherWithdraw(
        uint amount,
        address indexed sendTo
    );

     
    function withdrawEther(
        uint amount,
        address payable sendTo
    )
        external
        onlyAdmin
    {
        sendTo.transfer(amount);
        emit EtherWithdraw(amount, sendTo);
    }
}

 

 
 
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

 

 
contract TokenFRT is Proxied, GnosisStandardToken {
    address public owner;

    string public constant symbol = "MGN";
    string public constant name = "Magnolia Token";
    uint8 public constant decimals = 18;

    struct UnlockedToken {
        uint amountUnlocked;
        uint withdrawalTime;
    }

     
    address public minter;

     
    mapping(address => UnlockedToken) public unlockedTokens;

     
    mapping(address => uint) public lockedTokenBalances;

     

     
     
    function updateMinter(address _minter) public {
        require(msg.sender == owner, "Only the minter can set a new one");
        require(_minter != address(0), "The new minter must be a valid address");

        minter = _minter;
    }

     
     
    function updateOwner(address _owner) public {
        require(msg.sender == owner, "Only the owner can update the owner");
        require(_owner != address(0), "The new owner must be a valid address");
        owner = _owner;
    }

    function mintTokens(address user, uint amount) public {
        require(msg.sender == minter, "Only the minter can mint tokens");

        lockedTokenBalances[user] = add(lockedTokenBalances[user], amount);
        totalTokens = add(totalTokens, amount);
    }

     
    function lockTokens(uint amount) public returns (uint totalAmountLocked) {
         
        uint actualAmount = min(amount, balances[msg.sender]);

         
        balances[msg.sender] = sub(balances[msg.sender], actualAmount);
        lockedTokenBalances[msg.sender] = add(lockedTokenBalances[msg.sender], actualAmount);

         
        totalAmountLocked = lockedTokenBalances[msg.sender];
    }

    function unlockTokens() public returns (uint totalAmountUnlocked, uint withdrawalTime) {
         
        uint amount = lockedTokenBalances[msg.sender];

        if (amount > 0) {
             
            lockedTokenBalances[msg.sender] = sub(lockedTokenBalances[msg.sender], amount);
            unlockedTokens[msg.sender].amountUnlocked = add(unlockedTokens[msg.sender].amountUnlocked, amount);
            unlockedTokens[msg.sender].withdrawalTime = now + 24 hours;
        }

         
        totalAmountUnlocked = unlockedTokens[msg.sender].amountUnlocked;
        withdrawalTime = unlockedTokens[msg.sender].withdrawalTime;
    }

    function withdrawUnlockedTokens() public {
        require(unlockedTokens[msg.sender].withdrawalTime < now, "The tokens cannot be withdrawn yet");
        balances[msg.sender] = add(balances[msg.sender], unlockedTokens[msg.sender].amountUnlocked);
        unlockedTokens[msg.sender].amountUnlocked = 0;
    }

    function min(uint a, uint b) public pure returns (uint) {
        if (a < b) {
            return a;
        } else {
            return b;
        }
    }
    
     
     
     
     
    function safeToAdd(uint a, uint b) public pure returns (bool) {
        return a + b >= a;
    }

     
     
     
     
    function safeToSub(uint a, uint b) public pure returns (bool) {
        return a >= b;
    }

     
     
     
     
    function add(uint a, uint b) public pure returns (uint) {
        require(safeToAdd(a, b), "It must be a safe adition");
        return a + b;
    }

     
     
     
     
    function sub(uint a, uint b) public pure returns (uint) {
        require(safeToSub(a, b), "It must be a safe substraction");
        return a - b;
    }
}

 

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
    }

     
     
     
    function burnOWL(address user, uint amount) public {
        allowances[user][msg.sender] = allowances[user][msg.sender].sub(amount);
        balances[user] = balances[user].sub(amount);
        totalTokens = totalTokens.sub(amount);
        emit Burnt(msg.sender, user, amount);
    }
}

 

interface BadToken {
    function transfer(address to, uint value) external;
    function transferFrom(address from, address to, uint value) external;
}

contract SafeTransfer {
    function safeTransfer(address token, address to, uint value, bool from) internal returns (bool result) {
        if (from) {
            BadToken(token).transferFrom(msg.sender, address(this), value);
        } else {
            BadToken(token).transfer(to, value);
        }

         
        assembly {
            switch returndatasize
                case 0 {
                     
                    result := not(0)  
                }
                case 32 {
                     
                    returndatacopy(0, 0, 32)
                    result := mload(0)  
                }
                default {
                     
                    result := 0
                }
        }
        return result;
    }
}

 

contract AuctioneerManaged {
     
    address public auctioneer;

    function updateAuctioneer(address _auctioneer) public onlyAuctioneer {
        require(_auctioneer != address(0), "The auctioneer must be a valid address");
        auctioneer = _auctioneer;
    }

     
    modifier onlyAuctioneer() {
         
         
         
        require(msg.sender == auctioneer, "Only the auctioneer can nominate a new one");
        _;
    }
}

 

contract TokenWhitelist is AuctioneerManaged {
     
     
     
    mapping(address => bool) public approvedTokens;

    event Approval(address indexed token, bool approved);

     
     
    function getApprovedAddressesOfList(address[] calldata addressesToCheck) external view returns (bool[] memory) {
        uint length = addressesToCheck.length;

        bool[] memory isApproved = new bool[](length);

        for (uint i = 0; i < length; i++) {
            isApproved[i] = approvedTokens[addressesToCheck[i]];
        }

        return isApproved;
    }
    
    function updateApprovalOfToken(address[] memory token, bool approved) public onlyAuctioneer {
        for (uint i = 0; i < token.length; i++) {
            approvedTokens[token[i]] = approved;
            emit Approval(token[i], approved);
        }
    }

}

 

contract DxMath {
     
    function min(uint a, uint b) public pure returns (uint) {
        if (a < b) {
            return a;
        } else {
            return b;
        }
    }

    function atleastZero(int a) public pure returns (uint) {
        if (a < 0) {
            return 0;
        } else {
            return uint(a);
        }
    }
    
     
     
     
     
    function safeToAdd(uint a, uint b) public pure returns (bool) {
        return a + b >= a;
    }

     
     
     
     
    function safeToSub(uint a, uint b) public pure returns (bool) {
        return a >= b;
    }

     
     
     
     
    function safeToMul(uint a, uint b) public pure returns (bool) {
        return b == 0 || a * b / b == a;
    }

     
     
     
     
    function add(uint a, uint b) public pure returns (uint) {
        require(safeToAdd(a, b));
        return a + b;
    }

     
     
     
     
    function sub(uint a, uint b) public pure returns (uint) {
        require(safeToSub(a, b));
        return a - b;
    }

     
     
     
     
    function mul(uint a, uint b) public pure returns (uint) {
        require(safeToMul(a, b));
        return a * b;
    }
}

 

contract DSMath {
     

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

     

    function hadd(uint128 x, uint128 y) internal pure returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) internal pure returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) internal pure returns (uint128 z) {
        assert((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) internal pure returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) internal pure returns (uint128 z) {
        return x <= y ? x : y;
    }

    function hmax(uint128 x, uint128 y) internal pure returns (uint128 z) {
        return x >= y ? x : y;
    }

     

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

     

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) internal pure returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) internal pure returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) internal pure returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) internal pure returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) internal pure returns (uint128) {
        return hmin(x, y);
    }

    function wmax(uint128 x, uint128 y) internal pure returns (uint128) {
        return hmax(x, y);
    }

     

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) internal pure returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) internal pure returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) internal pure returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) internal pure returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) internal pure returns (uint128 z) {
         
         
         
         
         
         
         
         
         
         
         
         
         
         

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) internal pure returns (uint128) {
        return hmin(x, y);
    }

    function rmax(uint128 x, uint128 y) internal pure returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) internal pure returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}

 

contract DSAuthority {
    function canCall(address src, address dst, bytes4 sig) public view returns (bool);
}


contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}


contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public auth {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "It must be an authorized call");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

 

contract DSNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 bar,
        uint wad,
        bytes fax
    );

    modifier note {
        bytes32 foo;
        bytes32 bar;
         
        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(
            msg.sig,
            msg.sender,
            foo,
            bar,
            msg.value,
            msg.data
        );

        _;
    }
}

 

contract DSThing is DSAuth, DSNote, DSMath {}

 

 

 

 
 

 
 
 



contract PriceFeed is DSThing {
    uint128 val;
    uint32 public zzz;

    function peek() public view returns (bytes32, bool) {
        return (bytes32(uint256(val)), block.timestamp < zzz);
    }

    function read() public view returns (bytes32) {
        assert(block.timestamp < zzz);
        return bytes32(uint256(val));
    }

    function post(uint128 val_, uint32 zzz_, address med_) public payable note auth {
        val = val_;
        zzz = zzz_;
        (bool success, ) = med_.call(abi.encodeWithSignature("poke()"));
        require(success, "The poke must succeed");
    }

    function void() public payable note auth {
        zzz = 0;
    }

}

 

contract DSValue is DSThing {
    bool has;
    bytes32 val;
    function peek() public view returns (bytes32, bool) {
        return (val, has);
    }

    function read() public view returns (bytes32) {
        (bytes32 wut, bool _has) = peek();
        assert(_has);
        return wut;
    }

    function poke(bytes32 wut) public payable note auth {
        val = wut;
        has = true;
    }

    function void() public payable note auth {
         
        has = false;
    }
}

 

contract Medianizer is DSValue {
    mapping(bytes12 => address) public values;
    mapping(address => bytes12) public indexes;
    bytes12 public next = bytes12(uint96(1));
    uint96 public minimun = 0x1;

    function set(address wat) public auth {
        bytes12 nextId = bytes12(uint96(next) + 1);
        assert(nextId != 0x0);
        set(next, wat);
        next = nextId;
    }

    function set(bytes12 pos, address wat) public payable note auth {
        require(pos != 0x0, "pos cannot be 0x0");
        require(wat == address(0) || indexes[wat] == 0, "wat is not defined or it has an index");

        indexes[values[pos]] = bytes12(0);  

        if (wat != address(0)) {
            indexes[wat] = pos;
        }

        values[pos] = wat;
    }

    function setMin(uint96 min_) public payable note auth {
        require(min_ != 0x0, "min cannot be 0x0");
        minimun = min_;
    }

    function setNext(bytes12 next_) public payable note auth {
        require(next_ != 0x0, "next cannot be 0x0");
        next = next_;
    }

    function unset(bytes12 pos) public {
        set(pos, address(0));
    }

    function unset(address wat) public {
        set(indexes[wat], address(0));
    }

    function poke() public {
        poke(0);
    }

    function poke(bytes32) public payable note {
        (val, has) = compute();
    }

    function compute() public view returns (bytes32, bool) {
        bytes32[] memory wuts = new bytes32[](uint96(next) - 1);
        uint96 ctr = 0;
        for (uint96 i = 1; i < uint96(next); i++) {
            if (values[bytes12(i)] != address(0)) {
                (bytes32 wut, bool wuz) = DSValue(values[bytes12(i)]).peek();
                if (wuz) {
                    if (ctr == 0 || wut >= wuts[ctr - 1]) {
                        wuts[ctr] = wut;
                    } else {
                        uint96 j = 0;
                        while (wut >= wuts[j]) {
                            j++;
                        }
                        for (uint96 k = ctr; k > j; k--) {
                            wuts[k] = wuts[k - 1];
                        }
                        wuts[j] = wut;
                    }
                    ctr++;
                }
            }
        }

        if (ctr < minimun)
            return (val, false);

        bytes32 value;
        if (ctr % 2 == 0) {
            uint128 val1 = uint128(uint(wuts[(ctr / 2) - 1]));
            uint128 val2 = uint128(uint(wuts[ctr / 2]));
            value = bytes32(uint256(wdiv(hadd(val1, val2), 2 ether)));
        } else {
            value = wuts[(ctr - 1) / 2];
        }

        return (value, true);
    }
}

 

 




contract PriceOracleInterface {
    address public priceFeedSource;
    address public owner;
    bool public emergencyMode;

     
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can do the operation");
        _;
    }

     
     
    constructor(address _owner, address _priceFeedSource) public {
        owner = _owner;
        priceFeedSource = _priceFeedSource;
    }
    
     
     
    function raiseEmergency(bool _emergencyMode) public onlyOwner {
        emergencyMode = _emergencyMode;
    }

     
     
    function updateCurator(address _owner) public onlyOwner {
        owner = _owner;
    }

     
    function getUsdEthPricePeek() public view returns (bytes32 price, bool valid) {
        return Medianizer(priceFeedSource).peek();
    }

     
    function getUSDETHPrice() public view returns (uint256) {
         
        if (emergencyMode) {
            return 600;
        }
        (bytes32 price, ) = Medianizer(priceFeedSource).peek();

         
         
        uint priceUint = uint256(price)/(1 ether);
        if (priceUint == 0) {
            return 1;
        }
        if (priceUint > 1000000) {
            return 1000000; 
        }
        return priceUint;
    }
}

 

contract EthOracle is AuctioneerManaged, DxMath {
    uint constant WAITING_PERIOD_CHANGE_ORACLE = 30 days;

     
    PriceOracleInterface public ethUSDOracle;
     
    PriceOracleInterface public newProposalEthUSDOracle;

    uint public oracleInterfaceCountdown;

    event NewOracleProposal(PriceOracleInterface priceOracleInterface);

    function initiateEthUsdOracleUpdate(PriceOracleInterface _ethUSDOracle) public onlyAuctioneer {
        require(address(_ethUSDOracle) != address(0), "The oracle address must be valid");
        newProposalEthUSDOracle = _ethUSDOracle;
        oracleInterfaceCountdown = add(block.timestamp, WAITING_PERIOD_CHANGE_ORACLE);
        emit NewOracleProposal(_ethUSDOracle);
    }

    function updateEthUSDOracle() public {
        require(address(newProposalEthUSDOracle) != address(0), "The new proposal must be a valid addres");
        require(
            oracleInterfaceCountdown < block.timestamp,
            "It's not possible to update the oracle during the waiting period"
        );
        ethUSDOracle = newProposalEthUSDOracle;
        newProposalEthUSDOracle = PriceOracleInterface(0);
    }
}

 

contract DxUpgrade is Proxied, AuctioneerManaged, DxMath {
    uint constant WAITING_PERIOD_CHANGE_MASTERCOPY = 30 days;

    address public newMasterCopy;
     
    uint public masterCopyCountdown;

    event NewMasterCopyProposal(address newMasterCopy);

    function startMasterCopyCountdown(address _masterCopy) public onlyAuctioneer {
        require(_masterCopy != address(0), "The new master copy must be a valid address");

         
        newMasterCopy = _masterCopy;
        masterCopyCountdown = add(block.timestamp, WAITING_PERIOD_CHANGE_MASTERCOPY);
        emit NewMasterCopyProposal(_masterCopy);
    }

    function updateMasterCopy() public {
        require(newMasterCopy != address(0), "The new master copy must be a valid address");
        require(block.timestamp >= masterCopyCountdown, "The master contract cannot be updated in a waiting period");

         
        masterCopy = newMasterCopy;
        newMasterCopy = address(0);
    }

}

 

 
 
 

contract DutchExchange is DxUpgrade, TokenWhitelist, EthOracle, SafeTransfer {

     
    struct Fraction {
        uint num;
        uint den;
    }

    uint constant WAITING_PERIOD_NEW_TOKEN_PAIR = 6 hours;
    uint constant WAITING_PERIOD_NEW_AUCTION = 10 minutes;
    uint constant AUCTION_START_WAITING_FOR_FUNDING = 1;

     
     
    address public ethToken;

     
    uint public thresholdNewTokenPair;
     
    uint public thresholdNewAuction;
     
    TokenFRT public frtToken;
     
    TokenOWL public owlToken;

     
     
     
     
    mapping(address => mapping(address => uint)) public latestAuctionIndices;
     
    mapping (address => mapping (address => uint)) public auctionStarts;
     
    mapping (address => mapping (address => mapping (uint => uint))) public clearingTimes;

     
    mapping(address => mapping(address => mapping(uint => Fraction))) public closingPrices;

     
    mapping(address => mapping(address => uint)) public sellVolumesCurrent;
     
    mapping(address => mapping(address => uint)) public sellVolumesNext;
     
    mapping(address => mapping(address => uint)) public buyVolumes;

     
     
    mapping(address => mapping(address => uint)) public balances;

     
    mapping(address => mapping(address => mapping(uint => uint))) public extraTokens;

     
    mapping(address => mapping(address => mapping(uint => mapping(address => uint)))) public sellerBalances;
    mapping(address => mapping(address => mapping(uint => mapping(address => uint)))) public buyerBalances;
    mapping(address => mapping(address => mapping(uint => mapping(address => uint)))) public claimedAmounts;

    function depositAndSell(address sellToken, address buyToken, uint amount)
        external
        returns (uint newBal, uint auctionIndex, uint newSellerBal)
    {
        newBal = deposit(sellToken, amount);
        (auctionIndex, newSellerBal) = postSellOrder(sellToken, buyToken, 0, amount);
    }

    function claimAndWithdraw(address sellToken, address buyToken, address user, uint auctionIndex, uint amount)
        external
        returns (uint returned, uint frtsIssued, uint newBal)
    {
        (returned, frtsIssued) = claimSellerFunds(sellToken, buyToken, user, auctionIndex);
        newBal = withdraw(buyToken, amount);
    }

     
     
     
     
     
    function claimTokensFromSeveralAuctionsAsSeller(
        address[] calldata auctionSellTokens,
        address[] calldata auctionBuyTokens,
        uint[] calldata auctionIndices,
        address user
    ) external returns (uint[] memory, uint[] memory)
    {
        uint length = checkLengthsForSeveralAuctionClaiming(auctionSellTokens, auctionBuyTokens, auctionIndices);

        uint[] memory claimAmounts = new uint[](length);
        uint[] memory frtsIssuedList = new uint[](length);

        for (uint i = 0; i < length; i++) {
            (claimAmounts[i], frtsIssuedList[i]) = claimSellerFunds(
                auctionSellTokens[i],
                auctionBuyTokens[i],
                user,
                auctionIndices[i]
            );
        }

        return (claimAmounts, frtsIssuedList);
    }

     
     
     
     
     
    function claimTokensFromSeveralAuctionsAsBuyer(
        address[] calldata auctionSellTokens,
        address[] calldata auctionBuyTokens,
        uint[] calldata auctionIndices,
        address user
    ) external returns (uint[] memory, uint[] memory)
    {
        uint length = checkLengthsForSeveralAuctionClaiming(auctionSellTokens, auctionBuyTokens, auctionIndices);

        uint[] memory claimAmounts = new uint[](length);
        uint[] memory frtsIssuedList = new uint[](length);

        for (uint i = 0; i < length; i++) {
            (claimAmounts[i], frtsIssuedList[i]) = claimBuyerFunds(
                auctionSellTokens[i],
                auctionBuyTokens[i],
                user,
                auctionIndices[i]
            );
        }

        return (claimAmounts, frtsIssuedList);
    }

     
     
     
     
    function claimAndWithdrawTokensFromSeveralAuctionsAsSeller(
        address[] calldata auctionSellTokens,
        address[] calldata auctionBuyTokens,
        uint[] calldata auctionIndices
    ) external returns (uint[] memory, uint frtsIssued)
    {
        uint length = checkLengthsForSeveralAuctionClaiming(auctionSellTokens, auctionBuyTokens, auctionIndices);

        uint[] memory claimAmounts = new uint[](length);
        uint claimFrts = 0;

        for (uint i = 0; i < length; i++) {
            (claimAmounts[i], claimFrts) = claimSellerFunds(
                auctionSellTokens[i],
                auctionBuyTokens[i],
                msg.sender,
                auctionIndices[i]
            );

            frtsIssued += claimFrts;

            withdraw(auctionBuyTokens[i], claimAmounts[i]);
        }

        return (claimAmounts, frtsIssued);
    }

     
     
     
     
    function claimAndWithdrawTokensFromSeveralAuctionsAsBuyer(
        address[] calldata auctionSellTokens,
        address[] calldata auctionBuyTokens,
        uint[] calldata auctionIndices
    ) external returns (uint[] memory, uint frtsIssued)
    {
        uint length = checkLengthsForSeveralAuctionClaiming(auctionSellTokens, auctionBuyTokens, auctionIndices);

        uint[] memory claimAmounts = new uint[](length);
        uint claimFrts = 0;

        for (uint i = 0; i < length; i++) {
            (claimAmounts[i], claimFrts) = claimBuyerFunds(
                auctionSellTokens[i],
                auctionBuyTokens[i],
                msg.sender,
                auctionIndices[i]
            );

            frtsIssued += claimFrts;

            withdraw(auctionSellTokens[i], claimAmounts[i]);
        }

        return (claimAmounts, frtsIssued);
    }

    function getMasterCopy() external view returns (address) {
        return masterCopy;
    }

     
     
     
     
     
     
     
    function setupDutchExchange(
        TokenFRT _frtToken,
        TokenOWL _owlToken,
        address _auctioneer,
        address _ethToken,
        PriceOracleInterface _ethUSDOracle,
        uint _thresholdNewTokenPair,
        uint _thresholdNewAuction
    ) public
    {
         
        require(ethToken == address(0), "The contract must be uninitialized");

         
        require(address(_owlToken) != address(0), "The OWL address must be valid");
        require(address(_frtToken) != address(0), "The FRT address must be valid");
        require(_auctioneer != address(0), "The auctioneer address must be valid");
        require(_ethToken != address(0), "The WETH address must be valid");
        require(address(_ethUSDOracle) != address(0), "The oracle address must be valid");

        frtToken = _frtToken;
        owlToken = _owlToken;
        auctioneer = _auctioneer;
        ethToken = _ethToken;
        ethUSDOracle = _ethUSDOracle;
        thresholdNewTokenPair = _thresholdNewTokenPair;
        thresholdNewAuction = _thresholdNewAuction;
    }

    function updateThresholdNewTokenPair(uint _thresholdNewTokenPair) public onlyAuctioneer {
        thresholdNewTokenPair = _thresholdNewTokenPair;
    }

    function updateThresholdNewAuction(uint _thresholdNewAuction) public onlyAuctioneer {
        thresholdNewAuction = _thresholdNewAuction;
    }

     
     
    function addTokenPair(
        address token1,
        address token2,
        uint token1Funding,
        uint token2Funding,
        uint initialClosingPriceNum,
        uint initialClosingPriceDen
    ) public
    {
         
        require(token1 != token2, "You cannot add a token pair using the same token");

         
        require(initialClosingPriceNum != 0, "You must set the numerator for the initial price");

         
        require(initialClosingPriceDen != 0, "You must set the denominator for the initial price");

         
        require(getAuctionIndex(token1, token2) == 0, "The token pair was already added");

         
        require(initialClosingPriceNum < 10 ** 18, "You must set a smaller numerator for the initial price");

         
        require(initialClosingPriceDen < 10 ** 18, "You must set a smaller denominator for the initial price");

        setAuctionIndex(token1, token2);

        token1Funding = min(token1Funding, balances[token1][msg.sender]);
        token2Funding = min(token2Funding, balances[token2][msg.sender]);

         
        require(token1Funding < 10 ** 30, "You should use a smaller funding for token 1");

         
        require(token2Funding < 10 ** 30, "You should use a smaller funding for token 2");

        uint fundedValueUSD;
        uint ethUSDPrice = ethUSDOracle.getUSDETHPrice();

         
        address ethTokenMem = ethToken;
        if (token1 == ethTokenMem) {
             
             
            fundedValueUSD = mul(token1Funding, ethUSDPrice);
        } else if (token2 == ethTokenMem) {
             
             
            fundedValueUSD = mul(token2Funding, ethUSDPrice);
        } else {
             
            fundedValueUSD = calculateFundedValueTokenToken(
                token1,
                token2,
                token1Funding,
                token2Funding,
                ethTokenMem,
                ethUSDPrice
            );
        }

         
        require(fundedValueUSD >= thresholdNewTokenPair, "You should surplus the threshold for adding token pairs");

         
        closingPrices[token1][token2][0] = Fraction(initialClosingPriceNum, initialClosingPriceDen);
        closingPrices[token2][token1][0] = Fraction(initialClosingPriceDen, initialClosingPriceNum);

         
        addTokenPairSecondPart(token1, token2, token1Funding, token2Funding);
    }

    function deposit(address tokenAddress, uint amount) public returns (uint) {
         
        require(safeTransfer(tokenAddress, msg.sender, amount, true), "The deposit transaction must succeed");

        uint newBal = add(balances[tokenAddress][msg.sender], amount);

        balances[tokenAddress][msg.sender] = newBal;

        emit NewDeposit(tokenAddress, amount);

        return newBal;
    }

    function withdraw(address tokenAddress, uint amount) public returns (uint) {
        uint usersBalance = balances[tokenAddress][msg.sender];
        amount = min(amount, usersBalance);

         
        require(amount > 0, "The amount must be greater than 0");

        uint newBal = sub(usersBalance, amount);
        balances[tokenAddress][msg.sender] = newBal;

         
        require(safeTransfer(tokenAddress, msg.sender, amount, false), "The withdraw transfer must succeed");
        emit NewWithdrawal(tokenAddress, amount);

        return newBal;
    }

    function postSellOrder(address sellToken, address buyToken, uint auctionIndex, uint amount)
        public
        returns (uint, uint)
    {
         
         

        amount = min(amount, balances[sellToken][msg.sender]);

         
         

         
        uint latestAuctionIndex = getAuctionIndex(sellToken, buyToken);
        require(latestAuctionIndex > 0);

         
        uint auctionStart = getAuctionStart(sellToken, buyToken);
        if (auctionStart == AUCTION_START_WAITING_FOR_FUNDING || auctionStart > now) {
             
             
             
             
             
            if (auctionIndex == 0) {
                auctionIndex = latestAuctionIndex;
            } else {
                require(auctionIndex == latestAuctionIndex, "Auction index should be equal to latest auction index");
            }

             
            require(add(sellVolumesCurrent[sellToken][buyToken], amount) < 10 ** 30);
        } else {
             
             
            if (auctionIndex == 0) {
                auctionIndex = latestAuctionIndex + 1;
            } else {
                require(auctionIndex == latestAuctionIndex + 1);
            }

             
            require(add(sellVolumesNext[sellToken][buyToken], amount) < 10 ** 30);
        }

         
        uint amountAfterFee = settleFee(sellToken, buyToken, auctionIndex, amount);

         
        balances[sellToken][msg.sender] = sub(balances[sellToken][msg.sender], amount);
        uint newSellerBal = add(sellerBalances[sellToken][buyToken][auctionIndex][msg.sender], amountAfterFee);
        sellerBalances[sellToken][buyToken][auctionIndex][msg.sender] = newSellerBal;

        if (auctionStart == AUCTION_START_WAITING_FOR_FUNDING || auctionStart > now) {
             
            uint sellVolumeCurrent = sellVolumesCurrent[sellToken][buyToken];
            sellVolumesCurrent[sellToken][buyToken] = add(sellVolumeCurrent, amountAfterFee);
        } else {
             
            uint sellVolumeNext = sellVolumesNext[sellToken][buyToken];
            sellVolumesNext[sellToken][buyToken] = add(sellVolumeNext, amountAfterFee);

             
            closeTheoreticalClosedAuction(sellToken, buyToken, latestAuctionIndex);
        }

        if (auctionStart == AUCTION_START_WAITING_FOR_FUNDING) {
            scheduleNextAuction(sellToken, buyToken);
        }

        emit NewSellOrder(sellToken, buyToken, msg.sender, auctionIndex, amountAfterFee);

        return (auctionIndex, newSellerBal);
    }

    function postBuyOrder(address sellToken, address buyToken, uint auctionIndex, uint amount)
        public
        returns (uint newBuyerBal)
    {
         
        require(closingPrices[sellToken][buyToken][auctionIndex].den == 0);

        uint auctionStart = getAuctionStart(sellToken, buyToken);

         
        require(auctionStart <= now);

         
        require(auctionIndex == getAuctionIndex(sellToken, buyToken));

         
        require(auctionStart > AUCTION_START_WAITING_FOR_FUNDING);

         
        require(sellVolumesCurrent[sellToken][buyToken] > 0);

        uint buyVolume = buyVolumes[sellToken][buyToken];
        amount = min(amount, balances[buyToken][msg.sender]);

         
        require(add(buyVolume, amount) < 10 ** 30);

         
         
         
        uint sellVolume = sellVolumesCurrent[sellToken][buyToken];

        uint num;
        uint den;
        (num, den) = getCurrentAuctionPrice(sellToken, buyToken, auctionIndex);
         
        uint outstandingVolume = atleastZero(int(mul(sellVolume, num) / den - buyVolume));

        uint amountAfterFee;
        if (amount < outstandingVolume) {
            if (amount > 0) {
                amountAfterFee = settleFee(buyToken, sellToken, auctionIndex, amount);
            }
        } else {
            amount = outstandingVolume;
            amountAfterFee = outstandingVolume;
        }

         
        if (amount > 0) {
             
            balances[buyToken][msg.sender] = sub(balances[buyToken][msg.sender], amount);
            newBuyerBal = add(buyerBalances[sellToken][buyToken][auctionIndex][msg.sender], amountAfterFee);
            buyerBalances[sellToken][buyToken][auctionIndex][msg.sender] = newBuyerBal;
            buyVolumes[sellToken][buyToken] = add(buyVolumes[sellToken][buyToken], amountAfterFee);
            emit NewBuyOrder(sellToken, buyToken, msg.sender, auctionIndex, amountAfterFee);
        }

         
        if (amount >= outstandingVolume) {
             
            clearAuction(sellToken, buyToken, auctionIndex, sellVolume);
        }

        return (newBuyerBal);
    }

    function claimSellerFunds(address sellToken, address buyToken, address user, uint auctionIndex)
        public
        returns (
         
        uint returned,
        uint frtsIssued
    )
    {
        closeTheoreticalClosedAuction(sellToken, buyToken, auctionIndex);
        uint sellerBalance = sellerBalances[sellToken][buyToken][auctionIndex][user];

         
        require(sellerBalance > 0);

         
        Fraction memory closingPrice = closingPrices[sellToken][buyToken][auctionIndex];
        uint num = closingPrice.num;
        uint den = closingPrice.den;

         
        require(den > 0);

         
         
        returned = mul(sellerBalance, num) / den;

        frtsIssued = issueFrts(
            sellToken,
            buyToken,
            returned,
            auctionIndex,
            sellerBalance,
            user
        );

         
        sellerBalances[sellToken][buyToken][auctionIndex][user] = 0;
        if (returned > 0) {
            balances[buyToken][user] = add(balances[buyToken][user], returned);
        }
        emit NewSellerFundsClaim(
            sellToken,
            buyToken,
            user,
            auctionIndex,
            returned,
            frtsIssued
        );
    }

    function claimBuyerFunds(address sellToken, address buyToken, address user, uint auctionIndex)
        public
        returns (uint returned, uint frtsIssued)
    {
        closeTheoreticalClosedAuction(sellToken, buyToken, auctionIndex);

        uint num;
        uint den;
        (returned, num, den) = getUnclaimedBuyerFunds(sellToken, buyToken, user, auctionIndex);

        if (closingPrices[sellToken][buyToken][auctionIndex].den == 0) {
             
            claimedAmounts[sellToken][buyToken][auctionIndex][user] = add(
                claimedAmounts[sellToken][buyToken][auctionIndex][user],
                returned
            );
        } else {
             
             
             

             
             
            uint extraTokensTotal = extraTokens[sellToken][buyToken][auctionIndex];
            uint buyerBalance = buyerBalances[sellToken][buyToken][auctionIndex][user];

             
             
            uint tokensExtra = mul(
                buyerBalance,
                extraTokensTotal
            ) / closingPrices[sellToken][buyToken][auctionIndex].num;
            returned = add(returned, tokensExtra);

            frtsIssued = issueFrts(
                buyToken,
                sellToken,
                mul(buyerBalance, den) / num,
                auctionIndex,
                buyerBalance,
                user
            );

             
             
            buyerBalances[sellToken][buyToken][auctionIndex][user] = 0;
            claimedAmounts[sellToken][buyToken][auctionIndex][user] = 0;
        }

         
        if (returned > 0) {
            balances[sellToken][user] = add(balances[sellToken][user], returned);
        }

        emit NewBuyerFundsClaim(
            sellToken,
            buyToken,
            user,
            auctionIndex,
            returned,
            frtsIssued
        );
    }

     
     
     
     
    function closeTheoreticalClosedAuction(address sellToken, address buyToken, uint auctionIndex) public {
        if (auctionIndex == getAuctionIndex(
            buyToken,
            sellToken
        ) && closingPrices[sellToken][buyToken][auctionIndex].num == 0) {
            uint buyVolume = buyVolumes[sellToken][buyToken];
            uint sellVolume = sellVolumesCurrent[sellToken][buyToken];
            uint num;
            uint den;
            (num, den) = getCurrentAuctionPrice(sellToken, buyToken, auctionIndex);
             
            if (sellVolume > 0) {
                uint outstandingVolume = atleastZero(int(mul(sellVolume, num) / den - buyVolume));

                if (outstandingVolume == 0) {
                    postBuyOrder(sellToken, buyToken, auctionIndex, 0);
                }
            }
        }
    }

     
    function getUnclaimedBuyerFunds(address sellToken, address buyToken, address user, uint auctionIndex)
        public
        view
        returns (
         
        uint unclaimedBuyerFunds,
        uint num,
        uint den
    )
    {
         
        require(auctionIndex <= getAuctionIndex(sellToken, buyToken));

        (num, den) = getCurrentAuctionPrice(sellToken, buyToken, auctionIndex);

        if (num == 0) {
             
             
            unclaimedBuyerFunds = 0;
        } else {
            uint buyerBalance = buyerBalances[sellToken][buyToken][auctionIndex][user];
             
            unclaimedBuyerFunds = atleastZero(
                int(mul(buyerBalance, den) / num - claimedAmounts[sellToken][buyToken][auctionIndex][user])
            );
        }
    }

    function getFeeRatio(address user)
        public
        view
        returns (
         
        uint num,
        uint den
    )
    {
        uint totalSupply = frtToken.totalSupply();
        uint lockedFrt = frtToken.lockedTokenBalances(user);

         

        if (lockedFrt * 10000 < totalSupply || totalSupply == 0) {
             
             
            num = 1;
            den = 200;
        } else if (lockedFrt * 1000 < totalSupply) {
             
             
            num = 1;
            den = 250;
        } else if (lockedFrt * 100 < totalSupply) {
             
             
            num = 3;
            den = 1000;
        } else if (lockedFrt * 10 < totalSupply) {
             
             
            num = 1;
            den = 500;
        } else {
             
             
            num = 1;
            den = 1000;
        }
    }

     
     
     
     
    function getPriceInPastAuction(
        address token1,
        address token2,
        uint auctionIndex
    )
        public
        view
         
        returns (uint num, uint den)
    {
        if (token1 == token2) {
             
            num = 1;
            den = 1;
        } else {
             
             
             

             
             
            require(auctionIndex <= getAuctionIndex(token1, token2));
             

            uint i = 0;
            bool correctPair = false;
            Fraction memory closingPriceToken1;
            Fraction memory closingPriceToken2;

            while (!correctPair) {
                closingPriceToken2 = closingPrices[token2][token1][auctionIndex - i];
                closingPriceToken1 = closingPrices[token1][token2][auctionIndex - i];

                if (closingPriceToken1.num > 0 && closingPriceToken1.den > 0 ||
                    closingPriceToken2.num > 0 && closingPriceToken2.den > 0)
                {
                    correctPair = true;
                }
                i++;
            }

             
             
            if (closingPriceToken1.num == 0 || closingPriceToken1.den == 0) {
                num = closingPriceToken2.den;
                den = closingPriceToken2.num;
            } else if (closingPriceToken2.num == 0 || closingPriceToken2.den == 0) {
                num = closingPriceToken1.num;
                den = closingPriceToken1.den;
            } else {
                 
                num = closingPriceToken2.den + closingPriceToken1.num;
                den = closingPriceToken2.num + closingPriceToken1.den;
            }
        }
    }

    function scheduleNextAuction(
        address sellToken,
        address buyToken
    )
        internal
    {
        (uint sellVolume, uint sellVolumeOpp) = getSellVolumesInUSD(sellToken, buyToken);

        bool enoughSellVolume = sellVolume >= thresholdNewAuction;
        bool enoughSellVolumeOpp = sellVolumeOpp >= thresholdNewAuction;
        bool schedule;
         
        if (enoughSellVolume && enoughSellVolumeOpp) {
            schedule = true;
        } else if (enoughSellVolume || enoughSellVolumeOpp) {
             
             
            uint latestAuctionIndex = getAuctionIndex(sellToken, buyToken);
            uint clearingTime = getClearingTime(sellToken, buyToken, latestAuctionIndex - 1);
            schedule = clearingTime <= now - 24 hours;
        }

        if (schedule) {
             
            setAuctionStart(sellToken, buyToken, WAITING_PERIOD_NEW_AUCTION);
        } else {
            resetAuctionStart(sellToken, buyToken);
        }
    }

    function getSellVolumesInUSD(
        address sellToken,
        address buyToken
    )
        internal
        view
        returns (uint sellVolume, uint sellVolumeOpp)
    {
         
        uint ethUSDPrice = ethUSDOracle.getUSDETHPrice();

        uint sellNum;
        uint sellDen;
        (sellNum, sellDen) = getPriceOfTokenInLastAuction(sellToken);

        uint buyNum;
        uint buyDen;
        (buyNum, buyDen) = getPriceOfTokenInLastAuction(buyToken);

         
         
         
         

         
        sellVolume = mul(mul(sellVolumesCurrent[sellToken][buyToken], sellNum), ethUSDPrice) / sellDen;
        sellVolumeOpp = mul(mul(sellVolumesCurrent[buyToken][sellToken], buyNum), ethUSDPrice) / buyDen;
    }

     
     
     
    function getPriceOfTokenInLastAuction(address token)
        public
        view
        returns (
         
        uint num,
        uint den
    )
    {
        uint latestAuctionIndex = getAuctionIndex(token, ethToken);
         
        (num, den) = getPriceInPastAuction(token, ethToken, latestAuctionIndex - 1);
    }

    function getCurrentAuctionPrice(address sellToken, address buyToken, uint auctionIndex)
        public
        view
        returns (
         
        uint num,
        uint den
    )
    {
        Fraction memory closingPrice = closingPrices[sellToken][buyToken][auctionIndex];

        if (closingPrice.den != 0) {
             
            (num, den) = (closingPrice.num, closingPrice.den);
        } else if (auctionIndex > getAuctionIndex(sellToken, buyToken)) {
            (num, den) = (0, 0);
        } else {
             
            uint pastNum;
            uint pastDen;
            (pastNum, pastDen) = getPriceInPastAuction(sellToken, buyToken, auctionIndex - 1);

             
             
            uint timeElapsed = atleastZero(int(now - getAuctionStart(sellToken, buyToken)));

             
             

             
            num = atleastZero(int((24 hours - timeElapsed) * pastNum));
             
            den = mul((timeElapsed + 12 hours), pastDen);

            if (mul(num, sellVolumesCurrent[sellToken][buyToken]) <= mul(den, buyVolumes[sellToken][buyToken])) {
                num = buyVolumes[sellToken][buyToken];
                den = sellVolumesCurrent[sellToken][buyToken];
            }
        }
    }

     
    function getTokenOrder(address token1, address token2) public pure returns (address, address) {
        if (token2 < token1) {
            (token1, token2) = (token2, token1);
        }

        return (token1, token2);
    }

    function getAuctionStart(address token1, address token2) public view returns (uint auctionStart) {
        (token1, token2) = getTokenOrder(token1, token2);
        auctionStart = auctionStarts[token1][token2];
    }

    function getAuctionIndex(address token1, address token2) public view returns (uint auctionIndex) {
        (token1, token2) = getTokenOrder(token1, token2);
        auctionIndex = latestAuctionIndices[token1][token2];
    }

    function calculateFundedValueTokenToken(
        address token1,
        address token2,
        uint token1Funding,
        uint token2Funding,
        address ethTokenMem,
        uint ethUSDPrice
    )
        internal
        view
        returns (uint fundedValueUSD)
    {
         
         
        require(getAuctionIndex(token1, ethTokenMem) > 0);

         
        require(getAuctionIndex(token2, ethTokenMem) > 0);

         
        uint priceToken1Num;
        uint priceToken1Den;
        (priceToken1Num, priceToken1Den) = getPriceOfTokenInLastAuction(token1);

         
        uint priceToken2Num;
        uint priceToken2Den;
        (priceToken2Num, priceToken2Den) = getPriceOfTokenInLastAuction(token2);

         
         
        uint fundedValueETH = add(
            mul(token1Funding, priceToken1Num) / priceToken1Den,
            token2Funding * priceToken2Num / priceToken2Den
        );

        fundedValueUSD = mul(fundedValueETH, ethUSDPrice);
    }

    function addTokenPairSecondPart(
        address token1,
        address token2,
        uint token1Funding,
        uint token2Funding
    )
        internal
    {
        balances[token1][msg.sender] = sub(balances[token1][msg.sender], token1Funding);
        balances[token2][msg.sender] = sub(balances[token2][msg.sender], token2Funding);

         
        uint token1FundingAfterFee = settleFee(token1, token2, 1, token1Funding);
        uint token2FundingAfterFee = settleFee(token2, token1, 1, token2Funding);

         
        sellVolumesCurrent[token1][token2] = token1FundingAfterFee;
        sellVolumesCurrent[token2][token1] = token2FundingAfterFee;
        sellerBalances[token1][token2][1][msg.sender] = token1FundingAfterFee;
        sellerBalances[token2][token1][1][msg.sender] = token2FundingAfterFee;

         
        (address tokenA, address tokenB) = getTokenOrder(token1, token2);
        clearingTimes[tokenA][tokenB][0] = now;

        setAuctionStart(token1, token2, WAITING_PERIOD_NEW_TOKEN_PAIR);
        emit NewTokenPair(token1, token2);
    }

    function setClearingTime(
        address token1,
        address token2,
        uint auctionIndex,
        uint auctionStart,
        uint sellVolume,
        uint buyVolume
    )
        internal
    {
        (uint pastNum, uint pastDen) = getPriceInPastAuction(token1, token2, auctionIndex - 1);
         
             
        uint numerator = sub(mul(mul(pastNum, sellVolume), 24 hours), mul(mul(buyVolume, pastDen), 12 hours));
        uint timeElapsed = numerator / (add(mul(sellVolume, pastNum), mul(buyVolume, pastDen)));
        uint clearingTime = auctionStart + timeElapsed;
        (token1, token2) = getTokenOrder(token1, token2);
        clearingTimes[token1][token2][auctionIndex] = clearingTime;
    }

    function getClearingTime(
        address token1,
        address token2,
        uint auctionIndex
    )
        public
        view
        returns (uint time)
    {
        (token1, token2) = getTokenOrder(token1, token2);
        time = clearingTimes[token1][token2][auctionIndex];
    }

    function issueFrts(
        address primaryToken,
        address secondaryToken,
        uint x,
        uint auctionIndex,
        uint bal,
        address user
    )
        internal
        returns (uint frtsIssued)
    {
        if (approvedTokens[primaryToken] && approvedTokens[secondaryToken]) {
            address ethTokenMem = ethToken;
             
            if (primaryToken == ethTokenMem) {
                frtsIssued = bal;
            } else if (secondaryToken == ethTokenMem) {
                 
                frtsIssued = x;
            } else {
                 
                uint pastNum;
                uint pastDen;
                (pastNum, pastDen) = getPriceInPastAuction(primaryToken, ethTokenMem, auctionIndex - 1);
                 
                frtsIssued = mul(bal, pastNum) / pastDen;
            }

            if (frtsIssued > 0) {
                 
                frtToken.mintTokens(user, frtsIssued);
            }
        }
    }

    function settleFee(address primaryToken, address secondaryToken, uint auctionIndex, uint amount)
        internal
        returns (
         
        uint amountAfterFee
    )
    {
        uint feeNum;
        uint feeDen;
        (feeNum, feeDen) = getFeeRatio(msg.sender);
         
        uint fee = mul(amount, feeNum) / feeDen;

        if (fee > 0) {
            fee = settleFeeSecondPart(primaryToken, fee);

            uint usersExtraTokens = extraTokens[primaryToken][secondaryToken][auctionIndex + 1];
            extraTokens[primaryToken][secondaryToken][auctionIndex + 1] = add(usersExtraTokens, fee);

            emit Fee(primaryToken, secondaryToken, msg.sender, auctionIndex, fee);
        }

        amountAfterFee = sub(amount, fee);
    }

    function settleFeeSecondPart(address primaryToken, uint fee) internal returns (uint newFee) {
         
        uint num;
        uint den;
        (num, den) = getPriceOfTokenInLastAuction(primaryToken);

         
         
        uint feeInETH = mul(fee, num) / den;

        uint ethUSDPrice = ethUSDOracle.getUSDETHPrice();
         
         
        uint feeInUSD = mul(feeInETH, ethUSDPrice);
        uint amountOfowlTokenBurned = min(owlToken.allowance(msg.sender, address(this)), feeInUSD / 2);
        amountOfowlTokenBurned = min(owlToken.balanceOf(msg.sender), amountOfowlTokenBurned);

        if (amountOfowlTokenBurned > 0) {
            owlToken.burnOWL(msg.sender, amountOfowlTokenBurned);
             
             
            uint adjustment = mul(amountOfowlTokenBurned, fee) / feeInUSD;
            newFee = sub(fee, adjustment);
        } else {
            newFee = fee;
        }
    }

     
     
     
     
     
    function clearAuction(
        address sellToken,
        address buyToken,
        uint auctionIndex,
        uint sellVolume
    )
        internal
    {
         
        uint buyVolume = buyVolumes[sellToken][buyToken];
        uint sellVolumeOpp = sellVolumesCurrent[buyToken][sellToken];
        uint closingPriceOppDen = closingPrices[buyToken][sellToken][auctionIndex].den;
        uint auctionStart = getAuctionStart(sellToken, buyToken);

         
        if (sellVolume > 0) {
            closingPrices[sellToken][buyToken][auctionIndex] = Fraction(buyVolume, sellVolume);
        }

         
         
        if (sellVolumeOpp == 0 || now >= auctionStart + 24 hours || closingPriceOppDen > 0) {
             
            uint buyVolumeOpp = buyVolumes[buyToken][sellToken];
            if (closingPriceOppDen == 0 && sellVolumeOpp > 0) {
                 
                closingPrices[buyToken][sellToken][auctionIndex] = Fraction(buyVolumeOpp, sellVolumeOpp);
            }

            uint sellVolumeNext = sellVolumesNext[sellToken][buyToken];
            uint sellVolumeNextOpp = sellVolumesNext[buyToken][sellToken];

             
            sellVolumesCurrent[sellToken][buyToken] = sellVolumeNext;
            if (sellVolumeNext > 0) {
                sellVolumesNext[sellToken][buyToken] = 0;
            }
            if (buyVolume > 0) {
                buyVolumes[sellToken][buyToken] = 0;
            }

            sellVolumesCurrent[buyToken][sellToken] = sellVolumeNextOpp;
            if (sellVolumeNextOpp > 0) {
                sellVolumesNext[buyToken][sellToken] = 0;
            }
            if (buyVolumeOpp > 0) {
                buyVolumes[buyToken][sellToken] = 0;
            }

             
            setClearingTime(sellToken, buyToken, auctionIndex, auctionStart, sellVolume, buyVolume);
             
            setAuctionIndex(sellToken, buyToken);
             
            scheduleNextAuction(sellToken, buyToken);
        }

        emit AuctionCleared(sellToken, buyToken, sellVolume, buyVolume, auctionIndex);
    }

    function setAuctionStart(address token1, address token2, uint value) internal {
        (token1, token2) = getTokenOrder(token1, token2);
        uint auctionStart = now + value;
        uint auctionIndex = latestAuctionIndices[token1][token2];
        auctionStarts[token1][token2] = auctionStart;
        emit AuctionStartScheduled(token1, token2, auctionIndex, auctionStart);
    }

    function resetAuctionStart(address token1, address token2) internal {
        (token1, token2) = getTokenOrder(token1, token2);
        if (auctionStarts[token1][token2] != AUCTION_START_WAITING_FOR_FUNDING) {
            auctionStarts[token1][token2] = AUCTION_START_WAITING_FOR_FUNDING;
        }
    }

    function setAuctionIndex(address token1, address token2) internal {
        (token1, token2) = getTokenOrder(token1, token2);
        latestAuctionIndices[token1][token2] += 1;
    }

    function checkLengthsForSeveralAuctionClaiming(
        address[] memory auctionSellTokens,
        address[] memory auctionBuyTokens,
        uint[] memory auctionIndices
    ) internal pure returns (uint length)
    {
        length = auctionSellTokens.length;
        uint length2 = auctionBuyTokens.length;
        require(length == length2);

        uint length3 = auctionIndices.length;
        require(length2 == length3);
    }

     
    event NewDeposit(address indexed token, uint amount);

    event NewWithdrawal(address indexed token, uint amount);

    event NewSellOrder(
        address indexed sellToken,
        address indexed buyToken,
        address indexed user,
        uint auctionIndex,
        uint amount
    );

    event NewBuyOrder(
        address indexed sellToken,
        address indexed buyToken,
        address indexed user,
        uint auctionIndex,
        uint amount
    );

    event NewSellerFundsClaim(
        address indexed sellToken,
        address indexed buyToken,
        address indexed user,
        uint auctionIndex,
        uint amount,
        uint frtsIssued
    );

    event NewBuyerFundsClaim(
        address indexed sellToken,
        address indexed buyToken,
        address indexed user,
        uint auctionIndex,
        uint amount,
        uint frtsIssued
    );

    event NewTokenPair(address indexed sellToken, address indexed buyToken);

    event AuctionCleared(
        address indexed sellToken,
        address indexed buyToken,
        uint sellVolume,
        uint buyVolume,
        uint indexed auctionIndex
    );

    event AuctionStartScheduled(
        address indexed sellToken,
        address indexed buyToken,
        uint indexed auctionIndex,
        uint auctionStart
    );

    event Fee(
        address indexed primaryToken,
        address indexed secondarToken,
        address indexed user,
        uint auctionIndex,
        uint fee
    );
}

 

 
 
contract EtherToken is GnosisStandardToken {
    using GnosisMath for *;

     
    event Deposit(address indexed sender, uint value);
    event Withdrawal(address indexed receiver, uint value);

     
    string public constant name = "Ether Token";
    string public constant symbol = "ETH";
    uint8 public constant decimals = 18;

     
     
    function deposit() public payable {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        totalTokens = totalTokens.add(msg.value);
        emit Deposit(msg.sender, msg.value);
    }

     
     
    function withdraw(uint value) public {
         
        balances[msg.sender] = balances[msg.sender].sub(value);
        totalTokens = totalTokens.sub(value);
        msg.sender.transfer(value);
        emit Withdrawal(msg.sender, value);
    }
}

 

interface KyberNetworkProxy {
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty)
        external
        view
        returns (uint expectedRate, uint slippageRate);
}


contract KyberDxMarketMaker is Withdrawable {
     
    ERC20 constant internal KYBER_ETH_TOKEN = ERC20(
        0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
    );

     
    uint public constant DX_AUCTION_START_WAITING_FOR_FUNDING = 1;

    enum AuctionState {
        WAITING_FOR_FUNDING,
        WAITING_FOR_OPP_FUNDING,
        WAITING_FOR_SCHEDULED_AUCTION,
        AUCTION_IN_PROGRESS,
        WAITING_FOR_OPP_TO_FINISH,
        AUCTION_EXPIRED
    }

     
    AuctionState constant public WAITING_FOR_FUNDING = AuctionState.WAITING_FOR_FUNDING;
    AuctionState constant public WAITING_FOR_OPP_FUNDING = AuctionState.WAITING_FOR_OPP_FUNDING;
    AuctionState constant public WAITING_FOR_SCHEDULED_AUCTION = AuctionState.WAITING_FOR_SCHEDULED_AUCTION;
    AuctionState constant public AUCTION_IN_PROGRESS = AuctionState.AUCTION_IN_PROGRESS;
    AuctionState constant public WAITING_FOR_OPP_TO_FINISH = AuctionState.WAITING_FOR_OPP_TO_FINISH;
    AuctionState constant public AUCTION_EXPIRED = AuctionState.AUCTION_EXPIRED;

    DutchExchange public dx;
    EtherToken public weth;
    KyberNetworkProxy public kyberNetworkProxy;

     
    mapping (address => mapping (address => uint)) public lastParticipatedAuction;

    constructor(
        DutchExchange _dx,
        KyberNetworkProxy _kyberNetworkProxy
    ) public {
        require(
            address(_dx) != address(0),
            "DutchExchange address cannot be 0"
        );
        require(
            address(_kyberNetworkProxy) != address(0),
            "KyberNetworkProxy address cannot be 0"
        );

        dx = DutchExchange(_dx);
        weth = EtherToken(dx.ethToken());
        kyberNetworkProxy = KyberNetworkProxy(_kyberNetworkProxy);
    }

    event KyberNetworkProxyUpdated(
        KyberNetworkProxy kyberNetworkProxy
    );

    function setKyberNetworkProxy(
        KyberNetworkProxy _kyberNetworkProxy
    )
        public
        onlyAdmin
        returns (bool)
    {
        require(
            address(_kyberNetworkProxy) != address(0),
            "KyberNetworkProxy address cannot be 0"
        );

        kyberNetworkProxy = _kyberNetworkProxy;
        emit KyberNetworkProxyUpdated(kyberNetworkProxy);
        return true;
    }

    event AmountDepositedToDx(
        address indexed token,
        uint amount
    );

    function depositToDx(
        address token,
        uint amount
    )
        public
        onlyOperator
        returns (uint)
    {
        require(ERC20(token).approve(address(dx), amount), "Cannot approve deposit");
        uint deposited = dx.deposit(token, amount);
        emit AmountDepositedToDx(token, deposited);
        return deposited;
    }

    event AmountWithdrawnFromDx(
        address indexed token,
        uint amount
    );

    function withdrawFromDx(
        address token,
        uint amount
    )
        public
        onlyOperator
        returns (uint)
    {
        uint withdrawn = dx.withdraw(token, amount);
        emit AmountWithdrawnFromDx(token, withdrawn);
        return withdrawn;
    }

     
    function claimSpecificAuctionFunds(
        address sellToken,
        address buyToken,
        uint auctionIndex
    )
        public
        returns (uint sellerFunds, uint buyerFunds)
    {
        uint availableFunds;
        availableFunds = dx.sellerBalances(
            sellToken,
            buyToken,
            auctionIndex,
            address(this)
        );
        if (availableFunds > 0) {
            (sellerFunds, ) = dx.claimSellerFunds(
                sellToken,
                buyToken,
                address(this),
                auctionIndex
            );
        }

        availableFunds = dx.buyerBalances(
            sellToken,
            buyToken,
            auctionIndex,
            address(this)
        );
        if (availableFunds > 0) {
            (buyerFunds, ) = dx.claimBuyerFunds(
                sellToken,
                buyToken,
                address(this),
                auctionIndex
            );
        }
    }

     
     
    function step(
        address sellToken,
        address buyToken
    )
        public
        onlyOperator
        returns (bool)
    {
         
         
         
         
         
        require(
            ERC20(sellToken).decimals() == 18 && ERC20(buyToken).decimals() == 18,
            "Only 18 decimals tokens are supported"
        );

         
        depositAllBalance(sellToken);
        depositAllBalance(buyToken);

        AuctionState state = getAuctionState(sellToken, buyToken);
        uint auctionIndex = dx.getAuctionIndex(sellToken, buyToken);
        emit CurrentAuctionState(sellToken, buyToken, auctionIndex, state);

        if (state == AuctionState.WAITING_FOR_FUNDING) {
             
            claimSpecificAuctionFunds(
                sellToken,
                buyToken,
                lastParticipatedAuction[sellToken][buyToken]
            );
            require(fundAuctionDirection(sellToken, buyToken));
            return true;
        }

        if (state == AuctionState.WAITING_FOR_OPP_FUNDING ||
            state == AuctionState.WAITING_FOR_SCHEDULED_AUCTION) {
            return false;
        }

        if (state == AuctionState.AUCTION_IN_PROGRESS) {
            if (isPriceRightForBuying(sellToken, buyToken, auctionIndex)) {
                return buyInAuction(sellToken, buyToken);
            }
            return false;
        }

        if (state == AuctionState.WAITING_FOR_OPP_TO_FINISH) {
            return false;
        }

        if (state == AuctionState.AUCTION_EXPIRED) {
            dx.closeTheoreticalClosedAuction(sellToken, buyToken, auctionIndex);
            dx.closeTheoreticalClosedAuction(buyToken, sellToken, auctionIndex);
            return true;
        }

         
        revert("Unknown auction state");
    }

    function willAmountClearAuction(
        address sellToken,
        address buyToken,
        uint auctionIndex,
        uint amount
    )
        public
        view
        returns (bool)
    {
        uint buyVolume = dx.buyVolumes(sellToken, buyToken);

         
         
         
        uint sellVolume = dx.sellVolumesCurrent(sellToken, buyToken);

        uint num;
        uint den;
        (num, den) = dx.getCurrentAuctionPrice(sellToken, buyToken, auctionIndex);
         
        uint outstandingVolume = atleastZero(int(div(mul(sellVolume, num), sub(den, buyVolume))));
        return amount >= outstandingVolume;
    }

     
    function thresholdNewAuctionToken(
        address token
    )
        public
        view
        returns (uint)
    {
        uint priceTokenNum;
        uint priceTokenDen;
        (priceTokenNum, priceTokenDen) = dx.getPriceOfTokenInLastAuction(token);

         
         
        return 1 + div(
             
            mul(
                dx.thresholdNewAuction(),
                priceTokenDen
            ),
            mul(
                dx.ethUSDOracle().getUSDETHPrice(),
                priceTokenNum
            )
        );
    }

    function calculateMissingTokenForAuctionStart(
        address sellToken,
        address buyToken
    )
        public
        view
        returns (uint)
    {
        uint currentAuctionSellVolume = dx.sellVolumesCurrent(sellToken, buyToken);
        uint thresholdTokenWei = thresholdNewAuctionToken(sellToken);

        if (thresholdTokenWei > currentAuctionSellVolume) {
            return sub(thresholdTokenWei, currentAuctionSellVolume);
        }

        return 0;
    }

    function addFee(
        uint amount
    )
        public
        view
        returns (uint)
    {
        uint num;
        uint den;
        (num, den) = dx.getFeeRatio(msg.sender);

         
        return div(
            mul(amount, den),
            sub(den, num)
        );
    }

    function getAuctionState(
        address sellToken,
        address buyToken
    )
        public
        view
        returns (AuctionState)
    {

         
        uint auctionStart = dx.getAuctionStart(sellToken, buyToken);
        if (auctionStart == DX_AUCTION_START_WAITING_FOR_FUNDING) {
             
             
            if (calculateMissingTokenForAuctionStart(sellToken, buyToken) > 0) {
                return AuctionState.WAITING_FOR_FUNDING;
            } else {
                return AuctionState.WAITING_FOR_OPP_FUNDING;
            }
        }

         
         
        if (auctionStart > now) {
             
             
             
             
            if (calculateMissingTokenForAuctionStart(sellToken, buyToken) > 0) {
                return AuctionState.WAITING_FOR_FUNDING;
            } else {
                return AuctionState.WAITING_FOR_SCHEDULED_AUCTION;
            }
        }

         
         
         
        if (now - auctionStart > 24 hours) {
            return AuctionState.AUCTION_EXPIRED;
        }

        uint auctionIndex = dx.getAuctionIndex(sellToken, buyToken);
        uint closingPriceDen;
        (, closingPriceDen) = dx.closingPrices(sellToken, buyToken, auctionIndex);
        if (closingPriceDen == 0) {
            return AuctionState.AUCTION_IN_PROGRESS;
        }

        return AuctionState.WAITING_FOR_OPP_TO_FINISH;
    }

    function getKyberRate(
        address srcToken,
        address destToken,
        uint amount
    )
        public
        view
        returns (uint num, uint den)
    {
         
         
         
         
         
        require(
            ERC20(srcToken).decimals() == 18 && ERC20(destToken).decimals() == 18,
            "Only 18 decimals tokens are supported"
        );

         
        uint rate;
        (rate, ) = kyberNetworkProxy.getExpectedRate(
            srcToken == address(weth) ? KYBER_ETH_TOKEN : ERC20(srcToken),
            destToken == address(weth) ? KYBER_ETH_TOKEN : ERC20(destToken),
            amount
        );

        return (rate, 10 ** 18);
    }

    function tokensSoldInCurrentAuction(
        address sellToken,
        address buyToken,
        uint auctionIndex,
        address account
    )
        public
        view
        returns (uint)
    {
        return dx.sellerBalances(sellToken, buyToken, auctionIndex, account);
    }

     
     
    function calculateAuctionBuyTokens(
        address sellToken,
        address buyToken,
        uint auctionIndex,
        address account
    )
        public
        view
        returns (uint)
    {
        uint sellVolume = tokensSoldInCurrentAuction(
            sellToken,
            buyToken,
            auctionIndex,
            account
        );

        uint num;
        uint den;
        (num, den) = dx.getCurrentAuctionPrice(
            sellToken,
            buyToken,
            auctionIndex
        );

         
        if (den == 0) return 0;

        uint desiredBuyVolume = div(mul(sellVolume, num), den);

         
        uint auctionSellVolume = dx.sellVolumesCurrent(sellToken, buyToken);
        uint existingBuyVolume = dx.buyVolumes(sellToken, buyToken);
        uint availableBuyVolume = atleastZero(
            int(mul(auctionSellVolume, num) / den - existingBuyVolume)
        );

        return desiredBuyVolume < availableBuyVolume
            ? desiredBuyVolume
            : availableBuyVolume;
    }

    function atleastZero(int a)
        public
        pure
        returns (uint)
    {
        if (a < 0) {
            return 0;
        } else {
            return uint(a);
        }
    }

    event Execution(
        bool success,
        address caller,
        address destination,
        uint value,
        bytes data,
        bytes result
    );

     
    function executeTransaction(
        address destination,
        uint value,
        bytes memory data
    )
        public
        onlyAdmin
    {
        (bool success, bytes memory result) = destination.call.value(value)(data);
        if (success) {
            emit Execution(true, msg.sender, destination, value, data, result);
        } else {
            revert();
        }
    }

    function adminBuyInAuction(
        address sellToken,
        address buyToken
    )
        public
        onlyAdmin
        returns (bool bought)
    {
        return buyInAuction(sellToken, buyToken);
    }

    event AuctionDirectionFunded(
        address indexed sellToken,
        address indexed buyToken,
        uint indexed auctionIndex,
        uint sellTokenAmount,
        uint sellTokenAmountWithFee
    );

    function fundAuctionDirection(
        address sellToken,
        address buyToken
    )
        internal
        returns (bool)
    {
        uint missingTokens = calculateMissingTokenForAuctionStart(
            sellToken,
            buyToken
        );
        uint missingTokensWithFee = addFee(missingTokens);
        if (missingTokensWithFee == 0) return false;

        uint balance = dx.balances(sellToken, address(this));
        require(
            balance >= missingTokensWithFee,
            "Not enough tokens to fund auction direction"
        );

        uint auctionIndex = dx.getAuctionIndex(sellToken, buyToken);
        dx.postSellOrder(sellToken, buyToken, auctionIndex, missingTokensWithFee);
        lastParticipatedAuction[sellToken][buyToken] = auctionIndex;

        emit AuctionDirectionFunded(
            sellToken,
            buyToken,
            auctionIndex,
            missingTokens,
            missingTokensWithFee
        );
        return true;
    }

     
    event BoughtInAuction(
        address indexed sellToken,
        address indexed buyToken,
        uint auctionIndex,
        uint buyTokenAmount,
        bool clearedAuction
    );

     
    function buyInAuction(
        address sellToken,
        address buyToken
    )
        internal
        returns (bool bought)
    {
        require(
            getAuctionState(sellToken, buyToken) == AuctionState.AUCTION_IN_PROGRESS,
            "No auction in progress"
        );

        uint auctionIndex = dx.getAuctionIndex(sellToken, buyToken);
        uint buyTokenAmount = calculateAuctionBuyTokens(
            sellToken,
            buyToken,
            auctionIndex,
            address(this)
        );

        if (buyTokenAmount == 0) {
            return false;
        }

        bool willClearAuction = willAmountClearAuction(
            sellToken,
            buyToken,
            auctionIndex,
            buyTokenAmount
        );
        if (!willClearAuction) {
            buyTokenAmount = addFee(buyTokenAmount);
        }

        require(
            dx.balances(buyToken, address(this)) >= buyTokenAmount,
            "Not enough buy token to buy required amount"
        );

        dx.postBuyOrder(sellToken, buyToken, auctionIndex, buyTokenAmount);
        emit BoughtInAuction(
            sellToken,
            buyToken,
            auctionIndex,
            buyTokenAmount,
            willClearAuction
        );
        return true;
    }

    function depositAllBalance(
        address token
    )
        internal
        returns (uint)
    {
        uint amount;
        uint balance = ERC20(token).balanceOf(address(this));
        if (balance > 0) {
            amount = depositToDx(token, balance);
        }
        return amount;
    }

    event CurrentAuctionState(
        address indexed sellToken,
        address indexed buyToken,
        uint auctionIndex,
        AuctionState auctionState
    );

    event PriceIsRightForBuying(
        address indexed sellToken,
        address indexed buyToken,
        uint auctionIndex,
        uint amount,
        uint dutchExchangePriceNum,
        uint dutchExchangePriceDen,
        uint kyberPriceNum,
        uint kyberPriceDen,
        bool shouldBuy
    );

    function isPriceRightForBuying(
        address sellToken,
        address buyToken,
        uint auctionIndex
    )
        internal
        returns (bool)
    {
        uint amount = calculateAuctionBuyTokens(
            sellToken,
            buyToken,
            auctionIndex,
            address(this)
        );

        uint dNum;
        uint dDen;
        (dNum, dDen) = dx.getCurrentAuctionPrice(
            sellToken,
            buyToken,
            auctionIndex
        );

         
         
        uint kNum;
        uint kDen;
        (kNum, kDen) = getKyberRate(
            buyToken,  
            sellToken,  
            amount
        );

         
        bool shouldBuy = mul(dNum, kDen) <= mul(kNum, dDen);
         
        emit PriceIsRightForBuying(
            sellToken,
            buyToken,
            auctionIndex,
            amount,
            dNum,
            dDen,
            kNum,
            kDen,
            shouldBuy
        );
        return shouldBuy;
    }

     
     
     
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
}