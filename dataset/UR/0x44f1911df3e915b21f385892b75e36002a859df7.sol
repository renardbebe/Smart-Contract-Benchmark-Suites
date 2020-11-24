 

pragma solidity ^0.5.10;

 
 

contract Ed25519 {
    uint constant q = 2 ** 255 - 19;
    uint constant d = 37095705934669439343138083508754565189542113879843219016388785533085940283555;
                       
    uint constant Bx = 15112221349535400772501151409588531511454012693041857206046113283949847762202;
    uint constant By = 46316835694926478169428394003475163141307993866256225615783033603165251855960;

    struct Point {
        uint x;
        uint y;
        uint z;
    }

    struct Scratchpad {
        uint a;
        uint b;
        uint c;
        uint d;
        uint e;
        uint f;
        uint g;
        uint h;
    }

    function inv(uint a) internal view returns (uint invA) {
        uint e = q - 2;
        uint m = q;

         
        assembly {
            let p := mload(0x40)
            mstore(p, 0x20)
            mstore(add(p, 0x20), 0x20)
            mstore(add(p, 0x40), 0x20)
            mstore(add(p, 0x60), a)
            mstore(add(p, 0x80), e)
            mstore(add(p, 0xa0), m)
            if iszero(staticcall(not(0), 0x05, p, 0xc0, p, 0x20)) {
                revert(0, 0)
            }
            invA := mload(p)
        }
    }

    function ecAdd(Point memory p1,
                   Point memory p2) internal pure returns (Point memory p3) {
        Scratchpad memory tmp;

        tmp.a = mulmod(p1.z, p2.z, q);
        tmp.b = mulmod(tmp.a, tmp.a, q);
        tmp.c = mulmod(p1.x, p2.x, q);
        tmp.d = mulmod(p1.y, p2.y, q);
        tmp.e = mulmod(d, mulmod(tmp.c, tmp.d, q), q);
        tmp.f = addmod(tmp.b, q - tmp.e, q);
        tmp.g = addmod(tmp.b, tmp.e, q);
        p3.x = mulmod(mulmod(tmp.a, tmp.f, q),
                      addmod(addmod(mulmod(addmod(p1.x, p1.y, q),
                                           addmod(p2.x, p2.y, q), q),
                                    q - tmp.c, q), q - tmp.d, q), q);
        p3.y = mulmod(mulmod(tmp.a, tmp.g, q),
                      addmod(tmp.d, tmp.c, q), q);
        p3.z = mulmod(tmp.f, tmp.g, q);
    }

    function ecDouble(Point memory p1) internal pure returns (Point memory p2) {
        Scratchpad memory tmp;

        tmp.a = addmod(p1.x, p1.y, q);
        tmp.b = mulmod(tmp.a, tmp.a, q);
        tmp.c = mulmod(p1.x, p1.x, q);
        tmp.d = mulmod(p1.y, p1.y, q);
        tmp.e = q - tmp.c;
        tmp.f = addmod(tmp.e, tmp.d, q);
        tmp.h = mulmod(p1.z, p1.z, q);
        tmp.g = addmod(tmp.f, q - mulmod(2, tmp.h, q), q);
        p2.x = mulmod(addmod(addmod(tmp.b, q - tmp.c, q), q - tmp.d, q),
                      tmp.g, q);
        p2.y = mulmod(tmp.f, addmod(tmp.e, q - tmp.d, q), q);
        p2.z = mulmod(tmp.f, tmp.g, q);
    }

    function scalarMultBase(uint s) public view returns (uint, uint) {
        Point memory b;
        Point memory result;
        b.x = Bx;
        b.y = By;
        b.z = 1;
        result.x = 0;
        result.y = 1;
        result.z = 1;

        while (s > 0) {
            if (s & 1 == 1) { result = ecAdd(result, b); }
            s = s >> 1;
            b = ecDouble(b);
        }

        uint invZ = inv(result.z);
        result.x = mulmod(result.x, invZ, q);
        result.y = mulmod(result.y, invZ, q);

        return (result.x, result.y);
    }
}

