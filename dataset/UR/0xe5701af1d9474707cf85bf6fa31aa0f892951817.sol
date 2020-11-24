 

 
pragma solidity ^0.4.11;

 
 
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


 
 
contract PixelAuthority {

     
    event ContractUpgrade(address newContract);

    address public authorityAddress;
    uint public authorityBalance = 0;

     
    modifier onlyAuthority() {
        require(msg.sender == authorityAddress);
        _;
    }

     
     
    function setAuthority(address _newAuthority) external onlyAuthority {
        require(_newAuthority != address(0));
        authorityAddress = _newAuthority;
    }

}


 
 
 
contract PixelBase is PixelAuthority {
     

     
     
    event Transfer(address from, address to, uint256 tokenId);

     
    uint32 public WIDTH = 1000;
    uint32 public HEIGHT = 1000;

     
     
     
    mapping (uint256 => address) public pixelIndexToOwner;
     
    mapping (uint256 => address) public pixelIndexToApproved;
     
    mapping (uint256 => uint32) public colors;
     
     
    mapping (address => uint256) ownershipTokenCount;

     
     
     

     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
         
        ownershipTokenCount[_to]++;
        pixelIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete pixelIndexToApproved[_tokenId];
        }
         
        Transfer(_from, _to, _tokenId);
    }

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return pixelIndexToOwner[_tokenId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return pixelIndexToApproved[_tokenId] == _claimant;
    }
}


 
 
 
 
contract PixelOwnership is PixelBase, ERC721 {

     
    string public constant name = "PixelCoins";
    string public constant symbol = "PXL";


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


    string public metaBaseUrl = "https://pixelcoins.io/meta/";


     
     
     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

     
     
     
     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));

         
        require(_owns(msg.sender, _tokenId));
         
        require(pixelIndexToApproved[_tokenId] != address(this));

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
    {
         
        require(_owns(msg.sender, _tokenId));
         
        require(pixelIndexToApproved[_tokenId] != address(this));

         
        pixelIndexToApproved[_tokenId] = _to;

         
        Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

     
     
    function totalSupply() public view returns (uint) {
        return WIDTH * HEIGHT;
    }

     
     
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = pixelIndexToOwner[_tokenId];
        require(owner != address(0));
    }

     
    function ownersOfArea(uint256 x, uint256 y, uint256 x2, uint256 y2) external view returns (address[] result) {
        require(x2 > x && y2 > y);
        require(x2 <= WIDTH && y2 <= HEIGHT);
        result = new address[]((y2 - y) * (x2 - x));

        uint256 r = 0;
        for (uint256 i = y; i < y2; i++) {
            uint256 tokenId = i * WIDTH;
            for (uint256 j = x; j < x2; j++) {
                result[r] = pixelIndexToOwner[tokenId + j];
                r++;
            }
        }
    }

     
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalPixels = totalSupply();
            uint256 resultIndex = 0;

             
             
            uint256 pixelId;

            for (pixelId = 0; pixelId <= totalPixels; pixelId++) {
                if (pixelIndexToOwner[pixelId] == _owner) {
                    result[resultIndex] = pixelId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

     
    function uintToString(uint v) constant returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = string(s);
    }

     
    function appendUintToString(string inStr, uint v) constant returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    function setMetaBaseUrl(string _metaBaseUrl) external onlyAuthority {
        metaBaseUrl = _metaBaseUrl;
    }

     
     
     
    function tokenMetadata(uint256 _tokenId) external view returns (string infoUrl) {
        return appendUintToString(metaBaseUrl, _tokenId);
    }
}

