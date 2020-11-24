 

 

 

 

pragma solidity ^0.4.25;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

 
library SafeMath {

     
    function mul64(uint256 a, uint256 b) internal pure returns (uint64) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        require(c < 2**64);
        return uint64(c);
    }

     
    function div64(uint256 a, uint256 b) internal pure returns (uint64) {
        uint256 c = a / b;
        require(c < 2**64);
         
        return uint64(c);
    }

     
    function sub64(uint256 a, uint256 b) internal pure returns (uint64) {
        require(b <= a);
        uint256 c = a - b;
        require(c < 2**64);
         
        return uint64(c);
    }

     
    function add64(uint256 a, uint256 b) internal pure returns (uint64) {
        uint256 c = a + b;
        require(c >= a && c < 2**64);
         
        return uint64(c);
    }

     
    function mul32(uint256 a, uint256 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        require(c < 2**32);
         
        return uint32(c);
    }

     
    function div32(uint256 a, uint256 b) internal pure returns (uint32) {
        uint256 c = a / b;
        require(c < 2**32);
         
        return uint32(c);
    }

     
    function sub32(uint256 a, uint256 b) internal pure returns (uint32) {
        require(b <= a);
        uint256 c = a - b;
        require(c < 2**32);
         
        return uint32(c);
    }

     
    function add32(uint256 a, uint256 b) internal pure returns (uint32) {
        uint256 c = a + b;
        require(c >= a && c < 2**32);
        return uint32(c);
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
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}



 
library Merkle {

     
    function combinedHash(bytes32 a, bytes32 b) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(a, b));
    }

     
    function getProofRootHash(bytes32[] memory proof, uint256 key, bytes32 leaf) public pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(leaf));
        uint256 k = key;
        for(uint i = 0; i<proof.length; i++) {
            uint256 bit = k % 2;
            k = k / 2;

            if (bit == 0)
                hash = combinedHash(hash, proof[i]);
            else
                hash = combinedHash(proof[i], hash);
        }
        return hash;
    }
}

 
contract Data {
    struct Account {
        address owner;
        uint64  balance;
        uint32  lastCollectedPaymentId;
    }

    struct BulkRegistration {
        bytes32 rootHash;
        uint32  recordCount;
        uint32  smallestRecordId;
    }

    struct Payment {
        uint32  fromAccountId;
        uint64  amount;
        uint64  fee;
        uint32  smallestAccountId;
        uint32  greatestAccountId;
        uint32  totalNumberOfPayees;
        uint64  lockTimeoutBlockNumber;
        bytes32 paymentDataHash;
        bytes32 lockingKeyHash;
        bytes32 metadata;
    }

    struct CollectSlot {
        uint32  minPayIndex;
        uint32  maxPayIndex;
        uint64  amount;
        uint64  delegateAmount;
        uint32  to;
        uint64  block;
        uint32  delegate;
        uint32  challenger;
        uint32  index;
        uint64  challengeAmount;
        uint8   status;
        address addr;
        bytes32 data;
    }

    struct Config {
        uint32 maxBulk;
        uint32 maxTransfer;
        uint32 challengeBlocks;
        uint32 challengeStepBlocks;
        uint64 collectStake;
        uint64 challengeStake;
        uint32 unlockBlocks;
        uint32 massExitIdBlocks;
        uint32 massExitIdStepBlocks;
        uint32 massExitBalanceBlocks;
        uint32 massExitBalanceStepBlocks;
        uint64 massExitStake;
        uint64 massExitChallengeStake;
        uint64 maxCollectAmount;
    }

    Config public params;
    address public owner;

    uint public constant MAX_ACCOUNT_ID = 2**32-1;     
    uint public constant NEW_ACCOUNT_FLAG = 2**256-1;  
    uint public constant INSTANT_SLOT = 32768;

}


 

