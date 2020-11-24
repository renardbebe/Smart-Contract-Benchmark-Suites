 

pragma solidity ^0.4.19;


contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
    function getBeneficiary() external view returns(address);
}

contract GeneratorInterface {

    function isGenerator() public pure returns (bool);

     
     
     
     
    function generateWarrior(uint256 _heroGenes, uint256 _heroLevel, uint256 _targetBlock, uint256 _perkId) public returns (uint256);
}

contract PVPInterface {

    function isPVPProvider() external pure returns (bool);
    
    function addTournamentContender(address _owner, uint256[] _tournamentData) external payable;
    function getTournamentThresholdFee() public view returns(uint256);
    
    function addPVPContender(address _owner, uint256 _packedWarrior) external payable;
    function getPVPEntranceFee(uint256 _levelPoints) external view returns(uint256);
}

contract PVPListenerInterface {

    function isPVPListener() public pure returns (bool);
    function getBeneficiary() external view returns(address);
    
    function pvpFinished(uint256[] warriorData, uint256 matchingCount) public;
    function pvpContenderRemoved(uint32 _warriorId) public;
    function tournamentFinished(uint256[] packedContenders) public;
}

 
 
 
 
 
 
contract PermissionControll {

    event ContractUpgrade(address newContract);
    
    address public newContractAddress;

    address public adminAddress;
    address public bankAddress;
    address public issuerAddress; 

    bool public paused = false;
    

    modifier onlyAdmin(){
        require(msg.sender == adminAddress);
        _;
    }

    modifier onlyBank(){
        require(msg.sender == bankAddress);
        _;
    }
    
    modifier onlyIssuer(){
    		require(msg.sender == issuerAddress);
        _;
    }
    
    modifier onlyAuthorized(){
        require(msg.sender == issuerAddress ||
            msg.sender == adminAddress ||
            msg.sender == bankAddress);
        _;
    }


    function setBank(address _newBank) external onlyBank {
        require(_newBank != address(0));
        bankAddress = _newBank;
    }

    function setAdmin(address _newAdmin) external {
        require(msg.sender == adminAddress || msg.sender == bankAddress);
        require(_newAdmin != address(0));
        adminAddress = _newAdmin;
    }
    
    function setIssuer(address _newIssuer) external onlyAdmin{
        require(_newIssuer != address(0));
        issuerAddress = _newIssuer;
    }

    modifier whenNotPaused(){
        require(!paused);
        _;
    }


    modifier whenPaused{
        require(paused);
        _;
    }

    function pause() external onlyAuthorized whenNotPaused{
        paused = true;
    }

    function unpause() public onlyAdmin whenPaused{
        paused = false;
    }
    

    function setNewAddress(address _v2Address) external onlyAdmin whenPaused {
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }
}

