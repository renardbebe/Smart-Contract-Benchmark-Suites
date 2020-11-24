 

pragma solidity ^0.4.25;
 
 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
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
    function transfer(address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


 


 

 
 
 
contract ArtworkAccessControl {
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
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

     
     
    function setCEO(address _newCEO) external payable onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

     
     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

     
     
    function setCOO(address _newCOO) external payable onlyCEO {
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

     
     
     
     
     
    function unpause() public payable onlyCEO whenPaused {
         
        paused = false;
    }
}




 
 
 
contract ArtworkBase is ArtworkAccessControl {
     

     
    event Birth(address owner,bytes artworkContent);
      
    event CoupledArt(address owner, uint256 topId, uint256 bottomId);
    event CoupledArtRightpiece(address owner, uint256 topId, uint256 bottomId);

     
    event Grant(uint256 _tokenToGrantControlOf, uint256 _tokenToGrantControlTo);
    event GrantControl(uint256 _tokenToGrantControlOf, uint256 _tokenToGrantControlTo);


     
     
    event Transfer(address from, address to, uint256 tokenId);

     

     
     
     
     
     
    struct Artwork {
        address creatorId;
        uint64 birthTime;
        bytes artworkContent;
    }

     


     
    uint256 public secondsPerBlock = 15;

     

     
     
     
     
     
     
    Artwork[] artworks;
    mapping (bytes => bool) isTaken;


     
     
    mapping (uint256 => address) public artworkIndexToOwner;
    mapping (uint256 => bool) public artworkIndexToPublic;
    mapping (address=> bytes32) public addressToUsername;

     
     
    mapping (address => uint256) ownershipTokenCount;

     
     
     
    mapping (uint256 => address) public artworkIndexToApproved;
    
    mapping (uint256 => uint256) public artworkIndexToLeftpiece;
    mapping (uint256 => uint256) public artworkIndexToRightpiece;
    mapping (uint256 => uint256) public artworkIndexToControlPiece;


    
         
     
     
    mapping (uint256 => address) public coupleAllowedToAddress;
     
     
     
    SaleClockAuction public saleAuction;
    CouplingClockAuction public couplingAuction;


      function _getBytes(uint256 _artworkId) internal returns (bytes artworkContent){
           return artworks[_artworkId].artworkContent;
    }

     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
        ownershipTokenCount[_to]++;
         
        artworkIndexToOwner[_tokenId] = _to;
         
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
             
            delete artworkIndexToApproved[_tokenId];
        }
         
        Transfer(_from, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function _createArtwork(
        bytes _artworkContent,
        address _owner,
        address _creatorId
    )
        internal
        returns (uint256)
    {
         
         
         
         
        require(isTaken[_artworkContent] == false);
        Artwork memory _artwork = Artwork({
            birthTime: uint64(now),
            creatorId: _creatorId,
            artworkContent: _artworkContent
        });
        
        uint256 newArtId = artworks.push(_artwork) - 1;
        isTaken[_artworkContent] = true;

         
         
        require(newArtId == uint256(newArtId));

         
        Birth(
            _artwork.creatorId,
            _artworkContent
        );
        artworkIndexToLeftpiece[newArtId] = 0;
        artworkIndexToRightpiece[newArtId] = 0;

         
         
        _transfer(0, _owner, newArtId);

        return newArtId;
    }
    
     function _assignLeftpiece(uint256 _topId, uint256 _leftId) internal {


         
        
        artworkIndexToLeftpiece[_topId] = _leftId;
         
        CoupledArt(artworkIndexToOwner[_topId], _topId, _leftId);
    }

     function _assignControlPiece(uint256 _tokenId, uint256 _controlId) internal {
    
        artworkIndexToControlPiece[_tokenId] = _controlId;
    }

    function _assignRightpiece(uint256 _topId, uint256 _rightId) internal {
         Artwork storage topArtwork = artworks[_topId];

         
         
        
        artworkIndexToRightpiece[_topId] = _rightId;
         
        CoupledArtRightpiece(artworkIndexToOwner[_topId], _topId, _rightId);
    }
    
     function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return artworkIndexToOwner[_tokenId] == _claimant;
    }
       
      
     
     
     
      function _ownsOrControls(address _claimant, uint256 _tokenId, uint256 _controlToken) internal view returns (bool) {
        return artworkIndexToOwner[_tokenId] == _claimant || artworkIndexToControlPiece[_tokenId] == _controlToken;
    }

    function _shareControl(uint256 _masterToken, uint256 _childToken) internal view returns (bool){
        return (artworkIndexToControlPiece[_childToken] == _masterToken || artworkIndexToControlPiece[_childToken] == artworkIndexToControlPiece[_masterToken]);
    }
    
     function _isCouplingPermitted(uint256 _topId, uint256 _partnerId) internal view returns (bool) {
        address topOwner = artworkIndexToOwner[_topId];
        address bottomOwner = artworkIndexToOwner[_partnerId];

         
         
        return (topOwner == bottomOwner || coupleAllowedToAddress[_partnerId] == topOwner || artworkIndexToPublic[_partnerId] == true);
    }
    
        function approveCoupling(address _addr, uint256 _partnerId)
        external payable
        whenNotPaused
    {
        require(_owns(msg.sender, _partnerId));
        coupleAllowedToAddress[_partnerId] = _addr;
    }

        function setUsername(bytes32 _username)
        external payable
        whenNotPaused
    {
        addressToUsername[msg.sender] = _username;
    }


      function setTokenAsPublic(uint256 _tokenId)
        external payable
        whenNotPaused
    {
        require(_owns(msg.sender, _tokenId));
        artworkIndexToPublic[_tokenId] = true;
    }

      function setTokenAsPrivate(uint256 _tokenId)
        external payable
        whenNotPaused
    {
        require(_owns(msg.sender, _tokenId));
        artworkIndexToPublic[_tokenId] = false;
    }
    
           function removeCouplingPermission(uint256 _partnerId)
        external payable
        whenNotPaused
    {
        require(_owns(msg.sender, _partnerId));
        coupleAllowedToAddress[_partnerId] = msg.sender;
    }

}


 
 
contract ERC721Metadata {
     
    function getMetadata(uint256 _tokenId, string) public view returns (bytes32[4] buffer, uint256 count) {
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


 
 
 
 
contract ArtworkOwnership is ArtworkBase, ERC721 {
     
    string public constant name = "glia.icu";
    string public constant symbol = "GLIA";

     
    ERC721Metadata public erc721Metadata;

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256("supportsInterface(bytes4)"));

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

     
     
     
 function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
         
         

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

     
    function setMetadataAddress(address _contractAddress) public onlyCEO {
        erc721Metadata = ERC721Metadata(_contractAddress);
     }

     
     
     

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return artworkIndexToOwner[_tokenId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return artworkIndexToApproved[_tokenId] == _claimant;
    }

     
     
     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        artworkIndexToApproved[_tokenId] = _approved;
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

     
     
     
     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external payable
        whenNotPaused
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
         
         
        require(_to != address(saleAuction));
        require(_to != address(couplingAuction));

         
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
        external payable
        whenNotPaused
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

     
     
    function totalSupply() public view returns (uint) {
        return artworks.length - 1;
    }

     
     
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = artworkIndexToOwner[_tokenId];

        require(owner != address(0));
    }

     
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalArtpieces = totalSupply();
            uint256 resultIndex = 0;

             
             
            uint256 artworkId;

            for (artworkId = 1; artworkId <= totalArtpieces; artworkId++) {
                if (artworkIndexToOwner[artworkId] == _owner) {
                    result[resultIndex] = artworkId;
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

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() payable onlyOwner whenPaused returns (bool) {
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
         
        bool res = nftAddress.send(this.balance);
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

 
 
contract CouplingClockAuction is ClockAuction {

     
     
    bool public isCouplingClockAuction = true;

     
    function CouplingClockAuction(address _nftAddr, uint256 _cut) public
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

     
    uint256 public saleCount;
    uint256[5] public lastSalePrices;

     
    function SaleClockAuction(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) 
        {}

     
     
     
     
     
     
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

       
            lastSalePrices[saleCount % 5] = price;
            saleCount++;
        }
    }

contract ArtworkLicensing is ArtworkOwnership {

   


     
     
     
    uint256 public autoCreationFee = 2 finney;


     
     
     
    function setAutoCreationFee(uint256 val) external onlyCOO {
        autoCreationFee = val;
    }
}

contract ArtworkAuction is ArtworkLicensing {

     
     
     
     

     
     
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

         
        require(candidateContract.isSaleClockAuction());

         
        saleAuction = candidateContract;
    }

         
     
    function setCouplingAuctionAddress(address _address) external onlyCEO {
        CouplingClockAuction candidateContract = CouplingClockAuction(_address);

         
        require(candidateContract.isCouplingClockAuction());

         
        couplingAuction = candidateContract;
    }
         
     
        function createCouplingAuction(
        uint256 _artworkId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _artworkId));
        _approve(_artworkId, couplingAuction);
         
         
        couplingAuction.createAuction(
            _artworkId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }
     
         

     
     
    function createSaleAuction(
        uint256 _artworkId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _artworkId));
         
         
         
        _approve(_artworkId, saleAuction);
         
         
        saleAuction.createAuction(
            _artworkId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }



         
     
     
     
    function bidOnCouplingAuction(
        uint256 _partnerId,
        uint256 _topId
    )
        external
        payable
        whenNotPaused
    {
         
        require(_owns(msg.sender, _topId));

         
        uint256 currentPrice = couplingAuction.getCurrentPrice(_partnerId);
        require(msg.value >= currentPrice);

         
        couplingAuction.bid.value(msg.value)(_partnerId);
        _assignLeftpiece(_topId,_partnerId);
    }
   

     
     
     
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
        couplingAuction.withdrawBalance();
    }
}

 
contract ArtworkMinting is ArtworkAuction {

     
    uint256 public constant PROMO_CREATION_LIMIT = 5000;

     
    uint256 public promoCreatedCount;

     
     
    function createPromoArtwork(bytes _artworkContent) external payable onlyCOO {
        address artOwner = msg.sender;
        if (artOwner == address(0)) {
             artOwner = cooAddress;
        }
        require(promoCreatedCount < PROMO_CREATION_LIMIT);
        promoCreatedCount++;
        _createArtwork(_artworkContent, artOwner,artOwner);
    }

     
     function createArtwork(bytes _artworkContent) external payable whenNotPaused {
        address artOwner = msg.sender;
        if (artOwner == address(0)) {
             artOwner = cooAddress;
        }
        require(msg.value >= autoCreationFee);
        _createArtwork(_artworkContent, artOwner,artOwner);
    }
     function _ownsOrIsOpUnassigned(address _claimant, uint256 _tokenId) internal view returns (bool) {
         
        return (_owns(msg.sender, _tokenId) || (msg.sender == cooAddress && artworkIndexToLeftpiece[_tokenId] == 0));

    }
       
      
     
     
     

     function assignControlPiece(uint256 _tokenId, uint256 _controlId) external payable whenNotPaused  {
        require(_owns(msg.sender, _tokenId));
       _assignControlPiece(_tokenId,_controlId);
    }
       function assignLeftpiece(uint256 _topId, uint256 _leftId) external payable whenNotPaused  {
        require(_owns(msg.sender, _topId));
        require(_isCouplingPermitted(_topId, _leftId));
       _assignLeftpiece(_topId,_leftId);
    }

          function assignRightpiece(uint256 _topId, uint256 _rightId) external payable whenNotPaused  {
        require(_owns(msg.sender, _topId));
        require(_isCouplingPermitted(_topId, _rightId));
       _assignRightpiece(_topId,_rightId);
    }
     
      
     
     
     
     
     

    function grantRightpiece(uint256 _masterId,uint256 _controlTargetId, uint256 _receiverId, uint256 _tokenToGrant, address _controlOwner) external payable whenNotPaused {
        require(artworkIndexToControlPiece[_masterId] != 0);
        require(_owns(msg.sender, _masterId));  
        require(_ownsOrControls(msg.sender, _tokenToGrant, _masterId));
         require(_owns(_controlOwner, _receiverId));
        require(_owns(_controlOwner, _controlTargetId));
        require(_shareControl(_masterId,_controlTargetId));
        require(_shareControl(_masterId,_receiverId));

        _assignRightpiece(_receiverId,_tokenToGrant);
        Grant(_receiverId, _tokenToGrant);
    }


       function grantLeftpiece(uint256 _masterId,uint256 _controlTargetId, uint256 _receiverId, uint256 _tokenToGrant, address _controlOwner) external payable whenNotPaused {
        require(artworkIndexToControlPiece[_masterId] != 0);
        require(_owns(msg.sender, _masterId));
        require(_ownsOrControls(msg.sender, _tokenToGrant, _masterId));
         require(_owns(_controlOwner, _receiverId));
        require(_owns(_controlOwner, _controlTargetId));
        require(_shareControl(_masterId,_controlTargetId));
        require(_shareControl(_masterId,_receiverId));
         _assignLeftpiece(_receiverId,_tokenToGrant);
         Grant(_receiverId, _tokenToGrant);

    }
        
      
     
     
    function grantControlpiece(uint256 _masterId,uint256 _tokenToGrantControlOf, uint256 _tokenToGrantControlTo)  external payable whenNotPaused {
          require(artworkIndexToControlPiece[_masterId] != 0);
        require(_owns(msg.sender, _masterId));  
        require(_ownsOrControls(msg.sender, _tokenToGrantControlOf, _masterId));
        require(_shareControl(_masterId,_tokenToGrantControlOf));
        artworkIndexToControlPiece[_tokenToGrantControlTo];
        GrantControl(_tokenToGrantControlOf, _tokenToGrantControlTo);
    }
       
      
     
     
     
     
     function pointRightToControlledArtwork(uint256 _masterId, uint256 _tokenToPoint, uint256 _topToken, address _controlOwner) external payable whenNotPaused {
        require(artworkIndexToControlPiece[_masterId] != 0);
        require(_owns(msg.sender, _masterId));  
        require(_ownsOrControls(msg.sender, _topToken, _masterId));
        require(_ownsOrControls(msg.sender, _topToken, _masterId));
        require(_shareControl(_masterId,_tokenToPoint));
        _assignRightpiece(_topToken,_tokenToPoint);
        Grant(_topToken, _tokenToPoint);
    }


     function pointLeftToControlledArtwork(uint256 _masterId, uint256 _tokenToPoint, uint256 _topToken, address _controlOwner) external payable whenNotPaused {
        require(artworkIndexToControlPiece[_masterId] != 0);
        require(_owns(msg.sender, _masterId));  
        require(_ownsOrControls(msg.sender, _topToken, _masterId));
         require(_owns(_controlOwner, _tokenToPoint));
        require(_shareControl(_masterId,_tokenToPoint));

        _assignLeftpiece(_topToken,_tokenToPoint);
        Grant(_topToken, _tokenToPoint);
    }


     
      
     
          function removeRightpiece(uint256 _topId) external payable whenNotPaused {
        require(_owns(msg.sender, _topId));
        artworkIndexToRightpiece[_topId] = 0;
    }

          function removeLeftpiece(uint256 _topId) external payable whenNotPaused {
        require(_owns(msg.sender, _topId));
        artworkIndexToLeftpiece[_topId] = 0;
    }

    function shareControl(uint256 _tokenA, uint256 _tokenB) external view returns (bool){
        return _shareControl(_tokenA,_tokenB);
    }


}
 
 

