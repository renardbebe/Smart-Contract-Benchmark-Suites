 

pragma solidity ^0.5.0;

pragma solidity ^0.5.0;

pragma solidity ^0.5.0;

pragma solidity ^0.5.0;


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

pragma solidity ^0.5.0;


 
library Address {

     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}

pragma solidity ^0.5.0;

 
contract CommonConstants {

    bytes4 constant internal ERC1155_ACCEPTED = 0x4dc21a2f;  
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xac007889;  
}

pragma solidity ^0.5.0;

 
interface IERC1155TokenReceiver {

     
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

     
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);

     
    function isERC1155TokenReceiver() external view returns (bytes4);
}

pragma solidity ^0.5.0;

pragma solidity ^0.5.0;


 
interface ERC165 {

     
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}


 
interface IERC1155   {
     
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

     
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
    event URI(string _value, uint256 indexed _id);

     
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

     
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

     
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

     
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

     
    function setApprovalForAll(address _operator, bool _approved) external;

     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


 
contract ERC1155 is IERC1155, ERC165, CommonConstants
{
    using SafeMath for uint256;
    using Address for address;

     
    mapping (uint256 => mapping(address => uint256)) internal balances;

     
    mapping (address => mapping(address => bool)) internal operatorApproval;

 

     
    bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

     
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    function supportsInterface(bytes4 _interfaceId)
    public
    view
    returns (bool) {
         if (_interfaceId == INTERFACE_SIGNATURE_ERC165 ||
             _interfaceId == INTERFACE_SIGNATURE_ERC1155) {
            return true;
         }

         return false;
    }

 

     
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external {

        require(_to != address(0x0), "_to must be non-zero.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

         
         
        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to]   = _value.add(balances[_id][_to]);

         
        emit TransferSingle(msg.sender, _from, _to, _id, _value);

         
         
        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _value, _data);
        }
    }

     
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external {

         
        require(_to != address(0x0), "destination address must be non-zero.");
        require(_ids.length == _values.length, "_ids and _values array lenght must match.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];

             
             
            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to]   = value.add(balances[id][_to]);
        }

         
         
         
         

         
        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

         
         
        if (_to.isContract()) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _ids, _values, _data);
        }
    }

     
    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
         
         
         
        return balances[_id][_owner];
    }


     
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory) {

        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

     
    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApproval[_owner][_operator];
    }

 

    function _doSafeTransferAcceptanceCheck(address _operator, address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) internal {

        (bool success, bytes memory returnData) = _to.call(
            abi.encodeWithSignature(
                "onERC1155Received(address,address,uint256,uint256,bytes)",
                _operator,
                _from,
                _id,
                _value,
                _data
            )
        );
        (success);  
        bytes4 receiverRet = 0x0;
        if(returnData.length > 0) {
            assembly {
                receiverRet := mload(add(returnData, 32))
            }
        }

        if (receiverRet == ERC1155_ACCEPTED) {
             
        } else {
             
            revert("Receiver contract did not accept the transfer.");
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(address _operator, address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) internal {

        (bool success, bytes memory returnData) = _to.call(
            abi.encodeWithSignature(
                "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)",
                _operator,
                _from,
                _ids,
                _values,
                _data
            )
        );
        (success);  
        bytes4 receiverRet = 0x0;
        if(returnData.length > 0) {
            assembly {
                receiverRet := mload(add(returnData, 32))
            }
        }

        if (receiverRet == ERC1155_BATCH_ACCEPTED) {
             
        } else {
             
            revert("Receiver contract did not accept the transfer.");
        }
    }
}


 
contract ERC1155MixedFungible is ERC1155 {

     
     
    uint256 constant TYPE_MASK = uint256(uint128(~0)) << 128;

     
    uint256 constant NF_INDEX_MASK = uint128(~0);

     
    uint256 constant public TYPE_NF_BIT = 1 << 255;

    uint256 constant NFT_MASK = (uint256(uint128(~0)) << 128) & ~uint256(1 << 255);

     
    mapping (uint256 => address) nfOwners;

     
    function isNonFungible(uint256 _id) public pure returns(bool) {
        return _id & TYPE_NF_BIT == TYPE_NF_BIT;
    }
    function isFungible(uint256 _id) public pure returns(bool) {
        return _id & TYPE_NF_BIT == 0;
    }
    function getNonFungibleIndex(uint256 _id) public pure returns(uint256) {
        return _id & NF_INDEX_MASK;
    }
    function getNonFungibleBaseType(uint256 _id) public pure returns(uint256) {
        return _id & TYPE_MASK;
    }
    function getNFTType(uint256 _id) public pure returns(uint256) {
        return (_id & NFT_MASK) >> 128;
    }
    function isNonFungibleBaseType(uint256 _id) public pure returns(bool) {
         
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK == 0);
    }
    function isNonFungibleItem(uint256 _id) public pure returns(bool) {
         
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK != 0);
    }

    function ownerOf(uint256 _id) external view returns (address) {
        return nfOwners[_id];
    }

    function _ownerOf(uint256 _id) internal view returns (address) {
        return nfOwners[_id];
    }

     
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external {

        require(_to != address(0x0), "cannot send to zero address");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        if (isNonFungible(_id)) {
            require(nfOwners[_id] == _from);
            nfOwners[_id] = _to;
             
             
             
             
            onTransferNft(_from, _to, _id);
        } else {
            balances[_id][_from] = balances[_id][_from].sub(_value);
            balances[_id][_to]   = balances[_id][_to].add(_value);
            onTransfer20(_from, _to, _id, _value);
        }

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _value, _data);
        }
    }

    function onTransferNft(address _from, address _to, uint256 _tokenId) internal {
    }

    function onTransfer20(address _from, address _to, uint256 _type, uint256 _value) internal {
    }

     
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external {

        require(_to != address(0x0), "cannot send to zero address");
        require(_ids.length == _values.length, "Array length must match");

         
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        for (uint256 i = 0; i < _ids.length; ++i) {
             
            uint256 id = _ids[i];
            uint256 value = _values[i];

            if (isNonFungible(id)) {
                require(nfOwners[id] == _from);
                nfOwners[id] = _to;
            } else {
                balances[id][_from] = balances[id][_from].sub(value);
                balances[id][_to]   = value.add(balances[id][_to]);
            }
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        if (_to.isContract()) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _ids, _values, _data);
        }
    }

    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
        if (isNonFungibleItem(_id))
            return nfOwners[_id] == _owner ? 1 : 0;
        return balances[_id][_owner];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory) {

        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            uint256 id = _ids[i];
            if (isNonFungibleItem(id)) {
                balances_[i] = nfOwners[id] == _owners[i] ? 1 : 0;
            } else {
            	balances_[i] = balances[id][_owners[i]];
            }
        }

        return balances_;
    }
}

