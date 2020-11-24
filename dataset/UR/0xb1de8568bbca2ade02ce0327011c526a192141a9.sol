 

pragma solidity ^0.5.9;

 

 
 

interface Resolver {
    function addr(bytes32 node) external view returns (address);
    function setAddr(bytes32 node, address addr) external;
}

interface ReverseRegistrar {
    function claim(address owner) external returns (bytes32 node);
}

interface AbstractENS {
    function owner(bytes32 node) external view returns(address);
    function setOwner(bytes32 node, address owner) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function resolver(bytes32 node) view external returns (address);
}


 
 

interface IERC721Receiver {
    function onERC721Received(address operator,
                              address from,
                              uint256 tokenId,
                              bytes calldata data) external returns (bytes4);
}


 
 

contract TakoyakiRegistrar {

     
     

     
    bytes32 constant NODE_RR = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

     
     
    uint48 constant MIN_COMMIT_BLOCKS   = (60 / 15);              
    uint48 constant MAX_COMMIT_BLOCKS   = (24 * 60 * 60 / 15);    
    uint48 constant WAIT_CANCEL_BLOCKS  = (60 * 60 / 15);         


     
     
    uint48 constant REGISTRATION_PERIOD    = (366 days);          
    uint48 constant GRACE_PERIOD           = (30 days);           


     
     

    struct Commitment {
         
        uint48 blockNumber;

         
        address payable payer;
        uint256 feePaid;
    }

    struct Takoyaki {
        uint48 expires;
        uint48 commitBlockNumber;
        uint48 revealBlockNumber;
        address owner;
        address approved;
        uint256 upkeepFee;
        bytes32 revealedSalt;
    }


     
     

     
    event Committed(address indexed funder, bytes32 commitment);
    event Cancelled(address indexed funder, bytes32 commitment);
    event Registered(address indexed owner, uint256 indexed tokenId, string label, uint48 expires);
    event Renewed(address indexed owner, uint256 indexed tokenId, uint48 expires);

     
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


     
     

     
    address payable private _admin;

     
    AbstractENS private _ens;
    bytes32 private _nodehash;
    Resolver private _defaultResolver;

     
    uint256 private _fee = (0.1 ether);

     
    mapping (bytes32 => Commitment) private _commitments;

     
    mapping (uint256 => Takoyaki) private _takoyaki;

     
    mapping (address => uint256) private _balances;

     
    mapping (address => mapping (address => bool)) private _approveAll;

    uint256 private _totalSupply = 0;


     
     

    constructor(address ens, bytes32 nodehash, address defaultResolver) public {
        _ens = AbstractENS(ens);
        _nodehash = nodehash;
        _defaultResolver = Resolver(defaultResolver);

        _admin = msg.sender;

         
        ReverseRegistrar(_ens.owner(NODE_RR)).claim(_admin);
    }

     
     

    function setAdmin(address payable newAdmin) external {
        require(msg.sender == _admin);
        _admin = newAdmin;

         
        ReverseRegistrar(_ens.owner(NODE_RR)).claim(_admin);
    }

    function setFee(uint newFee) external {
        require(msg.sender == _admin);
        _fee = newFee;
    }

    function setResolver(address newResolver) external {
        require(msg.sender == _admin);
        _defaultResolver = Resolver(newResolver);
    }

    function withdraw(uint256 amount) external {
        require(msg.sender == _admin);
        _admin.transfer(amount);
    }


     
     

    function ens() external view returns (address) { return address(_ens); }
    function nodehash() external view returns (bytes32) { return _nodehash; }

    function admin() external view returns (address) { return _admin; }
    function defaultResolver() external view returns (address) { return address(_defaultResolver); }
    function fee() external view returns (uint256) { return _fee; }

     
    function totalSupply() external view returns (uint256) { return _totalSupply; }
    function name() external pure returns (string memory) { return "Takoyaki"; }
    function symbol() external pure returns (string memory) { return "TAKO"; }
    function decimals() external pure returns (uint8) { return 0; }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        Takoyaki memory takoyaki = _takoyaki[_tokenId];
        require(takoyaki.expires > now);

        string memory uri = "https://takoyaki.cafe/json/_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-";

         
         
         
        uint offset = 0;
        assembly { offset := add(uri, 59) }

         
        uint hexLut = 0x3031323334353637383961626364656667000000000000000000000000000000;

        for (uint i = 0; i < 32; i++) {
            assembly {
                let value := byte(i, _tokenId)

                mstore8(offset, byte(shr(4, value), hexLut))
                offset := add(offset, 1)

                mstore8(offset, byte(and(value, 0x0f), hexLut))
                offset := add(offset, 1)
            }
        }

        return uri;
    }

     
     

    function fee(string calldata label) external view returns (uint256) {
        require(isValidLabel(label));
        return _fee;
    }

     
     
     
     
    function isValidLabel(string memory label) public pure returns (bool) {
        bytes memory data = bytes(label);

         
        if (data.length < 1 || data.length > 20) { return false; }

         
        if (data.length >= 2 && data[0] == 0x30 && (data[1] | 0x20) == 0x78) {
            return false;
        }

        return true;
    }


     
     

    function makeBlindedCommitment(string memory label, address owner, bytes32 salt) public view returns (bytes32) {
        return keccak256(abi.encode(label, owner, salt));
    }

    function getBlindedCommit(bytes32 blindedCommit) public view returns (uint48 blockNumber, address payer, uint256 feePaid) {
        Commitment memory commitment = _commitments[blindedCommit];
        return (commitment.blockNumber, commitment.payer, commitment.feePaid);
    }

    function commit(bytes32 blindedCommit, address payable prefundRevealer, uint prefundAmount) external payable {
        require(msg.value == _fee + prefundAmount);

        Commitment storage commitment = _commitments[blindedCommit];
        require(commitment.payer == address(0));

        commitment.blockNumber = uint48(block.number);

        commitment.payer = msg.sender;
        commitment.feePaid = _fee;

        if (prefundAmount > 0) {
            prefundRevealer.transfer(prefundAmount);
        }

        emit Committed(msg.sender, blindedCommit);
    }

     
     
     
     
     
    function cancelCommitment(bytes32 blindedCommit) external {
        Commitment memory commitment = _commitments[blindedCommit];
        require(commitment.feePaid <= address(this).balance);
        require(commitment.payer == msg.sender);
        require(block.number >= commitment.blockNumber + MAX_COMMIT_BLOCKS + WAIT_CANCEL_BLOCKS);

        delete _commitments[blindedCommit];

        commitment.payer.transfer(commitment.feePaid);

        emit Cancelled(msg.sender, blindedCommit);
    }

    function reveal(string calldata label, address owner, bytes32 salt) external {
        require(owner != address(0));

        bytes32 blindedCommit = makeBlindedCommitment(label, owner, salt);

        Commitment memory commitment = _commitments[blindedCommit];
        require(block.number <= commitment.blockNumber + MAX_COMMIT_BLOCKS);
        require(block.number >= commitment.blockNumber + MIN_COMMIT_BLOCKS);

         
        require(isValidLabel(label));

         
        delete _commitments[blindedCommit];

        uint256 tokenId = uint256(keccak256(bytes(label)));
        Takoyaki storage takoyaki = _takoyaki[tokenId];

        if (takoyaki.expires == 0) {
             
            _totalSupply += 1;
        } else {
             
            require(takoyaki.expires < now - GRACE_PERIOD);

             
            _balances[takoyaki.owner] -= 1;
        }

         
         
        takoyaki.expires = uint48(now + REGISTRATION_PERIOD);
        takoyaki.commitBlockNumber = commitment.blockNumber;
        takoyaki.revealBlockNumber = uint48(block.number);
        takoyaki.revealedSalt = keccak256(abi.encode(tokenId, salt));
        takoyaki.owner = owner;
        takoyaki.upkeepFee = commitment.feePaid;
        takoyaki.approved = address(0);

        _balances[owner] += 1;

         
        bytes32 nodehash = keccak256(abi.encode(_nodehash, tokenId));

         
        _ens.setSubnodeOwner(_nodehash, bytes32(tokenId), address(this));

         
        _ens.setResolver(nodehash, address(_defaultResolver));
        _defaultResolver.setAddr(nodehash, owner);

         
        _ens.setOwner(nodehash, owner);

        emit Registered(owner, tokenId, label, takoyaki.expires);
        emit Transfer(address(0), owner, tokenId);
    }

     
     
    function destroy(uint256 tokenId) external {
        Takoyaki memory takoyaki = _takoyaki[tokenId];
        require(takoyaki.owner != address(0));
        require(takoyaki.expires < now - GRACE_PERIOD);

        _balances[takoyaki.owner] -= 1;

        delete _takoyaki[tokenId];

        _totalSupply -= 1;
        _ens.setSubnodeOwner(_nodehash, bytes32(tokenId), address(0));

        emit Transfer(takoyaki.owner, address(0), tokenId);
    }

     
    function syncUpkeepFee(uint256 tokenId) external {
        Takoyaki storage takoyaki = _takoyaki[tokenId];
        require(takoyaki.owner != address(0));
        require(takoyaki.expires > now);

         
        if (_fee < takoyaki.upkeepFee) { takoyaki.upkeepFee = _fee; }
    }


     
     
     
    function renew(uint256 tokenId) external payable {

        Takoyaki storage takoyaki = _takoyaki[tokenId];
        require(takoyaki.owner != address(0));

         
        require(takoyaki.expires > (now - GRACE_PERIOD));

         
        if (_fee < takoyaki.upkeepFee) { takoyaki.upkeepFee = _fee; }

        require(msg.value == takoyaki.upkeepFee);

         
        require(takoyaki.expires < now + (2 * REGISTRATION_PERIOD));

         
        takoyaki.expires += REGISTRATION_PERIOD;

        emit Renewed(takoyaki.owner, tokenId, takoyaki.expires);
    }

     
    function reclaim(uint256 tokenId, address owner) external {
        Takoyaki memory takoyaki = _takoyaki[tokenId];
        require(msg.sender == takoyaki.owner && takoyaki.expires > now);

        _ens.setSubnodeOwner(_nodehash, bytes32(tokenId), owner);
    }


     
     

     
     
     
     
     
    function getTakoyaki(uint256 tokenId) external view returns (bytes32 revealSeed, address owner, uint256 upkeepFee, uint48 commitBlock, uint48 revealBlock, uint48 expires, uint8 status) {

         
         
         
         
        uint8 status = 2;
        if (_takoyaki[tokenId].expires < now - GRACE_PERIOD) {
            status = 0;
        } else if (_takoyaki[tokenId].expires < now) {
            status = 1;
        }

        Takoyaki storage takoyaki = _takoyaki[tokenId];
        return (takoyaki.revealedSalt,
                takoyaki.owner,
                takoyaki.upkeepFee,
                takoyaki.commitBlockNumber,
                takoyaki.revealBlockNumber,
                takoyaki.expires,
                status);
    }


     
     

    function ownerOf(uint256 tokenId) public view returns (address) {
        Takoyaki memory takoyaki = _takoyaki[tokenId];
        require(takoyaki.expires > now);
        return takoyaki.owner;
    }

     
    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0));
        return _balances[owner];
    }

    function approve(address to, uint256 tokenId) external {
        Takoyaki storage takoyaki = _takoyaki[tokenId];
         
        require(msg.sender == takoyaki.owner || isApprovedForAll(takoyaki.owner, msg.sender));
        require(takoyaki.expires > now);

        takoyaki.approved = to;

        emit Approval(takoyaki.owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        Takoyaki memory takoyaki = _takoyaki[tokenId];
         
         
        require(takoyaki.expires > now);
        return takoyaki.approved;
    }

    function setApprovalForAll(address to, bool approved) external {
         
        _approveAll[msg.sender][to] = approved;

        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _approveAll[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(to != address(0));

        Takoyaki storage takoyaki = _takoyaki[tokenId];
        require(takoyaki.owner == from);
        require(takoyaki.expires > now);
        require(msg.sender == takoyaki.owner ||
                msg.sender == takoyaki.approved ||
                isApprovedForAll(takoyaki.owner, msg.sender));

        if (takoyaki.owner != to) {
            _balances[takoyaki.owner] -= 1;
            _balances[to] += 1;
        }

        emit Transfer(takoyaki.owner, to, tokenId);

        takoyaki.owner = to;
        takoyaki.approved = address(0);

         

        bytes32 nodehash = keccak256(abi.encode(_nodehash, tokenId));

         
        _ens.setSubnodeOwner(_nodehash, bytes32(tokenId), address(this));

         
        _ens.setResolver(nodehash, address(_defaultResolver));
        _defaultResolver.setAddr(nodehash, to);

         
        _ens.setOwner(nodehash, to);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

     
    bytes4 constant private ERC721_TOKEN_RECEIVER_ID = bytes4(
        keccak256("onERC721Received(address,address,uint256,bytes)")
    );

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);

         
         
        uint256 codeSize;
        assembly { codeSize := extcodesize(to) }
        if (codeSize > 0) {
            bytes4 result = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);

             
            require(result == ERC721_TOKEN_RECEIVER_ID);
        }
    }

     
     

     
    bytes4 constant private INTERFACE_META_ID = bytes4(
        keccak256("supportsInterface(bytes4)")
    );

     
    bytes4 constant private ERC721_ID = bytes4(
        keccak256("balanceOf(address)") ^
        keccak256("ownerOf(uint256)") ^
        keccak256("approve(address,uint256)") ^
        keccak256("getApproved(uint256)") ^
        keccak256("setApprovalForAll(address,bool)") ^
        keccak256("isApprovedForAll(address,address)") ^
        keccak256("transferFrom(address,address,uint256)") ^
        keccak256("safeTransferFrom(address,address,uint256)") ^
        keccak256("safeTransferFrom(address,address,uint256,bytes)")
    );

     
    bytes4 constant private ERC721_METAEXT_ID = bytes4(
        keccak256("name()") ^
        keccak256("symbol()") ^
        keccak256("tokenURI(uint256)")
    );

     
     
    bytes4 constant private RECLAIM_ID = bytes4(
        keccak256("reclaim(uint256,address)")
    );

     
    function supportsInterface(bytes4 interfaceID) public view returns (bool) {
        return (
            interfaceID == INTERFACE_META_ID     ||
            interfaceID == ERC721_ID             ||
            interfaceID == ERC721_METAEXT_ID     ||
            interfaceID == RECLAIM_ID
        );
    }
}