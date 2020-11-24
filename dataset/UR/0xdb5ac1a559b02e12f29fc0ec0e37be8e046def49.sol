 

pragma solidity ^0.4.24;


 
library MerkleProof {
     
    function verifyProof(
        bytes32[] _proof,
        bytes32 _root,
        bytes32 _leaf
    )
        internal
        pure
        returns (bool)
    {
        bytes32 computedHash = _leaf;

        for (uint256 i = 0; i < _proof.length; i++) {
            bytes32 proofElement = _proof[i];

            if (computedHash < proofElement) {
                 
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                 
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

         
        return computedHash == _root;
    }
}

contract Controlled {
     
     
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

    address public controller;

    constructor() internal { 
        controller = msg.sender; 
    }

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}


 
 

interface ERC20Token {

     
    function transfer(address _to, uint256 _value) external returns (bool success);

     
    function approve(address _spender, uint256 _value) external returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

     
    function balanceOf(address _owner) external view returns (uint256 balance);

     
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

     
    function totalSupply() external view returns (uint256 supply);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

interface ENS {

   
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

   
  event Transfer(bytes32 indexed node, address owner);

   
  event NewResolver(bytes32 indexed node, address resolver);

   
  event NewTTL(bytes32 indexed node, uint64 ttl);


  function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;
  function setResolver(bytes32 node, address resolver) public;
  function setOwner(bytes32 node, address owner) public;
  function setTTL(bytes32 node, uint64 ttl) public;
  function owner(bytes32 node) public view returns (address);
  function resolver(bytes32 node) public view returns (address);
  function ttl(bytes32 node) public view returns (uint64);

}


 
contract PublicResolver {

    bytes4 constant INTERFACE_META_ID = 0x01ffc9a7;
    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant CONTENT_INTERFACE_ID = 0xd8389dc5;
    bytes4 constant NAME_INTERFACE_ID = 0x691f3431;
    bytes4 constant ABI_INTERFACE_ID = 0x2203ab56;
    bytes4 constant PUBKEY_INTERFACE_ID = 0xc8690233;
    bytes4 constant TEXT_INTERFACE_ID = 0x59d1d43c;
    bytes4 constant MULTIHASH_INTERFACE_ID = 0xe89401a1;

    event AddrChanged(bytes32 indexed node, address a);
    event ContentChanged(bytes32 indexed node, bytes32 hash);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexedKey, string key);
    event MultihashChanged(bytes32 indexed node, bytes hash);

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    struct Record {
        address addr;
        bytes32 content;
        string name;
        PublicKey pubkey;
        mapping(string=>string) text;
        mapping(uint256=>bytes) abis;
        bytes multihash;
    }

    ENS ens;

    mapping (bytes32 => Record) records;

    modifier only_owner(bytes32 node) {
        require(ens.owner(node) == msg.sender);
        _;
    }

     
    constructor(ENS ensAddr) public {
        ens = ensAddr;
    }

     
    function setAddr(bytes32 node, address addr) public only_owner(node) {
        records[node].addr = addr;
        emit AddrChanged(node, addr);
    }

     
    function setContent(bytes32 node, bytes32 hash) public only_owner(node) {
        records[node].content = hash;
        emit ContentChanged(node, hash);
    }

     
    function setMultihash(bytes32 node, bytes hash) public only_owner(node) {
        records[node].multihash = hash;
        emit MultihashChanged(node, hash);
    }
    
     
    function setName(bytes32 node, string name) public only_owner(node) {
        records[node].name = name;
        emit NameChanged(node, name);
    }

     
    function setABI(bytes32 node, uint256 contentType, bytes data) public only_owner(node) {
         
        require(((contentType - 1) & contentType) == 0);
        
        records[node].abis[contentType] = data;
        emit ABIChanged(node, contentType);
    }
    
     
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) public only_owner(node) {
        records[node].pubkey = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

     
    function setText(bytes32 node, string key, string value) public only_owner(node) {
        records[node].text[key] = value;
        emit TextChanged(node, key, key);
    }

     
    function text(bytes32 node, string key) public view returns (string) {
        return records[node].text[key];
    }

     
    function pubkey(bytes32 node) public view returns (bytes32 x, bytes32 y) {
        return (records[node].pubkey.x, records[node].pubkey.y);
    }

     
    function ABI(bytes32 node, uint256 contentTypes) public view returns (uint256 contentType, bytes data) {
        Record storage record = records[node];
        for (contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && record.abis[contentType].length > 0) {
                data = record.abis[contentType];
                return;
            }
        }
        contentType = 0;
    }

     
    function name(bytes32 node) public view returns (string) {
        return records[node].name;
    }

     
    function content(bytes32 node) public view returns (bytes32) {
        return records[node].content;
    }

     
    function multihash(bytes32 node) public view returns (bytes) {
        return records[node].multihash;
    }

     
    function addr(bytes32 node) public view returns (address) {
        return records[node].addr;
    }

     
    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == ADDR_INTERFACE_ID ||
        interfaceID == CONTENT_INTERFACE_ID ||
        interfaceID == NAME_INTERFACE_ID ||
        interfaceID == ABI_INTERFACE_ID ||
        interfaceID == PUBKEY_INTERFACE_ID ||
        interfaceID == TEXT_INTERFACE_ID ||
        interfaceID == MULTIHASH_INTERFACE_ID ||
        interfaceID == INTERFACE_META_ID;
    }
}


 
contract UsernameRegistrar is Controlled, ApproveAndCallFallBack {
    
    ERC20Token public token;
    ENS public ensRegistry;
    PublicResolver public resolver;
    address public parentRegistry;

    uint256 public constant releaseDelay = 365 days;
    mapping (bytes32 => Account) public accounts;
    mapping (bytes32 => SlashReserve) reservedSlashers;

     
    uint256 public usernameMinLength;
    bytes32 public reservedUsernamesMerkleRoot;
    
    event RegistryState(RegistrarState state);
    event RegistryPrice(uint256 price);
    event RegistryMoved(address newRegistry);
    event UsernameOwner(bytes32 indexed nameHash, address owner);

    enum RegistrarState { Inactive, Active, Moved }
    bytes32 public ensNode;
    uint256 public price;
    RegistrarState public state;
    uint256 public reserveAmount;

    struct Account {
        uint256 balance;
        uint256 creationTime;
        address owner;
    }

    struct SlashReserve {
        address reserver;
        uint256 blockNumber;
    }

     
    modifier onlyParentRegistry {
        require(msg.sender == parentRegistry, "Migration only.");
        _;
    }

     
    constructor(
        ERC20Token _token,
        ENS _ensRegistry,
        PublicResolver _resolver,
        bytes32 _ensNode,
        uint256 _usernameMinLength,
        bytes32 _reservedUsernamesMerkleRoot,
        address _parentRegistry
    ) 
        public 
    {
        require(address(_token) != address(0), "No ERC20Token address defined.");
        require(address(_ensRegistry) != address(0), "No ENS address defined.");
        require(address(_resolver) != address(0), "No Resolver address defined.");
        require(_ensNode != bytes32(0), "No ENS node defined.");
        token = _token;
        ensRegistry = _ensRegistry;
        resolver = _resolver;
        ensNode = _ensNode;
        usernameMinLength = _usernameMinLength;
        reservedUsernamesMerkleRoot = _reservedUsernamesMerkleRoot;
        parentRegistry = _parentRegistry;
        setState(RegistrarState.Inactive);
    }

     
    function register(
        bytes32 _label,
        address _account,
        bytes32 _pubkeyA,
        bytes32 _pubkeyB
    ) 
        external 
        returns(bytes32 namehash) 
    {
        return registerUser(msg.sender, _label, _account, _pubkeyA, _pubkeyB);
    }
    
     
    function release(
        bytes32 _label
    )
        external 
    {
        bytes32 namehash = keccak256(abi.encodePacked(ensNode, _label));
        Account memory account = accounts[_label];
        require(account.creationTime > 0, "Username not registered.");
        if (state == RegistrarState.Active) {
            require(msg.sender == ensRegistry.owner(namehash), "Not owner of ENS node.");
            require(block.timestamp > account.creationTime + releaseDelay, "Release period not reached.");
        } else {
            require(msg.sender == account.owner, "Not the former account owner.");
        }
        delete accounts[_label];
        if (account.balance > 0) {
            reserveAmount -= account.balance;
            require(token.transfer(msg.sender, account.balance), "Transfer failed");
        }
        if (state == RegistrarState.Active) {
            ensRegistry.setSubnodeOwner(ensNode, _label, address(this));
            ensRegistry.setResolver(namehash, address(0));
            ensRegistry.setOwner(namehash, address(0));
        } else {
            address newOwner = ensRegistry.owner(ensNode);
             
             
            !newOwner.call.gas(80000)(
                abi.encodeWithSignature(
                    "dropUsername(bytes32)",
                    _label
                )
            );
        }
        emit UsernameOwner(namehash, address(0));   
    }

     
    function updateAccountOwner(
        bytes32 _label
    ) 
        external 
    {
        bytes32 namehash = keccak256(abi.encodePacked(ensNode, _label));
        require(msg.sender == ensRegistry.owner(namehash), "Caller not owner of ENS node.");
        require(accounts[_label].creationTime > 0, "Username not registered.");
        require(ensRegistry.owner(ensNode) == address(this), "Registry not owner of registry.");
        accounts[_label].owner = msg.sender;
        emit UsernameOwner(namehash, msg.sender);
    }  

     
    function reserveSlash(bytes32 _secret) external {
        require(reservedSlashers[_secret].blockNumber == 0, "Already Reserved");
        reservedSlashers[_secret] = SlashReserve(msg.sender, block.number);
    }

     
    function slashSmallUsername(
        string _username,
        uint256 _reserveSecret
    ) 
        external 
    {
        bytes memory username = bytes(_username);
        require(username.length < usernameMinLength, "Not a small username.");
        slashUsername(username, _reserveSecret);
    }

     
    function slashAddressLikeUsername(
        string _username,
        uint256 _reserveSecret
    ) 
        external 
    {
        bytes memory username = bytes(_username);
        require(username.length > 12, "Too small to look like an address.");
        require(username[0] == byte("0"), "First character need to be 0");
        require(username[1] == byte("x"), "Second character need to be x");
        for(uint i = 2; i < 7; i++){
            byte b = username[i];
            require((b >= 48 && b <= 57) || (b >= 97 && b <= 102), "Does not look like an address");
        }
        slashUsername(username, _reserveSecret);
    }  

     
    function slashReservedUsername(
        string _username,
        bytes32[] _proof,
        uint256 _reserveSecret
    ) 
        external 
    {   
        bytes memory username = bytes(_username);
        require(
            MerkleProof.verifyProof(
                _proof,
                reservedUsernamesMerkleRoot,
                keccak256(username)
            ),
            "Invalid Proof."
        );
        slashUsername(username, _reserveSecret);
    }

     
    function slashInvalidUsername(
        string _username,
        uint256 _offendingPos,
        uint256 _reserveSecret
    ) 
        external
    { 
        bytes memory username = bytes(_username);
        require(username.length > _offendingPos, "Invalid position.");
        byte b = username[_offendingPos];
        
        require(!((b >= 48 && b <= 57) || (b >= 97 && b <= 122)), "Not invalid character.");
    
        slashUsername(username, _reserveSecret);
    }

     
    function eraseNode(
        bytes32[] _labels
    ) 
        external 
    {
        uint len = _labels.length;
        require(len != 0, "Nothing to erase");
        bytes32 label = _labels[len - 1];
        bytes32 subnode = keccak256(abi.encodePacked(ensNode, label));
        require(ensRegistry.owner(subnode) == address(0), "First slash/release top level subdomain");
        ensRegistry.setSubnodeOwner(ensNode, label, address(this));
        if(len > 1) {
            eraseNodeHierarchy(len - 2, _labels, subnode);
        }
        ensRegistry.setResolver(subnode, 0);
        ensRegistry.setOwner(subnode, 0);
    }

     
    function moveAccount(
        bytes32 _label,
        UsernameRegistrar _newRegistry
    ) 
        external 
    {
        require(state == RegistrarState.Moved, "Wrong contract state");
        require(msg.sender == accounts[_label].owner, "Callable only by account owner.");
        require(ensRegistry.owner(ensNode) == address(_newRegistry), "Wrong update");
        Account memory account = accounts[_label];
        delete accounts[_label];

        token.approve(_newRegistry, account.balance);
        _newRegistry.migrateUsername(
            _label,
            account.balance,
            account.creationTime,
            account.owner
        );
    }

     
    function activate(
        uint256 _price
    ) 
        external
        onlyController
    {
        require(state == RegistrarState.Inactive, "Registry state is not Inactive");
        require(ensRegistry.owner(ensNode) == address(this), "Registry does not own registry");
        price = _price;
        setState(RegistrarState.Active);
        emit RegistryPrice(_price);
    }

     
    function setResolver(
        address _resolver
    ) 
        external
        onlyController
    {
        resolver = PublicResolver(_resolver);
    }

     
    function updateRegistryPrice(
        uint256 _price
    ) 
        external
        onlyController
    {
        require(state == RegistrarState.Active, "Registry not owned");
        price = _price;
        emit RegistryPrice(_price);
    }
  
     
    function moveRegistry(
        UsernameRegistrar _newRegistry
    ) 
        external
        onlyController
    {
        require(_newRegistry != this, "Cannot move to self.");
        require(ensRegistry.owner(ensNode) == address(this), "Registry not owned anymore.");
        setState(RegistrarState.Moved);
        ensRegistry.setOwner(ensNode, _newRegistry);
        _newRegistry.migrateRegistry(price);
        emit RegistryMoved(_newRegistry);
    }

     
    function dropUsername(
        bytes32 _label
    ) 
        external 
        onlyParentRegistry
    {
        require(accounts[_label].creationTime == 0, "Already migrated");
        bytes32 namehash = keccak256(abi.encodePacked(ensNode, _label));
        ensRegistry.setSubnodeOwner(ensNode, _label, address(this));
        ensRegistry.setResolver(namehash, address(0));
        ensRegistry.setOwner(namehash, address(0));
    }

     
    function withdrawExcessBalance(
        address _token,
        address _beneficiary
    )
        external 
        onlyController 
    {
        require(_beneficiary != address(0), "Cannot burn token");
        if (_token == address(0)) {
            _beneficiary.transfer(address(this).balance);
        } else {
            ERC20Token excessToken = ERC20Token(_token);
            uint256 amount = excessToken.balanceOf(address(this));
            if(_token == address(token)){
                require(amount > reserveAmount, "Is not excess");
                amount -= reserveAmount;
            } else {
                require(amount > 0, "No balance");
            }
            excessToken.transfer(_beneficiary, amount);
        }
    }

     
    function withdrawWrongNode(
        bytes32 _domainHash,
        address _beneficiary
    ) 
        external
        onlyController
    {
        require(_beneficiary != address(0), "Cannot burn node");
        require(_domainHash != ensNode, "Cannot withdraw main node");   
        require(ensRegistry.owner(_domainHash) == address(this), "Not owner of this node");   
        ensRegistry.setOwner(_domainHash, _beneficiary);
    }

     
    function getPrice() 
        external 
        view 
        returns(uint256 registryPrice) 
    {
        return price;
    }
    
     
    function getAccountBalance(bytes32 _label)
        external
        view
        returns(uint256 accountBalance) 
    {
        accountBalance = accounts[_label].balance;
    }

     
    function getAccountOwner(bytes32 _label)
        external
        view
        returns(address owner) 
    {
        owner = accounts[_label].owner;
    }

     
    function getCreationTime(bytes32 _label)
        external
        view
        returns(uint256 creationTime) 
    {
        creationTime = accounts[_label].creationTime;
    }

     
    function getExpirationTime(bytes32 _label)
        external
        view
        returns(uint256 releaseTime)
    {
        uint256 creationTime = accounts[_label].creationTime;
        if (creationTime > 0){
            releaseTime = creationTime + releaseDelay;
        }
    }

     
    function getSlashRewardPart(bytes32 _label)
        external
        view
        returns(uint256 partReward)
    {
        uint256 balance = accounts[_label].balance;
        if (balance > 0) {
            partReward = balance / 3;
        }
    }

     
    function receiveApproval(
        address _from,
        uint256 _amount,
        address _token,
        bytes _data
    ) 
        public
    {
        require(_amount == price, "Wrong value");
        require(_token == address(token), "Wrong token");
        require(_token == address(msg.sender), "Wrong call");
        require(_data.length <= 132, "Wrong data length");
        bytes4 sig;
        bytes32 label;
        address account;
        bytes32 pubkeyA;
        bytes32 pubkeyB;
        (sig, label, account, pubkeyA, pubkeyB) = abiDecodeRegister(_data);
        require(
            sig == bytes4(0xb82fedbb),  
            "Wrong method selector"
        );
        registerUser(_from, label, account, pubkeyA, pubkeyB);
    }
   
     
    function migrateUsername(
        bytes32 _label,
        uint256 _tokenBalance,
        uint256 _creationTime,
        address _accountOwner
    )
        external
        onlyParentRegistry
    {
        if (_tokenBalance > 0) {
            require(
                token.transferFrom(
                    parentRegistry,
                    address(this),
                    _tokenBalance
                ), 
                "Error moving funds from old registar."
            );
            reserveAmount += _tokenBalance;
        }
        accounts[_label] = Account(_tokenBalance, _creationTime, _accountOwner);
    }

     
    function migrateRegistry(
        uint256 _price
    ) 
        external
        onlyParentRegistry
    {
        require(state == RegistrarState.Inactive, "Not Inactive");
        require(ensRegistry.owner(ensNode) == address(this), "ENS registry owner not transfered.");
        price = _price;
        setState(RegistrarState.Active);
        emit RegistryPrice(_price);
    }

     
    function registerUser(
        address _owner,
        bytes32 _label,
        address _account,
        bytes32 _pubkeyA,
        bytes32 _pubkeyB
    ) 
        internal 
        returns(bytes32 namehash)
    {
        require(state == RegistrarState.Active, "Registry not active.");
        namehash = keccak256(abi.encodePacked(ensNode, _label));
        require(ensRegistry.owner(namehash) == address(0), "ENS node already owned.");
        require(accounts[_label].creationTime == 0, "Username already registered.");
        accounts[_label] = Account(price, block.timestamp, _owner);
        if(price > 0) {
            require(token.allowance(_owner, address(this)) >= price, "Unallowed to spend.");
            require(
                token.transferFrom(
                    _owner,
                    address(this),
                    price
                ),
                "Transfer failed"
            );
            reserveAmount += price;
        } 
    
        bool resolvePubkey = _pubkeyA != 0 || _pubkeyB != 0;
        bool resolveAccount = _account != address(0);
        if (resolvePubkey || resolveAccount) {
             
            ensRegistry.setSubnodeOwner(ensNode, _label, address(this));
            ensRegistry.setResolver(namehash, resolver);  
            if (resolveAccount) {
                resolver.setAddr(namehash, _account);
            }
            if (resolvePubkey) {
                resolver.setPubkey(namehash, _pubkeyA, _pubkeyB);
            }
            ensRegistry.setOwner(namehash, _owner);
        } else {
             
            ensRegistry.setSubnodeOwner(ensNode, _label, _owner);
        }
        emit UsernameOwner(namehash, _owner);
    }
    
     
    function slashUsername(
        bytes _username,
        uint256 _reserveSecret
    ) 
        internal 
    {
        bytes32 label = keccak256(_username);
        bytes32 namehash = keccak256(abi.encodePacked(ensNode, label));
        uint256 amountToTransfer = 0;
        uint256 creationTime = accounts[label].creationTime;
        address owner = ensRegistry.owner(namehash);
        if(creationTime == 0) {
            require(
                owner != address(0) ||
                ensRegistry.resolver(namehash) != address(0),
                "Nothing to slash."
            );
        } else {
            assert(creationTime != block.timestamp);
            amountToTransfer = accounts[label].balance;
            delete accounts[label];
        }

        ensRegistry.setSubnodeOwner(ensNode, label, address(this));
        ensRegistry.setResolver(namehash, address(0));
        ensRegistry.setOwner(namehash, address(0));
        
        if (amountToTransfer > 0) {
            reserveAmount -= amountToTransfer;
            uint256 partialDeposit = amountToTransfer / 3;
            amountToTransfer = partialDeposit * 2;  
            bytes32 secret = keccak256(abi.encodePacked(namehash, creationTime, _reserveSecret));
            SlashReserve memory reserve = reservedSlashers[secret];
            require(reserve.reserver != address(0), "Not reserved.");
            require(reserve.blockNumber < block.number, "Cannot reveal in same block");
            delete reservedSlashers[secret];

            require(token.transfer(reserve.reserver, amountToTransfer), "Error in transfer.");
        }
        emit UsernameOwner(namehash, address(0));
    }

    function setState(RegistrarState _state) private {
        state = _state;
        emit RegistryState(_state);
    }

     
    function eraseNodeHierarchy(
        uint _idx,
        bytes32[] _labels,
        bytes32 _subnode
    ) 
        private 
    {
         
        ensRegistry.setSubnodeOwner(_subnode, _labels[_idx], address(this));
        bytes32 subnode = keccak256(abi.encodePacked(_subnode, _labels[_idx]));

         
        if (_idx > 0) {
            eraseNodeHierarchy(_idx - 1, _labels, subnode);
        }

         
        ensRegistry.setResolver(subnode, 0);
        ensRegistry.setOwner(subnode, 0);
    }

     
    function abiDecodeRegister(
        bytes _data
    ) 
        private 
        pure 
        returns(
            bytes4 sig,
            bytes32 label,
            address account,
            bytes32 pubkeyA,
            bytes32 pubkeyB
        )
    {
        assembly {
            sig := mload(add(_data, add(0x20, 0)))
            label := mload(add(_data, 36))
            account := mload(add(_data, 68))
            pubkeyA := mload(add(_data, 100))
            pubkeyB := mload(add(_data, 132))
        }
    }
}