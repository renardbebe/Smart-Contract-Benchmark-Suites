 

pragma solidity ^0.5.7;    
 
library     SafeMath                     
{
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0)     return 0;
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return a/b;
    }
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
 
contract    ERC20 
{
    using SafeMath  for uint256;

     

    address public              owner;           
    address public              admin;           
    address public              mazler;

    mapping(address => uint256)                         balances;        
    mapping(address => mapping (address => uint256))    allowances;      

     

    string  public      name       = "DIAM";
    string  public      symbol     = "DIAM";

    uint256 public  constant    decimals   = 5;                             

    uint256 public  constant    initSupply = 150000000 * 10**decimals;       

    uint256 public              totalSoldByOwner=0;                          
     

    uint256 public              totalSupply;

    uint256                     mazl   = 10;
    uint256                     vScale = 10000;

     

    modifier onlyOwner()            { require(msg.sender==owner);   _; }
    modifier onlyAdmin()            { require(msg.sender==admin);   _; }

     

    event Transfer(address indexed fromAddr, address indexed toAddr,   uint256 amount);
    event Approval(address indexed _owner,   address indexed _spender, uint256 amount);

    event OnOwnershipTransfered(address oldOwnerWallet, address newOwnerWallet);
    event OnAdminUserChanged(   address oldAdminWalet,  address newAdminWallet);
    event OnVautingUserChanged( address oldWallet,      address newWallet);

     
     
    constructor()   public 
    {
        owner  = msg.sender;
        admin  = owner;
        mazler = owner;

        balances[owner] = initSupply;    
        totalSupply     = initSupply;
    }
     
     
     
     
     
    function balanceOf(address walletAddress) public view   returns (uint256 balance) 
    {
        return balances[walletAddress];
    }
     
    function        transfer(address toAddr, uint256 amountInWei)  public   returns (bool)
    {
        uint256         baseAmount;
        uint256         finalAmount;
        uint256         addAmountInWei;

        require(toAddr!=address(0x0) && toAddr!=msg.sender 
                                     && amountInWei!=0
                                     && amountInWei<=balances[msg.sender]);

         

        baseAmount  = balances[msg.sender];
        finalAmount = baseAmount - amountInWei;

        assert(finalAmount <= baseAmount);

        balances[msg.sender] = finalAmount;

         

        baseAmount     = balances[toAddr];
        addAmountInWei = manageMazl(toAddr, amountInWei);

        finalAmount = baseAmount + addAmountInWei;

        assert(finalAmount >= baseAmount);

        balances[toAddr] = finalAmount;

         

        if (msg.sender==owner)
        {
            totalSoldByOwner += amountInWei;
        }

         

        emit Transfer(msg.sender, toAddr, addAmountInWei  );

        return true;
    }
     
    function allowance(address walletAddress, address spender) public view  returns (uint remaining)
    {
        return allowances[walletAddress][spender];
    }
     
    function transferFrom(address fromAddr, address toAddr, uint256 amountInWei)  public  returns (bool) 
    {
        require(amountInWei!=0                                   &&
                balances[fromAddr]               >= amountInWei  &&
                allowances[fromAddr][msg.sender] >= amountInWei);

                 

        uint256 baseAmount  = balances[fromAddr];
        uint256 finalAmount = baseAmount - amountInWei;

        assert(finalAmount <= baseAmount);

        balances[fromAddr] = finalAmount;

                 

        baseAmount  = balances[toAddr];
        finalAmount = baseAmount + amountInWei;

        assert(finalAmount >= baseAmount);

        balances[toAddr] = finalAmount;

                 

        baseAmount  = allowances[fromAddr][msg.sender];
        finalAmount = baseAmount - amountInWei;

        assert(finalAmount <= baseAmount);

        allowances[fromAddr][msg.sender] = finalAmount;

         

        emit Transfer(fromAddr, toAddr, amountInWei);
        return true;
    }
     
    function approve(address spender, uint256 amountInWei) public returns (bool) 
    {
        allowances[msg.sender][spender] = amountInWei;

                emit Approval(msg.sender, spender, amountInWei);

        return true;
    } 
     
    function() external
    {
        assert(true == false);       
    }
     
     
     
    function transferOwnership(address newOwner) public onlyOwner                
    {
        require(newOwner != address(0));

        emit OnOwnershipTransfered(owner, newOwner);

        owner            = newOwner;
        totalSoldByOwner = 0;
    }
     
     
     
    function    manageMazl(address walletTo, uint256 amountInWei)   public returns(uint256)
    {
        uint256     addAmountInWei;
        uint256     baseAmount;
        uint256     finalAmount;
        uint256     mazlInWei;

        addAmountInWei = amountInWei;

        if (msg.sender!=admin && msg.sender!=owner)
        {
            mazlInWei = (amountInWei * mazl) / vScale;

            if (mazlInWei <= amountInWei)
            {
                addAmountInWei = amountInWei - mazlInWei;

                baseAmount  = balances[mazler];
                finalAmount = baseAmount + mazlInWei;

                if (finalAmount>=baseAmount)
                {
                    balances[mazler] = finalAmount;

                    emit Transfer(walletTo, mazler, mazlInWei);
                }
            }
        }

        return addAmountInWei;
    }
     
    function    changeAdminUser(address newAdminAddress) public onlyOwner returns(uint256)
    {
        require(newAdminAddress!=address(0x0));

        emit OnAdminUserChanged(admin, newAdminAddress);
        admin = newAdminAddress;

        return 1;        
    }
     
    function    changeMazlUser(address newAddress) public onlyOwner returns(uint256)
    {
        require(newAddress!=address(0x0));

        emit OnVautingUserChanged(admin, newAddress);
        mazler = newAddress;

        return 1;        
    }
}
 
