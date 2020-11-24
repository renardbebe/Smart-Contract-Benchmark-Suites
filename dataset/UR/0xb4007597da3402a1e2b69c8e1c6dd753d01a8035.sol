 

pragma solidity ^0.4.17;

 



contract ApplicationEntityABI {

    address public ProposalsEntity;
    address public FundingEntity;
    address public MilestonesEntity;
    address public MeetingsEntity;
    address public BountyManagerEntity;
    address public TokenManagerEntity;
    address public ListingContractEntity;
    address public FundingManagerEntity;
    address public NewsContractEntity;

    bool public _initialized = false;
    bool public _locked = false;
    uint8 public CurrentEntityState;
    uint8 public AssetCollectionNum;
    address public GatewayInterfaceAddress;
    address public deployerAddress;
    address testAddressAllowUpgradeFrom;
    mapping (bytes32 => uint8) public EntityStates;
    mapping (bytes32 => address) public AssetCollection;
    mapping (uint8 => bytes32) public AssetCollectionIdToName;
    mapping (bytes32 => uint256) public BylawsUint256;
    mapping (bytes32 => bytes32) public BylawsBytes32;

    function ApplicationEntity() public;
    function getEntityState(bytes32 name) public view returns (uint8);
    function linkToGateway( address _GatewayInterfaceAddress, bytes32 _sourceCodeUrl ) external;
    function setUpgradeState(uint8 state) public ;
    function addAssetProposals(address _assetAddresses) external;
    function addAssetFunding(address _assetAddresses) external;
    function addAssetMilestones(address _assetAddresses) external;
    function addAssetMeetings(address _assetAddresses) external;
    function addAssetBountyManager(address _assetAddresses) external;
    function addAssetTokenManager(address _assetAddresses) external;
    function addAssetFundingManager(address _assetAddresses) external;
    function addAssetListingContract(address _assetAddresses) external;
    function addAssetNewsContract(address _assetAddresses) external;
    function getAssetAddressByName(bytes32 _name) public view returns (address);
    function setBylawUint256(bytes32 name, uint256 value) public;
    function getBylawUint256(bytes32 name) public view returns (uint256);
    function setBylawBytes32(bytes32 name, bytes32 value) public;
    function getBylawBytes32(bytes32 name) public view returns (bytes32);
    function initialize() external returns (bool);
    function getParentAddress() external view returns(address);
    function createCodeUpgradeProposal( address _newAddress, bytes32 _sourceCodeUrl ) external returns (uint256);
    function acceptCodeUpgradeProposal(address _newAddress) external;
    function initializeAssetsToThisApplication() external returns (bool);
    function transferAssetsToNewApplication(address _newAddress) external returns (bool);
    function lock() external returns (bool);
    function canInitiateCodeUpgrade(address _sender) public view returns(bool);
    function doStateChanges() public;
    function hasRequiredStateChanges() public view returns (bool);
    function anyAssetHasChanges() public view returns (bool);
    function extendedAnyAssetHasChanges() internal view returns (bool);
    function getRequiredStateChanges() public view returns (uint8, uint8);
    function getTimestamp() view public returns (uint256);

}

 




contract ApplicationAsset {

    event EventAppAssetOwnerSet(bytes32 indexed _name, address indexed _owner);
    event EventRunBeforeInit(bytes32 indexed _name);
    event EventRunBeforeApplyingSettings(bytes32 indexed _name);


    mapping (bytes32 => uint8) public EntityStates;
    mapping (bytes32 => uint8) public RecordStates;
    uint8 public CurrentEntityState;

    event EventEntityProcessor(bytes32 indexed _assetName, uint8 indexed _current, uint8 indexed _required);
    event DebugEntityRequiredChanges( bytes32 _assetName, uint8 indexed _current, uint8 indexed _required );

    bytes32 public assetName;

     
    uint8 public RecordNum = 0;

     
    bool public _initialized = false;

     
    bool public _settingsApplied = false;

     
    address public owner = address(0x0) ;
    address public deployerAddress;

    function ApplicationAsset() public {
        deployerAddress = msg.sender;
    }

    function setInitialApplicationAddress(address _ownerAddress) public onlyDeployer requireNotInitialised {
        owner = _ownerAddress;
    }

    function setInitialOwnerAndName(bytes32 _name) external
        requireNotInitialised
        onlyOwner
        returns (bool)
    {
         
        setAssetStates();
        assetName = _name;
         
        CurrentEntityState = getEntityState("NEW");
        runBeforeInitialization();
        _initialized = true;
        EventAppAssetOwnerSet(_name, owner);
        return true;
    }

    function setAssetStates() internal {
         
        EntityStates["__IGNORED__"]     = 0;
        EntityStates["NEW"]             = 1;
         
        RecordStates["__IGNORED__"]     = 0;
    }

    function getRecordState(bytes32 name) public view returns (uint8) {
        return RecordStates[name];
    }

    function getEntityState(bytes32 name) public view returns (uint8) {
        return EntityStates[name];
    }

    function runBeforeInitialization() internal requireNotInitialised  {
        EventRunBeforeInit(assetName);
    }

    function applyAndLockSettings()
        public
        onlyDeployer
        requireInitialised
        requireSettingsNotApplied
        returns(bool)
    {
        runBeforeApplyingSettings();
        _settingsApplied = true;
        return true;
    }

    function runBeforeApplyingSettings() internal requireInitialised requireSettingsNotApplied  {
        EventRunBeforeApplyingSettings(assetName);
    }

    function transferToNewOwner(address _newOwner) public requireInitialised onlyOwner returns (bool) {
        require(owner != address(0x0) && _newOwner != address(0x0));
        owner = _newOwner;
        EventAppAssetOwnerSet(assetName, owner);
        return true;
    }

    function getApplicationAssetAddressByName(bytes32 _name)
        public
        view
        returns(address)
    {
        address asset = ApplicationEntityABI(owner).getAssetAddressByName(_name);
        if( asset != address(0x0) ) {
            return asset;
        } else {
            revert();
        }
    }

    function getApplicationState() public view returns (uint8) {
        return ApplicationEntityABI(owner).CurrentEntityState();
    }

    function getApplicationEntityState(bytes32 name) public view returns (uint8) {
        return ApplicationEntityABI(owner).getEntityState(name);
    }

    function getAppBylawUint256(bytes32 name) public view requireInitialised returns (uint256) {
        ApplicationEntityABI CurrentApp = ApplicationEntityABI(owner);
        return CurrentApp.getBylawUint256(name);
    }

    function getAppBylawBytes32(bytes32 name) public view requireInitialised returns (bytes32) {
        ApplicationEntityABI CurrentApp = ApplicationEntityABI(owner);
        return CurrentApp.getBylawBytes32(name);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyApplicationEntity() {
        require(msg.sender == owner);
        _;
    }

    modifier requireInitialised() {
        require(_initialized == true);
        _;
    }

    modifier requireNotInitialised() {
        require(_initialized == false);
        _;
    }

    modifier requireSettingsApplied() {
        require(_settingsApplied == true);
        _;
    }

    modifier requireSettingsNotApplied() {
        require(_settingsApplied == false);
        _;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployerAddress);
        _;
    }

    modifier onlyAsset(bytes32 _name) {
        address AssetAddress = getApplicationAssetAddressByName(_name);
        require( msg.sender == AssetAddress);
        _;
    }

    function getTimestamp() view public returns (uint256) {
        return now;
    }


}

 



