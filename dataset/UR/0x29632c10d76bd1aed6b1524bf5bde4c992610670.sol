 

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

 





contract ABIGatewayInterface {
    address public currentApplicationEntityAddress;
    ApplicationEntityABI private currentApp;
    address public deployerAddress;

    function getApplicationAddress() external view returns (address);
    function requestCodeUpgrade( address _newAddress, bytes32 _sourceCodeUrl ) external returns (bool);
    function approveCodeUpgrade( address _newAddress ) external returns (bool);
    function link( address _newAddress ) internal returns (bool);
    function getNewsContractAddress() external view returns (address);
    function getListingContractAddress() external view returns (address);
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

 





contract ABIMeetings is ABIApplicationAsset {
    struct Record {
        bytes32 hash;
        bytes32 name;
        uint8 state;
        uint256 time_start;                      
        uint256 duration;
        uint8 index;
    }
    mapping (uint8 => Record) public Collection;
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

 





contract ABIBountyManager is ABIApplicationAsset {
    function sendBounty( address _receiver, uint256 _amount ) public;
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

 





contract ABIListingContract is ABIApplicationAsset {

    address public managerAddress;
     
    struct item {
        bytes32 name;
        address itemAddress;
        bool    status;
        uint256 index;
    }

    mapping ( uint256 => item ) public items;
    uint256 public itemNum;

    function setManagerAddress(address _manager) public;
    function addItem(bytes32 _name, address _address) public;
    function getNewsContractAddress(uint256 _childId) external view returns (address);
    function canBeDelisted(uint256 _childId) public view returns (bool);
    function getChildStatus( uint256 _childId ) public view returns (bool);
    function delistChild( uint256 _childId ) public;

}

 





contract ABINewsContract is ABIApplicationAsset {

    struct item {
        string hash;
        uint8 itemType;
        uint256 length;
    }

    uint256 public itemNum = 0;
    mapping ( uint256 => item ) public items;

    function addInternalMessage(uint8 state) public;
    function addItem(string _hash, uint256 _length) public;
}

 














contract ApplicationEntity {

     
    bytes32 sourceCodeUrl;

     
    bool public _initialized = false;

     
    bool public _locked = false;

     
    uint8 public CurrentEntityState;

     
    mapping (bytes32 => uint8) public EntityStates;

     
    address public GatewayInterfaceAddress;

     
    ABIGatewayInterface GatewayInterfaceEntity;

     
    ABIProposals public ProposalsEntity;
    ABIFunding public FundingEntity;
    ABIMilestones public MilestonesEntity;
    ABIMeetings public MeetingsEntity;
    ABIBountyManager public BountyManagerEntity;
    ABITokenManager public TokenManagerEntity;
    ABIListingContract public ListingContractEntity;
    ABIFundingManager public FundingManagerEntity;
    ABINewsContract public NewsContractEntity;

     
    mapping (bytes32 => address) public AssetCollection;
    mapping (uint8 => bytes32) public AssetCollectionIdToName;
    uint8 public AssetCollectionNum = 0;

    event EventAppEntityReady ( address indexed _address );
    event EventAppEntityCodeUpgradeProposal ( address indexed _address, bytes32 indexed _sourceCodeUrl );
    event EventAppEntityInitAsset ( bytes32 indexed _name, address indexed _address );
    event EventAppEntityInitAssetsToThis ( uint8 indexed _assetNum );
    event EventAppEntityAssetsToNewApplication ( address indexed _address );
    event EventAppEntityLocked ( address indexed _address );

    address public deployerAddress;

    function ApplicationEntity() public {
        deployerAddress = msg.sender;
        setEntityStates();
        CurrentEntityState = getEntityState("NEW");
    }

    function setEntityStates() internal {

         
        EntityStates["__IGNORED__"]                 = 0;
        EntityStates["NEW"]                         = 1;
        EntityStates["WAITING"]                     = 2;

        EntityStates["IN_FUNDING"]                  = 3;

        EntityStates["IN_DEVELOPMENT"]              = 5;
        EntityStates["IN_CODE_UPGRADE"]             = 50;

        EntityStates["UPGRADED"]                    = 100;

        EntityStates["IN_GLOBAL_CASHBACK"]          = 150;
        EntityStates["LOCKED"]                      = 200;

        EntityStates["DEVELOPMENT_COMPLETE"]        = 250;
    }

    function getEntityState(bytes32 name) public view returns (uint8) {
        return EntityStates[name];
    }

     
    function linkToGateway(
        address _GatewayInterfaceAddress,
        bytes32 _sourceCodeUrl
    )
        external
        requireNoParent
        requireNotInitialised
        onlyDeployer
    {
        GatewayInterfaceAddress = _GatewayInterfaceAddress;
        sourceCodeUrl = _sourceCodeUrl;

         
        GatewayInterfaceEntity = ABIGatewayInterface(GatewayInterfaceAddress);
        GatewayInterfaceEntity.requestCodeUpgrade( address(this), sourceCodeUrl );
    }

    function setUpgradeState(uint8 state) public onlyGatewayInterface {
        CurrentEntityState = state;
    }

     
    function addAssetProposals(address _assetAddresses) external requireNotInitialised onlyDeployer {
        ProposalsEntity = ABIProposals(_assetAddresses);
        assetInitialized("Proposals", _assetAddresses);
    }

    function addAssetFunding(address _assetAddresses) external requireNotInitialised onlyDeployer {
        FundingEntity = ABIFunding(_assetAddresses);
        assetInitialized("Funding", _assetAddresses);
    }

    function addAssetMilestones(address _assetAddresses) external requireNotInitialised onlyDeployer {
        MilestonesEntity = ABIMilestones(_assetAddresses);
        assetInitialized("Milestones", _assetAddresses);
    }

    function addAssetMeetings(address _assetAddresses) external requireNotInitialised onlyDeployer {
        MeetingsEntity = ABIMeetings(_assetAddresses);
        assetInitialized("Meetings", _assetAddresses);
    }

    function addAssetBountyManager(address _assetAddresses) external requireNotInitialised onlyDeployer {
        BountyManagerEntity = ABIBountyManager(_assetAddresses);
        assetInitialized("BountyManager", _assetAddresses);
    }

    function addAssetTokenManager(address _assetAddresses) external requireNotInitialised onlyDeployer {
        TokenManagerEntity = ABITokenManager(_assetAddresses);
        assetInitialized("TokenManager", _assetAddresses);
    }

    function addAssetFundingManager(address _assetAddresses) external requireNotInitialised onlyDeployer {
        FundingManagerEntity = ABIFundingManager(_assetAddresses);
        assetInitialized("FundingManager", _assetAddresses);
    }

    function addAssetListingContract(address _assetAddresses) external requireNotInitialised onlyDeployer {
        ListingContractEntity = ABIListingContract(_assetAddresses);
        assetInitialized("ListingContract", _assetAddresses);
    }

    function addAssetNewsContract(address _assetAddresses) external requireNotInitialised onlyDeployer {
        NewsContractEntity = ABINewsContract(_assetAddresses);
        assetInitialized("NewsContract", _assetAddresses);
    }

    function assetInitialized(bytes32 name, address _assetAddresses) internal {
        if(AssetCollection[name] == 0x0) {
            AssetCollectionIdToName[AssetCollectionNum] = name;
            AssetCollection[name] = _assetAddresses;
            AssetCollectionNum++;
        } else {
             
            AssetCollection[name] = _assetAddresses;
        }
        EventAppEntityInitAsset(name, _assetAddresses);
    }

    function getAssetAddressByName(bytes32 _name) public view returns (address) {
        return AssetCollection[_name];
    }

     
    mapping (bytes32 => uint256) public BylawsUint256;
    mapping (bytes32 => bytes32) public BylawsBytes32;


    function setBylawUint256(bytes32 name, uint256 value) public requireNotInitialised onlyDeployer {
        BylawsUint256[name] = value;
    }

    function getBylawUint256(bytes32 name) public view requireInitialised returns (uint256) {
        return BylawsUint256[name];
    }

    function setBylawBytes32(bytes32 name, bytes32 value) public requireNotInitialised onlyDeployer {
        BylawsBytes32[name] = value;
    }

    function getBylawBytes32(bytes32 name) public view requireInitialised returns (bytes32) {
        return BylawsBytes32[name];
    }

    function initialize() external requireNotInitialised onlyGatewayInterface returns (bool) {
        _initialized = true;
        EventAppEntityReady( address(this) );
        return true;
    }

    function getParentAddress() external view returns(address) {
        return GatewayInterfaceAddress;
    }

    function createCodeUpgradeProposal(
        address _newAddress,
        bytes32 _sourceCodeUrl
    )
        external
        requireInitialised
        onlyGatewayInterface
        returns (uint256)
    {
         
        EventAppEntityCodeUpgradeProposal ( _newAddress, _sourceCodeUrl );

         
        return ProposalsEntity.addCodeUpgradeProposal(_newAddress, _sourceCodeUrl);
    }

     
    function acceptCodeUpgradeProposal(address _newAddress) external onlyProposalsAsset  {
        GatewayInterfaceEntity.approveCodeUpgrade( _newAddress );
    }

    function initializeAssetsToThisApplication() external onlyGatewayInterface returns (bool) {

        for(uint8 i = 0; i < AssetCollectionNum; i++ ) {
            bytes32 _name = AssetCollectionIdToName[i];
            address current = AssetCollection[_name];
            if(current != address(0x0)) {
                if(!current.call(bytes4(keccak256("setInitialOwnerAndName(bytes32)")), _name) ) {
                    revert();
                }
            } else {
                revert();
            }
        }
        EventAppEntityInitAssetsToThis( AssetCollectionNum );

        return true;
    }

    function transferAssetsToNewApplication(address _newAddress) external onlyGatewayInterface returns (bool){
        for(uint8 i = 0; i < AssetCollectionNum; i++ ) {
            
            bytes32 _name = AssetCollectionIdToName[i];
            address current = AssetCollection[_name];
            if(current != address(0x0)) {
                if(!current.call(bytes4(keccak256("transferToNewOwner(address)")), _newAddress) ) {
                    revert();
                }
            } else {
                revert();
            }
        }
        EventAppEntityAssetsToNewApplication ( _newAddress );
        return true;
    }

     
    function lock() external onlyGatewayInterface returns (bool) {
        _locked = true;
        CurrentEntityState = getEntityState("UPGRADED");
        EventAppEntityLocked(address(this));
        return true;
    }

     
    address testAddressAllowUpgradeFrom;
    function canInitiateCodeUpgrade(address _sender) public view returns(bool) {
         
        if(testAddressAllowUpgradeFrom != 0x0 && testAddressAllowUpgradeFrom == _sender) {
            return true;
        }
        return false;
    }

     
    modifier onlyGatewayInterface() {
        require(GatewayInterfaceAddress != address(0) && msg.sender == GatewayInterfaceAddress);
        _;
    }

     
    modifier onlyProposalsAsset() {
        require(msg.sender == address(ProposalsEntity));
        _;
    }

    modifier requireNoParent() {
        require(GatewayInterfaceAddress == address(0x0));
        _;
    }

    modifier requireNotInitialised() {
        require(_initialized == false && _locked == false);
        _;
    }

    modifier requireInitialised() {
        require(_initialized == true && _locked == false);
        _;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployerAddress);
        _;
    }

    event DebugApplicationRequiredChanges( uint8 indexed _current, uint8 indexed _required );
    event EventApplicationEntityProcessor(uint8 indexed _current, uint8 indexed _required);

     

    function doStateChanges() public {

        if(!_locked) {
             
            AssetProcessor();

            var (returnedCurrentEntityState, EntityStateRequired) = getRequiredStateChanges();
            bool callAgain = false;

            DebugApplicationRequiredChanges( returnedCurrentEntityState, EntityStateRequired );

            if(EntityStateRequired != getEntityState("__IGNORED__") ) {
                EntityProcessor(EntityStateRequired);
                callAgain = true;
            }
        } else {
            revert();
        }
    }

    function hasRequiredStateChanges() public view returns (bool) {
        bool hasChanges = false;
        if(!_locked) {
            var (returnedCurrentEntityState, EntityStateRequired) = getRequiredStateChanges();
             
            returnedCurrentEntityState = 0;
            if(EntityStateRequired != getEntityState("__IGNORED__") ) {
                hasChanges = true;
            }

            if(anyAssetHasChanges()) {
                hasChanges = true;
            }
        }
        return hasChanges;
    }

    function anyAssetHasChanges() public view returns (bool) {
        if( FundingEntity.hasRequiredStateChanges() ) {
            return true;
        }
        if( FundingManagerEntity.hasRequiredStateChanges() ) {
            return true;
        }
        if( MilestonesEntity.hasRequiredStateChanges() ) {
            return true;
        }
        if( ProposalsEntity.hasRequiredStateChanges() ) {
            return true;
        }

        return extendedAnyAssetHasChanges();
    }

     
    function extendedAnyAssetHasChanges() internal view returns (bool) {
        if(_initialized) {}
        return false;
    }

     
    function extendedAssetProcessor() internal  {
         
        if ( CurrentEntityState == 255 ) {
            ProposalsEntity.process();
        }
    }

     
     

    function AssetProcessor() internal {


        if ( CurrentEntityState == getEntityState("NEW") ) {

             
            if(FundingEntity.hasRequiredStateChanges()) {
                FundingEntity.doStateChanges();
            }

            if(FundingManagerEntity.hasRequiredStateChanges()) {
                FundingManagerEntity.doStateChanges();
            }

            if( MilestonesEntity.hasRequiredStateChanges() ) {
                MilestonesEntity.doStateChanges();
            }

        } else if ( CurrentEntityState == getEntityState("WAITING") ) {

            if( FundingEntity.hasRequiredStateChanges() ) {
                FundingEntity.doStateChanges();
            }
        }
        else if ( CurrentEntityState == getEntityState("IN_FUNDING") ) {

            if( FundingEntity.hasRequiredStateChanges() ) {
                FundingEntity.doStateChanges();
            }

            if( FundingManagerEntity.hasRequiredStateChanges() ) {
                FundingManagerEntity.doStateChanges();
            }
        }
        else if ( CurrentEntityState == getEntityState("IN_DEVELOPMENT") ) {

            if( FundingManagerEntity.hasRequiredStateChanges() ) {
                FundingManagerEntity.doStateChanges();
            }

            if(MilestonesEntity.hasRequiredStateChanges()) {
                MilestonesEntity.doStateChanges();
            }

            if(ProposalsEntity.hasRequiredStateChanges()) {
                ProposalsEntity.process();
            }
        }
        else if ( CurrentEntityState == getEntityState("DEVELOPMENT_COMPLETE") ) {

            if(ProposalsEntity.hasRequiredStateChanges()) {
                ProposalsEntity.process();
            }
        }

        extendedAssetProcessor();
    }

    function EntityProcessor(uint8 EntityStateRequired) internal {

        EventApplicationEntityProcessor( CurrentEntityState, EntityStateRequired );

         
        CurrentEntityState = EntityStateRequired;

         

        if ( EntityStateRequired == getEntityState("IN_FUNDING") ) {
             
             
        }

         


         
         
    }

     
    function getRequiredStateChanges() public view returns (uint8, uint8) {

        uint8 EntityStateRequired = getEntityState("__IGNORED__");

        if( CurrentEntityState == getEntityState("NEW") ) {
             
            EntityStateRequired = getEntityState("WAITING");

        } else if ( CurrentEntityState == getEntityState("WAITING") ) {

             
            if( FundingEntity.CurrentEntityState() == FundingEntity.getEntityState("IN_PROGRESS") ) {
                EntityStateRequired = getEntityState("IN_FUNDING");
            }

        } else if ( CurrentEntityState == getEntityState("IN_FUNDING") ) {

            if(FundingEntity.CurrentEntityState() == FundingEntity.getEntityState("SUCCESSFUL_FINAL")) {
                 
                EntityStateRequired = getEntityState("IN_DEVELOPMENT");

            } else if(FundingEntity.CurrentEntityState() == FundingEntity.getEntityState("FAILED_FINAL")) {
                 
                EntityStateRequired = getEntityState("IN_GLOBAL_CASHBACK");
            }

        } else if ( CurrentEntityState == getEntityState("IN_DEVELOPMENT") ) {

             
             
             
             

             

            if(MilestonesEntity.CurrentEntityState() == MilestonesEntity.getEntityState("DEVELOPMENT_COMPLETE")) {
                 
                EntityStateRequired = getEntityState("DEVELOPMENT_COMPLETE");
            }

            if(MilestonesEntity.CurrentEntityState() == MilestonesEntity.getEntityState("DEADLINE_MEETING_TIME_FAILED")) {
                EntityStateRequired = getEntityState("IN_GLOBAL_CASHBACK");
            }

        } else if ( CurrentEntityState == getEntityState("START_CODE_UPGRADE") ) {

             
             

        } else if ( CurrentEntityState == getEntityState("IN_CODE_UPGRADE") ) {

             
             

        } else if ( CurrentEntityState == getEntityState("FINISHED_CODE_UPGRADE") ) {

             
             
             

        }

        return (CurrentEntityState, EntityStateRequired);
    }

    function getTimestamp() view public returns (uint256) {
        return now;
    }

}