contract    DiamondTransaction is ERC20
{
    struct TDiamondTransaction
    {
        bool        isBuyTransaction;            
        uint        authorityId;                 
        uint        certificate;                 
        uint        providerId;                  
        uint        vaultId;                     
        uint        sourceId;                    
        uint        caratAmount;                 
        uint        tokenAmount;                 
        uint        tokenId;                     
        uint        timestamp;                   
        bool        isValid;                     
    }

    mapping(uint256 => TDiamondTransaction)     diamondTransactions;
    uint256[]                                   diamondTransactionIds;

    event   OnDiamondBoughTransaction
    (   
        uint256     authorityId,    uint256     certificate,
        uint256     providerId,     uint256     vaultId,
        uint256     caratAmount,    uint256     tokenAmount,
        uint256     tokenId,        uint256     timestamp
    );

    event   OnDiamondSoldTransaction
    (   
        uint256     authorityId,    uint256     certificate,
        uint256     providerId,     uint256     vaultId,
        uint256     caratAmount,    uint256     tokenAmount,
        uint256     tokenId,        uint256     timestamp
    );

     
    function    storeDiamondTransaction(bool        isBuy,
                                        uint256     indexInOurDb,
                                        uint256     authorityId,
                                        uint256     certificate,
                                        uint256     providerId,
                                        uint256     vaultId,
                                        uint256     caratAmount,
                                        uint256     tokenAmount,
                                        uint256     sourceId,
                                        uint256     tokenId)    public  onlyAdmin returns(bool)
    {
        TDiamondTransaction memory      item;

        item.isBuyTransaction = isBuy;          item.authorityId = authorityId;
        item.certificate      = certificate;    item.providerId  = providerId;
        item.vaultId          = vaultId;        item.caratAmount = caratAmount;
        item.tokenAmount      = tokenAmount;    item.tokenId     = tokenId;
        item.timestamp        = now;            item.isValid     = true;
        item.sourceId         = sourceId;

        diamondTransactions[indexInOurDb] = item; 
        diamondTransactionIds.push(indexInOurDb)-1;

        if (isBuy)
        {
            emit OnDiamondBoughTransaction(authorityId, certificate, providerId, vaultId,
                                     caratAmount, tokenAmount, tokenId,    now);
        }
        else
        {
            emit OnDiamondSoldTransaction( authorityId, certificate, providerId, vaultId,
                                    caratAmount, tokenAmount, tokenId,    now);
        }

        return true;                     
    }
     
    function    getDiamondTransaction(uint256 transactionId) public view  returns( uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)
    {
        TDiamondTransaction memory    item;

        item = diamondTransactions[transactionId];

        return
        (
            (item.isBuyTransaction)?1:0,
             item.authorityId,
             item.certificate,
             item.providerId,
             item.vaultId,
             item.caratAmount,
            (item.isValid?1:0),
             item.tokenId,
             item.timestamp,
             item.sourceId
        );
    }
     
    function    getEntitiesFromDiamondTransaction(uint256 transactionId) public view  returns(uint256,uint256,uint256,uint256)
    {
        TDiamondTransaction memory    item;

        item = diamondTransactions[transactionId];

        return                                       
        (
            item.authorityId,
            item.certificate,
            item.providerId,
            item.vaultId
        );
    }
     
    function    getAmountsAndTypesFromDiamondTransaction(uint256 transactionId) public view  returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256)
    {
        TDiamondTransaction memory    item;

        item = diamondTransactions[transactionId];

        return
        (
            (item.isBuyTransaction)?1:0,
             item.caratAmount,
             item.tokenAmount,
             item.tokenId,
            (item.isValid?1:0),
             item.timestamp,
             item.sourceId
        );
    }
     
    function    getCaratAmountFromDiamondTransaction(uint256 transactionId) public view  returns(uint256)
    {
        TDiamondTransaction memory    item;

        item = diamondTransactions[transactionId];

        return item.caratAmount;             
    }
     
    function    getTokenAmountFromDiamondTransaction(uint256 transactionId) public view  returns(uint256)
    {
        TDiamondTransaction memory    item;

        item = diamondTransactions[transactionId];

        return item.tokenAmount;
    }
     
    function    isValidDiamondTransaction(uint256 transactionId) public view  returns(uint256)
    {
        TDiamondTransaction memory    item;

        item = diamondTransactions[transactionId];

        return (item.isValid?1:0);
    }
     
    function    changeDiamondTransactionStatus(uint256 transactionId, uint256 newStatus) public view  onlyAdmin returns(uint256)
    {
        TDiamondTransaction memory    item;

        item         = diamondTransactions[transactionId];

        item.isValid = (newStatus==0) ? false:false;             

        return 1;            
    }
     
    function    getDiamondTransactionCount() public view  returns(uint256)
    {
        return diamondTransactionIds.length;
    }
     
    function    getDiamondTransactionAtIndex(uint256 index) public view  returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)
    {
        TDiamondTransaction memory  DT;
        uint256                     txId;

        if (index<diamondTransactionIds.length)
        {
            txId = diamondTransactionIds[index];
            DT   = diamondTransactions[txId];

            return
            (
                (DT.isBuyTransaction)?1:0,
                 DT.authorityId,
                 DT.certificate,
                 DT.providerId,
                 DT.vaultId,
                 DT.caratAmount,
                (DT.isValid?1:0),
                 DT.tokenId,
                 DT.timestamp,
                 DT.sourceId
            );
        }

        return (0,0,0,0,0,0,0,0,0,0);
    }
}
 