contract ABIApplicationAsset {

    bytes32 public assetName;
    uint8 public CurrentEntityState;
    uint8 public RecordNum;
    bool public _initialized;
    bool public _settingsApplied;
    address public owner;
    address public deployerAddress;
    mapping (bytes32 => uint8) public EntityStates;
    mapping (bytes32 => uint8) public RecordStates;

    function setInitialApplicationAddress(address _ownerAddress) public;
    function setInitialOwnerAndName(bytes32 _name) external returns (bool);
    function getRecordState(bytes32 name) public view returns (uint8);
    function getEntityState(bytes32 name) public view returns (uint8);
    function applyAndLockSettings() public returns(bool);
    function transferToNewOwner(address _newOwner) public returns (bool);
    function getApplicationAssetAddressByName(bytes32 _name) public returns(address);
    function getApplicationState() public view returns (uint8);
    function getApplicationEntityState(bytes32 name) public view returns (uint8);
    function getAppBylawUint256(bytes32 name) public view returns (uint256);
    function getAppBylawBytes32(bytes32 name) public view returns (bytes32);
    function getTimestamp() view public returns (uint256);


}

 





contract ABITokenManager is ABIApplicationAsset {

    address public TokenSCADAEntity;
    address public TokenEntity;
    address public MarketingMethodAddress;
    bool OwnerTokenBalancesReleased = false;

    function addSettings(address _scadaAddress, address _tokenAddress, address _marketing ) public;
    function getTokenSCADARequiresHardCap() public view returns (bool);
    function mint(address _to, uint256 _amount) public returns (bool);
    function finishMinting() public returns (bool);
    function mintForMarketingPool(address _to, uint256 _amount) external returns (bool);
    function ReleaseOwnersLockedTokens(address _multiSigOutputAddress) public returns (bool);

}

 





contract ABIProposals is ABIApplicationAsset {

    address public Application;
    address public ListingContractEntity;
    address public FundingEntity;
    address public FundingManagerEntity;
    address public TokenManagerEntity;
    address public TokenEntity;
    address public MilestonesEntity;

    struct ProposalRecord {
        address creator;
        bytes32 name;
        uint8 actionType;
        uint8 state;
        bytes32 hash;                        
        address addr;
        bytes32 sourceCodeUrl;
        uint256 extra;
        uint256 time_start;
        uint256 time_end;
        uint256 index;
    }

    struct VoteStruct {
        address voter;
        uint256 time;
        bool    vote;
        uint256 power;
        bool    annulled;
        uint256 index;
    }

    struct ResultRecord {
        uint256 totalAvailable;
        uint256 requiredForResult;
        uint256 totalSoFar;
        uint256 yes;
        uint256 no;
        bool    requiresCounting;
    }

    uint8 public ActiveProposalNum;
    uint256 public VoteCountPerProcess;
    bool public EmergencyFundingReleaseApproved;

    mapping (bytes32 => uint8) public ActionTypes;
    mapping (uint8 => uint256) public ActiveProposalIds;
    mapping (uint256 => bool) public ExpiredProposalIds;
    mapping (uint256 => ProposalRecord) public ProposalsById;
    mapping (bytes32 => uint256) public ProposalIdByHash;
    mapping (uint256 => mapping (uint256 => VoteStruct) ) public VotesByProposalId;
    mapping (uint256 => mapping (address => VoteStruct) ) public VotesByCaster;
    mapping (uint256 => uint256) public VotesNumByProposalId;
    mapping (uint256 => ResultRecord ) public ResultsByProposalId;
    mapping (uint256 => uint256) public lastProcessedVoteIdByProposal;
    mapping (uint256 => uint256) public ProcessedVotesByProposal;
    mapping (uint256 => uint256) public VoteCountAtProcessingStartByProposal;

    function getRecordState(bytes32 name) public view returns (uint8);
    function getActionType(bytes32 name) public view returns (uint8);
    function getProposalState(uint256 _proposalId) public view returns (uint8);
    function getBylawsProposalVotingDuration() public view returns (uint256);
    function getBylawsMilestoneMinPostponing() public view returns (uint256);
    function getBylawsMilestoneMaxPostponing() public view returns (uint256);
    function getHash(uint8 actionType, bytes32 arg1, bytes32 arg2) public pure returns ( bytes32 );
    function process() public;
    function hasRequiredStateChanges() public view returns (bool);
    function getRequiredStateChanges() public view returns (uint8);
    function addCodeUpgradeProposal(address _addr, bytes32 _sourceCodeUrl) external returns (uint256);
    function createMilestoneAcceptanceProposal() external returns (uint256);
    function createMilestonePostponingProposal(uint256 _duration) external returns (uint256);
    function getCurrentMilestonePostponingProposalDuration() public view returns (uint256);
    function getCurrentMilestoneProposalStatusForType(uint8 _actionType ) public view returns (uint8);
    function createEmergencyFundReleaseProposal() external returns (uint256);
    function createDelistingProposal(uint256 _projectId) external returns (uint256);
    function RegisterVote(uint256 _proposalId, bool _myVote) public;
    function hasPreviousVote(uint256 _proposalId, address _voter) public view returns (bool);
    function getTotalTokenVotingPower(address _voter) public view returns ( uint256 );
    function getVotingPower(uint256 _proposalId, address _voter) public view returns ( uint256 );
    function setVoteCountPerProcess(uint256 _perProcess) external;
    function ProcessVoteTotals(uint256 _proposalId, uint256 length) public;
    function canEndVoting(uint256 _proposalId) public view returns (bool);
    function getProposalType(uint256 _proposalId) public view returns (uint8);
    function expiryChangesState(uint256 _proposalId) public view returns (bool);
    function needsProcessing(uint256 _proposalId) public view returns (bool);
    function getMyVoteForCurrentMilestoneRelease(address _voter) public view returns (bool);
    function getHasVoteForCurrentMilestoneRelease(address _voter) public view returns (bool);
    function getMyVote(uint256 _proposalId, address _voter) public view returns (bool);

}

 





