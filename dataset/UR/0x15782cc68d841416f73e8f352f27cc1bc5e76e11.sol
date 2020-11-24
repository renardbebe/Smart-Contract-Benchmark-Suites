 

pragma solidity ^0.4.19;

 
interface XCPluginInterface {

     
    function start() external;

     
    function stop() external;

     
    function getStatus() external view returns (bool);

     
    function getPlatformName() external view returns (bytes32);

     
    function setAdmin(address account) external;

     
    function getAdmin() external view returns (address);

     
    function getTokenSymbol() external view returns (bytes32);

     
    function addCaller(address caller) external;

     
    function deleteCaller(address caller) external;

     
    function existCaller(address caller) external view returns (bool);

     
    function getCallers() external view returns (address[]);

     
    function getTrustPlatform() external view returns (bytes32 name);

     
    function addPublicKey(address publicKey) external;

     
    function deletePublicKey(address publicKey) external;

     
    function existPublicKey(address publicKey) external view returns (bool);

     
    function countOfPublicKey() external view returns (uint);

     
    function publicKeys() external view returns (address[]);

     
    function setWeight(uint weight) external;

     
    function getWeight() external view returns (uint);

     
    function voteProposal(address fromAccount, address toAccount, uint value, string txid, bytes sig) external;

     
    function verifyProposal(address fromAccount, address toAccount, uint value, string txid) external view returns (bool, bool);

     
    function commitProposal(string txid) external returns (bool);

     
    function getProposal(string txid) external view returns (bool status, address fromAccount, address toAccount, uint value, address[] voters, uint weight);

     
    function deleteProposal(string txid) external;
}

