 

 

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

    bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61;  
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81;  
}

 

pragma solidity ^0.5.0;

 
interface ERC1155TokenReceiver {
     
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

     
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);
}

 

pragma solidity ^0.5.0;


 
interface ERC165 {

     
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

 

pragma solidity ^0.5.0;


 
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

 

pragma solidity ^0.5.0;






 
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

         
         


         
         
        require(ERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data) == ERC1155_ACCEPTED, "contract returned an unknown value from onERC1155Received");
    }

    function _doSafeBatchTransferAcceptanceCheck(address _operator, address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) internal {

         
         

         
         
        require(ERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data) == ERC1155_BATCH_ACCEPTED, "contract returned an unknown value from onERC1155BatchReceived");
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;

library Strings {
   
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

 

pragma solidity ^0.5.0;




 
contract RCContract is ERC1155, Ownable {

    bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;

      
    string private _contractName = 'ReceiptChain';

     
    string private _symbol = 'RCPT';

     
    string private _baseURI = 'https: 

     
    mapping(uint256 => uint256) private _totalSupplies;

     
    uint256 public nonce;

         
    event CreationName(string _value, uint256 indexed _id);

    event Update(string _value, uint256 indexed _id);

    function supportsInterface(bytes4 _interfaceId)
    public
    view
    returns (bool) {
        if (_interfaceId == INTERFACE_SIGNATURE_URI) {
            return true;
        } else {
            return super.supportsInterface(_interfaceId);
        }
    }

     
    function create(uint256 _initialSupply, address _to, string calldata _name) external onlyOwner returns (uint256 _id) {

        _id = ++nonce;
        balances[_id][_to] = _initialSupply;
        _totalSupplies[_id] = _initialSupply;

         
        emit TransferSingle(msg.sender, address(0x0), _to, _id, _initialSupply);

        emit URI(string(abi.encodePacked(baseTokenURI(),Strings.uint2str(_id))), _id);

        if (bytes(_name).length > 0)
            emit CreationName(_name, _id);
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _baseURI = uri;
    }

    function update(string calldata _update, uint256 _id) external onlyOwner {
        emit Update(_update, _id);
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseURI;
    }

    function uri(uint256 _id) external view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(),Strings.uint2str(_id)));
    }

    function tokenURI(uint256 _id) external view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(),Strings.uint2str(_id)));
    }

     
    function name() external view returns (string memory) {
        return _contractName;
    }

     
    function symbol() external view returns (string memory) {
        return _symbol;
    }

     
     
     
     
    function totalSupply(uint256 _id) external view returns (uint256) {
        return _totalSupplies[_id];
    }

     
     
     
    function totalTokenTypes() external view returns (uint256) {
        return nonce;
    }
}