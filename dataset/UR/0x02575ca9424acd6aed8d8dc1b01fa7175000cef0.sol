 

pragma solidity ^0.4.18;

 
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
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract ERC721Interface {
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address owner);
     
     
     
}

 
contract NameProvider is Ownable {
    
    uint256 public FEE = 1 finney;
    
     
    mapping(bytes32 => mapping(address => string)) addressNames;
    
     
    mapping(bytes32 => bool) takenNamespaces;
    
     
    mapping(address => mapping(uint256 => string)) tokenNames;
    
     
    mapping(address => mapping(uint256 => string)) tokenDescriptions;
    
     
    
    event NameChanged(bytes32 namespace, address account, string name);
    
    event TokenNameChanged(address tokenProvider, uint256 tokenId, string name);
    
    event TokenDescriptionChanged(address tokenProvider, uint256 tokenId, string description);
    
    function NameProvider(address _owner) public {
        require(_owner != address(0));
        owner = _owner;
    }
    
    modifier setTokenText(address _tokenInterface, uint256 _tokenId, string _text){
         
        require(msg.value >= FEE);
         
        require(bytes(_text).length > 0);
        
        ERC721Interface tokenInterface = ERC721Interface(_tokenInterface);
         
        require(msg.sender == tokenInterface.ownerOf(_tokenId));
        
        _; 
        
         
        if (msg.value > FEE) {
            msg.sender.transfer(msg.value - FEE);
        }
    }
    
     
     
     
     
     
    function setTokenName(address _tokenInterface, uint256 _tokenId, string _name) 
    setTokenText(_tokenInterface, _tokenId, _name) external payable {
        _setTokenName(_tokenInterface, _tokenId, _name);
    }
    
     
     
     
     
     
    function setTokenDescription(address _tokenInterface, uint256 _tokenId, string _description)
    setTokenText(_tokenInterface, _tokenId, _description) external payable {
        _setTokenDescription(_tokenInterface, _tokenId, _description);
    }
    
     
     
     
    function getTokenName(address _tokenInterface, uint256 _tokenId) external view returns(string) {
        return tokenNames[_tokenInterface][_tokenId];
    }
    
     
     
     
    function getTokenDescription(address _tokenInterface, uint256 _tokenId) external view returns(string) {
        return tokenDescriptions[_tokenInterface][_tokenId];
    }
    
     
     
     
    function setName(string _name) external payable {
        setServiceName(bytes32(0), _name);
    }
    
     
     
     
     
    function setServiceName(bytes32 _namespace, string memory _name) public payable {
         
        require(msg.value >= FEE);
         
        _setName(_namespace, _name);
         
        if (msg.value > FEE) {
            msg.sender.transfer(msg.value - FEE);
        }
    }
    
     
     
    function getNameByAddress(address _address) external view returns(string) {
        return addressNames[bytes32(0)][_address];
    }
    
     
    function getName() external view returns(string) {
        return addressNames[bytes32(0)][msg.sender];
    }
    
     
     
     
    function getServiceNameByAddress(bytes32 _namespace, address _address) external view returns(string) {
        return addressNames[_namespace][_address];
    }
    
     
     
    function getServiceName(bytes32 _namespace) external view returns(string) {
        return addressNames[_namespace][msg.sender];
    }
    
     
     
     
     
    function getNames(address[] _address) external view returns(bytes32[] namesData, uint256[] nameLength) {
        return getServiceNames(bytes32(0), _address);
	}
	
	 
     
     
     
	function getTokenNames(address _tokenInterface, uint256[] _tokenIds) external view returns(bytes32[] memory namesData, uint256[] memory nameLength) {
        return _getTokenTexts(_tokenInterface, _tokenIds, true);
	}
	
	 
     
     
     
	function getTokenDescriptions(address _tokenInterface, uint256[] _tokenIds) external view returns(bytes32[] memory descriptonData, uint256[] memory descriptionLength) {
        return _getTokenTexts(_tokenInterface, _tokenIds, false);
	}
	
	 
	 
     
     
     
    function getServiceNames(bytes32 _namespace, address[] _address) public view returns(bytes32[] memory namesData, uint256[] memory nameLength) {
        uint256 length = _address.length;
        nameLength = new uint256[](length);
        
        bytes memory stringBytes;
        uint256 size = 0;
        uint256 i;
        for (i = 0; i < length; i ++) {
            stringBytes = bytes(addressNames[_namespace][_address[i]]);
            size += nameLength[i] = stringBytes.length % 32 == 0 ? stringBytes.length / 32 : stringBytes.length / 32 + 1;
        }
        namesData = new bytes32[](size);
        size = 0;
        for (i = 0; i < length; i ++) {
            size += _stringToBytes32(addressNames[_namespace][_address[i]], namesData, size);
        }
    }
    
    function namespaceTaken(bytes32 _namespace) external view returns(bool) {
        return takenNamespaces[_namespace];
    }
    
    function setFee(uint256 _fee) onlyOwner external {
        FEE = _fee;
    }
    
    function withdraw() onlyOwner external {
        owner.transfer(this.balance);
    }
    
    function _setName(bytes32 _namespace, string _name) internal {
        addressNames[_namespace][msg.sender] = _name;
        if (!takenNamespaces[_namespace]) {
            takenNamespaces[_namespace] = true;
        }
        NameChanged(_namespace, msg.sender, _name);
    }
    
    function _setTokenName(address _tokenInterface, uint256 _tokenId, string _name) internal {
        tokenNames[_tokenInterface][_tokenId] = _name;
        TokenNameChanged(_tokenInterface, _tokenId, _name);
    }
    
    function _setTokenDescription(address _tokenInterface, uint256 _tokenId, string _description) internal {
        tokenDescriptions[_tokenInterface][_tokenId] = _description;
        TokenDescriptionChanged(_tokenInterface, _tokenId, _description);
    }
    
    function _getTokenTexts(address _tokenInterface, uint256[] memory _tokenIds, bool names) internal view returns(bytes32[] memory namesData, uint256[] memory nameLength) {
        uint256 length = _tokenIds.length;
        nameLength = new uint256[](length);
        mapping(address => mapping(uint256 => string)) textMap = names ? tokenNames : tokenDescriptions;
        
        bytes memory stringBytes;
        uint256 size = 0;
        uint256 i;
        for (i = 0; i < length; i ++) {
            stringBytes = bytes(textMap[_tokenInterface][_tokenIds[i]]);
            size += nameLength[i] = stringBytes.length % 32 == 0 ? stringBytes.length / 32 : stringBytes.length / 32 + 1;
        }
        namesData = new bytes32[](size);
        size = 0;
        for (i = 0; i < length; i ++) {
            size += _stringToBytes32(textMap[_tokenInterface][_tokenIds[i]], namesData, size);
        }
    }
    
        
    function _stringToBytes32(string memory source, bytes32[] memory namesData, uint256 _start) internal pure returns (uint256) {
        bytes memory stringBytes = bytes(source);
        uint256 length = stringBytes.length;
        bytes32[] memory result = new bytes32[](length % 32 == 0 ? length / 32 : length / 32 + 1);
        
        bytes32 word;
        uint256 index = 0;
        uint256 limit = 0;
        for (uint256 i = 0; i < length; i += 32) {
            limit = i + 32;
            assembly {
                word := mload(add(source, limit))
            }
            namesData[_start + index++] = word;
        }
        return result.length;
    }
}