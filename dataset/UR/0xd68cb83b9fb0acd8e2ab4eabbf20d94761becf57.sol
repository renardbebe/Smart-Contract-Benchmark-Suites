 

pragma solidity >=0.4.22 <0.6.0;

 
 
 
 
contract AacOwnership {
    struct Aac {
         
        address payable owner;
         
        uint uid;
         
        uint timestamp;
         
        uint exp;
         
        bytes aacData;
    }

    struct ExternalNft{
         
        address nftContractAddress;
         
        uint nftId;
    }

     
     
    Aac[] aacArray;
     
     
    mapping (uint => uint) uidToAacIndex;
     
     
    mapping (uint => ExternalNft) uidToExternalNft;
     
     
    mapping (address => mapping (uint => bool)) linkedExternalNfts;
    
     
     
     
    modifier mustExist(uint _tokenId) {
        require (uidToAacIndex[_tokenId] != 0);
        _;
    }

     
     
     
    modifier mustOwn(uint _tokenId) {
        require (ownerOf(_tokenId) == msg.sender);
        _;
    }

     
     
     
    modifier notZero(uint _param) {
        require(_param != 0);
        _;
    }

     
     
     
    constructor () public {
        aacArray.push(Aac(address(0), 0, 0, 0, ""));
    }

     
     
     
     
     
     
    function ownerOf(uint256 _tokenId) 
        public 
        view 
        mustExist(_tokenId) 
        returns (address payable) 
    {
         
        require (aacArray[uidToAacIndex[_tokenId]].owner != address(0));
        return aacArray[uidToAacIndex[_tokenId]].owner;
    }

     
     
     
     
     
     
    function balanceOf(address _owner) 
        public 
        view 
        notZero(uint(_owner)) 
        returns (uint256) 
    {
        uint owned;
        for (uint i = 1; i < aacArray.length; ++i) {
            if(aacArray[i].owner == _owner) {
                ++owned;
            }
        }
        return owned;
    }

     
     
     
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns (uint[] memory) {
        uint aacsOwned = balanceOf(_owner);
        require(aacsOwned > 0);
        uint counter = 0;
        uint[] memory result = new uint[](aacsOwned);
        for (uint i = 0; i < aacArray.length; i++) {
            if(aacArray[i].owner == _owner) {
                result[counter] = aacArray[i].uid;
                counter++;
            }
        }
        return result;
    }

     
     
     
     
     
    function totalSupply() external view returns (uint256) {
        return (aacArray.length - 1);
    }

     
     
     
     
     
     
    function tokenByIndex(uint256 _index) external view returns (uint256) {
         
        require (_index > 0 && _index < aacArray.length);
        return (aacArray[_index].uid);
    }

     
     
     
     
     
     
     
     
     
    function tokenOfOwnerByIndex(
        address _owner, 
        uint256 _index
    ) external view notZero(uint(_owner)) returns (uint256) {
        uint aacsOwned = balanceOf(_owner);
        require(aacsOwned > 0);
        require(_index < aacsOwned);
        uint counter = 0;
        for (uint i = 0; i < aacArray.length; i++) {
            if (aacArray[i].owner == _owner) {
                if (counter == _index) {
                    return(aacArray[i].uid);
                } else {
                    counter++;
                }
            }
        }
    }
}


 
 
 
interface TokenReceiverInterface {
    function onERC721Received(
        address _operator, 
        address _from, 
        uint256 _tokenId, 
        bytes calldata _data
    ) external returns(bytes4);
}


 
 
 
interface VIP181 {
    function transferFrom (
        address _from, 
        address _to, 
        uint256 _tokenId
    ) external payable;
    function ownerOf(uint _tokenId) external returns(address);
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function tokenURI(uint _tokenId) external view returns (string memory);
}


 
 
 
 
 
 
