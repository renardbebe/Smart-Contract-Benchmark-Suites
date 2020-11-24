 

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


 
 
 
contract CobeFriendACL {
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
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


 
 
 
contract CobeFriendBase is CobeFriendACL {
	 

	 
	 
	 
	event Birth(address owner, uint256 CobeFriendId, uint256 matronId, uint256 sireId, uint256 genes, uint256 generation);

	 
	 
	event Transfer(address from, address to, uint256 tokenId);

	 

	 
	 
	 
	 
	 
	struct CobeFriend {
		 
		 
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

	 

	 
	 
	 
	 
	 
	CobeFriend[] CobeFriends;

	 
	 
	mapping (uint256 => address) public CobeFriendIndexToOwner;

	 
	 
	mapping (address => uint256) ownershipTokenCount;

	 
	 
	 
	mapping (uint256 => address) public CobeFriendIndexToApproved;

	 
	 
	 
	mapping (uint256 => address) public sireAllowedToAddress;

	 
	 
	 
	SaleClockAuction public saleAuction;

	 
	function _transfer(address _from, address _to, uint256 _tokenId) internal {
		 
		ownershipTokenCount[_to]++;
		 
		CobeFriendIndexToOwner[_tokenId] = _to;
		 
		if (_from != address(0)) {
			ownershipTokenCount[_from]--;
			 
			delete sireAllowedToAddress[_tokenId];
			 
			delete CobeFriendIndexToApproved[_tokenId];
		}
		 
		Transfer(_from, _to, _tokenId);
	}

	 
	 
	 
	 
	 
	 
	 
	 
	 
	function _createCobeFriend(
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

		CobeFriend memory _CobeFriend = CobeFriend({
			genes: _genes,
			birthTime: uint64(now),
			cooldownEndBlock: 0,
			matronId: uint32(_matronId),
			sireId: uint32(_sireId),
			siringWithId: 0,
			cooldownIndex: cooldownIndex,
			generation: uint16(_generation)
		});
		uint256 newCobeFriendId = CobeFriends.push(_CobeFriend) - 1;

		 
		 
		require(newCobeFriendId == uint256(uint32(newCobeFriendId)));

		 
		Birth(
			_owner,
			newCobeFriendId,
			uint256(_CobeFriend.matronId),
			uint256(_CobeFriend.sireId),
			_CobeFriend.genes,
            uint256(_CobeFriend.generation)
		);

		 
		 
		_transfer(0, _owner, newCobeFriendId);

		return newCobeFriendId;
	}

	 
	 
	 
	 
	 
	 
	 
	 
	 
     
     
	function _createCobeFriendWithTime(
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

		CobeFriend memory _CobeFriend = CobeFriend({
			genes: _genes,
			birthTime: uint64(_time),
			cooldownEndBlock: 0,
			matronId: uint32(_matronId),
			sireId: uint32(_sireId),
			siringWithId: 0,
			cooldownIndex: cooldownIndex,
			generation: uint16(_generation)
			});
		uint256 newCobeFriendId = CobeFriends.push(_CobeFriend) - 1;

		 
		 
		require(newCobeFriendId == uint256(uint32(newCobeFriendId)));

		 
		Birth(
			_owner,
			newCobeFriendId,
			uint256(_CobeFriend.matronId),
			uint256(_CobeFriend.sireId),
			_CobeFriend.genes,
            uint256(_CobeFriend.generation)
		);

		 
		 
		_transfer(0, _owner, newCobeFriendId);

		return newCobeFriendId;
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


 
 
 
contract CobeFriendOwnership is CobeFriendBase, ERC721 {

     
    string public constant name = "CobeFriends";
    string public constant symbol = "CBF";

     
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
        return CobeFriendIndexToOwner[_tokenId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return CobeFriendIndexToApproved[_tokenId] == _claimant;
    }

     
     
     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        CobeFriendIndexToApproved[_tokenId] = _approved;
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
        return CobeFriends.length - 1;
    }

     
     
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = CobeFriendIndexToOwner[_tokenId];

        require(owner != address(0));
    }

     
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalcbfs = totalSupply();
            uint256 resultIndex = 0;

             
             
            uint256 cbfId;

            for (cbfId = 1; cbfId <= totalcbfs; cbfId++) {
                if (CobeFriendIndexToOwner[cbfId] == _owner) {
                    result[resultIndex] = cbfId;
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


 
 
 
contract CobeFriendAuction is CobeFriendOwnership {

     
     
     
     

     
     
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

         
        require(candidateContract.isSaleClockAuction());

         
        saleAuction = candidateContract;
    }

     
     
    function createSaleAuction(
        uint256 _CobeFriendId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _CobeFriendId));
        _approve(_CobeFriendId, saleAuction);
         
         
        saleAuction.createAuction(
            _CobeFriendId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }


     
     
     
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
    }
}


 
contract CobeFriendMinting is CobeFriendAuction {

     
    uint256 public constant DEFAULT_CREATION_LIMIT = 50000;

     
    uint256 public defaultCreatedCount;


     
     
     
     
     
    function createDefaultGen0CobeFriend(uint256 _genes, address _owner, uint256 _time, uint256 _cooldownIndex) external onlyCOO {

        require(_time == uint256(uint64(_time)));
        require(_cooldownIndex == uint256(uint16(_cooldownIndex)));

        require(_time > 0);
        require(_cooldownIndex >= 0 && _cooldownIndex <= 13);

        address CobeFriendOwner = _owner;
        if (CobeFriendOwner == address(0)) {
            CobeFriendOwner = cooAddress;
        }
        require(defaultCreatedCount < DEFAULT_CREATION_LIMIT);

        defaultCreatedCount++;
        _createCobeFriendWithTime(0, 0, 0, _genes, CobeFriendOwner, _time, _cooldownIndex);
    }

     
     
     
     
     
     
     
    function createDefaultCobeFriend(uint256 _matronId, uint256 _sireId, uint256 _genes, address _owner, uint256 _time, uint256 _cooldownIndex) external onlyCOO {

        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_time == uint256(uint64(_time)));
        require(_cooldownIndex == uint256(uint16(_cooldownIndex)));

        require(_time > 0);
        require(_cooldownIndex >= 0 && _cooldownIndex <= 13);

        address CobeFriendOwner = _owner;
        if (CobeFriendOwner == address(0)) {
            CobeFriendOwner = cooAddress;
        }

        require(_matronId > 0);
        require(_sireId > 0);

         
        CobeFriend storage matron = CobeFriends[_matronId];

         
        CobeFriend storage sire = CobeFriends[_sireId];

         
        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

        _createCobeFriendWithTime(_matronId, _sireId, parentGen + 1, _genes, CobeFriendOwner, _time, _cooldownIndex);
    }

}


 
 
contract CobeFriendCore is CobeFriendMinting {
 
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    address public newContractAddress;

     
    function CobeFriendCore() public {
         
        paused = true;

         
        ceoAddress = msg.sender;

         
        cooAddress = msg.sender;

         
        _createCobeFriend(0, 0, 0, uint256(-1), address(0));
    }

     
     
     
     
     
     
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
         
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

     
     
     
    function() external payable {
        require(
            msg.sender == address(saleAuction)
        );
    }

     
     
    function getCobeFriend(uint256 _id)
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
        CobeFriend storage cbf = CobeFriends[_id];

         
        isGestating = (cbf.siringWithId != 0);
        isReady = (cbf.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(cbf.cooldownIndex);
        nextActionAt = uint256(cbf.cooldownEndBlock);
        siringWithId = uint256(cbf.siringWithId);
        birthTime = uint256(cbf.birthTime);
        matronId = uint256(cbf.matronId);
        sireId = uint256(cbf.sireId);
        generation = uint256(cbf.generation);
        genes = cbf.genes;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(newContractAddress == address(0));

         
        super.unpause();
    }

     
    function withdrawBalance() external onlyCFO {
        uint256 balance = this.balance;
        cfoAddress.transfer(balance);
    }
}