contract PixelPainting is PixelOwnership {

    event Paint(uint256 tokenId, uint32 color);

     
    function setPixelColor(uint256 _tokenId, uint32 _color) external {
         
        require(_tokenId < HEIGHT * WIDTH);
         
        require(_owns(msg.sender, _tokenId));
        colors[_tokenId] = _color;
    }

     
    function setPixelAreaColor(uint256 x, uint256 y, uint256 x2, uint256 y2, uint32[] _colors) external {
        require(x2 > x && y2 > y);
        require(x2 <= WIDTH && y2 <= HEIGHT);
        require(_colors.length == (y2 - y) * (x2 - x));
        uint256 r = 0;
        for (uint256 i = y; i < y2; i++) {
            uint256 tokenId = i * WIDTH;
            for (uint256 j = x; j < x2; j++) {
                if (_owns(msg.sender, tokenId + j)) {
                    uint32 color = _colors[r];
                    colors[tokenId + j] = color;
                    Paint(tokenId + j, color);
                }
                r++;
            }
        }
    }

     
    function getPixelColor(uint256 _tokenId) external view returns (uint32 color) {
        require(_tokenId < HEIGHT * WIDTH);
        color = colors[_tokenId];
    }

     
    function getPixelAreaColor(uint256 x, uint256 y, uint256 x2, uint256 y2) external view returns (uint32[] result) {
        require(x2 > x && y2 > y);
        require(x2 <= WIDTH && y2 <= HEIGHT);
        result = new uint32[]((y2 - y) * (x2 - x));
        uint256 r = 0;
        for (uint256 i = y; i < y2; i++) {
            uint256 tokenId = i * WIDTH;
            for (uint256 j = x; j < x2; j++) {
                result[r] = colors[tokenId + j];
                r++;
            }
        }
    }
}


 
contract PixelMinting is PixelPainting {

    uint public pixelPrice = 3030 szabo;

     
    function setNewPixelPrice(uint _pixelPrice) external onlyAuthority {
        pixelPrice = _pixelPrice;
    }
    
     
    function buyEmptyPixel(uint256 _tokenId) external payable {
        require(msg.value == pixelPrice);
        require(_tokenId < HEIGHT * WIDTH);
        require(pixelIndexToOwner[_tokenId] == address(0));
         
        authorityBalance += msg.value;
         
         
        _transfer(0, msg.sender, _tokenId);
    }

     
    function buyEmptyPixelArea(uint256 x, uint256 y, uint256 x2, uint256 y2) external payable {
        require(x2 > x && y2 > y);
        require(x2 <= WIDTH && y2 <= HEIGHT);
        require(msg.value == pixelPrice * (x2-x) * (y2-y));
        
        uint256 i;
        uint256 tokenId;
        uint256 j;
         
        for (i = y; i < y2; i++) {
            tokenId = i * WIDTH;
            for (j = x; j < x2; j++) {
                require(pixelIndexToOwner[tokenId + j] == address(0));
            }
        }

        authorityBalance += msg.value;

         
        for (i = y; i < y2; i++) {
            tokenId = i * WIDTH;
            for (j = x; j < x2; j++) {
                _transfer(0, msg.sender, tokenId + j);
            }
        }
    }

}

 
contract PixelAuction is PixelMinting {

     
    struct Auction {
          
        address highestBidder;
        uint highestBid;
        uint256 endTime;
        bool live;
    }

     
    mapping (uint256 => Auction) tokenIdToAuction;
     
    mapping (address => uint) pendingReturns;

     
    uint256 public duration = 60 * 60 * 24 * 4;
     
    bool public auctionsEnabled = false;

     
    function setDuration(uint _duration) external onlyAuthority {
        duration = _duration;
    }

     
    function setAuctionsEnabled(bool _auctionsEnabled) external onlyAuthority {
        auctionsEnabled = _auctionsEnabled;
    }

     
     
    function createAuction(
        uint256 _tokenId
    )
        external payable
    {
         
        require(auctionsEnabled);
        require(_owns(msg.sender, _tokenId) || msg.sender == authorityAddress);
         
        require(!tokenIdToAuction[_tokenId].live);

        uint startPrice = pixelPrice;
        if (msg.sender == authorityAddress) {
            startPrice = 0;
        }

        require(msg.value == startPrice);
         
        pixelIndexToApproved[_tokenId] = address(this);

        tokenIdToAuction[_tokenId] = Auction(
            msg.sender,
            startPrice,
            block.timestamp + duration,
            true
        );
        AuctionStarted(_tokenId);
    }

     
    function bid(uint256 _tokenId) external payable {
         
         
         
         
         
        Auction storage auction = tokenIdToAuction[_tokenId];

         
         
        require(auction.live);
        require(auction.endTime > block.timestamp);

         
         
        require(msg.value > auction.highestBid);

        if (auction.highestBidder != 0) {
             
             
             
             
             
            pendingReturns[auction.highestBidder] += auction.highestBid;
        }
        
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        HighestBidIncreased(_tokenId, msg.sender, msg.value);
    }

     
    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
             
             
             
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                 
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

     
     
    function endAuction(uint256 _tokenId) external {
         
         
         
         
         
         
         
         
         
         
         
         

        Auction storage auction = tokenIdToAuction[_tokenId];

         
        require(auction.endTime < block.timestamp);
        require(auction.live);  

         
        auction.live = false;
        AuctionEnded(_tokenId, auction.highestBidder, auction.highestBid);

         
        address owner = pixelIndexToOwner[_tokenId];
         
        uint amount = auction.highestBid * 9 / 10;
        pendingReturns[owner] += amount;
        authorityBalance += (auction.highestBid - amount);
         
        _transfer(owner, auction.highestBidder, _tokenId);

       
    }

     
    event AuctionStarted(uint256 _tokenId);
    event HighestBidIncreased(uint256 _tokenId, address bidder, uint amount);
    event AuctionEnded(uint256 _tokenId, address winner, uint amount);


     
     
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address highestBidder,
        uint highestBid,
        uint endTime,
        bool live
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        return (
            auction.highestBidder,
            auction.highestBid,
            auction.endTime,
            auction.live
        );
    }

     
     
    function getHighestBid(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        return auction.highestBid;
    }
}


 
 
 
contract PixelCore is PixelAuction {

     
    address public newContractAddress;

     
    function PixelCore() public {
         
        authorityAddress = msg.sender;
    }

     
     
     
     
     
     
    function setNewAddress(address _v2Address) external onlyAuthority {
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

     
    function withdrawBalance() external onlyAuthority returns (bool) {
        uint amount = authorityBalance;
        if (amount > 0) {
            authorityBalance = 0;
            if (!authorityAddress.send(amount)) {
                authorityBalance = amount;
                return false;
            }
        }
        return true;
    }
}