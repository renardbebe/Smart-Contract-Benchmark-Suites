 

pragma solidity ^0.4.24;

 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

     
    constructor() public {
        owner = msg.sender;
    }

      
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
      
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

      
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract TRNData is Owned {
    TripioRoomNightData dataSource;
      
    modifier onlyVendor {
        uint256 vendorId = dataSource.vendorIds(msg.sender);
        require(vendorId > 0);
        (,,,bool valid) = dataSource.getVendor(vendorId);
        require(valid);
        _;
    }

     
    modifier vendorValid(address _vendor) {
        uint256 vendorId = dataSource.vendorIds(_vendor);
        require(vendorId > 0);
        (,,,bool valid) = dataSource.getVendor(vendorId);
        require(valid);
        _;
    }

     
    modifier vendorIdValid(uint256 _vendorId) {
        (,,,bool valid) = dataSource.getVendor(_vendorId);
        require(valid);
        _;
    }

     
    modifier ratePlanExist(uint256 _vendorId, uint256 _rpid) {
        (,,,bool valid) = dataSource.getVendor(_vendorId);
        require(valid);
        require(dataSource.ratePlanIsExist(_vendorId, _rpid));
        _;
    }
    
     
    modifier validToken(uint256 _tokenId) {
        require(_tokenId > 0);
        require(dataSource.roomNightIndexToOwner(_tokenId) != address(0));
        _;
    }

     
    modifier validTokenInBatch(uint256[] _tokenIds) {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] > 0);
            require(dataSource.roomNightIndexToOwner(_tokenIds[i]) != address(0));
        }
        _;
    }

     
    modifier canTransfer(uint256 _tokenId) {
        address owner = dataSource.roomNightIndexToOwner(_tokenId);
        bool isOwner = (msg.sender == owner);
        bool isApproval = (msg.sender == dataSource.roomNightApprovals(_tokenId));
        bool isOperator = (dataSource.operatorApprovals(owner, msg.sender));
        require(isOwner || isApproval || isOperator);
        _;
    }

     
    modifier canTransferInBatch(uint256[] _tokenIds) {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            address owner = dataSource.roomNightIndexToOwner(_tokenIds[i]);
            bool isOwner = (msg.sender == owner);
            bool isApproval = (msg.sender == dataSource.roomNightApprovals(_tokenIds[i]));
            bool isOperator = (dataSource.operatorApprovals(owner, msg.sender));
            require(isOwner || isApproval || isOperator);
        }
        _;
    }


     
    modifier canOperate(uint256 _tokenId) {
        address owner = dataSource.roomNightIndexToOwner(_tokenId);
        bool isOwner = (msg.sender == owner);
        bool isOperator = (dataSource.operatorApprovals(owner, msg.sender));
        require(isOwner || isOperator);
        _;
    }

     
    modifier validDate(uint256 _date) {
        require(_date > 0);
        require(dateIsLegal(_date));
        _;
    }

     
    modifier validDates(uint256[] _dates) {
        for(uint256 i = 0;i < _dates.length; i++) {
            require(_dates[i] > 0);
            require(dateIsLegal(_dates[i]));
        }
        _;
    }

    function dateIsLegal(uint256 _date) pure private returns(bool) {
        uint256 year = _date / 10000;
        uint256 mon = _date / 100 - year * 100;
        uint256 day = _date - mon * 100 - year * 10000;
        
        if(year < 1970 || mon <= 0 || mon > 12 || day <= 0 || day > 31)
            return false;

        if(4 == mon || 6 == mon || 9 == mon || 11 == mon){
            if (day == 31) {
                return false;
            }
        }
        if(((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0)) {
            if(2 == mon && day > 29) {
                return false;
            }
        }else {
            if(2 == mon && day > 28){
                return false;
            }
        }
        return true;
    }
     
    constructor() public {

    }
}