contract AacTransfers is AacOwnership {
     
     
     
     
     
     
    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 indexed _tokenId
    );

     
     
     
     
     
     
    event Approval(
        address indexed _owner, 
        address indexed _approved, 
        uint256 indexed _tokenId
    );

     
     
     
     
    event ApprovalForAll(
        address indexed _owner, 
        address indexed _operator, 
        bool _approved
    );

     
    mapping (uint => address) idToApprovedAddress;
     
    mapping (address => mapping (address => bool)) operatorApprovals;

     
     
     
     
    modifier canOperate(uint _uid) {
         
         
         
        require (
            msg.sender == aacArray[uidToAacIndex[_uid]].owner ||
            msg.sender == idToApprovedAddress[_uid] ||
            operatorApprovals[aacArray[uidToAacIndex[_uid]].owner][msg.sender]
        );
        _;
    }

     
     
     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external payable {
        address owner = ownerOf(_tokenId);
         
         
        require (
            msg.sender == owner || isApprovedForAll(owner, msg.sender)
        );
        idToApprovedAddress[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }
    
     
     
     
     
     
     
     
    function getApproved(
        uint256 _tokenId
    ) external view mustExist(_tokenId) returns (address) {
        return idToApprovedAddress[_tokenId];
    }
    
     
     
     
     
     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender);
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
     
     
     
     
     
     
     
    function isApprovedForAll(
        address _owner, 
        address _operator
    ) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address payable _to, uint256 _tokenId) 
        external 
        payable 
        mustExist(_tokenId) 
        canOperate(_tokenId) 
        notZero(uint(_to)) 
    {
        address owner = ownerOf(_tokenId);
         
        require (_from == owner);
               
         
         
        ExternalNft memory externalNft = uidToExternalNft[_tokenId];
        if (externalNft.nftContractAddress != address(0)) {
             
            VIP181 externalContract = VIP181(externalNft.nftContractAddress);
             
            address nftOwner = externalContract.ownerOf(externalNft.nftId);
            if(
                msg.sender == nftOwner ||
                msg.sender == externalContract.getApproved(externalNft.nftId) ||
                externalContract.isApprovedForAll(nftOwner, msg.sender)
            ) {
                 
                externalContract.transferFrom(_from, _to, externalNft.nftId);
            }
        }

         
        idToApprovedAddress[_tokenId] = address(0);
         
        aacArray[uidToAacIndex[_tokenId]].owner = _to;

        emit Transfer(_from, _to, _tokenId);

         
         
        uint size;
        assembly { size := extcodesize(_to) }
        if (size > 0) {
            bytes4 retval = TokenReceiverInterface(_to).onERC721Received(msg.sender, _from, _tokenId, "");
            require(
                retval == 0x150b7a02
            );
        }
    }
    
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(
        address _from, 
        address payable _to, 
        uint256 _tokenId, 
        bytes calldata _data
    ) 
        external 
        payable 
        mustExist(_tokenId) 
        canOperate(_tokenId) 
        notZero(uint(_to)) 
    {
        address owner = ownerOf(_tokenId);
         
        require (_from == owner);
        
         
         
        ExternalNft memory externalNft = uidToExternalNft[_tokenId];
        if (externalNft.nftContractAddress != address(0)) {
             
            VIP181 externalContract = VIP181(externalNft.nftContractAddress);
             
            address nftOwner = externalContract.ownerOf(externalNft.nftId);
            if(
                msg.sender == nftOwner ||
                msg.sender == externalContract.getApproved(externalNft.nftId) ||
                externalContract.isApprovedForAll(nftOwner, msg.sender)
            ) {
                 
                externalContract.transferFrom(_from, _to, externalNft.nftId);
            }
        }

         
        idToApprovedAddress[_tokenId] = address(0);
         
        aacArray[uidToAacIndex[_tokenId]].owner = _to;

        emit Transfer(_from, _to, _tokenId);

         
         
        uint size;
        assembly { size := extcodesize(_to) }
        if (size > 0) {
            bytes4 retval = TokenReceiverInterface(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require (retval == 0x150b7a02);
        }
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address payable _to, uint256 _tokenId)
        external 
        payable 
        mustExist(_tokenId) 
        canOperate(_tokenId) 
        notZero(uint(_to)) 
    {
        address owner = ownerOf(_tokenId);
         
        require (_from == owner && _from != address(0));
        
         
         
        ExternalNft memory externalNft = uidToExternalNft[_tokenId];
        if (externalNft.nftContractAddress != address(0)) {
             
            VIP181 externalContract = VIP181(externalNft.nftContractAddress);
             
            address nftOwner = externalContract.ownerOf(externalNft.nftId);
            if(
                msg.sender == nftOwner ||
                msg.sender == externalContract.getApproved(externalNft.nftId) ||
                externalContract.isApprovedForAll(nftOwner, msg.sender)
            ) {
                 
                externalContract.transferFrom(_from, _to, externalNft.nftId);
            }
        }

         
        idToApprovedAddress[_tokenId] = address(0);
         
        aacArray[uidToAacIndex[_tokenId]].owner = _to;

        emit Transfer(_from, _to, _tokenId);
    }
}

 
 
 
 
 
 