contract Ownable {
    address public owner;

     
    function Ownable() public{
        owner = msg.sender;
    }

     
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner{
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Pausable is Ownable {
    event Pause();

    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused(){
        require(!paused);
        _;
    }

     
    modifier whenPaused{
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}


library DataTypes {

    struct Warrior{
         
        uint256 identity;
        
        uint64 cooldownEndBlock;
         
        uint64 level;
         
        int64 rating;
         
        uint32 action;
         
        uint32 dungeonIndex;
    }
}

contract CryptoWarriorBase is PermissionControll, PVPListenerInterface {


     
    event Arise(address owner, uint256 warriorId, uint256 identity);

     
    event Transfer(address from, address to, uint256 tokenId);

     
    
	uint256 public constant IDLE = 0;
    uint256 public constant PVE_BATTLE = 1;
    uint256 public constant PVP_BATTLE = 2;
    uint256 public constant TOURNAMENT_BATTLE = 3;
    
     
    uint256 public constant MAX_LEVEL = 25;
     
    uint256 public constant POINTS_TO_LEVEL = 10;
    
     
     
    uint32[6] public dungeonRequirements = [
        uint32(10),
        uint32(30),
        uint32(60),
        uint32(100),
        uint32(150),
        uint32(250)
    ];

    uint256 public secondsPerBlock = 15;

     

     
    DataTypes.Warrior[] warriors;

     
    mapping (uint256 => address) public warriorToOwner;

     
    mapping (address => uint256) ownersTokenCount;

     
    mapping (uint256 => address) public warriorToApproved;

    SaleClockAuction public saleAuction;
    
    
     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
        ownersTokenCount[_to]++;
         
        warriorToOwner[_tokenId] = _to;
         
        if (_from != address(0)) {
            ownersTokenCount[_from]--;
             
            delete warriorToApproved[_tokenId];
        }
         
        Transfer(_from, _to, _tokenId);
    }

     
     
     
    function _createWarrior(uint256 _identity, address _owner, uint256 _cooldown)
        internal
        returns (uint256) {
        	    
        DataTypes.Warrior memory _warrior = DataTypes.Warrior({
            identity : _identity,
            cooldownEndBlock : uint64(_cooldown),
            level : uint64(10),
            rating : int64(100),
            action : uint32(IDLE),
            dungeonIndex : uint32(0)
        });
        uint256 newWarriorId = warriors.push(_warrior) - 1;
        
        require(newWarriorId == uint256(uint32(newWarriorId)));
        
         
        Arise(_owner, newWarriorId, _identity);
        
         
        _transfer(0, _owner, newWarriorId);

        return newWarriorId;
    }
    

    function setSecondsPerBlock(uint256 secs) external onlyAuthorized {
        secondsPerBlock = secs;
    }
}

contract WarriorTokenImpl is CryptoWarriorBase, ERC721 {

    string public constant name = "CryptoWarriors";
    string public constant symbol = "CW";

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('transfer(address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)')) ^
        bytes4(keccak256('tokensOfOwner(address)'));

    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return warriorToOwner[_tokenId] == _claimant;    
    }

    function _ownerApproved(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return warriorToOwner[_tokenId] == _claimant && warriorToApproved[_tokenId] == address(0);    
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return warriorToApproved[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        warriorToApproved[_tokenId] = _approved;
    }
	
	 
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownersTokenCount[_owner];
    }

	 
    function transfer(address _to, uint256 _tokenId) external whenNotPaused {
         
        require(_to != address(0));
         
        require(_to != address(this));
         
        require(_to != address(saleAuction));

         
        require(_owns(msg.sender, _tokenId));
         
        require(warriors[_tokenId].action == IDLE);

         
        _transfer(msg.sender, _to, _tokenId);
    }

	 
    function approve(address _to, uint256 _tokenId) external whenNotPaused {
         
        require(_owns(msg.sender, _tokenId));
         
        require(warriors[_tokenId].action == IDLE);

         
        _approve(_tokenId, _to);

         
        Approval(msg.sender, _to, _tokenId);
    }

	 
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
        whenNotPaused
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
         
        require(warriors[_tokenId].action == IDLE);

         
        _transfer(_from, _to, _tokenId);
    }

     
    function totalSupply() public view returns (uint256) {
        return warriors.length;
    }

     
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = warriorToOwner[_tokenId];

        require(owner != address(0));
    }

     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalWarriors = totalSupply();
            uint256 resultIndex = 0;

            uint256 warriorId;

            for (warriorId = 0; warriorId < totalWarriors; warriorId++) {
                if (warriorToOwner[warriorId] == _owner) {
                    result[resultIndex] = warriorId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

}

contract CryptoWarriorPVE is WarriorTokenImpl {
    
    uint256 internal constant SUMMONING_SICKENESS = 12;
    
    uint256 internal constant PVE_COOLDOWN = 1 hours;
    uint256 internal constant PVE_DURATION = 15 minutes;
    
    
     
    uint256 public pveBattleFee = 10 finney;
    uint256 public constant PVE_COMPENSATION = 2 finney;
    
	 
    GeneratorInterface public generator;

     
    event PVEStarted(address owner, uint256 dungeonIndex, uint256 warriorId, uint256 battleEndBlock);

     
    event PVEFinished(address owner, uint256 dungeonIndex, uint256 warriorId, uint256 cooldownEndBlock, uint256 rewardId);

	 
     
    function setGeneratorAddress(address _address) external onlyAdmin {
        GeneratorInterface candidateContract = GeneratorInterface(_address);

         
        require(candidateContract.isGenerator());

         
        generator = candidateContract;
    }
    
    function areUnique(uint32[] memory _warriorIds) internal pure returns(bool) {
   	    uint256 length = _warriorIds.length;
   	    uint256 j;
        for(uint256 i = 0; i < length; i++) {
	        for(j = i + 1; j < length; j++) {
	            if (_warriorIds[i] == _warriorIds[j]) return false;
	        }
        }
        return true; 
   	}

     
     
    function setPVEBattleFee(uint256 _pveBattleFee) external onlyAdmin {
        require(_pveBattleFee > PVE_COMPENSATION);
        pveBattleFee = _pveBattleFee;
    }
    
     
    function getPVECooldown(uint256 _levelPoints) public pure returns (uint256) {
        uint256 level = CryptoUtils._getLevel(_levelPoints);
        if (level >= MAX_LEVEL) return (14 * 24 * PVE_COOLDOWN); 
        return (PVE_COOLDOWN * level);
    }

     
    function getPVEDuration(uint256 _levelPoints) public pure returns (uint256) {
        return CryptoUtils._getLevel(_levelPoints) * PVE_DURATION;
    }
    
     
     
     
    function _isReadyToPVE(DataTypes.Warrior _warrior) internal view returns (bool) {
        return (_warrior.action == IDLE) &&  
        (_warrior.cooldownEndBlock <= uint64(block.number)) &&  
        (_warrior.level >= dungeonRequirements[_warrior.dungeonIndex]); 
    }
    
     
     
    function _triggerPVEStart(uint256 _warriorId) internal {
         
        DataTypes.Warrior storage warrior = warriors[_warriorId];
         
        warrior.action = uint16(PVE_BATTLE);
         
        warrior.cooldownEndBlock = uint64((getPVEDuration(warrior.level) / secondsPerBlock) + block.number);
         
        PVEStarted(msg.sender, warrior.dungeonIndex, _warriorId, warrior.cooldownEndBlock);
    }
    
     
     
     
    function startPVE(uint256 _warriorId) external payable whenNotPaused {
		 
        require(msg.value >= pveBattleFee);
		
		 
        require(_ownerApproved(msg.sender, _warriorId));

         
        DataTypes.Warrior storage warrior = warriors[_warriorId];

         
        require(warrior.identity != 0);

         
        require(_isReadyToPVE(warrior));
        
         
        _triggerPVEStart(_warriorId);
        
         
         
         
         
        uint256 feeExcess = msg.value - pveBattleFee;

         
         
         
        msg.sender.transfer(feeExcess);
         
        bankAddress.transfer(pveBattleFee - PVE_COMPENSATION);
    }
    
    function _ariseWarrior(address _owner, DataTypes.Warrior storage _warrior) internal returns(uint256) {
        uint256 identity = generator.generateWarrior(_warrior.identity, CryptoUtils._getLevel(_warrior.level), _warrior.cooldownEndBlock - 1, 0);
        return _createWarrior(identity, _owner, block.number + (PVE_COOLDOWN * SUMMONING_SICKENESS / secondsPerBlock));
    }

	 
     
    function _triggerPVEFinish(uint256 _warriorId) internal {
         
        DataTypes.Warrior storage warrior = warriors[_warriorId];
        
         
        warrior.action = uint16(IDLE);
        
         
         
        warrior.cooldownEndBlock = uint64((getPVECooldown(warrior.level) / 
            CryptoUtils._getBonus(warrior.identity) / secondsPerBlock) + block.number);
        
         
        uint32 dungeonIndex = warrior.dungeonIndex;
         
         
         
        if (dungeonIndex < 6) {
            warrior.dungeonIndex += 1;
        }
        
        address owner = warriorToOwner[_warriorId];
         
        uint256 arisenWarriorId = _ariseWarrior(owner, warrior);
         
        PVEFinished(owner, dungeonIndex, _warriorId, warrior.cooldownEndBlock, arisenWarriorId);
    }
    
     
    function finishPVE(uint32 _warriorId) external whenNotPaused {
         
        DataTypes.Warrior storage warrior = warriors[_warriorId];
        
         
        require(warrior.identity != 0);
        
         
        require(warrior.action == PVE_BATTLE);
        
         
        require(warrior.cooldownEndBlock <= uint64(block.number));
        
         
        _triggerPVEFinish(_warriorId);
        
         
         
        msg.sender.transfer(PVE_COMPENSATION);
    }
    
     
    function finishPVEBatch(uint32[] _warriorIds) external whenNotPaused {
        uint256 length = _warriorIds.length;
         
        require(length <= 20);
        uint256 blockNumber = block.number;
        uint256 index;
         
        require(areUnique(_warriorIds));
         
        for(index = 0; index < length; index ++) {
            DataTypes.Warrior storage warrior = warriors[_warriorIds[index]];
			require(
		         
			    warrior.identity != 0 &&
		         
			    warrior.action == PVE_BATTLE &&
		         
			    warrior.cooldownEndBlock <= blockNumber
			);
        }
         
        for(index = 0; index < length; index ++) {
            _triggerPVEFinish(_warriorIds[index]);
        }
        
         
         
        msg.sender.transfer(PVE_COMPENSATION * length);
    }
}

contract CryptoWarriorPVP is CryptoWarriorPVE {
	
	PVPInterface public battleProvider;
	
	 
     
    function setBattleProviderAddress(address _address) external onlyAdmin {
        PVPInterface candidateContract = PVPInterface(_address);

         
        require(candidateContract.isPVPProvider());

         
        battleProvider = candidateContract;
    }
    
    function _packPVPData(uint256 _warriorId, DataTypes.Warrior storage warrior) internal view returns(uint256){
        return CryptoUtils._packWarriorPvpData(warrior.identity, uint256(warrior.rating), 0, _warriorId, warrior.level);
    }
    
    function _triggerPVPSignUp(uint32 _warriorId, uint256 fee) internal {
        DataTypes.Warrior storage warrior = warriors[_warriorId];
    		
		uint256 packedWarrior = _packPVPData(_warriorId, warrior);
        
         
        battleProvider.addPVPContender.value(fee)(msg.sender, packedWarrior);
        
        warrior.action = uint16(PVP_BATTLE);
    }
    
     
    function signUpForPVP(uint32 _warriorId) public payable whenNotPaused { 
		 
        require(_ownerApproved(msg.sender, _warriorId));
         
        DataTypes.Warrior storage warrior = warriors[_warriorId];
         
        require(warrior.identity != 0);

         
        require(warrior.action == IDLE);
        
         
        uint256 fee = battleProvider.getPVPEntranceFee(warrior.level);
        
         
        require(msg.value >= fee);
        
         
        _triggerPVPSignUp(_warriorId, fee);
        
         
         
         
         
        uint256 feeExcess = msg.value - fee;

         
         
         
        msg.sender.transfer(feeExcess);
    }

    function _grandPVPWinnerReward(uint256 _warriorId) internal {
        DataTypes.Warrior storage warrior = warriors[_warriorId];
         
        uint256 level = warrior.level;
        if (level < (MAX_LEVEL * POINTS_TO_LEVEL)) {
            level = level + POINTS_TO_LEVEL;
			warrior.level = uint64(level > (MAX_LEVEL * POINTS_TO_LEVEL) ? (MAX_LEVEL * POINTS_TO_LEVEL) : level);
        }
		 
		warrior.rating += 130;
		 
		 
		warrior.action = uint16(IDLE);
    }

    function _grandPVPLoserReward(uint256 _warriorId) internal {
        DataTypes.Warrior storage warrior = warriors[_warriorId];
		 
		uint256 oldLevel = warrior.level;
		uint256 level = oldLevel;
		if (level < (MAX_LEVEL * POINTS_TO_LEVEL)) {
            level += (POINTS_TO_LEVEL / 2);
			warrior.level = uint64(level);
        }
		 
		int256 newRating = warrior.rating + (CryptoUtils._getLevel(level) > CryptoUtils._getLevel(oldLevel) ? int256(100 - 30) : int256(-30));
		 
	    warrior.rating = int64((newRating >= 0) ? (newRating > 1000000000 ? 1000000000 : newRating) : 0);
         
		 
	    warrior.action = uint16(IDLE);
    }
    
    function _grandPVPRewards(uint256[] memory warriorsData, uint256 matchingCount) internal {
        for(uint256 id = 0; id < matchingCount; id += 2){
             
             
            _grandPVPWinnerReward(CryptoUtils._unpackIdValue(warriorsData[id]));
             
             
            _grandPVPLoserReward(CryptoUtils._unpackIdValue(warriorsData[id + 1]));
        }
	}

     
     
    function pvpFinished(uint256[] warriorsData, uint256 matchingCount) public {
         
        require(msg.sender == address(battleProvider));
        
        _grandPVPRewards(warriorsData, matchingCount);
    }
    
    function pvpContenderRemoved(uint32 _warriorId) public {
         
        require(msg.sender == address(battleProvider));
         
        DataTypes.Warrior storage warrior = warriors[_warriorId];
         
        require(warrior.action == PVP_BATTLE);
         
         
        warrior.action = uint16(IDLE);
    }
}

contract CryptoWarriorTournament is CryptoWarriorPVP {
    
    uint256 internal constant GROUP_SIZE = 5;
    
    function _ownsAll(address _claimant, uint32[] memory _warriorIds) internal view returns (bool) {
        uint256 length = _warriorIds.length;
        for(uint256 i = 0; i < length; i++) {
            if (!_ownerApproved(_claimant, _warriorIds[i])) return false;
        }
        return true;    
    }
    
    function _isReadyToTournament(DataTypes.Warrior storage _warrior) internal view returns(bool){
        return _warrior.level >= 50 && _warrior.action == IDLE; 
    }
    
    function _packTournamentData(uint32[] memory _warriorIds) internal view returns(uint256[] memory tournamentData) {
        tournamentData = new uint256[](GROUP_SIZE);
        uint256 warriorId;
        for(uint256 i = 0; i < GROUP_SIZE; i++) {
            warriorId = _warriorIds[i];
            tournamentData[i] = _packPVPData(warriorId, warriors[warriorId]);   
        }
        return tournamentData;
    }
    
    
     
     
    function _triggerTournamentSignUp(uint32[] memory _warriorIds, uint256 fee) internal {
         
        uint256[] memory tournamentData = _packTournamentData(_warriorIds);
        
        for(uint256 i = 0; i < GROUP_SIZE; i++) {
             
            warriors[_warriorIds[i]].action = uint16(TOURNAMENT_BATTLE);
        }

        battleProvider.addTournamentContender.value(fee)(msg.sender, tournamentData);
    }
    
    function signUpForTournament(uint32[] _warriorIds) public payable {
         
         
        uint256 fee = battleProvider.getTournamentThresholdFee();
        require(msg.value >= fee);
         
         
        require(_warriorIds.length == GROUP_SIZE);
         
         
        require(_ownsAll(msg.sender, _warriorIds));
         
         
        require(areUnique(_warriorIds));
         
         
        for(uint256 i = 0; i < GROUP_SIZE; i ++) {
             
            require(_isReadyToTournament(warriors[_warriorIds[i]]));
        }
        
        
         
        _triggerTournamentSignUp(_warriorIds, fee);
        
         
         
         
         
        uint256 feeExcess = msg.value - fee;

         
         
         
        msg.sender.transfer(feeExcess);
    }
    
    function _setIDLE(uint256 warriorIds) internal {
        for(uint256 i = 0; i < GROUP_SIZE; i ++) {
            warriors[CryptoUtils._unpackWarriorId(warriorIds, i)].action = uint16(IDLE);
        }
    }
    
    function _freeWarriors(uint256[] memory packedContenders) internal {
        uint256 length = packedContenders.length;
        for(uint256 i = 0; i < length; i ++) {
             
            _setIDLE(packedContenders[i]);
        }
    }
    
    function tournamentFinished(uint256[] packedContenders) public {
         
        require(msg.sender == address(battleProvider));
        
         
        _freeWarriors(packedContenders);
    }
    
}

contract CryptoWarriorAuction is CryptoWarriorTournament {

    function setSaleAuctionAddress(address _address) external onlyAdmin {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        require(candidateContract.isSaleClockAuction());

        saleAuction = candidateContract;
    }

    function createSaleAuction(
        uint256 _warriorId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
         
        require(_ownerApproved(msg.sender, _warriorId));
         
         
        require(warriors[_warriorId].action == IDLE);
        _approve(_warriorId, address(saleAuction));
         
        saleAuction.createAuction(
            _warriorId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

}

contract CryptoWarriorIssuer is CryptoWarriorAuction {
    
     
    uint256 public constant MINER_CREATION_LIMIT = 2880; 
	uint256 internal constant MINER_PERK = 1;
     
    uint256 public constant MINER_STARTING_PRICE = 100 finney;
    uint256 public constant MINER_END_PRICE = 50 finney;
    uint256 public constant MINER_AUCTION_DURATION = 1 days;

    uint256 public minerCreatedCount;

     
     
    function createMinerAuction() external onlyIssuer {
        require(minerCreatedCount < MINER_CREATION_LIMIT);
		
        minerCreatedCount++;

        uint256 identity = generator.generateWarrior(minerCreatedCount, 0, block.number - 1, MINER_PERK);
        uint256 warriorId = _createWarrior(identity, bankAddress, 0);
        _approve(warriorId, address(saleAuction));

        saleAuction.createAuction(
            warriorId,
            _computeNextMinerPrice(),
            MINER_END_PRICE,
            MINER_AUCTION_DURATION,
            bankAddress
        );
    }

    function _computeNextMinerPrice() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageMinerSalePrice();

        require(avePrice == uint256(uint128(avePrice)));

        uint256 nextPrice = avePrice * 3 / 2; 

        if (nextPrice < MINER_STARTING_PRICE) {
            nextPrice = MINER_STARTING_PRICE;
        }

        return nextPrice;
    }

}

contract CryptoWarriorCore is CryptoWarriorIssuer {

    function CryptoWarriorCore() public {
         
        paused = true;

         
        adminAddress = msg.sender;

         
        issuerAddress = msg.sender;
        
         
        bankAddress = msg.sender;
    }
    
    function() external payable {
        require(false);
    }
    
    function unpause() public onlyAdmin whenPaused {
        require(address(saleAuction) != address(0));
        require(address(generator) != address(0));
        require(address(battleProvider) != address(0));
        require(newContractAddress == address(0));

         
        super.unpause();
    }
    
    function getBeneficiary() external view returns(address) {
        return bankAddress;
    }
    
    function isPVPListener() public pure returns (bool) {
        return true;
    }
       
     
    function getWarriors(uint32[] _warriorIds) external view returns (uint256[] memory warriorsData, uint32 stepSize) {
        stepSize = 6;
        warriorsData = new uint256[](_warriorIds.length * stepSize);
        for(uint32 i = 0; i < _warriorIds.length; i++) {
            _setWarriorData(warriorsData, warriors[_warriorIds[i]], i * stepSize);
        }
    }
    
     
    function getWarriorsFromIndex(uint32 indexFrom, uint32 count) external view returns (uint256[] memory warriorsData, uint32 stepSize) {
        stepSize = 6;
         
        uint256 lenght = (warriors.length - indexFrom >= count ? count : warriors.length - indexFrom);
        
        warriorsData = new uint256[](lenght * stepSize);
        for(uint32 i = 0; i < lenght; i ++) {
            _setWarriorData(warriorsData, warriors[indexFrom + i], i * stepSize);
        }
    }
    
    function getWarriorOwners(uint32[] _warriorIds) external view returns (address[] memory owners) {
        uint256 lenght = _warriorIds.length;
        owners = new address[](lenght);
        
        for(uint256 i = 0; i < lenght; i ++) {
            owners[i] = warriorToOwner[_warriorIds[i]];
        }
    }
    
    
    function _setWarriorData(uint256[] memory warriorsData, DataTypes.Warrior storage warrior, uint32 id) internal view {
        warriorsData[id] = uint256(warrior.identity); 
        warriorsData[id + 1] = uint256(warrior.cooldownEndBlock); 
        warriorsData[id + 2] = uint256(warrior.level); 
        warriorsData[id + 3] = uint256(warrior.rating); 
        warriorsData[id + 4] = uint256(warrior.action); 
        warriorsData[id + 5] = uint256(warrior.dungeonIndex); 
    }
    
	function getWarrior(uint256 _id) external view returns 
    (
        uint256 identity, 
        uint256 cooldownEndBlock, 
        uint256 level,
        uint256 rating, 
        uint256 action,
        uint256 dungeonIndex
    ) {
        DataTypes.Warrior storage warrior = warriors[_id];

        identity = uint256(warrior.identity);
        cooldownEndBlock = uint256(warrior.cooldownEndBlock);
        level = uint256(warrior.level);
		rating = uint256(warrior.rating);
		action = uint256(warrior.action);
		dungeonIndex = uint256(warrior.dungeonIndex);
    }
    
}


contract PVP is Pausable, PVPInterface {
	 
	
     
    uint256[100] public pvpQueue;
     
     
    uint256 public pvpQueueSize = 0;
    
     
     
     
    mapping (address => uint256) public ownerToBooty;
    
     
    mapping (uint256 => address) internal warriorToOwner;
    
     
    uint256 internal secondsPerBlock = 15;
    
     
     
    uint256 public pvpOwnerCut;
    
     
     
     
    uint256 public pvpMaxIncentiveCut;
    
     
     
    uint256 internal pvpBattleFee = 20 finney;
    
    uint256 public constant PVP_INTERVAL = 15 minutes;
    
    uint256 public nextPVPBatleBlock = 0;
     
    uint256 public totalBooty = 0;
    
     
    uint256 public constant FUND_GATHERING_TIME = 24 hours;
    uint256 public constant ADMISSION_TIME = 12 hours;
    uint256 public constant RATING_EXPAND_INTERVAL = 1 hours;
    uint256 internal constant SAFETY_GAP = 5;
    
    uint256 internal constant MAX_INCENTIVE_REWARD = 200 finney;
    
     
    uint256 public tournamentQueueSize = 0;
    
     
    uint256 public tournamentBankCut;
    
    
    uint256 public tournamentEndBlock;
    
     
    uint256 public currentTournamentBank = 0;
    uint256 public nextTournamentBank = 0;
    
    PVPListenerInterface internal pvpListener;
    
     
     
    event TournamentScheduled(uint256 tournamentEndBlock);
    
     
    event PVPScheduled(uint256 nextPVPBatleBlock);
    
     
    event PVPNewContender(address owner, uint256 warriorId, uint256 entranceFee);

     
    event PVPFinished(uint256[] warriorsData, address[] owners, uint256 matchingCount);
    
     
    event BootySendFailed(address recipient, uint256 amount);
    
     
    event BootyGrabbed(address receiver, uint256 amount);
    
     
    event PVPContenderRemoved(uint256 warriorId, address owner);
    
    function PVP(uint256 _pvpCut, uint256 _tournamentBankCut, uint256 _pvpMaxIncentiveCut) public {
        require((_tournamentBankCut + _pvpCut + _pvpMaxIncentiveCut) <= 10000);
		pvpOwnerCut = _pvpCut;
		tournamentBankCut = _tournamentBankCut;
		pvpMaxIncentiveCut = _pvpMaxIncentiveCut;
    }
    
     
    function grabBooty() external {
        uint256 booty = ownerToBooty[msg.sender];
        require(booty > 0);
        require(totalBooty >= booty);
        
        ownerToBooty[msg.sender] = 0;
        totalBooty -= booty;
        
        msg.sender.transfer(booty);
         
        BootyGrabbed(msg.sender, booty);
    }
    
    function safeSend(address _recipient, uint256 _amaunt) internal {
		uint256 failedBooty = sendBooty(_recipient, _amaunt);
        if (failedBooty > 0) {
			totalBooty += failedBooty;
        }
    }
    
    function sendBooty(address _recipient, uint256 _amaunt) internal returns(uint256) {
        bool success = _recipient.send(_amaunt);
        if (!success && _amaunt > 0) {
            ownerToBooty[_recipient] += _amaunt;
            BootySendFailed(_recipient, _amaunt);
            return _amaunt;
        }
        return 0;
    }
    
     
    function getTournamentAdmissionBlock() public view returns(uint256) {
        uint256 admissionInterval = (ADMISSION_TIME / secondsPerBlock);
        return tournamentEndBlock < admissionInterval ? 0 : tournamentEndBlock - admissionInterval;
    }
    
    
     
    function _scheduleTournament() internal {
         
         
		if (tournamentQueueSize == 0 && tournamentEndBlock <= block.number) {
		    tournamentEndBlock = ((FUND_GATHERING_TIME / 2 + ADMISSION_TIME) / secondsPerBlock) + block.number;
		    TournamentScheduled(tournamentEndBlock);
		}
    }
    
     
     
    function setPVPEntranceFee(uint256 value) external onlyOwner {
        require(pvpQueueSize == 0);
        pvpBattleFee = value;
    }
    
     
     
    function getPVPEntranceFee(uint256 _levelPoints) external view returns(uint256) {
        return pvpBattleFee * CryptoUtils._getLevel(_levelPoints);
    }
    
     
    function _getPVPFeeByLevel(uint256 _level) internal view returns(uint256) {
        return pvpBattleFee * _level;
    }
    
	 
     
    function _computePVPReward(uint256 _totalBet, uint256 _contendersCut) internal pure returns (uint256){
         
         
         
         
         
        return _totalBet * _contendersCut / 10000;
    }
    
    function _getPVPContendersCut(uint256 _incentiveCut) internal view returns (uint256) {
         
         
         
         
        return (10000 - pvpOwnerCut - tournamentBankCut - _incentiveCut);
    }
	
	 
     
    function _computeIncentiveReward(uint256 _totalSessionLoot, uint256 _incentiveCut) internal pure returns (uint256){
         
         
         
         
         
        return _totalSessionLoot * _incentiveCut / 10000;
    }
    
	 
	 
	 
	 
	 
     
     
    function _computeIncentiveCut(uint256 _totalSessionLoot, uint256 maxIncentiveCut) internal pure returns(uint256) {
        uint256 result = _totalSessionLoot * maxIncentiveCut / 10000;
        result = result <= MAX_INCENTIVE_REWARD ? maxIncentiveCut : MAX_INCENTIVE_REWARD * 10000 / _totalSessionLoot;
         
        return result > 0 ? result : 1;
    }
    
     
     
    function _computePVPBeneficiaryFee(uint256 _totalSessionLoot) internal view returns (uint256){
         
         
         
         
         
        return _totalSessionLoot * pvpOwnerCut / 10000;
    }
    
     
     
    function _computeTournamentCut(uint256 _totalSessionLoot) internal view returns (uint256){
         
         
         
         
         
        return _totalSessionLoot * tournamentBankCut / 10000;
    }

    function indexOf(uint256 _warriorId) internal view returns(int256) {
	    uint256 length = uint256(pvpQueueSize);
	    for(uint256 i = 0; i < length; i ++) {
	        if(CryptoUtils._unpackIdValue(pvpQueue[i]) == _warriorId) return int256(i);
	    }
	    return -1;
	}
    
    function getPVPIncentiveReward(uint256[] memory matchingIds, uint256 matchingCount) internal view returns(uint256) {
        uint256 sessionLoot = _computeTotalBooty(matchingIds, matchingCount);
        
        return _computeIncentiveReward(sessionLoot, _computeIncentiveCut(sessionLoot, pvpMaxIncentiveCut));
    }
    
    function maxPVPContenders() external view returns(uint256){
        return pvpQueue.length;
    }
    
    function getPVPState() external view returns
    (uint256 contendersCount, uint256 matchingCount, uint256 endBlock, uint256 incentiveReward)
    {
        uint256[] memory pvpData = _packPVPData();
        
    	contendersCount = pvpQueueSize;
    	matchingCount = CryptoUtils._getMatchingIds(pvpData, PVP_INTERVAL, _computeCycleSkip(), RATING_EXPAND_INTERVAL);
    	endBlock = nextPVPBatleBlock;   
    	incentiveReward = getPVPIncentiveReward(pvpData, matchingCount);
    }
    
    function canFinishPVP() external view returns(bool) {
        return nextPVPBatleBlock <= block.number &&
         CryptoUtils._getMatchingIds(_packPVPData(), PVP_INTERVAL, _computeCycleSkip(), RATING_EXPAND_INTERVAL) > 1;
    }
    
    function _clarifyPVPSchedule() internal {
        uint256 length = pvpQueueSize;
		uint256 currentBlock = block.number;
		uint256 nextBattleBlock = nextPVPBatleBlock;
		 
		if (nextBattleBlock <= currentBlock) {
		     
		    if (length > 0) {
				uint256 packedWarrior;
				uint256 cycleSkip = _computeCycleSkip();
		        for(uint256 i = 0; i < length; i++) {
		            packedWarrior = pvpQueue[i];
		             
		            pvpQueue[i] = CryptoUtils._changeCycleValue(packedWarrior, CryptoUtils._unpackCycleValue(packedWarrior) + cycleSkip);
		        }
		    }
		    nextBattleBlock = (PVP_INTERVAL / secondsPerBlock) + currentBlock;
		    nextPVPBatleBlock = nextBattleBlock;
		    PVPScheduled(nextBattleBlock);
		 
		} else if (length + 1 == pvpQueue.length && (currentBlock + SAFETY_GAP * 2) < nextBattleBlock) {
		    nextBattleBlock = currentBlock + SAFETY_GAP;
		    nextPVPBatleBlock = nextBattleBlock;
		    PVPScheduled(nextBattleBlock);
		}
    }
    
     
     
    function _triggerNewPVPContender(address _owner, uint256 _packedWarrior, uint256 fee) internal {

		_clarifyPVPSchedule();
         
         
        _packedWarrior = CryptoUtils._changeCycleValue(_packedWarrior, 0);
		
		 
		pvpQueue[pvpQueueSize++] = _packedWarrior;
		warriorToOwner[CryptoUtils._unpackIdValue(_packedWarrior)] = _owner;
		
		 
		PVPNewContender(_owner, CryptoUtils._unpackIdValue(_packedWarrior), fee);
    }
    
    function _noMatchingPairs() internal view returns(bool) {
        uint256 matchingCount = CryptoUtils._getMatchingIds(_packPVPData(), uint64(PVP_INTERVAL), _computeCycleSkip(), uint64(RATING_EXPAND_INTERVAL));
        return matchingCount == 0;
    }
    
     
    function addPVPContender(address _owner, uint256 _packedWarrior) external payable whenNotPaused {
		 
        require(msg.sender == address(pvpListener));

        require(_owner != address(0));
         
         
        require(nextPVPBatleBlock > block.number || _noMatchingPairs());
         
        require(_packedWarrior != 0);
         
        require(ownerToBooty[_owner] == 0);
         
        require(pvpQueueSize < pvpQueue.length);
         
        uint256 fee = _getPVPFeeByLevel(CryptoUtils._unpackLevelValue(_packedWarrior));
        require(msg.value >= fee);
         
         
        _triggerNewPVPContender(_owner, _packedWarrior, fee);
    }
    
    function _packPVPData() internal view returns(uint256[] memory matchingIds) {
        uint256 length = pvpQueueSize;
        matchingIds = new uint256[](length);
        for(uint256 i = 0; i < length; i++) {
            matchingIds[i] = pvpQueue[i];
        }
        return matchingIds;
    }
    
    function _computeTotalBooty(uint256[] memory _packedWarriors, uint256 matchingCount) internal view returns(uint256) {
         
        uint256 sessionLoot = 0;
        for(uint256 i = 0; i < matchingCount; i++) {
            sessionLoot += _getPVPFeeByLevel(CryptoUtils._unpackLevelValue(_packedWarriors[i]));
        }
        return sessionLoot;
    }
    
    function _grandPVPRewards(uint256[] memory _packedWarriors, uint256 matchingCount) 
    internal returns(uint256)
    {
        uint256 booty = 0;
        uint256 packedWarrior;
        uint256 failedBooty = 0;
        
        uint256 sessionBooty = _computeTotalBooty(_packedWarriors, matchingCount);
        uint256 incentiveCut = _computeIncentiveCut(sessionBooty, pvpMaxIncentiveCut);
        uint256 contendersCut = _getPVPContendersCut(incentiveCut);
        
        for(uint256 id = 0; id < matchingCount; id++) {
             
			 
			packedWarrior = _packedWarriors[id];
			 
			 
			 
			booty = _getPVPFeeByLevel(CryptoUtils._unpackLevelValue(packedWarrior)) + 
				_getPVPFeeByLevel(CryptoUtils._unpackLevelValue(_packedWarriors[id + 1]));
			
			 
			 
			failedBooty += sendBooty(warriorToOwner[CryptoUtils._unpackIdValue(packedWarrior)], _computePVPReward(booty, contendersCut));
			 
			 
			id ++;
        }
        failedBooty += sendBooty(pvpListener.getBeneficiary(), _computePVPBeneficiaryFee(sessionBooty));
        
        if (failedBooty > 0) {
            totalBooty += failedBooty;
        }
         
         
         
        if (getTournamentAdmissionBlock() > block.number) {
            currentTournamentBank += _computeTournamentCut(sessionBooty);
        } else {
            nextTournamentBank += _computeTournamentCut(sessionBooty);
        }
        
         
        return _computeIncentiveReward(sessionBooty, incentiveCut);
    }
    
    function _increaseCycleAndTrimQueue(uint256[] memory matchingIds, uint256 matchingCount) internal {
        uint32 length = uint32(matchingIds.length - matchingCount);  
		uint256 packedWarrior;
		uint256 skipCycles = _computeCycleSkip();
        for(uint256 i = 0; i < length; i++) {
            packedWarrior = matchingIds[matchingCount + i];
             
            pvpQueue[i] = CryptoUtils._changeCycleValue(packedWarrior, CryptoUtils._unpackCycleValue(packedWarrior) + skipCycles);
        }
         
        pvpQueueSize = length;
    }
    
    function _computeCycleSkip() internal view returns(uint256) {
        uint256 number = block.number;
        return nextPVPBatleBlock > number ? 0 : (number - nextPVPBatleBlock) * secondsPerBlock / PVP_INTERVAL + 1;
    }
    
    function _getWarriorOwners(uint256[] memory pvpData) internal view returns (address[] memory owners){
        uint256 length = pvpData.length;
        owners = new address[](length);
        for(uint256 i = 0; i < length; i ++) {
            owners[i] = warriorToOwner[CryptoUtils._unpackIdValue(pvpData[i])];
        }
    }
    
     
     
    function _triggerPVPFinish(uint256[] memory pvpData, uint256 matchingCount) internal returns(uint256){
         
		 
        CryptoUtils._getPVPBattleResults(pvpData, matchingCount, nextPVPBatleBlock);
         
         
        _increaseCycleAndTrimQueue(pvpData, matchingCount);
         
         
        nextPVPBatleBlock = (PVP_INTERVAL / secondsPerBlock) + block.number;
        
         
         
         
         
        _scheduleTournament();
         
         
         
        uint256 incentiveReward = _grandPVPRewards(pvpData, matchingCount);
         
         
        pvpListener.pvpFinished(pvpData, matchingCount);
        
         
         
		PVPFinished(pvpData, _getWarriorOwners(pvpData), matchingCount);
        PVPScheduled(nextPVPBatleBlock);
		
		return incentiveReward;
    }
    
    
     
    function finishPVP() public whenNotPaused {
         
        require(nextPVPBatleBlock <= block.number);
         
	     
        uint256[] memory pvpData = _packPVPData();
         
        uint256 matchingCount = CryptoUtils._getMatchingIds(pvpData, uint64(PVP_INTERVAL), _computeCycleSkip(), uint64(RATING_EXPAND_INTERVAL));
		 
        require(matchingCount > 1);
        
         
        uint256 incentiveReward = _triggerPVPFinish(pvpData, matchingCount);
        
         
        safeSend(msg.sender, incentiveReward);
    }

     
     
     
     
     
    function removePVPContender(uint32 _warriorId) external{
        uint256 queueSize = pvpQueueSize;
        require(queueSize > 0);
         
        require(warriorToOwner[_warriorId] == msg.sender);
         
        int256 warriorIndex = indexOf(_warriorId);
        require(warriorIndex >= 0);
         
        uint256 warriorData = pvpQueue[uint32(warriorIndex)];
         
        require((CryptoUtils._unpackCycleValue(warriorData) + _computeCycleSkip()) >= 4);
        
         
        if (uint256(warriorIndex) < queueSize - 1) {
	        pvpQueue[uint32(warriorIndex)] = pvpQueue[pvpQueueSize - 1];
        }
        pvpQueueSize --;
         
        pvpListener.pvpContenderRemoved(_warriorId);
         
        msg.sender.transfer(_getPVPFeeByLevel(CryptoUtils._unpackLevelValue(warriorData)));
         
        PVPContenderRemoved(_warriorId, msg.sender);
    }
    
    function getPVPCycles(uint32[] warriorIds) external view returns(uint32[]){
        uint256 length = warriorIds.length;
        uint32[] memory cycles = new uint32[](length);
        int256 index;
        uint256 skipCycles = _computeCycleSkip();
	    for(uint256 i = 0; i < length; i ++) {
	        index = indexOf(warriorIds[i]);
	        cycles[i] = index >= 0 ? uint32(CryptoUtils._unpackCycleValue(pvpQueue[uint32(index)]) + skipCycles) : 0;
	    }
	    return cycles;
    }
    
     
     
     
    function removeAllPVPContenders() external onlyOwner whenPaused {
         
        uint256 length = pvpQueueSize;
        
        uint256 warriorData;
        uint256 warriorId;
        uint256 failedBooty;
        address owner;
        
        pvpQueueSize = 0;
        
        for(uint256 i = 0; i < length; i++) {
	         
	        warriorData = pvpQueue[i];
	        warriorId = CryptoUtils._unpackIdValue(warriorData);
	         
	        pvpListener.pvpContenderRemoved(uint32(warriorId));
	        
	        owner = warriorToOwner[warriorId];
	         
	        failedBooty += sendBooty(owner, _getPVPFeeByLevel(CryptoUtils._unpackLevelValue(warriorData)));
        }
        totalBooty += failedBooty;
    }
}

contract Tournament is PVP {

    uint256 internal constant GROUP_SIZE = 5;
    uint256 internal constant DATA_SIZE = 2;
    uint256 internal constant THRESHOLD = 300;
    
   
    uint256[160] public tournamentQueue;
    
     
    uint256 internal tournamentEntranceFeeCut = 100;
    
     
    uint256 public tournamentOwnersCut;
    uint256 public tournamentIncentiveCut;
    
      
    event TournamentNewContender(address owner, uint256 warriorIds, uint256 entranceFee);
    
     
    event TournamentFinished(uint256[] owners, uint32[] results, uint256 tournamentBank);
    
    function Tournament(uint256 _pvpCut, uint256 _tournamentBankCut, 
    uint256 _pvpMaxIncentiveCut, uint256 _tournamentOwnersCut, uint256 _tournamentIncentiveCut) public
    PVP(_pvpCut, _tournamentBankCut, _pvpMaxIncentiveCut) 
    {
        require((_tournamentOwnersCut + _tournamentIncentiveCut) <= 10000);
		
		tournamentOwnersCut = _tournamentOwnersCut;
		tournamentIncentiveCut = _tournamentIncentiveCut;
    }
    
    
    
     
     
    function _computeTournamentIncentiveReward(uint256 _currentBank, uint256 _incentiveCut) internal pure returns (uint256){
         
         
         
         
        return _currentBank * _incentiveCut / 10000;
    }
    
    function _computeTournamentContenderCut(uint256 _incentiveCut) internal view returns (uint256) {
         
         
         
        return 10000 - tournamentOwnersCut - _incentiveCut;
    }
    
    function _computeTournamentBeneficiaryFee(uint256 _currentBank) internal view returns (uint256){
         
         
         
         
        return _currentBank * tournamentOwnersCut / 10000;
    }
    
     
     
     
    function setTournamentEntranceFeeCut(uint256 _cut) external onlyOwner {
         
        require(_cut <= 10000);
         
        require(tournamentQueueSize == 0);
         
		tournamentEntranceFeeCut = _cut;
    }
    
    function getTournamentEntranceFee() external view returns(uint256) {
        return currentTournamentBank * tournamentEntranceFeeCut / 10000;
    }
    
     
    function getTournamentThresholdFee() public view returns(uint256) {
        return currentTournamentBank * tournamentEntranceFeeCut * (10000 - THRESHOLD) / 10000 / 10000;
    }
    
     
    function maxTournamentContenders() public view returns(uint256){
        return tournamentQueue.length / DATA_SIZE;
    }
    
    function canFinishTournament() external view returns(bool) {
        return tournamentEndBlock <= block.number && tournamentQueueSize > 0;
    }
    
     
     
    function _triggerNewTournamentContender(address _owner, uint256[] memory _tournamentData, uint256 _fee) internal {
         
        
        currentTournamentBank += _fee;
        
        uint256 packedWarriorIds = CryptoUtils._packWarriorIds(_tournamentData);
         
        uint256 combinedWarrior = CryptoUtils._combineWarriors(_tournamentData);
        
         
         
        uint256 size = tournamentQueueSize++ * DATA_SIZE;
         
		tournamentQueue[size++] = packedWarriorIds;
		tournamentQueue[size++] = combinedWarrior;
		warriorToOwner[CryptoUtils._unpackWarriorId(packedWarriorIds, 0)] = _owner;
		 
		 
		TournamentNewContender(_owner, packedWarriorIds, _fee);
    }
    
    function addTournamentContender(address _owner, uint256[] _tournamentData) external payable whenNotPaused{
         
        require(msg.sender == address(pvpListener));
        
        require(_owner != address(0));
         
         
        require(pvpBattleFee == 0 || currentTournamentBank > 0);
         
         
        uint256 fee = getTournamentThresholdFee();
        require(msg.value >= fee);
         
        require(ownerToBooty[_owner] == 0);
         
         
        require(_tournamentData.length == GROUP_SIZE);
         
         
        require(tournamentQueueSize < maxTournamentContenders());
         
         
        require(block.number >= getTournamentAdmissionBlock());
         
        require(block.number <= tournamentEndBlock);
        
         
        _triggerNewTournamentContender(_owner, _tournamentData, fee);
    }
    
     
    function getCombinedWarriors() internal view returns(uint256[] memory warriorsData) {
        uint256 length = tournamentQueueSize;
        warriorsData = new uint256[](length);
        
        for(uint256 i = 0; i < length; i ++) {
             
            warriorsData[i] = tournamentQueue[i * DATA_SIZE + 1];
        }
        return warriorsData;
    }
    
    function getTournamentState() external view returns
    (uint256 contendersCount, uint256 bank, uint256 admissionStartBlock, uint256 endBlock, uint256 incentiveReward)
    {
    	contendersCount = tournamentQueueSize;
    	bank = currentTournamentBank;
    	admissionStartBlock = getTournamentAdmissionBlock();   
    	endBlock = tournamentEndBlock;
    	incentiveReward = _computeTournamentIncentiveReward(bank, _computeIncentiveCut(bank, tournamentIncentiveCut));
    }
    
    function _repackToCombinedIds(uint256[] memory _warriorsData) internal view {
        uint256 length = _warriorsData.length;
        for(uint256 i = 0; i < length; i ++) {
            _warriorsData[i] = tournamentQueue[i * DATA_SIZE];
        }
    }
    
     
     
    function _computeTournamentBooty(uint256 _currentBank, uint256 _contenderResult, uint256 _totalBattles) internal pure returns (uint256){
         
         
         
         
         
        return _currentBank * _contenderResult / _totalBattles;
        
    }
    
    function _grandTournamentBooty(uint256 _warriorIds, uint256 _currentBank, uint256 _contenderResult, uint256 _totalBattles)
    internal returns (uint256)
    {
        uint256 warriorId = CryptoUtils._unpackWarriorId(_warriorIds, 0);
        address owner = warriorToOwner[warriorId];
        uint256 booty = _computeTournamentBooty(_currentBank, _contenderResult, _totalBattles);
        return sendBooty(owner, booty);
    }
    
    function _grandTournamentRewards(uint256 _currentBank, uint256[] memory _warriorsData, uint32[] memory _results) internal returns (uint256){
        uint256 length = _warriorsData.length;
        uint256 totalBattles = CryptoUtils._getTournamentBattles(length) * 10000; 
        uint256 incentiveCut = _computeIncentiveCut(_currentBank, tournamentIncentiveCut);
        uint256 contenderCut = _computeTournamentContenderCut(incentiveCut);
        
        uint256 failedBooty = 0;
        for(uint256 i = 0; i < length; i ++) {
             
            failedBooty += _grandTournamentBooty(_warriorsData[i], _currentBank, _results[i] * contenderCut, totalBattles);
        }
         
        failedBooty += sendBooty(pvpListener.getBeneficiary(), _computeTournamentBeneficiaryFee(_currentBank));
        if (failedBooty > 0) {
            totalBooty += failedBooty;
        }
        return _computeTournamentIncentiveReward(_currentBank, incentiveCut);
    }
    
    function _repackToWarriorOwners(uint256[] memory warriorsData) internal view {
        uint256 length = warriorsData.length;
        for (uint256 i = 0; i < length; i ++) {
            warriorsData[i] = uint256(warriorToOwner[CryptoUtils._unpackWarriorId(warriorsData[i], 0)]);
        }
    }
    
    function _triggerFinishTournament() internal returns(uint256){
         
        uint256[] memory warriorsData = getCombinedWarriors();
        uint32[] memory results = CryptoUtils.getTournamentBattleResults(warriorsData, tournamentEndBlock - 1);
         
        _repackToCombinedIds(warriorsData);
         
        pvpListener.tournamentFinished(warriorsData);
         
         
        tournamentQueueSize = 0;
         
        _scheduleTournament();
        
        uint256 currentBank = currentTournamentBank;
        currentTournamentBank = 0; 
         
         
         
        uint256 incentiveReward = _grandTournamentRewards(currentBank, warriorsData, results);
        
        currentTournamentBank = nextTournamentBank;
        nextTournamentBank = 0;
        
        _repackToWarriorOwners(warriorsData);
        
         
        TournamentFinished(warriorsData, results, currentBank);

        return incentiveReward;
    }
    
    function finishTournament() external whenNotPaused {
         
         
        require(tournamentEndBlock <= block.number);
         
        require(tournamentQueueSize > 0);
        
        uint256 incentiveReward = _triggerFinishTournament();
        
         
        safeSend(msg.sender, incentiveReward);
    }
    
    
     
     
     
    function removeAllTournamentContenders() external onlyOwner whenPaused {
         
        uint256 length = tournamentQueueSize;
        
        uint256 warriorId;
        uint256 failedBooty;
        uint256 i;

        uint256 fee;
        uint256 bank = currentTournamentBank;
        
        uint256[] memory warriorsData = new uint256[](length);
         
        for(i = 0; i < length; i ++) {
            warriorsData[i] = tournamentQueue[i * DATA_SIZE];
        }
         
        pvpListener.tournamentFinished(warriorsData);
         
     	currentTournamentBank = 0;
        tournamentQueueSize = 0;

        for(i = length - 1; i >= 0; i --) {
             
            warriorId = CryptoUtils._unpackWarriorId(warriorsData[i], 0);
             
			fee = bank - (bank * 10000 / (tournamentEntranceFeeCut * (10000 - THRESHOLD) / 10000 + 10000));
			 
	        failedBooty += sendBooty(warriorToOwner[warriorId], fee);
	         
	        bank -= fee;
        }
        currentTournamentBank = bank;
        totalBooty += failedBooty;
    }
}

contract BattleProvider is Tournament {
    
    function BattleProvider(address _pvpListener, uint256 _pvpCut, uint256 _tournamentCut, uint256 _incentiveCut, 
    uint256 _tournamentOwnersCut, uint256 _tournamentIncentiveCut) public 
    Tournament(_pvpCut, _tournamentCut, _incentiveCut, _tournamentOwnersCut, _tournamentIncentiveCut) 
    {
        PVPListenerInterface candidateContract = PVPListenerInterface(_pvpListener);
         
        require(candidateContract.isPVPListener());
         
        pvpListener = candidateContract;
        
        paused = true;

         
        owner = msg.sender;
    }
    
    
     
     
    function isPVPProvider() external pure returns (bool) {
        return true;
    }
    
     
     
     
     
    function unpause() public onlyOwner whenPaused {
        require(address(pvpListener) != address(0));

         
        super.unpause();
    }
    
    function setSecondsPerBlock(uint256 secs) external onlyOwner {
        secondsPerBlock = secs;
    }
}

library CryptoUtils {
   
     
    uint256 internal constant WARRIOR = 0;
    uint256 internal constant ARCHER = 1;
    uint256 internal constant MAGE = 2;
     
    uint256 internal constant COMMON = 1;
    uint256 internal constant UNCOMMON = 2;
    uint256 internal constant RARE = 3;
    uint256 internal constant MYTHIC = 4;
    uint256 internal constant LEGENDARY = 5;
    uint256 internal constant UNIQUE = 6;
     
    uint256 internal constant CLASS_MECHANICS_MAX = 3;
    uint256 internal constant RARITY_MAX = 6;
     
    uint256 internal constant RARITY_CHANCE_RANGE = 10000000;
    uint256 internal constant POINTS_TO_LEVEL = 10;
     
     
    uint256 internal constant UNIQUE_MASK_0 = 1;
     
    uint256 internal constant RARITY_MASK_1 = UNIQUE_MASK_0 * 10000;
     
    uint256 internal constant CLASS_VIEW_MASK_2 = RARITY_MASK_1 * 10;
     
    uint256 internal constant BODY_COLOR_MASK_3 = CLASS_VIEW_MASK_2 * 1000;
     
    uint256 internal constant EYES_MASK_4 = BODY_COLOR_MASK_3 * 1000;
     
    uint256 internal constant MOUTH_MASK_5 = EYES_MASK_4 * 1000;
     
    uint256 internal constant HEIR_MASK_6 = MOUTH_MASK_5 * 1000;
     
    uint256 internal constant HEIR_COLOR_MASK_7 = HEIR_MASK_6 * 1000;
     
    uint256 internal constant ARMOR_MASK_8 = HEIR_COLOR_MASK_7 * 1000;
     
    uint256 internal constant WEAPON_MASK_9 = ARMOR_MASK_8 * 1000;
     
    uint256 internal constant HAT_MASK_10 = WEAPON_MASK_9 * 1000;
     
    uint256 internal constant RUNES_MASK_11 = HAT_MASK_10 * 1000;
     
    uint256 internal constant WINGS_MASK_12 = RUNES_MASK_11 * 100;
     
    uint256 internal constant PET_MASK_13 = WINGS_MASK_12 * 100;
     
    uint256 internal constant BORDER_MASK_14 = PET_MASK_13 * 100;
     
    uint256 internal constant BACKGROUND_MASK_15 = BORDER_MASK_14 * 100;
     
    uint256 internal constant INTELLIGENCE_MASK_16 = BACKGROUND_MASK_15 * 100;
     
    uint256 internal constant AGILITY_MASK_17 = INTELLIGENCE_MASK_16 * 100;
     
    uint256 internal constant STRENGTH_MASK_18 = AGILITY_MASK_17 * 100;
     
    uint256 internal constant CLASS_MECH_MASK_19 = STRENGTH_MASK_18 * 100;
     
    uint256 internal constant RARITY_BONUS_MASK_20 = CLASS_MECH_MASK_19 * 10;
     
    uint256 internal constant SPECIALITY_MASK_21 = RARITY_BONUS_MASK_20 * 1000;
     
    uint256 internal constant DAMAGE_MASK_22 = SPECIALITY_MASK_21 * 10;
     
    uint256 internal constant AURA_MASK_23 = DAMAGE_MASK_22 * 100;
     
    uint256 internal constant BASE_MASK_24 = AURA_MASK_23 * 100;
    
    
     
    uint256 internal constant MINER_PERK = 1;
    
    
     
    uint256 internal constant BODY_COLOR_MAX_INDEX_0 = 0;
    uint256 internal constant EYES_MAX_INDEX_1 = 1;
    uint256 internal constant MOUTH_MAX_2 = 2;
    uint256 internal constant HAIR_MAX_3 = 3;
    uint256 internal constant HEIR_COLOR_MAX_4 = 4;
    uint256 internal constant ARMOR_MAX_5 = 5;
    uint256 internal constant WEAPON_MAX_6 = 6;
    uint256 internal constant HAT_MAX_7 = 7;
    uint256 internal constant RUNES_MAX_8 = 8;
    uint256 internal constant WINGS_MAX_9 = 9;
    uint256 internal constant PET_MAX_10 = 10;
    uint256 internal constant BORDER_MAX_11 = 11;
    uint256 internal constant BACKGROUND_MAX_12 = 12;
    uint256 internal constant UNIQUE_INDEX_13 = 13;
    uint256 internal constant LEGENDARY_INDEX_14 = 14;
    uint256 internal constant MYTHIC_INDEX_15 = 15;
    uint256 internal constant RARE_INDEX_16 = 16;
    uint256 internal constant UNCOMMON_INDEX_17 = 17;
    uint256 internal constant UNIQUE_TOTAL_INDEX_18 = 18;
    
      
     
    uint256 internal constant CLASS_PACK_0 = 1;
    uint256 internal constant RARITY_BONUS_PACK_1 = CLASS_PACK_0 * 10;
    uint256 internal constant RARITY_PACK_2 = RARITY_BONUS_PACK_1 * 1000;
    uint256 internal constant EXPERIENCE_PACK_3 = RARITY_PACK_2 * 10;
    uint256 internal constant INTELLIGENCE_PACK_4 = EXPERIENCE_PACK_3 * 1000;
    uint256 internal constant AGILITY_PACK_5 = INTELLIGENCE_PACK_4 * 100;
    uint256 internal constant STRENGTH_PACK_6 = AGILITY_PACK_5 * 100;
    uint256 internal constant BASE_DAMAGE_PACK_7 = STRENGTH_PACK_6 * 100;
    uint256 internal constant PET_PACK_8 = BASE_DAMAGE_PACK_7 * 100;
    uint256 internal constant AURA_PACK_9 = PET_PACK_8 * 100;
    uint256 internal constant WARRIOR_ID_PACK_10 = AURA_PACK_9 * 100;
    uint256 internal constant PVP_CYCLE_PACK_11 = WARRIOR_ID_PACK_10 * 10**10;
    uint256 internal constant RATING_PACK_12 = PVP_CYCLE_PACK_11 * 10**10;
    uint256 internal constant PVP_BASE_PACK_13 = RATING_PACK_12 * 10**10; 
    
     
    uint256 internal constant HP_PACK_0 = 1;
    uint256 internal constant DAMAGE_PACK_1 = HP_PACK_0 * 10**12;
    uint256 internal constant ARMOR_PACK_2 = DAMAGE_PACK_1 * 10**12;
    uint256 internal constant DODGE_PACK_3 = ARMOR_PACK_2 * 10**12;
    uint256 internal constant PENETRATION_PACK_4 = DODGE_PACK_3 * 10**12;
    uint256 internal constant COMBINE_BASE_PACK_5 = PENETRATION_PACK_4 * 10**12;
    
     
    uint256 internal constant MAX_ID_SIZE = 10000000000;
    int256 internal constant PRECISION = 1000000;
    
    uint256 internal constant BATTLES_PER_CONTENDER = 10; 
    uint256 internal constant BATTLES_PER_CONTENDER_SUM = BATTLES_PER_CONTENDER * 100; 
    
    uint256 internal constant LEVEL_BONUSES = 98898174676155504541373431282523211917151413121110;
    
     
    uint256 internal constant BONUS_NONE = 0;
    uint256 internal constant BONUS_HP = 1;
    uint256 internal constant BONUS_ARMOR = 2;
    uint256 internal constant BONUS_CRIT_CHANCE = 3;
    uint256 internal constant BONUS_CRIT_MULT = 4;
    uint256 internal constant BONUS_PENETRATION = 5;
     
    uint256 internal constant BONUS_STR = 6;
    uint256 internal constant BONUS_AGI = 7;
    uint256 internal constant BONUS_INT = 8;
    uint256 internal constant BONUS_DAMAGE = 9;
    
     
    uint256 internal constant BONUS_DATA = 16060606140107152000;
     
    uint256 internal constant PETS_DATA = 287164235573728325842459981692000;
    
    uint256 internal constant PET_AURA = 2;
    uint256 internal constant PET_PARAM_1 = 1;
    uint256 internal constant PET_PARAM_2 = 0;

     
	function getUniqueValue(uint256 identity) internal pure returns(uint256){
		return identity % RARITY_MASK_1;
	}

    function getRarityValue(uint256 identity) internal pure returns(uint256){
        return (identity % CLASS_VIEW_MASK_2) / RARITY_MASK_1;
    }

	function getClassViewValue(uint256 identity) internal pure returns(uint256){
		return (identity % BODY_COLOR_MASK_3) / CLASS_VIEW_MASK_2;
	}

	function getBodyColorValue(uint256 identity) internal pure returns(uint256){
        return (identity % EYES_MASK_4) / BODY_COLOR_MASK_3;
    }

    function getEyesValue(uint256 identity) internal pure returns(uint256){
        return (identity % MOUTH_MASK_5) / EYES_MASK_4;
    }

    function getMouthValue(uint256 identity) internal pure returns(uint256){
        return (identity % HEIR_MASK_6) / MOUTH_MASK_5;
    }

    function getHairValue(uint256 identity) internal pure returns(uint256){
        return (identity % HEIR_COLOR_MASK_7) / HEIR_MASK_6;
    }

    function getHairColorValue(uint256 identity) internal pure returns(uint256){
        return (identity % ARMOR_MASK_8) / HEIR_COLOR_MASK_7;
    }

    function getArmorValue(uint256 identity) internal pure returns(uint256){
        return (identity % WEAPON_MASK_9) / ARMOR_MASK_8;
    }

    function getWeaponValue(uint256 identity) internal pure returns(uint256){
        return (identity % HAT_MASK_10) / WEAPON_MASK_9;
    }

    function getHatValue(uint256 identity) internal pure returns(uint256){
        return (identity % RUNES_MASK_11) / HAT_MASK_10;
    }

    function getRunesValue(uint256 identity) internal pure returns(uint256){
        return (identity % WINGS_MASK_12) / RUNES_MASK_11;
    }

    function getWingsValue(uint256 identity) internal pure returns(uint256){
        return (identity % PET_MASK_13) / WINGS_MASK_12;
    }

    function getPetValue(uint256 identity) internal pure returns(uint256){
        return (identity % BORDER_MASK_14) / PET_MASK_13;
    }

	function getBorderValue(uint256 identity) internal pure returns(uint256){
		return (identity % BACKGROUND_MASK_15) / BORDER_MASK_14;
	}

	function getBackgroundValue(uint256 identity) internal pure returns(uint256){
		return (identity % INTELLIGENCE_MASK_16) / BACKGROUND_MASK_15;
	}

    function getIntelligenceValue(uint256 identity) internal pure returns(uint256){
        return (identity % AGILITY_MASK_17) / INTELLIGENCE_MASK_16;
    }

    function getAgilityValue(uint256 identity) internal pure returns(uint256){
        return ((identity % STRENGTH_MASK_18) / AGILITY_MASK_17);
    }

    function getStrengthValue(uint256 identity) internal pure returns(uint256){
        return ((identity % CLASS_MECH_MASK_19) / STRENGTH_MASK_18);
    }

    function getClassMechValue(uint256 identity) internal pure returns(uint256){
        return (identity % RARITY_BONUS_MASK_20) / CLASS_MECH_MASK_19;
    }

    function getRarityBonusValue(uint256 identity) internal pure returns(uint256){
        return (identity % SPECIALITY_MASK_21) / RARITY_BONUS_MASK_20;
    }

    function getSpecialityValue(uint256 identity) internal pure returns(uint256){
        return (identity % DAMAGE_MASK_22) / SPECIALITY_MASK_21;
    }
    
    function getDamageValue(uint256 identity) internal pure returns(uint256){
        return (identity % AURA_MASK_23) / DAMAGE_MASK_22;
    }

    function getAuraValue(uint256 identity) internal pure returns(uint256){
        return ((identity % BASE_MASK_24) / AURA_MASK_23);
    }

     
    function _setUniqueValue0(uint256 value) internal pure returns(uint256){
        require(value < RARITY_MASK_1);
        return value * UNIQUE_MASK_0;
    }

    function _setRarityValue1(uint256 value) internal pure returns(uint256){
        require(value < (CLASS_VIEW_MASK_2 / RARITY_MASK_1));
        return value * RARITY_MASK_1;
    }

    function _setClassViewValue2(uint256 value) internal pure returns(uint256){
        require(value < (BODY_COLOR_MASK_3 / CLASS_VIEW_MASK_2));
        return value * CLASS_VIEW_MASK_2;
    }

    function _setBodyColorValue3(uint256 value) internal pure returns(uint256){
        require(value < (EYES_MASK_4 / BODY_COLOR_MASK_3));
        return value * BODY_COLOR_MASK_3;
    }

    function _setEyesValue4(uint256 value) internal pure returns(uint256){
        require(value < (MOUTH_MASK_5 / EYES_MASK_4));
        return value * EYES_MASK_4;
    }

    function _setMouthValue5(uint256 value) internal pure returns(uint256){
        require(value < (HEIR_MASK_6 / MOUTH_MASK_5));
        return value * MOUTH_MASK_5;
    }

    function _setHairValue6(uint256 value) internal pure returns(uint256){
        require(value < (HEIR_COLOR_MASK_7 / HEIR_MASK_6));
        return value * HEIR_MASK_6;
    }

    function _setHairColorValue7(uint256 value) internal pure returns(uint256){
        require(value < (ARMOR_MASK_8 / HEIR_COLOR_MASK_7));
        return value * HEIR_COLOR_MASK_7;
    }

    function _setArmorValue8(uint256 value) internal pure returns(uint256){
        require(value < (WEAPON_MASK_9 / ARMOR_MASK_8));
        return value * ARMOR_MASK_8;
    }

    function _setWeaponValue9(uint256 value) internal pure returns(uint256){
        require(value < (HAT_MASK_10 / WEAPON_MASK_9));
        return value * WEAPON_MASK_9;
    }

    function _setHatValue10(uint256 value) internal pure returns(uint256){
        require(value < (RUNES_MASK_11 / HAT_MASK_10));
        return value * HAT_MASK_10;
    }

    function _setRunesValue11(uint256 value) internal pure returns(uint256){
        require(value < (WINGS_MASK_12 / RUNES_MASK_11));
        return value * RUNES_MASK_11;
    }

    function _setWingsValue12(uint256 value) internal pure returns(uint256){
        require(value < (PET_MASK_13 / WINGS_MASK_12));
        return value * WINGS_MASK_12;
    }

    function _setPetValue13(uint256 value) internal pure returns(uint256){
        require(value < (BORDER_MASK_14 / PET_MASK_13));
        return value * PET_MASK_13;
    }

    function _setBorderValue14(uint256 value) internal pure returns(uint256){
        require(value < (BACKGROUND_MASK_15 / BORDER_MASK_14));
        return value * BORDER_MASK_14;
    }

    function _setBackgroundValue15(uint256 value) internal pure returns(uint256){
        require(value < (INTELLIGENCE_MASK_16 / BACKGROUND_MASK_15));
        return value * BACKGROUND_MASK_15;
    }

    function _setIntelligenceValue16(uint256 value) internal pure returns(uint256){
        require(value < (AGILITY_MASK_17 / INTELLIGENCE_MASK_16));
        return value * INTELLIGENCE_MASK_16;
    }

    function _setAgilityValue17(uint256 value) internal pure returns(uint256){
        require(value < (STRENGTH_MASK_18 / AGILITY_MASK_17));
        return value * AGILITY_MASK_17;
    }

    function _setStrengthValue18(uint256 value) internal pure returns(uint256){
        require(value < (CLASS_MECH_MASK_19 / STRENGTH_MASK_18));
        return value * STRENGTH_MASK_18;
    }

    function _setClassMechValue19(uint256 value) internal pure returns(uint256){
        require(value < (RARITY_BONUS_MASK_20 / CLASS_MECH_MASK_19));
        return value * CLASS_MECH_MASK_19;
    }

    function _setRarityBonusValue20(uint256 value) internal pure returns(uint256){
        require(value < (SPECIALITY_MASK_21 / RARITY_BONUS_MASK_20));
        return value * RARITY_BONUS_MASK_20;
    }

    function _setSpecialityValue21(uint256 value) internal pure returns(uint256){
        require(value < (DAMAGE_MASK_22 / SPECIALITY_MASK_21));
        return value * SPECIALITY_MASK_21;
    }
    
    function _setDamgeValue22(uint256 value) internal pure returns(uint256){
        require(value < (AURA_MASK_23 / DAMAGE_MASK_22));
        return value * DAMAGE_MASK_22;
    }

    function _setAuraValue23(uint256 value) internal pure returns(uint256){
        require(value < (BASE_MASK_24 / AURA_MASK_23));
        return value * AURA_MASK_23;
    }
    
     
    function _computeRunes(uint256 _rarity) internal pure returns (uint256){
        return _rarity > UNCOMMON ? _rarity - UNCOMMON : 0; 
    }

    function _computeWings(uint256 _rarity, uint256 max, uint256 hash) internal pure returns (uint256){
        return _rarity > RARE ?  1 + _random(0, max, hash, PET_MASK_13, WINGS_MASK_12) : 0;
    }

    function _computePet(uint256 _rarity, uint256 max, uint256 hash) internal pure returns (uint256){
        return _rarity > MYTHIC ? 1 + _random(0, max, hash, BORDER_MASK_14, PET_MASK_13) : 0;
    }

    function _computeBorder(uint256 _rarity) internal pure returns (uint256){
        return _rarity >= COMMON ? _rarity - 1 : 0;
    }

    function _computeBackground(uint256 _rarity) internal pure returns (uint256){
        return _rarity;
    }
    
    function _unpackPetData(uint256 index) internal pure returns(uint256){
        return (PETS_DATA % (1000 ** (index + 1)) / (1000 ** index));
    }
    
    function _getPetBonus1(uint256 _pet) internal pure returns(uint256) {
        return (_pet % (10 ** (PET_PARAM_1 + 1)) / (10 ** PET_PARAM_1));
    }
    
    function _getPetBonus2(uint256 _pet) internal pure returns(uint256) {
        return (_pet % (10 ** (PET_PARAM_2 + 1)) / (10 ** PET_PARAM_2));
    }
    
    function _getPetAura(uint256 _pet) internal pure returns(uint256) {
        return (_pet % (10 ** (PET_AURA + 1)) / (10 ** PET_AURA));
    }
    
    function _getBattleBonus(uint256 _setBonusIndex, uint256 _currentBonusIndex, uint256 _petData, uint256 _warriorAuras, uint256 _petAuras) internal pure returns(int256) {
        int256 bonus = 0;
        if (_setBonusIndex == _currentBonusIndex) {
            bonus += int256(BONUS_DATA % (100 ** (_setBonusIndex + 1)) / (100 ** _setBonusIndex)) * PRECISION;
        }
         
        if (_setBonusIndex == _getPetBonus1(_petData)) {
            bonus += int256(BONUS_DATA % (100 ** (_setBonusIndex + 1)) / (100 ** _setBonusIndex)) * PRECISION / 2;
        }
        if (_setBonusIndex == _getPetBonus2(_petData)) {
            bonus += int256(BONUS_DATA % (100 ** (_setBonusIndex + 1)) / (100 ** _setBonusIndex)) * PRECISION / 2;
        }
         
        if (isAuraSet(_warriorAuras, uint8(_setBonusIndex))) { 
            bonus += int256(BONUS_DATA % (100 ** (_setBonusIndex + 1)) / (100 ** _setBonusIndex)) * PRECISION / 2;
        }
         
        if (isAuraSet(_petAuras, uint8(_setBonusIndex))) { 
            bonus += int256(BONUS_DATA % (100 ** (_setBonusIndex + 1)) / (100 ** _setBonusIndex)) * PRECISION;
        }
        return bonus;
    }
    
    function _computeRarityBonus(uint256 _rarity, uint256 hash) internal pure returns (uint256){
        if (_rarity == UNCOMMON) {
            return 1 + _random(0, BONUS_PENETRATION, hash, SPECIALITY_MASK_21, RARITY_BONUS_MASK_20);
        }
        if (_rarity == RARE) {
            return 1 + _random(BONUS_PENETRATION, BONUS_DAMAGE, hash, SPECIALITY_MASK_21, RARITY_BONUS_MASK_20);
        }
        if (_rarity >= MYTHIC) {
            return 1 + _random(0, BONUS_DAMAGE, hash, SPECIALITY_MASK_21, RARITY_BONUS_MASK_20);
        }
        return BONUS_NONE;
    }

    function _computeAura(uint256 _rarity, uint256 hash) internal pure returns (uint256){
        if (_rarity >= MYTHIC) {
            return 1 + _random(0, BONUS_DAMAGE, hash, BASE_MASK_24, AURA_MASK_23);
        }
        return BONUS_NONE;
    }
    
	function _computeRarity(uint256 _reward, uint256 _unique, uint256 _legendary, 
	    uint256 _mythic, uint256 _rare, uint256 _uncommon) internal pure returns(uint256){
	        
        uint256 range = _unique + _legendary + _mythic + _rare + _uncommon;
        if (_reward >= range) return COMMON;  
        if (_reward >= (range = (range - _uncommon))) return UNCOMMON;
        if (_reward >= (range = (range - _rare))) return RARE;
        if (_reward >= (range = (range - _mythic))) return MYTHIC;
        if (_reward >= (range = (range - _legendary))) return LEGENDARY;
        if (_reward < range) return UNIQUE;
        return COMMON;
    }
    
    function _computeUniqueness(uint256 _rarity, uint256 nextUnique) internal pure returns (uint256){
        return _rarity == UNIQUE ? nextUnique : 0;
    }
    
     
     
    function _getBonus(uint256 identity) internal pure returns(uint256){
        return getSpecialityValue(identity) == MINER_PERK ? 4 : 1;
    }
    

    function _computeAndSetBaseParameters16_18_22(uint256 _hash) internal pure returns (uint256, uint256){
        uint256 identity = 0;

        uint256 damage = 35 + _random(0, 21, _hash, AURA_MASK_23, DAMAGE_MASK_22);
        
        uint256 strength = 45 + _random(0, 26, _hash, CLASS_MECH_MASK_19, STRENGTH_MASK_18);
        uint256 agility = 15 + (125 - damage - strength);
        uint256 intelligence = 155 - strength - agility - damage;
        (strength, agility, intelligence) = _shuffleParams(strength, agility, intelligence, _hash);
        
        identity += _setStrengthValue18(strength);
        identity += _setAgilityValue17(agility);
		identity += _setIntelligenceValue16(intelligence);
		identity += _setDamgeValue22(damage);
        
        uint256 classMech = strength > agility ? (strength > intelligence ? WARRIOR : MAGE) : (agility > intelligence ? ARCHER : MAGE);
        return (identity, classMech);
    }
    
    function _shuffleParams(uint256 param1, uint256 param2, uint256 param3, uint256 _hash) internal pure returns(uint256, uint256, uint256) {
        uint256 temp = param1;
        if (_hash % 2 == 0) {
            temp = param1;
            param1 = param2;
            param2 = temp;
        }
        if ((_hash / 10 % 2) == 0) {
            temp = param2;
            param2 = param3;
            param3 = temp;
        }
        if ((_hash / 100 % 2) == 0) {
            temp = param1;
            param1 = param2;
            param2 = temp;
        }
        return (param1, param2, param3);
    }
    
    
     
    function _random(uint256 _min, uint256 _max, uint256 _hash, uint256 _reminder, uint256 _devider) internal pure returns (uint256){
        return ((_hash % _reminder) / _devider) % (_max - _min) + _min;
    }

    function _random(uint256 _min, uint256 _max, uint256 _hash) internal pure returns (uint256){
        return _hash % (_max - _min) + _min;
    }

    function _getTargetBlock(uint256 _targetBlock) internal view returns(uint256){
        uint256 currentBlock = block.number;
        uint256 target = currentBlock - (currentBlock % 256) + (_targetBlock % 256);
        if (target >= currentBlock) {
            return (target - 256);
        }
        return target;
    }
    
    function _getMaxRarityChance() internal pure returns(uint256){
        return RARITY_CHANCE_RANGE;
    }
    
    function generateWarrior(uint256 _heroIdentity, uint256 _heroLevel, uint256 _targetBlock, uint256 specialPerc, uint32[19] memory params) internal view returns (uint256) {
        _targetBlock = _getTargetBlock(_targetBlock);
        
        uint256 identity;
        uint256 hash = uint256(keccak256(block.blockhash(_targetBlock), _heroIdentity, block.coinbase, block.difficulty));
         
        uint256 rarityChance = _heroLevel == 0 ? RARITY_CHANCE_RANGE : 
        	_random(0, RARITY_CHANCE_RANGE, hash) / (_heroLevel * _getBonus(_heroIdentity));  
        uint256 rarity = _computeRarity(rarityChance, 
            params[UNIQUE_INDEX_13],params[LEGENDARY_INDEX_14], params[MYTHIC_INDEX_15], params[RARE_INDEX_16], params[UNCOMMON_INDEX_17]);
            
        uint256 classMech;
        
         
        (identity, classMech) = _computeAndSetBaseParameters16_18_22(hash);
        
        identity += _setUniqueValue0(_computeUniqueness(rarity, params[UNIQUE_TOTAL_INDEX_18] + 1));
        identity += _setRarityValue1(rarity);
        identity += _setClassViewValue2(classMech);  
        
        identity += _setBodyColorValue3(1 + _random(0, params[BODY_COLOR_MAX_INDEX_0], hash, EYES_MASK_4, BODY_COLOR_MASK_3));
        identity += _setEyesValue4(1 + _random(0, params[EYES_MAX_INDEX_1], hash, MOUTH_MASK_5, EYES_MASK_4));
        identity += _setMouthValue5(1 + _random(0, params[MOUTH_MAX_2], hash, HEIR_MASK_6, MOUTH_MASK_5));
        identity += _setHairValue6(1 + _random(0, params[HAIR_MAX_3], hash, HEIR_COLOR_MASK_7, HEIR_MASK_6));
        identity += _setHairColorValue7(1 + _random(0, params[HEIR_COLOR_MAX_4], hash, ARMOR_MASK_8, HEIR_COLOR_MASK_7));
        identity += _setArmorValue8(1 + _random(0, params[ARMOR_MAX_5], hash, WEAPON_MASK_9, ARMOR_MASK_8));
        identity += _setWeaponValue9(1 + _random(0, params[WEAPON_MAX_6], hash, HAT_MASK_10, WEAPON_MASK_9));
        identity += _setHatValue10(_random(0, params[HAT_MAX_7], hash, RUNES_MASK_11, HAT_MASK_10)); 
        
        identity += _setRunesValue11(_computeRunes(rarity));
        identity += _setWingsValue12(_computeWings(rarity, params[WINGS_MAX_9], hash));
        identity += _setPetValue13(_computePet(rarity, params[PET_MAX_10], hash));
        identity += _setBorderValue14(_computeBorder(rarity));  
        identity += _setBackgroundValue15(_computeBackground(rarity));  
        
        identity += _setClassMechValue19(classMech);

        identity += _setRarityBonusValue20(_computeRarityBonus(rarity, hash));
        identity += _setSpecialityValue21(specialPerc);  
        
        identity += _setAuraValue23(_computeAura(rarity, hash));
         
        return identity;
    }
    
	function _changeParameter(uint256 _paramIndex, uint32 _value, uint32[19] storage parameters) internal {
		 
		require(_paramIndex >= BODY_COLOR_MAX_INDEX_0 && _paramIndex <= UNIQUE_INDEX_13);
		 
		 
		require(
		    _paramIndex != RUNES_MAX_8 && 
		    _paramIndex != PET_MAX_10 && 
		    _paramIndex != BORDER_MAX_11 && 
		    _paramIndex != BACKGROUND_MAX_12
		);
		 
		require(_paramIndex > HAT_MAX_7 || _value < 1000);
		 
		require(_paramIndex > BACKGROUND_MAX_12 || _value < 100);
		 
		require(_paramIndex != UNIQUE_INDEX_13 || (_value + parameters[UNIQUE_TOTAL_INDEX_18]) <= 100);
		
		parameters[_paramIndex] = _value;
    }
    
	function _recordWarriorData(uint256 identity, uint32[19] storage parameters) internal {
        uint256 rarity = getRarityValue(identity);
        if (rarity == UNCOMMON) {  
            parameters[UNCOMMON_INDEX_17]--;
            return;
        }
        if (rarity == RARE) {  
            parameters[RARE_INDEX_16]--;
            return;
        }
        if (rarity == MYTHIC) {  
            parameters[MYTHIC_INDEX_15]--;
            return;
        }
        if (rarity == LEGENDARY) {  
            parameters[LEGENDARY_INDEX_14]--;
            return;
        }
        if (rarity == UNIQUE) {  
            parameters[UNIQUE_INDEX_13]--;
            parameters[UNIQUE_TOTAL_INDEX_18] ++;
            return;
        }
    }
    
    function _validateIdentity(uint256 _identity, uint32[19] memory params) internal pure returns(bool){
        uint256 rarity = getRarityValue(_identity);
        require(rarity <= UNIQUE);
        
        require(
            rarity <= COMMON || 
            (rarity == UNCOMMON && params[UNCOMMON_INDEX_17] > 0) || 
            (rarity == RARE && params[RARE_INDEX_16] > 0) || 
            (rarity == MYTHIC && params[MYTHIC_INDEX_15] > 0) || 
            (rarity == LEGENDARY && params[LEGENDARY_INDEX_14] > 0) || 
            (rarity == UNIQUE && params[UNIQUE_INDEX_13] > 0) 
        );
        require(rarity != UNIQUE || getUniqueValue(_identity) > params[UNIQUE_TOTAL_INDEX_18]);
        
         
        require(
            getStrengthValue(_identity) < 100 &&
            getAgilityValue(_identity) < 100 &&
            getIntelligenceValue(_identity) < 100 &&
            getDamageValue(_identity) <= 55
        );
        require(getClassMechValue(_identity) <= MAGE);
        require(getClassMechValue(_identity) == getClassViewValue(_identity));
        require(getSpecialityValue(_identity) <= MINER_PERK);
        require(getRarityBonusValue(_identity) <= BONUS_DAMAGE);
        require(getAuraValue(_identity) <= BONUS_DAMAGE);
        
         
        require(getBodyColorValue(_identity) <= params[BODY_COLOR_MAX_INDEX_0]);
        require(getEyesValue(_identity) <= params[EYES_MAX_INDEX_1]);
        require(getMouthValue(_identity) <= params[MOUTH_MAX_2]);
        require(getHairValue(_identity) <= params[HAIR_MAX_3]);
        require(getHairColorValue(_identity) <= params[HEIR_COLOR_MAX_4]);
        require(getArmorValue(_identity) <= params[ARMOR_MAX_5]);
        require(getWeaponValue(_identity) <= params[WEAPON_MAX_6]);
        require(getHatValue(_identity) <= params[HAT_MAX_7]);
        require(getRunesValue(_identity) <= params[RUNES_MAX_8]);
        require(getWingsValue(_identity) <= params[WINGS_MAX_9]);
        require(getPetValue(_identity) <= params[PET_MAX_10]);
        require(getBorderValue(_identity) <= params[BORDER_MAX_11]);
        require(getBackgroundValue(_identity) <= params[BACKGROUND_MAX_12]);
        
        return true;
    }
    
     
     
    function _unpackClassValue(uint256 packedValue) internal pure returns(uint256){
        return (packedValue % RARITY_PACK_2 / CLASS_PACK_0);
    }
    
    function _unpackRarityBonusValue(uint256 packedValue) internal pure returns(uint256){
        return (packedValue % RARITY_PACK_2 / RARITY_BONUS_PACK_1);
    }
    
    function _unpackRarityValue(uint256 packedValue) internal pure returns(uint256){
        return (packedValue % EXPERIENCE_PACK_3 / RARITY_PACK_2);
    }
    
    function _unpackExpValue(uint256 packedValue) internal pure returns(uint256){
        return (packedValue % INTELLIGENCE_PACK_4 / EXPERIENCE_PACK_3);
    }

    function _unpackLevelValue(uint256 packedValue) internal pure returns(uint256){
        return (packedValue % INTELLIGENCE_PACK_4) / (EXPERIENCE_PACK_3 * POINTS_TO_LEVEL);
    }
    
    function _unpackIntelligenceValue(uint256 packedValue) internal pure returns(int256){
        return int256(packedValue % AGILITY_PACK_5 / INTELLIGENCE_PACK_4);
    }
    
    function _unpackAgilityValue(uint256 packedValue) internal pure returns(int256){
        return int256(packedValue % STRENGTH_PACK_6 / AGILITY_PACK_5);
    }
    
    function _unpackStrengthValue(uint256 packedValue) internal pure returns(int256){
        return int256(packedValue % BASE_DAMAGE_PACK_7 / STRENGTH_PACK_6);
    }

    function _unpackBaseDamageValue(uint256 packedValue) internal pure returns(int256){
        return int256(packedValue % PET_PACK_8 / BASE_DAMAGE_PACK_7);
    }
    
    function _unpackPetValue(uint256 packedValue) internal pure returns(uint256){
        return (packedValue % AURA_PACK_9 / PET_PACK_8);
    }
    
    function _unpackAuraValue(uint256 packedValue) internal pure returns(uint256){
        return (packedValue % WARRIOR_ID_PACK_10 / AURA_PACK_9);
    }
     
     
    function _unpackIdValue(uint256 packedValue) internal pure returns(uint256){
        return (packedValue % PVP_CYCLE_PACK_11 / WARRIOR_ID_PACK_10);
    }
    
    function _unpackCycleValue(uint256 packedValue) internal pure returns(uint256){
        return (packedValue % RATING_PACK_12 / PVP_CYCLE_PACK_11);
    }
    
    function _unpackRatingValue(uint256 packedValue) internal pure returns(uint256){
        return (packedValue % PVP_BASE_PACK_13 / RATING_PACK_12);
    }
    
     
    function _changeCycleValue(uint256 packedValue, uint256 newValue) internal pure returns(uint256){
        newValue = newValue > 1000000000 ? 1000000000 : newValue;
        return packedValue - (_unpackCycleValue(packedValue) * PVP_CYCLE_PACK_11) + newValue * PVP_CYCLE_PACK_11;
    }
    
    function _packWarriorCommonData(uint256 _identity, uint256 _experience) internal pure returns(uint256){
        uint256 packedData = 0;
        packedData += getClassMechValue(_identity) * CLASS_PACK_0;
        packedData += getRarityBonusValue(_identity) * RARITY_BONUS_PACK_1;
        packedData += getRarityValue(_identity) * RARITY_PACK_2;
        packedData += _experience * EXPERIENCE_PACK_3;
        packedData += getIntelligenceValue(_identity) * INTELLIGENCE_PACK_4;
        packedData += getAgilityValue(_identity) * AGILITY_PACK_5;
        packedData += getStrengthValue(_identity) * STRENGTH_PACK_6;
        packedData += getDamageValue(_identity) * BASE_DAMAGE_PACK_7;
        packedData += getPetValue(_identity) * PET_PACK_8;
        
        return packedData;
    }
    
    function _packWarriorPvpData(uint256 _identity, uint256 _rating, uint256 _pvpCycle, uint256 _warriorId, uint256 _experience) internal pure returns(uint256){
        uint256 packedData = _packWarriorCommonData(_identity, _experience);
        packedData += _warriorId * WARRIOR_ID_PACK_10;
        packedData += _pvpCycle * PVP_CYCLE_PACK_11;
         
        packedData += _rating * RATING_PACK_12;
        return packedData;
    }
    
     
    
    
    function _packWarriorIds(uint256[] memory packedWarriors) internal pure returns(uint256){
        uint256 packedIds = 0;
        uint256 length = packedWarriors.length;
        for(uint256 i = 0; i < length; i ++) {
            packedIds += (MAX_ID_SIZE ** i) * _unpackIdValue(packedWarriors[i]);
        }
        return packedIds;
    }

    function _unpackWarriorId(uint256 packedIds, uint256 index) internal pure returns(uint256){
        return (packedIds % (MAX_ID_SIZE ** (index + 1)) / (MAX_ID_SIZE ** index));
    }
    
    function _packCombinedParams(int256 hp, int256 damage, int256 armor, int256 dodge, int256 penetration) internal pure returns(uint256) {
        uint256 combinedWarrior = 0;
        combinedWarrior += uint256(hp) * HP_PACK_0;
        combinedWarrior += uint256(damage) * DAMAGE_PACK_1;
        combinedWarrior += uint256(armor) * ARMOR_PACK_2;
        combinedWarrior += uint256(dodge) * DODGE_PACK_3;
        combinedWarrior += uint256(penetration) * PENETRATION_PACK_4;
        return combinedWarrior;
    }
    
    function _unpackProtectionParams(uint256 combinedWarrior) internal pure returns 
    (int256 hp, int256 armor, int256 dodge){
        hp = int256(combinedWarrior % DAMAGE_PACK_1 / HP_PACK_0);
        armor = int256(combinedWarrior % DODGE_PACK_3 / ARMOR_PACK_2);
        dodge = int256(combinedWarrior % PENETRATION_PACK_4 / DODGE_PACK_3);
    }
    
    function _unpackAttackParams(uint256 combinedWarrior) internal pure returns(int256 damage, int256 penetration) {
        damage = int256(combinedWarrior % ARMOR_PACK_2 / DAMAGE_PACK_1);
        penetration = int256(combinedWarrior % COMBINE_BASE_PACK_5 / PENETRATION_PACK_4);
    }
    
    function _combineWarriors(uint256[] memory packedWarriors) internal pure returns (uint256) {
        int256 hp;
        int256 damage;
		int256 armor;
		int256 dodge;
		int256 penetration;
		
		(hp, damage, armor, dodge, penetration) = _computeCombinedParams(packedWarriors);
        return _packCombinedParams(hp, damage, armor, dodge, penetration);
    }
    
    function _computeCombinedParams(uint256[] memory packedWarriors) internal pure returns 
    (int256 totalHp, int256 totalDamage, int256 maxArmor, int256 maxDodge, int256 maxPenetration){
        uint256 length = packedWarriors.length;
        
        int256 hp;
		int256 armor;
		int256 dodge;
		int256 penetration;
		
		uint256 warriorAuras;
		uint256 petAuras;
		(warriorAuras, petAuras) = _getAurasData(packedWarriors);
		
		uint256 packedWarrior;
        for(uint256 i = 0; i < length; i ++) {
            packedWarrior = packedWarriors[i];
            
            totalDamage += getDamage(packedWarrior, warriorAuras, petAuras);
            
            penetration = getPenetration(packedWarrior, warriorAuras, petAuras);
            maxPenetration = maxPenetration > penetration ? maxPenetration : penetration;
			(hp, armor, dodge) = _getProtectionParams(packedWarrior, warriorAuras, petAuras);
            totalHp += hp;
            maxArmor = maxArmor > armor ? maxArmor : armor;
            maxDodge = maxDodge > dodge ? maxDodge : dodge;
        }
    }
    
    function _getAurasData(uint256[] memory packedWarriors) internal pure returns(uint256 warriorAuras, uint256 petAuras) {
        uint256 length = packedWarriors.length;
        
        warriorAuras = 0;
        petAuras = 0;
        
        uint256 packedWarrior;
        for(uint256 i = 0; i < length; i ++) {
            packedWarrior = packedWarriors[i];
            warriorAuras = enableAura(warriorAuras, (_unpackAuraValue(packedWarrior)));
            petAuras = enableAura(petAuras, (_getPetAura(_unpackPetData(_unpackPetValue(packedWarrior)))));
        }
        warriorAuras = filterWarriorAuras(warriorAuras, petAuras);
        return (warriorAuras, petAuras);
    }
    
     
    function isAuraSet(uint256 aura, uint256 auraIndex) internal pure returns (bool) {
        return aura & (uint256(0x01) << auraIndex) != 0;
    }
    
     
    function enableAura(uint256 a, uint256 n) internal pure returns (uint256) {
        return a | (uint256(0x01) << n);
    }
    
     
    function filterWarriorAuras(uint256 _warriorAuras, uint256 _petAuras) internal pure returns(uint256) {
        return (_warriorAuras & _petAuras) ^ _warriorAuras;
    }
  
    function _getTournamentBattles(uint256 _numberOfContenders) internal pure returns(uint256) {
        return (_numberOfContenders * BATTLES_PER_CONTENDER / 2);
    }
    
    function getTournamentBattleResults(uint256[] memory combinedWarriors, uint256 _targetBlock) internal view returns (uint32[] memory results){
        uint256 length = combinedWarriors.length;
        results = new uint32[](length);
		
		int256 damage1;
		int256 penetration1;
		
		uint256 hash;
		
		uint256 randomIndex;
		uint256 exp = 0;
		uint256 i;
		uint256 result;
        for(i = 0; i < length; i ++) {
            (damage1, penetration1) = _unpackAttackParams(combinedWarriors[i]);
            while(results[i] < BATTLES_PER_CONTENDER_SUM) {
                 
                 
                if (exp == 0 || exp > 73) {
                    hash = uint256(keccak256(block.blockhash(_getTargetBlock(_targetBlock - i)), uint256(damage1) + now));
                    exp = 0;
                }
                 
                randomIndex = (_random(i + 1 < length ? i + 1 : i, length, hash, 1000 * 10**exp, 10**exp));
                result = getTournamentBattleResult(damage1, penetration1, combinedWarriors[i],
                    combinedWarriors[randomIndex], hash % (1000 * 10**exp) / 10**exp);
                results[result == 1 ? i : randomIndex] += 101; 
                results[result == 1 ? randomIndex : i] += 100; 
                if (results[randomIndex] >= BATTLES_PER_CONTENDER_SUM) {
                    if (randomIndex < length - 1) {
                        _swapValues(combinedWarriors, results, randomIndex, length - 1);
                    }
                    length --;
                }
                exp++;
            }
        }
         
        length = combinedWarriors.length;
        for(i = 0; i < length; i ++) {
            results[i] = results[i] % 100;
        }
        
        return results;
    }
    
    function _swapValues(uint256[] memory combinedWarriors, uint32[] memory results, uint256 id1, uint256 id2) internal pure {
        uint256 temp = combinedWarriors[id1];
        combinedWarriors[id1] = combinedWarriors[id2];
        combinedWarriors[id2] = temp;
        temp = results[id1];
        results[id1] = results[id2];
        results[id2] = uint32(temp);
    }

    function getTournamentBattleResult(int256 damage1, int256 penetration1, uint256 combinedWarrior1, 
        uint256 combinedWarrior2, uint256 randomSource) internal pure returns (uint256)
    {
        int256 damage2;
		int256 penetration2;
        
		(damage2, penetration2) = _unpackAttackParams(combinedWarrior1);

		int256 totalHp1 = getCombinedTotalHP(combinedWarrior1, penetration2);
		int256 totalHp2 = getCombinedTotalHP(combinedWarrior2, penetration1);
        
        return _getBattleResult(damage1 * getBattleRandom(randomSource, 1) / 100, damage2 * getBattleRandom(randomSource, 10) / 100, totalHp1, totalHp2, randomSource);
    }
     
    
    function _getBattleResult(int256 damage1, int256 damage2, int256 totalHp1, int256 totalHp2, uint256 randomSource)  internal pure returns (uint256){
		totalHp1 = (totalHp1 * (PRECISION * PRECISION) / damage2);
		totalHp2 = (totalHp2 * (PRECISION * PRECISION) / damage1);
		 
		if (totalHp1 == totalHp2) return randomSource % 2 + 1;
		return totalHp1 > totalHp2 ? 1 : 2;       
    }
    
    function getCombinedTotalHP(uint256 combinedData, int256 enemyPenetration) internal pure returns(int256) {
        int256 hp;
		int256 armor;
		int256 dodge;
		(hp, armor, dodge) = _unpackProtectionParams(combinedData);
        
        return _getTotalHp(hp, armor, dodge, enemyPenetration);
    }
    
    function getTotalHP(uint256 packedData, uint256 warriorAuras, uint256 petAuras, int256 enemyPenetration) internal pure returns(int256) {
        int256 hp;
		int256 armor;
		int256 dodge;
		(hp, armor, dodge) = _getProtectionParams(packedData, warriorAuras, petAuras);
        
        return _getTotalHp(hp, armor, dodge, enemyPenetration);
    }
    
    function _getTotalHp(int256 hp, int256 armor, int256 dodge, int256 enemyPenetration) internal pure returns(int256) {
        int256 piercingResult = (armor - enemyPenetration) < -(75 * PRECISION) ? -(75 * PRECISION) : (armor - enemyPenetration);
        int256 mitigation = (PRECISION - piercingResult * PRECISION / (PRECISION + piercingResult / 100) / 100);
        
        return (hp * PRECISION / mitigation + (hp * dodge / (100 * PRECISION)));
    }
    
    function _applyLevelBonus(int256 _value, uint256 _level) internal pure returns(int256) {
        _level -= 1;
        return int256(uint256(_value) * (LEVEL_BONUSES % (100 ** (_level + 1)) / (100 ** _level)) / 10);
    }
    
    function _getProtectionParams(uint256 packedData, uint256 warriorAuras, uint256 petAuras) internal pure returns(int256 hp, int256 armor, int256 dodge) {
        uint256 rarityBonus = _unpackRarityBonusValue(packedData);
        uint256 petData = _unpackPetData(_unpackPetValue(packedData));
        int256 strength = _unpackStrengthValue(packedData) * PRECISION + _getBattleBonus(BONUS_STR, rarityBonus, petData, warriorAuras, petAuras);
        int256 agility = _unpackAgilityValue(packedData) * PRECISION + _getBattleBonus(BONUS_AGI, rarityBonus, petData, warriorAuras, petAuras);
        
        hp = 100 * PRECISION + strength + 7 * strength / 10 + _getBattleBonus(BONUS_HP, rarityBonus, petData, warriorAuras, petAuras); 
        hp = _applyLevelBonus(hp, _unpackLevelValue(packedData));
		armor = (strength + 8 * strength / 10 + agility + _getBattleBonus(BONUS_ARMOR, rarityBonus, petData, warriorAuras, petAuras)); 
		dodge = (2 * agility / 3);
    }
    
    function getDamage(uint256 packedWarrior, uint256 warriorAuras, uint256 petAuras) internal pure returns(int256) {
        uint256 rarityBonus = _unpackRarityBonusValue(packedWarrior);
        uint256 petData = _unpackPetData(_unpackPetValue(packedWarrior));
        int256 agility = _unpackAgilityValue(packedWarrior) * PRECISION + _getBattleBonus(BONUS_AGI, rarityBonus, petData, warriorAuras, petAuras);
        int256 intelligence = _unpackIntelligenceValue(packedWarrior) * PRECISION + _getBattleBonus(BONUS_INT, rarityBonus, petData, warriorAuras, petAuras);
		
		int256 crit = (agility / 5 + intelligence / 4) + _getBattleBonus(BONUS_CRIT_CHANCE, rarityBonus, petData, warriorAuras, petAuras);
		int256 critMultiplier = (PRECISION + intelligence / 25) + _getBattleBonus(BONUS_CRIT_MULT, rarityBonus, petData, warriorAuras, petAuras);
        
        int256 damage = int256(_unpackBaseDamageValue(packedWarrior) * 3 * PRECISION / 2) + _getBattleBonus(BONUS_DAMAGE, rarityBonus, petData, warriorAuras, petAuras);
        
		return (_applyLevelBonus(damage, _unpackLevelValue(packedWarrior)) * (PRECISION + crit * critMultiplier / (100 * PRECISION))) / PRECISION;
    }

    function getPenetration(uint256 packedWarrior, uint256 warriorAuras, uint256 petAuras) internal pure returns(int256) {
        uint256 rarityBonus = _unpackRarityBonusValue(packedWarrior);
        uint256 petData = _unpackPetData(_unpackPetValue(packedWarrior));
        int256 agility = _unpackAgilityValue(packedWarrior) * PRECISION + _getBattleBonus(BONUS_AGI, rarityBonus, petData, warriorAuras, petAuras);
        int256 intelligence = _unpackIntelligenceValue(packedWarrior) * PRECISION + _getBattleBonus(BONUS_INT, rarityBonus, petData, warriorAuras, petAuras);
		
		return (intelligence * 2 + agility + _getBattleBonus(BONUS_PENETRATION, rarityBonus, petData, warriorAuras, petAuras));
    }
    
     
    
     
    function getBattleRandom(uint256 randmSource, uint256 _step) internal pure returns(int256){
        return int256(100 + _random(0, 11, randmSource, 100 * _step, _step));
    }
    
    uint256 internal constant NO_AURA = 0;
    
    function getPVPBattleResult(uint256 packedData1, uint256 packedData2, uint256 randmSource) internal pure returns (uint256){
        uint256 petAura1 = _computePVPPetAura(packedData1);
        uint256 petAura2 = _computePVPPetAura(packedData2);
        
        uint256 warriorAura1 = _computePVPWarriorAura(packedData1, petAura1);
        uint256 warriorAura2 = _computePVPWarriorAura(packedData2, petAura2);
        
		int256 damage1 = getDamage(packedData1, warriorAura1, petAura1) * getBattleRandom(randmSource, 1) / 100;
        int256 damage2 = getDamage(packedData2, warriorAura2, petAura2) * getBattleRandom(randmSource, 10) / 100;

		int256 totalHp1;
		int256 totalHp2;
		(totalHp1, totalHp2) = _computeContendersTotalHp(packedData1, warriorAura1, petAura1, packedData2, warriorAura1, petAura1);
        
        return _getBattleResult(damage1, damage2, totalHp1, totalHp2, randmSource);
    }
    
    function _computePVPPetAura(uint256 packedData) internal pure returns(uint256) {
        return enableAura(NO_AURA, _getPetAura(_unpackPetData(_unpackPetValue(packedData))));
    }
    
    function _computePVPWarriorAura(uint256 packedData, uint256 petAuras) internal pure returns(uint256) {
        return filterWarriorAuras(enableAura(NO_AURA, _unpackAuraValue(packedData)), petAuras);
    }
    
    function _computeContendersTotalHp(uint256 packedData1, uint256 warriorAura1, uint256 petAura1, uint256 packedData2, uint256 warriorAura2, uint256 petAura2) 
    internal pure returns(int256 totalHp1, int256 totalHp2) {
		int256 enemyPenetration = getPenetration(packedData2, warriorAura2, petAura2);
		totalHp1 = getTotalHP(packedData1, warriorAura1, petAura1, enemyPenetration);
		enemyPenetration = getPenetration(packedData1, warriorAura1, petAura1);
		totalHp2 = getTotalHP(packedData2, warriorAura1, petAura1, enemyPenetration);
    }
    
    function getRatingRange(uint256 _pvpCycle, uint256 _pvpInterval, uint256 _expandInterval) internal pure returns (uint256){
        return 50 + (_pvpCycle * _pvpInterval / _expandInterval * 25);
    }
    
    function isMatching(int256 evenRating, int256 oddRating, int256 ratingGap) internal pure returns(bool) {
        return evenRating <= (oddRating + ratingGap) && evenRating >= (oddRating - ratingGap);
    }
    
    function sort(uint256[] memory data) internal pure {
       quickSort(data, int(0), int(data.length - 1));
    }
    
    function quickSort(uint256[] memory arr, int256 left, int256 right) internal pure {
        int256 i = left;
        int256 j = right;
        if(i==j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }
    
    function _swapPair(uint256[] memory matchingIds, uint256 id1, uint256 id2, uint256 id3, uint256 id4) internal pure {
        uint256 temp = matchingIds[id1];
        matchingIds[id1] = matchingIds[id2];
        matchingIds[id2] = temp;
        
        temp = matchingIds[id3];
        matchingIds[id3] = matchingIds[id4];
        matchingIds[id4] = temp;
    }
    
    function _swapValues(uint256[] memory matchingIds, uint256 id1, uint256 id2) internal pure {
        uint256 temp = matchingIds[id1];
        matchingIds[id1] = matchingIds[id2];
        matchingIds[id2] = temp;
    }
    
    function _getMatchingIds(uint256[] memory matchingIds, uint256 _pvpInterval, uint256 _skipCycles, uint256 _expandInterval) 
    internal pure returns(uint256 matchingCount) 
    {
        matchingCount = matchingIds.length;
        if (matchingCount == 0) return 0;
        
        uint256 warriorId;
        uint256 index;
         
        quickSort(matchingIds, int256(0), int256(matchingCount - 1));
         
        int256 rating1;
        uint256 pairIndex = 0;
        int256 ratingRange;
        for(index = 0; index < matchingCount; index++) {
             
            warriorId = matchingIds[index];
             
            rating1 = int256(_unpackRatingValue(warriorId));
            ratingRange = int256(getRatingRange(_unpackCycleValue(warriorId) + _skipCycles, _pvpInterval, _expandInterval));
            
            if (index > pairIndex &&  
            isMatching(rating1, int256(_unpackRatingValue(matchingIds[index - 1])), ratingRange)) {
                 
                 
                _swapPair(matchingIds, pairIndex, index - 1, pairIndex + 1, index);
                 
                pairIndex += 2;
            } else if (index + 1 < matchingCount &&  
            isMatching(rating1, int256(_unpackRatingValue(matchingIds[index + 1])), ratingRange)) {
                 
                 
                _swapPair(matchingIds, pairIndex, index, pairIndex + 1, index + 1);
                 
                pairIndex += 2;
                 
                index++;
            }
        }
        
        matchingCount = pairIndex;
    }

    function _getPVPBattleResults(uint256[] memory matchingIds, uint256 matchingCount, uint256 _targetBlock) internal view {
        uint256 exp = 0;
        uint256 hash = 0;
        uint256 result = 0;
        for (uint256 even = 0; even < matchingCount; even += 2) {
            if (exp == 0 || exp > 73) {
                hash = uint256(keccak256(block.blockhash(_getTargetBlock(_targetBlock)), hash));
                exp = 0;
            }
                
             
            result = getPVPBattleResult(matchingIds[even], matchingIds[even + 1], hash % (1000 * 10**exp) / 10**exp);
            require(result > 0 && result < 3);
            exp++;
             
             
             
            if (result == 2) {
                _swapValues(matchingIds, even, even + 1);
            }
        }
    }
    
    function _getLevel(uint256 _levelPoints) internal pure returns(uint256) {
        return _levelPoints / POINTS_TO_LEVEL;
    }
    
}

contract WarriorGenerator is Ownable, GeneratorInterface {
    
    address coreContract;
    
     
    uint32[19] public parameters; 
    
    function WarriorGenerator(address _coreContract, uint32[] _settings) public {
        uint256 length = _settings.length;
        require(length == 18);
        require(_settings[8] == 4); 
        require(_settings[10] == 10); 
        require(_settings[11] == 5); 
        require(_settings[12] == 6); 
         
        for(uint256 i = 0; i < length; i ++) {
            parameters[i] = _settings[i];
        }	
        
        coreContract = _coreContract;
    }
    
    function changeParameter(uint32 _paramIndex, uint32 _value) external onlyOwner {
        CryptoUtils._changeParameter(_paramIndex, _value, parameters);
    }

     
    function isGenerator() public pure returns (bool){
        return true;
    }

     
     
     
     
     
     
    function generateWarrior(uint256 _heroIdentity, uint256 _heroLevel, uint256 _targetBlock, uint256 _perkId) 
    public returns (uint256) 
    {
         
        require(msg.sender == coreContract);
         
        uint32[19] memory memoryParams = parameters;
         
        uint256 identity = CryptoUtils.generateWarrior(_heroIdentity, _heroLevel, _targetBlock, _perkId, memoryParams);
        
         
        CryptoUtils._validateIdentity(identity, memoryParams);
         
        CryptoUtils._recordWarriorData(identity, parameters);
        
        return identity;
    }
}

contract AuctionBase {
	uint256 public constant PRICE_CHANGE_TIME_STEP = 15 minutes;
	
    struct Auction{
        address seller;
        uint128 startingPrice;
        uint128 endingPrice;
        uint64 duration;
        uint64 startedAt;
    }
    mapping (uint256 => Auction) internal tokenIdToAuction;
    
    uint256 public ownerCut;
    
    ERC721 public nonFungibleContract;

    event AuctionCreated(uint256 tokenId, address seller, uint256 startingPrice);

    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner, address seller);

    event AuctionCancelled(uint256 tokenId, address seller);

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool){
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    function _escrow(address _owner, uint256 _tokenId) internal{
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }
    
    function _transfer(address _receiver, uint256 _tokenId) internal{
        nonFungibleContract.transfer(_receiver, _tokenId);
    }
    
    function _addAuction(uint256 _tokenId, Auction _auction) internal{
        require(_auction.duration >= 1 minutes);
        
        tokenIdToAuction[_tokenId] = _auction;
        
        AuctionCreated(uint256(_tokenId), _auction.seller, _auction.startingPrice);
    }

     
    function _cancelAuction(uint256 _tokenId, address _seller) internal{
        _removeAuction(_tokenId);
        
        _transfer(_seller, _tokenId);
        
        AuctionCancelled(_tokenId, _seller);
    }

    function _bid(uint256 _tokenId, uint256 _bidAmount) internal returns (uint256){
        
        Auction storage auction = tokenIdToAuction[_tokenId];
        
        require(_isOnAuction(auction));
        
        uint256 price = _currentPrice(auction);
        
        require(_bidAmount >= price);
        
        address seller = auction.seller;
        
        _removeAuction(_tokenId);
        
        if (price > 0) {
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;
            
            seller.transfer(sellerProceeds);
            nonFungibleContract.getBeneficiary().transfer(auctioneerCut);
        }
        
        uint256 bidExcess = _bidAmount - price;
        
        msg.sender.transfer(bidExcess);
        
        AuctionSuccessful(_tokenId, price, msg.sender, seller);
        
        return price;
    }

    function _removeAuction(uint256 _tokenId) internal{
        delete tokenIdToAuction[_tokenId];
    }

    function _isOnAuction(Auction storage _auction) internal view returns (bool){
        return (_auction.startedAt > 0);
    }

    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256){
        uint256 secondsPassed = 0;
        
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }
        
        return _computeCurrentPrice(_auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed);
    }
    
    function _computeCurrentPrice(uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed)
        internal
        pure
        returns (uint256){
        
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
            
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed / PRICE_CHANGE_TIME_STEP * PRICE_CHANGE_TIME_STEP) / int256(_duration);
            
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;
            
            return uint256(currentPrice);
        }
    }

    function _computeCut(uint256 _price) internal view returns (uint256){
        
        return _price * ownerCut / 10000;
    }
}


