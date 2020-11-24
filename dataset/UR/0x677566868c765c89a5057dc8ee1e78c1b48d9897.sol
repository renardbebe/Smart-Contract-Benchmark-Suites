 

pragma solidity ^0.4.18;

 
contract Ownable {
	address public owner;


	 
	function Ownable() public {
		owner = msg.sender;
	}


	 
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}


	 
	function transferOwnership(address newOwner) public onlyOwner {
		if (newOwner != address(0)) {
			owner = newOwner;
		}
	}

}


 
 
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
}


 
contract GeneScienceInterface {
     
    function isGeneScience() public pure returns (bool);

     
     
     
     
    function mixGenes(uint256 genes1, uint256 genes2, uint256 targetBlock) public returns (uint256);
}


 
 
 
contract LinglongCatACL {
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    event ContractUpgrade(address newContract);

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

     
    bool public paused = false;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

     
     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

     
     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

     
     
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
         
        paused = false;
    }
}


 
 
 
contract LinglongCatBase is LinglongCatACL {
	 

	 
	 
	 
	event Birth(address owner, uint256 LinglongCatId, uint256 matronId, uint256 sireId, uint256 genes, uint256 generation);

	 
	 
	event Transfer(address from, address to, uint256 tokenId);

	 

	 
	 
	 
	 
	 
	struct LinglongCat {
		 
		 
		uint256 genes;

		 
		uint64 birthTime;

		 
		 
		 
		uint64 cooldownEndBlock;

		 
		 
		 
		 
		 
		 
		uint32 matronId;
		uint32 sireId;

		 
		 
		 
		 
		uint32 siringWithId;

		 
		 
		 
		 
		 
		uint16 cooldownIndex;

		 
		 
		 
		 
		 
		uint16 generation;
	}

	 

	 
	 
	 
	 
	 
	 
	uint32[14] public cooldowns = [
		uint32(1 minutes),
		uint32(2 minutes),
		uint32(5 minutes),
		uint32(10 minutes),
		uint32(30 minutes),
		uint32(1 hours),
		uint32(2 hours),
		uint32(4 hours),
		uint32(8 hours),
		uint32(16 hours),
		uint32(1 days),
		uint32(2 days),
		uint32(4 days),
		uint32(7 days)
	];

	 
	uint256 public secondsPerBlock = 15;

	 

	 
	 
	 
	 
	 
	LinglongCat[] LinglongCats;

	 
	 
	mapping (uint256 => address) public LinglongCatIndexToOwner;

	 
	 
	mapping (address => uint256) ownershipTokenCount;

	 
	 
	 
	mapping (uint256 => address) public LinglongCatIndexToApproved;

	 
	 
	 
	mapping (uint256 => address) public sireAllowedToAddress;

	 
	 
	 
	SaleClockAuction public saleAuction;

	 
	 
	 
	SiringClockAuction public siringAuction;

	 
	function _transfer(address _from, address _to, uint256 _tokenId) internal {
		 
		ownershipTokenCount[_to]++;
		 
		LinglongCatIndexToOwner[_tokenId] = _to;
		 
		if (_from != address(0)) {
			ownershipTokenCount[_from]--;
			 
			delete sireAllowedToAddress[_tokenId];
			 
			delete LinglongCatIndexToApproved[_tokenId];
		}
		 
		Transfer(_from, _to, _tokenId);
	}

	 
	 
	 
	 
	 
	 
	 
	 
	 
	function _createLinglongCat(
		uint256 _matronId,
		uint256 _sireId,
		uint256 _generation,
		uint256 _genes,
		address _owner
	)
		internal
		returns (uint)
	{
		 
		 
		 
		 
		require(_matronId == uint256(uint32(_matronId)));
		require(_sireId == uint256(uint32(_sireId)));
		require(_generation == uint256(uint16(_generation)));

		 
		uint16 cooldownIndex = uint16(_generation / 2);
		if (cooldownIndex > 13) {
			cooldownIndex = 13;
		}

		LinglongCat memory _LinglongCat = LinglongCat({
			genes: _genes,
			birthTime: uint64(now),
			cooldownEndBlock: 0,
			matronId: uint32(_matronId),
			sireId: uint32(_sireId),
			siringWithId: 0,
			cooldownIndex: cooldownIndex,
			generation: uint16(_generation)
		});
		uint256 newLinglongCatId = LinglongCats.push(_LinglongCat) - 1;

		 
		 
		require(newLinglongCatId == uint256(uint32(newLinglongCatId)));

		 
		Birth(
			_owner,
			newLinglongCatId,
			uint256(_LinglongCat.matronId),
			uint256(_LinglongCat.sireId),
			_LinglongCat.genes,
            uint256(_LinglongCat.generation)
		);

		 
		 
		_transfer(0, _owner, newLinglongCatId);

		return newLinglongCatId;
	}

	 
	 
	 
	 
	 
	 
	 
	 
	 
     
     
	function _createLinglongCatWithTime(
		uint256 _matronId,
		uint256 _sireId,
		uint256 _generation,
		uint256 _genes,
		address _owner,
        uint256 _time,
        uint256 _cooldownIndex
	)
	internal
	returns (uint)
	{
		 
		 
		 
		 
		require(_matronId == uint256(uint32(_matronId)));
		require(_sireId == uint256(uint32(_sireId)));
		require(_generation == uint256(uint16(_generation)));
        require(_time == uint256(uint64(_time)));
        require(_cooldownIndex == uint256(uint16(_cooldownIndex)));

         
        uint16 cooldownIndex = uint16(_cooldownIndex);
		if (cooldownIndex > 13) {
			cooldownIndex = 13;
		}

		LinglongCat memory _LinglongCat = LinglongCat({
			genes: _genes,
			birthTime: uint64(_time),
			cooldownEndBlock: 0,
			matronId: uint32(_matronId),
			sireId: uint32(_sireId),
			siringWithId: 0,
			cooldownIndex: cooldownIndex,
			generation: uint16(_generation)
			});
		uint256 newLinglongCatId = LinglongCats.push(_LinglongCat) - 1;

		 
		 
		require(newLinglongCatId == uint256(uint32(newLinglongCatId)));

		 
		Birth(
			_owner,
			newLinglongCatId,
			uint256(_LinglongCat.matronId),
			uint256(_LinglongCat.sireId),
			_LinglongCat.genes,
            uint256(_LinglongCat.generation)
		);

		 
		 
		_transfer(0, _owner, newLinglongCatId);

		return newLinglongCatId;
	}

	 
	function setSecondsPerBlock(uint256 secs) external onlyCLevel {
		require(secs < cooldowns[0]);
		secondsPerBlock = secs;
	}
}


 
 
