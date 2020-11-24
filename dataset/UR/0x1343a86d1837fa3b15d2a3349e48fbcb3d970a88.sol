 

pragma solidity ^0.4.23;

 
 
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

 
 
contract ERC721 is ERC165 {
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

 
interface ERC721TokenReceiver {
	function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

contract AccessAdmin {
    bool public isPaused = false;
    address public addrAdmin;  

    event AdminTransferred(address indexed preAdmin, address indexed newAdmin);

    constructor() public {
        addrAdmin = msg.sender;
    }  


    modifier onlyAdmin() {
        require(msg.sender == addrAdmin);
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused);
        _;
    }

    modifier whenPaused {
        require(isPaused);
        _;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0));
        emit AdminTransferred(addrAdmin, _newAdmin);
        addrAdmin = _newAdmin;
    }

    function doPause() external onlyAdmin whenNotPaused {
        isPaused = true;
    }

    function doUnpause() external onlyAdmin whenPaused {
        isPaused = false;
    }
}

 
contract ELHeroToken is ERC721,AccessAdmin{
    struct Card {
        uint16 protoId;      
        uint16 hero;         
        uint16 quality;      
        uint16 feature;      
        uint16 level;        
        uint16 attrExt1;     
        uint16 attrExt2;     
    }
    
     
    Card[] public cardArray;

     
    uint256 destroyCardCount;

     
    mapping (uint256 => address) cardIdToOwner;

     
    mapping (address => uint256[]) ownerToCardArray;
    
     
    mapping (uint256 => uint256) cardIdToOwnerIndex;

     
    mapping (uint256 => address) cardIdToApprovals;

     
    mapping (address => mapping (address => bool)) operatorToApprovals;

     
    mapping (address => bool) actionContracts;

    function setActionContract(address _actionAddr, bool _useful) external onlyAdmin {
        actionContracts[_actionAddr] = _useful;
    }

    function getActionContract(address _actionAddr) external view onlyAdmin returns(bool) {
        return actionContracts[_actionAddr];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event CreateCard(address indexed owner, uint256 tokenId, uint16 protoId, uint16 hero, uint16 quality, uint16 createType);
    event DeleteCard(address indexed owner, uint256 tokenId, uint16 deleteType);
    event ChangeCard(address indexed owner, uint256 tokenId, uint16 changeType);
    

    modifier isValidToken(uint256 _tokenId) {
        require(_tokenId >= 1 && _tokenId <= cardArray.length);
        require(cardIdToOwner[_tokenId] != address(0)); 
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address owner = cardIdToOwner[_tokenId];
        require(msg.sender == owner || msg.sender == cardIdToApprovals[_tokenId] || operatorToApprovals[owner][msg.sender]);
        _;
    }

     
    function supportsInterface(bytes4 _interfaceId) external view returns(bool) {
         
        return (_interfaceId == 0x01ffc9a7 || _interfaceId == 0x80ac58cd || _interfaceId == 0x8153916a) && (_interfaceId != 0xffffffff);
    }

    constructor() public {
        addrAdmin = msg.sender;
        cardArray.length += 1;
    }


    function name() public pure returns(string) {
        return "Ether League Hero Token";
    }

    function symbol() public pure returns(string) {
        return "ELHT";
    }

     
     
     
    function balanceOf(address _owner) external view returns (uint256){
        require(_owner != address(0));
        return ownerToCardArray[_owner].length;
    }

     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address){
        return cardIdToOwner[_tokenId];
    }

     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external whenNotPaused{
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external whenNotPaused{
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external whenNotPaused isValidToken(_tokenId) canTransfer(_tokenId){
        address owner = cardIdToOwner[_tokenId];
        require(owner != address(0));
        require(_to != address(0));
        require(owner == _from);
        
        _transfer(_from, _to, _tokenId);
    }
    

     
     
     
    function approve(address _approved, uint256 _tokenId) external whenNotPaused{
        address owner = cardIdToOwner[_tokenId];
        require(owner != address(0));
        require(msg.sender == owner || operatorToApprovals[owner][msg.sender]);

        cardIdToApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

     
     
     
    function setApprovalForAll(address _operator, bool _approved) external whenNotPaused{
        operatorToApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

     
     
     
    function getApproved(uint256 _tokenId) external view isValidToken(_tokenId) returns (address) {
        return cardIdToApprovals[_tokenId];
    }

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorToApprovals[_owner][_operator];
    }

     
     
    function totalSupply() external view returns (uint256) {
        return cardArray.length - destroyCardCount - 1;
    }

     
    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) internal isValidToken(_tokenId) canTransfer(_tokenId){
        address owner = cardIdToOwner[_tokenId];
        require(owner != address(0));
        require(_to != address(0));
        require(owner == _from);
        
        _transfer(_from, _to, _tokenId);

         
        uint256 codeSize;
        assembly { codeSize := extcodesize(_to) }
        if (codeSize == 0) {
            return;
        }
        bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, data);
         
        require(retval == 0xf0b9e5ba);
    }

     
     
     
     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        if (_from != address(0)) {
            uint256 indexFrom = cardIdToOwnerIndex[_tokenId];
            uint256[] storage cdArray = ownerToCardArray[_from];
            require(cdArray[indexFrom] == _tokenId);

             
            if (indexFrom != cdArray.length - 1) {
                uint256 lastTokenId = cdArray[cdArray.length - 1];
                cdArray[indexFrom] = lastTokenId; 
                cardIdToOwnerIndex[lastTokenId] = indexFrom;
            }
            cdArray.length -= 1; 
            
            if (cardIdToApprovals[_tokenId] != address(0)) {
                delete cardIdToApprovals[_tokenId];
            }      
        }

         
        cardIdToOwner[_tokenId] = _to;
        ownerToCardArray[_to].push(_tokenId);
        cardIdToOwnerIndex[_tokenId] = ownerToCardArray[_to].length - 1;
        
        emit Transfer(_from != address(0) ? _from : this, _to, _tokenId);
    }



     


     
     
     
     
    function createCard(address _owner, uint16[5] _attrs, uint16 _createType) external whenNotPaused returns(uint256){
        require(actionContracts[msg.sender]);
        require(_owner != address(0));
        uint256 newCardId = cardArray.length;
        require(newCardId < 4294967296);

        cardArray.length += 1;
        Card storage cd = cardArray[newCardId];
        cd.protoId = _attrs[0];
        cd.hero = _attrs[1];
        cd.quality = _attrs[2];
        cd.feature = _attrs[3];
        cd.level = _attrs[4];

        _transfer(0, _owner, newCardId);
        emit CreateCard(_owner, newCardId, _attrs[0], _attrs[1], _attrs[2], _createType);
        return newCardId;
    }

     
    function _changeAttrByIndex(Card storage _cd, uint16 _index, uint16 _val) internal {
        if (_index == 2) {
            _cd.quality = _val;
        } else if(_index == 3) {
            _cd.feature = _val;
        } else if(_index == 4) {
            _cd.level = _val;
        } else if(_index == 5) {
            _cd.attrExt1 = _val;
        } else if(_index == 6) {
            _cd.attrExt2 = _val;
        }
    }

     
     
     
     
     
    function changeCardAttr(uint256 _tokenId, uint16[5] _idxArray, uint16[5] _params, uint16 _changeType) external whenNotPaused isValidToken(_tokenId) {
        require(actionContracts[msg.sender]);

        Card storage cd = cardArray[_tokenId];
        if (_idxArray[0] > 0) _changeAttrByIndex(cd, _idxArray[0], _params[0]);
        if (_idxArray[1] > 0) _changeAttrByIndex(cd, _idxArray[1], _params[1]);
        if (_idxArray[2] > 0) _changeAttrByIndex(cd, _idxArray[2], _params[2]);
        if (_idxArray[3] > 0) _changeAttrByIndex(cd, _idxArray[3], _params[3]);
        if (_idxArray[4] > 0) _changeAttrByIndex(cd, _idxArray[4], _params[4]);
        
        emit ChangeCard(cardIdToOwner[_tokenId], _tokenId, _changeType);
    }

     
     
     
    function destroyCard(uint256 _tokenId, uint16 _deleteType) external whenNotPaused isValidToken(_tokenId) {
        require(actionContracts[msg.sender]);

        address _from = cardIdToOwner[_tokenId];
        uint256 indexFrom = cardIdToOwnerIndex[_tokenId];
        uint256[] storage cdArray = ownerToCardArray[_from]; 
        require(cdArray[indexFrom] == _tokenId);

        if (indexFrom != cdArray.length - 1) {
            uint256 lastTokenId = cdArray[cdArray.length - 1];
            cdArray[indexFrom] = lastTokenId; 
            cardIdToOwnerIndex[lastTokenId] = indexFrom;
        }
        cdArray.length -= 1; 

        cardIdToOwner[_tokenId] = address(0);
        delete cardIdToOwnerIndex[_tokenId];
        destroyCardCount += 1;

        emit Transfer(_from, 0, _tokenId);

        emit DeleteCard(_from, _tokenId, _deleteType);
    }

     
    function safeTransferByContract(uint256 _tokenId, address _to) external whenNotPaused{
        require(actionContracts[msg.sender]);

        require(_tokenId >= 1 && _tokenId <= cardArray.length);
        address owner = cardIdToOwner[_tokenId];
        require(owner != address(0));
        require(_to != address(0));
        require(owner != _to);

        _transfer(owner, _to, _tokenId);
    }

     
    function getCard(uint256 _tokenId) external view isValidToken(_tokenId) returns (uint16[7] datas) {
        Card storage cd = cardArray[_tokenId];
        datas[0] = cd.protoId;
        datas[1] = cd.hero;
        datas[2] = cd.quality;
        datas[3] = cd.feature;
        datas[4] = cd.level;
        datas[5] = cd.attrExt1;
        datas[6] = cd.attrExt2;
    }

     
    function getOwnCard(address _owner) external view returns(uint256[] tokens, uint32[] flags) {
        require(_owner != address(0));
        uint256[] storage cdArray = ownerToCardArray[_owner];
        uint256 length = cdArray.length;
        tokens = new uint256[](length);
        flags = new uint32[](length);
        for (uint256 i = 0; i < length; ++i) {
            tokens[i] = cdArray[i];
            Card storage cd = cardArray[cdArray[i]];
            flags[i] = uint32(uint32(cd.protoId) * 1000 + uint32(cd.hero) * 10 + cd.quality);
        }
    }

     
    function getCardAttrs(uint256[] _tokens) external view returns(uint16[] attrs) {
        uint256 length = _tokens.length;
        require(length <= 64);
        attrs = new uint16[](length * 11);
        uint256 tokenId;
        uint256 index;
        for (uint256 i = 0; i < length; ++i) {
            tokenId = _tokens[i];
            if (cardIdToOwner[tokenId] != address(0)) {
                index = i * 11;
                Card storage cd = cardArray[tokenId];
                attrs[index] = cd.hero;
                attrs[index + 1] = cd.quality;
                attrs[index + 2] = cd.feature;
                attrs[index + 3] = cd.level;
                attrs[index + 4] = cd.attrExt1;
                attrs[index + 5] = cd.attrExt2;
            }   
        }
    }


}