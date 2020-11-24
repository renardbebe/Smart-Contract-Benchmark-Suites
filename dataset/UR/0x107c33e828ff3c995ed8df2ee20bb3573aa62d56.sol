 

pragma solidity ^0.4.17;

 

 
 
 
pragma solidity ^0.4.17;


 
contract iERC20Token {

     

    
    uint256 public totalSupply = 0;
    bytes32 public name; 
    uint8 public decimals; 
    bytes32 public symbol; 


     

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     

     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);


     

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

 
contract CurrencyToken {

    address public server;  
    address public populous;  

    uint256 public totalSupply;
    bytes32 public name; 
    uint8 public decimals; 
    bytes32 public symbol; 

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
     
     
    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 _value
    );
     
    event Approval(
        address indexed _owner, 
        address indexed _spender, 
        uint256 _value
    );
    event EventMintTokens(bytes32 currency, address owner, uint amount);
    event EventDestroyTokens(bytes32 currency, address owner, uint amount);


     

    modifier onlyServer {
        require(isServer(msg.sender) == true);
        _;
    }

    modifier onlyServerOrOnlyPopulous {
        require(isServer(msg.sender) == true || isPopulous(msg.sender) == true);
        _;
    }

    modifier onlyPopulous {
        require(isPopulous(msg.sender) == true);
        _;
    }
     
    
     
    function CurrencyToken ()
        public
    {
        populous = server = 0xf8B3d742B245Ec366288160488A12e7A2f1D720D;
        symbol = name = 0x55534443;  
        decimals = 6;  
        balances[server] = safeAdd(balances[server], 10000000000000000);
        totalSupply = safeAdd(totalSupply, 10000000000000000);
    }

     

     
    function mint(uint amount, address owner) public onlyServerOrOnlyPopulous returns (bool success) {
        balances[owner] = safeAdd(balances[owner], amount);
        totalSupply = safeAdd(totalSupply, amount);
        emit EventMintTokens(symbol, owner, amount);
        return true;
    }

     
    function destroyTokens(uint amount) public onlyServerOrOnlyPopulous returns (bool success) {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        totalSupply = safeSub(totalSupply, amount);
        emit EventDestroyTokens(symbol, populous, amount);
        return true;
    }
    
     
    function destroyTokensFrom(uint amount, address from) public onlyServerOrOnlyPopulous returns (bool success) {
        require(balances[from] >= amount);
        balances[from] = safeSub(balances[from], amount);
        totalSupply = safeSub(totalSupply, amount);
        emit EventDestroyTokens(symbol, from, amount);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


     

     
    function isPopulous(address sender) public view returns (bool) {
        return sender == populous;
    }

         
    function changePopulous(address _populous) public {
        require(isServer(msg.sender) == true);
        populous = _populous;
    }

     
    
     
    function isServer(address sender) public view returns (bool) {
        return sender == server;
    }

     
    function changeServer(address _server) public {
        require(isServer(msg.sender) == true);
        server = _server;
    }


     


       
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

   
    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

   
    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);  
        uint256 c = a / b;
        assert(a == b * c + a % b);  
        return c;
    }
}

 

 
contract AccessManager {
     

     

    address public server;  
    address public populous;  

     

     
    function AccessManager(address _server) public {
        server = _server;
         
    }

     
    function changeServer(address _server) public {
        require(isServer(msg.sender) == true);
        server = _server;
    }

     
     

     
    function changePopulous(address _populous) public {
        require(isServer(msg.sender) == true);
        populous = _populous;
    }

     
    
     
    function isServer(address sender) public view returns (bool) {
        return sender == server;
    }

     
     

     
    function isPopulous(address sender) public view returns (bool) {
        return sender == populous;
    }

}

 

 
contract withAccessManager {

     
    
    AccessManager public AM;

     

     
     
    modifier onlyServer {
        require(AM.isServer(msg.sender) == true);
        _;
    }

    modifier onlyServerOrOnlyPopulous {
        require(AM.isServer(msg.sender) == true || AM.isPopulous(msg.sender) == true);
        _;
    }

     
     
     

     
     
    modifier onlyPopulous {
        require(AM.isPopulous(msg.sender) == true);
        _;
    }

     
    
     
    function withAccessManager(address _accessManager) public {
        AM = AccessManager(_accessManager);
    }
    
     
    function updateAccessManager(address _accessManager) public onlyServer {
        AM = AccessManager(_accessManager);
    }

}

 

 
library ERC1155SafeMath {

     
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

 

 
library Address {

     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}

 

 
interface IERC1155TokenReceiver {
     
     
     
     
     
     
     
     
     
     
     
     
     
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes _data) external returns(bytes4);
}

interface IERC1155 {
    event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id, uint256 _oldValue, uint256 _value);
    event Transfer(address _spender, address indexed _from, address indexed _to, uint256 indexed _id, uint256 _value);

    function transferFrom(address _from, address _to, uint256 _id, uint256 _value) external;
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data) external;
    function approve(address _spender, uint256 _id, uint256 _currentValue, uint256 _value) external;
    function balanceOf(uint256 _id, address _owner) external view returns (uint256);
    function allowance(uint256 _id, address _owner, address _spender) external view returns (uint256);
}

