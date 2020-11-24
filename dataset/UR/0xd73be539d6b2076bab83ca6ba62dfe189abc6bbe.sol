 

pragma solidity ^0.4.20;

 
 


 
contract GeneMixerInterface {
     
    function isGeneMixer() external pure returns (bool);

     
     
     
     
    function mixGenes(uint256 genes1, uint256 genes2) public view returns (uint256);

    function canBreed(uint40 momId, uint256 genes1, uint40 dadId, uint256 genes2) public view returns (bool);
}



 
contract PluginInterface
{
     
    function isPluginInterface() public pure returns (bool);

    function onRemove() public;

     
     
     
     
    function run(
        uint40 _cutieId,
        uint256 _parameter,
        address _seller
    ) 
    public
    payable;

     
     
     
    function runSigned(
        uint40 _cutieId,
        uint256 _parameter,
        address _owner
    )
    external
    payable;

    function withdraw() public;
}



 
 
contract MarketInterface 
{
    function withdrawEthFromBalance() external;    

    function createAuction(uint40 _cutieId, uint128 _startPrice, uint128 _endPrice, uint40 _duration, address _seller) public payable;

    function bid(uint40 _cutieId) public payable;

    function cancelActiveAuctionWhenPaused(uint40 _cutieId) public;

	function getAuctionInfo(uint40 _cutieId)
        public
        view
        returns
    (
        address seller,
        uint128 startPrice,
        uint128 endPrice,
        uint40 duration,
        uint40 startedAt,
        uint128 featuringFee
    );
}



 
 
 
contract ConfigInterface
{
    function isConfig() public pure returns (bool);

    function getCooldownIndexFromGeneration(uint16 _generation) public view returns (uint16);
    
    function getCooldownEndTimeFromIndex(uint16 _cooldownIndex) public view returns (uint40);

    function getCooldownIndexCount() public view returns (uint256);
    
    function getBabyGen(uint16 _momGen, uint16 _dadGen) public pure returns (uint16);

    function getTutorialBabyGen(uint16 _dadGen) public pure returns (uint16);

    function getBreedingFee(uint40 _momId, uint40 _dadId) public pure returns (uint256);
}



 
interface ERC721TokenReceiver {
     
     
     
     
     
     
     
     
     
     
     
