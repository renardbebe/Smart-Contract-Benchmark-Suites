 

pragma solidity ^0.4.19;

 
 
 
interface ERC721   {
     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256);

     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address);

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;

     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external;

     
     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external;

     
     
     
     
    function getApproved(uint256 _tokenId) external view returns (address);

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 
 
 
interface ERC721Enumerable   {
   
   
   
  function totalSupply() external view returns (uint256);

   
   
   
   
   
  function tokenByIndex(uint256 _index) external view returns (uint256);

   
   
   
   
   
   
   
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

 
 
 
interface ERC721Metadata   {
     
    function name() external pure returns (string _name);

     
    function symbol() external pure returns (string _symbol);

     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string);
}

 
interface ERC721TokenReceiver {
     
     
     
     
     
     
     
     
     
     
     
    function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

contract Ownable {
    address private owner;

    event LogOwnerChange(address _owner);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() public {
        owner = msg.sender;
    }

     
    function replaceOwner(address _owner) external onlyOwner {
        owner = _owner;

        LogOwnerChange(_owner);
    }
}

contract Controllable is Ownable {
     
     
     
    mapping(address => uint256) private contractIndices;

     
     
    address[] private contracts;

     
    modifier onlyActiveContracts() {
        require(contractIndices[msg.sender] != 0);
        _;
    }

    function Controllable() public Ownable() {
         
         
         
        contracts.push(address(0));
    }

     
    function activateContract(address _address) external onlyOwner {
        require(contractIndices[_address] == 0);

        contracts.push(_address);

         
         
         
        contractIndices[_address] = contracts.length - 1;
    }

     
    function deactivateContract(address _address) external onlyOwner {
        require(contractIndices[_address] != 0);

         
         
        address lastActiveContract = contracts[contracts.length - 1];

         
         
         
        contracts[contractIndices[_address]] = lastActiveContract;

         
         
        contracts.length--;

         
         
        contractIndices[_address] = 0;
    }

     
    function getActiveContracts() external view returns (address[]) {
        return contracts;
    }
}

library Tools {
     
    function concatenate(
        string stringLeft,
        string stringRight
    )
        internal
        pure
        returns (string)
    {
         
         
        bytes memory stringLeftBytes = bytes(stringLeft);
        bytes memory stringRightBytes = bytes(stringRight);

         
         
        string memory resultString = new string(
            stringLeftBytes.length + stringRightBytes.length
        );

         
         
        bytes memory resultBytes = bytes(resultString);

         
         
        uint k = 0;

         
         
         
        for (uint i = 0; i < stringLeftBytes.length; i++) {
            resultBytes[k++] = stringLeftBytes[i];
        }

        for (i = 0; i < stringRightBytes.length; i++) {
            resultBytes[k++] = stringRightBytes[i];
        }

        return string(resultBytes);
    }

     
    function uint256ToBytes32(uint256 value) internal pure returns (bytes32) {
        if (value == 0) {
            return '0';
        }

        bytes32 resultBytes;

        while (value > 0) {
            resultBytes = bytes32(uint(resultBytes) / (2 ** 8));
            resultBytes |= bytes32(((value % 10) + 48) * 2 ** (8 * 31));
            value /= 10;
        }

        return resultBytes;
    }

     
    function bytes32ToString(bytes32 data) internal pure returns (string) {
        bytes memory bytesString = new bytes(32);

        for (uint i = 0; i < 32; i++) {
            bytes1 char = bytes1(bytes32(uint256(data) * 2 ** (8 * i)));

            if (char != 0) {
                bytesString[i] = char;
            }
        }

        return string(bytesString);
    }
}

 
interface PartialOwnership {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
}

 
contract EthergotchiOwnershipV2 is
    Controllable,
    ERC721,
    ERC721Enumerable,
    ERC721Metadata
{
     
    mapping(uint256 => address) private ownerByTokenId;

     
     
     
    mapping(address => uint256[]) private tokenIdsByOwner;

     
     
     
    mapping(uint256 => uint256) private ownerTokenIndexByTokenId;

     
     
     
    mapping(uint256 => address) private approvedTransfers;

     
     
     
     
    mapping(address => mapping(address => bool)) private operators;

     
     
     
    uint256 private totalTokens;

     
     
     
    bytes4 private constant INTERFACE_SIGNATURE_ERC165 = bytes4(
        keccak256("supportsInterface(bytes4)")
    );

     
     
     
     
    bytes4 private constant INTERFACE_SIGNATURE_ERC721 = bytes4(
        keccak256("balanceOf(address)") ^
        keccak256("ownerOf(uint256)") ^
        keccak256("safeTransferFrom(address,address,uint256,bytes)") ^
        keccak256("safeTransferFrom(address,address,uint256)") ^
        keccak256("transferFrom(address,address,uint256)") ^
        keccak256("approve(address,uint256)") ^
        keccak256("setApprovalForAll(address,bool)") ^
        keccak256("getApproved(uint256)") ^
        keccak256("isApprovedForAll(address,address)")
    );

     
     
     
     
    bytes4 private constant INTERFACE_SIGNATURE_ERC721_ENUMERABLE = bytes4(
        keccak256("totalSupply()") ^
        keccak256("tokenByIndex(uint256)") ^
        keccak256("tokenOfOwnerByIndex(address,uint256)")
    );

     
     
     
    bytes4 private constant INTERFACE_SIGNATURE_ERC721_METADATA = bytes4(
        keccak256("name()") ^
        keccak256("symbol()") ^
        keccak256("tokenURI(uint256)")
    );

     
     
     
     
    bytes4 private constant INTERFACE_SIGNATURE_ERC721_TOKEN_RECEIVER = bytes4(
        keccak256("onERC721Received(address,uint256,bytes)")
    );

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 _tokenId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

     
    modifier onlyValidToken(uint256 _tokenId) {
        require(ownerByTokenId[_tokenId] != address(0));
        _;
    }

     
    modifier onlyValidTransfers(address _from, address _to, uint256 _tokenId) {
         
         
        address tokenOwner = ownerByTokenId[_tokenId];

         
         
         
         
         
         
         
         
         
        require(
            msg.sender == tokenOwner ||
            msg.sender == approvedTransfers[_tokenId] ||
            operators[tokenOwner][msg.sender]
        );

         
         
         
         
        require(
            _to != address(0) &&
            _to != address(this) &&
            _to != _from
        );

        _;
    }

     
    function EthergotchiOwnershipV2(
        address _formerContract
    )
        public
        Controllable()
    {
        ownerByTokenId[0] = address(0);
        tokenIdsByOwner[address(0)].push(0);
        ownerTokenIndexByTokenId[0] = 0;

         
         
         
        migrationIndex = 1;
        formerContract = PartialOwnership(_formerContract);
    }

     
    function add(
        uint256 _tokenId,
        address _owner
    )
        external
        onlyActiveContracts
    {
         
         
        require(_tokenId != 0 && _owner != address(0));

        _add(_tokenId, _owner);

         
         
        Transfer(address(0), _owner, _tokenId);
    }

     
    function supportsInterface(
        bytes4 interfaceID
    )
        external
        view
        returns (bool)
    {
        return (
            interfaceID == INTERFACE_SIGNATURE_ERC165 ||
            interfaceID == INTERFACE_SIGNATURE_ERC721 ||
            interfaceID == INTERFACE_SIGNATURE_ERC721_METADATA ||
            interfaceID == INTERFACE_SIGNATURE_ERC721_ENUMERABLE
        );
    }

     
    function name() external pure returns (string) {
        return "Ethergotchi";
    }

     
    function symbol() external pure returns (string) {
        return "ETHERGOTCHI";
    }

     
    function tokenURI(uint256 _tokenId) external view returns (string) {
        bytes32 tokenIdBytes = Tools.uint256ToBytes32(_tokenId);

        return Tools.concatenate(
            "https://aethia.co/ethergotchi/",
            Tools.bytes32ToString(tokenIdBytes)
        );
    }

     
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));

        return tokenIdsByOwner[_owner].length;
    }

     
    function ownerOf(uint256 _tokenId) external view returns (address) {
         
         
        address _owner = ownerByTokenId[_tokenId];

        require(_owner != address(0));

        return _owner;
    }

     
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes data
    )
        external
        onlyValidToken(_tokenId)
    {
         
         
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

     
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        onlyValidToken(_tokenId)
    {
         
         
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        onlyValidToken(_tokenId)
        onlyValidTransfers(_from, _to, _tokenId)
    {
        _transfer(_to, _tokenId);
    }

     
    function approve(address _approved, uint256 _tokenId) external {
        address _owner = ownerByTokenId[_tokenId];

         
         
        require(msg.sender == _owner || operators[_owner][msg.sender]);

         
         
         
        approvedTransfers[_tokenId] = _approved;

        Approval(msg.sender, _approved, _tokenId);
    }

     
    function setApprovalForAll(address _operator, bool _approved) external {
        operators[msg.sender][_operator] = _approved;

        ApprovalForAll(msg.sender, _operator, _approved);
    }

     
    function getApproved(
        uint256 _tokenId
    )
        external
        view
        onlyValidToken(_tokenId)
        returns (address)
    {
        return approvedTransfers[_tokenId];
    }

     
    function isApprovedForAll(
        address _owner,
        address _operator
    )
        external
        view
        returns (bool)
    {
        return operators[_owner][_operator];
    }

     
    function totalSupply() external view returns (uint256) {
        return totalTokens;
    }

     
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < totalTokens);

        return _index;
    }

     
    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        external
        view
        returns (uint256)
    {
        require(_index < tokenIdsByOwner[_owner].length);

        return tokenIdsByOwner[_owner][_index];
    }

     
    function _isContract(address _address) internal view returns (bool) {
        uint size;

        assembly {
            size := extcodesize(_address)
        }

        return size > 0;
    }

     
    function _safeTransferFrom(
        address _from, 
        address _to, 
        uint256 _tokenId,
        bytes data
    )
        internal
        onlyValidTransfers(_from, _to, _tokenId)
    {
         
         
         
        _transfer(_to, _tokenId);

         
         
        if (_isContract(_to)) {

             
             
             
            ERC721TokenReceiver _receiver = ERC721TokenReceiver(_to);

             
             
             
             
            require(
                _receiver.onERC721Received(
                    address(this),
                    _tokenId,
                    data
                ) == INTERFACE_SIGNATURE_ERC721_TOKEN_RECEIVER
            );
        }
    }

     
    function _transfer(address _to, uint256 _tokenId) internal {
         
         
         
         
        address _from = ownerByTokenId[_tokenId];

         
         
         
         
        if (tokenIdsByOwner[_from].length > 1) {

             
             
            uint256 tokenIndexToDelete = ownerTokenIndexByTokenId[_tokenId];

             
             
             
             
            uint256 tokenIndexToMove = tokenIdsByOwner[_from].length - 1;

             
             
             
            tokenIdsByOwner[_from][tokenIndexToDelete] =
                tokenIdsByOwner[_from][tokenIndexToMove];
        }

         
         
         
         
         
        tokenIdsByOwner[_from].length--;

         
         
         
         
         
        tokenIdsByOwner[_to].push(_tokenId);
        ownerTokenIndexByTokenId[_tokenId] = tokenIdsByOwner[_to].length - 1;

         
         
         
        ownerByTokenId[_tokenId] = _to;

         
         
        approvedTransfers[_tokenId] = address(0);

         
         
        Transfer(_from, _to, _tokenId);
    }

     
    function _add(uint256 _tokenId, address _owner) internal {
         
         
        require(ownerByTokenId[_tokenId] == address(0));

         
         
         
         
         
        ownerByTokenId[_tokenId] = _owner;
        tokenIdsByOwner[_owner].push(_tokenId);

         
         
         
         
         
        ownerTokenIndexByTokenId[_tokenId] = tokenIdsByOwner[_owner].length - 1;

        totalTokens += 1;
    }

     
     
     

     
     
     
    uint256 public migrationIndex;

     
    PartialOwnership private formerContract;

     
    function migrate(uint256 _count) external onlyOwner {
         
         
         
        require(1521849600 <= now && now <= 1522022399);

         
         
        uint256 formerTokenCount = formerContract.totalSupply();

         
        uint256 endIndex = migrationIndex + _count;

         
         
         
        if (endIndex >= formerTokenCount) {
            endIndex = formerTokenCount;
        }

         
         
         
         
        for (uint256 i = migrationIndex; i < endIndex; i++) {
            address tokenOwner;

             
             
             
             
             
             
             
            if (_isExcluded(i)) {
                tokenOwner = address(0);
            } else {
                tokenOwner = formerContract.ownerOf(i);
            }

             
             
            _add(i, tokenOwner);

             
             
             
             
            Transfer(address(formerContract), tokenOwner, i);
        }

         
         
        migrationIndex = endIndex;
    }

     
    function _isExcluded(uint256 _gotchiId) internal pure returns (bool) {
        return
            1247 <= _gotchiId && _gotchiId <= 1688 &&
            _gotchiId != 1296 &&
            _gotchiId != 1297 &&
            _gotchiId != 1479 &&
            _gotchiId != 1492 &&
            _gotchiId != 1550 &&
            _gotchiId != 1551 &&
            _gotchiId != 1555;
    }
}