contract ABIMilestones is ABIApplicationAsset {

    struct Record {
        bytes32 name;
        string description;                      
        uint8 state;
        uint256 duration;
        uint256 time_start;                      
        uint256 last_state_change_time;          
        uint256 time_end;                        
        uint256 time_ended;                      
        uint256 meeting_time;
        uint8 funding_percentage;
        uint8 index;
    }

    uint8 public currentRecord;
    uint256 public MilestoneCashBackTime = 0;
    mapping (uint8 => Record) public Collection;
    mapping (bytes32 => bool) public MilestonePostponingHash;
    mapping (bytes32 => uint256) public ProposalIdByHash;

    function getBylawsProjectDevelopmentStart() public view returns (uint256);
    function getBylawsMinTimeInTheFutureForMeetingCreation() public view returns (uint256);
    function getBylawsCashBackVoteRejectedDuration() public view returns (uint256);
    function addRecord( bytes32 _name, string _description, uint256 _duration, uint8 _perc ) public;
    function getMilestoneFundingPercentage(uint8 recordId) public view returns (uint8);
    function doStateChanges() public;
    function getRecordStateRequiredChanges() public view returns (uint8);
    function hasRequiredStateChanges() public view returns (bool);
    function afterVoteNoCashBackTime() public view returns ( bool );
    function getHash(uint8 actionType, bytes32 arg1, bytes32 arg2) public pure returns ( bytes32 );
    function getCurrentHash() public view returns ( bytes32 );
    function getCurrentProposalId() internal view returns ( uint256 );
    function setCurrentMilestoneMeetingTime(uint256 _meeting_time) public;
    function isRecordUpdateAllowed(uint8 _new_state ) public view returns (bool);
    function getRequiredStateChanges() public view returns (uint8, uint8, uint8);
    function ApplicationIsInDevelopment() public view returns(bool);
    function MeetingTimeSetFailure() public view returns (bool);

}

 





contract ABIFunding is ABIApplicationAsset {

    address public multiSigOutputAddress;
    address public DirectInput;
    address public MilestoneInput;
    address public TokenManagerEntity;
    address public FundingManagerEntity;

    struct FundingStage {
        bytes32 name;
        uint8   state;
        uint256 time_start;
        uint256 time_end;
        uint256 amount_cap_soft;             
        uint256 amount_cap_hard;             
        uint256 amount_raised;               
         
        uint256 minimum_entry;
        uint8   methods;                     
         
        uint256 fixed_tokens;
        uint8   price_addition_percentage;   
        uint8   token_share_percentage;
        uint8   index;
    }

    mapping (uint8 => FundingStage) public Collection;
    uint8 public FundingStageNum;
    uint8 public currentFundingStage;
    uint256 public AmountRaised;
    uint256 public MilestoneAmountRaised;
    uint256 public GlobalAmountCapSoft;
    uint256 public GlobalAmountCapHard;
    uint8 public TokenSellPercentage;
    uint256 public Funding_Setting_funding_time_start;
    uint256 public Funding_Setting_funding_time_end;
    uint256 public Funding_Setting_cashback_time_start;
    uint256 public Funding_Setting_cashback_time_end;
    uint256 public Funding_Setting_cashback_before_start_wait_duration;
    uint256 public Funding_Setting_cashback_duration;


    function addFundingStage(
        bytes32 _name,
        uint256 _time_start,
        uint256 _time_end,
        uint256 _amount_cap_soft,
        uint256 _amount_cap_hard,    
        uint8   _methods,
        uint256 _minimum_entry,
        uint256 _fixed_tokens,
        uint8   _price_addition_percentage,
        uint8   _token_share_percentage
    )
    public;

    function addSettings(address _outputAddress, uint256 soft_cap, uint256 hard_cap, uint8 sale_percentage, address _direct, address _milestone ) public;
    function getStageAmount(uint8 StageId) public view returns ( uint256 );
    function allowedPaymentMethod(uint8 _payment_method) public pure returns (bool);
    function receivePayment(address _sender, uint8 _payment_method) payable public returns(bool);
    function canAcceptPayment(uint256 _amount) public view returns (bool);
    function getValueOverCurrentCap(uint256 _amount) public view returns (uint256);
    function isFundingStageUpdateAllowed(uint8 _new_state ) public view returns (bool);
    function getRecordStateRequiredChanges() public view returns (uint8);
    function doStateChanges() public;
    function hasRequiredStateChanges() public view returns (bool);
    function getRequiredStateChanges() public view returns (uint8, uint8, uint8);

}

 



contract ABIToken {

    string public  symbol;
    string public  name;
    uint8 public   decimals;
    uint256 public totalSupply;
    string public  version;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) allowed;
    address public manager;
    address public deployer;
    bool public mintingFinished = false;
    bool public initialized = false;

    function transfer(address _to, uint256 _value) public returns (bool);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success);
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success);
    function mint(address _to, uint256 _amount) public returns (bool);
    function finishMinting() public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed value);
    event Approval(address indexed owner, address indexed spender, uint256 indexed value);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
}

 




contract ABITokenSCADAVariable {
    bool public SCADA_requires_hard_cap = true;
    bool public initialized;
    address public deployerAddress;
    function addSettings(address _fundingContract) public;
    function requiresHardCap() public view returns (bool);
    function getTokensForValueInCurrentStage(uint256 _value) public view returns (uint256);
    function getTokensForValueInStage(uint8 _stage, uint256 _value) public view returns (uint256);
    function getBoughtTokens( address _vaultAddress, bool _direct ) public view returns (uint256);
}

 