contract ERC721Metadata {
     
    function getMetadata(uint256 _tokenId, string) public pure returns (bytes32[4] buffer, uint256 count) {
        if (_tokenId == 1) {
            buffer[0] = "Hello World! :D";
            count = 15;
        } else if (_tokenId == 2) {
            buffer[0] = "I would definitely choose a medi";
            buffer[1] = "um length string.";
            count = 49;
        } else if (_tokenId == 3) {
            buffer[0] = "Lorem ipsum dolor sit amet, mi e";
            buffer[1] = "st accumsan dapibus augue lorem,";
            buffer[2] = " tristique vestibulum id, libero";
            buffer[3] = " suscipit varius sapien aliquam.";
            count = 128;
        }
    }
}


 
 
 
contract LinglongCatOwnership is LinglongCatBase, ERC721 {

     
    string public constant name = "LinglongCats";
    string public constant symbol = "LLCAT";

     
    ERC721Metadata public erc721Metadata;

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
        bytes4(keccak256('tokensOfOwner(address)')) ^
        bytes4(keccak256('tokenMetadata(uint256,string)'));

     
     
     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
         
         

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

     
     
    function setMetadataAddress(address _contractAddress) public onlyCEO {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }

     
     
     

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return LinglongCatIndexToOwner[_tokenId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return LinglongCatIndexToApproved[_tokenId] == _claimant;
    }

     
     
     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        LinglongCatIndexToApproved[_tokenId] = _approved;
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

     
     
     
     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
         
         
        require(_to != address(saleAuction));
        require(_to != address(siringAuction));

         
        require(_owns(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
         
        require(_owns(msg.sender, _tokenId));

         
        _approve(_tokenId, _to);

         
        Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

     
     
    function totalSupply() public view returns (uint) {
        return LinglongCats.length - 1;
    }

     
     
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = LinglongCatIndexToOwner[_tokenId];

        require(owner != address(0));
    }

     
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalcats = totalSupply();
            uint256 resultIndex = 0;

             
             
            uint256 catId;

            for (catId = 1; catId <= totalcats; catId++) {
                if (LinglongCatIndexToOwner[catId] == _owner) {
                    result[resultIndex] = catId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

     
     
     
    function _memcpy(uint _dest, uint _src, uint _len) private view {
         
        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

         
        uint256 mask = 256 ** (32 - _len) - 1;
        assembly {
            let srcpart := and(mload(_src), not(mask))
            let destpart := and(mload(_dest), mask)
            mstore(_dest, or(destpart, srcpart))
        }
    }

     
     
     
    function _toString(bytes32[4] _rawBytes, uint256 _stringLength) private view returns (string) {
        var outputString = new string(_stringLength);
        uint256 outputPtr;
        uint256 bytesPtr;

        assembly {
            outputPtr := add(outputString, 32)
            bytesPtr := _rawBytes
        }

        _memcpy(outputPtr, bytesPtr, _stringLength);

        return outputString;
    }

     
     
     
    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl) {
        require(erc721Metadata != address(0));
        bytes32[4] memory buffer;
        uint256 count;
        (buffer, count) = erc721Metadata.getMetadata(_tokenId, _preferredTransport);

        return _toString(buffer, count);
    }
}


 
 
 
contract LinglongCatBreeding is LinglongCatOwnership {

     
     
    event Pregnant(address owner, uint256 matronId, uint256 sireId, uint256 matronCooldownEndBlock, uint256 sireCooldownEndBlock);

     
     
     
    uint256 public autoBirthFee = 2 finney;

     
    uint256 public pregnantLinglongCats;

     
     
    GeneScienceInterface public geneScience;

     
     
    function setGeneScienceAddress(address _address) external onlyCEO {
        GeneScienceInterface candidateContract = GeneScienceInterface(_address);

         
        require(candidateContract.isGeneScience());

         
        geneScience = candidateContract;
    }

     
     
     
    function _isReadyToBreed(LinglongCat _cat) internal view returns (bool) {
         
         
         
        return (_cat.siringWithId == 0) && (_cat.cooldownEndBlock <= uint64(block.number));
    }

     
     
     
    function _isSiringPermitted(uint256 _sireId, uint256 _matronId) internal view returns (bool) {
        address matronOwner = LinglongCatIndexToOwner[_matronId];
        address sireOwner = LinglongCatIndexToOwner[_sireId];

         
         
        return (matronOwner == sireOwner || sireAllowedToAddress[_sireId] == matronOwner);
    }

     
     
     
    function _triggerCooldown(LinglongCat storage _cat) internal {
         
        _cat.cooldownEndBlock = uint64((cooldowns[_cat.cooldownIndex]/secondsPerBlock) + block.number);

         
         
         
        if (_cat.cooldownIndex < 13) {
            _cat.cooldownIndex += 1;
        }
    }

     
     
     
     
    function approveSiring(address _addr, uint256 _sireId)
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _sireId));
        sireAllowedToAddress[_sireId] = _addr;
    }

     
     
     
    function setAutoBirthFee(uint256 val) external onlyCOO {
        autoBirthFee = val;
    }

     
     
    function _isReadyToGiveBirth(LinglongCat _matron) private view returns (bool) {
        return (_matron.siringWithId != 0) && (_matron.cooldownEndBlock <= uint64(block.number));
    }

     
     
     
    function isReadyToBreed(uint256 _LinglongCatId)
        public
        view
        returns (bool)
    {
        require(_LinglongCatId > 0);
        LinglongCat storage kit = LinglongCats[_LinglongCatId];
        return _isReadyToBreed(kit);
    }

     
     
    function isPregnant(uint256 _LinglongCatId)
        public
        view
        returns (bool)
    {
        require(_LinglongCatId > 0);
         
        return LinglongCats[_LinglongCatId].siringWithId != 0;
    }

     
     
     
     
     
     
    function _isValidMatingPair(
        LinglongCat storage _matron,
        uint256 _matronId,
        LinglongCat storage _sire,
        uint256 _sireId
    )
        private
        view
        returns(bool)
    {
         
        if (_matronId == _sireId) {
            return false;
        }

         
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

         
         
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

         
        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

         
        return true;
    }

     
     
    function _canBreedWithViaAuction(uint256 _matronId, uint256 _sireId)
        internal
        view
        returns (bool)
    {
        LinglongCat storage matron = LinglongCats[_matronId];
        LinglongCat storage sire = LinglongCats[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId);
    }

     
     
     
     
     
     
    function canBreedWith(uint256 _matronId, uint256 _sireId)
        external
        view
        returns(bool)
    {
        require(_matronId > 0);
        require(_sireId > 0);
        LinglongCat storage matron = LinglongCats[_matronId];
        LinglongCat storage sire = LinglongCats[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId) &&
            _isSiringPermitted(_sireId, _matronId);
    }

     
     
    function _breedWith(uint256 _matronId, uint256 _sireId) internal {
         
        LinglongCat storage sire = LinglongCats[_sireId];
        LinglongCat storage matron = LinglongCats[_matronId];

         
        matron.siringWithId = uint32(_sireId);

         
        _triggerCooldown(sire);
        _triggerCooldown(matron);

         
         
        delete sireAllowedToAddress[_matronId];
        delete sireAllowedToAddress[_sireId];

         
        pregnantLinglongCats++;

         
        Pregnant(LinglongCatIndexToOwner[_matronId], _matronId, _sireId, matron.cooldownEndBlock, sire.cooldownEndBlock);
    }

     
     
     
     
     
    function breedWithAuto(uint256 _matronId, uint256 _sireId)
        external
        payable
        whenNotPaused
    {
         
        require(msg.value >= autoBirthFee);

         
        require(_owns(msg.sender, _matronId));

         
         
         
         
         
         
         
         
         
         

         
         
         
        require(_isSiringPermitted(_sireId, _matronId));

         
        LinglongCat storage matron = LinglongCats[_matronId];

         
        require(_isReadyToBreed(matron));

         
        LinglongCat storage sire = LinglongCats[_sireId];

         
        require(_isReadyToBreed(sire));

         
        require(_isValidMatingPair(
            matron,
            _matronId,
            sire,
            _sireId
        ));

         
        _breedWith(_matronId, _sireId);
    }

     
     
     
     
     
     
     
     
    function giveBirth(uint256 _matronId)
        external
        whenNotPaused
        returns(uint256)
    {
         
        LinglongCat storage matron = LinglongCats[_matronId];

         
        require(matron.birthTime != 0);

         
        require(_isReadyToGiveBirth(matron));

         
        uint256 sireId = matron.siringWithId;
        LinglongCat storage sire = LinglongCats[sireId];

         
        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

         
        uint256 childGenes = geneScience.mixGenes(matron.genes, sire.genes, matron.cooldownEndBlock - 1);

         
        address owner = LinglongCatIndexToOwner[_matronId];
        uint256 LinglongCatId = _createLinglongCat(_matronId, matron.siringWithId, parentGen + 1, childGenes, owner);

         
         
        delete matron.siringWithId;

         
        pregnantLinglongCats--;

         
        msg.sender.transfer(autoBirthFee);

         
        return LinglongCatId;
    }
}






 
 
 
contract ClockAuctionBase {

     
    struct Auction {
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
         
        uint64 startedAt;
    }

     
    ERC721 public nonFungibleContract;

     
     
    uint256 public ownerCut;

     
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

     
     
     
     
    function _escrow(address _owner, uint256 _tokenId) internal {
         
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

     
     
     
     
    function _transfer(address _receiver, uint256 _tokenId) internal {
         
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

     
     
     
     
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
         
         
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

     
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }

     
     
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
         
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
        }

         
         
         
         
        uint256 bidExcess = _bidAmount - price;

         
         
         
        msg.sender.transfer(bidExcess);

         
        AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

     
     
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

     
     
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

     
     
     
     
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

         
         
         
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

     
     
     
     
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
         
         
         
         
         
        if (_secondsPassed >= _duration) {
             
             
            return _endingPrice;
        } else {
             
             
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

             
             
             
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

             
             
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

     
     
    function _computeCut(uint256 _price) internal view returns (uint256) {
         
         
         
         
         
        return _price * ownerCut / 10000;
    }
}






 
contract Pausable is Ownable {
	event Pause();
	event Unpause();

	bool public paused = false;


	 
	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	 
	modifier whenPaused {
		require(paused);
		_;
	}

	 
	function pause() public onlyOwner whenNotPaused returns (bool) {
		paused = true;
		Pause();
		return true;
	}

	 
	function unpause() public onlyOwner whenPaused returns (bool) {
		paused = false;
		Unpause();
		return true;
	}
}


 
 
contract ClockAuction is Pausable, ClockAuctionBase {

     
     
     
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

     
     
     
     
     
     
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }

     
     
     
     
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
         
        nftAddress.transfer(this.balance);
    }

     
     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
        whenNotPaused
    {
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

     
     
     
    function bid(uint256 _tokenId)
        external
        payable
        whenNotPaused
    {
         
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

     
     
     
     
     
    function cancelAuction(uint256 _tokenId)
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

     
     
     
     
    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

     
     
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

     
     
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}


 
 
contract SiringClockAuction is ClockAuction {

     
     
    bool public isSiringClockAuction = true;

     
    function SiringClockAuction(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}

     
     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

     
     
     
     
    function bid(uint256 _tokenId)
        external
        payable
    {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
         
        _bid(_tokenId, msg.value);
         
         
        _transfer(seller, _tokenId);
    }

}


 
 
contract SaleClockAuction is ClockAuction {

     
     
    bool public isSaleClockAuction = true;

     
    uint256 public gen0SaleCount;
    uint256[5] public lastGen0SalePrices;

     
    function SaleClockAuction(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}

     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

     
     
    function bid(uint256 _tokenId)
        external
        payable
    {
         
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);

         
        if (seller == address(nonFungibleContract)) {
             
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

    function averageGen0SalePrice() external view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += lastGen0SalePrices[i];
        }
        return sum / 5;
    }

}


 
 
 
contract LinglongCatAuction is LinglongCatBreeding {

     
     
     
     

     
     
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

         
        require(candidateContract.isSaleClockAuction());

         
        saleAuction = candidateContract;
    }

     
     
    function setSiringAuctionAddress(address _address) external onlyCEO {
        SiringClockAuction candidateContract = SiringClockAuction(_address);

         
        require(candidateContract.isSiringClockAuction());

         
        siringAuction = candidateContract;
    }

     
     
    function createSaleAuction(
        uint256 _LinglongCatId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _LinglongCatId));
         
         
         
        require(!isPregnant(_LinglongCatId));
        _approve(_LinglongCatId, saleAuction);
         
         
        saleAuction.createAuction(
            _LinglongCatId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

     
     
     
    function createSiringAuction(
        uint256 _LinglongCatId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _LinglongCatId));
        require(isReadyToBreed(_LinglongCatId));
        _approve(_LinglongCatId, siringAuction);
         
         
        siringAuction.createAuction(
            _LinglongCatId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

     
     
     
     
    function bidOnSiringAuction(
        uint256 _sireId,
        uint256 _matronId
    )
        external
        payable
        whenNotPaused
    {
         
        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(_canBreedWithViaAuction(_matronId, _sireId));

         
        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee);

         
        siringAuction.bid.value(msg.value - autoBirthFee)(_sireId);
        _breedWith(uint32(_matronId), uint32(_sireId));
    }

     
     
     
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
        siringAuction.withdrawBalance();
    }
}


 
contract LinglongCatMinting is LinglongCatAuction {

     
    uint256 public constant DEFAULT_CREATION_LIMIT = 50000;

     
    uint256 public defaultCreatedCount;


     
     
     
     
     
    function createDefaultGen0LinglongCat(uint256 _genes, address _owner, uint256 _time, uint256 _cooldownIndex) external onlyCOO {

        require(_time == uint256(uint64(_time)));
        require(_cooldownIndex == uint256(uint16(_cooldownIndex)));

        require(_time > 0);
        require(_cooldownIndex >= 0 && _cooldownIndex <= 13);

        address LinglongCatOwner = _owner;
        if (LinglongCatOwner == address(0)) {
            LinglongCatOwner = cooAddress;
        }
        require(defaultCreatedCount < DEFAULT_CREATION_LIMIT);

        defaultCreatedCount++;
        _createLinglongCatWithTime(0, 0, 0, _genes, LinglongCatOwner, _time, _cooldownIndex);
    }

     
     
     
     
     
     
     
    function createDefaultLinglongCat(uint256 _matronId, uint256 _sireId, uint256 _genes, address _owner, uint256 _time, uint256 _cooldownIndex) external onlyCOO {

        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_time == uint256(uint64(_time)));
        require(_cooldownIndex == uint256(uint16(_cooldownIndex)));

        require(_time > 0);
        require(_cooldownIndex >= 0 && _cooldownIndex <= 13);

        address LinglongCatOwner = _owner;
        if (LinglongCatOwner == address(0)) {
            LinglongCatOwner = cooAddress;
        }

        require(_matronId > 0);
        require(_sireId > 0);

         
        LinglongCat storage matron = LinglongCats[_matronId];

         
        LinglongCat storage sire = LinglongCats[_sireId];

         
        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

        _createLinglongCatWithTime(_matronId, _sireId, parentGen + 1, _genes, LinglongCatOwner, _time, _cooldownIndex);
    }

}


 
 