    function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract BlockchainCutiesCore  
{
     
    function name() external pure returns (string _name) 
    {
        return "BlockchainCuties"; 
    }

     
    function symbol() external pure returns (string _symbol)
    {
        return "BC";
    }
    
     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external pure returns (bool)
    {
        return
            interfaceID == 0x6466353c || 
            interfaceID == bytes4(keccak256('supportsInterface(bytes4)'));
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     
    event Birth(address indexed owner, uint40 cutieId, uint40 momId, uint40 dadId, uint256 genes);

     
     
     
     
    struct Cutie
    {
         
        uint256 genes;

         
        uint40 birthTime;

         
         
        uint40 cooldownEndTime;

         
         
         
        uint40 momId;
        uint40 dadId;

         
         
         
         
         
        uint16 cooldownIndex;

         
         
         
         
        uint16 generation;

         
         
        uint64 optional;
    }

     
     
     
    Cutie[] public cuties;

     
     
    mapping (uint40 => address) public cutieIndexToOwner;

     
     
    mapping (address => uint256) ownershipTokenCount;

     
     
     
    mapping (uint40 => address) public cutieIndexToApproved;

     
     
     
    mapping (uint40 => address) public sireAllowedToAddress;


     
     
     
    MarketInterface public saleMarket;

     
     
     
    MarketInterface public breedingMarket;


     
     
    modifier canBeStoredIn40Bits(uint256 _value) {
        require(_value <= 0xFFFFFFFFFF);
        _;
    }    

     
     
    function totalSupply() external view returns (uint256)
    {
        return cuties.length - 1;
    }

     
     
    function _totalSupply() internal view returns (uint256)
    {
        return cuties.length - 1;
    }
    
     
     
     

     
     
     
    function _isOwner(address _claimant, uint40 _cutieId) internal view returns (bool)
    {
        return cutieIndexToOwner[_cutieId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint40 _cutieId) internal view returns (bool)
    {
        return cutieIndexToApproved[_cutieId] == _claimant;
    }

     
     
     
     
     
    function _approve(uint40 _cutieId, address _approved) internal
    {
        cutieIndexToApproved[_cutieId] = _approved;
    }

     
     
     
    function balanceOf(address _owner) external view returns (uint256 count)
    {
        return ownershipTokenCount[_owner];
    }

     
     
     
     
     
     
    function transfer(address _to, uint256 _cutieId) external whenNotPaused canBeStoredIn40Bits(_cutieId)
    {
         
        require(_isOwner(msg.sender, uint40(_cutieId)));

         
        _transfer(msg.sender, _to, uint40(_cutieId));
    }

     
     
     
     
     
    function approve(address _to, uint256 _cutieId) external whenNotPaused canBeStoredIn40Bits(_cutieId)
    {
         
        require(_isOwner(msg.sender, uint40(_cutieId)));

         
        _approve(uint40(_cutieId), _to);

         
        emit Approval(msg.sender, _to, _cutieId);
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) 
        external whenNotPaused canBeStoredIn40Bits(_tokenId)
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_to != address(saleMarket));
        require(_to != address(breedingMarket));
       
         
        require(_approvedFor(msg.sender, uint40(_tokenId)) || _isApprovedForAll(_from, msg.sender));
        require(_isOwner(_from, uint40(_tokenId)));

         
        _transfer(_from, _to, uint40(_tokenId));
        ERC721TokenReceiver (_to).onERC721Received(_from, _tokenId, data);
    }

     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) 
        external whenNotPaused canBeStoredIn40Bits(_tokenId)
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_to != address(saleMarket));
        require(_to != address(breedingMarket));
       
         
        require(_approvedFor(msg.sender, uint40(_tokenId)) || _isApprovedForAll(_from, msg.sender));
        require(_isOwner(_from, uint40(_tokenId)));

         
        _transfer(_from, _to, uint40(_tokenId));
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) 
        external whenNotPaused canBeStoredIn40Bits(_tokenId) 
    {
         
        require(_approvedFor(msg.sender, uint40(_tokenId)) || _isApprovedForAll(_from, msg.sender));
        require(_isOwner(_from, uint40(_tokenId)));

         
        _transfer(_from, _to, uint40(_tokenId));
    }

     
     
    function ownerOf(uint256 _cutieId)
        external
        view
        canBeStoredIn40Bits(_cutieId)
        returns (address owner)
    {
        owner = cutieIndexToOwner[uint40(_cutieId)];

        require(owner != address(0));
    }

     
     
     
     
     
     
     
     
     
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256 cutieId)
    {
        uint40 count = 0;
        for (uint40 i = 1; i <= _totalSupply(); ++i) {
            if (cutieIndexToOwner[i] == _owner) {
                if (count == _index) {
                    return i;
                } else {
                    count++;
                }
            }
        }
        revert();
    }

     
     
     
     
     
    function tokenByIndex(uint256 _index) external pure returns (uint256)
    {
        return _index;
    }

     
     
     
     
    mapping (address => address) public addressToApprovedAll;

     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external
    {
        if (_approved)
        {
            addressToApprovedAll[msg.sender] = _operator;
        }
        else
        {
            delete addressToApprovedAll[msg.sender];
        }
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

     
     
     
     
    function getApproved(uint256 _tokenId) 
        external view canBeStoredIn40Bits(_tokenId) 
        returns (address)
    {
        require(_tokenId <= _totalSupply());

        if (cutieIndexToApproved[uint40(_tokenId)] != address(0))
        {
            return cutieIndexToApproved[uint40(_tokenId)];
        }

        address owner = cutieIndexToOwner[uint40(_tokenId)];
        return addressToApprovedAll[owner];
    }

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool)
    {
        return addressToApprovedAll[_owner] == _operator;
    }

    function _isApprovedForAll(address _owner, address _operator) internal view returns (bool)
    {
        return addressToApprovedAll[_owner] == _operator;
    }

    ConfigInterface public config;

     
     
    function setConfigAddress(address _address) public onlyOwner
    {
        ConfigInterface candidateContract = ConfigInterface(_address);

        require(candidateContract.isConfig());

         
        config = candidateContract;
    }

    function getCooldownIndexFromGeneration(uint16 _generation) internal view returns (uint16)
    {
        return config.getCooldownIndexFromGeneration(_generation);
    }

     
     
     
     
     
     
     
     
     
    function _createCutie(
        uint40 _momId,
        uint40 _dadId,
        uint16 _generation,
        uint16 _cooldownIndex,
        uint256 _genes,
        address _owner,
        uint40 _birthTime
    )
        internal
        returns (uint40)
    {
        Cutie memory _cutie = Cutie({
            genes: _genes, 
            birthTime: _birthTime, 
            cooldownEndTime: 0, 
            momId: _momId, 
            dadId: _dadId, 
            cooldownIndex: _cooldownIndex, 
            generation: _generation,
            optional: 0
        });
        uint256 newCutieId256 = cuties.push(_cutie) - 1;

         
        require(newCutieId256 <= 0xFFFFFFFFFF);

        uint40 newCutieId = uint40(newCutieId256);

         
        emit Birth(_owner, newCutieId, _cutie.momId, _cutie.dadId, _cutie.genes);

         
         
        _transfer(0, _owner, newCutieId);

        return newCutieId;
    }
  
     
     
    function getCutie(uint40 _id)
        external
        view
        returns (
        uint256 genes,
        uint40 birthTime,
        uint40 cooldownEndTime,
        uint40 momId,
        uint40 dadId,
        uint16 cooldownIndex,
        uint16 generation
    ) {
        Cutie storage cutie = cuties[_id];

        genes = cutie.genes;
        birthTime = cutie.birthTime;
        cooldownEndTime = cutie.cooldownEndTime;
        momId = cutie.momId;
        dadId = cutie.dadId;
        cooldownIndex = cutie.cooldownIndex;
        generation = cutie.generation;
    }    
    
     
    function _transfer(address _from, address _to, uint40 _cutieId) internal {
         
         
        ownershipTokenCount[_to]++;
         
        cutieIndexToOwner[_cutieId] = _to;
         
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
             
            delete sireAllowedToAddress[_cutieId];
             
            delete cutieIndexToApproved[_cutieId];
        }
         
        emit Transfer(_from, _to, _cutieId);
    }

     
     
     
     
     
     
    function restoreCutieToAddress(uint40 _cutieId, address _recipient) public onlyOperator whenNotPaused {
        require(_isOwner(this, _cutieId));
        _transfer(this, _recipient, _cutieId);
    }

    address ownerAddress;
    address operatorAddress;

    bool public paused = false;

    modifier onlyOwner()
    {
        require(msg.sender == ownerAddress);
        _;
    }

    function setOwner(address _newOwner) public onlyOwner
    {
        require(_newOwner != address(0));

        ownerAddress = _newOwner;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress || msg.sender == ownerAddress);
        _;
    }

    function setOperator(address _newOperator) public onlyOwner {
        require(_newOperator != address(0));

        operatorAddress = _newOperator;
    }

    modifier whenNotPaused()
    {
        require(!paused);
        _;
    }

    modifier whenPaused
    {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused
    {
        paused = true;
    }

    string public metadataUrlPrefix = "https://blockchaincuties.co/cutie/";
    string public metadataUrlSuffix = ".svg";

     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string infoUrl)
    {
        return 
            concat(toSlice(metadataUrlPrefix), 
                toSlice(concat(toSlice(uintToString(_tokenId)), toSlice(metadataUrlSuffix))));
    }

    function setMetadataUrl(string _metadataUrlPrefix, string _metadataUrlSuffix) public onlyOwner
    {
        metadataUrlPrefix = _metadataUrlPrefix;
        metadataUrlSuffix = _metadataUrlSuffix;
    }


    mapping(address => PluginInterface) public plugins;
    PluginInterface[] public pluginsArray;
    mapping(uint40 => address) public usedSignes;
    uint40 public minSignId;

    event GenesChanged(uint40 indexed cutieId, uint256 oldValue, uint256 newValue);
    event CooldownEndTimeChanged(uint40 indexed cutieId, uint40 oldValue, uint40 newValue);
    event CooldownIndexChanged(uint40 indexed cutieId, uint16 ololdValue, uint16 newValue);
    event GenerationChanged(uint40 indexed cutieId, uint16 oldValue, uint16 newValue);
    event OptionalChanged(uint40 indexed cutieId, uint64 oldValue, uint64 newValue);
    event SignUsed(uint40 signId, address sender);
    event MinSignSet(uint40 signId);

     
     
    function addPlugin(address _address) public onlyOwner
    {
        PluginInterface candidateContract = PluginInterface(_address);

         
        require(candidateContract.isPluginInterface());

         
        plugins[_address] = candidateContract;
        pluginsArray.push(candidateContract);
    }

     
    function removePlugin(address _address) public onlyOwner
    {
        plugins[_address].onRemove();
        delete plugins[_address];

        uint256 kindex = 0;
        while (kindex < pluginsArray.length)
        {
            if (address(pluginsArray[kindex]) == _address)
            {
                pluginsArray[kindex] = pluginsArray[pluginsArray.length-1];
                pluginsArray.length--;
            }
            else
            {
                kindex++;
            }
        }
    }

     
    function runPlugin(
        address _pluginAddress,
        uint40 _cutieId,
        uint256 _parameter
    )
        public
        whenNotPaused
        payable
    {
         
         
         
        require(_cutieId == 0 || _isOwner(msg.sender, _cutieId));
        require(address(plugins[_pluginAddress]) != address(0));
        if (_cutieId > 0)
        {
            _approve(_cutieId, _pluginAddress);
        }

         
         
        plugins[_pluginAddress].run.value(msg.value)(
            _cutieId,
            _parameter,
            msg.sender
        );
    }

     
    function getGenes(uint40 _id)
        public
        view
        returns (
        uint256 genes
    )
    {
        Cutie storage cutie = cuties[_id];
        genes = cutie.genes;
    }

     
    function changeGenes(
        uint40 _cutieId,
        uint256 _genes)
        public
        whenNotPaused
    {
         
        require(address(plugins[msg.sender]) != address(0));

        Cutie storage cutie = cuties[_cutieId];
        if (cutie.genes != _genes)
        {
            emit GenesChanged(_cutieId, cutie.genes, _genes);
            cutie.genes = _genes;
        }
    }

    function getCooldownEndTime(uint40 _id)
        public
        view
        returns (
        uint40 cooldownEndTime
    ) {
        Cutie storage cutie = cuties[_id];

        cooldownEndTime = cutie.cooldownEndTime;
    }

    function changeCooldownEndTime(
        uint40 _cutieId,
        uint40 _cooldownEndTime)
        public
        whenNotPaused
    {
        require(address(plugins[msg.sender]) != address(0));

        Cutie storage cutie = cuties[_cutieId];
        if (cutie.cooldownEndTime != _cooldownEndTime)
        {
            emit CooldownEndTimeChanged(_cutieId, cutie.cooldownEndTime, _cooldownEndTime);
            cutie.cooldownEndTime = _cooldownEndTime;
        }
    }

    function getCooldownIndex(uint40 _id)
        public
        view
        returns (
        uint16 cooldownIndex
    ) {
        Cutie storage cutie = cuties[_id];

        cooldownIndex = cutie.cooldownIndex;
    }

    function changeCooldownIndex(
        uint40 _cutieId,
        uint16 _cooldownIndex)
        public
        whenNotPaused
    {
        require(address(plugins[msg.sender]) != address(0));

        Cutie storage cutie = cuties[_cutieId];
        if (cutie.cooldownIndex != _cooldownIndex)
        {
            emit CooldownIndexChanged(_cutieId, cutie.cooldownIndex, _cooldownIndex);
            cutie.cooldownIndex = _cooldownIndex;
        }
    }

    function changeGeneration(
        uint40 _cutieId,
        uint16 _generation)
        public
        whenNotPaused
    {
        require(address(plugins[msg.sender]) != address(0));

        Cutie storage cutie = cuties[_cutieId];
        if (cutie.generation != _generation)
        {
            emit GenerationChanged(_cutieId, cutie.generation, _generation);
            cutie.generation = _generation;
        }
    }

    function getGeneration(uint40 _id)
        public
        view
        returns (uint16 generation)
    {
        Cutie storage cutie = cuties[_id];
        generation = cutie.generation;
    }

    function changeOptional(
        uint40 _cutieId,
        uint64 _optional)
        public
        whenNotPaused
    {
        require(address(plugins[msg.sender]) != address(0));

        Cutie storage cutie = cuties[_cutieId];
        if (cutie.optional != _optional)
        {
            emit OptionalChanged(_cutieId, cutie.optional, _optional);
            cutie.optional = _optional;
        }
    }

    function getOptional(uint40 _id)
        public
        view
        returns (uint64 optional)
    {
        Cutie storage cutie = cuties[_id];
        optional = cutie.optional;
    }

     
    function hashArguments(
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter)
        public pure returns (bytes32 msgHash)
    {
        msgHash = keccak256(_pluginAddress, _signId, _cutieId, _value, _parameter);
    }

     
    function getSigner(
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
        )
        public pure returns (address)
    {
        bytes32 msgHash = hashArguments(_pluginAddress, _signId, _cutieId, _value, _parameter);
        return ecrecover(msgHash, _v, _r, _s);
    }

     
    function isValidSignature(
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
        )
        public
        view
        returns (bool)
    {
        return getSigner(_pluginAddress, _signId, _cutieId, _value, _parameter, _v, _r, _s) == operatorAddress;
    }

     
     
     
    function runPluginSigned(
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        whenNotPaused
        payable
    {
         
         
         
        require(_cutieId == 0 || _isOwner(msg.sender, _cutieId));
    
        require(address(plugins[_pluginAddress]) != address(0));    

        require (usedSignes[_signId] == address(0));
        require (_signId >= minSignId);
         
        require (_value <= msg.value);

        require (isValidSignature(_pluginAddress, _signId, _cutieId, _value, _parameter, _v, _r, _s));
        
        usedSignes[_signId] = msg.sender;
        emit SignUsed(_signId, msg.sender);

         
         
        plugins[_pluginAddress].runSigned.value(_value)(
            _cutieId,
            _parameter,
            msg.sender
        );
    }

     
     
     
    function setMinSign(uint40 _newMinSignId)
        public
        onlyOperator
    {
        require (_newMinSignId > minSignId);
        minSignId = _newMinSignId;
        emit MinSignSet(minSignId);
    }


    event BreedingApproval(address indexed _owner, address indexed _approved, uint256 _tokenId);

     
    address public upgradedContractAddress;

    function isCutieCore() pure public returns (bool) { return true; }

     
    function BlockchainCutiesCore() public
    {
         
        paused = true;

         
        ownerAddress = msg.sender;

         
        operatorAddress = msg.sender;

         
        _createCutie(0, 0, 0, 0, uint256(-1), address(0), 0);
    }

    event ContractUpgrade(address newContract);

     
     
     
     
     
    function setUpgradedAddress(address _newAddress) public onlyOwner whenPaused
    {
        require(_newAddress != address(0));
        upgradedContractAddress = _newAddress;
        emit ContractUpgrade(upgradedContractAddress);
    }

     
     
     
     
    function migrate(address _oldAddress, uint40 _fromIndex, uint40 _toIndex) public onlyOwner whenPaused
    {
        require(_totalSupply() + 1 == _fromIndex);

        BlockchainCutiesCore old = BlockchainCutiesCore(_oldAddress);

        for (uint40 i = _fromIndex; i <= _toIndex; i++)
        {
            uint256 genes;
            uint40 birthTime;
            uint40 cooldownEndTime;
            uint40 momId;
            uint40 dadId;
            uint16 cooldownIndex;
            uint16 generation;            
            (genes, birthTime, cooldownEndTime, momId, dadId, cooldownIndex, generation) = old.getCutie(i);

            Cutie memory _cutie = Cutie({
                genes: genes, 
                birthTime: birthTime, 
                cooldownEndTime: cooldownEndTime, 
                momId: momId, 
                dadId: dadId, 
                cooldownIndex: cooldownIndex, 
                generation: generation,
                optional: 0
            });
            cuties.push(_cutie);
        }
    }

     
     
     
     
    function migrate2(address _oldAddress, uint40 _fromIndex, uint40 _toIndex, address saleAddress, address breedingAddress) public onlyOwner whenPaused
    {
        BlockchainCutiesCore old = BlockchainCutiesCore(_oldAddress);
        MarketInterface oldSaleMarket = MarketInterface(saleAddress);
        MarketInterface oldBreedingMarket = MarketInterface(breedingAddress);

        for (uint40 i = _fromIndex; i <= _toIndex; i++)
        {
            address owner = old.ownerOf(i);

            if (owner == saleAddress)
            {
                (owner,,,,,) = oldSaleMarket.getAuctionInfo(i);
            }

            if (owner == breedingAddress)
            {
                (owner,,,,,) = oldBreedingMarket.getAuctionInfo(i);
            }
            _transfer(0, owner, i);
        }
    }

     
    function unpause() public onlyOwner whenPaused
    {
        require(upgradedContractAddress == address(0));

        paused = false;
    }

     
    uint40 public promoCutieCreatedCount;
    uint40 public gen0CutieCreatedCount;
    uint40 public gen0Limit = 50000;
    uint40 public promoLimit = 5000;

     
     
    function createGen0Auction(uint256 _genes, uint128 startPrice, uint128 endPrice, uint40 duration) public onlyOperator
    {
        require(gen0CutieCreatedCount < gen0Limit);
        uint40 cutieId = _createCutie(0, 0, 0, 0, _genes, address(this), uint40(now));
        _approve(cutieId, saleMarket);

        saleMarket.createAuction(
            cutieId,
            startPrice,
            endPrice,
            duration,
            address(this)
        );

        gen0CutieCreatedCount++;
    }

    function createPromoCutie(uint256 _genes, address _owner) public onlyOperator
    {
        require(promoCutieCreatedCount < promoLimit);
        if (_owner == address(0)) {
             _owner = operatorAddress;
        }
        promoCutieCreatedCount++;
        gen0CutieCreatedCount++;
        _createCutie(0, 0, 0, 0, _genes, _owner, uint40(now));
    }

     
     
     
     
     
    function createBreedingAuction(
        uint40 _cutieId,
        uint128 _startPrice,
        uint128 _endPrice,
        uint40 _duration
    )
        public
        whenNotPaused
        payable
    {
         
         
         
        require(_isOwner(msg.sender, _cutieId));
        require(canBreed(_cutieId));
        _approve(_cutieId, breedingMarket);
         
         
        breedingMarket.createAuction.value(msg.value)(
            _cutieId,
            _startPrice,
            _endPrice,
            _duration,
            msg.sender
        );
    }

     
     
     
    function setMarketAddress(address _breedingAddress, address _saleAddress) public onlyOwner
    {
         
         

        breedingMarket = MarketInterface(_breedingAddress);
        saleMarket = MarketInterface(_saleAddress);
    }

     
     
     
     
    function bidOnBreedingAuction(
        uint40 _dadId,
        uint40 _momId
    )
        public
        payable
        whenNotPaused
        returns (uint256)
    {
         
        require(_isOwner(msg.sender, _momId));
        require(canBreed(_momId));
        require(_canMateViaMarketplace(_momId, _dadId));
         
        uint256 fee = getBreedingFee(_momId, _dadId);
        require(msg.value >= fee);

         
        breedingMarket.bid.value(msg.value - fee)(_dadId);
        return _breedWith(_momId, _dadId);
    }

     
     
     
     
    function createSaleAuction(
        uint40 _cutieId,
        uint128 _startPrice,
        uint128 _endPrice,
        uint40 _duration
    )
        public
        whenNotPaused
        payable
    {
         
         
         
        require(_isOwner(msg.sender, _cutieId));
        _approve(_cutieId, saleMarket);
         
         
        saleMarket.createAuction.value(msg.value)(
            _cutieId,
            _startPrice,
            _endPrice,
            _duration,
            msg.sender
        );
    }

     
    GeneMixerInterface geneMixer;

     
     
     
    function _isBreedingPermitted(uint40 _dadId, uint40 _momId) internal view returns (bool)
    {
        address momOwner = cutieIndexToOwner[_momId];
        address dadOwner = cutieIndexToOwner[_dadId];

         
         
        return (momOwner == dadOwner || sireAllowedToAddress[_dadId] == momOwner);
    }

     
     
    function setGeneMixerAddress(address _address) public onlyOwner
    {
        GeneMixerInterface candidateContract = GeneMixerInterface(_address);

        require(candidateContract.isGeneMixer());

         
        geneMixer = candidateContract;
    }

     
     
    function _canBreed(Cutie _cutie) internal view returns (bool)
    {
        return _cutie.cooldownEndTime <= now;
    }

     
     
     
     
    function approveBreeding(address _addr, uint40 _dadId) public whenNotPaused
    {
        require(_isOwner(msg.sender, _dadId));
        sireAllowedToAddress[_dadId] = _addr;
        emit BreedingApproval(msg.sender, _addr, _dadId);
    }

     
     
     
    function _triggerCooldown(uint40 _cutieId, Cutie storage _cutie) internal
    {
         
        uint40 oldValue = _cutie.cooldownIndex;
        _cutie.cooldownEndTime = config.getCooldownEndTimeFromIndex(_cutie.cooldownIndex);
        emit CooldownEndTimeChanged(_cutieId, oldValue, _cutie.cooldownEndTime);

         
        if (_cutie.cooldownIndex + 1 < config.getCooldownIndexCount()) {
            uint16 oldValue2 = _cutie.cooldownIndex;
            _cutie.cooldownIndex++;
            emit CooldownIndexChanged(_cutieId, oldValue2, _cutie.cooldownIndex);
        }
    }

     
     
     
    function canBreed(uint40 _cutieId)
        public
        view
        returns (bool)
    {
        require(_cutieId > 0);
        Cutie storage cutie = cuties[_cutieId];
        return _canBreed(cutie);
    }

     
    function _canPairMate(
        Cutie storage _mom,
        uint40 _momId,
        Cutie storage _dad,
        uint40 _dadId
    )
        private
        view
        returns(bool)
    {
         
        if (_dadId == _momId) { 
            return false; 
        }

         
        if (_mom.momId == _dadId) {
            return false;
        }
        if (_mom.dadId == _dadId) {
            return false;
        }

        if (_dad.momId == _momId) {
            return false;
        }
        if (_dad.dadId == _momId) {
            return false;
        }

         
         
        if (_dad.momId == 0) {
            return true;
        }
        if (_mom.momId == 0) {
            return true;
        }

         
        if (_dad.momId == _mom.momId) {
            return false;
        }
        if (_dad.momId == _mom.dadId) {
            return false;
        }
        if (_dad.dadId == _mom.momId) {
            return false;
        }
        if (_dad.dadId == _mom.dadId) {
            return false;
        }

        if (geneMixer.canBreed(_momId, _mom.genes, _dadId, _dad.genes)) {
            return true;
        }
        return false;
    }

     
     
     
     
     
    function canBreedWith(uint40 _momId, uint40 _dadId)
        public
        view
        returns(bool)
    {
        require(_momId > 0);
        require(_dadId > 0);
        Cutie storage mom = cuties[_momId];
        Cutie storage dad = cuties[_dadId];
        return _canPairMate(mom, _momId, dad, _dadId) && _isBreedingPermitted(_dadId, _momId);
    }
    
     
     
    function _canMateViaMarketplace(uint40 _momId, uint40 _dadId)
        internal
        view
        returns (bool)
    {
        Cutie storage mom = cuties[_momId];
        Cutie storage dad = cuties[_dadId];
        return _canPairMate(mom, _momId, dad, _dadId);
    }

    function getBreedingFee(uint40 _momId, uint40 _dadId)
        public
        view
        returns (uint256)
    {
        return config.getBreedingFee(_momId, _dadId);
    }


     
     
     
     
     
    function breedWith(uint40 _momId, uint40 _dadId) 
        public
        whenNotPaused
        payable
        returns (uint40)
    {
         
        require(_isOwner(msg.sender, _momId));

         
         
         
         
         
         
         
         
         
         

         
         
         
        require(_isBreedingPermitted(_dadId, _momId));

         
        require(getBreedingFee(_momId, _dadId) <= msg.value);

         
        Cutie storage mom = cuties[_momId];

         
        require(_canBreed(mom));

         
        Cutie storage dad = cuties[_dadId];

         
        require(_canBreed(dad));

         
        require(_canPairMate(
            mom,
            _momId,
            dad,
            _dadId
        ));

        return _breedWith(_momId, _dadId);
    }

     
     
    function _breedWith(uint40 _momId, uint40 _dadId) internal returns (uint40)
    {
         
        Cutie storage dad = cuties[_dadId];
        Cutie storage mom = cuties[_momId];

         
        _triggerCooldown(_dadId, dad);
        _triggerCooldown(_momId, mom);

         
        delete sireAllowedToAddress[_momId];
        delete sireAllowedToAddress[_dadId];

         
        require(mom.birthTime != 0);

         
        uint16 babyGen = config.getBabyGen(mom.generation, dad.generation);

         
        uint256 childGenes = geneMixer.mixGenes(mom.genes, dad.genes);

         
        address owner = cutieIndexToOwner[_momId];
        uint40 cutieId = _createCutie(_momId, _dadId, babyGen, getCooldownIndexFromGeneration(babyGen), childGenes, owner, mom.cooldownEndTime);

         
        return cutieId;
    }

    mapping(address => uint40) isTutorialPetUsed;

     
     
     
    function bidOnBreedingAuctionTutorial(
        uint40 _dadId
    )
        public
        payable
        whenNotPaused
        returns (uint)
    {
        require(isTutorialPetUsed[msg.sender] == 0);

         
        uint256 fee = getBreedingFee(0, _dadId);
        require(msg.value >= fee);

         
        breedingMarket.bid.value(msg.value - fee)(_dadId);

         
        Cutie storage dad = cuties[_dadId];

         
        _triggerCooldown(_dadId, dad);

         
        delete sireAllowedToAddress[_dadId];

        uint16 babyGen = config.getTutorialBabyGen(dad.generation);

         
        uint256 childGenes = geneMixer.mixGenes(0x0, dad.genes);

         
        uint40 cutieId = _createCutie(0, _dadId, babyGen, getCooldownIndexFromGeneration(babyGen), childGenes, msg.sender, 12);

        isTutorialPetUsed[msg.sender] = cutieId;

         
        return cutieId;
    }

    address party1address;
    address party2address;
    address party3address;
    address party4address;
    address party5address;

     
    function setParties(address _party1, address _party2, address _party3, address _party4, address _party5) public onlyOwner
    {
        require(_party1 != address(0));
        require(_party2 != address(0));
        require(_party3 != address(0));
        require(_party4 != address(0));
        require(_party5 != address(0));

        party1address = _party1;
        party2address = _party2;
        party3address = _party3;
        party4address = _party4;
        party5address = _party5;
    }

     
    function() external payable {
        require(
            msg.sender == address(saleMarket) ||
            msg.sender == address(breedingMarket) ||
            address(plugins[msg.sender]) != address(0)
        );
    }

     
     
    function withdrawBalances() external
    {
        require(
            msg.sender == ownerAddress || 
            msg.sender == operatorAddress);

        saleMarket.withdrawEthFromBalance();
        breedingMarket.withdrawEthFromBalance();
        for (uint32 i = 0; i < pluginsArray.length; ++i)        
        {
            pluginsArray[i].withdraw();
        }
    }

     
    function withdrawEthFromBalance() external
    {
        require(
            msg.sender == party1address ||
            msg.sender == party2address ||
            msg.sender == party3address ||
            msg.sender == party4address ||
            msg.sender == party5address ||
            msg.sender == ownerAddress || 
            msg.sender == operatorAddress);

        require(party1address != 0);
        require(party2address != 0);
        require(party3address != 0);
        require(party4address != 0);
        require(party5address != 0);

        uint256 total = address(this).balance;

        party1address.transfer(total*105/1000);
        party2address.transfer(total*105/1000);
        party3address.transfer(total*140/1000);
        party4address.transfer(total*140/1000);
        party5address.transfer(total*510/1000);
    }

 

    struct slice
    {
        uint _len;
        uint _ptr;
    }

     
    function toSlice(string self) internal pure returns (slice)
    {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    function memcpy(uint dest, uint src, uint len) private pure
    {
         
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

     
    function concat(slice self, slice other) internal pure returns (string)
    {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }


    function uintToString(uint256 a) internal pure returns (string result)
    {
        string memory r = "";
        do
        {
            uint b = a % 10;
            a /= 10;

            string memory c = "";

            if (b == 0) c = "0";
            else if (b == 1) c = "1";
            else if (b == 2) c = "2";
            else if (b == 3) c = "3";
            else if (b == 4) c = "4";
            else if (b == 5) c = "5";
            else if (b == 6) c = "6";
            else if (b == 7) c = "7";
            else if (b == 8) c = "8";
            else if (b == 9) c = "9";

            r = concat(toSlice(c), toSlice(r));
        }
        while (a > 0);
        result = r;
    }
}