pragma solidity ^0.5.0;

 
interface ERC1155Metadata_URI {
     
    function uri(uint256 _id) external view returns (string memory);
}

pragma solidity ^0.5.0;

pragma solidity ^0.5.0;

contract Operators
{
    mapping (address=>bool) ownerAddress;
    mapping (address=>bool) operatorAddress;

    constructor() public
    {
        ownerAddress[msg.sender] = true;
    }

    modifier onlyOwner()
    {
        require(ownerAddress[msg.sender]);
        _;
    }

    function isOwner(address _addr) public view returns (bool) {
        return ownerAddress[_addr];
    }

    function addOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));

        ownerAddress[_newOwner] = true;
    }

    function removeOwner(address _oldOwner) external onlyOwner {
        delete(ownerAddress[_oldOwner]);
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }

    function isOperator(address _addr) public view returns (bool) {
        return operatorAddress[_addr] || ownerAddress[_addr];
    }

    function addOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0));

        operatorAddress[_newOperator] = true;
    }

    function removeOperator(address _oldOperator) external onlyOwner {
        delete(operatorAddress[_oldOperator]);
    }
}


contract ERC1155URIProvider is Operators
{
    string public staticUri;

    function setUri(string calldata _uri) external onlyOwner
    {
        staticUri = _uri;
    }

    function uri(uint256) external view returns (string memory)
    {
        return staticUri;
    }
}

pragma solidity ^0.5.0;

interface IERC1155Mintable
{
    function mintNonFungibleSingle(uint256 _type, address _to) external;
    function mintNonFungible(uint256 _type, address[] calldata _to) external;
    function mintFungibleSingle(uint256 _id, address _to, uint256 _quantity) external;
    function mintFungible(uint256 _id, address[] calldata _to, uint256[] calldata _quantities) external;
}


pragma solidity ^0.5.0;

 
contract ERC20 {

    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
}

