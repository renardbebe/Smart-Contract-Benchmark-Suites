 

pragma solidity >= 0.5.12;

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
interface ChainValidator {
     
    function validateNewValidator(uint256 vesting, address acc, bool mining, uint256 actNumOfValidators) external returns (bool);
    
     
    function validateNewTransactor(uint256 deposit, address acc, uint256 actNumOfTransactors) external returns (bool);
}

 
contract LitionRegistry {
    using SafeMath for uint256;
    
     
     
     
    
     
    uint256 constant LIT_PRECISION               = 10**18;
    
     
    uint256 constant LARGEST_TX_FEE              = LIT_PRECISION/10;
    
     
    uint256 constant MIN_NOTARY_PERIOD           = 1440;     
    
     
    uint256 constant MAX_NOTARY_PERIOD           = 34560;
    
     
     
    uint256 constant CHAIN_INACTIVITY_TIMEOUT    = 7 days;   
    
     
    uint256 constant VESTING_LOCKUP_TIMEOUT      = 7 days;   
    
     
    uint256 constant MAX_URL_LENGTH              = 100;
    
     
    uint256 constant MAX_DESCRIPTION_LENGTH      = 200;
    
     
    uint256 constant LITION_MIN_REQUIRED_DEPOSIT = 1000*LIT_PRECISION;
    
     
    uint256 constant LITION_MIN_REQUIRED_VESTING = 1000*LIT_PRECISION;
    
    
     
     
     
    
     
    event NewChain(uint256 chainId, string description, string endpoint);
    
     
     
     
     
    event DepositInChain(uint256 indexed chainId, address indexed account, uint256 deposit, uint256 lastNotaryBlock, bool confirmed);
    
     
     
     
     
    event VestInChain(uint256 indexed chainId, address indexed account, uint256 vesting, uint256 lastNotaryBlock, bool confirmed);
    
     
     
    event AccountWhitelisted(uint256 indexed chainId, address indexed account, bool whitelisted);
    
     
    event AccountMining(uint256 indexed chainId, address indexed account, bool mining);

     
    event MiningReward(uint256 indexed chainId, address indexed account, uint256 reward);
    
     
    event Notary(uint256 indexed chainId, uint256 lastBlock, uint256 blocksProcessed);
    
     
    event NotaryReset(uint256 indexed chainId, uint256 lastValidBlock, uint256 resetBlock);
    

     
     
     
    
     
    struct IterableMap {
         
         
        mapping(address => uint256) listIndex;
         
        address[]                   list;        
    }
    
    struct VestingRequest {
         
        bool                    exist;
         
        uint256                 notaryBlock;
         
        uint256                 newVesting;
    }
    
    struct Validator {
         
        bool                    currentNotaryMined;
         
        bool                    prevNotaryMined;
         
        VestingRequest          vestingRequest;
         
        uint256                  vesting;
         
        uint256                 lastVestingIncreaseTime;
    }
    
     
    struct DepositWithdrawalRequest {
         
        uint256                  notaryBlock;
         
        bool                     exist;
    }
    
    struct Transactor {
         
        uint256                  deposit;
         
        DepositWithdrawalRequest depositWithdrawalRequest;
         
        bool                     whitelisted;
    }
    
    struct User {
         
        Transactor   transactor;
        
         
        Validator    validator;
    }

    
     
     
     
    
    ERC20 token;
    
    struct LastNotary {
         
        uint256 timestamp;
         
        uint256 block;
    }
    
    struct ChainInfo {
         
        uint256                         id;
        
         
         
        uint256                         minRequiredDeposit;
        
         
         
        uint256                         minRequiredVesting;
        
         
        uint256                         actNumOfTransactors;
        
         
         
         
         
         
        uint256                         maxNumOfValidators;
        
         
         
         
         
         
        uint256                         maxNumOfTransactors;
        
         
         
        uint256                         rewardBonusRequiredVesting;
        
         
        uint256                         rewardBonusPercentage;
        
         
        uint256                         totalVesting;
        
         
        uint256                         notaryPeriod;
        
         
        LastNotary                      lastNotary;
        
         
         
         
        bool                            involvedVestingNotaryCond;
        
         
         
         
        bool                            participationNotaryCond;
        
         
        bool                            registered;
        
         
        bool                            active;
        
         
        address                         creator;
        
         
         
        address                         lastValidator;
        
         
        ChainValidator                  chainValidator;
        
         
        string                          description;
        
         
        string                          endpoint;
        
         
        IterableMap                     users;
        
         
         
        IterableMap                     validators;
        
         
        mapping(address => User)        usersData;
    }
    
     
    mapping(uint256 => ChainInfo)   private chains;
    
     
    uint256                         public  nextId = 0;

    
     
     
     
    
     
    function requestVestInChain(uint256 chainId, uint256 vesting) external {
        ChainInfo storage chain = chains[chainId];
        Validator storage validator = chain.usersData[msg.sender].validator;
        
         
        require(chain.registered == true,                                 "Non-registered chain");
        require(transactorExist(chain, msg.sender) == false,              "Validator cannot be transactor at the same time. Withdraw your depoist or use different account");
        require(vestingRequestExist(chain, msg.sender) == false,          "There is already one vesting request being processed for this acc");
        
         
        checkAndSetChainActivity(chain);
        
         
        if (vesting == 0) {
            require(validatorExist(chain, msg.sender) == true,            "Non-existing validator account (0 vesting balance)");
            require(activeValidatorExist(chain, msg.sender) == false,     "StopMinig must be called first");
            
             
            if (chain.active == true) {
                require(validator.lastVestingIncreaseTime + VESTING_LOCKUP_TIMEOUT < now,  "Unable to decrease vesting balance, validators need to wait VESTING_LOCKUP_TIMEOUT(7 days) since the last increase");
            }
        }
         
        else {
            require(validator.vesting != vesting,                         "Cannot vest the same amount of tokens as you already has vested");
            require(vesting >= chain.minRequiredVesting,                  "User does not meet min.required vesting condition");
            
            if (chain.chainValidator != ChainValidator(0)) {
                require(chain.chainValidator.validateNewValidator(vesting, msg.sender, false  , chain.validators.list.length), "Validator not allowed by external chainvalidator SC");
            }
            
             
            if (vesting < validator.vesting) {
                if (chain.active == true) {
                    require(validator.lastVestingIncreaseTime + VESTING_LOCKUP_TIMEOUT < now,  "Unable to decrease vesting balance, validators need to wait VESTING_LOCKUP_TIMEOUT(7 days) since the last increase");
                }
            }
             
            else if (chain.maxNumOfValidators != 0 && chain.validators.list.length >= chain.maxNumOfValidators) {
           
                require(vesting > chain.usersData[chain.lastValidator].validator.vesting, "Upper limit of validators reached. Must vest more than the last validator to be able to start mining and replace him");
            }
        }
        
        requestVest(chain, vesting, msg.sender);
    }
    
     
    function confirmVestInChain(uint256 chainId) external {
        ChainInfo storage chain = chains[chainId];
        
         
        require(chain.registered == true, "Non-registered chain");
        require(vestingRequestExist(chain, msg.sender) == true, "Non-existing vesting request");
        
         
        checkAndSetChainActivity(chain);
        
         
        if (chain.active == true) {
            require(chain.lastNotary.block > chain.usersData[msg.sender].validator.vestingRequest.notaryBlock, "Confirm can be called in the next notary window after request was accepted");    
        }
        
        confirmVest(chain, msg.sender);
    }
    
     
    function requestDepositInChain(uint256 chainId, uint256 deposit) external {
        ChainInfo storage chain = chains[chainId];
        
        require(chain.registered == true,                                             "Non-registered chain");
        require(validatorExist(chain, msg.sender) == false,                           "Transactor cannot be validator at the same time. Withdraw your vesting or use different account");
        require(depositWithdrawalRequestExist(chain, msg.sender) == false,            "There is already existing withdrawal request being processed for this acc");
        
         
        checkAndSetChainActivity(chain);
        
         
        if (deposit == 0) {
            require(transactorExist(chain, msg.sender) == true,                       "Non-existing transactor account (0 deposit balance)");
        }
         
        else {
            require(chain.usersData[msg.sender].transactor.deposit != deposit,        "Cannot deposit the same amount of tokens as you already has deposited");
            require(deposit >= chain.minRequiredDeposit,                              "User does not meet min.required deposit condition");
            
            if (chain.chainValidator != ChainValidator(0)) {
                require(chain.chainValidator.validateNewTransactor(deposit, msg.sender, chain.actNumOfTransactors), "Transactor not allowed by external chainvalidator SC");
            }
            
             
            if (chain.maxNumOfTransactors != 0 && chain.usersData[msg.sender].transactor.whitelisted == false) {
                require(chain.actNumOfTransactors <= chain.maxNumOfTransactors, "Upper limit of transactors reached");
            }
        }
                
        requestDeposit(chain, deposit, msg.sender);
    }
    
     
    function confirmDepositWithdrawalFromChain(uint256 chainId) external {
        ChainInfo storage chain = chains[chainId];

        require(chain.registered == true, "Non-registered chain");
        require(depositWithdrawalRequestExist(chain, msg.sender) == true, "Non-existing deposit withdrawal request");
        
         
        checkAndSetChainActivity(chain);
        
         
        if (chain.active == true) {
            require(chain.lastNotary.block > chain.usersData[msg.sender].transactor.depositWithdrawalRequest.notaryBlock, "Confirm can be called in the next notary window after request was accepted");
        }
        
        confirmDepositWithdrawal(chain, msg.sender);
    }
    
      
    function registerChain(string memory description, string memory initEndpoint, ChainValidator chainValidator, uint256 minRequiredDeposit, uint256 minRequiredVesting, uint256 rewardBonusRequiredVesting, uint256 rewardBonusPercentage, 
                           uint256 notaryPeriod, uint256 maxNumOfValidators, uint256 maxNumOfTransactors, bool involvedVestingNotaryCond, bool participationNotaryCond) public returns (uint256 chainId) {
        require(bytes(description).length > 0 && bytes(description).length <= MAX_DESCRIPTION_LENGTH,   "Chain description length must be: > 0 && <= MAX_DESCRIPTION_LENGTH(200)");
        require(bytes(initEndpoint).length > 0 && bytes(initEndpoint).length <= MAX_URL_LENGTH,         "Chain endpoint length must be: > 0 && <= MAX_URL_LENGTH(100)");
        require(notaryPeriod >= MIN_NOTARY_PERIOD && notaryPeriod <= MAX_NOTARY_PERIOD,                 "Notary period must be in range <MIN_NOTARY_PERIOD(1440), MAX_NOTARY_PERIOD(34560)>");
        require(involvedVestingNotaryCond == true || participationNotaryCond == true,                   "At least one notary condition must be specified");
        
        if (minRequiredDeposit > 0) {
            require(minRequiredDeposit >= LITION_MIN_REQUIRED_DEPOSIT,                                  "Min. required deposit for all chains must be >= LITION_MIN_REQUIRED_DEPOSIT (1000 LIT)");
        }
        
        if (minRequiredVesting > 0) {
            require(minRequiredVesting >= LITION_MIN_REQUIRED_VESTING,                                  "Min. required vesting for all chains must be >= LITION_MIN_REQUIRED_VESTING (1000 LIT)");
        }
        
        if (rewardBonusRequiredVesting > 0) {
            require(rewardBonusPercentage > 0,                                                          "Reward bonus percentage must be > 0%");    
        }
    
        chainId                         = nextId;
        ChainInfo storage chain         = chains[chainId];
        
        chain.id                        = chainId;
        chain.description               = description;
        chain.endpoint                  = initEndpoint;
        chain.minRequiredDeposit        = minRequiredDeposit;
        chain.minRequiredVesting        = minRequiredVesting;
        chain.notaryPeriod              = notaryPeriod;
        chain.registered                = true;
        chain.creator                   = msg.sender;
        
        if (chainValidator != ChainValidator(0)) {
            chain.chainValidator = chainValidator;
        }
        
         
        if (minRequiredDeposit == 0) {
            chain.minRequiredDeposit = LITION_MIN_REQUIRED_DEPOSIT;
        } 
        else {
            chain.minRequiredDeposit = minRequiredDeposit;
        }
        
         
        if (minRequiredVesting == 0) {
            chain.minRequiredVesting = LITION_MIN_REQUIRED_VESTING;
        } 
        else {
            chain.minRequiredVesting = minRequiredVesting;
        }

        
        if (involvedVestingNotaryCond == true) {
            chain.involvedVestingNotaryCond  = true;    
        }
        
        if (participationNotaryCond == true) {
            chain.participationNotaryCond    = true;
        }
        
        if (maxNumOfValidators > 0) {
            chain.maxNumOfValidators         = maxNumOfValidators;
        }
        
        if (maxNumOfTransactors > 0) {
            chain.maxNumOfTransactors        = maxNumOfTransactors;
        }
        
        if (rewardBonusRequiredVesting > 0) {
            chain.rewardBonusRequiredVesting = rewardBonusRequiredVesting;
            chain.rewardBonusPercentage      = rewardBonusPercentage;
        }
        
        emit NewChain(chainId, description, initEndpoint);
        
        nextId++;
    }
    
     
    function setChainStaticDetails(uint256 chainId, string calldata description, string calldata endpoint) external {
        ChainInfo storage chain = chains[chainId];
        require(msg.sender == chain.creator, "Only chain creator can call this method");
    
        require(bytes(description).length <= MAX_DESCRIPTION_LENGTH,   "Chain description length must be: > 0 && <= MAX_DESCRIPTION_LENGTH(200)");
        require(bytes(endpoint).length <= MAX_URL_LENGTH,              "Chain endpoint length must be: > 0 && <= MAX_URL_LENGTH(100)");
        
        if (bytes(description).length > 0) {
            chain.description = description;
        }
        if (bytes(endpoint).length > 0) {
            chain.endpoint = endpoint;
        }
    }
    
     
    function getChainStaticDetails(uint256 chainId) external view returns (string memory description, string memory endpoint, bool registered, uint256 minRequiredDeposit, uint256 minRequiredVesting, 
                                                                           uint256 rewardBonusRequiredVesting, uint256 rewardBonusPercentage, uint256 notaryPeriod, uint256 maxNumOfValidators, 
                                                                           uint256 maxNumOfTransactors, bool involvedVestingNotaryCond, bool participationNotaryCond) {
        ChainInfo storage chain = chains[chainId];
        
        description                 = chain.description;
        endpoint                    = chain.endpoint;
        registered                  = chain.registered;
        minRequiredDeposit          = chain.minRequiredDeposit;
        minRequiredVesting          = chain.minRequiredVesting;
        rewardBonusRequiredVesting  = chain.rewardBonusRequiredVesting;
        rewardBonusPercentage       = chain.rewardBonusPercentage;
        notaryPeriod                = chain.notaryPeriod;
        maxNumOfValidators          = chain.maxNumOfValidators;
        maxNumOfTransactors         = chain.maxNumOfTransactors;
        involvedVestingNotaryCond   = chain.involvedVestingNotaryCond;
        participationNotaryCond     = chain.participationNotaryCond;
    }
    
     
    function getChainDynamicDetails(uint256 chainId) public view returns (bool active, uint256 totalVesting, uint256 validatorsCount, uint256 transactorsCount,
                                                                          uint256 lastValidatorVesting, uint256 lastNotaryBlock, uint256 lastNotaryTimestamp) {
        ChainInfo storage chain = chains[chainId];
        
        active               = chain.active;
        totalVesting         = chain.totalVesting;
        validatorsCount      = chain.validators.list.length;
        transactorsCount     = chain.actNumOfTransactors;
        lastValidatorVesting = chain.usersData[chain.lastValidator].validator.vesting;   
        lastNotaryBlock      = chain.lastNotary.block;
        lastNotaryTimestamp  = chain.lastNotary.timestamp;
    }
    
     
    function getUserDetails(uint256 chainId, address acc) external view returns (uint256 deposit, bool whitelisted, 
                                                                                 uint256 vesting, uint256 lastVestingIncreaseTime, bool mining, bool prevNotaryMined,
                                                                                 bool vestingReqExist, uint256 vestingReqNotary, uint256 vestingReqValue,
                                                                                 bool depositFullWithdrawalReqExist, uint256 depositReqNotary) {
        ChainInfo storage chain = chains[chainId];
        User storage user       = chain.usersData[acc];
         
        deposit                 = user.transactor.deposit;
        whitelisted             = user.transactor.whitelisted;
        vesting                 = user.validator.vesting;
        lastVestingIncreaseTime = user.validator.lastVestingIncreaseTime;
        mining                  = activeValidatorExist(chain, acc);
        prevNotaryMined         = user.validator.currentNotaryMined;  
        
        if (vestingRequestExist(chain, acc)) {
            vestingReqExist            = true;
            vestingReqNotary           = user.validator.vestingRequest.notaryBlock;
            vestingReqValue            = user.validator.vestingRequest.newVesting;
        }
        
        if (depositWithdrawalRequestExist(chain, acc)) {
            depositFullWithdrawalReqExist  = true;
            depositReqNotary               = user.transactor.depositWithdrawalRequest.notaryBlock;
        }
    }
    
     
    function notary(uint256 chainId, uint256 notaryStartBlock, uint256 notaryEndBlock, address[] memory validators, uint32[] memory blocksMined,
                    address[] memory users, uint64[] memory userGas, uint64 largestTx,
                    uint8[] memory v, bytes32[] memory r, bytes32[] memory s) public {
                  
        ChainInfo storage chain = chains[chainId];
        require(chain.registered    == true,                            "Invalid chain data: Non-registered chain");
        require(validatorExist(chain, msg.sender) == true,              "Sender must have vesting balance > 0");
        require(chain.totalVesting  > 0,                                "Current chain total_vesting == 0, there are no active validators");
        
        require(validators.length       > 0,                            "Invalid statistics data: validators.length == 0");
        require(validators.length       == blocksMined.length,          "Invalid statistics data: validators.length != num of block mined");
        if (chain.maxNumOfValidators != 0) {
            require(validators.length   <= chain.maxNumOfValidators,    "Invalid statistics data: validators.length > maxNumOfValidators");
            require(v.length            <= chain.maxNumOfValidators,    "Invalid statistics data: signatures.length > maxNumOfValidators");
        }
        
        if (chain.maxNumOfTransactors != 0) {
            require(users.length    <= chain.maxNumOfTransactors,   "Invalid statistics data: users.length > maxNumOfTransactors");
        }
        require(users.length        > 0,                            "Invalid statistics data: users.length == 0");
        require(users.length        == userGas.length,              "Invalid statistics data: users.length != usersGas.length");
        
        require(v.length            == r.length,                    "Invalid statistics data: v.length != r.length");
        require(v.length            == s.length,                    "Invalid statistics data: v.length != s.length");
        require(notaryStartBlock    >  chain.lastNotary.block,      "Invalid statistics data: notaryBlock_start <= last known notary block");
        require(notaryEndBlock      >  notaryStartBlock,            "Invalid statistics data: notaryEndBlock <= notaryStartBlock");
        require(largestTx           >  0,                           "Invalid statistics data: Largest tx <= 0");
        
        bytes32 signatureHash = keccak256(abi.encodePacked(notaryEndBlock, validators, blocksMined, users, userGas, largestTx));
        
         
        validateNotaryConditions(chain, signatureHash, v, r, s);
        
         
        uint256 totalCost = processUsersConsumptions(chain, users, userGas, largestTx);
        
         
         
        require(totalCost > 0, "Invalid statistics data: users totalUsageCost == 0");
        
         
        uint256 maxBlocksMined = (notaryEndBlock - notaryStartBlock) + 1;
        
         
        uint256 totalInvolvedVesting = processNotaryValidators(chain, validators, blocksMined, maxBlocksMined);
        
         
         
        require(totalInvolvedVesting > 0, "totalInvolvedVesting == 0. Invalid statistics or 0 active validators left in the chain");
        
         
        processValidatorsRewards(chain, totalInvolvedVesting, validators, blocksMined, maxBlocksMined, totalCost);
        
         
        chain.lastNotary.block = notaryEndBlock;
        chain.lastNotary.timestamp = now;
        
        if (chain.active == false) {
            chain.active = true;
        }
        
        emit Notary(chainId, notaryEndBlock, maxBlocksMined);
    }
    
     
    function resetNotary(uint256 chainId, uint256 resetBlock, bool processRequests, bool unvoteValidators) external {
        ChainInfo storage chain = chains[chainId];
        require(msg.sender == chain.creator, "Only chain creator can call this method");
        
         
        uint256 lastValidBlock = chain.lastNotary.block;
        chain.lastNotary.block = resetBlock;
        
        if (processRequests == true) {
          bool end = false;
          for (uint256 batch = 0; end == false; batch++) {
              end = resetRequests(chainId, resetBlock, batch);
          }
        }
        
        if (unvoteValidators == true) {
            removeValidators(chainId, chain.validators.list);
        }
    
        emit NotaryReset(chainId, lastValidBlock, resetBlock);               
    }
    
     
    function removeValidators(uint256 chainId, address[] memory validators) public {
        ChainInfo storage chain = chains[chainId];
        require(msg.sender == chain.creator, "Only chain creator can call this method");
        
        for (uint256 i = 0; i < validators.length; i++) {
            if (activeValidatorExist(chain, validators[i]) == true) {
                activeValidatorRemove(chain, validators[i]);
            }
        }
    }
    
     
    function resetRequests(uint256 chainId, uint256 resetBlock, uint256 batch) public returns (bool end) {
        ChainInfo storage chain = chains[chainId];
        require(msg.sender == chain.creator, "Only chain creator can call this method");
        
        uint256 usersTotalCount = chain.users.list.length;
        uint256 i;
        for(i = batch * 100; i < (batch + 1)*100 && i < usersTotalCount; i++) {
            User storage user = chain.usersData[chain.users.list[i]];
            
            if (user.transactor.depositWithdrawalRequest.exist == true) {
              user.transactor.depositWithdrawalRequest.notaryBlock = resetBlock;
            }
            
            if (user.validator.vestingRequest.exist == true) {
              user.validator.vestingRequest.notaryBlock = resetBlock;
            }
        }
        
        if (i >= usersTotalCount) {
            end = true;
        }
        else {
            end = false;
        }
    }
    
     
    function getTransactors(uint256 chainId, uint256 batch) external view returns (address[100] memory transactors, uint256 count, bool end) {
        return getUsers(chains[chainId], true, batch);
    }
    
     
    function getAllowedToValidate(uint256 chainId, uint256 batch) view external returns (address[100] memory validators, uint256 count, bool end) {
        return getUsers(chains[chainId], false, batch);
    }
    
     
    function getValidators(uint256 chainId, uint256 batch) view external returns (address[100] memory validators, uint256 count, bool end) {
        ChainInfo storage chain = chains[chainId];
        
        count = 0;
        uint256 validatorsTotalCount = chain.validators.list.length;
        
        address acc;
        uint256 i;
        for(i = batch * 100; i < (batch + 1)*100 && i < validatorsTotalCount; i++) {
            acc = chain.validators.list[i];
            
            validators[count] = acc;
            count++;
        }
        
        if (i >= validatorsTotalCount) {
            end = true;
        }
        else {
            end = false;
        }
    }
    
     
    function startMining(uint256 chainId) external {
        ChainInfo storage chain = chains[chainId];
        address acc = msg.sender;
        uint256 validatorVesting = chain.usersData[acc].validator.vesting;
        
        require(chain.registered == true,                         "Non-registered chain");
        require(validatorExist(chain, acc) == true,               "Non-existing validator (0 vesting balance)");
        require(vestingRequestExist(chain, acc) == false,         "Cannot start mining - there is ongoing vesting request");
        
        if (chain.chainValidator != ChainValidator(0)) {
            require(chain.chainValidator.validateNewValidator(validatorVesting, acc, true  , chain.validators.list.length) == true, "Validator not allowed by external chainvalidator SC");
        }
        
        if (activeValidatorExist(chain, acc) == true) {
             
             
            emit AccountMining(chainId, acc, true);
            
            return;
        }
            
         
        if (chain.maxNumOfValidators != 0 && chain.validators.list.length >= chain.maxNumOfValidators) {
            require(validatorVesting > chain.usersData[chain.lastValidator].validator.vesting, "Upper limit of validators reached. Must vest more than the last validator to replace him");
            activeValidatorReplace(chain, acc);
        }
         
        else {
            activeValidatorInsert(chain, acc);
        }
    }
  
     
    function stopMining(uint256 chainId) external {
        ChainInfo storage chain = chains[chainId];
        address acc = msg.sender;
        
        require(chain.registered == true, "Non-registered chain");
        require(validatorExist(chain, acc) == true, "Non-existing validator (0 vesting balance)");
    
        if (activeValidatorExist(chain, acc) == false) {
             
             
            emit AccountMining(chainId, acc, false);
            
            return;
        }
        
        activeValidatorRemove(chain, acc);
    }
    

     
     
     
    
     
    function insertAcc(IterableMap storage map, address acc) internal {
        map.list.push(acc);
         
        map.listIndex[acc] = map.list.length;
    }
    
     
    function removeAcc(IterableMap storage map, address acc) internal {
        uint256 index = map.listIndex[acc];
        require(index > 0 && index <= map.list.length, "RemoveAcc invalid index");
        
         
        uint256 foundIndex = index - 1;
        uint256 lastIndex  = map.list.length - 1;
    
        map.listIndex[map.list[lastIndex]] = foundIndex + 1;
        map.list[foundIndex] = map.list[lastIndex];
        map.list.length--;
    
         
        map.listIndex[acc] = 0;
    }
    
     
    function existAcc(IterableMap storage map, address acc) internal view returns (bool) {
        return map.listIndex[acc] != 0;
    }
    
     
    function validatorCreate(ChainInfo storage chain, address acc, uint256 vesting) internal {
        Validator storage validator     = chain.usersData[acc].validator;
        
        validator.vesting                   = vesting;
        validator.lastVestingIncreaseTime   = now;
         
        validator.currentNotaryMined        = true;
        validator.prevNotaryMined           = true;
        
        
         
        insertAcc(chain.users, acc);
    }
    
     
    function validatorDelete(ChainInfo storage chain, address acc) internal {
        Validator storage validator = chain.usersData[acc].validator;
        
        if (activeValidatorExist(chain, acc) == true) {
            activeValidatorRemove(chain, acc);
        }
        
        validator.vesting                   = 0;
        validator.lastVestingIncreaseTime   = 0;
        validator.currentNotaryMined        = false;
        validator.prevNotaryMined           = false;
        
         
        removeAcc(chain.users, acc);
    }
    
     
    function activeValidatorInsert(ChainInfo storage chain, address acc) internal {
        Validator storage validator = chain.usersData[acc].validator;
        
         
        if (chain.validators.list.length == 0 || validator.vesting <= chain.usersData[chain.lastValidator].validator.vesting) {
            chain.lastValidator = acc;
        }
        
        insertAcc(chain.validators, acc);   
        
         
        chain.totalVesting = chain.totalVesting.add(validator.vesting);
        
        emit AccountMining(chain.id, acc, true);
    }
    
     
    function activeValidatorRemove(ChainInfo storage chain, address acc) internal {
        Validator storage validator = chain.usersData[acc].validator;
        
        removeAcc(chain.validators, acc);   
        
         
        chain.totalVesting = chain.totalVesting.sub(validator.vesting);
        
         
         
        if (chain.validators.list.length == 0) {
            chain.active = false;
            chain.lastValidator = address(0x0);
        }
         
        else {
             
            if (chain.lastValidator == acc) {
                resetLastActiveValidator(chain);
            }
        }
        
        emit AccountMining(chain.id, acc, false);
    }
    
     
    function activeValidatorReplace(ChainInfo storage chain, address acc) internal {
        address accToBeReplaced                 = chain.lastValidator;
        Validator memory validatorToBeReplaced  = chain.usersData[accToBeReplaced].validator;
        Validator memory newValidator           = chain.usersData[acc].validator;
        
         
        chain.totalVesting = chain.totalVesting.sub(validatorToBeReplaced.vesting);
        chain.totalVesting = chain.totalVesting.add(newValidator.vesting);
        
         
        removeAcc(chain.validators, accToBeReplaced);
        insertAcc(chain.validators, acc);
        
         
        resetLastActiveValidator(chain);
        
        emit AccountMining(chain.id, accToBeReplaced, false);
        emit AccountMining(chain.id, acc, true);
    }
    
     
    function resetLastActiveValidator(ChainInfo storage chain) internal {
        address foundLastValidatorAcc     = chain.validators.list[0];
        uint256 foundLastValidatorVesting = chain.usersData[foundLastValidatorAcc].validator.vesting;
        
        address actValidatorAcc;
        uint256 actValidatorVesting;
        for (uint256 i = 1; i < chain.validators.list.length; i++) {
            actValidatorAcc     = chain.validators.list[i];
            actValidatorVesting = chain.usersData[actValidatorAcc].validator.vesting;
            
            if (actValidatorVesting <= foundLastValidatorVesting) {
                foundLastValidatorAcc     = actValidatorAcc;
                foundLastValidatorVesting = actValidatorVesting;
            }
        }
        
        chain.lastValidator = foundLastValidatorAcc;
    }
    
     
    function activeValidatorExist(ChainInfo storage chain, address acc) internal view returns (bool) {
        return existAcc(chain.validators, acc);
    }
    
     
    function validatorExist(ChainInfo storage chain, address acc) internal view returns (bool) {
        return chain.usersData[acc].validator.vesting > 0;
    }
    
     
    function transactorCreate(ChainInfo storage chain, address acc, uint256 deposit) internal {
        Transactor storage transactor = chain.usersData[acc].transactor;
        
        transactor.deposit = deposit;
        transactorWhitelist(chain, acc);
        
         
        insertAcc(chain.users, acc);
    }
    
     
    function transactorDelete(ChainInfo storage chain, address acc) internal {
        Transactor storage transactor = chain.usersData[acc].transactor;
        
        transactor.deposit = 0;
        transactorBlacklist(chain, acc);
        
         
        removeAcc(chain.users, acc);
    }
    
     
    function transactorExist(ChainInfo storage chain, address acc) internal view returns (bool) {
        return chain.usersData[acc].transactor.deposit > 0;
    }
    
     
    function transactorBlacklist(ChainInfo storage chain, address acc) internal {
        Transactor storage transactor   = chain.usersData[acc].transactor;
        
        if (transactor.whitelisted == true) {
            chain.actNumOfTransactors--;
            
            transactor.whitelisted = false;
            emit AccountWhitelisted(chain.id, acc, false);
        }
    }
    
     
    function transactorWhitelist(ChainInfo storage chain, address acc) internal {
        Transactor storage transactor   = chain.usersData[acc].transactor;
        
        if (transactor.whitelisted == false) {
            chain.actNumOfTransactors++;
            
            transactor.whitelisted = true;
            emit AccountWhitelisted(chain.id, acc, true);
        }
    }
    
     
    function getUsers(ChainInfo storage chain, bool transactorsFlag, uint256 batch) internal view returns (address[100] memory users, uint256 count, bool end) {
        count = 0;
        uint256 usersTotalCount = chain.users.list.length;
        
        address acc;
        uint256 i;
        for(i = batch * 100; i < (batch + 1)*100 && i < usersTotalCount; i++) {
            acc = chain.users.list[i];
            
             
            if (transactorsFlag == true) {
                if (chain.usersData[acc].transactor.whitelisted == false) {
                    continue;
                } 
            }
             
            else {
                if (chain.usersData[acc].validator.vesting == 0) {
                    continue;
                }
            }
            
            users[count] = acc;
            count++;
        }
        
        if (i >= usersTotalCount) {
            end = true;
        }
        else {
            end = false;
        }
    }
    
     
     
     
    
     
    function vestingRequestCreate(ChainInfo storage chain, address acc, uint256 vesting) internal {
        VestingRequest storage request = chain.usersData[acc].validator.vestingRequest;
        
        request.exist       = true;
        request.newVesting  = vesting;
        request.notaryBlock = chain.lastNotary.block; 
    }

     
    function depositWithdrawalRequestCreate(ChainInfo storage chain, address acc) internal {
        DepositWithdrawalRequest storage request = chain.usersData[acc].transactor.depositWithdrawalRequest;
        
        request.exist       = true;
        request.notaryBlock = chain.lastNotary.block; 
    }
    
    function vestingRequestDelete(ChainInfo storage chain, address acc) internal {
         
        VestingRequest storage request = chain.usersData[acc].validator.vestingRequest;
        request.exist          = false;
        request.notaryBlock    = 0;
        request.newVesting     = 0;
    }
    
    function depositWithdrawalRequestDelete(ChainInfo storage chain, address acc) internal {
         
        DepositWithdrawalRequest storage request = chain.usersData[acc].transactor.depositWithdrawalRequest;
        request.exist          = false;
        request.notaryBlock    = 0;
    }
    
     
    function vestingRequestExist(ChainInfo storage chain, address acc) internal view returns (bool) {
        return chain.usersData[acc].validator.vestingRequest.exist;
    }
    
     
    function depositWithdrawalRequestExist(ChainInfo storage chain, address acc) internal view returns (bool) {
        return chain.usersData[acc].transactor.depositWithdrawalRequest.exist;
    }
    
     
     
     
    function requestVest(ChainInfo storage chain, uint256 vesting, address acc) internal {
        Validator storage validator = chain.usersData[acc].validator;
        
        uint256 validatorVesting = validator.vesting;
        
         
        if (vesting > validatorVesting) {
            uint256 toVest = vesting - validatorVesting;
            token.transferFrom(acc, address(this), toVest);
        }
         
        else if (vesting != 0) {
            uint256 toWithdraw = validatorVesting - vesting;
            
            validator.vesting = vesting;    
            
             
            if (activeValidatorExist(chain, acc) == true) {
                chain.totalVesting = chain.totalVesting.sub(toWithdraw);
                
                 
                 
                if (acc != chain.lastValidator && validator.vesting < chain.usersData[chain.lastValidator].validator.vesting) {
                    chain.lastValidator = acc;
                }
            }
            
             
            token.transfer(acc, toWithdraw);
            
            emit VestInChain(chain.id, acc, vesting, chain.lastNotary.block, true);
            return;
        }
         
        
        vestingRequestCreate(chain, acc, vesting);
        emit VestInChain(chain.id, acc, vesting, chain.usersData[acc].validator.vestingRequest.notaryBlock, false);
        
        return;
    }
    
    function confirmVest(ChainInfo storage chain, address acc) internal {
        Validator storage validator             = chain.usersData[acc].validator;
        VestingRequest memory request           = chain.usersData[acc].validator.vestingRequest;
        
        vestingRequestDelete(chain, acc);
        uint256 origVesting = validator.vesting;
        
         
        if (request.newVesting > origVesting) {
             
            if (validatorExist(chain, acc) == false) {
                validatorCreate(chain, acc, request.newVesting);
            }
             
            else {
                validator.vesting = request.newVesting;
                validator.lastVestingIncreaseTime = now;
                
                if (activeValidatorExist(chain, acc) == true) {
                    chain.totalVesting = chain.totalVesting.add(request.newVesting - origVesting);
                    
                     
                    if (acc == chain.lastValidator) {
                        resetLastActiveValidator(chain);
                    }
                }    
            }
        }
         
        else {
            uint256 toWithdraw = origVesting;
            validatorDelete(chain, acc);
            
             
            token.transfer(acc, toWithdraw);
        }
        
        emit VestInChain(chain.id, acc, request.newVesting, request.notaryBlock, true);
    }
    
    function requestDeposit(ChainInfo storage chain, uint256 deposit, address acc) internal {
        Transactor storage transactor = chain.usersData[acc].transactor;
        
         
        if (deposit == 0) {
            depositWithdrawalRequestCreate(chain, acc);
            transactorBlacklist(chain, acc);
            emit DepositInChain(chain.id, acc, deposit, chain.usersData[acc].transactor.depositWithdrawalRequest.notaryBlock, false);  
          
            return;
        }
      
         
        uint256 actTransactorDeposit = transactor.deposit;
        
        if(actTransactorDeposit > deposit) {
            transactor.deposit = deposit;
         
            uint256 toWithdraw = actTransactorDeposit - deposit;
            token.transfer(acc, toWithdraw);
        } else {
            uint256 toDeposit = deposit - actTransactorDeposit;
            token.transferFrom(acc, address(this), toDeposit);
         
             
            if (transactorExist(chain, acc) == false) {
                transactorCreate(chain, acc, deposit);
            }
            else {
                transactor.deposit = deposit;
                transactorWhitelist(chain, acc);
            }
        }
        
        emit DepositInChain(chain.id, acc, deposit, chain.lastNotary.block, true);
    }
    
    function confirmDepositWithdrawal(ChainInfo storage chain, address acc) internal {
        Transactor storage transactor   = chain.usersData[acc].transactor;
        
        uint256 toWithdraw              = transactor.deposit;
        uint256 requestNotaryBlock      = transactor.depositWithdrawalRequest.notaryBlock;
        
        transactorDelete(chain, acc);
        depositWithdrawalRequestDelete(chain, acc);
        
         
        token.transfer(acc, toWithdraw);
        
        emit DepositInChain(chain.id, acc, 0, requestNotaryBlock, true);
    }
    
     
     
     

    constructor(ERC20 _token) public {
        token = _token;
    }
  
     
    function processUsersConsumptions(ChainInfo storage chain, address[] memory users, uint64[] memory userGas, uint64 largestTxGas) internal returns (uint256 totalCost) {
         
        totalCost = 0;
        
         
        uint256 userCost;
        
        uint256 transactorDeposit;
        address acc;
        for(uint256 i = 0; i < users.length; i++) {
            acc = users[i];
            Transactor storage transactor = chain.usersData[acc].transactor;
            transactorDeposit = transactor.deposit;
            
             
             
             
            if (transactorExist(chain, acc) == false || userGas[i] == 0) {
                 
                 
                if (chain.active == true) {
                    emit AccountWhitelisted(chain.id, users[i], false);
                }
                continue;
            }
            
            userCost = (userGas[i] * LARGEST_TX_FEE) / largestTxGas;
            
             
            if(userCost > transactorDeposit ) {
                userCost = transactorDeposit;
            
                transactorDelete(chain, acc);
            }
            else {
                transactorDeposit = transactorDeposit.sub(userCost);
                
                 
                transactor.deposit = transactorDeposit;
                
                 
                if (transactorDeposit < chain.minRequiredDeposit) {
                    transactorBlacklist(chain, acc);
                }
            }
            
             
            totalCost = totalCost.add(userCost);
        }
    }
    
     
    function processNotaryValidators(ChainInfo storage chain, address[] memory validators, uint32[] memory blocksMined, uint256 maxBlocksMined) internal returns (uint256 totalInvolvedVesting) {
         
        bool[] memory miningValidators = new bool[](chain.validators.list.length); 
        
         
        address actValidatorAcc;
        uint256 actValidatorIdx;
        uint256 actValidatorVesting;
        
        for(uint256 i = 0; i < validators.length; i++) {
            actValidatorAcc = validators[i];
        
             
            if (activeValidatorExist(chain, actValidatorAcc) == false || blocksMined[i] == 0) {
                continue;
            }
            
            actValidatorIdx = chain.validators.listIndex[actValidatorAcc] - 1;
            
             
             
            if (miningValidators[actValidatorIdx] == true) {
                continue;
            }
            else {
                miningValidators[actValidatorIdx] = true;
            }
            
            actValidatorVesting = chain.usersData[actValidatorAcc].validator.vesting;
            
             
            if (chain.rewardBonusRequiredVesting > 0 && actValidatorVesting >= chain.rewardBonusRequiredVesting) {
                actValidatorVesting = actValidatorVesting.mul(chain.rewardBonusPercentage + 100) / 100;
            }
            
            totalInvolvedVesting = totalInvolvedVesting.add(actValidatorVesting.mul(blocksMined[i])); 
        }
        totalInvolvedVesting /= maxBlocksMined;

         
        for(uint256 i = 0; i < chain.validators.list.length; i++) {
            actValidatorAcc = chain.validators.list[i];
            
            Validator storage validator = chain.usersData[actValidatorAcc].validator;
            validator.prevNotaryMined   = validator.currentNotaryMined;
            
            if (miningValidators[i] == true) {
                validator.currentNotaryMined = true;
            }
            else {
                validator.currentNotaryMined = false;
            }
        }
        
         
        uint256 activeValidatorsCount = chain.validators.list.length; 
        for (uint256 i = 0; i < activeValidatorsCount; ) {
            actValidatorAcc = chain.validators.list[i];
            Validator memory validator = chain.usersData[actValidatorAcc].validator;
           
            if (validator.currentNotaryMined == true || validator.prevNotaryMined == true) {
                i++;
                continue;
            }
           
            activeValidatorRemove(chain, actValidatorAcc);
            activeValidatorsCount--;
        } 
     
        delete miningValidators;   
    }

     
    function processValidatorsRewards(ChainInfo storage chain, uint256 totalInvolvedVesting, address[] memory validators, uint32[] memory blocksMined, uint256 maxBlocksMined, uint256 litToDistribute) internal {
         
        bool[] memory miningValidators = new bool[](chain.validators.list.length); 
        
         
        address actValidatorAcc;
        uint256 actValidatorIdx;
        uint256 actValidatorVesting;
        uint256 actValidatorReward;
        
         
        uint256 litToDistributeRest = litToDistribute;
        
         
         
         
        for(uint256 i = 0; i < validators.length; i++) {
            actValidatorAcc = validators[i];
            
             
            if (activeValidatorExist(chain, actValidatorAcc) == false || blocksMined[i] == 0) {
                continue;
            } 
            
            actValidatorIdx = chain.validators.listIndex[actValidatorAcc] - 1;
            
             
             
            if (miningValidators[actValidatorIdx] == true) {
                continue;
            }
            else {
                miningValidators[actValidatorIdx] = true;
            }
            
            Validator storage actValidator = chain.usersData[actValidatorAcc].validator;
            actValidatorVesting = actValidator.vesting;
            
             
            if (chain.rewardBonusRequiredVesting > 0 && actValidatorVesting >= chain.rewardBonusRequiredVesting) {
                actValidatorVesting = actValidatorVesting.mul(chain.rewardBonusPercentage + 100) / 100;
            }
        
            actValidatorReward = actValidatorVesting.mul(blocksMined[i]).mul(litToDistribute) / maxBlocksMined / totalInvolvedVesting;
            
            litToDistributeRest = litToDistributeRest.sub(actValidatorReward);
            
             
            actValidator.vesting = actValidator.vesting.add(actValidatorReward);
            
            emit MiningReward(chain.id, actValidatorAcc, actValidatorReward);
        }
        
        if(litToDistributeRest > 0) {
             
            Validator storage sender = chain.usersData[msg.sender].validator;
            
            sender.vesting = sender.vesting.add(litToDistributeRest);
            
            if (activeValidatorExist(chain, msg.sender) == false) {
                chain.totalVesting = chain.totalVesting.sub(litToDistributeRest);
            }
            
            emit MiningReward(chain.id, msg.sender, litToDistributeRest);
        }
        
         
        chain.totalVesting = chain.totalVesting.add(litToDistribute); 
        
         
        resetLastActiveValidator(chain);

        delete miningValidators;
    }
   
    
    function validateNotaryConditions(ChainInfo storage chain, bytes32 signatureHash, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) internal view {
        uint256 involvedVestingSum = 0;
        uint256 involvedSignaturesCount = 0;
        
        bool[] memory signedValidators = new bool[](chain.validators.list.length); 
        
        address signerAcc;
        for(uint256 i = 0; i < v.length; i++) {
            signerAcc = ecrecover(signatureHash, v[i], r[i], s[i]);
            
             
            if (activeValidatorExist(chain, signerAcc) == false) {
                continue;
            }
            
            uint256 validatorIdx = chain.validators.listIndex[signerAcc] - 1;
            
             
            if (signedValidators[validatorIdx] == true) {
                continue;
            }
            else {
                signedValidators[validatorIdx] = true;
            }
            
            
            involvedVestingSum = involvedVestingSum.add(chain.usersData[signerAcc].validator.vesting);
            involvedSignaturesCount++;
        }
        
        delete signedValidators;
        
         
        if (chain.involvedVestingNotaryCond == true) {
             
            involvedVestingSum = involvedVestingSum.mul(2);
            require(involvedVestingSum > chain.totalVesting, "Invalid statistics data: involvedVesting <= 50% of chain.totalVesting");
        }
        
        
         
        if (chain.participationNotaryCond == true) {
            uint256 actNumOfValidators = chain.validators.list.length;
            
             
            if (actNumOfValidators >= 4) {
                uint256 minRequiredSignaturesCount = ((2 * actNumOfValidators) / 3) + 1;
                
                require(involvedSignaturesCount >= minRequiredSignaturesCount, "Invalid statistics data: Not enough signatures provided (2/3 + 1 cond)");
            }
             
            else {
                require(involvedSignaturesCount == actNumOfValidators, "Invalid statistics data: Not enough signatures provided (involvedSignatures == activeValidatorsCount)");
            }
        }
    }
   
     
     
    function checkAndSetChainActivity(ChainInfo storage chain) internal {
        if (chain.active == true && chain.lastNotary.timestamp + CHAIN_INACTIVITY_TIMEOUT < now) {
            chain.active = false;   
        }
    }
}

 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
}