contract Ownable {
     
     
     
    event OwnershipTransfer (address previousOwner, address newOwner);
    
     
    address owner;
    
     
     
     
    constructor() public {
        owner = msg.sender;
    }

     
     
     
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

     
     
     
     
     
    function transferOwnership(address _newOwner) public onlyOwner {
         
        require (_newOwner != address(0));
         
        address oldOwner = owner;
         
        owner = _newOwner;
         
        emit OwnershipTransfer(oldOwner, _newOwner);
    }
}


 
 
 
 
contract ERC165 {
     
    mapping (bytes4 => bool) interfaceIdToIsSupported;
    
    bytes4 constant ERC_165 = 0x01ffc9a7;
    bytes4 constant ERC_721 = 0x80ac58cd;
    bytes4 constant ERC_721_ENUMERATION = 0x780e9d63;
    bytes4 constant ERC_721_METADATA = 0x5b5e139f;
    
     
     
     
     
    constructor () public {
         
        interfaceIdToIsSupported[ERC_165] = true;
         
        interfaceIdToIsSupported[ERC_721] = true;
         
        interfaceIdToIsSupported[ERC_721_ENUMERATION] = true;
         
        interfaceIdToIsSupported[ERC_721_METADATA] = true;
    }

     
     
     
     
     
     
     
     
    function supportsInterface(
        bytes4 interfaceID
    ) external view returns (bool) {
        if(interfaceID == 0xffffffff) {
            return false;
        } else {
            return interfaceIdToIsSupported[interfaceID];
        }
    }
}


 
 
 
 
 
contract AacCreation is AacTransfers, ERC165, Ownable {
     
     
     
    event Link(uint _oldUid, uint _newUid);

    address public creationHandlerContractAddress;
     
    uint constant UID_MAX = 0xFFFFFFFFFFFFFF;
    
    function setCreationHandlerContractAddress(address _creationHandlerAddress) 
    external 
    notZero(uint(_creationHandlerAddress))
    onlyOwner 
    {
        creationHandlerContractAddress = _creationHandlerAddress;
    }

     
     
     
     
     
     
     
     
    function mintAndSend(address payable _to) external {
        require (msg.sender == creationHandlerContractAddress);

        uint uid = UID_MAX + aacArray.length + 1;
        uint index = aacArray.push(Aac(_to, uid, 0, 0, ""));
        uidToAacIndex[uid] = index - 1;

        emit Transfer(address(0), _to, uid);
    }

     
     
     
     
     
     
     
     
     
     
     
    function link(
        bytes7 _newUid, 
        uint _currentUid, 
        bytes calldata _data
    ) external {
        require (msg.sender == creationHandlerContractAddress);
        Aac storage aac = aacArray[uidToAacIndex[_currentUid]];
        uint newUid = uint(uint56(_newUid));

         
        uidToAacIndex[newUid] = uidToAacIndex[_currentUid];
         
        uidToAacIndex[_currentUid] = 0;
         
        aac.uid = newUid;
         
        aac.aacData = _data;
         
        aac.timestamp = now;
         
        if (uidToExternalNft[_currentUid].nftContractAddress != address(0)) {
            uidToExternalNft[newUid] = uidToExternalNft[_currentUid];
        }

        emit Link(_currentUid, newUid);
    }

     
     
     
     
     
     
     
     
     
     
    function linkExternalNft(
        uint _aacUid, 
        address _externalAddress, 
        uint _externalId
    ) external canOperate(_aacUid) {
        require (linkedExternalNfts[_externalAddress][_externalId] == false);
        require (ERC165(_externalAddress).supportsInterface(ERC_721));
        require (msg.sender == VIP181(_externalAddress).ownerOf(_externalId));
        uidToExternalNft[_aacUid] = ExternalNft(_externalAddress, _externalId);
        linkedExternalNfts[_externalAddress][_externalId] = true;
    }
    
     
     
     
    function checkExists(uint _tokenId) external view returns(bool) {
        return (uidToAacIndex[_tokenId] != 0);
    }
}


 
 
 
 