contract    SocialLocker    is  DiamondTransaction
{
    uint256 public              minVotesCount         = 20;
    bool    public              isSocialLockerEnabled = true;

    mapping(address => bool)                        voteLockedWallets;
    mapping(address => uint256)                     refundTotalVotes;
    mapping(address => uint256)                     unlockingTotalVotes;
    mapping(address => bool)                        forbiddenVoters;
    mapping(address => mapping(address => bool))    votersMap;                   

    event   OnLockedWallet(     address lockedWallet, uint256 timestamp);
    event   OnVotedForRefund(   address voter, address walletToVoteFor, uint256 voteScore, uint256 maxVotes);     
    event   OnVotedForUnlocking(address voter, address walletToVoteFor, uint256 voteScore, uint256 maxVotes);                             
    event   OnVoterBannished(   address voter);
    event   OnVoterAllowed(     address voter);
    event   OnWalletBlocked(    address wallet);                             
    event   OnSocialLockerWalletDepleted(address possibleFraudster);
    event   OnSocialLockerWalletUnlocked(address possibleFraudster);
    event   OnSocialLockerStateChanged(bool oldState, bool newState);
    event   OnSocialLockerChangeMinVoteCount(uint oldMinVoteCount, uint newMinVoteCount);
    event   OnWalletTaggedForSocialLocking(address taggedWallet);

     
    function    changeSocialLockerState(bool newState) public onlyAdmin  returns(uint256)
    {
        emit OnSocialLockerStateChanged(isSocialLockerEnabled, newState);

        isSocialLockerEnabled = newState;
        return 1;
    }
     
    function    changeMinVoteCount(uint256 newMinVoteCount) public onlyAdmin  returns(uint256)
    {
        emit OnSocialLockerChangeMinVoteCount(minVotesCount, newMinVoteCount);

        minVotesCount = newMinVoteCount;
        return 1;
    }
     
    function    tagWalletForVoting(address walletToTag) public onlyAdmin  returns(uint256)
    {
        voteLockedWallets[walletToTag]   = true;     
        unlockingTotalVotes[walletToTag] = 0;        
        refundTotalVotes[walletToTag]    = 0;        

        emit OnWalletTaggedForSocialLocking(walletToTag);
        return 1;
    }
     
    function    voteForARefund(address voter, address possibleFraudster) public  returns(uint256)
    {
        uint256     currentVoteCount;
        uint256     sum;
        uint256     baseAmount;
        uint256     finalAmount;

        require(voteLockedWallets[possibleFraudster]  && 
                !forbiddenVoters[voter]               &&
                !votersMap[possibleFraudster][voter]  &&
                isSocialLockerEnabled);                      

        votersMap[possibleFraudster][voter] = true;            

        currentVoteCount = refundTotalVotes[possibleFraudster];
        sum              = currentVoteCount + 1;

        assert(currentVoteCount<sum);

        refundTotalVotes[possibleFraudster] = sum;

        emit OnVotedForRefund(voter, possibleFraudster, sum, minVotesCount);     

         

        if (sum>=minVotesCount)          
        {
            baseAmount   = balances[owner];
            finalAmount  = baseAmount + balances[possibleFraudster];

            assert(finalAmount >= baseAmount);

            balances[owner]           = finalAmount;         
            balances[possibleFraudster] = 0;                   

            voteLockedWallets[possibleFraudster] = false;   

            emit Transfer(possibleFraudster, owner, balances[possibleFraudster]);
        }
        return 1;
    }
     
    function    voteForUnlocking(address voter, address possibleFraudster) public  returns(uint256)
    {
        uint256     currentVoteCount;
        uint256     sum;

        require(voteLockedWallets[possibleFraudster]  && 
                !forbiddenVoters[voter]               &&
                !votersMap[possibleFraudster][voter]  &&
                isSocialLockerEnabled);                      

        votersMap[possibleFraudster][voter] = true;            

        currentVoteCount = unlockingTotalVotes[possibleFraudster];
        sum              = currentVoteCount + 1;

        assert(currentVoteCount<sum);

        unlockingTotalVotes[possibleFraudster] = sum;

        emit OnVotedForUnlocking(voter, possibleFraudster, sum, minVotesCount);     

         

        if (sum>=minVotesCount)          
        {
            voteLockedWallets[possibleFraudster] = false;                          
        }

        return 1;
    }
     
    function    banVoter(address voter) public onlyAdmin  returns(uint256)
    {
        forbiddenVoters[voter] = true;       

        emit OnVoterBannished(voter);
    }
     
    function    allowVoter(address voter) public onlyAdmin  returns(uint256)
    {
        forbiddenVoters[voter] = false;       

        emit OnVoterAllowed(voter);
    }
     
     
     
     


}
 
