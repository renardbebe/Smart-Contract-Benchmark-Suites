 

pragma solidity >=0.5.6 <0.6.0;


 
 
interface ERC165Interface {
     
     
     
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


 
contract WizardConstants {
     
     
     
    uint8 internal constant ELEMENT_NOTSET = 0;  
     
     
    uint8 internal constant ELEMENT_NEUTRAL = 1;  
     
     
     
     
     
    uint8 internal constant ELEMENT_FIRE = 2;  
    uint8 internal constant ELEMENT_WATER = 3;  
    uint8 internal constant ELEMENT_WIND = 4;  
    uint8 internal constant MAX_ELEMENT = ELEMENT_WIND;
}




contract ERC1654 {

     
    bytes4 public constant ERC1654_VALIDSIGNATURE = 0x1626ba7e;

     
     
     
     
     
     
    function isValidSignature(
        bytes32 hash,
        bytes calldata _signature)
        external
        view
        returns (bytes4);
}








 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}


contract WizardGuildInterfaceId {
    bytes4 internal constant _INTERFACE_ID_WIZARDGUILD = 0x41d4d437;
}

 
 
 
 
 
contract WizardGuildInterface is IERC721, WizardGuildInterfaceId {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function getWizard(uint256 id) external view returns (address owner, uint88 innatePower, uint8 affinity, bytes32 metadata);

     
     
     
     
     
     
     
     
     
     
    function setAffinity(uint256 wizardId, uint8 newAffinity) external;

     
     
     
     
     
     
     
     
    function mintWizards(
        uint88[] calldata powers,
        uint8[] calldata affinities,
        address owner
        ) external returns (uint256[] memory wizardIds);

     
     
     
     
     
    function mintReservedWizards(
        uint256[] calldata wizardIds,
        uint88[] calldata powers,
        uint8[] calldata affinities,
        address owner
        ) external;

     
     
     
     
     
     
     
    function setMetadata(uint256[] calldata wizardIds, bytes32[] calldata metadata) external;

     
     
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function verifySignature(uint256 wizardId, bytes32 hash, bytes calldata sig) external view;

     
     
     
     
     
     
     
     
     
    function verifySignatures(
        uint256 wizardId1,
        uint256 wizardId2,
        bytes32 hash1,
        bytes32 hash2,
        bytes calldata sig1,
        bytes calldata sig2) external view;
}





 
 
contract DuelResolverInterfaceId {
     
    bytes4 internal constant _INTERFACE_ID_DUELRESOLVER = 0x41fc4f1e;
}

 
 
 
contract DuelResolverInterface is DuelResolverInterfaceId, ERC165Interface {
     
     
     
     
    function isValidMoveSet(bytes32 moveSet) public pure returns(bool);

     
     
     
     
     
     
     
     
    function isValidAffinity(uint256 affinity) external pure returns(bool);

     
     
     
     
     
     
     
     
     
     
     
     
    function resolveDuel(
        bytes32 moveSet1,
        bytes32 moveSet2,
        uint256 power1,
        uint256 power2,
        uint256 affinity1,
        uint256 affinity2)
        public pure returns(int256);
}





 
 