contract ABIFundingManager is ABIApplicationAsset {

    bool public fundingProcessed;
    bool FundingPoolBalancesAllocated;
    uint8 public VaultCountPerProcess;
    uint256 public lastProcessedVaultId;
    uint256 public vaultNum;
    uint256 public LockedVotingTokens;
    bytes32 public currentTask;
    mapping (bytes32 => bool) public taskByHash;
    mapping  (address => address) public vaultList;
    mapping  (uint256 => address) public vaultById;

    function receivePayment(address _sender, uint8 _payment_method, uint8 _funding_stage) payable public returns(bool);
    function getMyVaultAddress(address _sender) public view returns (address);
    function setVaultCountPerProcess(uint8 _perProcess) external;
    function getHash(bytes32 actionType, bytes32 arg1) public pure returns ( bytes32 );
    function getCurrentMilestoneProcessed() public view returns (bool);
    function processFundingFailedFinished() public view returns (bool);
    function processFundingSuccessfulFinished() public view returns (bool);
    function getCurrentMilestoneIdHash() internal view returns (bytes32);
    function processMilestoneFinished() public view returns (bool);
    function processEmergencyFundReleaseFinished() public view returns (bool);
    function getAfterTransferLockedTokenBalances(address vaultAddress, bool excludeCurrent) public view returns (uint256);
    function VaultRequestedUpdateForLockedVotingTokens(address owner) public;
    function doStateChanges() public;
    function hasRequiredStateChanges() public view returns (bool);
    function getRequiredStateChanges() public view returns (uint8, uint8);
    function ApplicationInFundingOrDevelopment() public view returns(bool);

}

 













