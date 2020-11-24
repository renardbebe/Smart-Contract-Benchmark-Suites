 

pragma solidity ^0.4.24;

contract ERC725 {

    uint256 public constant MANAGEMENT_KEY = 1;
    uint256 public constant ACTION_KEY = 2;
    uint256 public constant CLAIM_SIGNER_KEY = 3;
    uint256 public constant ENCRYPTION_KEY = 4;

    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Approved(uint256 indexed executionId, bool approved);

    struct Key {
        uint256[] purpose;  
        uint256 keyType;  
        bytes32 key;
    }

    function getKey(bytes32 _key) public constant returns(uint256[] purpose, uint256 keyType, bytes32 key);
    function getKeyPurpose(bytes32 _key) public constant returns(uint256[] purpose);
    function getKeysByPurpose(uint256 _purpose) public constant returns(bytes32[] keys);
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) public returns (bool success);
    function removeKey(bytes32 _key, uint256 _purpose) public returns (bool success);
    function execute(address _to, uint256 _value, bytes _data) public returns (uint256 executionId);
    function approve(uint256 _id, bool _approve) public returns (bool success);
}

contract ERC20Basic {
    function balanceOf(address _who) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract Identity is ERC725 {

    uint256 constant LOGIN_KEY = 10;
    uint256 constant FUNDS_MANAGEMENT = 11;

    uint256 executionNonce;

    struct Execution {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }

    mapping (bytes32 => Key) keys;
    mapping (uint256 => bytes32[]) keysByPurpose;
    mapping (uint256 => Execution) executions;

    event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    modifier onlyManagement() {
        require(keyHasPurpose(keccak256(msg.sender), MANAGEMENT_KEY), "Sender does not have management key");
        _;
    }

    modifier onlyAction() {
        require(keyHasPurpose(keccak256(msg.sender), ACTION_KEY), "Sender does not have action key");
        _;
    }

    modifier onlyFundsManagement() {
        require(keyHasPurpose(keccak256(msg.sender), FUNDS_MANAGEMENT), "Sender does not have funds key");
        _;
    }

    constructor() public {
        bytes32 _key = keccak256(msg.sender);
        keys[_key].key = _key;
        keys[_key].purpose = [MANAGEMENT_KEY];
        keys[_key].keyType = 1;
        keysByPurpose[MANAGEMENT_KEY].push(_key);
        emit KeyAdded(_key, MANAGEMENT_KEY, 1);
    }

    function getKey(bytes32 _key)
        public
        view
        returns(uint256[] purpose, uint256 keyType, bytes32 key)
    {
        return (keys[_key].purpose, keys[_key].keyType, keys[_key].key);
    }

    function getKeyPurpose(bytes32 _key)
        public
        view
        returns(uint256[] purpose)
    {
        return (keys[_key].purpose);
    }

    function getKeysByPurpose(uint256 _purpose)
        public
        view
        returns(bytes32[] _keys)
    {
        return keysByPurpose[_purpose];
    }

    function addKey(bytes32 _key, uint256 _purpose, uint256 _type)
        public
        onlyManagement
        returns (bool success)
    {
        if (keyHasPurpose(_key, _purpose)) {
            return true;
        }

        keys[_key].key = _key;
        keys[_key].purpose.push(_purpose);
        keys[_key].keyType = _type;

        keysByPurpose[_purpose].push(_key);

        emit KeyAdded(_key, _purpose, _type);

        return true;
    }

    function approve(uint256 _id, bool _approve)
        public
        onlyAction
        returns (bool success)
    {
        emit Approved(_id, _approve);

        if (_approve == true) {
            executions[_id].approved = true;
            success = executions[_id].to.call(executions[_id].data, 0);
            if (success) {
                executions[_id].executed = true;
                emit Executed(
                    _id,
                    executions[_id].to,
                    executions[_id].value,
                    executions[_id].data
                );
            } else {
                emit ExecutionFailed(
                    _id,
                    executions[_id].to,
                    executions[_id].value,
                    executions[_id].data
                );
            }
            return success;
        } else {
            executions[_id].approved = false;
        }
        return true;
    }

    function execute(address _to, uint256 _value, bytes _data)
        public
        returns (uint256 executionId)
    {
        require(!executions[executionNonce].executed, "Already executed");
        executions[executionNonce].to = _to;
        executions[executionNonce].value = _value;
        executions[executionNonce].data = _data;

        emit ExecutionRequested(executionNonce, _to, _value, _data);

        if (keyHasPurpose(keccak256(msg.sender), ACTION_KEY)) {
            approve(executionNonce, true);
        }

        executionNonce++;
        return executionNonce-1;
    }

    function removeKey(bytes32 _key, uint256 _purpose)
        public
        onlyManagement
        returns (bool success)
    {
        require(keys[_key].key == _key, "No such key");

        if (!keyHasPurpose(_key, _purpose)) {
            return false;
        }

        uint256 arrayLength = keys[_key].purpose.length;
        int index = -1;
        for (uint i = 0; i < arrayLength; i++) {
            if (keys[_key].purpose[i] == _purpose) {
                index = int(i);
                break;
            }
        }

        if (index != -1) {
            keys[_key].purpose[uint(index)] = keys[_key].purpose[arrayLength - 1];
            delete keys[_key].purpose[arrayLength - 1];
            keys[_key].purpose.length--;
        }

        uint256 purposesLen = keysByPurpose[_purpose].length;
        for (uint j = 0; j < purposesLen; j++) {
            if (keysByPurpose[_purpose][j] == _key) {
                keysByPurpose[_purpose][j] = keysByPurpose[_purpose][purposesLen - 1];
                delete keysByPurpose[_purpose][purposesLen - 1];
                keysByPurpose[_purpose].length--;
                break;
            }
        }

        emit KeyRemoved(_key, _purpose, keys[_key].keyType);

        return true;
    }

    function keyHasPurpose(bytes32 _key, uint256 _purpose)
        public
        view
        returns(bool result)
    {
        if (keys[_key].key == 0) return false;
        uint256 arrayLength = keys[_key].purpose.length;
        for (uint i = 0; i < arrayLength; i++) {
            if (keys[_key].purpose[i] == _purpose) {
                return true;
            }
        }
        return false;
    }

    
    function withdraw() public onlyFundsManagement {
        msg.sender.transfer(address(this).balance);
    }

     
    function transferEth(uint _amount, address _account) public onlyFundsManagement {
        require(_amount <= address(this).balance, "Amount should be less than total balance of the contract");
        require(_account != address(0), "must be valid address");
        _account.transfer(_amount);
    }

     
    function getBalance() public view returns(uint)  {
        return address(this).balance;
    }

     
    function getTokenBalance(address _token) public view returns (uint) {
        return ERC20Basic(_token).balanceOf(this);
    }

     
    function withdrawTokens(address _token) public onlyFundsManagement {
        require(_token != address(0));
        ERC20Basic token = ERC20Basic(_token);
        uint balance = token.balanceOf(this);
         
        assert(token.transfer(msg.sender, balance));
    }

     
    function transferTokens(address _token, address _to, uint _amount) public onlyFundsManagement {
        require(_token != address(0));
        require(_to != address(0));
        ERC20Basic token = ERC20Basic(_token);
        uint balance = token.balanceOf(this);
        require(_amount <= balance);
        assert(token.transfer(_to, _amount));
    }

    function () public payable {}

}

contract Encoder {

    function uintToChar(uint8 _uint) internal pure returns(string) {
        byte b = "\x30";  
        if (_uint > 9) {
            b = "\x60";   
            _uint -= 9;
        }
        bytes memory bs = new bytes(1);
        bs[0] = b | byte(_uint);
        return string(bs);
    }

     
    function encodeUInt(uint256 _uint) public pure returns(bytes memory) {
        if (_uint == 0) {
            return abi.encodePacked(uintToChar(0));
        }

        bytes memory result;
        uint256 x = _uint;
        while (x > 0) {
            result = abi.encodePacked(uintToChar(uint8(x % 10)), result);
            x /= 10;
        }
        return result;
    }

     
    function encodeAddress(address _address) public pure returns (bytes memory res) {
        for (uint i = 0; i < 20; i++) {
             
            byte b = byte(uint8(uint(_address) / (2**(8*(19 - i)))));

             
            uint8 high = uint8(b >> 4);
            uint8 low = uint8(b) & 15;

             
            res = abi.encodePacked(res, uintToChar(high), uintToChar(low));
        }
        return res;
    }

     
    function encodeString(string _str) public pure returns (bytes memory) {
        return abi.encodePacked(_str);
    }
}

contract SignatureValidator {

    function doHash(string _message1, uint32 _message2, string _header1, string _header2)
     pure internal returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                    keccak256(abi.encodePacked(_header1, _header2)),
                    keccak256(abi.encodePacked(_message1, _message2)))
        );
    }

     
    function checkSignature(string _message1, uint32 _nonce, string _header1, string _header2, bytes32 _r, bytes32 _s, uint8 _v)
     public pure returns (address) {
        bytes32 hash = doHash(_message1, _nonce, _header1, _header2);
        return ecrecover(hash, _v, _r, _s);
    }

}


 