contract XCPlugin is XCPluginInterface {

     
    struct Admin {
        bool status;
        bytes32 platformName;
        bytes32 tokenSymbol;
        address account;
        string version;
    }

     
    struct Proposal {
        bool status;
        address fromAccount;
        address toAccount;
        uint value;
        address[] voters;
        uint weight;
    }

     
    struct Platform {
        bool status;
        bytes32 name;
        uint weight;
        address[] publicKeys;
        mapping(string => Proposal) proposals;
    }

    Admin private admin;

    address[] private callers;

    Platform private platform;


    constructor() public {
        init();
    }

     
    function init() internal {
         
        admin.status = true;
        admin.platformName = "ETH";
        admin.tokenSymbol = "INK";
        admin.account = msg.sender;
        admin.version = "1.0";
        platform.status = true;
        platform.name = "INK";
        platform.weight = 3;
        platform.publicKeys.push(0x80aa17b21c16620a4d7dd06ec1dcc44190b02ca0);
        platform.publicKeys.push(0xd2e40bb4967b355da8d70be40c277ebcf108063c);
        platform.publicKeys.push(0x1501e0f09498aa95cb0c2f1e3ee51223e5074720);
    }

    function start() onlyAdmin external {
        if (!admin.status) {
            admin.status = true;
        }
    }

    function stop() onlyAdmin external {
        if (admin.status) {
            admin.status = false;
        }
    }

    function getStatus() external view returns (bool) {
        return admin.status;
    }

    function getPlatformName() external view returns (bytes32) {
        return admin.platformName;
    }

    function setAdmin(address account) onlyAdmin nonzeroAddress(account) external {
        if (admin.account != account) {
            admin.account = account;
        }
    }

    function getAdmin() external view returns (address) {
        return admin.account;
    }

    function getTokenSymbol() external view returns (bytes32) {
        return admin.tokenSymbol;
    }

    function addCaller(address caller) onlyAdmin nonzeroAddress(caller) external {
        if (!_existCaller(caller)) {
            callers.push(caller);
        }
    }

    function deleteCaller(address caller) onlyAdmin nonzeroAddress(caller) external {
        for (uint i = 0; i < callers.length; i++) {
            if (callers[i] == caller) {
                if (i != callers.length - 1 ) {
                    callers[i] = callers[callers.length - 1];
                }
                callers.length--;
                return;
            }
        }
    }

    function existCaller(address caller) external view returns (bool) {
        return _existCaller(caller);
    }

    function getCallers() external view returns (address[]) {
        return callers;
    }

    function getTrustPlatform() external view returns (bytes32 name){
        return platform.name;
    }

    function setWeight(uint weight) onlyAdmin external {
        require(weight > 0);
        if (platform.weight != weight) {
            platform.weight = weight;
        }
    }

    function getWeight() external view returns (uint) {
        return platform.weight;
    }

    function addPublicKey(address publicKey) onlyAdmin nonzeroAddress(publicKey) external {
        address[] storage publicKeys = platform.publicKeys;
        for (uint i; i < publicKeys.length; i++) {
            if (publicKey == publicKeys[i]) {
                return;
            }
        }
        publicKeys.push(publicKey);
    }

    function deletePublicKey(address publicKey) onlyAdmin nonzeroAddress(publicKey) external {
        address[] storage publicKeys = platform.publicKeys;
        for (uint i = 0; i < publicKeys.length; i++) {
            if (publicKeys[i] == publicKey) {
                if (i != publicKeys.length - 1 ) {
                    publicKeys[i] = publicKeys[publicKeys.length - 1];
                }
                publicKeys.length--;
                return;
            }
        }
    }

    function existPublicKey(address publicKey) external view returns (bool) {
        return _existPublicKey(publicKey);
    }

    function countOfPublicKey() external view returns (uint){
        return platform.publicKeys.length;
    }

    function publicKeys() external view returns (address[]){
        return platform.publicKeys;
    }

    function voteProposal(address fromAccount, address toAccount, uint value, string txid, bytes sig) opened external {
        bytes32 msgHash = hashMsg(platform.name, fromAccount, admin.platformName, toAccount, value, admin.tokenSymbol, txid,admin.version);
        address publicKey = recover(msgHash, sig);
        require(_existPublicKey(publicKey));
        Proposal storage proposal = platform.proposals[txid];
        if (proposal.value == 0) {
            proposal.fromAccount = fromAccount;
            proposal.toAccount = toAccount;
            proposal.value = value;
        } else {
            require(proposal.fromAccount == fromAccount && proposal.toAccount == toAccount && proposal.value == value);
        }
        changeVoters(publicKey, txid);
    }

    function verifyProposal(address fromAccount, address toAccount, uint value, string txid) external view returns (bool, bool) {
        Proposal storage proposal = platform.proposals[txid];
        if (proposal.status) {
            return (true, (proposal.voters.length >= proposal.weight));
        }
        if (proposal.value == 0) {
            return (false, false);
        }
        require(proposal.fromAccount == fromAccount && proposal.toAccount == toAccount && proposal.value == value);
        return (false, (proposal.voters.length >= platform.weight));
    }

    function commitProposal(string txid) external returns (bool) {
        require((admin.status &&_existCaller(msg.sender)) || msg.sender == admin.account);
        require(!platform.proposals[txid].status);
        platform.proposals[txid].status = true;
        platform.proposals[txid].weight = platform.proposals[txid].voters.length;
        return true;
    }

    function getProposal(string txid) external view returns (bool status, address fromAccount, address toAccount, uint value, address[] voters, uint weight){
        fromAccount = platform.proposals[txid].fromAccount;
        toAccount = platform.proposals[txid].toAccount;
        value = platform.proposals[txid].value;
        voters = platform.proposals[txid].voters;
        status = platform.proposals[txid].status;
        weight = platform.proposals[txid].weight;
        return;
    }

    function deleteProposal(string txid) onlyAdmin external {
        delete platform.proposals[txid];
    }

     

    function hashMsg(bytes32 fromPlatform, address fromAccount, bytes32 toPlatform, address toAccount, uint value, bytes32 tokenSymbol, string txid,string version) internal pure returns (bytes32) {
        return sha256(bytes32ToStr(fromPlatform), ":0x", uintToStr(uint160(fromAccount), 16), ":", bytes32ToStr(toPlatform), ":0x", uintToStr(uint160(toAccount), 16), ":", uintToStr(value, 10), ":", bytes32ToStr(tokenSymbol), ":", txid, ":", version);
    }

    function changeVoters(address publicKey, string txid) internal {
        address[] storage voters = platform.proposals[txid].voters;
        for (uint i = 0; i < voters.length; i++) {
            if (voters[i] == publicKey) {
                return;
            }
        }
        voters.push(publicKey);
    }

    function bytes32ToStr(bytes32 b) internal pure returns (string) {
        uint length = b.length;
        for (uint i = 0; i < b.length; i++) {
            if (b[b.length - 1 - i] != "") {
                length -= i;
                break;
            }
        }
        bytes memory bs = new bytes(length);
        for (uint j = 0; j < length; j++) {
            bs[j] = b[j];
        }
        return string(bs);
    }

    function uintToStr(uint value, uint base) internal pure returns (string) {
        uint _value = value;
        uint length = 0;
        bytes16 tenStr = "0123456789abcdef";
        while (true) {
            if (_value > 0) {
                length ++;
                _value = _value / base;
            } else {
                break;
            }
        }
        if (base == 16) {
            length = 40;
        }
        bytes memory bs = new bytes(length);
        for (uint i = 0; i < length; i++) {
            bs[length - 1 - i] = tenStr[value % base];
            value = value / base;
        }
        return string(bs);
    }

    function _existCaller(address caller) internal view returns (bool) {
        for (uint i = 0; i < callers.length; i++) {
            if (callers[i] == caller) {
                return true;
            }
        }
        return false;
    }

    function _existPublicKey(address publicKey) internal view returns (bool) {
        address[] memory publicKeys = platform.publicKeys;
        for (uint i = 0; i < publicKeys.length; i++) {
            if (publicKeys[i] == publicKey) {
                return true;
            }
        }
        return false;
    }

    function recover(bytes32 hash, bytes sig) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        return ecrecover(hash, v, r, s);
    }

    modifier onlyAdmin {
        require(admin.account == msg.sender);
        _;
    }

    modifier nonzeroAddress(address account) {
        require(account != address(0));
        _;
    }

    modifier opened() {
        require(admin.status);
        _;
    }
}