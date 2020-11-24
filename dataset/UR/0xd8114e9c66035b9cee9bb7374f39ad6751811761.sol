 

pragma solidity ^0.4.24;

interface ERC165 {
     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

 
 
 
interface ERC721Metadata   {
     
    function name() external pure returns (string _name);

     
    function symbol() external pure returns (string _symbol);

     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string);
}


 
 
 
interface ERC721   {
     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256);

     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address);

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external payable;

     
     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external;

     
     
     
     
    function getApproved(uint256 _tokenId) external view returns (address);

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 
contract ERC721Receiver {
     
    function onERC721Received(address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

 
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

contract TRNOwners is TRNData {
     
    constructor() public {

    }

     
    function _pushRoomNight(address _owner, uint256 _rnid, bool _isVendor) internal {
        require(_owner != address(0));
        require(_rnid != 0);
        if (_isVendor) {
            dataSource.pushOrderOfVendor(_owner, _rnid, false);
        } else {
            dataSource.pushOrderOfOwner(_owner, _rnid, false);
        }
    }

     
    function _removeRoomNight(address _owner, uint256 _rnid) internal {
        dataSource.removeOrderOfOwner(_owner, _rnid);
    }

     
    function roomNightsOfOwner(uint256 _from, uint256 _limit, bool _isVendor) 
        external
        view 
        returns(uint256[], uint256) {
        if(_isVendor) {
            return dataSource.getOrdersOfVendor(msg.sender, _from, _limit, true);
        }else {
            return dataSource.getOrdersOfOwner(msg.sender, _from, _limit, true);
        }
    }

     
    function roomNight(uint256 _rnid) 
        external 
        view 
        returns(uint256 _vendorId,uint256 _rpid,uint256 _token,uint256 _price,uint256 _timestamp,uint256 _date,bytes32 _ipfs, string _name) {
        (_vendorId, _rpid, _token, _price, _timestamp, _date, _ipfs) = dataSource.roomnights(_rnid);
        (_name,,) = dataSource.getRatePlan(_vendorId, _rpid);
    }
}

library IPFSLib {
    bytes constant ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
    bytes constant HEX = "0123456789abcdef";

     
    function base58Address(bytes _source) internal pure returns (bytes) {
        uint8[] memory digits = new uint8[](_source.length * 136/100 + 1);
        digits[0] = 0;
        uint8 digitlength = 1;
        for (uint i = 0; i < _source.length; ++i) {
            uint carry = uint8(_source[i]);
            for (uint j = 0; j<digitlength; ++j) {
                carry += uint(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }
            
            while (carry > 0) {
                digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry = carry / 58;
            }
        }
        return toAlphabet(reverse(truncate(digits, digitlength)));
    }

     
    function hexAddress(bytes32 _source) internal pure returns(bytes) {
        uint256 value = uint256(_source);
        bytes memory result = "0000000000000000000000000000000000000000000000000000000000000000";
        uint8 index = 0;
        while(value > 0) {
            result[index] = HEX[value & 0xf];
            index++;
            value = value>>4;
        }
        bytes memory ipfsBytes = reverseBytes(result);
        return ipfsBytes;
    }

     
    function truncate(uint8[] _array, uint8 _length) internal pure returns (uint8[]) {
        uint8[] memory output = new uint8[](_length);
        for (uint i = 0; i < _length; i++) {
            output[i] = _array[i];
        }
        return output;
    }
    
     
    function reverse(uint8[] _input) internal pure returns (uint8[]) {
        uint8[] memory output = new uint8[](_input.length);
        for (uint i = 0; i < _input.length; i++) {
            output[i] = _input[_input.length - 1 - i];
        }
        return output;
    }

     
    function reverseBytes(bytes _input) private pure returns (bytes) {
        bytes memory output = new bytes(_input.length);
        for (uint8 i = 0; i < _input.length; i++) {
            output[i] = _input[_input.length-1-i];
        }
        return output;
    }
    
     
    function toAlphabet(uint8[] _indices) internal pure returns (bytes) {
        bytes memory output = new bytes(_indices.length);
        for (uint i = 0; i < _indices.length; i++) {
            output[i] = ALPHABET[_indices[i]];
        }
        return output;
    }

     
    function toBytes(bytes32 _input) internal pure returns (bytes) {
        bytes memory output = new bytes(32);
        for (uint8 i = 0; i < 32; i++) {
            output[i] = _input[i];
        }
        return output;
    }

     
    function concat(bytes _byteArray, bytes _byteArray2) internal pure returns (bytes) {
        bytes memory returnArray = new bytes(_byteArray.length + _byteArray2.length);
        for (uint16 i = 0; i < _byteArray.length; i++) {
            returnArray[i] = _byteArray[i];
        }
        for (i; i < (_byteArray.length + _byteArray2.length); i++) {
            returnArray[i] = _byteArray2[i - _byteArray.length];
        }
        return returnArray;
    }
}

contract TRNAsset is TRNData, ERC721Metadata {
    using IPFSLib for bytes;
    using IPFSLib for bytes32;

     
    constructor() public {
        
    }

     
    function name() external pure returns (string _name) {
        return "Tripio Room Night";
    }

     
    function symbol() external pure returns (string _symbol) {
        return "TRN";
    }

     
    function tokenURI(uint256 _tokenId) 
        external 
        view 
        validToken(_tokenId) 
        returns (string) { 
        bytes memory prefix = new bytes(2);
        prefix[0] = 0x12;
        prefix[1] = 0x20;
        (,,,,,,bytes32 ipfs) = dataSource.roomnights(_tokenId);
        bytes memory value = prefix.concat(ipfs.toBytes());
        bytes memory ipfsBytes = value.base58Address();
        bytes memory tokenBaseURIBytes = bytes(dataSource.tokenBaseURI());
        return string(tokenBaseURIBytes.concat(ipfsBytes));
    }
}

contract TRNOwnership is TRNOwners, ERC721 {
     
    constructor() public {

    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

     
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
    function _transfer(uint256 _tokenId, address _to) private {
         
        address from = dataSource.roomNightIndexToOwner(_tokenId);

         
        _removeRoomNight(from, _tokenId);

         
        _pushRoomNight(_to, _tokenId, false);

         
         
        dataSource.transferTokenTo(_tokenId, _to);

         
        emit Transfer(from, _to, _tokenId);
    }

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data)
        private
        validToken(_tokenId)
        canTransfer(_tokenId) {
         
        address owner = dataSource.roomNightIndexToOwner(_tokenId);
        require(owner == _from);

         
        require(_to != address(0));

        _transfer(_tokenId, _to);

        uint256 codeSize;
        assembly { codeSize := extcodesize(_to) }
        if (codeSize == 0) {
            return;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
        require (retval == dataSource.ERC721_RECEIVED());
    }

     
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return dataSource.balanceOf(_owner);
    }

     
    function ownerOf(uint256 _tokenId) external view returns (address) {
        require(_tokenId > 0);
        return dataSource.roomNightIndexToOwner(_tokenId);
    }

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external payable {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

     
    function transferFrom(address _from, address _to, uint256 _tokenId) 
        external 
        payable
        validToken(_tokenId)
        canTransfer(_tokenId) {
         
        address owner = dataSource.roomNightIndexToOwner(_tokenId);
        require(owner == _from);

         
        require(_to != address(0));

        _transfer(_tokenId, _to);
    }

     
    function transferFromInBatch(address _from, address _to, uint256[] _tokenIds) 
        external
        payable
        validTokenInBatch(_tokenIds)
        canTransferInBatch(_tokenIds) {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
             
            address owner = dataSource.roomNightIndexToOwner(_tokenIds[i]);
            require(owner == _from);

             
            require(_to != address(0));

            _transfer(_tokenIds[i], _to);
        }
    }

     
    function approve(address _approved, uint256 _tokenId) 
        external 
        payable 
        validToken(_tokenId)
        canOperate(_tokenId) {
        address owner = dataSource.roomNightIndexToOwner(_tokenId);
        
        dataSource.approveTokenTo(_tokenId, _approved);
        emit Approval(owner, _approved, _tokenId);
    }

     
    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != address(0));
        dataSource.approveOperatorTo(_operator, msg.sender, _approved);
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

     
    function getApproved(uint256 _tokenId) 
        external 
        view 
        validToken(_tokenId)
        returns (address) {
        return dataSource.roomNightApprovals(_tokenId);
    }

     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return dataSource.operatorApprovals(_owner, _operator);
    }
}


contract TRNSupportsInterface is TRNData, ERC165 {
     
    constructor() public {

    }

     
    function supportsInterface(bytes4 interfaceID) 
        external 
        view 
        returns (bool) {
        return ((interfaceID == dataSource.interfaceSignature_ERC165()) ||
        (interfaceID == dataSource.interfaceSignature_ERC721Metadata()) ||
        (interfaceID == dataSource.interfaceSignature_ERC721())) &&
        (interfaceID != 0xffffffff);
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



contract TRNTransactions is TRNOwners {
     
    constructor() public {

    }

     
    event BuyInBatch(address indexed _customer, address indexed _vendor, uint256 indexed _rpid, uint256[] _dates, uint256 _token);

     
    event ApplyRefund(address _customer, uint256 indexed _rnid, bool _isRefund);

     
    event Refund(address _vendor, uint256 _rnid);

     
    function _buy(uint256 _vendorId, uint256 _rpid, uint256 _date, address _customer, uint256 _token) private {
         
        (,,uint256 _price) = dataSource.getPrice(_vendorId, _rpid, _date, _token);
        (,,bytes32 _ipfs) = dataSource.getRatePlan(_vendorId, _rpid);
        uint256 rnid = dataSource.generateRoomNightToken(_vendorId, _rpid, _date, _token, _price, _ipfs);

         
        dataSource.transferTokenTo(rnid, _customer);

         
        _pushRoomNight(_customer, rnid, false);

         
        (,address vendor,,) = dataSource.getVendor(_vendorId);
        _pushRoomNight(vendor, rnid, true);

         
        dataSource.reduceInventories(_vendorId, _rpid, _date, 1);
    }

     
    function _buyInBatch(uint256 _vendorId, address _vendor, uint256 _rpid, uint256[] _dates, uint256 _token) private returns(bool) {
        (uint16[] memory inventories, uint256[] memory values) = dataSource.getPrices(_vendorId, _rpid, _dates, _token);
        uint256 totalValues = 0;
        for(uint256 i = 0; i < _dates.length; i++) {
            if(inventories[i] == 0 || values[i] == 0) {
                return false;
            }
            totalValues += values[i];
             
            _buy(_vendorId, _rpid, _dates[i], msg.sender, _token);
        }
        
        if (_token == 0) {
             
            require(msg.value == totalValues);

             
            _vendor.transfer(totalValues);
        } else {
             
            address tokenAddress = dataSource.tokenIndexToAddress(_token);
            require(tokenAddress != address(0));

             
            TripioToken tripio = TripioToken(tokenAddress);
            tripio.transferFrom(msg.sender, _vendor, totalValues);
        }
        return true;
    }

     
    function _refund(uint256 _rnid, uint256 _vendorId, uint256 _rpid, uint256 _date) private {
         
        _removeRoomNight(dataSource.roomNightIndexToOwner(_rnid), _rnid);

         
        dataSource.addInventories(_vendorId, _rpid, _date, 1);

         
        dataSource.transferTokenTo(_rnid, address(0));
    }

     
    function buyInBatch(uint256 _vendorId, uint256 _rpid, uint256[] _dates, uint256 _token) 
        external
        payable
        ratePlanExist(_vendorId, _rpid)
        validDates(_dates)
        returns(bool) {
        
        (,address vendor,,) = dataSource.getVendor(_vendorId);
        
        bool result = _buyInBatch(_vendorId, vendor, _rpid, _dates, _token);
        
        require(result);

         
        emit BuyInBatch(msg.sender, vendor, _rpid, _dates, _token);
        return true;
    }

     
    function applyRefund(uint256 _rnid, bool _isRefund) 
        external
        validToken(_rnid)
        canTransfer(_rnid)
        returns(bool) {
        dataSource.updateRefundApplications(msg.sender, _rnid, _isRefund);

         
        emit ApplyRefund(msg.sender, _rnid, _isRefund);
        return true;
    }

     
    function isRefundApplied(uint256 _rnid) 
        external
        view
        validToken(_rnid) returns(bool) {
        return dataSource.refundApplications(dataSource.roomNightIndexToOwner(_rnid), _rnid);
    }

     
    function refund(uint256 _rnid) 
        external
        payable
        validToken(_rnid) 
        returns(bool) {
         
        require(dataSource.refundApplications(dataSource.roomNightIndexToOwner(_rnid), _rnid));

         
        (uint256 vendorId,uint256 rpid,uint256 token,uint256 price,,uint256 date,) = dataSource.roomnights(_rnid);
        (,address vendor,,) = dataSource.getVendor(vendorId);
        require(msg.sender == vendor);

        address ownerAddress = dataSource.roomNightIndexToOwner(_rnid);

        if (token == 0) {
             

             
            uint256 value = price;
            require(msg.value >= value);

             
            ownerAddress.transfer(value);
        } else {
             

             
            require(price > 0);

             
            TripioToken tripio = TripioToken(dataSource.tokenIndexToAddress(token));
            tripio.transferFrom(msg.sender, ownerAddress, price);
        }
         
        _refund(_rnid, vendorId, rpid, date);

         
        emit Refund(msg.sender, _rnid);
        return true;
    }
}

contract TripioRoomNightCustomer is TRNAsset, TRNSupportsInterface, TRNOwnership, TRNTransactions {
     
    constructor(address _dataSource) public {
         
        dataSource = TripioRoomNightData(_dataSource);
    }

     
    function withdrawBalance() external onlyOwner {
        owner.transfer(address(this).balance);
    }

     
    function withdrawTokenId(uint _token) external onlyOwner {
        TripioToken tripio = TripioToken(dataSource.tokenIndexToAddress(_token));
        uint256 tokens = tripio.balanceOf(address(this));
        tripio.transfer(owner, tokens);
    }

     
    function withdrawToken(address _tokenAddress) external onlyOwner {
        TripioToken tripio = TripioToken(_tokenAddress);
        uint256 tokens = tripio.balanceOf(address(this));
        tripio.transfer(owner, tokens);
    }

     
    function destroy() external onlyOwner {
        selfdestruct(owner);
    }

    function() external payable {

    }
}