interface IERC1155Extended {
    function transfer(address _to, uint256 _id, uint256 _value) external;
    function safeTransfer(address _to, uint256 _id, uint256 _value, bytes _data) external;
}

interface IERC1155BatchTransfer {
    function batchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values, bytes _data) external;
    function batchApprove(address _spender, uint256[] _ids,  uint256[] _currentValues, uint256[] _values) external;
}

interface IERC1155BatchTransferExtended {
    function batchTransfer(address _to, uint256[] _ids, uint256[] _values) external;
    function safeBatchTransfer(address _to, uint256[] _ids, uint256[] _values, bytes _data) external;
}

interface IERC1155Operators {
    event OperatorApproval(address indexed _owner, address indexed _operator, uint256 indexed _id, bool _approved);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function setApproval(address _operator, uint256[] _ids, bool _approved) external;
    function isApproved(address _owner, address _operator, uint256 _id)  external view returns (bool);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

interface IERC1155Views {
    function totalSupply(uint256 _id) external view returns (uint256);
    function name(uint256 _id) external view returns (string);
    function symbol(uint256 _id) external view returns (string);
    function decimals(uint256 _id) external view returns (uint8);
    function uri(uint256 _id) external view returns (string);
}

 

contract ERC1155 is IERC1155, IERC1155Extended, IERC1155BatchTransfer, IERC1155BatchTransferExtended {
    using ERC1155SafeMath for uint256;
    using Address for address;

     
    struct Items {
        string name;
        uint256 totalSupply;
        mapping (address => uint256) balances;
    }
    mapping (uint256 => uint8) public decimals;
    mapping (uint256 => string) public symbols;
    mapping (uint256 => mapping(address => mapping(address => uint256))) public allowances;
    mapping (uint256 => Items) public items;
    mapping (uint256 => string) public metadataURIs;

    bytes4 constant private ERC1155_RECEIVED = 0xf23a6e61;

 

     
    event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id, uint256 _oldValue, uint256 _value);
    event Transfer(address _spender, address indexed _from, address indexed _to, uint256 indexed _id, uint256 _value);

    function transferFrom(address _from, address _to, uint256 _id, uint256 _value) external {
        if(_from != msg.sender) {
             
            allowances[_id][_from][msg.sender] = allowances[_id][_from][msg.sender].sub(_value);
        }

        items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
        items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

        Transfer(msg.sender, _from, _to, _id, _value);
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data) external {
         

         
        require(_checkAndCallSafeTransfer(_from, _to, _id, _value, _data));
        if(_from != msg.sender) {
             
            allowances[_id][_from][msg.sender] = allowances[_id][_from][msg.sender].sub(_value);
        }

        items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
        items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

        Transfer(msg.sender, _from, _to, _id, _value);
    }

    function approve(address _spender, uint256 _id, uint256 _currentValue, uint256 _value) external {
         
        require(_value == 0 || allowances[_id][msg.sender][_spender] == _currentValue);
        allowances[_id][msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _id, _currentValue, _value);
    }

    function balanceOf(uint256 _id, address _owner) external view returns (uint256) {
        return items[_id].balances[_owner];
    }

    function allowance(uint256 _id, address _owner, address _spender) external view returns (uint256) {
        return allowances[_id][_owner][_spender];
    }

 

    function transfer(address _to, uint256 _id, uint256 _value) external {
         
         
        items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
        items[_id].balances[_to] = _value.add(items[_id].balances[_to]);
        Transfer(msg.sender, msg.sender, _to, _id, _value);
    }

    function safeTransfer(address _to, uint256 _id, uint256 _value, bytes _data) external {
         
                
         
        require(_checkAndCallSafeTransfer(msg.sender, _to, _id, _value, _data));
        items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
        items[_id].balances[_to] = _value.add(items[_id].balances[_to]);
        Transfer(msg.sender, msg.sender, _to, _id, _value);
    }

 