contract ZincAccessor is SignatureValidator, Encoder {

    uint256 public nonce = 0;

    event UserIdentityCreated(address indexed userAddress, address indexed identityContractAddress);
    event AccessorAdded(address indexed identityContractAddress, address indexed keyAddress, uint256 indexed purpose);
    event AccessorRemoved(address indexed identityContractAddress, address indexed keyAddress, uint256 indexed purpose);

    function checkUserSignature(
        address _userAddress,
        string _message1,
        uint32 _nonce,
        string _header1,
        string _header2,
        bytes32 _r,
        bytes32 _s,
        uint8 _v) 
    pure internal returns (bool) {
        require(
            checkSignature(_message1, _nonce, _header1, _header2, _r, _s, _v) == _userAddress,
            "User signature must be the same as signed message");
        return true;
    }

    modifier checknonce(uint _nonce) {
        require(++nonce == _nonce, "Wrong nonce");
        _;
    }

     
    function constructUserIdentity(
        address _userAddress,
        string _message1,
        uint32 _nonce,
        string _header1,
        string _header2,
        bytes32 _r,
        bytes32 _s,
        uint8 _v)
    public
     returns (address) {
        require(
            checkUserSignature(_userAddress, _message1, _nonce, _header1, _header2, _r, _s, _v),
            "User Signature does not match");

        Identity id = new Identity();
        id.addKey(keccak256(_userAddress), id.MANAGEMENT_KEY(), 1);

        emit UserIdentityCreated(_userAddress, address(id));

        return address(id);
    }

     
    function addAccessor(
        address _key,
        address _idContract,
        uint256 _purpose,
        address _userAddress,
        string _message1,
        uint32 _nonce,
        string _header1,
        string _header2,
        bytes32 _r,
        bytes32 _s,
        uint8 _v)
    public checknonce(_nonce) returns (bool) {
        require(checkUserSignature(_userAddress, _message1, _nonce, _header1, _header2, _r, _s, _v));
        require(
            keccak256(abi.encodePacked("Add 0x", encodeAddress(_key), " to 0x", encodeAddress(_idContract), " with purpose ", encodeUInt(_purpose))) ==
            keccak256(encodeString(_message1)), "Message incorrect");

        Identity id = Identity(_idContract);
        require(id.keyHasPurpose(keccak256(_userAddress), id.MANAGEMENT_KEY()));

        id.addKey(keccak256(_key), _purpose, 1);
        emit AccessorAdded(_idContract, _key, _purpose);
        return true;
    }

     
    function removeAccessor(
        address _key,
        address _idContract,
        uint256 _purpose,
        address _userAddress,
        string _message1,
        uint32 _nonce,
        string _header1,
        string _header2,
        bytes32 _r,
        bytes32 _s,
        uint8 _v)
    public checknonce(_nonce) returns (bool) {
        require(checkUserSignature(_userAddress, _message1, _nonce, _header1, _header2, _r, _s, _v));
        require(
            keccak256(abi.encodePacked("Remove 0x", encodeAddress(_key), " from 0x", encodeAddress(_idContract), " with purpose ", encodeUInt(_purpose))) ==
            keccak256(encodeString(_message1)), "Message incorrect");

        Identity id = Identity(_idContract);
        require(id.keyHasPurpose(keccak256(_userAddress), id.MANAGEMENT_KEY()));

        id.removeKey(keccak256(_key), _purpose);

        emit AccessorRemoved(_idContract, _key, _purpose);
        return true;
    }

}