contract FundingVault {

     
    bool public _initialized = false;

     
    address public vaultOwner ;
    address public outputAddress;
    address public managerAddress;

     

    bool public allFundingProcessed = false;
    bool public DirectFundingProcessed = false;

     
     
    ABIFunding FundingEntity;
    ABIFundingManager FundingManagerEntity;
    ABIMilestones MilestonesEntity;
    ABIProposals ProposalsEntity;
    ABITokenSCADAVariable TokenSCADAEntity;
    ABIToken TokenEntity ;

     
    uint256 public amount_direct = 0;
    uint256 public amount_milestone = 0;

     
    bool public emergencyFundReleased = false;
    uint8 emergencyFundPercentage = 0;
    uint256 BylawsCashBackOwnerMiaDuration;
    uint256 BylawsCashBackVoteRejectedDuration;
    uint256 BylawsProposalVotingDuration;

    struct PurchaseStruct {
        uint256 unix_time;
        uint8 payment_method;
        uint256 amount;
        uint8 funding_stage;
        uint16 index;
    }

    mapping(uint16 => PurchaseStruct) public purchaseRecords;
    uint16 public purchaseRecordsNum;

    event EventPaymentReceived(uint8 indexed _payment_method, uint256 indexed _amount, uint16 indexed _index );
    event VaultInitialized(address indexed _owner);

    function initialize(
        address _owner,
        address _output,
        address _fundingAddress,
        address _milestoneAddress,
        address _proposalsAddress
    )
        public
        requireNotInitialised
        returns(bool)
    {
        VaultInitialized(_owner);

        outputAddress = _output;
        vaultOwner = _owner;

         
        managerAddress = msg.sender;

         
        FundingEntity = ABIFunding(_fundingAddress);
        FundingManagerEntity = ABIFundingManager(managerAddress);
        MilestonesEntity = ABIMilestones(_milestoneAddress);
        ProposalsEntity = ABIProposals(_proposalsAddress);

        address TokenManagerAddress = FundingEntity.getApplicationAssetAddressByName("TokenManager");
        ABITokenManager TokenManagerEntity = ABITokenManager(TokenManagerAddress);

        address TokenAddress = TokenManagerEntity.TokenEntity();
        TokenEntity = ABIToken(TokenAddress);

        address TokenSCADAAddress = TokenManagerEntity.TokenSCADAEntity();
        TokenSCADAEntity = ABITokenSCADAVariable(TokenSCADAAddress);

         
        address ApplicationEntityAddress = TokenManagerEntity.owner();
        ApplicationEntityABI ApplicationEntity = ApplicationEntityABI(ApplicationEntityAddress);

         
        emergencyFundPercentage             = uint8( ApplicationEntity.getBylawUint256("emergency_fund_percentage") );
        BylawsCashBackOwnerMiaDuration      = ApplicationEntity.getBylawUint256("cashback_owner_mia_dur") ;
        BylawsCashBackVoteRejectedDuration  = ApplicationEntity.getBylawUint256("cashback_investor_no") ;
        BylawsProposalVotingDuration        = ApplicationEntity.getBylawUint256("proposal_voting_duration") ;

         
        _initialized = true;
        return true;
    }



     

    mapping (uint8 => uint256) public stageAmounts;
    mapping (uint8 => uint256) public stageAmountsDirect;

    function addPayment(
        uint8 _payment_method,
        uint8 _funding_stage
    )
        public
        payable
        requireInitialised
        onlyManager
        returns (bool)
    {
        if(msg.value > 0 && FundingEntity.allowedPaymentMethod(_payment_method)) {

             
            PurchaseStruct storage purchase = purchaseRecords[++purchaseRecordsNum];
                purchase.unix_time = now;
                purchase.payment_method = _payment_method;
                purchase.amount = msg.value;
                purchase.funding_stage = _funding_stage;
                purchase.index = purchaseRecordsNum;

             
            if(_payment_method == 1) {
                amount_direct+= purchase.amount;
                stageAmountsDirect[_funding_stage]+=purchase.amount;
            }

            if(_payment_method == 2) {
                amount_milestone+= purchase.amount;
            }

             
             
             
             
             
            stageAmounts[_funding_stage]+=purchase.amount;

            EventPaymentReceived( purchase.payment_method, purchase.amount, purchase.index );
            return true;
        } else {
            revert();
        }
    }

    function getBoughtTokens() public view returns (uint256) {
        return TokenSCADAEntity.getBoughtTokens( address(this), false );
    }

    function getDirectBoughtTokens() public view returns (uint256) {
        return TokenSCADAEntity.getBoughtTokens( address(this), true );
    }


    mapping (uint8 => uint256) public etherBalances;
    mapping (uint8 => uint256) public tokenBalances;
    uint8 public BalanceNum = 0;

    bool public BalancesInitialised = false;
    function initMilestoneTokenAndEtherBalances() internal
    {
        if(BalancesInitialised == false) {

            uint256 milestoneTokenBalance = TokenEntity.balanceOf(address(this));
            uint256 milestoneEtherBalance = this.balance;

             

             
            if(emergencyFundPercentage > 0) {
                tokenBalances[0] = milestoneTokenBalance / 100 * emergencyFundPercentage;
                etherBalances[0] = milestoneEtherBalance / 100 * emergencyFundPercentage;

                milestoneTokenBalance-=tokenBalances[0];
                milestoneEtherBalance-=etherBalances[0];
            }

             
            for(uint8 i = 1; i <= MilestonesEntity.RecordNum(); i++) {

                uint8 perc = MilestonesEntity.getMilestoneFundingPercentage(i);
                tokenBalances[i] = milestoneTokenBalance / 100 * perc;
                etherBalances[i] = milestoneEtherBalance / 100 * perc;
            }

            BalanceNum = i;
            BalancesInitialised = true;
        }
    }

    function ReleaseFundsAndTokens()
        public
        requireInitialised
        onlyManager
        returns (bool)
    {
         
        if(!canCashBack() && allFundingProcessed == false) {

            if(FundingManagerEntity.CurrentEntityState() == FundingManagerEntity.getEntityState("FUNDING_SUCCESSFUL_PROGRESS")) {

                 
                if(amount_direct > 0 && amount_milestone == 0) {

                     
                     

                     
                    TokenEntity.transfer(vaultOwner, TokenEntity.balanceOf( address(this) ) );

                     
                    outputAddress.transfer(this.balance);

                     
                    allFundingProcessed = true;

                } else {
                 

                    if(amount_direct > 0 && DirectFundingProcessed == false ) {
                        TokenEntity.transfer(vaultOwner, getDirectBoughtTokens() );
                         
                        outputAddress.transfer(amount_direct);
                        DirectFundingProcessed = true;
                    }

                     
                    initMilestoneTokenAndEtherBalances();
                }
                return true;

            } else if(FundingManagerEntity.CurrentEntityState() == FundingManagerEntity.getEntityState("MILESTONE_PROCESS_PROGRESS")) {

                 
                uint8 milestoneId = MilestonesEntity.currentRecord();

                uint256 transferTokens = tokenBalances[milestoneId];
                uint256 transferEther = etherBalances[milestoneId];

                if(milestoneId == BalanceNum - 1) {
                     
                     
                     
                    transferTokens = TokenEntity.balanceOf(address(this));
                    transferEther = this.balance;
                }

                 
                 
                 

                 
                TokenEntity.transfer(vaultOwner, transferTokens );

                 
                outputAddress.transfer(transferEther);

                if(milestoneId == BalanceNum - 1) {
                     
                    allFundingProcessed = true;
                }

                return true;
            }
        }

        return false;
    }


    function releaseTokensAndEtherForEmergencyFund()
        public
        requireInitialised
        onlyManager
        returns (bool)
    {
        if( emergencyFundReleased == false && emergencyFundPercentage > 0) {

             
            TokenEntity.transfer(vaultOwner, tokenBalances[0] );

             
            outputAddress.transfer(etherBalances[0]);

            emergencyFundReleased = true;
            return true;
        }
        return false;
    }

    function ReleaseFundsToInvestor()
        public
        requireInitialised
        isOwner
    {
        if(canCashBack()) {

             
             
             

             
            uint256 myBalance = TokenEntity.balanceOf(address(this));
             
            if(myBalance > 0) {
                TokenEntity.transfer(outputAddress, myBalance );
            }

             
            vaultOwner.transfer(this.balance);

             
            FundingManagerEntity.VaultRequestedUpdateForLockedVotingTokens( vaultOwner );

             
             
            allFundingProcessed = true;
        }
    }

     
    function canCashBack() public view requireInitialised returns (bool) {

         
        if(checkFundingStateFailed()) {
            return true;
        }
         
        if(checkMilestoneStateInvestorVotedNoVotingEndedNo()) {
            return true;
        }
         
        if(checkOwnerFailedToSetTimeOnMeeting()) {
            return true;
        }

        return false;
    }

    function checkFundingStateFailed() public view returns (bool) {
        if(FundingEntity.CurrentEntityState() == FundingEntity.getEntityState("FAILED_FINAL") ) {
            return true;
        }

         
        if( FundingEntity.getTimestamp() >= FundingEntity.Funding_Setting_cashback_time_start() ) {

             
            if( FundingEntity.CurrentEntityState() != FundingEntity.getEntityState("SUCCESSFUL_FINAL") ) {
                return true;
            }
        }

        return false;
    }

    function checkMilestoneStateInvestorVotedNoVotingEndedNo() public view returns (bool) {
        if(MilestonesEntity.CurrentEntityState() == MilestonesEntity.getEntityState("VOTING_ENDED_NO") ) {
             
            if( ProposalsEntity.getHasVoteForCurrentMilestoneRelease(vaultOwner) == true) {
                 
                if( ProposalsEntity.getMyVoteForCurrentMilestoneRelease( vaultOwner ) == false) {
                    return true;
                }
            }
        }
        return false;
    }

    function checkOwnerFailedToSetTimeOnMeeting() public view returns (bool) {
         
         
         

         
        if( MilestonesEntity.CurrentEntityState() == MilestonesEntity.getEntityState("DEADLINE_MEETING_TIME_FAILED") ) {
            return true;
        }
        return false;
    }


    modifier isOwner() {
        require(msg.sender == vaultOwner);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == managerAddress);
        _;
    }

    modifier requireInitialised() {
        require(_initialized == true);
        _;
    }

    modifier requireNotInitialised() {
        require(_initialized == false);
        _;
    }
}

 