    function batchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values) external {
        uint256 _id;
        uint256 _value;

        if(_from == msg.sender) {
            for (uint256 i = 0; i < _ids.length; ++i) {
                _id = _ids[i];
                _value = _values[i];

                items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
                items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

                Transfer(msg.sender, _from, _to, _id, _value);
            }
        }
        else {
            for (i = 0; i < _ids.length; ++i) {
                _id = _ids[i];
                _value = _values[i];

                allowances[_id][_from][msg.sender] = allowances[_id][_from][msg.sender].sub(_value);

                items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
                items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

                Transfer(msg.sender, _from, _to, _id, _value);
            }
        }
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values, bytes _data) external {
         

        for (uint256 i = 0; i < _ids.length; ++i) {
             
            require(_checkAndCallSafeTransfer(_from, _to, _ids[i], _values[i], _data));
        }

        uint256 _id;
        uint256 _value;

        if(_from == msg.sender) {
            for (i = 0; i < _ids.length; ++i) {
                _id = _ids[i];
                _value = _values[i];

                items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
                items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

                Transfer(msg.sender, _from, _to, _id, _value);
            }
        }
        else {
            for (i = 0; i < _ids.length; ++i) {
                _id = _ids[i];
                _value = _values[i];

                allowances[_id][_from][msg.sender] = allowances[_id][_from][msg.sender].sub(_value);

                items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
                items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

                Transfer(msg.sender, _from, _to, _id, _value);
            }
        }
    }

    function batchApprove(address _spender, uint256[] _ids,  uint256[] _currentValues, uint256[] _values) external {
        uint256 _id;
        uint256 _value;

        for (uint256 i = 0; i < _ids.length; ++i) {
            _id = _ids[i];
            _value = _values[i];

            require(_value == 0 || allowances[_id][msg.sender][_spender] == _currentValues[i]);
            allowances[_id][msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _id, _currentValues[i], _value);
        }
    }

 

    function batchTransfer(address _to, uint256[] _ids, uint256[] _values) external {
        uint256 _id;
        uint256 _value;

        for (uint256 i = 0; i < _ids.length; ++i) {
            _id = _ids[i];
            _value = _values[i];

            items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
            items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

            Transfer(msg.sender, msg.sender, _to, _id, _value);
        }
    }

    function safeBatchTransfer(address _to, uint256[] _ids, uint256[] _values, bytes _data) external {
         

        for (uint256 i = 0; i < _ids.length; ++i) {
             
            require(_checkAndCallSafeTransfer(msg.sender, _to, _ids[i], _values[i], _data));
        }

        uint256 _id;
        uint256 _value;

        for (i = 0; i < _ids.length; ++i) {
            _id = _ids[i];
            _value = _values[i];

            items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
            items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

            Transfer(msg.sender, msg.sender, _to, _id, _value);
        }
    }

 

     
     
    function name(uint256 _id) external view returns (string) {
        return items[_id].name;
    }

    function symbol(uint256 _id) external view returns (string) {
        return symbols[_id];
    }

    function decimals(uint256 _id) external view returns (uint8) {
        return decimals[_id];
    }

    function totalSupply(uint256 _id) external view returns (uint256) {
        return items[_id].totalSupply;
    }

    function uri(uint256 _id) external view returns (string) {
        return metadataURIs[_id];
    }

 


    function multicastTransfer(address[] _to, uint256[] _ids, uint256[] _values) external {
        for (uint256 i = 0; i < _to.length; ++i) {
            uint256 _id = _ids[i];
            uint256 _value = _values[i];
            address _dst = _to[i];

            items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
            items[_id].balances[_dst] = _value.add(items[_id].balances[_dst]);

            Transfer(msg.sender, msg.sender, _dst, _id, _value);
        }
    }

    function safeMulticastTransfer(address[] _to, uint256[] _ids, uint256[] _values, bytes _data) external {
         

        for (uint256 i = 0; i < _ids.length; ++i) {
             
            require(_checkAndCallSafeTransfer(msg.sender, _to[i], _ids[i], _values[i], _data));
        }

        for (i = 0; i < _to.length; ++i) {
            uint256 _id = _ids[i];
            uint256 _value = _values[i];
            address _dst = _to[i];

            items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
            items[_id].balances[_dst] = _value.add(items[_id].balances[_dst]);

            Transfer(msg.sender, msg.sender, _dst, _id, _value);
        }
    }

 

    function _checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes _data
    )
    internal
    returns (bool)
    {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received(
            msg.sender, _from, _id, _value, _data);
        return (retval == ERC1155_RECEIVED);
    }
}

 

 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

 

 