contract Accounts is Data {
    event BulkRegister(uint bulkSize, uint smallestAccountId, uint bulkId );
    event AccountRegistered(uint accountId, address accountAddress);

    IERC20 public token;
    Account[] public accounts;
    BulkRegistration[] public bulkRegistrations;

     
    function isValidId(uint accountId) public view returns (bool) {
        return (accountId < accounts.length);
    }

     
    function isAccountOwner(uint accountId) public view returns (bool) {
        return isValidId(accountId) && msg.sender == accounts[accountId].owner;
    }

     
    modifier validId(uint accountId) {
        require(isValidId(accountId), "accountId is not valid");
        _;
    }

     
    modifier onlyAccountOwner(uint accountId) {
        require(isAccountOwner(accountId), "Only account owner can invoke this method");
        _;
    }

     
    function bulkRegister(uint256 bulkSize, bytes32 rootHash) public {
        require(bulkSize > 0, "Bulk size can't be zero");
        require(bulkSize < params.maxBulk, "Cannot register this number of ids simultaneously");
        require(SafeMath.add(accounts.length, bulkSize) <= MAX_ACCOUNT_ID, "Cannot register: ran out of ids");
        require(rootHash > 0, "Root hash can't be zero");

        emit BulkRegister(bulkSize, accounts.length, bulkRegistrations.length);
        bulkRegistrations.push(BulkRegistration(rootHash, uint32(bulkSize), uint32(accounts.length)));
        accounts.length = SafeMath.add(accounts.length, bulkSize);
    }

     
    function claimBulkRegistrationId(address addr, bytes32[] memory proof, uint accountId, uint bulkId) public {
        require(bulkId < bulkRegistrations.length, "the bulkId referenced is invalid");
        uint smallestAccountId = bulkRegistrations[bulkId].smallestRecordId;
        uint n = bulkRegistrations[bulkId].recordCount;
        bytes32 rootHash = bulkRegistrations[bulkId].rootHash;
        bytes32 hash = Merkle.getProofRootHash(proof, SafeMath.sub(accountId, smallestAccountId), bytes32(addr));

        require(accountId >= smallestAccountId && accountId < smallestAccountId + n,
            "the accountId specified is not part of that bulk registration slot");
        require(hash == rootHash, "invalid Merkle proof");
        emit AccountRegistered(accountId, addr);

        accounts[accountId].owner = addr;
    }

     
    function register() public returns (uint32 ret) {
        require(accounts.length < MAX_ACCOUNT_ID, "no more accounts left");
        ret = (uint32)(accounts.length);
        accounts.push(Account(msg.sender, 0, 0));
        emit AccountRegistered(ret, msg.sender);
        return ret;
    }

     
    function withdraw(uint64 amount, uint256 accountId)
        external
        onlyAccountOwner(accountId)
    {
        uint64 balance = accounts[accountId].balance;

        require(balance >= amount, "insufficient funds");
        require(amount > 0, "amount should be nonzero");

        balanceSub(accountId, amount);

        require(token.transfer(msg.sender, amount), "transfer failed");
    }

     
    function deposit(uint64 amount, uint256 accountId) external {
        require(accountId < accounts.length || accountId == NEW_ACCOUNT_FLAG, "invalid accountId");
        require(amount > 0, "amount should be positive");

        if (accountId == NEW_ACCOUNT_FLAG) {
             
            uint newId = register();
            accounts[newId].balance = amount;
        } else {
             
            balanceAdd(accountId, amount);
        }

        require(token.transferFrom(msg.sender, address(this), amount), "transfer failed");
    }

     
    function balanceAdd(uint accountId, uint64 amount)
    internal
    validId(accountId)
    {
        accounts[accountId].balance = SafeMath.add64(accounts[accountId].balance, amount);
    }

     
    function balanceSub(uint accountId, uint64 amount)
    internal
    validId(accountId)
    {
        uint64 balance = accounts[accountId].balance;
        require(balance >= amount, "not enough funds");
        accounts[accountId].balance = SafeMath.sub64(balance, amount);
    }

     
    function balanceOf(uint accountId)
        external
        view
        validId(accountId)
        returns (uint64)
    {
        return accounts[accountId].balance;
    }

     
    function getAccountsLength() external view returns (uint) {
        return accounts.length;
    }

     
    function getBulkLength() external view returns (uint) {
        return bulkRegistrations.length;
    }
}


 
library Challenge {

    uint8 public constant PAY_DATA_HEADER_MARKER = 0xff;  

     
    modifier onlyValidCollectSlot(Data.CollectSlot storage collectSlot, uint8 validStatus) {
        require(!challengeHasExpired(collectSlot), "Challenge has expired");
        require(isSlotStatusValid(collectSlot, validStatus), "Wrong Collect Slot status");
        _;
    }

     
    function challengeHasExpired(Data.CollectSlot storage collectSlot) public view returns (bool) {
        return collectSlot.block <= block.number;
    }

     
    function isSlotStatusValid(Data.CollectSlot storage collectSlot, uint8 validStatus) public view returns (bool) {
        return collectSlot.status == validStatus;
    }

     
    function getFutureBlock(uint delta) public view returns(uint64) {
        return SafeMath.add64(block.number, delta);
    }

     
    function getDataSum(bytes memory data) public pure returns (uint sum) {
        require(data.length > 0, "no data provided");
        require(data.length % 12 == 0, "wrong data format, data length should be multiple of 12");

        uint n = SafeMath.div(data.length, 12);
        uint maxSafeAmount = 2**64;
        uint maxSafePayIndex = 2**32;
        int previousPayIndex = -1;
        int currentPayIndex = 0;

         
         
        sum = 0;
        for (uint i = 0; i < n; i++) {
             
            assembly {
              sum := add(sum, mod(mload(add(data, add(8, mul(i, 12)))), maxSafeAmount))
              currentPayIndex := mod(mload(add(data, mul(add(i, 1), 12))), maxSafePayIndex)
            }
            require(sum < maxSafeAmount, "max cashout exceeded");
            require(previousPayIndex < currentPayIndex, "wrong data format, data should be ordered by payIndex");
            previousPayIndex = currentPayIndex;
        }
    }

     
    function getDataAtIndex(bytes memory data, uint index) public pure returns (uint64 amount, uint32 payIndex) {
        require(data.length > 0, "no data provided");
        require(data.length % 12 == 0, "wrong data format, data length should be multiple of 12");

        uint mod1 = 2**64;
        uint mod2 = 2**32;
        uint i = SafeMath.mul(index, 12);

        require(i <= SafeMath.sub(data.length, 12), "index * 12 must be less or equal than (data.length - 12)");

         
        assembly {
            amount := mod( mload(add(data, add(8, i))), mod1 )

            payIndex := mod( mload(add(data, add(12, i))), mod2 )
        }
    }

     
    function getBytesPerId(bytes payData) internal pure returns (uint) {
         
         

        uint len = payData.length;
        require(len >= 2, "payData length should be >= 2");
        require(uint8(payData[0]) == PAY_DATA_HEADER_MARKER, "payData header missing");
        uint bytesPerId = uint(payData[1]);
        require(bytesPerId > 0 && bytesPerId < 32, "second byte of payData should be positive and less than 32");

         
        require((len - 2) % bytesPerId == 0,
        "payData length is invalid, all payees must have same amount of bytes (payData[1])");

        return bytesPerId;
    }

     
    function getPayDataSum(bytes memory payData, uint id, uint amount) public pure returns (uint sum) {
        uint bytesPerId = getBytesPerId(payData);
        uint modulus = 1 << SafeMath.mul(bytesPerId, 8);
        uint currentId = 0;

        sum = 0;

        for (uint i = 2; i < payData.length; i += bytesPerId) {
             
             

             
            assembly {
                currentId := add(
                    currentId,
                    mod(
                        mload(add(payData, add(i, bytesPerId))),
                        modulus))

                switch eq(currentId, id)
                case 1 { sum := add(sum, amount) }
            }
        }
    }

     
    function getPayDataCount(bytes payData) public pure returns (uint) {
        uint bytesPerId = getBytesPerId(payData);

         
        return SafeMath.div(payData.length - 2, bytesPerId);
    }

     
    function challenge_1(
        Data.CollectSlot storage collectSlot,
        Data.Config storage config,
        Data.Account[] storage accounts,
        uint32 challenger
    )
        public
        onlyValidCollectSlot(collectSlot, 1)
    {
        require(accounts[challenger].balance >= config.challengeStake, "not enough balance");

        collectSlot.status = 2;
        collectSlot.challenger = challenger;
        collectSlot.block = getFutureBlock(config.challengeStepBlocks);

        accounts[challenger].balance -= config.challengeStake;
    }

     
    function challenge_2(
        Data.CollectSlot storage collectSlot,
        Data.Config storage config,
        bytes memory data
    )
        public
        onlyValidCollectSlot(collectSlot, 2)
    {
        require(getDataSum(data) == collectSlot.amount, "data doesn't represent collected amount");

        collectSlot.data = keccak256(data);
        collectSlot.status = 3;
        collectSlot.block = getFutureBlock(config.challengeStepBlocks);
    }

     
    function challenge_3(
        Data.CollectSlot storage collectSlot,
        Data.Config storage config,
        bytes memory data,
        uint32 disputedPaymentIndex
    )
        public
        onlyValidCollectSlot(collectSlot, 3)
    {
        require(collectSlot.data == keccak256(data),
        "data mismatch, collected data hash doesn't match provided data hash");
        (collectSlot.challengeAmount, collectSlot.index) = getDataAtIndex(data, disputedPaymentIndex);
        collectSlot.status = 4;
        collectSlot.block = getFutureBlock(config.challengeStepBlocks);
    }

     
    function challenge_4(
        Data.CollectSlot storage collectSlot,
        Data.Payment[] storage payments,
        bytes memory payData
    )
        public
        onlyValidCollectSlot(collectSlot, 4)
    {
        require(collectSlot.index >= collectSlot.minPayIndex && collectSlot.index < collectSlot.maxPayIndex,
            "payment referenced is out of range");
        Data.Payment memory p = payments[collectSlot.index];
        require(keccak256(payData) == p.paymentDataHash,
        "payData mismatch, payment's data hash doesn't match provided payData hash");
        require(p.lockingKeyHash == 0, "payment is locked");

        uint collected = getPayDataSum(payData, collectSlot.to, p.amount);

         
        if (collectSlot.to >= p.smallestAccountId && collectSlot.to < p.greatestAccountId) {
            collected = SafeMath.add(collected, p.amount);
        }

        require(collected == collectSlot.challengeAmount,
        "amount mismatch, provided payData sum doesn't match collected challenge amount");

        collectSlot.status = 5;
    }

     
    function challenge_success(
        Data.CollectSlot storage collectSlot,
        Data.Config storage config,
        Data.Account[] storage accounts
    )
        public
    {
        require((collectSlot.status == 2 || collectSlot.status == 4),
            "Wrong Collect Slot status");
        require(challengeHasExpired(collectSlot),
            "Challenge not yet finished");

        accounts[collectSlot.challenger].balance = SafeMath.add64(
            accounts[collectSlot.challenger].balance,
            SafeMath.add64(config.collectStake, config.challengeStake));

        collectSlot.status = 0;
    }

     
    function challenge_failed(
        Data.CollectSlot storage collectSlot,
        Data.Config storage config,
        Data.Account[] storage accounts
    )
        public
    {
        require(collectSlot.status == 5 || (collectSlot.status == 3 && block.number >= collectSlot.block),
            "challenge not completed");

         
         
        accounts[collectSlot.delegate].balance = SafeMath.add64(
            accounts[collectSlot.delegate].balance,
            config.challengeStake);

         
        collectSlot.challenger = 0;
        collectSlot.status = 1;
        collectSlot.block = getFutureBlock(config.challengeBlocks);
    }

     
    function recoverHelper(bytes32 hash, bytes sig) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));

        bytes32 r;
        bytes32 s;
        uint8 v;

         
        if (sig.length != 65) {
            return (address(0));
        }

         
         
         
         
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

         
        if (v < 27) {
            v += 27;
        }

         
        if (v != 27 && v != 28) {
            return address(0);
        }

        return ecrecover(prefixedHash, v, r, s);
    }
}


 
contract Payments is Accounts {
    event PaymentRegistered(
        uint32 indexed payIndex,
        uint indexed from,
        uint totalNumberOfPayees,
        uint amount
    );

    event PaymentUnlocked(uint32 indexed payIndex, bytes key);
    event PaymentRefunded(uint32 beneficiaryAccountId, uint64 amountRefunded);

     
    event Collect(
        uint indexed delegate,
        uint indexed slot,
        uint indexed to,
        uint32 fromPayindex,
        uint32 toPayIndex,
        uint amount
    );

    event Challenge1(uint indexed delegate, uint indexed slot, uint challenger);
    event Challenge2(uint indexed delegate, uint indexed slot);
    event Challenge3(uint indexed delegate, uint indexed slot, uint index);
    event Challenge4(uint indexed delegate, uint indexed slot);
    event ChallengeSuccess(uint indexed delegate, uint indexed slot);
    event ChallengeFailed(uint indexed delegate, uint indexed slot);

    Payment[] public payments;
    mapping (uint32 => mapping (uint32 => CollectSlot)) public collects;

     
    function registerPayment(
        uint32 fromId,
        uint64 amount,
        uint64 fee,
        bytes payData,
        uint newCount,
        bytes32 rootHash,
        bytes32 lockingKeyHash,
        bytes32 metadata
    )
        external
    {
        require(payments.length < 2**32, "Cannot add more payments");
        require(isAccountOwner(fromId), "Invalid fromId");
        require(amount > 0, "Invalid amount");
        require(newCount == 0 || rootHash > 0, "Invalid root hash");  
        require(fee == 0 || lockingKeyHash > 0, "Invalid lock hash");

        Payment memory p;

         
        p.totalNumberOfPayees = SafeMath.add32(Challenge.getPayDataCount(payData), newCount);
        require(p.totalNumberOfPayees > 0, "Invalid number of payees, should at least be 1 payee");
        require(p.totalNumberOfPayees < params.maxTransfer,
        "Too many payees, it should be less than config maxTransfer");

        p.fromAccountId = fromId;
        p.amount = amount;
        p.fee = fee;
        p.lockingKeyHash = lockingKeyHash;
        p.metadata = metadata;
        p.smallestAccountId = uint32(accounts.length);
        p.greatestAccountId = SafeMath.add32(p.smallestAccountId, newCount);
        p.lockTimeoutBlockNumber = SafeMath.add64(block.number, params.unlockBlocks);
        p.paymentDataHash = keccak256(abi.encodePacked(payData));

         
        uint64 totalCost = SafeMath.mul64(amount, p.totalNumberOfPayees);
        totalCost = SafeMath.add64(totalCost, fee);

         
        balanceSub(fromId, totalCost);

         
        if (newCount > 0) {
            bulkRegister(newCount, rootHash);
        }

         
        payments.push(p);

        emit PaymentRegistered(SafeMath.sub32(payments.length, 1), p.fromAccountId, p.totalNumberOfPayees, p.amount);
    }

     
    function unlock(uint32 payIndex, uint32 unlockerAccountId, bytes memory key) public returns(bool) {
        require(payIndex < payments.length, "invalid payIndex, payments is not that long yet");
        require(isValidId(unlockerAccountId), "Invalid unlockerAccountId");
        require(block.number < payments[payIndex].lockTimeoutBlockNumber, "Hash lock expired");
        bytes32 h = keccak256(abi.encodePacked(unlockerAccountId, key));
        require(h == payments[payIndex].lockingKeyHash, "Invalid key");

        payments[payIndex].lockingKeyHash = bytes32(0);
        balanceAdd(unlockerAccountId, payments[payIndex].fee);

        emit PaymentUnlocked(payIndex, key);
        return true;
    }

     
    function refundLockedPayment(uint32 payIndex) external returns (bool) {
        require(payIndex < payments.length, "invalid payIndex, payments is not that long yet");
        require(payments[payIndex].lockingKeyHash != 0, "payment is already unlocked");
        require(block.number >= payments[payIndex].lockTimeoutBlockNumber, "Hash lock has not expired yet");
        Payment memory payment = payments[payIndex];
        require(payment.totalNumberOfPayees > 0, "payment already refunded");

        uint64 total = SafeMath.add64(
            SafeMath.mul64(payment.totalNumberOfPayees, payment.amount),
            payment.fee
        );

        payment.totalNumberOfPayees = 0;
        payment.fee = 0;
        payment.amount = 0;
        payments[payIndex] = payment;

         
        balanceAdd(payment.fromAccountId, total);
        emit PaymentRefunded(payment.fromAccountId, total);

        return true;
    }

     
    function collect(
        uint32 delegate,
        uint32 slotId,
        uint32 toAccountId,
        uint32 maxPayIndex,
        uint64 declaredAmount,
        uint64 fee,
        address destination,
        bytes memory signature
    )
    public
    {
         
        require(isAccountOwner(delegate), "invalid delegate");
        require(isValidId(toAccountId), "toAccountId must be a valid account id");

         
        freeSlot(delegate, slotId);

        Account memory tacc = accounts[toAccountId];
        require(tacc.owner != 0, "account registration has to be completed");

        if (delegate != toAccountId) {
             
            bytes32 hash =
            keccak256(
            abi.encodePacked(
                address(this), delegate, toAccountId, tacc.lastCollectedPaymentId,
                maxPayIndex, declaredAmount, fee, destination
            ));
            require(Challenge.recoverHelper(hash, signature) == tacc.owner, "Bad user signature");
        }

         
        require(maxPayIndex > 0 && maxPayIndex <= payments.length,
        "invalid maxPayIndex, payments is not that long yet");
        require(maxPayIndex > tacc.lastCollectedPaymentId, "account already collected payments up to maxPayIndex");
        require(payments[maxPayIndex - 1].lockTimeoutBlockNumber < block.number,
            "cannot collect payments that can be unlocked");

         
        require(declaredAmount <= params.maxCollectAmount, "declaredAmount is too big");
        require(fee <= declaredAmount, "fee is too big, should be smaller than declaredAmount");

         
        CollectSlot storage sl = collects[delegate][slotId];
        sl.delegate = delegate;
        sl.minPayIndex = tacc.lastCollectedPaymentId;
        sl.maxPayIndex = maxPayIndex;
        sl.amount = declaredAmount;
        sl.to = toAccountId;
        sl.block = Challenge.getFutureBlock(params.challengeBlocks);
        sl.status = 1;

         
        uint64 needed = params.collectStake;

         
        if (slotId >= INSTANT_SLOT) {
            uint64 declaredAmountLessFee = SafeMath.sub64(declaredAmount, fee);
            sl.delegateAmount = declaredAmount;
            needed = SafeMath.add64(needed, declaredAmountLessFee);
            sl.addr = address(0);

             
            balanceAdd(toAccountId, declaredAmountLessFee);
        } else
        {    
            sl.delegateAmount = fee;
            sl.addr = destination;
        }

         
        require(accounts[delegate].balance >= needed, "not enough funds");

         
        accounts[toAccountId].lastCollectedPaymentId = uint32(maxPayIndex);

         
        balanceSub(delegate, needed);

         
        if (destination != address(0) && slotId >= INSTANT_SLOT) {
            uint64 toWithdraw = accounts[toAccountId].balance;
            accounts[toAccountId].balance = 0;
            require(token.transfer(destination, toWithdraw), "transfer failed");
        }

        emit Collect(delegate, slotId, toAccountId, tacc.lastCollectedPaymentId, maxPayIndex, declaredAmount);
    }

     
    function getPaymentsLength() external view returns (uint) {
        return payments.length;
    }

     
    function challenge_1(
        uint32 delegate,
        uint32 slot,
        uint32 challenger
    )
        public
        validId(delegate)
        onlyAccountOwner(challenger)
    {
        Challenge.challenge_1(collects[delegate][slot], params, accounts, challenger);
        emit Challenge1(delegate, slot, challenger);
    }

     
    function challenge_2(
        uint32 delegate,
        uint32 slot,
        bytes memory data
    )
        public
        onlyAccountOwner(delegate)
    {
        Challenge.challenge_2(collects[delegate][slot], params, data);
        emit Challenge2(delegate, slot);
    }

     
    function challenge_3(
        uint32 delegate,
        uint32 slot,
        bytes memory data,
        uint32 index
    )
        public
        validId(delegate)
    {
        require(isAccountOwner(collects[delegate][slot].challenger), "only challenger can call challenge_2");

        Challenge.challenge_3(collects[delegate][slot], params, data, index);
        emit Challenge3(delegate, slot, index);
    }

     
    function challenge_4(
        uint32 delegate,
        uint32 slot,
        bytes memory payData
    )
        public
        onlyAccountOwner(delegate)
    {
        Challenge.challenge_4(
            collects[delegate][slot],
            payments,
            payData
            );
        emit Challenge4(delegate, slot);
    }

     
    function challenge_success(
        uint32 delegate,
        uint32 slot
    )
        public
        validId(delegate)
    {
        Challenge.challenge_success(collects[delegate][slot], params, accounts);
        emit ChallengeSuccess(delegate, slot);
    }

     
    function challenge_failed(
        uint32 delegate,
        uint32 slot
    )
        public
        onlyAccountOwner(delegate)
    {
        Challenge.challenge_failed(collects[delegate][slot], params, accounts);
        emit ChallengeFailed(delegate, slot);
    }

     
    function freeSlot(uint32 delegate, uint32 slot) public {
        CollectSlot memory s = collects[delegate][slot];

         
        if (s.status == 0) return;

         
         
        require(s.status == 1, "slot not available");
        require(block.number >= s.block, "slot not available");

         
        collects[delegate][slot].status = 0;

         
         
         
        balanceAdd(delegate, SafeMath.add64(s.delegateAmount, params.collectStake));

         
         
        uint64 balance = SafeMath.sub64(s.amount, s.delegateAmount);

         
        if (s.addr != address(0))
        {
             
            balance = SafeMath.add64(balance, accounts[s.to].balance);
            accounts[s.to].balance = 0;
            if (balance != 0)
                require(token.transfer(s.addr, balance), "transfer failed");
        } else
        {
            balanceAdd(s.to, balance);
        }
    }
}


 
contract BatPay is Payments {

     
    constructor(
        IERC20 token_,
        uint32 maxBulk,
        uint32 maxTransfer,
        uint32 challengeBlocks,
        uint32 challengeStepBlocks,
        uint64 collectStake,
        uint64 challengeStake,
        uint32 unlockBlocks,
        uint64 maxCollectAmount
    )
        public
    {
        require(token_ != address(0), "Token address can't be zero");
        require(maxBulk > 0, "Parameter maxBulk can't be zero");
        require(maxTransfer > 0, "Parameter maxTransfer can't be zero");
        require(challengeBlocks > 0, "Parameter challengeBlocks can't be zero");
        require(challengeStepBlocks > 0, "Parameter challengeStepBlocks can't be zero");
        require(collectStake > 0, "Parameter collectStake can't be zero");
        require(challengeStake > 0, "Parameter challengeStake can't be zero");
        require(unlockBlocks > 0, "Parameter unlockBlocks can't be zero");
        require(maxCollectAmount > 0, "Parameter maxCollectAmount can't be zero");

        owner = msg.sender;
        token = IERC20(token_);
        params.maxBulk = maxBulk;
        params.maxTransfer = maxTransfer;
        params.challengeBlocks = challengeBlocks;
        params.challengeStepBlocks = challengeStepBlocks;
        params.collectStake = collectStake;
        params.challengeStake = challengeStake;
        params.unlockBlocks = unlockBlocks;
        params.maxCollectAmount = maxCollectAmount;
    }
}