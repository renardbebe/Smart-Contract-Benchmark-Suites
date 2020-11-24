 

pragma solidity ^0.4.25;

 


 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

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


 
contract Zer0netDbInterface {
     
    function getAddress(bytes32 _key) external view returns (address);
    function getBool(bytes32 _key)    external view returns (bool);
    function getBytes(bytes32 _key)   external view returns (bytes);
    function getInt(bytes32 _key)     external view returns (int);
    function getString(bytes32 _key)  external view returns (string);
    function getUint(bytes32 _key)    external view returns (uint);

     
    function setAddress(bytes32 _key, address _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setBytes(bytes32 _key, bytes _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setString(bytes32 _key, string _value) external;
    function setUint(bytes32 _key, uint _value) external;

     
    function deleteAddress(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
}


 
contract ZeroFilters is Owned {
     
    address private _predecessor;

     
    address private _successor;

     
    uint private _revision;

     
    Zer0netDbInterface private _zer0netDb;

     
    string _NAMESPACE = 'zerofilters';

    event Filter(
        bytes32 indexed dataId,
        bytes metadata
    );

     
    constructor() public {
         
        _predecessor = 0x0;

         
        if (_predecessor != 0x0) {
             
            uint lastRevision = ZeroFilters(_predecessor).getRevision();

             
            _revision = lastRevision + 1;
        }

         
         
        _zer0netDb = Zer0netDbInterface(0xE865Fe1A1A3b342bF0E2fcB11fF4E3BCe58263af);
    }

     
    modifier onlyAuthBy0Admin() {
         
        require(_zer0netDb.getBool(keccak256(
            abi.encodePacked(msg.sender, '.has.auth.for.zerofilters'))) == true);

        _;       
    }

     
    function () public payable {
         
        revert('Oops! Direct payments are NOT permitted here.');
    }


     

     
    function calcIdByHash(
        bytes32 _hash
    ) public view returns (bytes32 dataId) {
         
        dataId = keccak256(abi.encodePacked(
            _NAMESPACE, '.hash.', _hash));
    }

     
    function calcIdByHostname(
        string _hostname
    ) external view returns (bytes32 dataId) {
         
        dataId = keccak256(abi.encodePacked(
            _NAMESPACE, '.hostname.', _hostname));
    }

     
    function calcIdByOwner(
        address _owner
    ) external view returns (bytes32 dataId) {
         
        dataId = keccak256(abi.encodePacked(
            _NAMESPACE, '.owner.', _owner));
    }

     
    function calcIdByRegex(
        string _regex
    ) external view returns (bytes32 dataId) {
         
        dataId = keccak256(abi.encodePacked(
            _NAMESPACE, '.regex.', _regex));
    }


     

     
    function getInfo(
        bytes32 _dataId
    ) external view returns (bytes info) {
         
        return _getInfo(_dataId);
    }

     
    function getInfoByHash(
        bytes32 _hash
    ) external view returns (bytes info) {
         
        bytes32 dataId = keccak256(abi.encodePacked(
            _NAMESPACE, '.hash.', _hash));

         
        return _getInfo(dataId);
    }

     
    function getInfoByHostname(
        string _hostname
    ) external view returns (bytes info) {
         
        bytes32 dataId = keccak256(abi.encodePacked(
            _NAMESPACE, '.hostname.', _hostname));

         
        return _getInfo(dataId);
    }

     
    function getInfoByOwner(
        address _owner
    ) external view returns (bytes info) {
         
        bytes32 dataId = keccak256(abi.encodePacked(
            _NAMESPACE, '.owner.', _owner));

         
        return _getInfo(dataId);
    }

     
    function getInfoByRegex(
        string _regex
    ) external view returns (bytes info) {
         
        bytes32 dataId = keccak256(abi.encodePacked(
            _NAMESPACE, '.regex.', _regex));

         
        return _getInfo(dataId);
    }

     
    function _getInfo(
        bytes32 _dataId
    ) private view returns (bytes info) {
         
        info = _zer0netDb.getBytes(_dataId);
    }

     
    function getRevision() public view returns (uint) {
        return _revision;
    }

     
    function getPredecessor() public view returns (address) {
        return _predecessor;
    }

     
    function getSuccessor() public view returns (address) {
        return _successor;
    }


     

     
    function setInfoByHash(
        bytes32 _hash,
        bytes _data
    ) onlyAuthBy0Admin external returns (bool success) {
         
        bytes32 dataId = keccak256(abi.encodePacked(
            _NAMESPACE, '.hash.', _hash));

         
        return _setInfo(dataId, _data);
    }

     
    function setInfoByHostname(
        string _hostname,
        bytes _data
    ) onlyAuthBy0Admin external returns (bool success) {
         
        bytes32 dataId = keccak256(abi.encodePacked(
            _NAMESPACE, '.hostname.', _hostname));

         
        return _setInfo(dataId, _data);
    }

     
    function setInfoByOwner(
        address _owner,
        bytes _data
    ) onlyAuthBy0Admin external returns (bool success) {
         
        bytes32 dataId = keccak256(abi.encodePacked(
            _NAMESPACE, '.owner.', _owner));

         
        return _setInfo(dataId, _data);
    }

     
    function setInfoByRegex(
        string _regex,
        bytes _data
    ) onlyAuthBy0Admin external returns (bool success) {
         
        bytes32 dataId = keccak256(abi.encodePacked(
            _NAMESPACE, '.regex.', _regex));

         
        return _setInfo(dataId, _data);
    }

     
    function _setInfo(
        bytes32 _dataId,
        bytes _data
    ) private returns (bool success) {
         
        _zer0netDb.setBytes(_dataId, _data);

         
        emit Filter(_dataId, _data);

         
        return true;
    }

     
    function setSuccessor(
        address _newSuccessor
    ) onlyAuthBy0Admin external returns (bool success) {
         
        _successor = _newSuccessor;

         
        return true;
    }


     

     
    function supportsInterface(
        bytes4 _interfaceID
    ) external pure returns (bool) {
         
        bytes4 InvalidId = 0xffffffff;
        bytes4 ERC165Id = 0x01ffc9a7;

         
        if (_interfaceID == InvalidId) {
            return false;
        }

         
        if (_interfaceID == ERC165Id) {
            return true;
        }

         

         
        return false;
    }


     

     
    function transferAnyERC20Token(
        address _tokenAddress,
        uint _tokens
    ) public onlyOwner returns (bool success) {
        return ERC20Interface(_tokenAddress).transfer(owner, _tokens);
    }
}