contract TRNPrices is TRNData {

     
    constructor() public {

    }

     
    event RatePlanPriceChanged(uint256 indexed _rpid);

     
    event RatePlanInventoryChanged(uint256 indexed _rpid);

     
    event RatePlanBasePriceChanged(uint256 indexed _rpid);
    
    function _updatePrices(uint256 _rpid, uint256 _date, uint16 _inventory, uint256[] _tokens, uint256[] _prices) private {
        uint256 vendorId = dataSource.vendorIds(msg.sender);
        dataSource.updateInventories(vendorId, _rpid, _date, _inventory);
        for (uint256 tindex = 0; tindex < _tokens.length; tindex++) {
            dataSource.updatePrice(vendorId, _rpid, _date, _tokens[tindex], _prices[tindex]);
        }
    }

    function _updateInventories(uint256 _rpid, uint256 _date, uint16 _inventory) private {
        uint256 vendorId = dataSource.vendorIds(msg.sender);
        dataSource.updateInventories(vendorId, _rpid, _date, _inventory);
    }

     
    function updateBasePrice(uint256 _rpid, uint256[] _tokens, uint256[] _prices, uint16 _inventory) 
        external 
        ratePlanExist(dataSource.vendorIds(msg.sender), _rpid) 
        returns(bool) {
        require(_tokens.length == _prices.length);
        require(_prices.length > 0);
        uint256 vendorId = dataSource.vendorIds(msg.sender);
        dataSource.updateBaseInventory(vendorId, _rpid, _inventory);
        for (uint256 tindex = 0; tindex < _tokens.length; tindex++) {
            dataSource.updateBasePrice(vendorId, _rpid, _tokens[tindex], _prices[tindex]);
        }
         
        emit RatePlanBasePriceChanged(_rpid);
        return true;
    }

     
    function updatePrices(uint256 _rpid, uint256[] _dates, uint16 _inventory, uint256[] _tokens, uint256[] _prices)
        external 
        ratePlanExist(dataSource.vendorIds(msg.sender), _rpid) 
        returns(bool) {
        require(_dates.length > 0);
        require(_tokens.length == _prices.length);
        require(_prices.length > 0);
        for (uint256 index = 0; index < _dates.length; index++) {
            _updatePrices(_rpid, _dates[index], _inventory, _tokens, _prices);
        }
         
        emit RatePlanPriceChanged(_rpid);
        return true;
    }

     
    function updateInventories(uint256 _rpid, uint256[] _dates, uint16 _inventory) 
        external 
        ratePlanExist(dataSource.vendorIds(msg.sender), _rpid) 
        returns(bool) {
        for (uint256 index = 0; index < _dates.length; index++) {
            _updateInventories(_rpid, _dates[index], _inventory);
        }

         
        emit RatePlanInventoryChanged(_rpid);
        return true;
    }

     
    function inventoriesOfDate(uint256 _vendorId, uint256 _rpid, uint256[] _dates) 
        external 
        view
        ratePlanExist(_vendorId, _rpid) 
        returns(uint16[]) {
        require(_dates.length > 0);
        uint16[] memory result = new uint16[](_dates.length);
        for (uint256 index = 0; index < _dates.length; index++) {
            uint256 date = _dates[index];
            (uint16 inventory,) = dataSource.getInventory(_vendorId, _rpid, date);
            result[index] = inventory;
        }
        return result;
    }

     
    function pricesOfDate(uint256 _vendorId, uint256 _rpid, uint256[] _dates, uint256 _token)
        external 
        view
        ratePlanExist(_vendorId, _rpid) 
        returns(uint256[]) {
        require(_dates.length > 0);
        uint256[] memory result = new uint256[](_dates.length);
        for (uint256 index = 0; index < _dates.length; index++) {
            (,, uint256 _price) = dataSource.getPrice(_vendorId, _rpid, _dates[index], _token);
            result[index] = _price;
        }
        return result;
    }

     
    function pricesAndInventoriesOfDate(uint256 _vendorId, uint256 _rpid, uint256[] _dates, uint256 _token)
        external 
        view
        returns(uint256[], uint16[]) {
        uint256[] memory prices = new uint256[](_dates.length);
        uint16[] memory inventories = new uint16[](_dates.length);
        for (uint256 index = 0; index < _dates.length; index++) {
            (uint16 _inventory,, uint256 _price) = dataSource.getPrice(_vendorId, _rpid, _dates[index], _token);
            prices[index] = _price;
            inventories[index] = _inventory;
        }
        return (prices, inventories);
    }

     
    function priceOfDate(uint256 _vendorId, uint256 _rpid, uint256 _date, uint256 _token) 
        external 
        view
        ratePlanExist(_vendorId, _rpid) 
        returns(uint16 _inventory, uint256 _price) {
        (_inventory, , _price) = dataSource.getPrice(_vendorId, _rpid, _date, _token);
    }
}

 
library LinkedListLib {

    uint256 constant NULL = 0;
    uint256 constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;

    struct LinkedList {
        mapping (uint256 => mapping (bool => uint256)) list;
        uint256 length;
        uint256 index;
    }

     
    function listExists(LinkedList storage self)
        internal
        view returns (bool) {
        return self.length > 0;
    }

     
    function nodeExists(LinkedList storage self, uint256 _node)
        internal
        view returns (bool) {
        if (self.list[_node][PREV] == HEAD && self.list[_node][NEXT] == HEAD) {
            if (self.list[HEAD][NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

      
    function sizeOf(LinkedList storage self) 
        internal 
        view 
        returns (uint256 numElements) {
        return self.length;
    }

     
    function getNode(LinkedList storage self, uint256 _node)
        public 
        view 
        returns (bool, uint256, uint256) {
        if (!nodeExists(self,_node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

     
    function getAdjacent(LinkedList storage self, uint256 _node, bool _direction)
        public 
        view 
        returns (bool, uint256) {
        if (!nodeExists(self,_node)) {
            return (false,0);
        } else {
            return (true,self.list[_node][_direction]);
        }
    }

     
    function getSortedSpot(LinkedList storage self, uint256 _node, uint256 _value, bool _direction)
        public 
        view 
        returns (uint256) {
        if (sizeOf(self) == 0) { 
            return 0; 
        }
        require((_node == 0) || nodeExists(self,_node));
        bool exists;
        uint256 next;
        (exists,next) = getAdjacent(self, _node, _direction);
        while  ((next != 0) && (_value != next) && ((_value < next) != _direction)) next = self.list[next][_direction];
        return next;
    }

     
    function createLink(LinkedList storage self, uint256 _node, uint256 _link, bool _direction) 
        private {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }

     
    function insert(LinkedList storage self, uint256 _node, uint256 _new, bool _direction) 
        internal 
        returns (bool) {
        if(!nodeExists(self,_new) && nodeExists(self,_node)) {
            uint256 c = self.list[_node][_direction];
            createLink(self, _node, _new, _direction);
            createLink(self, _new, c, _direction);
            self.length++;
            return true;
        } else {
            return false;
        }
    }

     
    function remove(LinkedList storage self, uint256 _node) 
        internal 
        returns (uint256) {
        if ((_node == NULL) || (!nodeExists(self,_node))) { 
            return 0; 
        }
        createLink(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];
        self.length--;
        return _node;
    }

     
    function add(LinkedList storage self, uint256 _index, bool _direction) 
        internal 
        returns (uint256) {
        insert(self, HEAD, _index, _direction);
        return self.index;
    }

     
    function push(LinkedList storage self, bool _direction) 
        internal 
        returns (uint256) {
        self.index++;
        insert(self, HEAD, self.index, _direction);
        return self.index;
    }

     
    function pop(LinkedList storage self, bool _direction) 
        internal 
        returns (uint256) {
        bool exists;
        uint256 adj;
        (exists,adj) = getAdjacent(self, HEAD, _direction);
        return remove(self, adj);
    }
}


contract TripioToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    function transfer(address _to, uint256 _value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
}

contract TripioRoomNightData is Owned {
    using LinkedListLib for LinkedListLib.LinkedList;
     
     
    bytes4 constant public interfaceSignature_ERC165 = 0x01ffc9a7;

     
     
    bytes4 constant public interfaceSignature_ERC721Metadata = 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd;
        
     
     
     
     
     
     
     
     
     
     
    bytes4 constant public interfaceSignature_ERC721 = 0x70a08231 ^ 0x6352211e ^ 0xb88d4fde ^ 0x42842e0e ^ 0x23b872dd ^ 0x095ea7b3 ^ 0xa22cb465 ^ 0x081812fc ^ 0xe985e9c5;

     
    string public tokenBaseURI;

     
    struct AuthorizedContract {
        string name;
        address acontract;
    }
    mapping (address=>uint256) public authorizedContractIds;
    mapping (uint256 => AuthorizedContract) public authorizedContracts;
    LinkedListLib.LinkedList public authorizedContractList = LinkedListLib.LinkedList(0, 0);

     
    struct Price {
        uint16 inventory;        
        bool init;               
        mapping (uint256 => uint256) tokens;
    }

     
    struct RatePlan {
        string name;             
        uint256 timestamp;       
        bytes32 ipfs;            
        Price basePrice;         
        mapping (uint256 => Price) prices;    
    }

     
    struct Vendor {
        string name;             
        address vendor;          
        uint256 timestamp;       
        bool valid;              
        LinkedListLib.LinkedList ratePlanList;
        mapping (uint256=>RatePlan) ratePlans;
    }
    mapping (address => uint256) public vendorIds;
    mapping (uint256 => Vendor) vendors;
    LinkedListLib.LinkedList public vendorList = LinkedListLib.LinkedList(0, 0);

     
    mapping (uint256 => address) public tokenIndexToAddress;
    LinkedListLib.LinkedList public tokenList = LinkedListLib.LinkedList(0, 0);

     
    struct RoomNight {
        uint256 vendorId;
        uint256 rpid;
        uint256 token;           
        uint256 price;           
        uint256 timestamp;       
        uint256 date;            
        bytes32 ipfs;            
    }
    RoomNight[] public roomnights;
     
    mapping (uint256 => address) public roomNightIndexToOwner;

     
    mapping (address => LinkedListLib.LinkedList) public roomNightOwners;

     
    mapping (address => LinkedListLib.LinkedList) public roomNightVendors;

     
    mapping (uint256 => address) public roomNightApprovals;

     
    mapping (address => mapping (address => bool)) public operatorApprovals;

     
    mapping (address => mapping (uint256 => bool)) public refundApplications;

     
     
    bytes4 constant public ERC721_RECEIVED = 0xf0b9e5ba;

     
    event ContractAuthorized(address _contract);

     
    event ContractDeauthorized(address _contract);

     
    modifier authorizedContractValid(address _contract) {
        require(authorizedContractIds[_contract] > 0);
        _;
    }

     
    modifier authorizedContractIdValid(uint256 _cid) {
        require(authorizedContractList.nodeExists(_cid));
        _;
    }

     
    modifier onlyOwnerOrAuthorizedContract {
        require(msg.sender == owner || authorizedContractIds[msg.sender] > 0);
        _;
    }

     
    constructor() public {
         
        roomnights.push(RoomNight(0, 0, 0, 0, 0, 0, 0));
    }

     
    function getNodes(LinkedListLib.LinkedList storage self, uint256 _node, uint256 _limit, bool _direction) 
        private
        view 
        returns (uint256[], uint256) {
        bool exists;
        uint256 i = 0;
        uint256 ei = 0;
        uint256 index = 0;
        uint256 count = _limit;
        if(count > self.length) {
            count = self.length;
        }
        (exists, i) = self.getAdjacent(_node, _direction);
        if(!exists || count == 0) {
            return (new uint256[](0), 0);
        }else {
            uint256[] memory temp = new uint256[](count);
            if(_node != 0) {
                index++;
                temp[0] = _node;
            }
            while (i != 0 && index < count) {
                temp[index] = i;
                (exists,i) = self.getAdjacent(i, _direction);
                index++;
            }
            ei = i;
            if(index < count) {
                uint256[] memory result = new uint256[](index);
                for(i = 0; i < index; i++) {
                    result[i] = temp[i];
                }
                return (result, ei);
            }else {
                return (temp, ei);
            }
        }
    }

     
    function authorizeContract(address _contract, string _name) 
        public 
        onlyOwner 
        returns(bool) {
        uint256 codeSize;
        assembly { codeSize := extcodesize(_contract) }
        require(codeSize != 0);
         
        require(authorizedContractIds[_contract] == 0);

         
        uint256 id = authorizedContractList.push(false);
        authorizedContractIds[_contract] = id;
        authorizedContracts[id] = AuthorizedContract(_name, _contract);

         
        emit ContractAuthorized(_contract);
        return true;
    }

     
    function deauthorizeContract(address _contract) 
        public 
        onlyOwner
        authorizedContractValid(_contract)
        returns(bool) {
        uint256 id = authorizedContractIds[_contract];
        authorizedContractList.remove(id);
        authorizedContractIds[_contract] = 0;
        delete authorizedContracts[id];
        
         
        emit ContractDeauthorized(_contract);
        return true;
    }

     
    function deauthorizeContractById(uint256 _cid) 
        public
        onlyOwner
        authorizedContractIdValid(_cid)
        returns(bool) {
        address acontract = authorizedContracts[_cid].acontract;
        authorizedContractList.remove(_cid);
        authorizedContractIds[acontract] = 0;
        delete authorizedContracts[_cid];

         
        emit ContractDeauthorized(acontract);
        return true;
    }

     
    function getAuthorizeContractIds(uint256 _from, uint256 _limit) 
        external 
        view 
        returns(uint256[], uint256){
        return getNodes(authorizedContractList, _from, _limit, true);
    }

     
    function getAuthorizeContract(uint256 _cid) 
        external 
        view 
        returns(string _name, address _acontract) {
        AuthorizedContract memory acontract = authorizedContracts[_cid]; 
        _name = acontract.name;
        _acontract = acontract.acontract;
    }

     

     
    function getRatePlan(uint256 _vendorId, uint256 _rpid) 
        public 
        view 
        returns (string _name, uint256 _timestamp, bytes32 _ipfs) {
        _name = vendors[_vendorId].ratePlans[_rpid].name;
        _timestamp = vendors[_vendorId].ratePlans[_rpid].timestamp;
        _ipfs = vendors[_vendorId].ratePlans[_rpid].ipfs;
    }

     
    function getPrice(uint256 _vendorId, uint256 _rpid, uint256 _date, uint256 _tokenId) 
        public
        view 
        returns(uint16 _inventory, bool _init, uint256 _price) {
        _inventory = vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory;
        _init = vendors[_vendorId].ratePlans[_rpid].prices[_date].init;
        _price = vendors[_vendorId].ratePlans[_rpid].prices[_date].tokens[_tokenId];
        if(!_init) {
             
            _inventory = vendors[_vendorId].ratePlans[_rpid].basePrice.inventory;
            _price = vendors[_vendorId].ratePlans[_rpid].basePrice.tokens[_tokenId];
            _init = vendors[_vendorId].ratePlans[_rpid].basePrice.init;
        }
    }

     
    function getPrices(uint256 _vendorId, uint256 _rpid, uint256[] _dates, uint256 _tokenId) 
        public
        view 
        returns(uint16[] _inventories, uint256[] _prices) {
        uint16[] memory inventories = new uint16[](_dates.length);
        uint256[] memory prices = new uint256[](_dates.length);
        uint256 date;
        for(uint256 i = 0; i < _dates.length; i++) {
            date = _dates[i];
            uint16 inventory = vendors[_vendorId].ratePlans[_rpid].prices[date].inventory;
            bool init = vendors[_vendorId].ratePlans[_rpid].prices[date].init;
            uint256 price = vendors[_vendorId].ratePlans[_rpid].prices[date].tokens[_tokenId];
            if(!init) {
                 
                inventory = vendors[_vendorId].ratePlans[_rpid].basePrice.inventory;
                price = vendors[_vendorId].ratePlans[_rpid].basePrice.tokens[_tokenId];
                init = vendors[_vendorId].ratePlans[_rpid].basePrice.init;
            }
            inventories[i] = inventory;
            prices[i] = price;
        }
        return (inventories, prices);
    }

     
    function getInventory(uint256 _vendorId, uint256 _rpid, uint256 _date) 
        public
        view 
        returns(uint16 _inventory, bool _init) {
        _inventory = vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory;
        _init = vendors[_vendorId].ratePlans[_rpid].prices[_date].init;
        if(!_init) {
             
            _inventory = vendors[_vendorId].ratePlans[_rpid].basePrice.inventory;
        }
    }

     
    function ratePlanIsExist(uint256 _vendorId, uint256 _rpid) 
        public 
        view 
        returns (bool) {
        return vendors[_vendorId].ratePlanList.nodeExists(_rpid);
    }

     
    function getOrdersOfOwner(address _owner, uint256 _from, uint256 _limit, bool _direction) 
        public 
        view 
        returns (uint256[], uint256) {
        return getNodes(roomNightOwners[_owner], _from, _limit, _direction);
    }

     
    function getOrdersOfVendor(address _owner, uint256 _from, uint256 _limit, bool _direction) 
        public 
        view 
        returns (uint256[], uint256) {
        return getNodes(roomNightVendors[_owner], _from, _limit, _direction);
    }

     
    function balanceOf(address _owner) 
        public 
        view 
        returns(uint256) {
        return roomNightOwners[_owner].length;
    }

     
    function getRatePlansOfVendor(uint256 _vendorId, uint256 _from, uint256 _limit, bool _direction) 
        public 
        view 
        returns(uint256[], uint256) {
        return getNodes(vendors[_vendorId].ratePlanList, _from, _limit, _direction);
    }

     
    function getTokens(uint256 _from, uint256 _limit, bool _direction) 
        public 
        view 
        returns(uint256[], uint256) {
        return getNodes(tokenList, _from, _limit, _direction);
    }

     
    function getToken(uint256 _tokenId)
        public 
        view 
        returns(string _symbol, string _name, uint8 _decimals, address _token) {
        _token = tokenIndexToAddress[_tokenId];
        TripioToken tripio = TripioToken(_token);
        _symbol = tripio.symbol();
        _name = tripio.name();
        _decimals = tripio.decimals();
    }

     
    function getVendors(uint256 _from, uint256 _limit, bool _direction) 
        public 
        view 
        returns(uint256[], uint256) {
        return getNodes(vendorList, _from, _limit, _direction);
    }

     
    function getVendor(uint256 _vendorId) 
        public 
        view 
        returns(string _name, address _vendor,uint256 _timestamp, bool _valid) {
        _name = vendors[_vendorId].name;
        _vendor = vendors[_vendorId].vendor;
        _timestamp = vendors[_vendorId].timestamp;
        _valid = vendors[_vendorId].valid;
    }

     
     
    function updateTokenBaseURI(string _tokenBaseURI) 
        public 
        onlyOwnerOrAuthorizedContract {
        tokenBaseURI = _tokenBaseURI;
    }

     
    function pushOrderOfOwner(address _owner, uint256 _rnid, bool _direction) 
        public 
        onlyOwnerOrAuthorizedContract {
        if(!roomNightOwners[_owner].listExists()) {
            roomNightOwners[_owner] = LinkedListLib.LinkedList(0, 0);
        }
        roomNightOwners[_owner].add(_rnid, _direction);
    }

     
    function removeOrderOfOwner(address _owner, uint _rnid) 
        public 
        onlyOwnerOrAuthorizedContract {
        require(roomNightOwners[_owner].nodeExists(_rnid));
        roomNightOwners[_owner].remove(_rnid);
    }

     
    function pushOrderOfVendor(address _vendor, uint256 _rnid, bool _direction) 
        public 
        onlyOwnerOrAuthorizedContract {
        if(!roomNightVendors[_vendor].listExists()) {
            roomNightVendors[_vendor] = LinkedListLib.LinkedList(0, 0);
        }
        roomNightVendors[_vendor].add(_rnid, _direction);
    }

     
    function removeOrderOfVendor(address _vendor, uint256 _rnid) 
        public 
        onlyOwnerOrAuthorizedContract {
        require(roomNightVendors[_vendor].nodeExists(_rnid));
        roomNightVendors[_vendor].remove(_rnid);
    }

     
    function transferTokenTo(uint256 _tokenId, address _to) 
        public 
        onlyOwnerOrAuthorizedContract {
        roomNightIndexToOwner[_tokenId] = _to;
        roomNightApprovals[_tokenId] = address(0);
    }

     
    function approveTokenTo(uint256 _tokenId, address _to) 
        public 
        onlyOwnerOrAuthorizedContract {
        roomNightApprovals[_tokenId] = _to;
    }

     
    function approveOperatorTo(address _operator, address _to, bool _approved) 
        public 
        onlyOwnerOrAuthorizedContract {
        operatorApprovals[_to][_operator] = _approved;
    } 

     
    function updateBasePrice(uint256 _vendorId, uint256 _rpid, uint256 _tokenId, uint256 _price)
        public 
        onlyOwnerOrAuthorizedContract {
        vendors[_vendorId].ratePlans[_rpid].basePrice.init = true;
        vendors[_vendorId].ratePlans[_rpid].basePrice.tokens[_tokenId] = _price;
    }

     
    function updateBaseInventory(uint256 _vendorId, uint256 _rpid, uint16 _inventory)
        public 
        onlyOwnerOrAuthorizedContract {
        vendors[_vendorId].ratePlans[_rpid].basePrice.inventory = _inventory;
    }

     
    function updatePrice(uint256 _vendorId, uint256 _rpid, uint256 _date, uint256 _tokenId, uint256 _price)
        public
        onlyOwnerOrAuthorizedContract {
        if (vendors[_vendorId].ratePlans[_rpid].prices[_date].init) {
            vendors[_vendorId].ratePlans[_rpid].prices[_date].tokens[_tokenId] = _price;
        } else {
            vendors[_vendorId].ratePlans[_rpid].prices[_date] = Price(0, true);
            vendors[_vendorId].ratePlans[_rpid].prices[_date].tokens[_tokenId] = _price;
        }
    }

     
    function updateInventories(uint256 _vendorId, uint256 _rpid, uint256 _date, uint16 _inventory)
        public 
        onlyOwnerOrAuthorizedContract {
        if (vendors[_vendorId].ratePlans[_rpid].prices[_date].init) {
            vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory = _inventory;
        } else {
            vendors[_vendorId].ratePlans[_rpid].prices[_date] = Price(_inventory, true);
        }
    }

     
    function reduceInventories(uint256 _vendorId, uint256 _rpid, uint256 _date, uint16 _inventory) 
        public  
        onlyOwnerOrAuthorizedContract {
        uint16 a = 0;
        if(vendors[_vendorId].ratePlans[_rpid].prices[_date].init) {
            a = vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory;
            require(_inventory <= a);
            vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory = a - _inventory;
        }else if(vendors[_vendorId].ratePlans[_rpid].basePrice.init){
            a = vendors[_vendorId].ratePlans[_rpid].basePrice.inventory;
            require(_inventory <= a);
            vendors[_vendorId].ratePlans[_rpid].basePrice.inventory = a - _inventory;
        }
    }

     
    function addInventories(uint256 _vendorId, uint256 _rpid, uint256 _date, uint16 _inventory) 
        public  
        onlyOwnerOrAuthorizedContract {
        uint16 c = 0;
        if(vendors[_vendorId].ratePlans[_rpid].prices[_date].init) {
            c = _inventory + vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory;
            require(c >= _inventory);
            vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory = c;
        }else if(vendors[_vendorId].ratePlans[_rpid].basePrice.init) {
            c = _inventory + vendors[_vendorId].ratePlans[_rpid].basePrice.inventory;
            require(c >= _inventory);
            vendors[_vendorId].ratePlans[_rpid].basePrice.inventory = c;
        }
    }

     
    function updatePriceAndInventories(uint256 _vendorId, uint256 _rpid, uint256 _date, uint256 _tokenId, uint256 _price, uint16 _inventory)
        public 
        onlyOwnerOrAuthorizedContract {
        if (vendors[_vendorId].ratePlans[_rpid].prices[_date].init) {
            vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory = _inventory;
            vendors[_vendorId].ratePlans[_rpid].prices[_date].tokens[_tokenId] = _price;
        } else {
            vendors[_vendorId].ratePlans[_rpid].prices[_date] = Price(_inventory, true);
            vendors[_vendorId].ratePlans[_rpid].prices[_date].tokens[_tokenId] = _price;
        }
    }

     
    function pushRatePlan(uint256 _vendorId, string _name, bytes32 _ipfs, bool _direction) 
        public 
        onlyOwnerOrAuthorizedContract
        returns(uint256) {
        RatePlan memory rp = RatePlan(_name, uint256(now), _ipfs, Price(0, false));
        
        uint256 id = vendors[_vendorId].ratePlanList.push(_direction);
        vendors[_vendorId].ratePlans[id] = rp;
        return id;
    }

     
    function removeRatePlan(uint256 _vendorId, uint256 _rpid) 
        public 
        onlyOwnerOrAuthorizedContract {
        delete vendors[_vendorId].ratePlans[_rpid];
        vendors[_vendorId].ratePlanList.remove(_rpid);
    }

     
    function updateRatePlan(uint256 _vendorId, uint256 _rpid, string _name, bytes32 _ipfs)
        public 
        onlyOwnerOrAuthorizedContract {
        vendors[_vendorId].ratePlans[_rpid].ipfs = _ipfs;
        vendors[_vendorId].ratePlans[_rpid].name = _name;
    }
    
     
    function pushToken(address _contract, bool _direction)
        public 
        onlyOwnerOrAuthorizedContract 
        returns(uint256) {
        uint256 id = tokenList.push(_direction);
        tokenIndexToAddress[id] = _contract;
        return id;
    }

     
    function removeToken(uint256 _tokenId) 
        public 
        onlyOwnerOrAuthorizedContract {
        delete tokenIndexToAddress[_tokenId];
        tokenList.remove(_tokenId);
    }

     
    function generateRoomNightToken(uint256 _vendorId, uint256 _rpid, uint256 _date, uint256 _token, uint256 _price, bytes32 _ipfs)
        public 
        onlyOwnerOrAuthorizedContract 
        returns(uint256) {
        roomnights.push(RoomNight(_vendorId, _rpid, _token, _price, now, _date, _ipfs));

         
        uint256 rnid = uint256(roomnights.length - 1);
        return rnid;
    }

     
    function updateRefundApplications(address _buyer, uint256 _rnid, bool _isRefund) 
        public 
        onlyOwnerOrAuthorizedContract {
        refundApplications[_buyer][_rnid] = _isRefund;
    }

     
    function pushVendor(string _name, address _vendor, bool _direction)
        public 
        onlyOwnerOrAuthorizedContract 
        returns(uint256) {
        uint256 id = vendorList.push(_direction);
        vendorIds[_vendor] = id;
        vendors[id] = Vendor(_name, _vendor, uint256(now), true, LinkedListLib.LinkedList(0, 0));
        return id;
    }

     
    function removeVendor(uint256 _vendorId) 
        public 
        onlyOwnerOrAuthorizedContract {
        vendorList.remove(_vendorId);
        address vendor = vendors[_vendorId].vendor;
        vendorIds[vendor] = 0;
        delete vendors[_vendorId];
    }

     
    function updateVendorValid(uint256 _vendorId, bool _valid)
        public 
        onlyOwnerOrAuthorizedContract {
        vendors[_vendorId].valid = _valid;
    }

     
    function updateVendorName(uint256 _vendorId, string _name)
        public 
        onlyOwnerOrAuthorizedContract {
        vendors[_vendorId].name = _name;
    }
}


contract TRNRatePlans is TRNData {
     
    constructor() public {

    }

     
    event RatePlanCreated(address indexed _vendor, string _name, bytes32 indexed _ipfs);

     
    event RatePlanRemoved(address indexed _vendor, uint256 indexed _rpid);

     
    event RatePlanModified(address indexed _vendor, uint256 indexed _rpid, string name, bytes32 _ipfs);

     
    function createRatePlan(string _name, bytes32 _ipfs) 
        external 
         
        returns(uint256) {
         
        if(dataSource.vendorIds(msg.sender) == 0) {
            dataSource.pushVendor("", msg.sender, false);
        }
        bytes memory nameBytes = bytes(_name);
        require(nameBytes.length > 0 && nameBytes.length < 200);
    
        uint256 vendorId = dataSource.vendorIds(msg.sender);
        uint256 id = dataSource.pushRatePlan(vendorId, _name, _ipfs, false);
        
         
        emit RatePlanCreated(msg.sender, _name, _ipfs);

        return id;
    }
    
     
    function removeRatePlan(uint256 _rpid) 
        external 
        onlyVendor 
        ratePlanExist(dataSource.vendorIds(msg.sender), _rpid) 
        returns(bool) {
        uint256 vendorId = dataSource.vendorIds(msg.sender);

         
        dataSource.removeRatePlan(vendorId, _rpid);
        
         
        emit RatePlanRemoved(msg.sender, _rpid);
        return true;
    }

     
    function modifyRatePlan(uint256 _rpid, string _name, bytes32 _ipfs) 
        external 
        onlyVendor 
        ratePlanExist(dataSource.vendorIds(msg.sender), _rpid) 
        returns(bool) {

        uint256 vendorId = dataSource.vendorIds(msg.sender);
        dataSource.updateRatePlan(vendorId, _rpid, _name, _ipfs);

         
        emit RatePlanModified(msg.sender, _rpid, _name, _ipfs);
        return true;
    }

     
    function ratePlansOfVendor(uint256 _vendorId, uint256 _from, uint256 _limit) 
        external
        view
        vendorIdValid(_vendorId)  
        returns(uint256[], uint256) {
        return dataSource.getRatePlansOfVendor(_vendorId, _from, _limit, true);
    }

     
    function ratePlanOfVendor(uint256 _vendorId, uint256 _rpid) 
        external 
        view 
        vendorIdValid(_vendorId) 
        returns(string _name, uint256 _timestamp, bytes32 _ipfs) {
        (_name, _timestamp, _ipfs) = dataSource.getRatePlan(_vendorId, _rpid);
    }
}

contract TripioRoomNightVendor is TRNPrices, TRNRatePlans {
     
    constructor(address _dataSource) public {
         
        dataSource = TripioRoomNightData(_dataSource);
    }
    
     
    function destroy() external onlyOwner {
        selfdestruct(owner);
    }
}