contract ArtworkCore is ArtworkMinting {

     
    address public newContractAddress;

     
    function ArtworkCore() public {
         
        paused = true;

         
        ceoAddress = msg.sender;

         
        cooAddress = msg.sender;

         
         
    }

     
     
     
     
     
     
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
         
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

     
     
     
    function() external payable {
          require(
            msg.sender == address(saleAuction) ||
            msg.sender == address(couplingAuction)
        );
    }

     
     
    function getArtwork(uint256 _id)
        external
        view
        returns (
        uint256 birthTime,
        address creatorId,
        bytes artworkContent
    ) {
        Artwork storage art = artworks[_id];
        birthTime = uint256(art.birthTime);
        creatorId = art.creatorId;
        artworkContent = art.artworkContent;
    }

     
     
     
     
     
    function unpause() public payable onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(couplingAuction != address(0));
        require(newContractAddress == address(0));

         
        super.unpause();
    }
    
   

     
    function withdrawBalance() external onlyCFO {
        uint256 balance = this.balance;
         
        cfoAddress.transfer(balance);
    }
}


 
contract Contest {
     
     
     
    struct Voter {
        uint weight;  
        bool voted;   
        address delegate;  
        uint vote;    
    }

     
    struct ContestEntry {
        uint voteCount;  
    }

    address public chairperson;

     
     
    mapping(address => Voter) public voters;

     
    ContestEntry[] public contestEntrys;

     
    constructor(uint256[] contestEntryTokens) public {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

         
         
         
    }

    function addEntry(uint256 tokenId) public {
        contestEntrys.push(  ContestEntry(   {voteCount:0}  ) );
    }

     
     
    function giveRightToVote(address voter) public {
         
         
         
         
         
         
         
         
         
         
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

     
    function delegate(address to) public {
         
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");

        require(to != msg.sender, "Self-delegation is disallowed.");

         
         
         
         
         
         
         
         
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

             
            require(to != msg.sender, "Found loop in delegation.");
        }

         
         
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
             
             
            contestEntrys[delegate_.vote].voteCount += sender.weight;
        } else {
             
             
            delegate_.weight += sender.weight;
        }
    }

     
     
    function vote(uint contestEntry) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = contestEntry;

         
         
         
        contestEntrys[contestEntry].voteCount += sender.weight;
    }

     
     
    function winningContestEntry() public view
            returns (uint winningContestEntry_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < contestEntrys.length; p++) {
            if (contestEntrys[p].voteCount > winningVoteCount) {
                winningVoteCount = contestEntrys[p].voteCount;
                winningContestEntry_ = p;
            }
        }
    }

    
}