pragma solidity ^0.5.0;

 
 
 
interface ERC721Proxy   {

     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256);

     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address);

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;

     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external;

     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external;

     
     
     
     
    function getApproved(uint256 _tokenId) external view returns (address);

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);


     
    function name() external view returns (string memory _name);

     
    function symbol() external view returns (string memory _symbol);


     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string memory);

     
     
     
    function totalSupply() external view returns (uint256);

     
     
     
     
     
    function tokenByIndex(uint256 _index) external view returns (uint256);

     
     
     
     
     
     
     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);

     
     
     
     
    function transfer(address _to, uint256 _tokenId) external;

    function onTransfer(address _from, address _to, uint256 _nftIndex) external;
}

pragma solidity ^0.5.0;

 
contract ERC20Proxy {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    function onTransfer(address _from, address _to, uint256 _value) external;
}

pragma solidity ^0.5.0;

interface MintCallbackInterface
{
    function onMint(uint256 id) external;
}


 
contract BlockchainCutiesERC1155 is ERC1155MixedFungible, Operators, ERC1155Metadata_URI, IERC1155Mintable {

    mapping (uint256 => uint256) public maxIndex;

    mapping(uint256 => ERC721Proxy) public proxy721;
    mapping(uint256 => ERC20Proxy) public proxy20;
    mapping(uint256 => bool) public disallowSetProxy721;
    mapping(uint256 => bool) public disallowSetProxy20;
    MintCallbackInterface public mintCallback;

    bytes4 constant private INTERFACE_SIGNATURE_ERC1155_URI = 0x0e89341c;

    function supportsInterface(bytes4 _interfaceId) public view returns (bool) {
        return
            super.supportsInterface(_interfaceId) ||
            _interfaceId == INTERFACE_SIGNATURE_ERC1155_URI;
    }

     
     
     
    function create(uint256 _type) onlyOwner external
    {
         
        emit TransferSingle(msg.sender, address(0x0), address(0x0), _type, 0);
    }

    function setMintCallback(MintCallbackInterface _newCallback) external onlyOwner
    {
        mintCallback = _newCallback;
    }

    function mintNonFungibleSingleShort(uint128 _type, address _to) external onlyOperator {
        uint tokenType = (uint256(_type) << 128) | (1 << 255);
        _mintNonFungibleSingle(tokenType, _to);
    }

    function mintNonFungibleSingle(uint256 _type, address _to) external onlyOperator {
         
        require(isNonFungible(_type));
        require(getNonFungibleIndex(_type) == 0);

        _mintNonFungibleSingle(_type, _to);
    }

    function _mintNonFungibleSingle(uint256 _type, address _to) internal {

         
        uint256 index = maxIndex[_type] + 1;

        uint256 id  = _type | index;

        nfOwners[id] = _to;

         
         

        emit TransferSingle(msg.sender, address(0x0), _to, id, 1);

        onTransferNft(address(0x0), _to, id);
        maxIndex[_type] = maxIndex[_type].add(1);

        if (address(mintCallback) != address(0)) {
            mintCallback.onMint(id);
        }

        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, _to, id, 1, '');
        }
    }

    function mintNonFungibleShort(uint128 _type, address[] calldata _to) external onlyOperator {
        uint tokenType = (uint256(_type) << 128) | (1 << 255);
        _mintNonFungible(tokenType, _to);
    }

    function mintNonFungible(uint256 _type, address[] calldata _to) external onlyOperator {

         
        require(isNonFungible(_type), "_type must be NFT type");
        _mintNonFungible(_type, _to);
    }

    function _mintNonFungible(uint256 _type, address[] memory _to) internal {

         
        uint256 index = maxIndex[_type] + 1;

        for (uint256 i = 0; i < _to.length; ++i) {
            address dst = _to[i];
            uint256 id  = _type | index + i;

            nfOwners[id] = dst;

             
             

            emit TransferSingle(msg.sender, address(0x0), dst, id, 1);
            onTransferNft(address(0x0), dst, id);

            if (address(mintCallback) != address(0)) {
                mintCallback.onMint(id);
            }
            if (dst.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, dst, id, 1, '');
            }
        }

        maxIndex[_type] = _to.length.add(maxIndex[_type]);
    }

    function mintFungibleSingle(uint256 _id, address _to, uint256 _quantity) external onlyOperator {

        require(isFungible(_id));

         
        balances[_id][_to] = _quantity.add(balances[_id][_to]);

         
         
         
        emit TransferSingle(msg.sender, address(0x0), _to, _id, _quantity);
        onTransfer20(address(0x0), _to, _id, _quantity);

        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, _to, _id, _quantity, '');
        }
    }

    function mintFungible(uint256 _id, address[] calldata _to, uint256[] calldata _quantities) external onlyOperator {

        require(isFungible(_id));

        for (uint256 i = 0; i < _to.length; ++i) {

            address to = _to[i];
            uint256 quantity = _quantities[i];

             
            balances[_id][to] = quantity.add(balances[_id][to]);

             
             
             
            emit TransferSingle(msg.sender, address(0x0), to, _id, quantity);
            onTransfer20(address(0x0), to, _id, quantity);

            if (to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, to, _id, quantity, '');
            }
        }
    }

    function setURI(string calldata _uri, uint256 _id) external onlyOperator {
        emit URI(_uri, _id);
    }

    ERC1155URIProvider public uriProvider;

    function setUriProvider(ERC1155URIProvider _uriProvider) onlyOwner external
    {
        uriProvider = _uriProvider;
    }

    function uri(uint256 _id) external view returns (string memory)
    {
        return uriProvider.uri(_id);
    }

    function withdraw() external onlyOwner
    {
        if (address(this).balance > 0)
        {
            msg.sender.transfer(address(this).balance);
        }
    }

    function withdrawTokenFromBalance(ERC20 _tokenContract) external onlyOwner
    {
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(msg.sender, balance);
    }

    function totalSupplyNonFungible(uint256 _type) view external returns (uint256)
    {
         
        require(isNonFungible(_type));
        return maxIndex[_type];
    }

    function totalSupplyNonFungibleShort(uint128 _type) view external returns (uint256)
    {
        uint tokenType = (uint256(_type) << 128) | (1 << 255);
        return maxIndex[tokenType];
    }

    function setProxy721(uint256 nftType, ERC721Proxy proxy) external onlyOwner
    {
        require(!disallowSetProxy721[nftType]);
        proxy721[nftType] = proxy;
    }

     
    function disableSetProxy721(uint256 nftType) external onlyOwner
    {
        disallowSetProxy721[nftType] = true;
    }

    function setProxy20(uint256 _type, ERC20Proxy proxy) external onlyOwner
    {
        require(!disallowSetProxy20[_type]);
        proxy20[_type] = proxy;
    }

     
    function disableSetProxy20(uint256 _type) external onlyOwner
    {
        disallowSetProxy20[_type] = true;
    }

    function proxyTransfer721(address _from, address _to, uint256 _tokenId, bytes calldata _data) external
    {
        uint256 nftType = getNFTType(_tokenId);
        ERC721Proxy proxy = proxy721[nftType];
        require(msg.sender == address(proxy));

        require(_ownerOf(_tokenId) == _from);
        require(_to != address(0x0), "cannot send to zero address");
        nfOwners[_tokenId] = _to;
        emit TransferSingle(msg.sender, _from, _to, _tokenId, 1);
        onTransferNft(_from, _to, _tokenId);

        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(_to, _from, _to, _tokenId, 1, _data);
        }
    }

     
    function onTransferNft(address _from, address _to, uint256 _tokenId) internal {
        uint256 nftType = getNFTType(_tokenId);
        uint256 nftIndex = getNonFungibleIndex(_tokenId);
        ERC721Proxy proxy = proxy721[nftType];
        if (address(proxy) != address(0x0))
        {
            proxy.onTransfer(_from, _to, nftIndex);
        }
    }

    function proxyTransfer20(address _from, address _to, uint256 _tokenId, uint256 _value) external
    {
        ERC20Proxy proxy = proxy20[_tokenId];
        require(msg.sender == address(proxy));

        require(_to != address(0x0), "cannot send to zero address");

        balances[_tokenId][_from] = balances[_tokenId][_from].sub(_value);
        balances[_tokenId][_to]   = balances[_tokenId][_to].add(_value);

        emit TransferSingle(msg.sender, _from, _to, _tokenId, _value);
        onTransfer20(_from, _to, _tokenId, _value);
    }

     
    function onTransfer20(address _from, address _to, uint256 _tokenId, uint256 _value) internal {
        ERC20Proxy proxy = proxy20[_tokenId];
        if (address(proxy) != address(0x0))
        {
            proxy.onTransfer(_from, _to, _value);
        }
    }

     
    function burn(address _from, uint256 _id, uint256 _value) external {

        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        address to = address(0x0);

        if (isNonFungible(_id)) {
            require(nfOwners[_id] == _from);
            nfOwners[_id] = to;
             
             
             
             
            onTransferNft(_from, to, _id);
        } else {
            balances[_id][_from] = balances[_id][_from].sub(_value);
            balances[_id][to]   = balances[_id][to].add(_value);
            onTransfer20(_from, to, _id, _value);
        }

        emit TransferSingle(msg.sender, _from, to, _id, _value);
    }
}