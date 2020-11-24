 

pragma solidity ^0.4.24;

 
 
 
 
contract ToyOwnership {
    struct ToyToken {
         
        address owner;
         
        uint uid;
         
        uint timestamp;
         
        uint exp;
         
        bytes toyData;
    }

    struct ExternalNft{
         
        address nftContractAddress;
         
        uint nftId;
    }

     
     
    ToyToken[] toyArray;
     
     
    mapping (uint => uint) uidToToyIndex;
     
     
    mapping (uint => ExternalNft) uidToExternalNft;
     
     
    mapping (address => mapping (uint => bool)) linkedExternalNfts;
    
     
     
     
    modifier mustExist(uint _tokenId) {
        require (uidToToyIndex[_tokenId] != 0, "Invalid TOY Token UID");
        _;
    }

     
     
     
    modifier mustOwn(uint _tokenId) {
        require 
        (
            ownerOf(_tokenId) == msg.sender, 
            "Must be owner of this TOY Token"
        );
        _;
    }

     
     
     
    modifier notZero(uint _param) {
        require(_param != 0, "Parameter cannot be zero");
        _;
    }

     
     
     
     
    constructor () public {
        toyArray.push(ToyToken(0,0,0,0,""));
    }

     
     
     
     
     
     
    function ownerOf(uint256 _tokenId) 
        public 
        view 
        mustExist(_tokenId) 
        returns (address) 
    {
         
        require (
            toyArray[uidToToyIndex[_tokenId]].owner != 0, 
            "TOY Token has no owner"
        );
        return toyArray[uidToToyIndex[_tokenId]].owner;
    }

     
     
     
     
     
     
    function balanceOf(address _owner) 
        public 
        view 
        notZero(uint(_owner)) 
        returns (uint256) 
    {
        uint owned;
        for (uint i = 1; i < toyArray.length; ++i) {
            if(toyArray[i].owner == _owner) {
                ++owned;
            }
        }
        return owned;
    }

     
     
     
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns (uint[]) {
        uint toysOwned = balanceOf(_owner);
        require(toysOwned > 0, "No owned TOY Tokens");
        uint counter = 0;
        uint[] memory result = new uint[](toysOwned);
        for (uint i = 0; i < toyArray.length; i++) {
            if(toyArray[i].owner == _owner) {
                result[counter] = toyArray[i].uid;
                counter++;
            }
        }
        return result;
    }

     
     
     
     
     
    function totalSupply() external view returns (uint256) {
        return (toyArray.length - 1);
    }

     
     
     
     
     
     
    function tokenByIndex(uint256 _index) external view returns (uint256) {
         
        require (_index > 0 && _index < toyArray.length, "Invalid index");
        return (toyArray[_index].uid);
    }

     
     
     
     
     
     
     
     
     
    function tokenOfOwnerByIndex(
        address _owner, 
        uint256 _index
    ) external view notZero(uint(_owner)) returns (uint256) {
        uint toysOwned = balanceOf(_owner);
        require(toysOwned > 0, "No owned TOY Tokens");
        require(_index < toysOwned, "Invalid index");
        uint counter = 0;
        for (uint i = 0; i < toyArray.length; i++) {
            if (toyArray[i].owner == _owner) {
                if (counter == _index) {
                    return(toyArray[i].uid);
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
        bytes _data
    ) external returns(bytes4);
}


 
 
 
interface ERC721 {
    function transferFrom (
        address _from, 
        address _to, 
        uint256 _tokenId
    ) external payable;
    function ownerOf(uint _tokenId) external returns(address);
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


 
 
 
 
 
 
contract ToyTransfers is ToyOwnership {
     
     
     
     
     
     
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
            msg.sender == toyArray[uidToToyIndex[_uid]].owner ||
            msg.sender == idToApprovedAddress[_uid] ||
            operatorApprovals[toyArray[uidToToyIndex[_uid]].owner][msg.sender],
            "Not authorized to operate for this TOY Token"
        );
        _;
    }

     
     
     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external payable {
        address owner = ownerOf(_tokenId);
         
         
        require (
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Not authorized to approve for this TOY Token"
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
        require(_operator != msg.sender, "Operator cannot be sender");
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
     
     
     
     
     
     
     
     
    function isApprovedForAll(
        address _owner, 
        address _operator
    ) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) 
        external 
        payable 
        mustExist(_tokenId) 
        canOperate(_tokenId) 
        notZero(uint(_to)) 
    {
        address owner = ownerOf(_tokenId);
         
        require (
            _from == owner, 
            "TOY Token not owned by '_from'"
        );
               
         
         
        ExternalNft memory externalNft = uidToExternalNft[_tokenId];
        if (externalNft.nftContractAddress != 0) {
             
            ERC721 externalContract = ERC721(externalNft.nftContractAddress);
             
            externalContract.transferFrom(_from, _to, externalNft.nftId);
        }

         
        idToApprovedAddress[_tokenId] = 0;
         
        toyArray[uidToToyIndex[_tokenId]].owner = _to;

        emit Transfer(_from, _to, _tokenId);

         
         
        uint size;
        assembly { size := extcodesize(_to) }
        if (size > 0) {
            bytes4 retval = TokenReceiverInterface(_to).onERC721Received(msg.sender, _from, _tokenId, "");
            require(
                retval == 0x150b7a02, 
                "Destination contract not equipped to receive TOY Tokens"
            );
        }
    }
    
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(
        address _from, 
        address _to, 
        uint256 _tokenId, 
        bytes _data
    ) 
        external 
        payable 
        mustExist(_tokenId) 
        canOperate(_tokenId) 
        notZero(uint(_to)) 
    {
        address owner = ownerOf(_tokenId);
         
        require (
            _from == owner, 
            "TOY Token not owned by '_from'"
        );
        
         
         
        ExternalNft memory externalNft = uidToExternalNft[_tokenId];
        if (externalNft.nftContractAddress != 0) {
             
            ERC721 externalContract = ERC721(externalNft.nftContractAddress);
             
            externalContract.transferFrom(_from, _to, externalNft.nftId);
        }

         
        idToApprovedAddress[_tokenId] = 0;
         
        toyArray[uidToToyIndex[_tokenId]].owner = _to;

        emit Transfer(_from, _to, _tokenId);

         
         
        uint size;
        assembly { size := extcodesize(_to) }
        if (size > 0) {
            bytes4 retval = TokenReceiverInterface(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(
                retval == 0x150b7a02,
                "Destination contract not equipped to receive TOY Tokens"
            );
        }
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external 
        payable 
        mustExist(_tokenId) 
        canOperate(_tokenId) 
        notZero(uint(_to)) 
    {
        address owner = ownerOf(_tokenId);
         
        require (
            _from == owner && _from != 0, 
            "TOY Token not owned by '_from'"
        );
        
         
         
        ExternalNft memory externalNft = uidToExternalNft[_tokenId];
        if (externalNft.nftContractAddress != 0) {
             
            ERC721 externalContract = ERC721(externalNft.nftContractAddress);
             
            externalContract.transferFrom(_from, _to, externalNft.nftId);
        }

         
        idToApprovedAddress[_tokenId] = 0;
         
        toyArray[uidToToyIndex[_tokenId]].owner = _to;

        emit Transfer(_from, _to, _tokenId);
    }
}


 
 
 
interface ERC20 {
    function transfer (
        address to, 
        uint tokens
    ) external returns (bool success);

    function transferFrom (
        address from, 
        address to, 
        uint tokens
    ) external returns (bool success);
}


 
 
 
 
 
contract ExternalTokenHandler is ToyTransfers {
     
    mapping (address => mapping(uint => uint)) externalTokenBalances;
    
     
    uint constant UID_MAX = 0xFFFFFFFFFFFFFF;

     
     
     
     
     
     
     
    function depositEther(uint _toUid) 
        external 
        payable 
        canOperate(_toUid)
        notZero(msg.value)
    {
         
        require (
            _toUid < UID_MAX, 
            "Invalid TOY Token. TOY Token not yet linked"
        );
         
        externalTokenBalances[address(this)][_toUid] += msg.value;
    }

     
     
     
     
     
     
     
     
    function withdrawEther(
        uint _fromUid, 
        uint _amount
    ) external canOperate(_fromUid) notZero(_amount) {
         
        require (
            externalTokenBalances[address(this)][_fromUid] >= _amount,
            "Insufficient Ether to withdraw"
        );
         
        externalTokenBalances[address(this)][_fromUid] -= _amount;
         
        ownerOf(_fromUid).transfer(_amount);
    }

     
     
     
     
     
     
     
     
     
    function transferEther(
        uint _fromUid,
        address _to,
        uint _amount
    ) external canOperate(_fromUid) notZero(_amount) {
         
        require (
            externalTokenBalances[address(this)][_fromUid] >= _amount,
            "Insufficient Ether to transfer"
        );
         
        externalTokenBalances[address(this)][_fromUid] -= _amount;
         
        _to.transfer(_amount);
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function depositERC20 (
        address _tokenAddress, 
        uint _toUid, 
        uint _tokens
    ) external canOperate(_toUid) notZero(_tokens) {
         
        require (_toUid < UID_MAX, "Invalid TOY Token. TOY Token not yet linked");
         
        ERC20 tokenContract = ERC20(_tokenAddress);
         
        externalTokenBalances[_tokenAddress][_toUid] += _tokens;

         
        tokenContract.transferFrom(msg.sender, address(this), _tokens);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
    function depositERC20From (
        address _tokenAddress,
        address _from, 
        uint _toUid, 
        uint _tokens
    ) external canOperate(_toUid) notZero(_tokens) {
         
        require (
            _toUid < UID_MAX, 
            "Invalid TOY Token. TOY Token not yet linked"
        );
         
        ERC20 tokenContract = ERC20(_tokenAddress);
         
        externalTokenBalances[_tokenAddress][_toUid] += _tokens;

         
        tokenContract.transferFrom(_from, address(this), _tokens);
    }

     
     
     
     
     
     
     
     
     
     
     
    function withdrawERC20 (
        address _tokenAddress, 
        uint _fromUid, 
        uint _tokens
    ) external canOperate(_fromUid) notZero(_tokens) {
         
        require (
            externalTokenBalances[_tokenAddress][_fromUid] >= _tokens,
            "insufficient tokens to withdraw"
        );
         
        ERC20 tokenContract = ERC20(_tokenAddress);
         
        externalTokenBalances[_tokenAddress][_fromUid] -= _tokens;
        
         
        tokenContract.transfer(ownerOf(_fromUid), _tokens);
    }

     
     
     
     
     
     
     
     
     
     
     
    function transferERC20 (
        address _tokenAddress, 
        uint _fromUid, 
        address _to, 
        uint _tokens
    ) external canOperate(_fromUid) notZero(_tokens) {
         
        require (
            externalTokenBalances[_tokenAddress][_fromUid] >= _tokens,
            "insufficient tokens to withdraw"
        );
         
        ERC20 tokenContract = ERC20(_tokenAddress);
         
        externalTokenBalances[_tokenAddress][_fromUid] -= _tokens;
        
         
        tokenContract.transfer(_to, _tokens);
    }

     
     
     
     
     
     
     
    function getExternalTokenBalance(
        uint _uid, 
        address _tokenAddress
    ) external view returns (uint) {
        return externalTokenBalances[_tokenAddress][_uid];
    }
}


 
 
 
 
 
 
contract Ownable {
     
     
     
    event OwnershipTransfer (address previousOwner, address newOwner);
    
     
    address owner;
    
     
     
     
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransfer(address(0), owner);
    }

     
     
     
    modifier onlyOwner() {
        require(
            msg.sender == owner, 
            "Function can only be called by contract owner"
        );
        _;
    }

     
     
     
     
     
    function transferOwnership(address _newOwner) public onlyOwner {
         
        require (
            _newOwner != address(0),
            "New owner address cannot be zero"
        );
         
        address oldOwner = owner;
         
        owner = _newOwner;
         
        emit OwnershipTransfer(oldOwner, _newOwner);
    }
}


 
 
 
 
contract ToyInterfaceSupport {
     
    mapping (bytes4 => bool) interfaceIdToIsSupported;
    
     
     
     
     
    constructor () public {
         
        interfaceIdToIsSupported[0x01ffc9a7] = true;
         
        interfaceIdToIsSupported[0x80ac58cd] = true;
         
        interfaceIdToIsSupported[0x780e9d63] = true;
         
        interfaceIdToIsSupported[0x5b5e139f] = true;
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


 
 
 
interface PlayInterface {
     
     
     
     
     
     
    function balanceOf(address tokenOwner) external view returns (uint);
    
     
     
     
     
     
     
     
     
     
     
     
     
    function lockFrom(address from, uint numberOfYears, uint tokens) 
        external
        returns(bool); 
}


 
 
 
 
 
contract ToyCreation is Ownable, ExternalTokenHandler, ToyInterfaceSupport {
     
     
     
    event Link(uint _oldUid, uint _newUid);

     
    uint public priceToMint = 1000 * 10**18;
     
     
    uint constant uidBuffer = 0x0100000000000000;  
     
    PlayInterface play = PlayInterface(0xe2427cfEB5C330c007B8599784B97b65b4a3A819);

     
     
     
     
     
    function updatePlayTokenContract(address _newAddress) external onlyOwner {
        play = PlayInterface(_newAddress);
    }

     
     
     
     
     
     
    function changeToyPrice(uint _newPrice) external onlyOwner {
        priceToMint = _newPrice;
    }

     
     
     
     
     
     
     
    function mint() external {
        play.lockFrom (msg.sender, 2, priceToMint);

        uint uid = uidBuffer + toyArray.length;
        uint index = toyArray.push(ToyToken(msg.sender, uid, 0, 0, ""));
        uidToToyIndex[uid] = index - 1;

        emit Transfer(0, msg.sender, uid);
    }

     
     
     
     
     
     
     
     
    function mintAndSend(address _to) external {
        play.lockFrom (msg.sender, 2, priceToMint);

        uint uid = uidBuffer + toyArray.length;
        uint index = toyArray.push(ToyToken(_to, uid, 0, 0, ""));
        uidToToyIndex[uid] = index - 1;

        emit Transfer(0, _to, uid);
    }

     
     
     
     
     
     
     
     
    function mintBulk(uint _amount) external {
        play.lockFrom (msg.sender, 2, priceToMint * _amount);

        for (uint i = 0; i < _amount; ++i) {
            uint uid = uidBuffer + toyArray.length;
            uint index = toyArray.push(ToyToken(msg.sender, uid, 0, 0, ""));
            uidToToyIndex[uid] = index - 1;
            emit Transfer(0, msg.sender, uid);
        }
    }

     
     
     
     
     
     
     
     
     
     
     
    function link(
        bytes7 _newUid, 
        uint _toyId, 
        bytes _data
    ) external canOperate(_toyId) {
        ToyToken storage toy = toyArray[uidToToyIndex[_toyId]];
         
        require (_toyId > uidBuffer, "TOY Token already linked");
         
        require (_newUid > 0 && uint(_newUid) < UID_MAX, "Invalid new UID");
         
        require (
            uidToToyIndex[uint(_newUid)] == 0, 
            "TOY Token with 'newUID' already exists"
        );

         
        uidToToyIndex[uint(_newUid)] = uidToToyIndex[_toyId];
         
        uidToToyIndex[_toyId] = 0;
         
        toy.uid = uint(_newUid);
         
        toy.toyData = _data;
         
        toy.timestamp = now;

        emit Link(_toyId, uint(_newUid));
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function linkBulk(
        bytes7[] _newUid, 
        uint[] _toyId, 
        bytes _data
    ) external {
        require (_newUid.length == _toyId.length, "Array lengths not equal");
        for (uint i = 0; i < _newUid.length; ++i) {
            ToyToken storage toy = toyArray[uidToToyIndex[_toyId[i]]];
             
            require (
                msg.sender == toy.owner ||
                msg.sender == idToApprovedAddress[_toyId[i]] ||
                operatorApprovals[toy.owner][msg.sender],
                "Not authorized to operate for this TOY Token"
            );
             
            require (_toyId[i] > uidBuffer, "TOY Token already linked");
             
            require (_newUid[i] > 0 && uint(_newUid[i]) < UID_MAX, "Invalid new UID");
             
            require (
                uidToToyIndex[uint(_newUid[i])] == 0, 
                "TOY Token with 'newUID' already exists"
            );

             
            uidToToyIndex[uint(_newUid[i])] = uidToToyIndex[_toyId[i]];
             
            uidToToyIndex[_toyId[i]] = 0;
             
            toy.uid = uint(_newUid[i]);
             
            toy.toyData = _data;
             
            toy.timestamp = now;

            emit Link(_toyId[i], uint(_newUid[i]));
        }
    }

     
     
     
     
     
     
     
     
     
     
     
    function linkExternalNft(
        uint _toyUid, 
        address _externalAddress, 
        uint _externalId
    ) external canOperate(_toyUid) {
        require(_toyUid < UID_MAX, "TOY Token not linked to a physical toy");
        require(
            linkedExternalNfts[_externalAddress][_externalId] == false,
            "External NFT already linked"
        );
        require(
            msg.sender == ERC721(_externalAddress).ownerOf(_externalId),
            "Sender does not own external NFT"
        );
        uidToExternalNft[_toyUid] = ExternalNft(_externalAddress, _externalId);
        linkedExternalNfts[_externalAddress][_externalId] = true;
    }
}


 
 
 
 
contract ToyInterface is ToyCreation {
     
    string metadataUrl = "http://52.9.230.48:8090/toy_token/";

     
     
     
     
     
    function updateMetadataUrl(string _newUrl)
        external 
        onlyOwner 
        notZero(bytes(_newUrl).length)
    {
        metadataUrl = _newUrl;
    }

     
     
     
     
     
     
     
    function changeToyData(uint _uid, bytes _data) 
        external 
        mustExist(_uid)
        canOperate(_uid)
        returns (address, uint, uint, uint, bytes) 
    {
        require(_uid < UID_MAX, "TOY Token must be linked");
        toyArray[uidToToyIndex[_uid]].toyData = _data;
    }

     
     
     
     
     
     
     
    function getToy(uint _uid) 
        external
        view 
        mustExist(_uid) 
        returns (address, uint, uint, uint, bytes) 
    {
        ToyToken memory toy = toyArray[uidToToyIndex[_uid]];
        return(toy.owner, toy.uid, toy.timestamp, toy.exp, toy.toyData);
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

     
     
     
    function name() external pure returns (string) {
        return "TOY Tokens";
    }

     
     
     
    function symbol() external pure returns (string) { return "TOY"; }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function tokenURI(uint _tokenId) 
        external 
        view 
        returns (string) 
    {
         
        bytes memory uidString = intToBytes(_tokenId);
         
        bytes memory fullUrlBytes = new bytes(bytes(metadataUrl).length + uidString.length);
         
        uint counter = 0;
        for (uint i = 0; i < bytes(metadataUrl).length; i++) {
            fullUrlBytes[counter++] = bytes(metadataUrl)[i];
        }
        for (i = 0; i < uidString.length; i++) {
            fullUrlBytes[counter++] = uidString[i];
        }
         
        return string(fullUrlBytes);
    }
    
     
     
     
    function intToBytes(uint _tokenId) 
        private 
        pure 
        returns (bytes) 
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
        for (i = 0; i < 14; ++i) {
            uidBytes[i] = uidBytes64[i + 50];
        }
        return uidBytes;
    }
    
     
     
     
    function char(byte b) private pure returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }
}