contract ERC721Basic is ERC165 {

    bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
     

    bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
     

    bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
     

    bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
     

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

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId) public view returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) public;
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);

    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public;
}

 

 
contract DepositContract is withAccessManager {

    bytes32 public clientId;  
    uint256 public version = 2;

     
    event EtherTransfer(address to, uint256 value);

     

     
    function DepositContract(bytes32 _clientId, address accessManager) public withAccessManager(accessManager) {
        clientId = _clientId;
    }
     
     
    function transfer(address populousTokenContract, address _to, uint256 _value) public
        onlyServerOrOnlyPopulous returns (bool success) 
    {
        return iERC20Token(populousTokenContract).transfer(_to, _value);
    }

     
    function transferERC1155(address _erc1155Token, address _to, uint256 _id, uint256 _value) 
        public onlyServerOrOnlyPopulous returns (bool success) {
        ERC1155(_erc1155Token).safeTransfer(_to, _id, _value, "");
        return true;
    }

     
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) public returns(bytes4) {
        return 0x150b7a02; 
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes _data) public returns(bytes4) {
        return 0xf23a6e61;
    }

     
    function transferERC721(
        address erc721Token,
        address _to,
        uint256 _tokenId
    )
        public onlyServerOrOnlyPopulous returns (bool success)
    {
         
        ERC721Basic(erc721Token).safeTransferFrom(this, _to, _tokenId, "");
        return true;
    }

     
    function transferEther(address _to, uint256 _value) public 
        onlyServerOrOnlyPopulous returns (bool success) 
    {
        require(this.balance >= _value);
        require(_to.send(_value) == true);
        EtherTransfer(_to, _value);
        return true;
    }

     
     

     
    
     
    function balanceOf(address populousTokenContract) public view returns (uint256) {
         
        if (populousTokenContract == address(0)) {
            return address(this).balance;
        } else {
             
            return iERC20Token(populousTokenContract).balanceOf(this);
        }
    }

     
    function balanceOfERC721(address erc721Token) public view returns (uint256) {
        return ERC721Basic(erc721Token).balanceOf(this);
         
    }

     
    function balanceOfERC1155(address erc1155Token, uint256 _id) external view returns (uint256) {
        return ERC1155(erc1155Token).balanceOf(_id, this);
    }

     
    function getVersion() public view returns (uint256) {
        return version;
    }

     

     
    function getClientId() public view returns (bytes32 _clientId) {
        return clientId;
    }
}

 

 
 
