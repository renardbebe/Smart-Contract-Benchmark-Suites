 

 
 
pragma solidity ^0.4.20;

 
 
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

    function AccessAdmin() public {
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
        AdminTransferred(addrAdmin, _newAdmin);
        addrAdmin = _newAdmin;
    }

    function doPause() external onlyAdmin whenNotPaused {
        isPaused = true;
    }

    function doUnpause() external onlyAdmin whenPaused {
        isPaused = false;
    }
}

contract AccessService is AccessAdmin {
    address public addrService;
    address public addrFinance;

    modifier onlyService() {
        require(msg.sender == addrService);
        _;
    }

    modifier onlyFinance() {
        require(msg.sender == addrFinance);
        _;
    }

    function setService(address _newService) external {
        require(msg.sender == addrService || msg.sender == addrAdmin);
        require(_newService != address(0));
        addrService = _newService;
    }

    function setFinance(address _newFinance) external {
        require(msg.sender == addrFinance || msg.sender == addrAdmin);
        require(_newFinance != address(0));
        addrFinance = _newFinance;
    }
}

contract WarToken is ERC721, AccessAdmin {
     
    struct Fashion {
        uint16 protoId;      
        uint16 quality;      
        uint16 pos;          
        uint16 health;       
        uint16 atkMin;       
        uint16 atkMax;       
        uint16 defence;      
        uint16 crit;         
        uint16 isPercent;    
        uint16 attrExt1;     
        uint16 attrExt2;     
        uint16 attrExt3;     
    }

     
    Fashion[] public fashionArray;

     
    uint256 destroyFashionCount;

     
    mapping (uint256 => address) fashionIdToOwner;

     
    mapping (address => uint256[]) ownerToFashionArray;

     
    mapping (uint256 => uint256) fashionIdToOwnerIndex;

     
    mapping (uint256 => address) fashionIdToApprovals;

     
    mapping (address => mapping (address => bool)) operatorToApprovals;

     
    mapping (address => bool) actionContracts;

    function setActionContract(address _actionAddr, bool _useful) external onlyAdmin {
        actionContracts[_actionAddr] = _useful;
    }

    function getActionContract(address _actionAddr) external view onlyAdmin returns(bool) {
        return actionContracts[_actionAddr];
    }

     
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
    event Transfer(address indexed from, address indexed to, uint256 tokenId);

     
    event CreateFashion(address indexed owner, uint256 tokenId, uint16 protoId, uint16 quality, uint16 pos, uint16 createType);

     
    event ChangeFashion(address indexed owner, uint256 tokenId, uint16 changeType);

     
    event DeleteFashion(address indexed owner, uint256 tokenId, uint16 deleteType);
    
    function WarToken() public {
        addrAdmin = msg.sender;
        fashionArray.length += 1;
    }

     
     
    modifier isValidToken(uint256 _tokenId) {
        require(_tokenId >= 1 && _tokenId <= fashionArray.length);
        require(fashionIdToOwner[_tokenId] != address(0)); 
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address owner = fashionIdToOwner[_tokenId];
        require(msg.sender == owner || msg.sender == fashionIdToApprovals[_tokenId] || operatorToApprovals[owner][msg.sender]);
        _;
    }

     
    function supportsInterface(bytes4 _interfaceId) external view returns(bool) {
         
        return (_interfaceId == 0x01ffc9a7 || _interfaceId == 0x80ac58cd || _interfaceId == 0x8153916a) && (_interfaceId != 0xffffffff);
    }
        
    function name() public pure returns(string) {
        return "WAR Token";
    }

    function symbol() public pure returns(string) {
        return "WAR";
    }

     
     
     
    function balanceOf(address _owner) external view returns(uint256) {
        require(_owner != address(0));
        return ownerToFashionArray[_owner].length;
    }

     
     
     
    function ownerOf(uint256 _tokenId) external view   returns (address owner) {
        return fashionIdToOwner[_tokenId];
    }

     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) 
        external
        whenNotPaused
    {
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) 
        external
        whenNotPaused
    {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
        whenNotPaused
        isValidToken(_tokenId)
        canTransfer(_tokenId)
    {
        address owner = fashionIdToOwner[_tokenId];
        require(owner != address(0));
        require(_to != address(0));
        require(owner == _from);
        
        _transfer(_from, _to, _tokenId);
    }

     
     
     
    function approve(address _approved, uint256 _tokenId)
        external
        whenNotPaused
    {
        address owner = fashionIdToOwner[_tokenId];
        require(owner != address(0));
        require(msg.sender == owner || operatorToApprovals[owner][msg.sender]);

        fashionIdToApprovals[_tokenId] = _approved;
        Approval(owner, _approved, _tokenId);
    }

     
     
     
    function setApprovalForAll(address _operator, bool _approved) 
        external 
        whenNotPaused
    {
        operatorToApprovals[msg.sender][_operator] = _approved;
        ApprovalForAll(msg.sender, _operator, _approved);
    }

     
     
     
    function getApproved(uint256 _tokenId) external view isValidToken(_tokenId) returns (address) {
        return fashionIdToApprovals[_tokenId];
    }

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorToApprovals[_owner][_operator];
    }

     
     
     
    function totalSupply() external view returns (uint256) {
        return fashionArray.length - destroyFashionCount - 1;
    }

     
     
     
     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        if (_from != address(0)) {
            uint256 indexFrom = fashionIdToOwnerIndex[_tokenId];
            uint256[] storage fsArray = ownerToFashionArray[_from];
            require(fsArray[indexFrom] == _tokenId);

             
            if (indexFrom != fsArray.length - 1) {
                uint256 lastTokenId = fsArray[fsArray.length - 1];
                fsArray[indexFrom] = lastTokenId; 
                fashionIdToOwnerIndex[lastTokenId] = indexFrom;
            }
            fsArray.length -= 1; 
            
            if (fashionIdToApprovals[_tokenId] != address(0)) {
                delete fashionIdToApprovals[_tokenId];
            }      
        }

         
        fashionIdToOwner[_tokenId] = _to;
        ownerToFashionArray[_to].push(_tokenId);
        fashionIdToOwnerIndex[_tokenId] = ownerToFashionArray[_to].length - 1;
        
        Transfer(_from != address(0) ? _from : this, _to, _tokenId);
    }

     
    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) 
        internal
        isValidToken(_tokenId) 
        canTransfer(_tokenId)
    {
        address owner = fashionIdToOwner[_tokenId];
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

     

     
     
     
     
    function createFashion(address _owner, uint16[9] _attrs, uint16 _createType) 
        external 
        whenNotPaused
        returns(uint256)
    {
        require(actionContracts[msg.sender]);
        require(_owner != address(0));

        uint256 newFashionId = fashionArray.length;
        require(newFashionId < 4294967296);

        fashionArray.length += 1;
        Fashion storage fs = fashionArray[newFashionId];
        fs.protoId = _attrs[0];
        fs.quality = _attrs[1];
        fs.pos = _attrs[2];
        if (_attrs[3] != 0) {
            fs.health = _attrs[3];
        }
        
        if (_attrs[4] != 0) {
            fs.atkMin = _attrs[4];
            fs.atkMax = _attrs[5];
        }
       
        if (_attrs[6] != 0) {
            fs.defence = _attrs[6];
        }
        
        if (_attrs[7] != 0) {
            fs.crit = _attrs[7];
        }

        if (_attrs[8] != 0) {
            fs.isPercent = _attrs[8];
        }
        
        _transfer(0, _owner, newFashionId);
        CreateFashion(_owner, newFashionId, _attrs[0], _attrs[1], _attrs[2], _createType);
        return newFashionId;
    }

     
    function _changeAttrByIndex(Fashion storage _fs, uint16 _index, uint16 _val) internal {
        if (_index == 3) {
            _fs.health = _val;
        } else if(_index == 4) {
            _fs.atkMin = _val;
        } else if(_index == 5) {
            _fs.atkMax = _val;
        } else if(_index == 6) {
            _fs.defence = _val;
        } else if(_index == 7) {
            _fs.crit = _val;
        } else if(_index == 9) {
            _fs.attrExt1 = _val;
        } else if(_index == 10) {
            _fs.attrExt2 = _val;
        } else if(_index == 11) {
            _fs.attrExt3 = _val;
        }
    }

     
     
     
     
     
    function changeFashionAttr(uint256 _tokenId, uint16[4] _idxArray, uint16[4] _params, uint16 _changeType) 
        external 
        whenNotPaused
        isValidToken(_tokenId) 
    {
        require(actionContracts[msg.sender]);

        Fashion storage fs = fashionArray[_tokenId];
        if (_idxArray[0] > 0) {
            _changeAttrByIndex(fs, _idxArray[0], _params[0]);
        }

        if (_idxArray[1] > 0) {
            _changeAttrByIndex(fs, _idxArray[1], _params[1]);
        }

        if (_idxArray[2] > 0) {
            _changeAttrByIndex(fs, _idxArray[2], _params[2]);
        }

        if (_idxArray[3] > 0) {
            _changeAttrByIndex(fs, _idxArray[3], _params[3]);
        }

        ChangeFashion(fashionIdToOwner[_tokenId], _tokenId, _changeType);
    }

     
     
     
    function destroyFashion(uint256 _tokenId, uint16 _deleteType)
        external 
        whenNotPaused
        isValidToken(_tokenId) 
    {
        require(actionContracts[msg.sender]);

        address _from = fashionIdToOwner[_tokenId];
        uint256 indexFrom = fashionIdToOwnerIndex[_tokenId];
        uint256[] storage fsArray = ownerToFashionArray[_from]; 
        require(fsArray[indexFrom] == _tokenId);

        if (indexFrom != fsArray.length - 1) {
            uint256 lastTokenId = fsArray[fsArray.length - 1];
            fsArray[indexFrom] = lastTokenId; 
            fashionIdToOwnerIndex[lastTokenId] = indexFrom;
        }
        fsArray.length -= 1; 

        fashionIdToOwner[_tokenId] = address(0);
        delete fashionIdToOwnerIndex[_tokenId];
        destroyFashionCount += 1;

        Transfer(_from, 0, _tokenId);

        DeleteFashion(_from, _tokenId, _deleteType);
    }

     
    function safeTransferByContract(uint256 _tokenId, address _to) 
        external
        whenNotPaused
    {
        require(actionContracts[msg.sender]);

        require(_tokenId >= 1 && _tokenId <= fashionArray.length);
        address owner = fashionIdToOwner[_tokenId];
        require(owner != address(0));
        require(_to != address(0));
        require(owner != _to);

        _transfer(owner, _to, _tokenId);
    }

     

     
    function getFashion(uint256 _tokenId) external view isValidToken(_tokenId) returns (uint16[12] datas) {
        Fashion storage fs = fashionArray[_tokenId];
        datas[0] = fs.protoId;
        datas[1] = fs.quality;
        datas[2] = fs.pos;
        datas[3] = fs.health;
        datas[4] = fs.atkMin;
        datas[5] = fs.atkMax;
        datas[6] = fs.defence;
        datas[7] = fs.crit;
        datas[8] = fs.isPercent;
        datas[9] = fs.attrExt1;
        datas[10] = fs.attrExt2;
        datas[11] = fs.attrExt3;
    }

     
    function getOwnFashions(address _owner) external view returns(uint256[] tokens, uint32[] flags) {
        require(_owner != address(0));
        uint256[] storage fsArray = ownerToFashionArray[_owner];
        uint256 length = fsArray.length;
        tokens = new uint256[](length);
        flags = new uint32[](length);
        for (uint256 i = 0; i < length; ++i) {
            tokens[i] = fsArray[i];
            Fashion storage fs = fashionArray[fsArray[i]];
            flags[i] = uint32(uint32(fs.protoId) * 100 + uint32(fs.quality) * 10 + fs.pos);
        }
    }

     
    function getFashionsAttrs(uint256[] _tokens) external view returns(uint16[] attrs) {
        uint256 length = _tokens.length;
        require(length <= 64);
        attrs = new uint16[](length * 11);
        uint256 tokenId;
        uint256 index;
        for (uint256 i = 0; i < length; ++i) {
            tokenId = _tokens[i];
            if (fashionIdToOwner[tokenId] != address(0)) {
                index = i * 11;
                Fashion storage fs = fashionArray[tokenId];
                attrs[index] = fs.health;
                attrs[index + 1] = fs.atkMin;
                attrs[index + 2] = fs.atkMax;
                attrs[index + 3] = fs.defence;
                attrs[index + 4] = fs.crit;
                attrs[index + 5] = fs.isPercent;
                attrs[index + 6] = fs.attrExt1;
                attrs[index + 7] = fs.attrExt2;
                attrs[index + 8] = fs.attrExt3;
            }   
        }
    }
}

