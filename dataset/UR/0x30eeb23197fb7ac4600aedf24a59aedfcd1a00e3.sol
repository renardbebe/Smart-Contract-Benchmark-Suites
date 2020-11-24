 

 
 
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





 
 

contract RaceToken is ERC721, AccessAdmin {
     
    struct Fashion {
        uint16 equipmentId;              
        uint16 quality;     	         
        uint16 pos;         	         
        uint16 production;    	         
        uint16 attack;	                 
        uint16 defense;                  
        uint16 plunder;     	         
        uint16 productionMultiplier;     
        uint16 attackMultiplier;     	 
        uint16 defenseMultiplier;     	 
        uint16 plunderMultiplier;     	 
        uint16 level;       	         
        uint16 isPercent;   	         
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

     
    event CreateFashion(address indexed owner, uint256 tokenId, uint16 equipmentId, uint16 quality, uint16 pos, uint16 level, uint16 createType);

     
    event ChangeFashion(address indexed owner, uint256 tokenId, uint16 changeType);

     
    event DeleteFashion(address indexed owner, uint256 tokenId, uint16 deleteType);
    
    function RaceToken() public {
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
        return "Race Token";
    }

    function symbol() public pure returns(string) {
        return "Race";
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

     

     
     
     
     
    function createFashion(address _owner, uint16[13] _attrs, uint16 _createType) 
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
        fs.equipmentId = _attrs[0];
        fs.quality = _attrs[1];
        fs.pos = _attrs[2];
        if (_attrs[3] != 0) {
            fs.production = _attrs[3];
        }
        
        if (_attrs[4] != 0) {
            fs.attack = _attrs[4];
        }
		
		if (_attrs[5] != 0) {
            fs.defense = _attrs[5];
        }
       
        if (_attrs[6] != 0) {
            fs.plunder = _attrs[6];
        }
        
        if (_attrs[7] != 0) {
            fs.productionMultiplier = _attrs[7];
        }

        if (_attrs[8] != 0) {
            fs.attackMultiplier = _attrs[8];
        }

        if (_attrs[9] != 0) {
            fs.defenseMultiplier = _attrs[9];
        }

        if (_attrs[10] != 0) {
            fs.plunderMultiplier = _attrs[10];
        }

        if (_attrs[11] != 0) {
            fs.level = _attrs[11];
        }

        if (_attrs[12] != 0) {
            fs.isPercent = _attrs[12];
        }
        
        _transfer(0, _owner, newFashionId);
        CreateFashion(_owner, newFashionId, _attrs[0], _attrs[1], _attrs[2], _attrs[11], _createType);
        return newFashionId;
    }

     
    function _changeAttrByIndex(Fashion storage _fs, uint16 _index, uint16 _val) internal {
        if (_index == 3) {
            _fs.production = _val;
        } else if(_index == 4) {
            _fs.attack = _val;
        } else if(_index == 5) {
            _fs.defense = _val;
        } else if(_index == 6) {
            _fs.plunder = _val;
        }else if(_index == 7) {
            _fs.productionMultiplier = _val;
        }else if(_index == 8) {
            _fs.attackMultiplier = _val;
        }else if(_index == 9) {
            _fs.defenseMultiplier = _val;
        }else if(_index == 10) {
            _fs.plunderMultiplier = _val;
        } else if(_index == 11) {
            _fs.level = _val;
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

     

	 
    function getFashionFront(uint256 _tokenId) external view isValidToken(_tokenId) returns (uint256[14] datas) {
        Fashion storage fs = fashionArray[_tokenId];
        datas[0] = fs.equipmentId;
        datas[1] = fs.quality;
        datas[2] = fs.pos;
        datas[3] = fs.production;
        datas[4] = fs.attack;
        datas[5] = fs.defense;
        datas[6] = fs.plunder;
        datas[7] = fs.productionMultiplier;
        datas[8] = fs.attackMultiplier;
        datas[9] = fs.defenseMultiplier;
        datas[10] = fs.plunderMultiplier;
        datas[11] = fs.level;
        datas[12] = fs.isPercent; 
        datas[13] = _tokenId;      
    }

     
    function getFashion(uint256 _tokenId) external view isValidToken(_tokenId) returns (uint16[13] datas) {
        Fashion storage fs = fashionArray[_tokenId];
        datas[0] = fs.equipmentId;
        datas[1] = fs.quality;
        datas[2] = fs.pos;
        datas[3] = fs.production;
        datas[4] = fs.attack;
        datas[5] = fs.defense;
        datas[6] = fs.plunder;
        datas[7] = fs.productionMultiplier;
        datas[8] = fs.attackMultiplier;
        datas[9] = fs.defenseMultiplier;
        datas[10] = fs.plunderMultiplier;
        datas[11] = fs.level;
        datas[12] = fs.isPercent;      
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
            flags[i] = uint32(uint32(fs.equipmentId) * 10000 + uint32(fs.quality) * 100 + fs.pos);
        }
    }


     
    function getFashionsAttrs(uint256[] _tokens) external view returns(uint256[] attrs) {
        uint256 length = _tokens.length;
        attrs = new uint256[](length * 14);
        uint256 tokenId;
        uint256 index;
        for (uint256 i = 0; i < length; ++i) {
            tokenId = _tokens[i];
            if (fashionIdToOwner[tokenId] != address(0)) {
                index = i * 14;
                Fashion storage fs = fashionArray[tokenId];
                attrs[index]     = fs.equipmentId;
				attrs[index + 1] = fs.quality;
                attrs[index + 2] = fs.pos;
                attrs[index + 3] = fs.production;
                attrs[index + 4] = fs.attack;
                attrs[index + 5] = fs.defense;
                attrs[index + 6] = fs.plunder;
                attrs[index + 7] = fs.productionMultiplier;
                attrs[index + 8] = fs.attackMultiplier;
                attrs[index + 9] = fs.defenseMultiplier;
                attrs[index + 10] = fs.plunderMultiplier;
                attrs[index + 11] = fs.level;
                attrs[index + 12] = fs.isPercent; 
                attrs[index + 13] = tokenId;  
            }   
        }
    }
}


 
interface IRaceCoin {
    function addTotalEtherPool(uint256 amount) external;
    function addPlayerToList(address player) external;
    function increasePlayersAttribute(address player, uint16[13] param) external;
    function reducePlayersAttribute(address player, uint16[13] param) external;
}

contract CarsPresell is AccessService {

    using SafeMath for uint256;
    
    RaceToken tokenContract;

    IRaceCoin public raceCoinContract;

   
     
    address poolContract;

     
    uint256 constant prizeGoldPercent = 80;

     
    uint256 constant refererPercent = 5;

     
	uint16 private carCountsLimit;


   



    mapping (uint16 => uint16) carPresellCounter;
    mapping (address => uint16[]) presellLimit;

    mapping (address => uint16) freeCarCount;

    event CarPreSelled(address indexed buyer, uint16 equipmentId);
    event FreeCarsObtained(address indexed buyer, uint16 equipmentId);

    event PresellReferalGain(address referal, address player, uint256 amount);

    function CarsPresell(address _nftAddr) public {
        addrAdmin = msg.sender;
        addrService = msg.sender;
        addrFinance = msg.sender;

        tokenContract = RaceToken(_nftAddr);
		
		 
		carCountsLimit = 500;

        carPresellCounter[10001] = 100;
        carPresellCounter[10002] = 100;
        carPresellCounter[10003] = 100;
        carPresellCounter[10004] = 100;
        carPresellCounter[10005] = 100;
		carPresellCounter[10006] = 100;

    }

    function() external payable {

    }

    function setRaceTokenAddr(address _nftAddr) external onlyAdmin {
        tokenContract = RaceToken(_nftAddr);
    }

   
     
    function setRaceCoin(address _addr) external onlyAdmin {
        require(_addr != address(0));
        poolContract = _addr;
        raceCoinContract = IRaceCoin(_addr);
    }
	
	
	 
	function setCarCounts(uint16 _carId, uint16 _carCounts) external onlyAdmin {
		require( carPresellCounter[_carId] <= carCountsLimit);
		uint16 curSupply = carPresellCounter[_carId];
		require((curSupply + _carCounts)<= carCountsLimit);
        carPresellCounter[_carId] = curSupply + _carCounts;
    }


     
    function freeCar(uint16 _equipmentId)
        external
        payable
        whenNotPaused 
    {
        require(freeCarCount[msg.sender] != 1);

        uint256 payBack = 0;

        uint16[] storage buyArray = presellLimit[msg.sender];

        if(_equipmentId == 10007){
            require(msg.value >= 0.0 ether);
            payBack = (msg.value - 0.0 ether);
            uint16[13] memory param0 = [10007, 7, 9, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            tokenContract.createFashion(msg.sender, param0, 1);
            raceCoinContract.increasePlayersAttribute(msg.sender, param0);
            buyArray.push(10007);

            if (payBack > 0) {
                msg.sender.transfer(payBack);
            }

            freeCarCount[msg.sender] = 1;

            raceCoinContract.addPlayerToList(msg.sender);

            emit FreeCarsObtained(msg.sender,_equipmentId);
        }
    }

     
    function getFreeCarCount(address _owner) external view returns(uint16){

        require(_owner != address(0));
        if(freeCarCount[msg.sender] != 1){
            freeCarCount[msg.sender] = 0;
        }

        return  freeCarCount[msg.sender];
    }



    function UpdateCurrentCarCount(uint16 _equipmentId,uint16 curSupply) internal {
        carPresellCounter[_equipmentId] = (curSupply - 1);
    }


    function carPresell(address referer,uint16 _equipmentId) 
        external
        payable
        whenNotPaused 
    {
        uint16 curSupply = carPresellCounter[_equipmentId];
        require(curSupply > 0);
        uint16[] storage buyArray = presellLimit[msg.sender];
        uint256 curBuyCnt = buyArray.length;
		
        require(curBuyCnt < 21);

        uint256 payBack = 0;
        if (_equipmentId == 10001) {
            require(msg.value >= 0.075 ether);
            payBack = (msg.value - 0.075 ether);
            uint16[13] memory param1 = [10001, 1, 9, 10, 0, 0, 0, 5, 0, 0, 0, 0, 0];        
            tokenContract.createFashion(msg.sender, param1, 1);
            raceCoinContract.increasePlayersAttribute(msg.sender, param1);
            buyArray.push(10001);
            raceCoinContract.addPlayerToList(msg.sender);
        } else if(_equipmentId == 10002) {
            require(msg.value >= 0.112 ether);
            payBack = (msg.value - 0.112 ether);
            uint16[13] memory param2 = [10002, 2, 9, 15, 0, 0, 0, 8, 5, 0, 0, 0, 0];        
            tokenContract.createFashion(msg.sender, param2, 1);
            raceCoinContract.increasePlayersAttribute(msg.sender, param2);
            buyArray.push(10002);
            raceCoinContract.addPlayerToList(msg.sender);
        } else if(_equipmentId == 10003) {
            require(msg.value >= 0.225 ether);
            payBack = (msg.value - 0.225 ether);
            uint16[13] memory param3 = [10003, 3, 9, 30, 0, 0, 0, 15, 10, 5, 0, 0, 0];         
            tokenContract.createFashion(msg.sender, param3, 1);
            raceCoinContract.increasePlayersAttribute(msg.sender, param3);
            buyArray.push(10003);
            raceCoinContract.addPlayerToList(msg.sender);
        } else if(_equipmentId == 10004) {
            require(msg.value >= 0.563 ether);
            payBack = (msg.value - 0.563 ether);
            uint16[13] memory param4 = [10004, 4, 9, 75, 0, 0, 0, 38, 25, 13, 5, 0, 0];         
            tokenContract.createFashion(msg.sender, param4, 1);
            raceCoinContract.increasePlayersAttribute(msg.sender, param4);
            buyArray.push(10004);
            raceCoinContract.addPlayerToList(msg.sender);
        } else if(_equipmentId == 10005){
            require(msg.value >= 1.7 ether);
            payBack = (msg.value - 1.7 ether);
            uint16[13] memory param5 = [10005, 5, 9, 225, 0, 0, 0, 113, 75, 38, 15, 0, 0];       
            tokenContract.createFashion(msg.sender, param5, 1);
            raceCoinContract.increasePlayersAttribute(msg.sender, param5);
            buyArray.push(10005);
            raceCoinContract.addPlayerToList(msg.sender);
        }else if(_equipmentId == 10006){
            require(msg.value >= 6 ether);
            payBack = (msg.value - 6 ether);
            uint16[13] memory param6 = [10006, 6, 9, 788, 0, 0, 0, 394, 263, 131, 53, 0, 0];       
            tokenContract.createFashion(msg.sender, param6, 1);
            raceCoinContract.increasePlayersAttribute(msg.sender, param6);
            buyArray.push(10006);
            raceCoinContract.addPlayerToList(msg.sender);
        }

        UpdateCurrentCarCount(_equipmentId,curSupply);


        emit CarPreSelled(msg.sender, _equipmentId);



        uint256 ethVal = msg.value.sub(payBack);

        uint256 referalDivs;
        if (referer != address(0) && referer != msg.sender) {
            referalDivs = ethVal.mul(refererPercent).div(100);  
            referer.transfer(referalDivs);
            emit PresellReferalGain(referer, msg.sender, referalDivs);
        }


         
        if (poolContract != address(0) && ethVal.mul(prizeGoldPercent).div(100) > 0) {
            poolContract.transfer(ethVal.mul(prizeGoldPercent).div(100));
            raceCoinContract.addTotalEtherPool(ethVal.mul(prizeGoldPercent).div(100));
        }

         
        if(referalDivs > 0){
            addrFinance.transfer(ethVal.sub(ethVal.mul(prizeGoldPercent).div(100)).sub(ethVal.mul(refererPercent).div(100)));
        }else{
            addrFinance.transfer(ethVal.sub(ethVal.mul(prizeGoldPercent).div(100)));
        }
        

           
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

    function getCarCanPresellCount() external view returns (uint16[6] cntArray) {
        cntArray[0] = carPresellCounter[10001];
        cntArray[1] = carPresellCounter[10002];
        cntArray[2] = carPresellCounter[10003];
        cntArray[3] = carPresellCounter[10004];
        cntArray[4] = carPresellCounter[10005];
		cntArray[5] = carPresellCounter[10006];  		
    }

    function getBuyCount(address _owner) external view returns (uint32) {
        return uint32(presellLimit[_owner].length);
    }

    function getBuyArray(address _owner) external view returns (uint16[]) {
        uint16[] storage buyArray = presellLimit[_owner];
        return buyArray;
    }
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}