library SafeMath {

   
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

   
    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

   
    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);  
        uint256 c = a / b;
        assert(a == b * c + a % b);  
        return c;
    }
}

 

 
contract iDataManager {
     
    uint256 public version;
     
    mapping(bytes32 => address) public currencyAddresses;
     
    mapping(address => bytes32) public currencySymbols;
     
    mapping(bytes32 => address) public depositAddresses;
     
    mapping(address => bytes32) public depositClientIds;
     
    mapping(bytes32 => bool) public actionStatus;
     
    struct actionData {
        bytes32 currency;
        uint amount;
        bytes32 accountId;
        address to;
        uint pptFee;
    }
     
    mapping(bytes32 => actionData) public blockchainActionIdData;
    
     
    mapping(bytes32 => bytes32) public actionIdToInvoiceId;
     
    struct providerCompany {
         
        bytes32 companyNumber;
        bytes32 companyName;
        bytes2 countryCode;
    }
     
    mapping(bytes2 => mapping(bytes32 => bytes32)) public providerData;
     
    mapping(bytes32 => providerCompany) public providerCompanyData;
     
    struct _invoiceDetails {
        bytes2 invoiceCountryCode;
        bytes32 invoiceCompanyNumber;
        bytes32 invoiceCompanyName;
        bytes32 invoiceNumber;
    }
     
    struct invoiceData {
        bytes32 providerUserId;
        bytes32 invoiceCompanyName;
    }

     
    mapping(bytes2 => mapping(bytes32 => mapping(bytes32 => invoiceData))) public invoices;
    
    
    
    
     

     
    function setDepositAddress(bytes32 _blockchainActionId, address _depositAddress, bytes32 _clientId) public returns (bool success);

     
    function setCurrency(bytes32 _blockchainActionId, address _currencyAddress, bytes32 _currencySymbol) public returns (bool success);

     
    function _setCurrency(bytes32 _blockchainActionId, address _currencyAddress, bytes32 _currencySymbol) public returns (bool success);


     
    function setBlockchainActionData(
        bytes32 _blockchainActionId, bytes32 currency, 
        uint amount, bytes32 accountId, address to, uint pptFee) 
        public 
        returns (bool success);

     
    function upgradeDepositAddress(bytes32 _blockchainActionId, bytes32 _clientId, address _depositContract) public returns (bool success);
  

     
    function _setDepositAddress(bytes32 _blockchainActionId, bytes32 _clientId, address _depositContract) public returns (bool success);

     
    function setInvoice(
        bytes32 _blockchainActionId, bytes32 _providerUserId, bytes2 _invoiceCountryCode, 
        bytes32 _invoiceCompanyNumber, bytes32 _invoiceCompanyName, bytes32 _invoiceNumber) 
        public returns (bool success);

    
     
    function setProvider(
        bytes32 _blockchainActionId, bytes32 _userId, bytes32 _companyNumber, 
        bytes32 _companyName, bytes2 _countryCode) 
        public returns (bool success);

     
    function _setProvider(
        bytes32 _blockchainActionId, bytes32 _userId, bytes32 _companyNumber, 
        bytes32 _companyName, bytes2 _countryCode) 
        public returns (bool success);
    
     

     
    function getDepositAddress(bytes32 _clientId) public view returns (address clientDepositAddress);


     
    function getClientIdWithDepositAddress(address _depositContract) public view returns (bytes32 depositClientId);


     
    function getCurrency(bytes32 _currencySymbol) public view returns (address currencyAddress);

   
     
    function getCurrencySymbol(address _currencyAddress) public view returns (bytes32 currencySymbol);

     
    function getCurrencyDetails(address _currencyAddress) public view returns (bytes32 _symbol, bytes32 _name, uint8 _decimals);

     
    function getBlockchainActionIdData(bytes32 _blockchainActionId) public view returns (bytes32 _currency, uint _amount, bytes32 _accountId, address _to);


     
    function getActionStatus(bytes32 _blockchainActionId) public view returns (bool _blockchainActionStatus);


     
    function getInvoice(bytes2 _invoiceCountryCode, bytes32 _invoiceCompanyNumber, bytes32 _invoiceNumber) 
        public 
        view 
        returns (bytes32 providerUserId, bytes32 invoiceCompanyName);


     
    function getProviderByCountryCodeCompanyNumber(bytes2 _providerCountryCode, bytes32 _providerCompanyNumber) 
        public 
        view 
        returns (bytes32 providerId, bytes32 companyName);


     
    function getProviderByUserId(bytes32 _providerUserId) public view 
        returns (bytes2 countryCode, bytes32 companyName, bytes32 companyNumber);


     
    function getVersion() public view returns (uint256 _version);

}

 

 
contract DataManager is iDataManager, withAccessManager {
    

     

     
    function DataManager(address _accessManager, uint256 _version) public withAccessManager(_accessManager) {
        version = _version;
    }

     
    function setDepositAddress(bytes32 _blockchainActionId, address _depositAddress, bytes32 _clientId) public onlyServerOrOnlyPopulous returns (bool success) {
        require(actionStatus[_blockchainActionId] == false);
        require(depositAddresses[_clientId] == 0x0 && depositClientIds[_depositAddress] == 0x0);
        depositAddresses[_clientId] = _depositAddress;
        depositClientIds[_depositAddress] = _clientId;
        assert(depositAddresses[_clientId] != 0x0 && depositClientIds[_depositAddress] != 0x0);
        return true;
    }

     
    function setCurrency(bytes32 _blockchainActionId, address _currencyAddress, bytes32 _currencySymbol) public onlyServerOrOnlyPopulous returns (bool success) {
        require(actionStatus[_blockchainActionId] == false);
        require(currencySymbols[_currencyAddress] == 0x0 && currencyAddresses[_currencySymbol] == 0x0);
        currencySymbols[_currencyAddress] = _currencySymbol;
        currencyAddresses[_currencySymbol] = _currencyAddress;
        assert(currencyAddresses[_currencySymbol] != 0x0 && currencySymbols[_currencyAddress] != 0x0);
        return true;
    }

     
    function _setCurrency(bytes32 _blockchainActionId, address _currencyAddress, bytes32 _currencySymbol) public onlyServerOrOnlyPopulous returns (bool success) {
        require(actionStatus[_blockchainActionId] == false);
        currencySymbols[_currencyAddress] = _currencySymbol;
        currencyAddresses[_currencySymbol] = _currencyAddress;
        assert(currencyAddresses[_currencySymbol] != 0x0 && currencySymbols[_currencyAddress] != 0x0);
        setBlockchainActionData(_blockchainActionId, _currencySymbol, 0, 0x0, _currencyAddress, 0);
        return true;
    }

     
    function setBlockchainActionData(
        bytes32 _blockchainActionId, bytes32 currency, 
        uint amount, bytes32 accountId, address to, uint pptFee) 
        public
        onlyServerOrOnlyPopulous 
        returns (bool success)
    {
        require(actionStatus[_blockchainActionId] == false);
        blockchainActionIdData[_blockchainActionId].currency = currency;
        blockchainActionIdData[_blockchainActionId].amount = amount;
        blockchainActionIdData[_blockchainActionId].accountId = accountId;
        blockchainActionIdData[_blockchainActionId].to = to;
        blockchainActionIdData[_blockchainActionId].pptFee = pptFee;
        actionStatus[_blockchainActionId] = true;
        return true;
    }
    
     
    function _setDepositAddress(bytes32 _blockchainActionId, bytes32 _clientId, address _depositContract) public
      onlyServerOrOnlyPopulous
      returns (bool success)
    {
        require(actionStatus[_blockchainActionId] == false);
        depositAddresses[_clientId] = _depositContract;
        depositClientIds[_depositContract] = _clientId;
         
        assert(depositAddresses[_clientId] == _depositContract && depositClientIds[_depositContract] == _clientId);
         
        setBlockchainActionData(_blockchainActionId, 0x0, 0, _clientId, depositAddresses[_clientId], 0);
        return true;
    }

     
    function setInvoice(
        bytes32 _blockchainActionId, bytes32 _providerUserId, bytes2 _invoiceCountryCode, 
        bytes32 _invoiceCompanyNumber, bytes32 _invoiceCompanyName, bytes32 _invoiceNumber) 
        public 
        onlyServerOrOnlyPopulous 
        returns (bool success) 
    {   
        require(actionStatus[_blockchainActionId] == false);
        bytes32 providerUserId; 
        bytes32 companyName;
        (providerUserId, companyName) = getInvoice(_invoiceCountryCode, _invoiceCompanyNumber, _invoiceNumber);
        require(providerUserId == 0x0 && companyName == 0x0);
         
        invoices[_invoiceCountryCode][_invoiceCompanyNumber][_invoiceNumber].providerUserId = _providerUserId;
        invoices[_invoiceCountryCode][_invoiceCompanyNumber][_invoiceNumber].invoiceCompanyName = _invoiceCompanyName;
        
        assert(
            invoices[_invoiceCountryCode][_invoiceCompanyNumber][_invoiceNumber].providerUserId != 0x0 && 
            invoices[_invoiceCountryCode][_invoiceCompanyNumber][_invoiceNumber].invoiceCompanyName != 0x0
        );
        return true;
    }
    
     
    function setProvider(
        bytes32 _blockchainActionId, bytes32 _userId, bytes32 _companyNumber, 
        bytes32 _companyName, bytes2 _countryCode) 
        public 
        onlyServerOrOnlyPopulous
        returns (bool success)
    {   
        require(actionStatus[_blockchainActionId] == false);
        require(
            providerCompanyData[_userId].companyNumber == 0x0 && 
            providerCompanyData[_userId].countryCode == 0x0 &&
            providerCompanyData[_userId].companyName == 0x0);
        
        providerCompanyData[_userId].countryCode = _countryCode;
        providerCompanyData[_userId].companyName = _companyName;
        providerCompanyData[_userId].companyNumber = _companyNumber;

        providerData[_countryCode][_companyNumber] = _userId;
        return true;
    }


     
    function _setProvider(
        bytes32 _blockchainActionId, bytes32 _userId, bytes32 _companyNumber, 
        bytes32 _companyName, bytes2 _countryCode) 
        public 
        onlyServerOrOnlyPopulous
        returns (bool success)
    {   
        require(actionStatus[_blockchainActionId] == false);
        providerCompanyData[_userId].countryCode = _countryCode;
        providerCompanyData[_userId].companyName = _companyName;
        providerCompanyData[_userId].companyNumber = _companyNumber;
        providerData[_countryCode][_companyNumber] = _userId;
        
        setBlockchainActionData(_blockchainActionId, 0x0, 0, _userId, 0x0, 0);
        return true;
    }

     

     
    function getDepositAddress(bytes32 _clientId) public view returns (address clientDepositAddress){
        return depositAddresses[_clientId];
    }

     
    function getClientIdWithDepositAddress(address _depositContract) public view returns (bytes32 depositClientId){
        return depositClientIds[_depositContract];
    }

     
    function getCurrency(bytes32 _currencySymbol) public view returns (address currencyAddress) {
        return currencyAddresses[_currencySymbol];
    }
   
     
    function getCurrencySymbol(address _currencyAddress) public view returns (bytes32 currencySymbol) {
        return currencySymbols[_currencyAddress];
    }

     
    function getCurrencyDetails(address _currencyAddress) public view returns (bytes32 _symbol, bytes32 _name, uint8 _decimals) {
        return (CurrencyToken(_currencyAddress).symbol(), CurrencyToken(_currencyAddress).name(), CurrencyToken(_currencyAddress).decimals());
    } 

     
    function getBlockchainActionIdData(bytes32 _blockchainActionId) public view 
    returns (bytes32 _currency, uint _amount, bytes32 _accountId, address _to) 
    {
        require(actionStatus[_blockchainActionId] == true);
        return (blockchainActionIdData[_blockchainActionId].currency, 
        blockchainActionIdData[_blockchainActionId].amount,
        blockchainActionIdData[_blockchainActionId].accountId,
        blockchainActionIdData[_blockchainActionId].to);
    }

     
    function getActionStatus(bytes32 _blockchainActionId) public view returns (bool _blockchainActionStatus) {
        return actionStatus[_blockchainActionId];
    }

     
    function getInvoice(bytes2 _invoiceCountryCode, bytes32 _invoiceCompanyNumber, bytes32 _invoiceNumber) 
        public 
        view 
        returns (bytes32 providerUserId, bytes32 invoiceCompanyName) 
    {   
        bytes32 _providerUserId = invoices[_invoiceCountryCode][_invoiceCompanyNumber][_invoiceNumber].providerUserId;
        bytes32 _invoiceCompanyName = invoices[_invoiceCountryCode][_invoiceCompanyNumber][_invoiceNumber].invoiceCompanyName;
        return (_providerUserId, _invoiceCompanyName);
    }

     
    function getProviderByCountryCodeCompanyNumber(bytes2 _providerCountryCode, bytes32 _providerCompanyNumber) 
        public 
        view 
        returns (bytes32 providerId, bytes32 companyName) 
    {
        bytes32 providerUserId = providerData[_providerCountryCode][_providerCompanyNumber];
        return (providerUserId, 
        providerCompanyData[providerUserId].companyName);
    }

     
    function getProviderByUserId(bytes32 _providerUserId) public view 
        returns (bytes2 countryCode, bytes32 companyName, bytes32 companyNumber) 
    {
        return (providerCompanyData[_providerUserId].countryCode,
        providerCompanyData[_providerUserId].companyName,
        providerCompanyData[_providerUserId].companyNumber);
    }

     
    function getVersion() public view returns (uint256 _version) {
        return version;
    }

}

 

 








 
contract Populous is withAccessManager {
     
     
    event EventUSDCToUSDp(bytes32 _blockchainActionId, bytes32 _clientId, uint amount);
    event EventUSDpToUSDC(bytes32 _blockchainActionId, bytes32 _clientId, uint amount);
    event EventDepositAddressUpgrade(bytes32 blockchainActionId, address oldDepositContract, address newDepositContract, bytes32 clientId, uint256 version);
    event EventWithdrawPPT(bytes32 blockchainActionId, bytes32 accountId, address depositContract, address to, uint amount);
    event EventWithdrawPoken(bytes32 _blockchainActionId, bytes32 accountId, bytes32 currency, uint amount);
    event EventNewDepositContract(bytes32 blockchainActionId, bytes32 clientId, address depositContractAddress, uint256 version);
    event EventWithdrawXAUp(bytes32 _blockchainActionId, address erc1155Token, uint amount, uint token_id, bytes32 accountId, uint pptFee);

     
    struct tokens {   
        address _token;
        uint256 _precision;
    }
    mapping(bytes8 => tokens) public tokenDetails;

     
     
     
    function Populous(address _accessManager) public withAccessManager(_accessManager) {
         
        
         

         
        tokenDetails[0x505854]._token = 0xc14830E53aA344E8c14603A91229A0b925b0B262;
        tokenDetails[0x505854]._precision = 8;
         
        tokenDetails[0x55534443]._token = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        tokenDetails[0x55534443]._precision = 6;
         
        tokenDetails[0x54555344]._token = 0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E;
        tokenDetails[0x54555344]._precision = 18;
         
        tokenDetails[0x505054]._token = 0xd4fa1460F537bb9085d22C7bcCB5DD450Ef28e3a;        
        tokenDetails[0x505054]._precision = 8;
         
        tokenDetails[0x584155]._token = 0x73a3b7DFFE9af119621f8467D8609771AB4BC33f;
        tokenDetails[0x584155]._precision = 0;
         
        tokenDetails[0x55534470]._token = 0xBaB5D0f110Be6f4a5b70a2FA22eD17324bFF6576;
        tokenDetails[0x55534470]._precision = 6;
        
    }

     
     

    function usdcToUsdp(
        address _dataManager, bytes32 _blockchainActionId, 
        bytes32 _clientId, uint amount)
        public
        onlyServer
    {   
         
        address _depositAddress = DataManager(_dataManager).getDepositAddress(_clientId);
        require(_dataManager != 0x0 && _depositAddress != 0x0 && amount > 0);
         
        require(DepositContract(_depositAddress).transfer(tokenDetails[0x55534443]._token, msg.sender, amount) == true);
         
        require(CurrencyToken(tokenDetails[0x55534470]._token).mint(amount, _depositAddress) == true);     
         
        require(DataManager(_dataManager).setBlockchainActionData(_blockchainActionId, 0x55534470, amount, _clientId, _depositAddress, 0) == true); 
         
        emit EventUSDCToUSDp(_blockchainActionId, _clientId, amount);
    }

    function usdpToUsdc(
        address _dataManager, bytes32 _blockchainActionId, 
        bytes32 _clientId, uint amount) 
        public
        onlyServer
    {
         
        address _depositAddress = DataManager(_dataManager).getDepositAddress(_clientId);
        require(_dataManager != 0x0 && _depositAddress != 0x0 && amount > 0);
         
        require(CurrencyToken(tokenDetails[0x55534470]._token).destroyTokensFrom(amount, _depositAddress) == true);
         
        require(CurrencyToken(tokenDetails[0x55534443]._token).transferFrom(msg.sender, _depositAddress, amount) == true);
         
        require(DataManager(_dataManager).setBlockchainActionData(_blockchainActionId, 0x55534470, amount, _clientId, _depositAddress, 0) == true); 
         
        emit EventUSDpToUSDC(_blockchainActionId, _clientId, amount);
    }

     
    function createAddress(address _dataManager, bytes32 _blockchainActionId, bytes32 clientId) 
        public
        onlyServer
    {   
        require(_dataManager != 0x0);
        DepositContract newDepositContract;
        DepositContract dc;
        if (DataManager(_dataManager).getDepositAddress(clientId) != 0x0) {
            dc = DepositContract(DataManager(_dataManager).getDepositAddress(clientId));
            newDepositContract = new DepositContract(clientId, AM);
            require(!dc.call(bytes4(keccak256("getVersion()")))); 
             
            address PXT = tokenDetails[0x505854]._token;
            address PPT = tokenDetails[0x505054]._token;            
            if(dc.balanceOf(PXT) > 0){
                require(dc.transfer(PXT, newDepositContract, dc.balanceOf(PXT)) == true);
            }
            if(dc.balanceOf(PPT) > 0) {
                require(dc.transfer(PPT, newDepositContract, dc.balanceOf(PPT)) == true);
            }
            require(DataManager(_dataManager)._setDepositAddress(_blockchainActionId, clientId, newDepositContract) == true);
            EventDepositAddressUpgrade(_blockchainActionId, address(dc), DataManager(_dataManager).getDepositAddress(clientId), clientId, newDepositContract.getVersion());
        } else { 
            newDepositContract = new DepositContract(clientId, AM);
            require(DataManager(_dataManager).setDepositAddress(_blockchainActionId, newDepositContract, clientId) == true);
            require(DataManager(_dataManager).setBlockchainActionData(_blockchainActionId, 0x0, 0, clientId, DataManager(_dataManager).getDepositAddress(clientId), 0) == true);
            EventNewDepositContract(_blockchainActionId, clientId, DataManager(_dataManager).getDepositAddress(clientId), newDepositContract.getVersion());
        }
    }

     


     
    function withdrawPoken(
        address _dataManager, bytes32 _blockchainActionId, 
        bytes32 currency, uint256 amount, uint256 amountUSD,
        address from, address to, bytes32 accountId, 
        uint256 inCollateral,
        uint256 pptFee, address adminExternalWallet) 
        public 
        onlyServer 
    {
        require(_dataManager != 0x0);
         
        require(DataManager(_dataManager).getActionStatus(_blockchainActionId) == false && DataManager(_dataManager).getDepositAddress(accountId) != 0x0);
        require(adminExternalWallet != 0x0 && pptFee > 0 && amount > 0);
        require(DataManager(_dataManager).getCurrency(currency) != 0x0);
        DepositContract o = DepositContract(DataManager(_dataManager).getDepositAddress(accountId));
         
        require(SafeMath.safeSub(o.balanceOf(tokenDetails[0x505054]._token), inCollateral) >= pptFee);
        require(o.transfer(tokenDetails[0x505054]._token, adminExternalWallet, pptFee) == true);
         
        if(amount > CurrencyToken(DataManager(_dataManager).getCurrency(currency)).balanceOf(from)) {
             
            require(CurrencyToken(DataManager(_dataManager).getCurrency(currency)).destroyTokensFrom(CurrencyToken(DataManager(_dataManager).getCurrency(currency)).balanceOf(from), from) == true);
             
        } else {
             
            require(CurrencyToken(DataManager(_dataManager).getCurrency(currency)).destroyTokensFrom(amount, from) == true);
             
        }
         
         
        if(amountUSD > 0)  
        {
            CurrencyToken(tokenDetails[0x55534443]._token).transferFrom(msg.sender, to, amountUSD);
        }else {  
            CurrencyToken(DataManager(_dataManager).getCurrency(currency)).transferFrom(msg.sender, to, amount);
        }
        require(DataManager(_dataManager).setBlockchainActionData(_blockchainActionId, currency, amount, accountId, to, pptFee) == true); 
        EventWithdrawPoken(_blockchainActionId, accountId, currency, amount);
    }

         
    function withdrawERC20(
        address _dataManager, bytes32 _blockchainActionId, 
        address pptAddress, bytes32 accountId, 
        address to, uint256 amount, uint256 inCollateral, 
        uint256 pptFee, address adminExternalWallet) 
        public 
        onlyServer 
    {   
        require(_dataManager != 0x0);
        require(DataManager(_dataManager).getActionStatus(_blockchainActionId) == false && DataManager(_dataManager).getDepositAddress(accountId) != 0x0);
        require(adminExternalWallet != 0x0 && pptFee >= 0 && amount > 0);
        address depositContract = DataManager(_dataManager).getDepositAddress(accountId);
        if(pptAddress == tokenDetails[0x505054]._token) {
            uint pptBalance = SafeMath.safeSub(DepositContract(depositContract).balanceOf(tokenDetails[0x505054]._token), inCollateral);
            require(pptBalance >= SafeMath.safeAdd(amount, pptFee));
        } else {
            uint erc20Balance = DepositContract(depositContract).balanceOf(pptAddress);
            require(erc20Balance >= amount);
        }
        require(DepositContract(depositContract).transfer(tokenDetails[0x505054]._token, adminExternalWallet, pptFee) == true);
        require(DepositContract(depositContract).transfer(pptAddress, to, amount) == true);
        bytes32 tokenSymbol = iERC20Token(pptAddress).symbol();    
        require(DataManager(_dataManager).setBlockchainActionData(_blockchainActionId, tokenSymbol, amount, accountId, to, pptFee) == true);
        EventWithdrawPPT(_blockchainActionId, accountId, DataManager(_dataManager).getDepositAddress(accountId), to, amount);
    }

     
 
}