contract ActionPresell is AccessService {
    WarToken tokenContract;
    mapping (uint16 => uint16) petPresellCounter;
    mapping (address => uint16[]) presellLimit;

    event PetPreSelled(address indexed buyer, uint16 protoId);

    function ActionPresell(address _nftAddr) public {
        addrAdmin = msg.sender;
        addrService = msg.sender;
        addrFinance = msg.sender;

        tokenContract = WarToken(_nftAddr);

        petPresellCounter[10001] = 50;
        petPresellCounter[10002] = 30;
        petPresellCounter[10003] = 50;
        petPresellCounter[10004] = 30;
        petPresellCounter[10005] = 30;
    }

    function() external payable {

    }

    function setWarTokenAddr(address _nftAddr) external onlyAdmin {
        tokenContract = WarToken(_nftAddr);
    }

    function petPresell(uint16 _protoId) 
        external
        payable
        whenNotPaused 
    {
        uint16 curSupply = petPresellCounter[_protoId];
        require(curSupply > 0);
        uint16[] storage buyArray = presellLimit[msg.sender];
        uint256 curBuyCnt = buyArray.length;
        require(curBuyCnt < 10);

        uint256 payBack = 0;
        if (_protoId == 10001) {
            require(msg.value >= 0.66 ether);
            payBack = (msg.value - 0.66 ether);
            uint16[9] memory param1 = [10001, 5, 9, 40, 0, 0, 0, 0, 1];        
            tokenContract.createFashion(msg.sender, param1, 1);
            buyArray.push(10001);
        } else if(_protoId == 10002) {
            require(msg.value >= 0.99 ether);
            payBack = (msg.value - 0.99 ether);
            uint16[9] memory param2 = [10002, 5, 9, 0, 30, 30, 0, 0, 1];        
            tokenContract.createFashion(msg.sender, param2, 1);
            buyArray.push(10002);
        } else if(_protoId == 10003) {
            require(msg.value >= 0.66 ether);
            payBack = (msg.value - 0.66 ether);
            uint16[9] memory param3 = [10003, 5, 9, 0, 0, 0, 40, 0, 1];         
            tokenContract.createFashion(msg.sender, param3, 1);
            buyArray.push(10003);
        } else if(_protoId == 10004) {
            require(msg.value >= 0.99 ether);
            payBack = (msg.value - 0.99 ether);
            uint16[9] memory param4 = [10004, 5, 9, 0, 0, 0, 0, 30, 1];         
            tokenContract.createFashion(msg.sender, param4, 1);
            buyArray.push(10004);
        } else {
            require(msg.value >= 0.99 ether);
            payBack = (msg.value - 0.99 ether);
            uint16[9] memory param5 = [10005, 5, 9, 20, 10, 10, 20, 0, 1];       
            tokenContract.createFashion(msg.sender, param5, 1);
            buyArray.push(10005);
        }

        petPresellCounter[_protoId] = (curSupply - 1);

        PetPreSelled(msg.sender, _protoId);

        addrFinance.transfer(msg.value - payBack);         
        if (payBack > 0) {
            msg.sender.transfer(payBack);
        }
    }

    function withdraw() 
        external 
    {
        require(msg.sender == addrFinance || msg.sender == addrAdmin);
        addrFinance.transfer(this.balance);
    }

    function getPetCanPresellCount() external view returns (uint16[5] cntArray) {
        cntArray[0] = petPresellCounter[10001];
        cntArray[1] = petPresellCounter[10002];
        cntArray[2] = petPresellCounter[10003];
        cntArray[3] = petPresellCounter[10004];
        cntArray[4] = petPresellCounter[10005];   
    }

    function getBuyCount(address _owner) external view returns (uint32) {
        return uint32(presellLimit[_owner].length);
    }

    function getBuyArray(address _owner) external view returns (uint16[]) {
        uint16[] storage buyArray = presellLimit[_owner];
        return buyArray;
    }
}