contract FundingManager is ApplicationAsset {

    ABIFunding FundingEntity;
    ABITokenManager TokenManagerEntity;
    ABIToken TokenEntity;
    ABITokenSCADAVariable TokenSCADAEntity;
    ABIProposals ProposalsEntity;
    ABIMilestones MilestonesEntity;

    uint256 public LockedVotingTokens = 0;

    event EventFundingManagerReceivedPayment(address indexed _vault, uint8 indexed _payment_method, uint256 indexed _amount );
    event EventFundingManagerProcessedVault(address _vault, uint256 id );

    mapping  (address => address) public vaultList;
    mapping  (uint256 => address) public vaultById;
    uint256 public vaultNum = 0;

    function setAssetStates() internal {
         
        EntityStates["__IGNORED__"]                 = 0;
        EntityStates["NEW"]                         = 1;
        EntityStates["WAITING"]                     = 2;

        EntityStates["FUNDING_FAILED_START"]        = 10;
        EntityStates["FUNDING_FAILED_PROGRESS"]     = 11;
        EntityStates["FUNDING_FAILED_DONE"]         = 12;

        EntityStates["FUNDING_SUCCESSFUL_START"]    = 20;
        EntityStates["FUNDING_SUCCESSFUL_PROGRESS"] = 21;
        EntityStates["FUNDING_SUCCESSFUL_DONE"]     = 22;
        EntityStates["FUNDING_SUCCESSFUL_ALLOCATE"] = 25;


        EntityStates["MILESTONE_PROCESS_START"]     = 30;
        EntityStates["MILESTONE_PROCESS_PROGRESS"]  = 31;
        EntityStates["MILESTONE_PROCESS_DONE"]      = 32;

        EntityStates["EMERGENCY_PROCESS_START"]     = 40;
        EntityStates["EMERGENCY_PROCESS_PROGRESS"]  = 41;
        EntityStates["EMERGENCY_PROCESS_DONE"]      = 42;


        EntityStates["COMPLETE_PROCESS_START"]     = 100;
        EntityStates["COMPLETE_PROCESS_PROGRESS"]  = 101;
        EntityStates["COMPLETE_PROCESS_DONE"]      = 102;

         
        RecordStates["__IGNORED__"]     = 0;

    }

    function runBeforeApplyingSettings()
        internal
        requireInitialised
        requireSettingsNotApplied
    {
        address FundingAddress = getApplicationAssetAddressByName('Funding');
        FundingEntity = ABIFunding(FundingAddress);
        EventRunBeforeApplyingSettings(assetName);

        address TokenManagerAddress = getApplicationAssetAddressByName('TokenManager');
        TokenManagerEntity = ABITokenManager(TokenManagerAddress);

        TokenEntity = ABIToken(TokenManagerEntity.TokenEntity());

        address TokenSCADAAddress = TokenManagerEntity.TokenSCADAEntity();
        TokenSCADAEntity = ABITokenSCADAVariable(TokenSCADAAddress) ;

        address MilestonesAddress = getApplicationAssetAddressByName('Milestones');
        MilestonesEntity = ABIMilestones(MilestonesAddress) ;

        address ProposalsAddress = getApplicationAssetAddressByName('Proposals');
        ProposalsEntity = ABIProposals(ProposalsAddress) ;
    }



    function receivePayment(address _sender, uint8 _payment_method, uint8 _funding_stage)
        payable
        public
        requireInitialised
        onlyAsset('Funding')
        returns(bool)
    {
         
        if(msg.value > 0) {
            FundingVault vault;

             
            if(!hasVault(_sender)) {
                 
                vault = new FundingVault();
                if(vault.initialize(
                    _sender,
                    FundingEntity.multiSigOutputAddress(),
                    address(FundingEntity),
                    address(getApplicationAssetAddressByName('Milestones')),
                    address(getApplicationAssetAddressByName('Proposals'))
                )) {
                     
                    vaultList[_sender] = vault;
                     
                    vaultNum++;
                     
                    vaultById[vaultNum] = vault;

                } else {
                    revert();
                }
            } else {
                 
                vault = FundingVault(vaultList[_sender]);
            }

            EventFundingManagerReceivedPayment(vault, _payment_method, msg.value);

            if( vault.addPayment.value(msg.value)( _payment_method, _funding_stage ) ) {

                 
                TokenManagerEntity.mint( vault, TokenSCADAEntity.getTokensForValueInCurrentStage(msg.value) );

                return true;
            } else {
                revert();
            }
        } else {
            revert();
        }
    }

    function getMyVaultAddress(address _sender) public view returns (address) {
        return vaultList[_sender];
    }

    function hasVault(address _sender) internal view returns(bool) {
        if(vaultList[_sender] != address(0x0)) {
            return true;
        } else {
            return false;
        }
    }

    bool public fundingProcessed = false;
    uint256 public lastProcessedVaultId = 0;
    uint8 public VaultCountPerProcess = 10;
    bytes32 public currentTask = "";

    mapping (bytes32 => bool) public taskByHash;

    function setVaultCountPerProcess(uint8 _perProcess) external onlyDeployer {
        if(_perProcess > 0) {
            VaultCountPerProcess = _perProcess;
        } else {
            revert();
        }
    }

    function getHash(bytes32 actionType, bytes32 arg1) public pure returns ( bytes32 ) {
        return keccak256(actionType, arg1);
    }

    function getCurrentMilestoneProcessed() public view returns (bool) {
        return taskByHash[ getHash("MILESTONE_PROCESS_START", getCurrentMilestoneIdHash() ) ];
    }



    function ProcessVaultList(uint8 length) internal {

        if(taskByHash[currentTask] == false) {
            if(
                CurrentEntityState == getEntityState("FUNDING_FAILED_PROGRESS") ||
                CurrentEntityState == getEntityState("FUNDING_SUCCESSFUL_PROGRESS") ||
                CurrentEntityState == getEntityState("MILESTONE_PROCESS_PROGRESS") ||
                CurrentEntityState == getEntityState("EMERGENCY_PROCESS_PROGRESS") ||
                CurrentEntityState == getEntityState("COMPLETE_PROCESS_PROGRESS")
            ) {

                uint256 start = lastProcessedVaultId + 1;
                uint256 end = start + length - 1;

                if(end > vaultNum) {
                    end = vaultNum;
                }

                 
                if(start == 1) {
                     
                    LockedVotingTokens = 0;
                }

                for(uint256 i = start; i <= end; i++) {
                    address currentVault = vaultById[i];
                    EventFundingManagerProcessedVault(currentVault, i);
                    ProcessFundingVault(currentVault);
                    lastProcessedVaultId++;
                }
                if(lastProcessedVaultId >= vaultNum ) {
                     
                    lastProcessedVaultId = 0;
                    taskByHash[currentTask] = true;
                }
            } else {
                revert();
            }
        } else {
            revert();
        }
    }

    function processFundingFailedFinished() public view returns (bool) {
        bytes32 thisHash = getHash("FUNDING_FAILED_START", "");
        return taskByHash[thisHash];
    }

    function processFundingSuccessfulFinished() public view returns (bool) {
        bytes32 thisHash = getHash("FUNDING_SUCCESSFUL_START", "");
        return taskByHash[thisHash];
    }

    function getCurrentMilestoneIdHash() internal view returns (bytes32) {
        return bytes32(MilestonesEntity.currentRecord());
    }

    function processMilestoneFinished() public view returns (bool) {
        bytes32 thisHash = getHash("MILESTONE_PROCESS_START", getCurrentMilestoneIdHash());
        return taskByHash[thisHash];
    }

    function processEmergencyFundReleaseFinished() public view returns (bool) {
        bytes32 thisHash = getHash("EMERGENCY_PROCESS_START", bytes32(0));
        return taskByHash[thisHash];
    }

    function ProcessFundingVault(address vaultAddress ) internal {
        FundingVault vault = FundingVault(vaultAddress);

        if(vault.allFundingProcessed() == false) {

            if(CurrentEntityState == getEntityState("FUNDING_SUCCESSFUL_PROGRESS")) {

                 
                 
                 
                 
                if(!vault.ReleaseFundsAndTokens()) {
                    revert();
                }

            } else if(CurrentEntityState == getEntityState("MILESTONE_PROCESS_PROGRESS")) {
                 
                if(!vault.ReleaseFundsAndTokens()) {
                    revert();
                }

            } else if(CurrentEntityState == getEntityState("EMERGENCY_PROCESS_PROGRESS")) {
                 
                if(!vault.releaseTokensAndEtherForEmergencyFund()) {
                    revert();
                }
            }

             
            LockedVotingTokens+= getAfterTransferLockedTokenBalances(vaultAddress, true);

        }
    }

    function getAfterTransferLockedTokenBalances(address vaultAddress, bool excludeCurrent) public view returns (uint256) {
        FundingVault vault = FundingVault(vaultAddress);
        uint8 currentMilestone = MilestonesEntity.currentRecord();

        uint256 LockedBalance = 0;
         
        if(vault.emergencyFundReleased() == false) {
            LockedBalance+=vault.tokenBalances(0);
        }

         
        uint8 start = currentMilestone;

        if(CurrentEntityState != getEntityState("FUNDING_SUCCESSFUL_PROGRESS")) {
            if(excludeCurrent == true) {
                start++;
            }
        }

        for(uint8 i = start; i < vault.BalanceNum() ; i++) {
            LockedBalance+=vault.tokenBalances(i);
        }
        return LockedBalance;

    }

    function VaultRequestedUpdateForLockedVotingTokens(address owner) public {
         
        address vaultAddress = vaultList[owner];
        if(msg.sender == vaultAddress){
             
            LockedVotingTokens-= getAfterTransferLockedTokenBalances(vaultAddress, false);
        }
    }

    bool FundingPoolBalancesAllocated = false;

    function AllocateAfterFundingBalances() internal {
         
        if(FundingPoolBalancesAllocated == false) {

             
            uint256 mintedSupply = TokenEntity.totalSupply();
            uint256 salePercent = getAppBylawUint256("token_sale_percentage");

             
            uint256 onePercent = (mintedSupply * 1 / salePercent * 100) / 100;

             
            uint256 bountyPercent = getAppBylawUint256("token_bounty_percentage");
            uint256 bountyValue = onePercent * bountyPercent;

            address BountyManagerAddress = getApplicationAssetAddressByName("BountyManager");
            TokenManagerEntity.mint( BountyManagerAddress, bountyValue );

             
             
            uint256 projectPercent = 100 - salePercent - bountyPercent;
            uint256 projectValue = onePercent * projectPercent;

             
            TokenManagerEntity.mint( TokenManagerEntity, projectValue );
            TokenManagerEntity.finishMinting();

            FundingPoolBalancesAllocated = true;
        }
    }


    function doStateChanges() public {

        var (returnedCurrentEntityState, EntityStateRequired) = getRequiredStateChanges();
        bool callAgain = false;

        DebugEntityRequiredChanges( assetName, returnedCurrentEntityState, EntityStateRequired );

        if(EntityStateRequired != getEntityState("__IGNORED__") ) {
            EntityProcessor(EntityStateRequired);
            callAgain = true;
        }
    }

    function hasRequiredStateChanges() public view returns (bool) {
        bool hasChanges = false;
        var (returnedCurrentEntityState, EntityStateRequired) = getRequiredStateChanges();
         
        returnedCurrentEntityState = 0;
        if(EntityStateRequired != getEntityState("__IGNORED__") ) {
            hasChanges = true;
        }
        return hasChanges;
    }

    function EntityProcessor(uint8 EntityStateRequired) internal {

        EventEntityProcessor( assetName, CurrentEntityState, EntityStateRequired );

         
        CurrentEntityState = EntityStateRequired;
         

 
        if ( EntityStateRequired == getEntityState("FUNDING_FAILED_START") ) {
             
            currentTask = getHash("FUNDING_FAILED_START", "");
            CurrentEntityState = getEntityState("FUNDING_FAILED_PROGRESS");
        } else if ( EntityStateRequired == getEntityState("FUNDING_FAILED_PROGRESS") ) {
            ProcessVaultList(VaultCountPerProcess);

 
        } else if ( EntityStateRequired == getEntityState("FUNDING_SUCCESSFUL_START") ) {

             
             

             
            currentTask = getHash("FUNDING_SUCCESSFUL_START", "");
            CurrentEntityState = getEntityState("FUNDING_SUCCESSFUL_PROGRESS");

        } else if ( EntityStateRequired == getEntityState("FUNDING_SUCCESSFUL_PROGRESS") ) {
            ProcessVaultList(VaultCountPerProcess);

        } else if ( EntityStateRequired == getEntityState("FUNDING_SUCCESSFUL_ALLOCATE") ) {
            AllocateAfterFundingBalances();

 
        } else if ( EntityStateRequired == getEntityState("MILESTONE_PROCESS_START") ) {
            currentTask = getHash("MILESTONE_PROCESS_START", getCurrentMilestoneIdHash() );
            CurrentEntityState = getEntityState("MILESTONE_PROCESS_PROGRESS");

        } else if ( EntityStateRequired == getEntityState("MILESTONE_PROCESS_PROGRESS") ) {
            ProcessVaultList(VaultCountPerProcess);

 
        } else if ( EntityStateRequired == getEntityState("EMERGENCY_PROCESS_START") ) {
            currentTask = getHash("EMERGENCY_PROCESS_START", bytes32(0) );
            CurrentEntityState = getEntityState("EMERGENCY_PROCESS_PROGRESS");
        } else if ( EntityStateRequired == getEntityState("EMERGENCY_PROCESS_PROGRESS") ) {
            ProcessVaultList(VaultCountPerProcess);

 
        } else if ( EntityStateRequired == getEntityState("COMPLETE_PROCESS_START") ) {
            currentTask = getHash("COMPLETE_PROCESS_START", "");
            CurrentEntityState = getEntityState("COMPLETE_PROCESS_PROGRESS");

        } else if ( EntityStateRequired == getEntityState("COMPLETE_PROCESS_PROGRESS") ) {
             
            TokenManagerEntity.ReleaseOwnersLockedTokens( FundingEntity.multiSigOutputAddress() );
            CurrentEntityState = getEntityState("COMPLETE_PROCESS_DONE");
        }

    }

     
    function getRequiredStateChanges() public view returns (uint8, uint8) {

        uint8 EntityStateRequired = getEntityState("__IGNORED__");

        if(ApplicationInFundingOrDevelopment()) {

            if ( CurrentEntityState == getEntityState("WAITING") ) {
                 

                 
                if(FundingEntity.CurrentEntityState() == FundingEntity.getEntityState("FAILED")) {
                    EntityStateRequired = getEntityState("FUNDING_FAILED_START");
                }
                else if(FundingEntity.CurrentEntityState() == FundingEntity.getEntityState("SUCCESSFUL")) {
                     
                    if(taskByHash[ getHash("FUNDING_SUCCESSFUL_START", "") ] == false) {
                        EntityStateRequired = getEntityState("FUNDING_SUCCESSFUL_START");
                    }
                }
                else if(FundingEntity.CurrentEntityState() == FundingEntity.getEntityState("SUCCESSFUL_FINAL")) {

                    if ( processMilestoneFinished() == false) {
                        if(
                            MilestonesEntity.CurrentEntityState() == MilestonesEntity.getEntityState("VOTING_ENDED_YES") ||
                            MilestonesEntity.CurrentEntityState() == MilestonesEntity.getEntityState("VOTING_ENDED_NO_FINAL")
                        ) {
                            EntityStateRequired = getEntityState("MILESTONE_PROCESS_START");
                        }
                    }

                    if(processEmergencyFundReleaseFinished() == false) {
                        if(ProposalsEntity.EmergencyFundingReleaseApproved() == true) {
                            EntityStateRequired = getEntityState("EMERGENCY_PROCESS_START");
                        }
                    }

                     
                     


                }

            } else if ( CurrentEntityState == getEntityState("FUNDING_SUCCESSFUL_PROGRESS") ) {
                 
                if ( processFundingSuccessfulFinished() ) {
                    EntityStateRequired = getEntityState("FUNDING_SUCCESSFUL_ALLOCATE");
                } else {
                    EntityStateRequired = getEntityState("FUNDING_SUCCESSFUL_PROGRESS");
                }

            } else if ( CurrentEntityState == getEntityState("FUNDING_SUCCESSFUL_ALLOCATE") ) {

                if(FundingPoolBalancesAllocated) {
                    EntityStateRequired = getEntityState("FUNDING_SUCCESSFUL_DONE");
                }

            } else if ( CurrentEntityState == getEntityState("FUNDING_SUCCESSFUL_DONE") ) {
                EntityStateRequired = getEntityState("WAITING");

     
            } else if ( CurrentEntityState == getEntityState("FUNDING_FAILED_PROGRESS") ) {
                 
                if ( processFundingFailedFinished() ) {
                    EntityStateRequired = getEntityState("FUNDING_FAILED_DONE");
                } else {
                    EntityStateRequired = getEntityState("FUNDING_FAILED_PROGRESS");
                }

     
            } else if ( CurrentEntityState == getEntityState("MILESTONE_PROCESS_PROGRESS") ) {
                 

                if ( processMilestoneFinished() ) {
                    EntityStateRequired = getEntityState("MILESTONE_PROCESS_DONE");
                } else {
                    EntityStateRequired = getEntityState("MILESTONE_PROCESS_PROGRESS");
                }

            } else if ( CurrentEntityState == getEntityState("MILESTONE_PROCESS_DONE") ) {

                if(processMilestoneFinished() == false) {
                    EntityStateRequired = getEntityState("WAITING");

                } else if(MilestonesEntity.currentRecord() == MilestonesEntity.RecordNum()) {
                    EntityStateRequired = getEntityState("COMPLETE_PROCESS_START");
                }

     
            } else if ( CurrentEntityState == getEntityState("EMERGENCY_PROCESS_PROGRESS") ) {
                 

                if ( processEmergencyFundReleaseFinished() ) {
                    EntityStateRequired = getEntityState("EMERGENCY_PROCESS_DONE");
                } else {
                    EntityStateRequired = getEntityState("EMERGENCY_PROCESS_PROGRESS");
                }
            } else if ( CurrentEntityState == getEntityState("EMERGENCY_PROCESS_DONE") ) {
                EntityStateRequired = getEntityState("WAITING");

     
            } else if ( CurrentEntityState == getEntityState("COMPLETE_PROCESS_PROGRESS") ) {
                EntityStateRequired = getEntityState("COMPLETE_PROCESS_PROGRESS");
            }
        } else {

            if( CurrentEntityState == getEntityState("NEW") ) {
                 
                EntityStateRequired = getEntityState("WAITING");
            }
        }

        return (CurrentEntityState, EntityStateRequired);
    }

    function ApplicationInFundingOrDevelopment() public view returns(bool) {
        uint8 AppState = getApplicationState();
        if(
            AppState == getApplicationEntityState("IN_FUNDING") ||
            AppState == getApplicationEntityState("IN_DEVELOPMENT")
        ) {
            return true;
        }
        return false;
    }



}