contract Hub is Ed25519 {
    address payable constant BLACK_HOLE = 0x0000000000000000000000000000000000000000;
    uint constant DEPOSIT_DURATION = 2 hours;
    uint constant DEPOSIT_DURATION_MARGIN = 30 minutes;

    struct AntiSpamFee {
        uint fee;
        uint blockNumber;
    }

    struct Deposit {
        address sender;
        address recipient;
        uint adaptorPubKey;
        uint value;
        uint blockNumber;
        uint deadline;
    }

    struct Server {
        string target;
        bytes cert;
        uint timestamp;
    }

    mapping(bytes32 => AntiSpamFee) public antiSpamFees;
    mapping(bytes32 => Deposit) public deposits;
    mapping(uint => uint) public adaptorPrivKeys;

    mapping(uint => Server) public servers;
    uint public nextServerID = 0;

    string public version = "0.1.0";
    bool public deprecated = false;
    address public admin;

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    constructor() public {
        admin = msg.sender;
    }

    function burnAntiSpamFee(bytes32 hashedID) external payable {
        antiSpamFees[hashedID].fee += msg.value;
        antiSpamFees[hashedID].blockNumber = block.number;
        BLACK_HOLE.transfer(msg.value);
    }

    function checkAntiSpamConfirmations(uint id, uint fee) external view returns (uint) {
        bytes32 hashedID = hash(id);

        if (antiSpamFees[hashedID].fee < fee) {
            return 0;
        } else {
            return block.number - antiSpamFees[hashedID].blockNumber;
        }
    }

    function depositEther(address recipient, uint adaptorPubKey, bytes32 hashedAntiSpamID) external payable {
        require(deposits[hashedAntiSpamID].blockNumber == 0);

        deposits[hashedAntiSpamID].sender = msg.sender;
        deposits[hashedAntiSpamID].recipient = recipient;
        deposits[hashedAntiSpamID].adaptorPubKey = adaptorPubKey;
        deposits[hashedAntiSpamID].value = msg.value;
        deposits[hashedAntiSpamID].blockNumber = block.number;
        deposits[hashedAntiSpamID].deadline = now + DEPOSIT_DURATION;
    }

    function checkDepositConfirmations(address recipient, uint adaptorPubKey,
                                       uint value, bytes32 hashedAntiSpamID) external view returns (uint) {
        if (deposits[hashedAntiSpamID].recipient != recipient ||
            deposits[hashedAntiSpamID].adaptorPubKey != adaptorPubKey ||
            deposits[hashedAntiSpamID].value < value ||
            deposits[hashedAntiSpamID].deadline - DEPOSIT_DURATION_MARGIN < now) {
            return 0;
        } else {
            return block.number - deposits[hashedAntiSpamID].blockNumber;
        }
    }

    function claimDeposit(uint adaptorPrivKey, uint antiSpamID) external {
        bytes32 hashedAntiSpamID = hash(antiSpamID);
        require(deposits[hashedAntiSpamID].deadline >= now);
        require(deposits[hashedAntiSpamID].recipient == msg.sender);
        require(adaptorPrivKey != 0);

        (, uint adaptorPubKey) = scalarMultBase(adaptorPrivKey);     
        require(deposits[hashedAntiSpamID].adaptorPubKey == adaptorPubKey);
        adaptorPrivKeys[adaptorPubKey] = adaptorPrivKey;

        uint value = deposits[hashedAntiSpamID].value;
        delete deposits[hashedAntiSpamID];
        delete antiSpamFees[hashedAntiSpamID];
        msg.sender.transfer(value);
    }

    function reclaimDeposit(bytes32 hashedAntiSpamID) external {
        require(deposits[hashedAntiSpamID].deadline < now);
        require(deposits[hashedAntiSpamID].sender == msg.sender);

        uint value = deposits[hashedAntiSpamID].value;
        delete deposits[hashedAntiSpamID];
        delete antiSpamFees[hashedAntiSpamID];
        msg.sender.transfer(value);
    }

    function registerServer(string calldata target, bytes calldata cert) external {
        servers[nextServerID].target = target;
        servers[nextServerID].cert = cert;
        servers[nextServerID].timestamp = now;
        nextServerID += 1;
    }

    function fetchServer(uint maxAge,
                         uint offset) external view
                         returns (bool, string memory, bytes memory) {
        if (offset >= nextServerID) {
            return (false, "", "");
        }

        uint id = nextServerID - offset - 1;
        if (servers[id].timestamp + maxAge < now) {
            return (false, "", "");
        }

        return (true, servers[id].target, servers[id].cert);
    }

    function hash(uint id) public pure returns (bytes32) {
        return sha256(abi.encode(id));
    }

    function setVersion(string calldata _version) external onlyAdmin {
        version = _version;
    }

    function setDeprecated(bool _deprecated) external onlyAdmin {
        deprecated = _deprecated;
    }
}