contract AacExperience is AacCreation {
    address public expIncreaserContractAddress;

    function setExpIncreaserContractAddress(address _expAddress) 
    external 
    notZero(uint(_expAddress))
    onlyOwner 
    {
        expIncreaserContractAddress = _expAddress;
    }
    
    function addExp(uint _uid, uint _amount) external mustExist(_uid) {
        require (msg.sender == expIncreaserContractAddress);
        aacArray[uidToAacIndex[_uid]].exp += _amount;
    }
}


 
 
 
 
contract AacInterface is AacExperience {
     
    string metadataUrl;

     
     
     
     
     
    function updateMetadataUrl(string calldata _newUrl)
        external 
        onlyOwner 
        notZero(bytes(_newUrl).length)
    {
        metadataUrl = _newUrl;
    }

     
     
     
     
     
     
    function changeAacData(uint _uid, bytes calldata _data) 
        external 
        mustExist(_uid)
        canOperate(_uid)
    {
        aacArray[uidToAacIndex[_uid]].aacData = _data;
    }

     
     
     
     
     
     
     
    function getAac(uint _uid) 
        external
        view 
        mustExist(_uid) 
        returns (address, uint, uint, uint, bytes memory) 
    {
        Aac memory aac = aacArray[uidToAacIndex[_uid]];
        return(aac.owner, aac.uid, aac.timestamp, aac.exp, aac.aacData);
    }

     
     
     
     
     
     
    function getLinkedNft(uint _uid) 
        external
        view 
        mustExist(_uid) 
        returns (address, uint) 
    {
        ExternalNft memory nft = uidToExternalNft[_uid];
        return (nft.nftContractAddress, nft.nftId);
    }

     
     
     
     
     
     
    function externalNftIsLinked(address _externalAddress, uint _externalId)
        external
        view
        returns(bool)
    {
        return linkedExternalNfts[_externalAddress][_externalId];
    }

     
     
     
    function name() external pure returns (string memory) {
        return "Authentic Asset Certificates";
    }

     
     
     
    function symbol() external pure returns (string memory) { return "AAC"; }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function tokenURI(uint _tokenId) external view returns (string memory) {
        if (uidToExternalNft[_tokenId].nftContractAddress != address(0) && 
            ERC165(uidToExternalNft[_tokenId].nftContractAddress).supportsInterface(ERC_721_METADATA)) 
        {
            return VIP181(uidToExternalNft[_tokenId].nftContractAddress).tokenURI(_tokenId);
        }
        else {
             
            bytes memory uidString = intToBytes(_tokenId);
             
            bytes memory fullUrlBytes = new bytes(bytes(metadataUrl).length + uidString.length);
             
            uint counter = 0;
            for (uint i = 0; i < bytes(metadataUrl).length; i++) {
                fullUrlBytes[counter++] = bytes(metadataUrl)[i];
            }
            for (uint i = 0; i < uidString.length; i++) {
                fullUrlBytes[counter++] = uidString[i];
            }
             
            return string(fullUrlBytes);
        }
    }
    
     
     
     
    function intToBytes(uint _tokenId) 
        private 
        pure 
        returns (bytes memory) 
    {
         
        bytes32 x = bytes32(_tokenId);
        
         
        bytes memory uidBytes64 = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            byte b = byte(x[i]);
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            uidBytes64[i*2] = char(hi);
            uidBytes64[i*2+1] = char(lo);
        }
        
         
        bytes memory uidBytes = new bytes(14);
        for (uint i = 0; i < 14; ++i) {
            uidBytes[i] = uidBytes64[i + 50];
        }
        return uidBytes;
    }
    
     
     
     
    function char(byte b) private pure returns (byte c) {
        if (uint8(b) < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }
}