 

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


 
contract ECRecovery {
    function recover(bytes32 hash, bytes sig) public pure returns (address);
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


 
contract TLDR is Owned {
     
    address private _predecessor;

     
    address private _successor;
    
     
    uint private _revision;

     
    Zer0netDbInterface private _zer0netDb;
    
     
    string _namespace = 'tldr';

    event Posted(
        bytes32 indexed postId,
        address indexed owner,
        bytes body
    );

     
    constructor() public {
         
         
        _zer0netDb = Zer0netDbInterface(0xE865Fe1A1A3b342bF0E2fcB11fF4E3BCe58263af);

         
        bytes32 hash = keccak256(abi.encodePacked('aname.', _namespace));

         
        _predecessor = _zer0netDb.getAddress(hash);

         
        if (_predecessor != 0x0) {
             
            uint lastRevision = TLDR(_predecessor).getRevision();
            
             
            _revision = lastRevision + 1;
        }
    }

     
    modifier onlyAuthBy0Admin() {
         
        require(_zer0netDb.getBool(keccak256(
            abi.encodePacked(msg.sender, '.has.auth.for.', _namespace))) == true);

        _;       
    }

     
    function () public payable {
         
        revert('Oops! Direct payments are NOT permitted here.');
    }


     

     
    function savePost(
        string _title,
        bytes _body
    ) external returns (bool success) {
        _setPost(msg.sender, _title, _body);

         
        return true;
    }
    
     
     
     
     
        
     
     
        
     
     
     

     
     
     
     
        
     
     
        
     
     
     


     

     
    function getPost(
        bytes32 _postId
    ) external view returns (
        address location,
        uint blockNum
    ) {
         
        location = _zer0netDb.getAddress(_postId);

         
        blockNum = _zer0netDb.getUint(_postId);
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
    

     

     
    function _setPost(
        address _owner, 
        string _title,
        bytes _body
    ) private returns (bool success) {
         
        bytes32 postId = calcPostId(_owner, _title);
        
         
        _zer0netDb.setAddress(postId, address(this));

         
        _zer0netDb.setUint(postId, block.number);

         
        emit Posted(postId, _owner, _body);

         
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


     

     
    function calcPostId(
        address _owner,
        string _title
    ) public view returns (
        bytes32 postId
    ) {
         
        postId = keccak256(abi.encodePacked(
            _namespace, '.', _owner, '.', _title));
    }

     
    function transferAnyERC20Token(
        address _tokenAddress, 
        uint _tokens
    ) public onlyOwner returns (bool success) {
        return ERC20Interface(_tokenAddress).transfer(owner, _tokens);
    }
}