contract AccessControl {

     
     
     
     
    address public ceoAddress;

     
     
     
     
     
    address public cooAddress;

     
     
     
    address payable public cfoAddress;

     
    event CEOTransferred(address previousCeo, address newCeo);
    event COOTransferred(address previousCoo, address newCoo);
    event CFOTransferred(address previousCfo, address newCfo);

     
     
     
     
    constructor(address newCooAddress, address payable newCfoAddress) public {
        _setCeo(msg.sender);
        setCoo(newCooAddress);

        if (newCfoAddress != address(0)) {
            setCfo(newCfoAddress);
        }
    }

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress, "Only CEO");
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress, "Only COO");
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress, "Only CFO");
        _;
    }

    function checkControlAddress(address newController) internal view {
        require(newController != address(0) && newController != ceoAddress, "Invalid CEO address");
    }

     
     
    function setCeo(address newCeo) external onlyCEO {
        checkControlAddress(newCeo);
        _setCeo(newCeo);
    }

     
     
    function _setCeo(address newCeo) private {
        emit CEOTransferred(ceoAddress, newCeo);
        ceoAddress = newCeo;
    }

     
     
    function setCoo(address newCoo) public onlyCEO {
        checkControlAddress(newCoo);
        emit COOTransferred(cooAddress, newCoo);
        cooAddress = newCoo;
    }

     
     
    function setCfo(address payable newCfo) public onlyCEO {
        checkControlAddress(newCfo);
        emit CFOTransferred(cfoAddress, newCfo);
        cfoAddress = newCfo;
    }
}



 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract TournamentTimeAbstract is AccessControl {

    event Paused(uint256 pauseEndedBlock);

     
    struct TournamentTimeParameters {
         
        uint48 tournamentStartBlock;

         
        uint48 pauseEndedBlock;

         
        uint32 admissionDuration;

         
        uint32 revivalDuration;

         
         
         
        uint32 duelTimeoutDuration;
    }

    TournamentTimeParameters internal tournamentTimeParameters;

     
    function getTimeParameters() external view returns (
        uint256 tournamentStartBlock,
        uint256 pauseEndedBlock,
        uint256 admissionDuration,
        uint256 revivalDuration,
        uint256 duelTimeoutDuration,
        uint256 ascensionWindowStart,
        uint256 ascensionWindowDuration,
        uint256 fightWindowStart,
        uint256 fightWindowDuration,
        uint256 resolutionWindowStart,
        uint256 resolutionWindowDuration,
        uint256 cullingWindowStart,
        uint256 cullingWindowDuration) {
        return (
            uint256(tournamentTimeParameters.tournamentStartBlock),
            uint256(tournamentTimeParameters.pauseEndedBlock),
            uint256(tournamentTimeParameters.admissionDuration),
            uint256(tournamentTimeParameters.revivalDuration),
            uint256(tournamentTimeParameters.duelTimeoutDuration),
            uint256(ascensionWindowParameters.firstWindowStartBlock),
            uint256(ascensionWindowParameters.windowDuration),
            uint256(fightWindowParameters.firstWindowStartBlock),
            uint256(fightWindowParameters.windowDuration),
            uint256(resolutionWindowParameters.firstWindowStartBlock),
            uint256(resolutionWindowParameters.windowDuration),
            uint256(cullingWindowParameters.firstWindowStartBlock),
            uint256(cullingWindowParameters.windowDuration));
    }

     
     
     
     
     
     
     
     
     
     
     
     

     
    struct WindowParameters {
         
        uint48 firstWindowStartBlock;

         
        uint48 pauseEndedBlock;

         
         
        uint32 sessionDuration;

         
        uint32 windowDuration;
    }

    WindowParameters internal ascensionWindowParameters;
    WindowParameters internal fightWindowParameters;
    WindowParameters internal resolutionWindowParameters;
    WindowParameters internal cullingWindowParameters;


     
     
    struct BlueMoldParameters {
        uint48 blueMoldStartBlock;
        uint32 sessionDuration;
        uint32 moldDoublingDuration;
        uint88 blueMoldBasePower;
    }

    BlueMoldParameters internal blueMoldParameters;

    function getBlueMoldParameters() external view returns (uint256, uint256, uint256, uint256) {
        return (
            blueMoldParameters.blueMoldStartBlock,
            blueMoldParameters.sessionDuration,
            blueMoldParameters.moldDoublingDuration,
            blueMoldParameters.blueMoldBasePower
        );
    }

    constructor(
        address _cooAddress,
        uint40 tournamentStartBlock,
        uint32 admissionDuration,
        uint32 revivalDuration,
        uint24 ascensionDuration,
        uint24 fightDuration,
        uint24 cullingDuration,
        uint24 duelTimeoutDuration,
        uint88 blueMoldBasePower,
        uint24 sessionsBetweenMoldDoubling
    )
    internal AccessControl(_cooAddress, address(0)) {
        require(tournamentStartBlock > block.number, "Invalid start time");

         
         
        require(duelTimeoutDuration >= 20, "Timeout too short");

         
         
         
         
         
         
         
         
        require(
            (uint256(admissionDuration) *
            uint256(revivalDuration) *
            uint256(ascensionDuration) *
            uint256(fightDuration) *
            uint256(cullingDuration) *
            uint256(blueMoldBasePower) *
            uint256(sessionsBetweenMoldDoubling)) != 0,
            "Constructor arguments must be non-0");

         
         
        require(fightDuration >= uint256(duelTimeoutDuration) * 2, "Fight window too short");

         
        require(cullingDuration >= duelTimeoutDuration, "Culling window too short");
         
        uint32 sessionDuration = ascensionDuration + fightDuration + duelTimeoutDuration + cullingDuration;

         
         
        require((revivalDuration % sessionDuration) == 0, "Revival/Session length mismatch");

        tournamentTimeParameters = TournamentTimeParameters({
            tournamentStartBlock: uint48(tournamentStartBlock),
            pauseEndedBlock: uint48(0),
            admissionDuration: admissionDuration,
            revivalDuration: revivalDuration,
            duelTimeoutDuration: duelTimeoutDuration
        });

         
         
         
        uint256 firstSessionStartBlock = uint256(tournamentStartBlock) + uint256(admissionDuration);

         
        ascensionWindowParameters = WindowParameters({
            firstWindowStartBlock: uint48(firstSessionStartBlock + revivalDuration),
            pauseEndedBlock: uint48(0),
            sessionDuration: sessionDuration,
            windowDuration: ascensionDuration
        });

        fightWindowParameters = WindowParameters({
            firstWindowStartBlock: uint48(firstSessionStartBlock + ascensionDuration),
            pauseEndedBlock: uint48(0),
            sessionDuration: sessionDuration,
            windowDuration: fightDuration
        });

        resolutionWindowParameters = WindowParameters({
            firstWindowStartBlock: uint48(firstSessionStartBlock + ascensionDuration + fightDuration),
            pauseEndedBlock: uint48(0),
            sessionDuration: sessionDuration,
            windowDuration: duelTimeoutDuration
        });

        cullingWindowParameters = WindowParameters({
             
            firstWindowStartBlock: uint48(firstSessionStartBlock + revivalDuration + ascensionDuration + fightDuration + duelTimeoutDuration),
            pauseEndedBlock: uint48(0),
            sessionDuration: sessionDuration,
            windowDuration: cullingDuration
        });

        blueMoldParameters = BlueMoldParameters({
            blueMoldStartBlock: uint48(firstSessionStartBlock + revivalDuration),
            sessionDuration: sessionDuration,
             
            moldDoublingDuration: uint32(sessionsBetweenMoldDoubling) * uint32(sessionDuration),
            blueMoldBasePower: blueMoldBasePower
        });
    }

     
    function _isRevivalPhase() internal view returns (bool) {
         
         
        TournamentTimeParameters memory localParams = tournamentTimeParameters;

        if (block.number < localParams.pauseEndedBlock) {
            return false;
        }

        return ((block.number >= localParams.tournamentStartBlock + localParams.admissionDuration) &&
            (block.number < localParams.tournamentStartBlock + localParams.admissionDuration + localParams.revivalDuration));
    }

     
    function _isEliminationPhase() internal view returns (bool) {
         
         
        TournamentTimeParameters memory localParams = tournamentTimeParameters;

        if (block.number < localParams.pauseEndedBlock) {
            return false;
        }

        return (block.number >= localParams.tournamentStartBlock + localParams.admissionDuration + localParams.revivalDuration);
    }

     
     
    function _isEnterPhase() internal view returns (bool) {
         
         
        TournamentTimeParameters memory localParams = tournamentTimeParameters;

        if (block.number < localParams.pauseEndedBlock) {
            return false;
        }

        return ((block.number >= localParams.tournamentStartBlock) &&
            (block.number < localParams.tournamentStartBlock + localParams.admissionDuration + localParams.revivalDuration));
    }

     
     
    function _isInWindow(WindowParameters memory localParams) internal view returns (bool) {
         
        if (block.number < localParams.pauseEndedBlock) {
            return false;
        }

         
        if (block.number < localParams.firstWindowStartBlock) {
            return false;
        }

         
         
        uint256 windowOffset = (block.number - localParams.firstWindowStartBlock) % localParams.sessionDuration;

         
        return windowOffset < localParams.windowDuration;
    }

     
    function checkAscensionWindow() internal view {
        require(_isInWindow(ascensionWindowParameters), "Only during Ascension Window");
    }

     
    function checkFightWindow() internal view {
        require(_isInWindow(fightWindowParameters), "Only during Fight Window");
    }

     
    function checkResolutionWindow() internal view {
        require(_isInWindow(resolutionWindowParameters), "Only during Resolution Window");
    }

     
    function checkCullingWindow() internal view {
        require(_isInWindow(cullingWindowParameters), "Only during Culling Window");
    }

     
     
     
     
     
     
    function _ascensionDuelTimeout() internal view returns (uint256) {
        WindowParameters memory localParams = cullingWindowParameters;

         
         

         
         
         
         
        uint256 sessionCount = (block.number + localParams.sessionDuration -
            localParams.firstWindowStartBlock) / localParams.sessionDuration;

        return localParams.firstWindowStartBlock + sessionCount * localParams.sessionDuration;
    }

     
     
     
     
     
     
     
     
    function canChallengeAscendingWizard() internal view returns (bool) {
         
         
        WindowParameters memory localParams = resolutionWindowParameters;

        uint256 sessionCount = (block.number + localParams.sessionDuration -
            localParams.firstWindowStartBlock) / localParams.sessionDuration;

        uint256 resolutionWindowStart = localParams.firstWindowStartBlock + sessionCount * localParams.sessionDuration;

         
        return resolutionWindowStart - localParams.windowDuration > block.number;
    }

     
    function _blueMoldPower() internal view returns (uint256) {
        BlueMoldParameters memory localParams = blueMoldParameters;

        if (block.number <= localParams.blueMoldStartBlock) {
            return localParams.blueMoldBasePower;
        } else {
            uint256 moldDoublings = (block.number - localParams.blueMoldStartBlock) / localParams.moldDoublingDuration;

             
             
             
             
             
             
            if (moldDoublings > 88) {
                moldDoublings = 88;
            }

            return localParams.blueMoldBasePower << moldDoublings;
        }
    }


    modifier duringEnterPhase() {
        require(_isEnterPhase(), "Only during Enter Phases");
        _;
    }

    modifier duringRevivalPhase() {
        require(_isRevivalPhase(), "Only during Revival Phases");
        _;
    }

    modifier duringAscensionWindow() {
        checkAscensionWindow();
        _;
    }

    modifier duringFightWindow() {
        checkFightWindow();
        _;
    }

    modifier duringResolutionWindow() {
        checkResolutionWindow();
        _;
    }

    modifier duringCullingWindow() {
        checkCullingWindow();
        _;
    }

     
     
     
     
     
     
     
     
     
     
    function pause(uint256 pauseDuration) external onlyCOO {
        uint256 sessionDuration = ascensionWindowParameters.sessionDuration;

         
        require(pauseDuration <= sessionDuration, "Invalid pause duration");

         
        uint48 newPauseEndedBlock = uint48(block.number + pauseDuration);
        uint48 tournamentExtensionAmount = uint48(pauseDuration);

        if (block.number < tournamentTimeParameters.pauseEndedBlock) {
             
             
             
            require(tournamentTimeParameters.pauseEndedBlock < newPauseEndedBlock, "Already paused");

            tournamentExtensionAmount = uint48(newPauseEndedBlock - tournamentTimeParameters.pauseEndedBlock);
        }

         
         
        tournamentTimeParameters.tournamentStartBlock += tournamentExtensionAmount;
        tournamentTimeParameters.pauseEndedBlock = newPauseEndedBlock;

        ascensionWindowParameters.firstWindowStartBlock += tournamentExtensionAmount;
        ascensionWindowParameters.pauseEndedBlock = newPauseEndedBlock;

        fightWindowParameters.firstWindowStartBlock += tournamentExtensionAmount;
        fightWindowParameters.pauseEndedBlock = newPauseEndedBlock;

        resolutionWindowParameters.firstWindowStartBlock += tournamentExtensionAmount;
        resolutionWindowParameters.pauseEndedBlock = newPauseEndedBlock;

        cullingWindowParameters.firstWindowStartBlock += tournamentExtensionAmount;
        cullingWindowParameters.pauseEndedBlock = newPauseEndedBlock;

        blueMoldParameters.blueMoldStartBlock += tournamentExtensionAmount;

        emit Paused(newPauseEndedBlock);
    }

    function isPaused() external view returns (bool) {
        return block.number < tournamentTimeParameters.pauseEndedBlock;
    }
}





 
contract TournamentInterfaceId {
    bytes4 internal constant _INTERFACE_ID_TOURNAMENT = 0xbd059098;
}

 
contract TournamentInterface is TournamentInterfaceId, ERC165Interface {

     
    function revive(uint256 wizardId) external payable;

    function enterWizards(uint256[] calldata wizardIds, uint88[] calldata powers) external payable;

     
    function isActive() external view returns (bool);

    function powerScale() external view returns (uint256);

    function destroy() external;
}



 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract BasicTournament is TournamentInterface, TournamentTimeAbstract, WizardConstants,
    DuelResolverInterfaceId {

     
    event DuelStart(
        bytes32 duelId,
        uint256 wizardId1,
        uint256 wizardId2,
        uint256 timeoutBlock,
        bool isAscensionBattle,
        bytes32 commit1,
        bytes32 commit2
    );

     
    event DuelEnd(
        bytes32 duelId,
        uint256 wizardId1,
        uint256 wizardId2,
        bytes32 moveSet1,
        bytes32 moveSet2,
        uint256 power1,
        uint256 power2
    );

     
    event OneSidedCommitAdded(
        uint256 committingWizardId,
        uint256 otherWizardId,
        uint256 committingWizardNonce,
        uint256 otherWizardNonce,
        bytes32 commitment
    );

     
    event OneSidedCommitCancelled(
        uint256 wizardId
    );

     
    event OneSidedRevealAdded(
        bytes32 duelId,
        uint256 committingWizardId,
        uint256 otherWizardId
    );

     
    event DuelTimeOut(bytes32 duelId, uint256 wizardId1, uint256 wizardId2, uint256 power1, uint256 power2);

     
     
    event WizardElimination(uint256 wizardId);

     
    event AscensionStart(uint256 wizardId);

     
    event AscensionPairUp(uint256 wizardId1, uint256 wizardId2);

     
    event AscensionComplete(uint256 wizardId, uint256 power);

     
    event AscensionChallenged(uint256 ascendingWizardId, uint256 challengingWizardId, bytes32 commitment);

     
    event Revive(uint256 wizId, uint256 power);

    uint8 internal constant REASON_COMPLETE_ASCENSION = 1;
    uint8 internal constant REASON_RESOLVE_ONE_SIDED_ASCENSION_BATTLE = 2;
    uint8 internal constant REASON_GIFT_POWER = 3;
     
     
     
     
     
     
     
     
     
     
    event PowerTransferred(uint256 sendingWizId, uint256 receivingWizId, uint256 amountTransferred, uint8 reason);

     
    event PrizeClaimed(uint256 claimingWinnerId, uint256 prizeAmount);

     
    byte internal constant EIP191_PREFIX = byte(0x19);
    byte internal constant EIP191_VERSION_DATA = byte(0);

     
     
     
     
     
     
     
     
    uint256 public powerScale;

     
    uint88 internal constant MAX_POWER = uint88(-1);

     
     
    address public constant GATE_KEEPER = address(0x673B537956a28e40aAA8D929Fd1B6688C1583dda);

     
     
     
    WizardGuildInterface public constant WIZARD_GUILD = WizardGuildInterface(address(0x35B7838dd7507aDA69610397A85310AE0abD5034));

     
    DuelResolverInterface public duelResolver;

     
     
    struct BattleWizard {
         
        uint88 power;

         
        uint88 maxPower;

         
        uint32 nonce;

         
        uint8 affinity;

         
         
        bytes32 currentDuel;
    }

    mapping(uint256 => BattleWizard) internal wizards;

     
     
     
    uint256 internal remainingWizards;

    function getRemainingWizards() external view returns(uint256) {
        return remainingWizards;
    }

     
     
     
     
    struct SingleCommitment {
        uint256 opponentId;
        bytes32 commitmentHash;
    }

     
    mapping(uint256 => SingleCommitment) internal pendingCommitments;

     
     
     
     
     
     
    mapping(bytes32 => mapping(uint256 => bytes32)) internal revealedMoves;

     
     
    uint256 internal ascendingWizardId;

    function getAscendingWizardId() external view returns (uint256) {
        return ascendingWizardId;
    }

     
     
     
     
    mapping(uint256 => uint256) internal ascensionOpponents;

     
     
     
     
     
     
     
     
     
    SingleCommitment internal ascensionCommitment;

    struct Duel {
        uint128 timeout;
        bool isAscensionBattle;
    }

     
    mapping(bytes32 => Duel) internal duels;

    constructor(
        address cooAddress_,
        address duelResolver_,
         
         
         
         
         
         
         
         
        uint256 powerScale_,
        uint40 tournamentStartBlock_,
        uint32 admissionDuration_,
        uint32 revivalDuration_,
        uint24 ascensionDuration_,
        uint24 fightDuration_,
        uint24 cullingDuration_,
        uint88 blueMoldBasePower_,
        uint24 sessionsBetweenMoldDoubling_,
        uint24 duelTimeoutBlocks_
    )
        public
        TournamentTimeAbstract(
            cooAddress_,
            tournamentStartBlock_,
            admissionDuration_,
            revivalDuration_,
            ascensionDuration_,
            fightDuration_,
            cullingDuration_,
            duelTimeoutBlocks_,
            blueMoldBasePower_,
            sessionsBetweenMoldDoubling_
        )
    {
        duelResolver = DuelResolverInterface(duelResolver_);
        require(
            duelResolver_ != address(0) &&
            duelResolver.supportsInterface(_INTERFACE_ID_DUELRESOLVER), "Invalid DuelResolver");

        powerScale = powerScale_;
    }

     
     
     
     
    function() external payable {}

     
     
     
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return
            interfaceId == this.supportsInterface.selector ||  
            interfaceId == _INTERFACE_ID_TOURNAMENT;  
    }

     
     
     
     
     
     
     
     
     
    function isActive() public view returns (bool) {
        uint256 maximumTournamentLength = blueMoldParameters.moldDoublingDuration * 200;

        if (block.number > blueMoldParameters.blueMoldStartBlock + maximumTournamentLength) {
            return false;
        } else {
            return remainingWizards != 0;
        }
    }


     
     
     
     
     
     
     
     
     
     
     
     
     

    function checkGateKeeper() internal view {
        require(msg.sender == GATE_KEEPER, "Only GateKeeper can call");
    }


     
    modifier onlyGateKeeper() {
        checkGateKeeper();
        _;
    }

    function checkExists(uint256 wizardId) internal view {
        require(wizards[wizardId].maxPower != 0, "Wizard does not exist");
    }

     
    modifier exists(uint256 wizardId) {
        checkExists(wizardId);
        _;
    }

    function checkController(uint256 wizardId) internal view {
        require(wizards[wizardId].maxPower != 0, "Wizard does not exist");
        require(WIZARD_GUILD.isApprovedOrOwner(msg.sender, wizardId), "Must be Wizard controller");
    }

     
     
    modifier onlyWizardController(uint256 wizardId) {
        checkController(wizardId);
        _;
    }

     
     
     
     
     
    function getWizard(uint256 wizardId) public view exists(wizardId) returns(
        uint256 affinity,
        uint256 power,
        uint256 maxPower,
        uint256 nonce,
        bytes32 currentDuel,
        bool ascending,
        uint256 ascensionOpponent,
        bool molded,
        bool ready
    ) {
        BattleWizard memory wizard = wizards[wizardId];

        affinity = wizard.affinity;
        power = wizard.power;
        maxPower = wizard.maxPower;
        nonce = wizard.nonce;
        currentDuel = wizard.currentDuel;

        ascending = ascendingWizardId == wizardId;
        ascensionOpponent = ascensionOpponents[wizardId];
        molded = _blueMoldPower() > wizard.power;
        ready = _isReady(wizardId, wizard);
    }

     
     
     
     
    function wizardFingerprint(uint256 wizardId) external view returns (bytes32) {
        (uint256 affinity,
        uint256 power,
        uint256 maxPower,
        uint256 nonce,
        bytes32 currentDuel,
        bool ascending,
        uint256 ascensionOpponent,
        bool molded,
        ) = getWizard(wizardId);

        uint256 pendingOpponent = pendingCommitments[wizardId].opponentId;

         
         
        return keccak256(
            abi.encodePacked(
                wizardId,
                affinity,
                power,
                maxPower,
                nonce,
                currentDuel,
                ascending,
                ascensionOpponent,
                molded,
                pendingOpponent
            ));
    }

     
     
     
    function isReady(uint256 wizardId) public view exists(wizardId) returns (bool) {
        BattleWizard memory wizard = wizards[wizardId];

        return _isReady(wizardId, wizard);
    }

     
     
    function _isReady(uint256 wizardId, BattleWizard memory wizard) internal view returns (bool) {
         
         
         
         
        return ((wizardId != ascendingWizardId) &&
            (ascensionOpponents[wizardId] == 0) &&
            (ascensionCommitment.opponentId != wizardId) &&
            (_blueMoldPower() <= wizard.power) &&
            (wizard.affinity != ELEMENT_NOTSET) &&
            (wizard.currentDuel == 0));
    }

     
     
     
     
     
     
     
     
    function enterWizards(uint256[] calldata wizardIds, uint88[] calldata powers) external payable duringEnterPhase onlyGateKeeper {
        require(wizardIds.length == powers.length, "Mismatched parameter lengths");

        uint256 totalCost = 0;

        for (uint256 i = 0; i < wizardIds.length; i++) {
            uint256 wizardId = wizardIds[i];
            uint88 power = powers[i];

            require(wizards[wizardId].maxPower == 0, "Wizard already in tournament");

            (, uint88 innatePower, uint8 affinity, ) = WIZARD_GUILD.getWizard(wizardId);

            require(power > 0 && power <= innatePower, "Invalid power");

            wizards[wizardId] = BattleWizard({
                power: power,
                maxPower: power,
                nonce: 0,
                affinity: affinity,
                currentDuel: 0
            });

            totalCost += power * powerScale;
        }

        remainingWizards += wizardIds.length;

        require(msg.value >= totalCost, "Insufficient funds");
    }

     
     
     
     
     
     
     
    function revive(uint256 wizardId) external payable exists(wizardId) duringRevivalPhase onlyGateKeeper {
        BattleWizard storage wizard = wizards[wizardId];

        uint88 maxPower = wizard.maxPower;
        uint88 revivalPower = uint88(msg.value / powerScale);

        require((revivalPower > _blueMoldPower()) && (revivalPower <= maxPower), "Invalid power level");
        require(wizard.power == 0, "Can only revive tired Wizards");

         
         

        wizard.power = revivalPower;
        wizard.nonce += 1;

        emit Revive(wizardId, revivalPower);
    }

     
     
     
     
     
     
    function updateAffinity(uint256 wizardId) external exists(wizardId) {
        (, , uint8 newAffinity, ) = WIZARD_GUILD.getWizard(wizardId);
        BattleWizard storage wizard = wizards[wizardId];
        require(wizard.affinity == ELEMENT_NOTSET, "Affinity already updated");
        wizard.affinity = newAffinity;
    }

    function startAscension(uint256 wizardId) external duringAscensionWindow onlyWizardController(wizardId) {
        BattleWizard memory wizard = wizards[wizardId];

        require(_isReady(wizardId, wizard), "Can't ascend a busy wizard!");

        require(wizard.power < _blueMoldPower() * 2, "Not eligible for ascension");

        if (ascendingWizardId != 0) {
             
             
            ascensionOpponents[ascendingWizardId] = wizardId;
            ascensionOpponents[wizardId] = ascendingWizardId;

            emit AscensionPairUp(ascendingWizardId, wizardId);

             
            ascendingWizardId = 0;
        } else {
             
            ascendingWizardId = wizardId;

            emit AscensionStart(wizardId);
        }
    }

    function _checkChallenge(uint256 challengerId, uint256 recipientId) internal view {
        require(pendingCommitments[challengerId].opponentId == 0, "Pending battle already exists");
        require(recipientId > 0, "No Wizard is ascending");
        require(challengerId != recipientId, "Cannot duel oneself!");
    }

     
     
     
    function challengeAscending(uint256 wizardId, bytes32 commitment) external duringFightWindow onlyWizardController(wizardId) {
        require(ascensionCommitment.opponentId == 0, "Wizard already challenged");

        _checkChallenge(wizardId, ascendingWizardId);

         
         
        require(canChallengeAscendingWizard(), "Challenge too late");

        BattleWizard memory wizard = wizards[wizardId];

        require(_isReady(wizardId, wizard), "Wizard not ready");
         

         
        ascensionCommitment = SingleCommitment({opponentId: wizardId, commitmentHash: commitment});
        emit AscensionChallenged(ascendingWizardId, wizardId, commitment);
    }

     
     
    function acceptAscensionChallenge(bytes32 commitment) external duringFightWindow onlyWizardController(ascendingWizardId) {
        uint256 challengerId = ascensionCommitment.opponentId;
        require(challengerId != 0, "No challenge to accept");

        if (challengerId < ascendingWizardId) {
            _beginDuel(challengerId, ascendingWizardId, ascensionCommitment.commitmentHash, commitment, true);
        } else {
            _beginDuel(ascendingWizardId, challengerId, commitment, ascensionCommitment.commitmentHash, true);
        }

         
        delete ascensionCommitment;
        delete ascendingWizardId;
    }

     
     
     
     
     
    function completeAscension() external duringResolutionWindow {
        require(ascendingWizardId != 0, "No Wizard to ascend");

        BattleWizard storage ascendingWiz = wizards[ascendingWizardId];

        if (ascensionCommitment.opponentId != 0) {
             
             
            _transferPower(ascendingWizardId, ascensionCommitment.opponentId, REASON_COMPLETE_ASCENSION);
        }
        else {
             
             
             
             
            _updatePower(ascendingWiz, ascendingWiz.power * 3);
            ascendingWiz.nonce += 1;
        }

        emit AscensionComplete(ascendingWizardId, ascendingWiz.power);

        ascendingWizardId = 0;
    }

    function oneSidedCommit(uint256 committingWizardId, uint256 otherWizardId, bytes32 commitment)
            external duringFightWindow onlyWizardController(committingWizardId) exists(otherWizardId)
    {
        _checkChallenge(committingWizardId, otherWizardId);

        bool isAscensionBattle = false;

        if ((ascensionOpponents[committingWizardId] != 0) || (ascensionOpponents[otherWizardId] != 0)) {
            require(
                (ascensionOpponents[committingWizardId] == otherWizardId) &&
                (ascensionOpponents[otherWizardId] == committingWizardId), "Must resolve Ascension Battle");

            isAscensionBattle = true;
        }

        BattleWizard memory committingWiz = wizards[committingWizardId];
        BattleWizard memory otherWiz = wizards[otherWizardId];

         
         
        require(
            (committingWizardId != ascendingWizardId) &&
            (ascensionCommitment.opponentId != committingWizardId) &&
            (_blueMoldPower() <= committingWiz.power) &&
            (committingWiz.affinity != ELEMENT_NOTSET) &&
            (committingWiz.currentDuel == 0), "Wizard not ready");

        require(
            (otherWizardId != ascendingWizardId) &&
            (ascensionCommitment.opponentId != otherWizardId) &&
            (_blueMoldPower() <= otherWiz.power) &&
            (otherWiz.affinity != ELEMENT_NOTSET) &&
            (otherWiz.currentDuel == 0), "Wizard not ready.");

        SingleCommitment memory otherCommitment = pendingCommitments[otherWizardId];

        if (otherCommitment.opponentId == 0) {
             
             
            pendingCommitments[committingWizardId] = SingleCommitment({opponentId: otherWizardId, commitmentHash: commitment});

            emit OneSidedCommitAdded(
                committingWizardId,
                otherWizardId,
                committingWiz.nonce,
                otherWiz.nonce,
                commitment);
        } else if (otherCommitment.opponentId == committingWizardId) {
             
            if (committingWizardId < otherWizardId) {
                _beginDuel(committingWizardId, otherWizardId, commitment, otherCommitment.commitmentHash, isAscensionBattle);
            } else {
                _beginDuel(otherWizardId, committingWizardId, otherCommitment.commitmentHash, commitment, isAscensionBattle);
            }

            delete pendingCommitments[otherWizardId];

            if (isAscensionBattle) {
                delete ascensionOpponents[committingWizardId];
                delete ascensionOpponents[otherWizardId];
            }
        }
        else {
            revert("Opponent has a pending challenge");
        }
    }

    function cancelCommitment(uint256 wizardId) external onlyWizardController(wizardId) {
        require(ascensionOpponents[wizardId] == 0, "Can't cancel Ascension Battle");

         
        if (pendingCommitments[wizardId].opponentId != 0) {
            emit OneSidedCommitCancelled(wizardId);
        }

        delete pendingCommitments[wizardId];
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function doubleCommit(
        uint256 wizardId1,
        uint256 wizardId2,
        bytes32 commit1,
        bytes32 commit2,
        bytes calldata sig1,
        bytes calldata sig2) external duringFightWindow returns (bytes32 duelId) {

         
         
        checkExists(wizardId1);
        checkExists(wizardId2);

         
         
         
        require(wizardId1 < wizardId2, "Wizard IDs must be ordered");

        bool isAscensionBattle = false;

        if ((ascensionOpponents[wizardId1] != 0) || (ascensionOpponents[wizardId2] != 0)) {
            require(
                (ascensionOpponents[wizardId1] == wizardId2) &&
                (ascensionOpponents[wizardId2] == wizardId1), "Must resolve Ascension Battle");

            isAscensionBattle = true;

             
             
             
             
            delete ascensionOpponents[wizardId1];
            delete ascensionOpponents[wizardId2];
        }

         
        BattleWizard memory wiz1 = wizards[wizardId1];
        BattleWizard memory wiz2 = wizards[wizardId2];

        require(_isReady(wizardId1, wiz1) && _isReady(wizardId2, wiz2), "Wizard not ready");

         
        bytes32 signedHash1 = _signedHash(wizardId1, wizardId2, wiz1.nonce, wiz2.nonce, commit1);
        bytes32 signedHash2 = _signedHash(wizardId1, wizardId2, wiz1.nonce, wiz2.nonce, commit2);
        WIZARD_GUILD.verifySignatures(wizardId1, wizardId2, signedHash1, signedHash2, sig1, sig2);

         
        duelId = _beginDuel(wizardId1, wizardId2, commit1, commit2, isAscensionBattle);

         
        delete pendingCommitments[wizardId1];
        delete pendingCommitments[wizardId2];
    }

     
     
    function _signedHash(uint256 wizardId1, uint256 wizardId2, uint32 nonce1, uint32 nonce2, bytes32 commit)
        internal view returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(
            EIP191_PREFIX,
            EIP191_VERSION_DATA,
            this,
            wizardId1,
            wizardId2,
            nonce1,
            nonce2,
            commit
        ));
    }

     
     
    function _beginDuel(uint256 wizardId1, uint256 wizardId2, bytes32 commit1, bytes32 commit2, bool isAscensionBattle)
            internal returns (bytes32 duelId)
    {
         
        BattleWizard storage wiz1 = wizards[wizardId1];
        BattleWizard storage wiz2 = wizards[wizardId2];

         
         
         
        duelId = keccak256(
            abi.encodePacked(
            this,
            wizardId1,
            wizardId2,
            wiz1.nonce,
            wiz2.nonce,
            commit1,
            commit2
        ));

         
        wiz1.currentDuel = duelId;
        wiz2.currentDuel = duelId;

         
        uint256 duelTimeout;

        if (isAscensionBattle) {
             
             
             
            duelTimeout = _ascensionDuelTimeout();
        } else {
             
            duelTimeout = block.number + tournamentTimeParameters.duelTimeoutDuration;
        }

        duels[duelId] = Duel({timeout: uint128(duelTimeout), isAscensionBattle: isAscensionBattle});

        emit DuelStart(duelId, wizardId1, wizardId2, duelTimeout, isAscensionBattle, commit1, commit2);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function oneSidedReveal(
        uint256 committingWizardId,
        bytes32 commit,
        bytes32 moveSet,
        bytes32 salt,
        uint256 otherWizardId,
        bytes32 otherCommit) external
    {
        BattleWizard memory wizard = wizards[committingWizardId];
        BattleWizard memory otherWizard = wizards[otherWizardId];

        bytes32 duelId = wizard.currentDuel;

        require(duelId != 0, "Wizard not dueling");

         
        bytes32 computedDuelId;

         
        if (committingWizardId < otherWizardId) {
            computedDuelId = keccak256(
                abi.encodePacked(
                this,
                committingWizardId,
                otherWizardId,
                wizard.nonce,
                otherWizard.nonce,
                commit,
                otherCommit
            ));
        } else {
            computedDuelId = keccak256(
                abi.encodePacked(
                this,
                otherWizardId,
                committingWizardId,
                otherWizard.nonce,
                wizard.nonce,
                otherCommit,
                commit
            ));
        }

        require(computedDuelId == duelId, "Invalid duel data");

         
        require(keccak256(abi.encodePacked(moveSet, salt)) == commit, "Moves don't match commitment");

         
         
         
         
        require(duelResolver.isValidMoveSet(moveSet), "Invalid moveset");

        if (revealedMoves[duelId][otherWizardId] != 0) {
             
            if (committingWizardId < otherWizardId) {
                _resolveDuel(duelId, committingWizardId, otherWizardId, moveSet, revealedMoves[duelId][otherWizardId]);
            } else {
                _resolveDuel(duelId, otherWizardId, committingWizardId, revealedMoves[duelId][otherWizardId], moveSet);
            }
        }
        else {
            require(block.number < duels[duelId].timeout, "Duel expired");
             
            revealedMoves[duelId][committingWizardId] = moveSet;
            emit OneSidedRevealAdded(duelId, committingWizardId, otherWizardId);
        }
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function doubleReveal(
        uint256 wizardId1,
        uint256 wizardId2,
        bytes32 commit1,
        bytes32 commit2,
        bytes32 moveSet1,
        bytes32 moveSet2,
        bytes32 salt1,
        bytes32 salt2) external
    {
         
        BattleWizard storage wiz1 = wizards[wizardId1];
        BattleWizard storage wiz2 = wizards[wizardId2];

         
         
         
         
         

         
        bytes32 duelId = keccak256(
            abi.encodePacked(
            this,
            wizardId1,
            wizardId2,
            wiz1.nonce,
            wiz2.nonce,
            commit1,
            commit2
        ));

         
         
        require(wiz1.currentDuel == duelId, "Invalid duel data");

         
        require(
            (keccak256(abi.encodePacked(moveSet1, salt1)) == commit1) &&
            (keccak256(abi.encodePacked(moveSet2, salt2)) == commit2), "Moves don't match commitment");

         
        _resolveDuel(duelId, wizardId1, wizardId2, moveSet1, moveSet2);
    }

     
    function _resolveDuel(bytes32 duelId, uint256 wizardId1, uint256 wizardId2, bytes32 moveSet1, bytes32 moveSet2) internal {
        Duel memory duelInfo = duels[duelId];

        require(block.number < duelInfo.timeout, "Duel expired");

         
        BattleWizard storage wiz1 = wizards[wizardId1];
        BattleWizard storage wiz2 = wizards[wizardId2];

        int256 battlePower1 = wiz1.power;
        int256 battlePower2 = wiz2.power;

        int256 moldPower = int256(_blueMoldPower());

        if (duelInfo.isAscensionBattle) {
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
            if (battlePower1 > battlePower2 + 2*moldPower) {
                battlePower1 = battlePower2;
            } else if (battlePower2 > battlePower1 + 2*moldPower) {
                battlePower2 = battlePower1;
            }
        }

        int256 powerDiff = duelResolver.resolveDuel(
            moveSet1,
            moveSet2,
            uint256(battlePower1),
            uint256(battlePower2),
            wiz1.affinity,
            wiz2.affinity);

         
         
         
        if (powerDiff < -battlePower1) {
            powerDiff = -battlePower1;
        } else if (powerDiff > battlePower2) {
            powerDiff = battlePower2;
        }

         
        battlePower1 += powerDiff;
        battlePower2 -= powerDiff;

        if (duelInfo.isAscensionBattle) {
             
             
             
            if (battlePower1 >= battlePower2) {
                 
                 
                 
                 
                 
                powerDiff += battlePower2;
            } else {
                powerDiff -= battlePower1;
            }
        }

         
         
        int256 power1 = wiz1.power + powerDiff;
        int256 power2 = wiz2.power - powerDiff;

         
         
        if (power1 < moldPower) {
            power2 += power1;
            power1 = 0;
        }
        else if (power2 < moldPower) {
            power1 += power2;
            power2 = 0;
        }

        _updatePower(wiz1, power1);
        _updatePower(wiz2, power2);

         
        wiz1.currentDuel = 0;
        wiz2.currentDuel = 0;

         
        wiz1.nonce += 1;
        wiz2.nonce += 1;

         
        delete duels[duelId];
        delete revealedMoves[duelId][wizardId1];
        delete revealedMoves[duelId][wizardId2];

         
        emit DuelEnd(duelId, wizardId1, wizardId2, moveSet1, moveSet2, wiz1.power, wiz2.power);
    }

     
     
     
    function _updatePower(BattleWizard storage wizard, int256 newPower) internal {
        if (newPower > MAX_POWER) {
            newPower = MAX_POWER;
        }

        wizard.power = uint88(newPower);

        if (wizard.maxPower < newPower) {
            wizard.maxPower = uint88(newPower);
        }
    }

     
     
    function _transferPower(uint256 sendingWizardId, uint256 receivingWizardId, uint8 reason) internal {
        BattleWizard storage sendingWiz = wizards[sendingWizardId];
        BattleWizard storage receivingWiz = wizards[receivingWizardId];

        _updatePower(receivingWiz, receivingWiz.power + sendingWiz.power);

        emit PowerTransferred(sendingWizardId, receivingWizardId, sendingWiz.power, reason);

        sendingWiz.power = 0;
         
        sendingWiz.nonce += 1;
        receivingWiz.nonce += 1;
    }

     
    function resolveOneSidedAscensionBattle(uint256 wizardId) external duringResolutionWindow {
        uint256 opponentId = ascensionOpponents[wizardId];
        require(opponentId != 0, "No opponent");

        SingleCommitment memory commit = pendingCommitments[wizardId];
        require(commit.opponentId == opponentId, "No commit");

        _transferPower(opponentId, wizardId, REASON_RESOLVE_ONE_SIDED_ASCENSION_BATTLE);

         
        delete pendingCommitments[wizardId];
        delete ascensionOpponents[wizardId];
        delete ascensionOpponents[opponentId];
    }

     
     
     
     
     
     
    function resolveTimedOutDuel(uint256 wizardId1, uint256 wizardId2) external {
        BattleWizard storage wiz1 = wizards[wizardId1];
        BattleWizard storage wiz2 = wizards[wizardId2];

        bytes32 duelId = wiz1.currentDuel;

        require(duelId != 0 && wiz2.currentDuel == duelId);
        require(block.number >= duels[duelId].timeout);

        int256 allPower = wiz1.power + wiz2.power;

        if (revealedMoves[duelId][wizardId1] != 0) {
             
             
            _updatePower(wiz1, allPower);
            wiz2.power = 0;
            }
        else if (revealedMoves[duelId][wizardId2] != 0) {
             
            _updatePower(wiz2, allPower);
            wiz1.power = 0;
        }
         

         
        wiz1.currentDuel = 0;
        wiz2.currentDuel = 0;

         
        wiz1.nonce += 1;
        wiz2.nonce += 1;

         
        delete duels[duelId];
        delete revealedMoves[duelId][wizardId1];
        delete revealedMoves[duelId][wizardId2];

         
        emit DuelTimeOut(duelId, wizardId1, wizardId2, wiz1.power, wiz2.power);
    }

     
     
     
     
     
     
     
     
    function giftPower(uint256 sendingWizardId, uint256 receivingWizardId) external
        onlyWizardController(sendingWizardId) exists(receivingWizardId) duringFightWindow
    {
        require(sendingWizardId != receivingWizardId);
        require(isReady(sendingWizardId) && isReady(receivingWizardId));

        _transferPower(sendingWizardId, receivingWizardId, REASON_GIFT_POWER);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function cullMoldedWithSurvivor(uint256[] calldata wizardIds, uint256 survivor) external
        exists(survivor) duringCullingWindow
    {
        uint256 moldLevel = _blueMoldPower();

        require(wizards[survivor].power >= moldLevel, "Survivor isn't alive");

        for (uint256 i = 0; i < wizardIds.length; i++) {
            uint256 wizardId = wizardIds[i];
            if (wizards[wizardId].maxPower != 0 && wizards[wizardId].power < moldLevel) {
                _deleteWizard(wizardId);
            }
        }
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function cullMoldedWithMolded(uint256[] calldata moldyWizardIds) external duringCullingWindow {
        require(moldyWizardIds.length > 0, "Empty ids");

        uint256 currentId;
        uint256 currentPower;
        uint256 previousId = moldyWizardIds[0];
        uint256 previousPower = wizards[previousId].power;

         
         
         

        require(previousPower < _blueMoldPower(), "Not moldy");
         
        require(wizards[previousId].currentDuel == 0, "Dueling");

        for (uint256 i = 1; i < moldyWizardIds.length; i++) {
            currentId = moldyWizardIds[i];
            checkExists(currentId);
            currentPower = wizards[currentId].power;

             
            require(
                (currentPower < previousPower) ||
                ((currentPower == previousPower) && (currentId > previousId)),
                "Wizards not strictly ordered");

            if (i >= 5) {
                _deleteWizard(currentId);
            } else {
                 
                require(wizards[currentId].currentDuel == 0, "Dueling");
            }

            previousId = currentId;
            previousPower = currentPower;
        }
    }

     
     
     
    function _deleteWizard(uint256 wizardId) internal {
        require(wizards[wizardId].currentDuel == 0, "Wizard is dueling");
        delete wizards[wizardId];
        remainingWizards--;
        emit WizardElimination(wizardId);
    }

     
     
     
     
    function cullTiredWizards(uint256[] calldata wizardIds) external duringCullingWindow {
        for (uint256 i = 0; i < wizardIds.length; i++) {
            uint256 wizardId = wizardIds[i];
            if (wizards[wizardId].maxPower != 0 && wizards[wizardId].power == 0) {
                _deleteWizard(wizardId);
            }
        }
    }

     
     
     
     
    function claimTheBigCheeze(uint256 claimingWinnerId) external duringCullingWindow onlyWizardController(claimingWinnerId) {
        require(remainingWizards == 1, "Keep fighting!");

         
        emit PrizeClaimed(claimingWinnerId, address(this).balance);

        remainingWizards = 0;
        delete wizards[claimingWinnerId];

        msg.sender.transfer(address(this).balance);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function claimSharedWinnings(uint256 claimingWinnerId, uint256[] calldata allWinners)
        external duringCullingWindow onlyWizardController(claimingWinnerId)
    {
        require(remainingWizards <= 5, "Too soon to claim");
        require(remainingWizards == allWinners.length, "Must provide all winners");
        require(wizards[claimingWinnerId].power != 0, "No cheeze for you!");

        uint256 moldLevel = _blueMoldPower();
        uint256 totalPower = 0;
        uint256 lastWizard = 0;

         
         
        for (uint256 i = 0; i < allWinners.length; i++) {
            uint256 wizardId = allWinners[i];
            uint256 wizardPower = wizards[wizardId].power;

            require(wizardId > lastWizard, "Winners not unique and ordered");
            require(wizards[wizardId].maxPower != 0, "Wizard already eliminated");
            require(wizardPower < moldLevel, "Wizard not moldy");

            lastWizard = wizardId;
            totalPower += wizardPower;
        }

        uint256 claimingWinnerShare = address(this).balance * wizards[claimingWinnerId].power / totalPower;

         
        delete wizards[claimingWinnerId];
        remainingWizards--;

        emit PrizeClaimed(claimingWinnerId, claimingWinnerShare);

        msg.sender.transfer(claimingWinnerShare);
    }

     
    function destroy() external onlyGateKeeper {
        require(isActive() == false, "Tournament active");

        selfdestruct(msg.sender);
    }
}