 

pragma solidity ^0.4.0;

 
 




 
 
 
 
 
 
 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 
 
 
 
 
 
 
 
 

 

 
 



contract NFT {
  function totalSupply() public constant returns (uint);
  function balanceOf(address) public constant returns (uint);

  function tokenOfOwnerByIndex(address owner, uint index) external constant returns (uint);
  function ownerOf(uint tokenId) external constant returns (address);

  function transfer(address to, uint tokenId) public;
  function takeOwnership(uint tokenId) external;
  function transferFrom(address from, address to, uint tokenId) external;
  function approve(address beneficiary, uint tokenId) external;

  function metadata(uint tokenId) external constant returns (string);
}

contract NFTEvents {
  event Transferred(uint tokenId, address from, address to);
  event Approval(address owner, address beneficiary, uint tokenId);
  event MetadataUpdated(uint tokenId, address owner, string data);
}

contract BasicNFT is NFT, NFTEvents {

  uint public totalTokens;

   
  mapping(address => uint[]) public ownedTokens;
  mapping(address => uint) _virtualLength;
  mapping(uint => uint) _tokenIndexInOwnerArray;

   
  mapping(uint => address) public tokenOwner;

   
  mapping(uint => address) public allowedTransfer;

   
  mapping(uint => string) public _tokenMetadata;

  function totalSupply() public constant returns (uint) {
    return totalTokens;
  }

  function balanceOf(address owner) public constant returns (uint) {
    return _virtualLength[owner];
  }

  function tokenOfOwnerByIndex(address owner, uint index) external constant returns (uint) {
    require(index >= 0 && index < balanceOf(owner));
    return ownedTokens[owner][index];
  }

  function getAllTokens(address owner) public constant returns (uint[]) {
    uint size = _virtualLength[owner];
    uint[] memory result = new uint[](size);
    for (uint i = 0; i < size; i++) {
      result[i] = ownedTokens[owner][i];
    }
    return result;
  }

  function ownerOf(uint tokenId) external constant returns (address) {
    return tokenOwner[tokenId];
  }

  function transfer(address to, uint tokenId) public {
    require(tokenOwner[tokenId] == msg.sender);
    return _transfer(tokenOwner[tokenId], to, tokenId);
  }

  function takeOwnership(uint tokenId) external {
    require(allowedTransfer[tokenId] == msg.sender);
    return _transfer(tokenOwner[tokenId], msg.sender, tokenId);
  }

  function transferFrom(address from, address to, uint tokenId) external {
    require(tokenOwner[tokenId] == from);
    require(allowedTransfer[tokenId] == msg.sender);
    return _transfer(tokenOwner[tokenId], to, tokenId);
  }

  function approve(address beneficiary, uint tokenId) external {
    require(msg.sender == tokenOwner[tokenId]);

    if (allowedTransfer[tokenId] != 0) {
      allowedTransfer[tokenId] = 0;
    }
    allowedTransfer[tokenId] = beneficiary;
    Approval(tokenOwner[tokenId], beneficiary, tokenId);
  }

  function tokenMetadata(uint tokenId) external constant returns (string) {
    return _tokenMetadata[tokenId];
  }

  function metadata(uint tokenId) external constant returns (string) {
    return _tokenMetadata[tokenId];
  }

  function updateTokenMetadata(uint tokenId, string _metadata) external {
    require(msg.sender == tokenOwner[tokenId]);
    _tokenMetadata[tokenId] = _metadata;
    MetadataUpdated(tokenId, msg.sender, _metadata);
  }

  function _transfer(address from, address to, uint tokenId) internal {
    _clearApproval(tokenId);
    if (from != address(0)) {
        _removeTokenFrom(from, tokenId);
    }
    _addTokenTo(to, tokenId);
    Transferred(tokenId, from, to);
  }

  function _clearApproval(uint tokenId) internal {
    allowedTransfer[tokenId] = 0;
    Approval(tokenOwner[tokenId], 0, tokenId);
  }

  function _removeTokenFrom(address from, uint tokenId) internal {
    require(_virtualLength[from] > 0);

    uint length = _virtualLength[from];
    uint index = _tokenIndexInOwnerArray[tokenId];
    uint swapToken = ownedTokens[from][length - 1];

    ownedTokens[from][index] = swapToken;
    _tokenIndexInOwnerArray[swapToken] = index;
    _virtualLength[from]--;
  }

  function _addTokenTo(address owner, uint tokenId) internal {
    if (ownedTokens[owner].length == _virtualLength[owner]) {
      ownedTokens[owner].push(tokenId);
    } else {
      ownedTokens[owner][_virtualLength[owner]] = tokenId;
    }
    tokenOwner[tokenId] = owner;
    _tokenIndexInOwnerArray[tokenId] = _virtualLength[owner];
    _virtualLength[owner]++;
  }
}


