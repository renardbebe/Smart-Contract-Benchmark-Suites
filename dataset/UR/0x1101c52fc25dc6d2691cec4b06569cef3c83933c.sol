 

 

pragma solidity ^0.5.12;


contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner() {
        require(msg.sender == _owner, "The owner should be the sender");
        _;
    }

    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0x0), msg.sender);
    }

    function owner() external view returns (address) {
        return _owner;
    }

     
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "0x0 Is not a valid owner");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}

 

pragma solidity ^0.5.12;


library Math {
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

 

pragma solidity 0.5.12;



 
library SortedList {
    using SortedList for SortedList.List;

    uint256 private constant HEAD = 0;

    struct List {
        uint256 size;
        mapping(uint256 => uint256) values;
        mapping(uint256 => uint256) links;
        mapping(uint256 => bool) exists;
    }

     
    function get(List storage self, uint256 _node) internal view returns (uint256) {
        return self.values[_node];
    }

     
    function set(List storage self, uint256 _node, uint256 _value) internal {
         
        if (self.exists[_node]) {

             
            (uint256 leftOldPos, uint256 leftNewPos) = self.findOldAndNewLeftPosition(_node, _value);

             
            if (leftOldPos != leftNewPos && _node != leftNewPos) {
                 
                self.links[leftOldPos] = self.links[_node];

                 
                uint256 next = self.links[leftNewPos];
                self.links[leftNewPos] = _node;
                self.links[_node] = next;
            }
        } else {
             
            self.size = self.size + 1;
             
            self.exists[_node] = true;
             
            uint256 leftPosition = self.findLeftPosition(_value);
            uint256 next = self.links[leftPosition];
            self.links[leftPosition] = _node;
            self.links[_node] = next;
        }

         
        self.values[_node] = _value;
    }

     
    function findOldAndNewLeftPosition(
        List storage self,
        uint256 _node,
        uint256 _value
    ) internal view returns (
        uint256 leftNodePos,
        uint256 leftValPos
    ) {
         
        bool foundNode;
        bool foundVal;

         
        uint256 c = HEAD;
        while (!foundNode || !foundVal) {
            uint256 next = self.links[c];

             
             
            if (next == 0) {
                leftValPos = c;
                break;
            }

             
             
            if (next == _node) {
                leftNodePos = c;
                foundNode = true;
            }

             
             
            if (self.values[next] > _value && !foundVal) {
                leftValPos = c;
                foundVal = true;
            }

            c = next;
        }
    }

     
    function findLeftPosition(List storage self, uint256 _value) internal view returns (uint256) {
        uint256 next = HEAD;
        uint256 c;

        do {
            c = next;
            next = self.links[c];
        } while(self.values[next] < _value && next != 0);

        return c;
    }

     
    function nodeAt(List storage self, uint256 _position) internal view returns (uint256) {
        uint256 next = self.links[HEAD];
        for (uint256 i = 0; i < _position; i++) {
            next = self.links[next];
        }

        return next;
    }

     
    function remove(List storage self, uint256 _node) internal {
        require(self.exists[_node], "the node does not exists");

        uint256 c = self.links[HEAD];
        while (c != 0) {
            uint256 next = self.links[c];
            if (next == _node) {
                break;
            }

            c = next;
        }

        self.size -= 1;
        self.exists[_node] = false;
        self.links[c] = self.links[_node];
        delete self.links[_node];
        delete self.values[_node];
    }

     
    function median(List storage self) internal view returns (uint256) {
        uint256 elements = self.size;
        if (elements % 2 == 0) {
            uint256 node = self.nodeAt(elements / 2 - 1);
            return Math.average(self.values[node], self.values[self.links[node]]);
        } else {
            return self.values[self.nodeAt(elements / 2)];
        }
    }
}

 

pragma solidity ^0.5.12;


 
contract RateOracle {
    uint256 public constant VERSION = 5;
    bytes4 internal constant RATE_ORACLE_INTERFACE = 0xa265d8e0;

     
    function symbol() external view returns (string memory);

     
    function name() external view returns (string memory);

     
    function decimals() external view returns (uint256);

     
    function token() external view returns (address);

     
    function currency() external view returns (bytes32);

     
    function maintainer() external view returns (string memory);

     
    function url() external view returns (string memory);

     
    function readSample(bytes calldata _data) external view returns (uint256 _tokens, uint256 _equivalent);
}

 

pragma solidity ^0.5.12;


interface PausedProvider {
    function isPaused() external view returns (bool);
}

 

pragma solidity ^0.5.12;



contract Pausable is Ownable {
    mapping(address => bool) public canPause;
    bool public paused;

    event Paused();
    event Started();
    event CanPause(address _pauser, bool _enabled);

    function setPauser(address _pauser, bool _enabled) external onlyOwner {
        canPause[_pauser] = _enabled;
        emit CanPause(_pauser, _enabled);
    }

    function pause() external {
        require(!paused, "already paused");

        require(
            msg.sender == _owner ||
            canPause[msg.sender],
            "not authorized to pause"
        );

        paused = true;
        emit Paused();
    }

    function start() external onlyOwner {
        require(paused, "not paused");
        paused = false;
        emit Started();
    }
}

 

pragma solidity ^0.5.12;


library StringUtils {
    function toBytes32(string memory _a) internal pure returns (bytes32 b) {
        require(bytes(_a).length <= 32, "string too long");

        assembly {
            let bi := mul(mload(_a), 8)
            b := and(mload(add(_a, 32)), shl(sub(256, bi), sub(exp(2, bi), 1)))
        }
    }
}

 

pragma solidity ^0.5.12;









contract MultiSourceOracle is RateOracle, Ownable, Pausable {
    using SortedList for SortedList.List;
    using StringUtils for string;

    uint256 public constant BASE = 10 ** 36;

    mapping(address => bool) public isSigner;
    mapping(address => string) public nameOfSigner;
    mapping(string => address) public signerWithName;

    SortedList.List private list;
    RateOracle public upgrade;
    PausedProvider public pausedProvider;

    string private isymbol;
    string private iname;
    uint256 private idecimals;
    address private itoken;
    bytes32 private icurrency;
    string private imaintainer;

    constructor(
        string memory _symbol,
        string memory _name,
        uint256 _decimals,
        address _token,
        string memory _maintainer
    ) public {
         
        bytes32 currency = _symbol.toBytes32();
         
        isymbol = _symbol;
        iname = _name;
        idecimals = _decimals;
        itoken = _token;
        icurrency = currency;
        imaintainer = _maintainer;
        pausedProvider = PausedProvider(msg.sender);
    }

    function providedBy(address _signer) external view returns (uint256) {
        return list.get(uint256(_signer));
    }

     
    function symbol() external view returns (string memory) {
        return isymbol;
    }

     
    function name() external view returns (string memory) {
        return iname;
    }

     
    function decimals() external view returns (uint256) {
        return idecimals;
    }

     
    function token() external view returns (address) {
        return itoken;
    }

     
    function currency() external view returns (bytes32) {
        return icurrency;
    }

     
    function maintainer() external view returns (string memory) {
        return imaintainer;
    }

     
    function url() external view returns (string memory) {
        return "";
    }

     
    function setMetadata(
        string calldata _name,
        uint256 _decimals,
        string calldata _maintainer
    ) external onlyOwner {
        iname = _name;
        idecimals = _decimals;
        imaintainer = _maintainer;
    }

     
    function setUpgrade(RateOracle _upgrade) external onlyOwner {
        upgrade = _upgrade;
    }

     
    function addSigner(address _signer, string calldata _name) external onlyOwner {
        require(!isSigner[_signer], "signer already defined");
        require(signerWithName[_name] == address(0), "name already in use");
        require(bytes(_name).length > 0, "name can't be empty");
        isSigner[_signer] = true;
        signerWithName[_name] = _signer;
        nameOfSigner[_signer] = _name;
    }

     
    function setName(address _signer, string calldata _name) external onlyOwner {
        require(isSigner[_signer], "signer not defined");
        require(signerWithName[_name] == address(0), "name already in use");
        require(bytes(_name).length > 0, "name can't be empty");
        string memory oldName = nameOfSigner[_signer];
        signerWithName[oldName] = address(0);
        signerWithName[_name] = _signer;
        nameOfSigner[_signer] = _name;
    }

     
    function removeSigner(address _signer) external onlyOwner {
        require(isSigner[_signer], "address is not a signer");
        string memory signerName = nameOfSigner[_signer];

        isSigner[_signer] = false;
        signerWithName[signerName] = address(0);
        nameOfSigner[_signer] = "";

         
        if (list.exists[uint256(_signer)]) {
            list.remove(uint256(_signer));
        }
    }

     
    function provide(address _signer, uint256 _rate) external onlyOwner {
        require(isSigner[_signer], "signer not valid");
        require(_rate != 0, "rate can't be zero");
        list.set(uint256(_signer), _rate);
    }

     
    function readSample(bytes memory _oracleData) public view returns (uint256 _tokens, uint256 _equivalent) {
         
        require(!paused && !pausedProvider.isPaused(), "contract paused");

         
        RateOracle _upgrade = upgrade;
        if (address(_upgrade) != address(0)) {
            return _upgrade.readSample(_oracleData);
        }

         
        _tokens = BASE;
        _equivalent = list.median();
    }

     
    function readSample() external view returns (uint256 _tokens, uint256 _equivalent) {
        (_tokens, _equivalent) = readSample(new bytes(0));
    }
}

 

pragma solidity ^0.5.12;







contract OracleFactory is Ownable, Pausable, PausedProvider {
    mapping(string => address) public symbolToOracle;
    mapping(address => string) public oracleToSymbol;

    event NewOracle(
        string _symbol,
        address _oracle,
        string _name,
        uint256 _decimals,
        address _token,
        string _maintainer
    );

    event Upgraded(
        address indexed _oracle,
        address _new
    );

    event AddSigner(
        address indexed _oracle,
        address _signer,
        string _name
    );

    event RemoveSigner(
        address indexed _oracle,
        address _signer
    );

    event UpdateSignerName(
        address indexed _oracle,
        address _signer,
        string _newName
    );

    event UpdatedMetadata(
        address indexed _oracle,
        string _name,
        uint256 _decimals,
        string _maintainer
    );

    event Provide(
        address indexed _oracle,
        address _signer,
        uint256 _rate
    );

    event OraclePaused(
        address indexed _oracle,
        address _pauser
    );

    event OracleStarted(
        address indexed _oracle
    );

     
    function newOracle(
        string calldata _symbol,
        string calldata _name,
        uint256 _decimals,
        address _token,
        string calldata _maintainer
    ) external onlyOwner {
         
        require(symbolToOracle[_symbol] == address(0), "Oracle already exists");
         
        MultiSourceOracle oracle = new MultiSourceOracle(
            _symbol,
            _name,
            _decimals,
            _token,
            _maintainer
        );
         
        assert(bytes(oracleToSymbol[address(oracle)]).length == 0);
         
        symbolToOracle[_symbol] = address(oracle);
        oracleToSymbol[address(oracle)] = _symbol;
         
        emit NewOracle(
            _symbol,
            address(oracle),
            _name,
            _decimals,
            _token,
            _maintainer
        );
    }

     
    function isPaused() external view returns (bool) {
        return paused;
    }

     
    function addSigner(address _oracle, address _signer, string calldata _name) external onlyOwner {
        MultiSourceOracle(_oracle).addSigner(_signer, _name);
        emit AddSigner(_oracle, _signer, _name);
    }

     
    function addSignerToOracles(
        address[] calldata _oracles,
        address _signer,
        string calldata _name
    ) external onlyOwner {
        for (uint256 i = 0; i < _oracles.length; i++) {
            address oracle = _oracles[i];
            MultiSourceOracle(oracle).addSigner(_signer, _name);
            emit AddSigner(oracle, _signer, _name);
        }
    }

     
    function setName(address _oracle, address _signer, string calldata _name) external onlyOwner {
        MultiSourceOracle(_oracle).setName(_signer, _name);
        emit UpdateSignerName(
            _oracle,
            _signer,
            _name
        );
    }

     
    function removeSigner(address _oracle, address _signer) external onlyOwner {
        MultiSourceOracle(_oracle).removeSigner(_signer);
        emit RemoveSigner(_oracle, _signer);
    }


     
    function removeSignerFromOracles(
        address[] calldata _oracles,
        address _signer
    ) external onlyOwner {
        for (uint256 i = 0; i < _oracles.length; i++) {
            address oracle = _oracles[i];
            MultiSourceOracle(oracle).removeSigner(_signer);
            emit RemoveSigner(oracle, _signer);
        }
    }

     
    function provide(address _oracle, uint256 _rate) external {
        MultiSourceOracle(_oracle).provide(msg.sender, _rate);
        emit Provide(_oracle, msg.sender, _rate);
    }

     
    function provideMultiple(
        address[] calldata _oracles,
        uint256[] calldata _rates
    ) external {
        uint256 length = _oracles.length;
        require(length == _rates.length, "arrays should have the same size");

        for (uint256 i = 0; i < length; i++) {
            address oracle = _oracles[i];
            uint256 rate = _rates[i];
            MultiSourceOracle(oracle).provide(msg.sender, rate);
            emit Provide(oracle, msg.sender, rate);
        }
    }

     
    function setUpgrade(address _oracle, address _upgrade) external onlyOwner {
        MultiSourceOracle(_oracle).setUpgrade(RateOracle(_upgrade));
        emit Upgraded(_oracle, _upgrade);
    }

     
    function pauseOracle(address _oracle) external {
        require(
            canPause[msg.sender] ||
            msg.sender == _owner,
            "not authorized to pause"
        );

        MultiSourceOracle(_oracle).pause();
        emit OraclePaused(_oracle, msg.sender);
    }

     
    function startOracle(address _oracle) external onlyOwner {
        MultiSourceOracle(_oracle).start();
        emit OracleStarted(_oracle);
    }

     
    function setMetadata(
        address _oracle,
        string calldata _name,
        uint256 _decimals,
        string calldata _maintainer
    ) external onlyOwner {
        MultiSourceOracle(_oracle).setMetadata(
            _name,
            _decimals,
            _maintainer
        );

        emit UpdatedMetadata(
            _oracle,
            _name,
            _decimals,
            _maintainer
        );
    }
}