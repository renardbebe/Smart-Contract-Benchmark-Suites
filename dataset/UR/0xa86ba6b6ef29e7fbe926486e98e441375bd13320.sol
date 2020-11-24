 

pragma solidity ^0.5.0;

 
contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

 
contract Owned {
    address public owner = msg.sender;

    modifier isOwner {
        assert(msg.sender == owner); _;
    }

    function changeOwner(address account) external isOwner {
        owner = account;
    }
}

 
contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused;

    modifier pausable {
        assert(!paused); _;
    }

    function pause() external isOwner {
        paused = true;

        emit Pause();
    }

    function unpause() external isOwner {
        paused = false;

        emit Unpause();
    }
}

 
contract BurnerAccount is Owned {
    address public burner;

    modifier isOwnerOrBurner {
        assert(msg.sender == burner || msg.sender == owner); _;
    }

    function changeBurner(address account) external isOwner {
        burner = account;
    }
}

 
contract IntervalBased is DSMath {
     
    uint256 public intervalStartTimestamp;

     
    uint256 public intervalDuration;

     
    uint256 public intervalMaximum;

     
    uint256 public intervalOffset;

    function changeDuration(uint256 duration) internal {
       
      if (duration == intervalDuration) { return; }

       
      intervalOffset = intervalNumber(block.timestamp);

       
      intervalDuration = duration;

       
      intervalStartTimestamp = block.timestamp;
    }

     
     
    function intervalNumber(uint256 timestamp) public view returns(uint256 number) {
        return add(intervalOffset, sub(timestamp, intervalStartTimestamp) / intervalDuration);
    }
}

 
contract ERC20Events {
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

 
contract ERC20 is ERC20Events {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint);
    function allowance(address tokenOwner, address spender) external view returns (uint);

    function approve(address spender, uint amount) public returns (bool);
    function transfer(address to, uint amount) external returns (bool);
    function transferFrom(
        address from, address to, uint amount
    ) public returns (bool);
}

 
contract ERC20Token is DSMath, ERC20 {
     
    string public symbol = "USDC";
    string public name = "UnityCoinTest";
    string public version = "1.0.0";
    uint8 public decimals = 18;

     
    mapping(address => uint256) balances;

     
    mapping(address => mapping (address => uint256)) approvals;

     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
    function transfer(address to, uint256 tokens) external returns (bool success) {
        return transferFrom(msg.sender, to, tokens);
    }

     
     
     
     
     
     
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        if (from != msg.sender) {
            approvals[from][msg.sender] = sub(approvals[from][msg.sender], tokens);
        }

        balances[from] = sub(balances[from], tokens);
        balances[to] = add(balances[to], tokens);

        emit Transfer(from, to, tokens);
        return true;
    }

     
     
    function approve(address spender, uint256 tokens) public returns (bool success) {
        approvals[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) external view returns (uint remaining) {
        return approvals[tokenOwner][spender];
    }
}

 
contract InterestRateBased is IntervalBased {
     
    struct InterestRate {
        uint256 interval;
        uint256 rate;  
    }

     
    InterestRate[] public interestRates;

     
    mapping(uint256 => uint256) public intervalToInterestIndex;

     
    struct BalanceRecord {
        uint256 interval;
        uint256 intervalOffset;
        uint256 balance;
    }

     
    mapping(address => BalanceRecord[]) public balanceRecords;

     
    mapping(address => uint256) public lastClaimedBalanceIndex;

     
    function balanceOf(address tokenOwner) public view returns (uint);

     
    function latestInterestRate() external view returns (uint256 rateAsRay, uint256 asOfInterval) {
        uint256 latestRateIndex = interestRates.length > 0 ? sub(interestRates.length, 1) : 0;

        return (interestRates[latestRateIndex].rate, interestRates[latestRateIndex].interval);
    }

     
    function numInterestRates() public view returns (uint256) {
      return interestRates.length;
    }

     
    function numBalanceRecords(address tokenOwner) public view returns (uint256) {
      return balanceRecords[tokenOwner].length;
    }

     
    function interestOwed(address tokenOwner)
        public
        view
        returns (uint256 amountOwed, uint256 balanceIndex, uint256 interval) {

         
        if (balanceRecords[tokenOwner].length == 0) {
          return (0, 0, 0);
        }

         
        amountOwed = 0;
        balanceIndex = lastClaimedBalanceIndex[tokenOwner];
        interval = balanceRecords[tokenOwner][balanceIndex].intervalOffset;

         
        uint256 principle = 0;  
        uint256 interestRate = 0;  

         
        uint256 nextBalanceInterval = interval;  
        uint256 nextInterestInterval = interval;  

         
        assert(sub(intervalNumber(block.timestamp), intervalOffset) < intervalMaximum);

         
         
         
        while (interval < intervalNumber(block.timestamp)) {

             
            if (interval == nextInterestInterval) {
                uint256 interestIndex = intervalToInterestIndex[interval];

                 
                interestRate = interestRates[interestIndex].rate;

                 
                nextInterestInterval = add(interestIndex, 1) >= interestRates.length
                    ? intervalNumber(block.timestamp)
                    : interestRates[add(interestIndex, 1)].interval;
            }

             
            if (interval == nextBalanceInterval) {
                 
                principle = add(balanceRecords[tokenOwner][balanceIndex].balance, amountOwed);

                 
                balanceIndex = add(balanceIndex, 1);

                 
                nextBalanceInterval = balanceIndex >= balanceRecords[tokenOwner].length
                    ? intervalNumber(block.timestamp)
                    : balanceRecords[tokenOwner][balanceIndex].interval;
            }

             
            amountOwed = add(amountOwed, sub(wmul(principle,
                rpow(interestRate,
                    sub(min(nextBalanceInterval, nextInterestInterval), interval)) / 10 ** 9),
                        principle));

             
            interval = min(nextBalanceInterval, nextInterestInterval);
        }

         
        return (amountOwed, (balanceIndex > 0 ? sub(balanceIndex, 1) : 0), interval);
    }

     
    function recordBalance(address tokenOwner) internal {
         
        uint256 todaysInterval = intervalNumber(block.timestamp);

         
        uint256 latestBalanceIndex = balanceRecords[tokenOwner].length > 0
            ? sub(balanceRecords[tokenOwner].length, 1) : 0;

         
         
        if (balanceRecords[tokenOwner].length > 0
            && balanceRecords[tokenOwner][latestBalanceIndex].interval == todaysInterval) {
            balanceRecords[tokenOwner][latestBalanceIndex].balance = balanceOf(tokenOwner);
        } else {
            balanceRecords[tokenOwner].push(BalanceRecord({
                interval: todaysInterval,
                intervalOffset: todaysInterval,
                balance: balanceOf(tokenOwner)
            }));
        }

         
        if (intervalToInterestIndex[todaysInterval] <= 0) {
            intervalToInterestIndex[todaysInterval] = sub(interestRates.length, 1); }
    }

     
    function recordInterestRate(uint256 rate) internal {
         
        assert(rate >= RAY);

         
        uint256 todaysInterval = intervalNumber(block.timestamp);

         
        uint256 latestRateIndex = interestRates.length > 0
            ? sub(interestRates.length, 1) : 0;

         
         
        if (interestRates.length > 0
            && interestRates[latestRateIndex].interval == todaysInterval) {
            interestRates[latestRateIndex].rate = rate;
        } else {
            interestRates.push(InterestRate({
                interval: todaysInterval,
                rate: rate
            }));
        }

         
        intervalToInterestIndex[todaysInterval] = sub(interestRates.length, 1);
    }
}

 
contract PausableCompoundInterestERC20 is Pausable, BurnerAccount, InterestRateBased, ERC20Token {
     
    event Mint(address indexed to, uint256 tokens);
    event Burn(uint256 tokens);
    event InterestRateChange(uint256 intervalDuration, uint256 intervalExpiry, uint256 indexed interestRateIndex);
    event InterestClaimed(address indexed tokenOwner, uint256 amountOwed);

     
     
    address public constant interestPool = address(0xd365131390302b58A61E265744288097Bd53532e);

     
     
    address public constant supplyPool = address(0x85c05851ef3175aeFBC74EcA16F174E22b5acF28);

     
    modifier isNotPool(address tokenOwner) {
        assert(tokenOwner != supplyPool && tokenOwner != interestPool); _;
    }

     
    function totalSupply() external view returns (uint256 supplyWithAccruedInterest) {
        (uint256 amountOwed,,) = interestOwed(supplyPool);

        return add(balanceOf(supplyPool), amountOwed);
    }

     
    function mint(address to, uint256 amount) public isOwner pausable isNotPool(to) {
         
        claimInterestOwed(supplyPool);

        balances[supplyPool] = add(balances[supplyPool], amount);
        balances[to] = add(balances[to], amount);

        recordBalance(supplyPool);
        recordBalance(to);

        emit Mint(to, amount);
    }

     
    function burn(address account) external isOwnerOrBurner pausable isNotPool(account) {
         
        address target = msg.sender == burner ? burner : account;

         
        claimInterestOwed(supplyPool);

        emit Burn(balances[target]);

        balances[supplyPool] = sub(balances[supplyPool], balances[target]);
        balances[target] = 0;

         
        recordBalance(supplyPool);
        recordBalance(target);
    }

     
    function changeInterestRate(
        uint256 duration,
        uint256 maximum,
        uint256 interestRate,
        uint256 increasePool,
        uint256 decreasePool) public isOwner pausable {
         
        if (interestRates.length > 0) {
          claimInterestOwed(supplyPool); }

         
        changeDuration(duration);

         
        intervalMaximum = maximum;

         
        recordInterestRate(interestRate);

         
        balances[interestPool] = sub(add(balances[interestPool], increasePool),
          decreasePool);
    }

     
    function setInterestPool(uint256 tokens) external isOwner pausable {
        balances[interestPool] = tokens;
         
    }

     
    function claimInterestOwed(address tokenOwner) public pausable {
         
        assert(tokenOwner != interestPool);

         
        (uint256 amountOwed, uint256 balanceIndex, uint256 interval) = interestOwed(tokenOwner);

         
        lastClaimedBalanceIndex[tokenOwner] = balanceIndex;

         
        if (balanceRecords[tokenOwner].length > 0) {
          balanceRecords[tokenOwner][balanceIndex].intervalOffset = interval;
        }

         
        if (tokenOwner != supplyPool) {
          balances[interestPool] = sub(balances[interestPool], amountOwed);
        }

         
        balances[tokenOwner] = add(balances[tokenOwner], amountOwed);
        recordBalance(tokenOwner);

         
        emit InterestClaimed(tokenOwner, amountOwed);
    }

    function transferFrom(address from, address to, uint256 tokens) public pausable isNotPool(from) isNotPool(to) returns (bool success) {
        super.transferFrom(from, to, tokens);

        recordBalance(from);
        recordBalance(to);

        return true;
    }

     
     
    function approve(address spender, uint256 tokens) public pausable isNotPool(spender) returns (bool success) {
        return super.approve(spender, tokens);
    }
}

 
contract SignableCompoundInterestERC20 is PausableCompoundInterestERC20 {
     
    bytes32 constant public EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");
    bytes32 constant public SIGNEDTRANSFER_TYPEHASH = keccak256("SignedTransfer(address to,uint256 tokens,address feeRecipient,uint256 fee,uint256 expiry,bytes32 nonce)");
    bytes32 constant public SIGNEDINTERESTCLAIM_TYPEHASH = keccak256("SignedInterestClaim(address feeRecipient,uint256 fee,uint256 expiry,bytes32 nonce)");
    bytes32 public DOMAIN_SEPARATOR = keccak256(abi.encode(
        EIP712_DOMAIN_TYPEHASH,  
        keccak256("UnityCoin"),  
        keccak256("1"),  
        uint256(1),  
        address(this),  
        bytes32(0x111857f4a3edcb7462eabc03bfe733db1e3f6cdc2b7971ee739626c98268ae12)  
    ));

     
    mapping(address => mapping(bytes32 => bool)) public releaseHashes;

    event SignedTransfer(address indexed from, address indexed to, uint256 tokens, bytes32 releaseHash);
    event SignedInterestClaim(address indexed from, bytes32 releaseHash);

     
    constructor(
        address tokenOwner,  
        address tokenBurner,  

        uint256 initialSupply,  

        uint256 interestIntervalStartTimestamp,  
        uint256 interestIntervalDurationSeconds,  
        uint256 interestIntervalMaximum,  
        uint256 interestPoolSize,  
        uint256 interestRate) public {
         
        burner = tokenBurner;

         
        intervalStartTimestamp = interestIntervalStartTimestamp;

         
        intervalDuration = interestIntervalDurationSeconds;

         
        changeInterestRate(interestIntervalDurationSeconds,
            interestIntervalMaximum,
            interestRate, interestPoolSize, 0);

         
        mint(tokenOwner, initialSupply);

         
        owner = tokenOwner;
    }

     
    function signedTransfer(address to,
        uint256 tokens,
        address feeRecipient,
        uint256 fee,
        uint256 expiry,
        bytes32 nonce,
        uint8 v, bytes32 r, bytes32 s) external returns (bool success) {
        bytes32 releaseHash = keccak256(abi.encodePacked(
           "\x19\x01",
           DOMAIN_SEPARATOR,
           keccak256(abi.encode(SIGNEDTRANSFER_TYPEHASH, to, tokens, feeRecipient, fee, expiry, nonce))
        ));
        address from = ecrecover(releaseHash, v, r, s);

         
        assert(block.timestamp < expiry);
        assert(releaseHashes[from][releaseHash] == false);

         
        releaseHashes[from][releaseHash] = true;

         
        approvals[from][msg.sender] = add(tokens, fee);

         
        transferFrom(from, to, tokens);
        transferFrom(from, feeRecipient, fee);

        emit SignedTransfer(from, to, tokens, releaseHash);

        return true;
    }

     
    function signedInterestClaim(
        address feeRecipient,
        uint256 fee,
        uint256 expiry,
        bytes32 nonce,
        uint8 v, bytes32 r, bytes32 s) external returns (bool success) {
        bytes32 releaseHash = keccak256(abi.encodePacked(
           "\x19\x01",
           DOMAIN_SEPARATOR,
           keccak256(abi.encode(SIGNEDINTERESTCLAIM_TYPEHASH, feeRecipient, fee, expiry, nonce))
        ));
        address from = ecrecover(releaseHash, v, r, s);

         
        assert(block.timestamp < expiry);
        assert(releaseHashes[from][releaseHash] == false);

         
        releaseHashes[from][releaseHash] = true;

         
        claimInterestOwed(from);

         
        approvals[from][msg.sender] = fee;

         
        transferFrom(from, feeRecipient, fee);

        emit SignedInterestClaim(from, releaseHash);

        return true;
    }

     
    function invalidateHash(bytes32 releaseHash) external pausable {
      releaseHashes[msg.sender][releaseHash] = true;
    }
}