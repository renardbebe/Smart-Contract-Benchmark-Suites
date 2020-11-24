 

pragma solidity ^0.5.0;

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4);
}

 
interface IRobeSyntaxChecker {

     
    function check(uint256 rootTokenId, uint256 newTokenId, address owner, bytes calldata payload, address robeAddress) external view returns(bool);
}

 
contract IERC721 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

 
contract IRobe is IERC721 {

     
    function mint(bytes calldata payload) external returns(uint256);
    
    function mintAndFinalize(bytes calldata payload) external returns(uint256);

     
    function mint(uint256 rootTokenId, bytes calldata payload) external returns(uint256);
    
    function mintAndFinalize(uint256 rootTokenId, bytes calldata payload) external returns(uint256);

    function finalize(uint256 rootTokenId) external;
    
    function isFinalized(uint256 tokenId) external view returns(bool);

     
    function getChain(uint256 tokenId) external view returns(uint256[] memory);

     
    function getRoot(uint256 tokenId) external view returns(uint256);

     
    function getContent(uint256 tokenId) external view returns(bytes memory);

     
    function getPositionOf(uint256 tokenId) external view returns(uint256);

     
    function getTokenIdAt(uint256 tokenId, uint256 position) external view returns(uint256);

     
    function getCompleteInfo(uint256 tokenId) external view returns(uint256, address, bytes memory);
    
    event Mint(uint256 indexed rootTokenId, uint256 indexed newTokenId, address indexed sender);
    
    event Finalize(uint256 indexed rootTokenId);
}

 
contract Robe is IRobe {

    address private _voidAddress = address(0);

    address private _myAddress;

    address private _syntaxCheckerAddress;
    IRobeSyntaxChecker private _syntaxChecker;

     
    mapping(uint256 => address) private _owner;

     
    mapping(address => uint256) private _balance;

     
    mapping(uint256 => address) private _tokenOperator;

     
    mapping(address => address) private _ownerOperator;

     
    mapping(uint256 => uint256[]) private _chain;

     
    mapping(uint256 => uint256) private _positionInChain;

     
    mapping(uint256 => uint256) private _root;
    
     
    mapping(uint256 => bool) private _finalized;

     
    bytes[] private _data;

    constructor(address syntaxCheckerAddress) public {
        _myAddress = address(this);
        if(syntaxCheckerAddress != _voidAddress) {
            _syntaxCheckerAddress = syntaxCheckerAddress;
            _syntaxChecker = IRobeSyntaxChecker(_syntaxCheckerAddress);
        }
    }

    function() external payable {
        revert("ETH not accepted");
    }

     
    function mint(bytes memory payload) public returns(uint256) {
        return _mintAndOrAttach(_data.length, payload, msg.sender, false);
    }
    
    function mintAndFinalize(bytes memory payload) public returns(uint256) {
        return _mintAndOrAttach(_data.length, payload, msg.sender, true);
    }

     
    function mint(uint256 rootTokenId, bytes memory payload) public returns(uint256) {
        return _mintAndOrAttach(rootTokenId, payload, msg.sender, false);
    }
    
    function mintAndFinalize(uint256 rootTokenId, bytes memory payload) public returns(uint256) {
        return _mintAndOrAttach(rootTokenId, payload, msg.sender, true);
    }

    function _mintAndOrAttach(uint256 rootTokenId, bytes memory payload, address owner, bool finalize) private returns(uint256 newTokenId) {
        newTokenId = _data.length;
        if(rootTokenId != newTokenId) {
            require(_owner[rootTokenId] == owner, "Cannot extend an already-existing chain of someone else is forbidden");
            require(!_finalized[rootTokenId], "Root token is finalized");
        }
        if(_syntaxCheckerAddress != _voidAddress) {
            require(_syntaxChecker.check(rootTokenId, newTokenId, owner, payload, _myAddress), "Invalid payload Syntax");
        }
        _data.push(payload);
        if(rootTokenId == newTokenId) {
            _owner[rootTokenId] = owner;
        }
        _balance[owner] = _balance[owner] + 1;
        _root[newTokenId] = rootTokenId;
        _positionInChain[newTokenId] = _chain[rootTokenId].length;
        _chain[rootTokenId].push(newTokenId);
        emit Mint(rootTokenId, newTokenId, owner);
        if(finalize) {
            _finalized[rootTokenId] = true;
            emit Finalize(rootTokenId);
        }
    }
    
    function finalize(uint256 tokenId) public {
        uint256 rootTokenId = _root[tokenId];
        require(_owner[rootTokenId] == msg.sender, "Cannot finalize an already-existing chain of someone else is forbidden");
        require(!_finalized[rootTokenId], "Root token is finalized");
        _finalized[rootTokenId] = true;
        emit Finalize(rootTokenId);
    }
    
    function isFinalized(uint256 tokenId) public view returns(bool) {
        return _finalized[_root[tokenId]];
    }

     
    function getChain(uint256 tokenId) public view returns(uint256[] memory) {
        return _chain[_root[tokenId]];
    }

     
    function getRoot(uint256 tokenId) public view returns(uint256) {
        return _root[tokenId];
    }

     
    function getContent(uint256 tokenId) public view returns(bytes memory) {
        return _data[tokenId];
    }

     
    function getPositionOf(uint256 tokenId) public view returns(uint256) {
        return _positionInChain[tokenId];
    }

     
    function getTokenIdAt(uint256 tokenId, uint256 position) public view returns(uint256) {
        return _chain[tokenId][position];
    }

     
    function getCompleteInfo(uint256 tokenId) public view returns(uint256, address, bytes memory) {
        return (_positionInChain[tokenId], _owner[_root[tokenId]], _data[tokenId]);
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return _balance[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address owner) {
        return _owner[_root[tokenId]];
    }

    function approve(address to, uint256 tokenId) public {
        require(_root[tokenId] == tokenId, "Only root NFTs can be approved");
        require(msg.sender == _owner[tokenId], "Only owner can approve operators");
        _tokenOperator[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address operator) {
        require(_root[tokenId] == tokenId, "Only root NFTs can be approved");
        operator = _tokenOperator[tokenId];
        if(operator == _voidAddress) {
            operator = _ownerOperator[_owner[tokenId]];
        }
    }

    function setApprovalForAll(address operator, bool _approved) public {
        if(!_approved && operator == _ownerOperator[msg.sender]) {
            _ownerOperator[msg.sender] = _voidAddress;
        }
        if(_approved) {
            _ownerOperator[msg.sender] = operator;
        }
        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _ownerOperator[owner] == operator;
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        _transferFrom(msg.sender, from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        _safeTransferFrom(msg.sender, from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        _safeTransferFrom(msg.sender, from, to, tokenId, data);
    }

    function _transferFrom(address sender, address from, address to, uint256 tokenId) private {
        require(_root[tokenId] == tokenId, "Only root NFTs can be transfered");
        require(_owner[tokenId] == from, "Given from is not the owner of given tokenId");
        require(from == sender || getApproved(tokenId) == sender, "Sender not allowed to transfer this tokenId");
        _owner[tokenId] = to;
        _balance[from] = _balance[from] - 1;
        _balance[to] = _balance[to] + 1;
        _tokenOperator[tokenId] = _voidAddress;
        emit Transfer(from, to, tokenId);
    }

    function _safeTransferFrom(address sender, address from, address to, uint256 tokenId, bytes memory data) public {
        _transferFrom(sender, from, to, tokenId);
        uint256 size;
        assembly { size := extcodesize(to) }
        require(size <= 0, "Receiver address is not a contract");
        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data);
        require(retval == 0x150b7a02, "Receiver address does not support the onERC721Received method");
    }
}