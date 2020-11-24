 

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
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


 


 












 
 
 
contract ArtAccessControl {
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
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




 
 
 
contract ArtBase is ArtAccessControl {
     

     
     
     
    event Create(address owner, uint256 artId, uint16 generator);

     
     
    event Transfer(address from, address to, uint256 tokenId);

    event Vote(uint16 candidate, uint256 voteCount, uint16 currentGenerator, uint256 currentGeneratorVoteCount);
    event NewRecipient(address recipient, uint256 position);
    event NewGenerator(uint256 position);

     

     
     
     
     
     
    struct ArtToken {
         
        uint64 birthTime;
         
        uint16 generator;
    }

     

     
     
     
     
     
    ArtToken[] artpieces;

     
     
    mapping (uint256 => address) public artIndexToOwner;

     
     
    mapping (address => uint256) ownershipTokenCount;

     
     
     
    mapping (uint256 => address) public artIndexToApproved;


     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
        ownershipTokenCount[_to]++;
         
        artIndexToOwner[_tokenId] = _to;
         
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
             
            delete artIndexToApproved[_tokenId];
        }
         
        Transfer(_from, _to, _tokenId);
    }

     
     
     
     
     
     
    function _createArt(
        uint256 _generator,
        address _owner
    )
        internal
        returns (uint)
    {
         
         
         
         
        require(_generator == uint256(uint16(_generator)));

        ArtToken memory _art = ArtToken({
            birthTime: uint64(now),
            generator: uint16(_generator)
        });
        uint256 newArtId = artpieces.push(_art) - 1;

         
         
        require(newArtId == uint256(uint32(newArtId)));

         
        Create(
            _owner,
            newArtId,
            _art.generator
        );

         
         
        _transfer(0, _owner, newArtId);

        return newArtId;
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


 
 
 
 
contract ArtOwnership is ArtBase, ERC721 {

     
    string public constant name = "Future of Trust 2018 Art Token";
    string public constant symbol = "FoT2018";

     
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
        return artIndexToOwner[_tokenId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return artIndexToApproved[_tokenId] == _claimant;
    }

     
     
     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        artIndexToApproved[_tokenId] = _approved;
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
        return artpieces.length - 1;
    }

     
     
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = artIndexToOwner[_tokenId];

        require(owner != address(0));
    }

     
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalCats = totalSupply();
            uint256 resultIndex = 0;

             
             
            uint256 catId;

            for (catId = 1; catId <= totalCats; catId++) {
                if (artIndexToOwner[catId] == _owner) {
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

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}






 
contract ArtMinting is ArtOwnership {

     
    uint256 public constant PROMO_CREATION_LIMIT = 300;

     
    uint256 public promoCreatedCount;

     
    function createPromoArt() external onlyCOO {
         
         
         
         
         
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;
        _createArt(curGenerator, cooAddress);
    }
    
    uint256[] public votes;
    uint16 public curGenerator = 0;
    uint16 public maxGenerators = 3;
    
    function castVote(uint _generator) external {
        require(_generator < votes.length);
        votes[_generator] = votes[_generator] + 1;
        if (votes[_generator] > votes[curGenerator]) {
            curGenerator = uint16(_generator);
        }
        Vote(uint16(_generator), votes[_generator], curGenerator, votes[curGenerator]);
    }
    
    function addGenerator() external {
        require(votes.length < maxGenerators);
        uint _id = votes.push(0);
        NewGenerator(_id);
    }
}


 
 
 
contract ArtCore is ArtMinting {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

    
     
    function ArtCore() public {
         
        paused = true;

         
        ceoAddress = msg.sender;

         
        cooAddress = msg.sender;

         
        _createArt(0, address(0));
    }



     
     
     
    function() external payable {
        require(
            msg.sender == address(0)
        );
    }

     
     
    function getArtToken(uint256 _id)
        external
        view
        returns (
        uint256 birthTime,
        uint256 generator
    ) {
        ArtToken storage art = artpieces[_id];

         
        birthTime = uint256(art.birthTime);
        generator = uint256(art.generator);
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
         
        super.unpause();
    }

     
    function withdrawBalance() external onlyCFO {
        uint256 balance = this.balance;
        cfoAddress.send(balance);
    }
}