contract SaleClockAuction is Pausable, AuctionBase {
    
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9f40b779);
    
    bool public isSaleClockAuction = true;
    uint256 public minerSaleCount;
    uint256[5] public lastMinerSalePrices;

    function SaleClockAuction(address _nftAddress, uint256 _cut) public{
        require(_cut <= 10000);
        ownerCut = _cut;
        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        require(candidateContract.getBeneficiary() != address(0));
        
        nonFungibleContract = candidateContract;
    }

    function cancelAuction(uint256 _tokenId)
        external{
        
        AuctionBase.Auction storage auction = tokenIdToAuction[_tokenId];
        
        require(_isOnAuction(auction));
        
        address seller = auction.seller;
        
        require(msg.sender == seller);
        
        _cancelAuction(_tokenId, seller);
    }

    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        external{
        AuctionBase.Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256){
        
        AuctionBase.Auction storage auction = tokenIdToAuction[_tokenId];
        
        require(_isOnAuction(auction));
        
        return _currentPrice(auction);
    }
    
    function createAuction(uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller)
        external{
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));
        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        
        AuctionBase.Auction memory auction = Auction(_seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now));
        
        _addAuction(_tokenId, auction);
    }
    
    function bid(uint256 _tokenId)
        external
        payable{
        
        address seller = tokenIdToAuction[_tokenId].seller;
        
        uint256 price = _bid(_tokenId, msg.value);
        
        _transfer(msg.sender, _tokenId);
        
        if (seller == nonFungibleContract.getBeneficiary()) {
            lastMinerSalePrices[minerSaleCount % 5] = price;
            minerSaleCount++;
        }
    }

    function averageMinerSalePrice() external view returns (uint256){
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++){
            sum += lastMinerSalePrices[i];
        }
        return sum / 5;
    }
    
     
    function getAuctionsById(uint32[] tokenIds) external view returns(uint256[] memory auctionData, uint32 stepSize) {
        stepSize = 6;
        auctionData = new uint256[](tokenIds.length * stepSize);
        
        uint32 tokenId;
        for(uint32 i = 0; i < tokenIds.length; i ++) {
            tokenId = tokenIds[i];
            AuctionBase.Auction storage auction = tokenIdToAuction[tokenId];
            require(_isOnAuction(auction));
            _setTokenData(auctionData, auction, tokenId, i * stepSize);
        }
    }
    
     
    function getAuctions(uint32 fromIndex, uint32 count) external view returns(uint256[] memory auctionData, uint32 stepSize) {
        stepSize = 6;
        if (count == 0) {
            AuctionBase.Auction storage auction = tokenIdToAuction[fromIndex];
	        	require(_isOnAuction(auction));
	        	auctionData = new uint256[](1 * stepSize);
	        	_setTokenData(auctionData, auction, fromIndex, count);
	        	return (auctionData, stepSize);
        } else {
            uint256 totalWarriors = nonFungibleContract.totalSupply();
	        if (totalWarriors == 0) {
	             
	            return (new uint256[](0), stepSize);
	        } else {
	
	            uint32 totalSize = 0;
	            uint32 tokenId;
	            uint32 size = 0;
				auctionData = new uint256[](count * stepSize);
	            for (tokenId = 0; tokenId < totalWarriors && size < count; tokenId++) {
	                AuctionBase.Auction storage auction1 = tokenIdToAuction[tokenId];
	        
		        		if (_isOnAuction(auction1)) {
		        		    totalSize ++;
		        		    if (totalSize > fromIndex) {
		        		        _setTokenData(auctionData, auction1, tokenId, size++ * stepSize); 
		        		    }
		        		}
	            }
	            
	            if (size < count) {
	                size *= stepSize;
	                uint256[] memory repack = new uint256[](size);
	                for(tokenId = 0; tokenId < size; tokenId++) {
	                    repack[tokenId] = auctionData[tokenId];
	                }
	                return (repack, stepSize);
	            }
	
	            return (auctionData, stepSize);
	        }
        }
    }
    
     
     
    function getAuction(uint256 _tokenId) external view returns(
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
        ){
        
        Auction storage auction = tokenIdToAuction[_tokenId];
        
        require(_isOnAuction(auction));
        
        return (auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt);
    }
    
     
    function _setTokenData(uint256[] memory auctionData, 
        AuctionBase.Auction storage auction, uint32 tokenId, uint32 index
    ) internal view {
        auctionData[index] = uint256(tokenId); 
        auctionData[index + 1] = uint256(auction.seller); 
        auctionData[index + 2] = uint256(auction.startingPrice); 
        auctionData[index + 3] = uint256(auction.endingPrice); 
        auctionData[index + 4] = uint256(auction.duration); 
        auctionData[index + 5] = uint256(auction.startedAt); 
    }
    
}