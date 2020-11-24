 

pragma solidity 0.4.25;

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 
contract StrikersBaseInterface {

  struct Card {
    uint32 mintTime;
    uint8 checklistId;
    uint16 serialNumber;
  }

  Card[] public cards;
}

 
 
contract StrikersMetadataIPFS is Ownable {

   
   
  string public ipfsGateway;

   
  StrikersBaseInterface public strikersBaseContract;

   
  mapping(uint256 => string) internal starredCardURIs;

   
  mapping(uint8 => string) internal checklistIdURIs;

  constructor(string _ipfsGateway, address _strikersBaseAddress) public {
    ipfsGateway = _ipfsGateway;
    strikersBaseContract = StrikersBaseInterface(_strikersBaseAddress);
    setupURIs();
  }

   
  function setupURIs() internal {
     
    starredCardURIs[1778] = "QmYr929yRFHUWqadAW6djKXaXjv9hzjxJyhgfNiTyQWw3a";
    starredCardURIs[8151] = "QmYr929yRFHUWqadAW6djKXaXjv9hzjxJyhgfNiTyQWw3a";

     
    starredCardURIs[882] = "QmPvDZykYBw9iMBfHcSdLMruWirKUfcwsXfZ5mZwEFnG7X";
    starredCardURIs[2552] = "QmPvDZykYBw9iMBfHcSdLMruWirKUfcwsXfZ5mZwEFnG7X";
    starredCardURIs[3043] = "QmPvDZykYBw9iMBfHcSdLMruWirKUfcwsXfZ5mZwEFnG7X";
    starredCardURIs[4019] = "QmPvDZykYBw9iMBfHcSdLMruWirKUfcwsXfZ5mZwEFnG7X";
    starredCardURIs[4460] = "QmPvDZykYBw9iMBfHcSdLMruWirKUfcwsXfZ5mZwEFnG7X";
    starredCardURIs[5303] = "QmPvDZykYBw9iMBfHcSdLMruWirKUfcwsXfZ5mZwEFnG7X";
    starredCardURIs[7109] = "QmPvDZykYBw9iMBfHcSdLMruWirKUfcwsXfZ5mZwEFnG7X";
    starredCardURIs[8494] = "QmPvDZykYBw9iMBfHcSdLMruWirKUfcwsXfZ5mZwEFnG7X";

     
    starredCardURIs[3448] = "QmXZmq6xs5MaoSZ6UPJ5MLKDeLK5rTWuwhjYvaeZJdMS77";
    starredCardURIs[4455] = "QmXZmq6xs5MaoSZ6UPJ5MLKDeLK5rTWuwhjYvaeZJdMS77";
    starredCardURIs[7366] = "QmXZmq6xs5MaoSZ6UPJ5MLKDeLK5rTWuwhjYvaeZJdMS77";
    starredCardURIs[7619] = "QmXZmq6xs5MaoSZ6UPJ5MLKDeLK5rTWuwhjYvaeZJdMS77";

     
    starredCardURIs[5233] = "QmVDfxWGjLSomrcQz7JB2iZmsfNFpyVPQzJvkCbJc19iWu";
    starredCardURIs[8089] = "QmVDfxWGjLSomrcQz7JB2iZmsfNFpyVPQzJvkCbJc19iWu";

     
    starredCardURIs[3224] = "QmXCJ53VF2nZdj1xpYaBo8BJyjdoo1ggVmCjt1cAWhd4ou";

     
    starredCardURIs[7357] = "QmP5wADxxZJVrzkKj5e8S7HAtAGg6L1DHMAUp7tGCgiGxE";
    starredCardURIs[7407] = "QmP5wADxxZJVrzkKj5e8S7HAtAGg6L1DHMAUp7tGCgiGxE";
    starredCardURIs[7697] = "QmP5wADxxZJVrzkKj5e8S7HAtAGg6L1DHMAUp7tGCgiGxE";

     
    starredCardURIs[736] = "Qmc7w3D5C9xEp3LPTwGxwC3xUnAsQH22KDSdhLi5Bj7nYr";
    starredCardURIs[5487] = "Qmc7w3D5C9xEp3LPTwGxwC3xUnAsQH22KDSdhLi5Bj7nYr";
    starredCardURIs[7421] = "Qmc7w3D5C9xEp3LPTwGxwC3xUnAsQH22KDSdhLi5Bj7nYr";

     
    starredCardURIs[2867] = "QmecZq2xjqRPQfUQbGs2N4dp7NX1ftutVcp6vRK9FUMV4C";
    starredCardURIs[6252] = "QmecZq2xjqRPQfUQbGs2N4dp7NX1ftutVcp6vRK9FUMV4C";

     
    starredCardURIs[6250] = "QmTyyYRJQhqVHAVCgvpMJgp5d67QDuLnkDZ24EnZBD2heF";

     
    starredCardURIs[7794] = "QmZFHQhcWenea4GwHsK2chF5x1rxyFDvnz3QhyPqLSRKc4";
  }

  function updateIpfsGateway(string _ipfsGateway) external onlyOwner {
    ipfsGateway = _ipfsGateway;
  }

  function updateStarredCardURI(uint256 _tokenId, string _uri) external onlyOwner {
    starredCardURIs[_tokenId] = _uri;
  }

  function updateChecklistIdURI(uint8 _checklistId, string _uri) external onlyOwner {
    checklistIdURIs[_checklistId] = _uri;
  }

   
   
   
   
  function tokenURI(uint256 _tokenId) external view returns (string) {
    string memory starredCardURI = starredCardURIs[_tokenId];
    if (bytes(starredCardURI).length > 0) {
      return strConcat(ipfsGateway, starredCardURI);
    }

    uint8 checklistId;
    (,checklistId,) = strikersBaseContract.cards(_tokenId);
    return strConcat(ipfsGateway, checklistIdURIs[checklistId]);
  }

   
   

  function strConcat(string _a, string _b) internal pure returns (string) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    string memory ab = new string(_ba.length + _bb.length);
    bytes memory bab = bytes(ab);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
    return string(bab);
  }
}