contract LinglongCatCore is LinglongCatMinting {
 
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    address public newContractAddress;

     
    function LinglongCatCore() public {
         
        paused = true;

         
        ceoAddress = msg.sender;

         
        cooAddress = msg.sender;

         
        _createLinglongCat(0, 0, 0, uint256(-1), address(0));
    }

     
     
     
     
     
     
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
         
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

     
     
     
    function() external payable {
        require(
            msg.sender == address(saleAuction) ||
            msg.sender == address(siringAuction)
        );
    }

     
     
    function getLinglongCat(uint256 _id)
        external
        view
        returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes
    ) {
        LinglongCat storage cat = LinglongCats[_id];

         
        isGestating = (cat.siringWithId != 0);
        isReady = (cat.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(cat.cooldownIndex);
        nextActionAt = uint256(cat.cooldownEndBlock);
        siringWithId = uint256(cat.siringWithId);
        birthTime = uint256(cat.birthTime);
        matronId = uint256(cat.matronId);
        sireId = uint256(cat.sireId);
        generation = uint256(cat.generation);
        genes = cat.genes;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(siringAuction != address(0));
        require(geneScience != address(0));
        require(newContractAddress == address(0));

         
        super.unpause();
    }

     
    function withdrawBalance() external onlyCFO {
        uint256 balance = this.balance;
         
        uint256 subtractFees = (pregnantLinglongCats + 1) * autoBirthFee;

        if (balance > subtractFees) {
            cfoAddress.transfer(balance - subtractFees);
        }
    }
}