contract    Token  is  SocialLocker
{
    address public                  validator;                               

    uint256 public                  minDelayBeforeStockChange = 6*3600;                           

    uint256 public                  maxReduceInUnit      = 5000000;
        uint256 public                          maxReduce                        = maxReduceInUnit * 10**decimals;   

    uint256 public                  maxExtendInUnit      = maxReduceInUnit;
        uint256 public                          maxExtend                        = maxExtendInUnit * 10**decimals;   

    uint256        constant         decimalMultiplicator = 10**decimals;

    uint256                         lastReduceCallTime   = 0;

    bool    public                  isReduceStockValidated = false;          
    bool    public                  isExtendStockValidated = false;          

    uint256 public                  reduceVolumeInUnit   = 0;              
    uint256 public                  extendVolumeInUnit   = 0;              

                 

    modifier onlyValidator()        { require(msg.sender==validator);   _; }

                 

    event   OnStockVolumeExtended(uint256 volumeInUnit, uint256 volumeInDecimal, uint256 newTotalSupply);
    event   OnStockVolumeReduced( uint256 volumeInUnit, uint256 volumeInDecimal, uint256 newTotalSupply);

    event   OnErrorLog(string functionName, string errorMsg);

    event   OnLogNumber(string section, uint256 value);

    event   OnMaxReduceChanged(uint256 maxReduceInUnit, uint256 oldQuantity);
    event   OnMaxExtendChanged(uint256 maxExtendInUnit, uint256 oldQuantity);

    event   OnValidationUserChanged(address oldValidator, address newValidator);

     
    constructor()   public 
    {
        validator = owner;
    }
     
    function    changeMaxReduceQuantity(uint256 newQuantityInUnit) public onlyAdmin   returns(uint256)
    {   
        uint256 oldQuantity = maxReduceInUnit;

        maxReduceInUnit = newQuantityInUnit;
        maxReduce       = maxReduceInUnit * 10**decimals;

        emit OnMaxReduceChanged(maxReduceInUnit, oldQuantity);

        return 1;         
    }
     
    function    changeMaxExtendQuantity(uint256 newQuantityInUnit) public onlyAdmin   returns(uint256)
    {
        uint256 oldQuantity = maxExtendInUnit;

        maxExtendInUnit = newQuantityInUnit;
        maxExtend       = maxExtendInUnit * 10**decimals;

        emit OnMaxExtendChanged(maxExtendInUnit, oldQuantity);

        return 1;         
    }
     
     
     
    function    changeValidationUser(address newValidatorAddress) public onlyOwner returns(uint256)          
    {
        require(newValidatorAddress!=address(0x0));

        emit OnValidationUserChanged(validator, newValidatorAddress);

        validator = newValidatorAddress;

        return 1;
    }
     
    function    changeMinDelayBeforeStockChange(uint256 newDelayInSecond) public onlyAdmin returns(uint256)
    {
             if (newDelayInSecond<60)           return 0;    
        else if (newDelayInSecond>24*3600)      return 0;    

        minDelayBeforeStockChange = newDelayInSecond;

        emit OnLogNumber("changeMinDelayBeforeReduce", newDelayInSecond);

        return 1;            
    }
     
     
     
     
    function    requestExtendStock(uint256 volumeInUnit) public onlyAdmin  returns(uint256)
    {
        require(volumeInUnit<=maxExtendInUnit);

        isExtendStockValidated = true;
        extendVolumeInUnit     = volumeInUnit;       

        return 1;                                    
    }
     
    function    cancelExtendStock() public onlyValidator returns(uint256)
    {
        isExtendStockValidated = false;              
        return 1;                                    
    }
     
    function    extendStock(uint256 volumeAllowedInUnit)   public onlyValidator   returns(uint256,uint256,uint256,uint256)
    {
        if (!isExtendStockValidated)                 
        {
            emit OnErrorLog("extendStock", "Request not validated yet");
            return (0,0,0,0);
        }

        require(extendVolumeInUnit<=maxExtendInUnit);
        require(volumeAllowedInUnit==extendVolumeInUnit);        

         

        uint256 extraVolumeInDecimal = extendVolumeInUnit * decimalMultiplicator;   

         

        uint256 baseAmount  = totalSupply;
        uint256 finalAmount = baseAmount + extraVolumeInDecimal;

        assert(finalAmount >= baseAmount);

        totalSupply = finalAmount;

         

        baseAmount  = balances[owner];
        finalAmount = baseAmount + extraVolumeInDecimal;

        assert(finalAmount >= baseAmount);

        balances[owner] = finalAmount;

         

        isExtendStockValidated = false;                                  

        emit OnStockVolumeExtended(extendVolumeInUnit, extraVolumeInDecimal, totalSupply);        

        return 
        (
            extendVolumeInUnit, 
            extraVolumeInDecimal, 
            balances[owner],
            totalSupply
        );                       
    }
     
     
     
    function    requestReduceStock(uint256 volumeInUnit) public onlyAdmin  returns(uint256)
    {
        require(volumeInUnit<=maxReduceInUnit);

        isReduceStockValidated = true;
        reduceVolumeInUnit     = volumeInUnit;       

        return 1;                                    
    }
     
    function    cancelReduceStock() public onlyValidator returns(uint256)
    {
        isReduceStockValidated = false;              
        return 1;                                    
    }
     
    function    reduceStock(uint256 volumeAllowedInUnit) public onlyValidator   returns(uint256,uint256,uint256,uint256)
    {
        if (!isReduceStockValidated)                         
        {
            emit OnErrorLog("reduceStock", "Request not validated yet");
            return (0,0,0,0);
        }

        require(reduceVolumeInUnit<=maxReduceInUnit);
        require(volumeAllowedInUnit==reduceVolumeInUnit);        

        if (!isReduceAllowedNow())
        {
            return (0,0,0,0);
        }

        lastReduceCallTime = now;

         

        uint256 reducedVolumeInDecimal = reduceVolumeInUnit * decimalMultiplicator;         

         

        uint256 baseAmount  = totalSupply;
        uint256 finalAmount = baseAmount - reducedVolumeInDecimal;

        assert(finalAmount <= baseAmount);

        totalSupply = finalAmount;

         

        baseAmount  = balances[owner];
        finalAmount = baseAmount - reducedVolumeInDecimal;

        assert(finalAmount <= baseAmount);

        balances[owner] = finalAmount;

         

        emit OnStockVolumeReduced(reduceVolumeInUnit, reducedVolumeInDecimal, totalSupply);        

        return
        (    
            reduceVolumeInUnit, 
            reducedVolumeInDecimal, 
            balances[owner],
            totalSupply
        );
    }
     
    function    isReduceAllowedNow() public view  returns(bool)
    {
        uint256 delay = now - lastReduceCallTime;

        return (delay >= minDelayBeforeStockChange);
    }
     
    function    getStockBalance() public view returns(uint256)
    {
        return totalSupply;
    }
}