pragma solidity ^0.4.0;

 
 
 
 
 

 

 
 
 
 
 
 
 

 
 

 
 
 
 
 
 
 



 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}






 
 


contract CryptoTulip is Destructible, Pausable, BasicNFT {

    function CryptoTulip() public {
         
        _createTulip(bytes32(-1), 0, 0, 0, address(0));
        paused = false;
    }

    string public name = "CryptoTulip";
    string public symbol = "TULIP";

    uint32 internal constant MONTHLY_BLOCKS = 172800;

     
    mapping(address => string) public usernames;


    struct Tulip {
        bytes32 genome;
        uint64 block;
        uint64 foundation;
        uint64 inspiration;
        uint64 generation;
    }

    Tulip[] tulips;

    uint256 public artistFees = 1 finney;

    function setArtistFees(uint256 _newFee) external onlyOwner {
        artistFees = _newFee;
    }

    function getTulip(uint256 _id) external view
      returns (
        bytes32 genome,
        uint64 blockNumber,
        uint64 foundation,
        uint64 inspiration,
        uint64 generation
    ) {
        require(_id > 0);
        Tulip storage tulip = tulips[_id];

        genome = tulip.genome;
        blockNumber = tulip.block;
        foundation = tulip.foundation;
        inspiration = tulip.inspiration;
        generation = tulip.generation;
    }

     
     
     
     
    function commissionArt(uint256 _foundation, uint256 _inspiration)
      external payable whenNotPaused returns (uint)
    {
        require(msg.sender == tokenOwner[_foundation]);
        require(msg.value >= artistFees);
        uint256 _id = _createTulip(bytes32(0), _foundation, _inspiration, tulips[_foundation].generation + 1, msg.sender);
        _creativeProcess(_id);
    }

     
     
    function nameArt(uint256 _id, string _newName) external whenNotPaused {
        require(msg.sender == tokenOwner[_id]);
        _tokenMetadata[_id] = _newName;
        MetadataUpdated(_id, msg.sender, _newName);
    }

    function setUsername(string _username) external whenNotPaused {
        usernames[msg.sender] = _username;
    }


     

    uint256 internal constant ORIGINAL_ARTWORK_LIMIT = 10000;
    uint256 internal originalCount = 0;

     
     
     
    function originalArtwork(bytes32 _genome, address _owner) external payable {
        address newOwner = _owner;
        if (newOwner == address(0)) {
             newOwner = msg.sender;
        }

        if (block.number > tulips[0].block + MONTHLY_BLOCKS ) {
            require(msg.sender == owner);
            require(originalCount < ORIGINAL_ARTWORK_LIMIT);
            originalCount++;
        } else {
            require(
                (msg.value >= artistFees && _virtualLength[msg.sender] < 10) ||
                msg.sender == owner);
        }

        _createTulip(_genome, 0, 0, 0, newOwner);
    }

     
    function withdraw() external onlyOwner {
        owner.transfer(this.balance);
    }


     
     

    function _creativeProcess(uint _id) internal {
        Tulip memory tulip = tulips[_id];

        require(tulip.genome == bytes32(0));
         
         
         
         
        bytes32 hash = keccak256(
            block.blockhash(block.number - 1) ^ block.blockhash(block.number - 2) ^ bytes32(msg.sender));

        Tulip memory foundation = tulips[tulip.foundation];
        Tulip memory inspiration = tulips[tulip.inspiration];

        bytes32 genome = bytes32(0);

        for (uint8 i = 0; i < 32; i++) {
            uint8 r = uint8(hash[i]);
            uint8 gene;

            if (r % 10 < 2) {
               gene = uint8(foundation.genome[i]) - 8 + (r / 16);
            } else if (r % 100 < 99) {
               gene = uint8(r % 10 < 7 ? foundation.genome[i] : inspiration.genome[i]);
            } else {
                gene = uint8(keccak256(r));
            }

            genome = bytes32(gene) | (genome << 8);
        }

        tulips[_id].genome = genome;
    }

    function _createTulip(
        bytes32 _genome,
        uint256 _foundation,
        uint256 _inspiration,
        uint256 _generation,
        address _owner
    ) internal returns (uint)
    {
        Tulip memory newTulip = Tulip({
            genome: _genome,
            block: uint64(block.number),
            foundation: uint64(_foundation),
            inspiration: uint64(_inspiration),
            generation: uint64(_generation)
        });

        uint256 newTulipId = tulips.push(newTulip) - 1;
        _transfer(0, _owner, newTulipId);
        totalTokens++;
        return newTulipId;
    }

}