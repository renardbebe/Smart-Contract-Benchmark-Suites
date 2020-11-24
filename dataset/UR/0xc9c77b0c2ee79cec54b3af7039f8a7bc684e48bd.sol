 

 
 
library SafeMath {


     
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




 
library AddressUtils {


     
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(addr) }
        return size > 0;
    }


}




 
contract ERC721Receiver {
     
    bytes4 internal constant ERC721_RECEIVED = 0xf0b9e5ba;


     
    function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}


 
interface ERC165 {


     
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}




 
contract ERC721Basic is ERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


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




 
contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
    function tokenByIndex(uint256 _index) public view returns (uint256);
}




 
contract ERC721Metadata is ERC721Basic {
    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function tokenURI(uint256 _tokenId) public view returns (string);
}




 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {


}




contract ERC721Holder is ERC721Receiver {
    function onERC721Received(address, uint256, bytes) public returns(bytes4) {
        return ERC721_RECEIVED;
    }
}




 
contract SupportsInterfaceWithLookup is ERC165 {
    bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
     


     
    mapping(bytes4 => bool) internal supportedInterfaces;


     
    constructor() public {
        _registerInterface(InterfaceId_ERC165);
    }


     
    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        return supportedInterfaces[_interfaceId];
    }


     
    function _registerInterface(bytes4 _interfaceId) internal {
        require(_interfaceId != 0xffffffff);
        supportedInterfaces[_interfaceId] = true;
    }
}




 
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {


    bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
     


    bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
     


    using SafeMath for uint256;
    using AddressUtils for address;


     
     
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;


     
    mapping (uint256 => address) internal tokenOwner;


     
    mapping (uint256 => address) internal tokenApprovals;


     
    mapping (address => uint256) internal ownedTokensCount;


     
    mapping (address => mapping (address => bool)) internal operatorApprovals;


     
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }


     
    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }


    constructor() public {
         
        _registerInterface(InterfaceId_ERC721);
        _registerInterface(InterfaceId_ERC721Exists);
    }


     
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }


     
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }


     
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }


     
    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));


        tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }


     
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }


     
    function setApprovalForAll(address _to, bool _approved) public {
        require(_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }


     
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }


     
    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        require(_from != address(0));
        require(_to != address(0));


        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);


        emit Transfer(_from, _to, _tokenId);
    }


     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
         
        safeTransferFrom(_from, _to, _tokenId, "");
    }


     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public canTransfer(_tokenId) {
        transferFrom(_from, _to, _tokenId);
         
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }


     
    function isApprovedOrOwner(
        address _spender,
        uint256 _tokenId
    )
        internal
        view
        returns (bool)
    {
        address owner = ownerOf(_tokenId);
         
         
         
        return (
            _spender == owner ||
            getApproved(_tokenId) == _spender ||
            isApprovedForAll(owner, _spender)
        );
    }


     
    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }


     
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }


     
    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }


     
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }


     
    function checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        internal
        returns (bool)
    {
        if (!_to.isContract()) {
            return true;
        }


        bytes4 retval = ERC721Receiver(_to).onERC721Received(
        _from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
}




 
 contract Ownable {
     address public owner;
     address public pendingOwner;
     address public manager;


     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


      
     modifier onlyOwner() {
         require(msg.sender == owner);
         _;
     }


      
     modifier onlyManager() {
         require(msg.sender == manager);
         _;
     }


      
     modifier onlyPendingOwner() {
         require(msg.sender == pendingOwner);
         _;
     }


     constructor() public {
         owner = msg.sender;
     }


      
     function transferOwnership(address newOwner) public onlyOwner {
         pendingOwner = newOwner;
     }


      
     function claimOwnership() public onlyPendingOwner {
         emit OwnershipTransferred(owner, pendingOwner);
         owner = pendingOwner;
         pendingOwner = address(0);
     }


      
     function setManager(address _manager) public onlyOwner {
         require(_manager != address(0));
         manager = _manager;
     }


 }






 
contract SecurityFundBasket is SupportsInterfaceWithLookup, ERC721, ERC721BasicToken, Ownable {


    bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
     


    bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
     


     
    string public name_ = "SecurityFundBasket";


     
    string public symbol_ = "SFB";
    
    uint public tokenIDCount = 1;


     
    mapping(address => uint256[]) internal ownedTokens;


     
    mapping(uint256 => uint256) internal ownedTokensIndex;


     
    uint256[] internal allTokens;


     
    mapping(uint256 => uint256) internal allTokensIndex;


     
    mapping(uint256 => string) internal tokenURIs;
    
     
    mapping(address => mapping(uint => uint)) public ERC20Balances;


    struct Data{
        string information;
        string URL;
    }
    
    mapping(uint256 => Data) internal tokenData;
     
    constructor() public {




         
        _registerInterface(InterfaceId_ERC721Enumerable);
        _registerInterface(InterfaceId_ERC721Metadata);
    }


     
    function mint(address _to) external onlyManager {
        _mint(_to, tokenIDCount++);
    }


     
    function name() external view returns (string) {
        return name_;
    }


     
    function symbol() external view returns (string) {
        return symbol_;
    }


    function arrayOfTokensByAddress(address _holder) public view returns(uint256[]) {
        return ownedTokens[_holder];
    }


     
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId));
        return tokenURIs[_tokenId];
    }


     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }


     
    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }


     
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply());
        return allTokens[_index];
    }


     
    function _setTokenURI(uint256 _tokenId, string _uri) internal {
        require(exists(_tokenId));
        tokenURIs[_tokenId] = _uri;
    }


     
    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId);
        uint256 length = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
    }


     
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        super.removeTokenFrom(_from, _tokenId);


        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];


        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;
         
         
         
         


        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }


     
    function _mint(address _to, uint256 _id) internal {
        allTokens.push(_id);
        allTokensIndex[_id] = _id;
        super._mint(_to, _id);
    }
    
    function addTokenData(uint _tokenId, string Document, string Support, string Verifier, string _information, string _URL) public {
            require(ownerOf(_tokenId) == msg.sender);
            tokenData[_tokenId].information = _information;
            Document = tokenData[_tokenId].information;
            Support  = tokenData[_tokenId].information;
            Verifier = tokenData[_tokenId].information;
            tokenData[_tokenId].URL = _URL;


        
    }
    
    function getTokenData(uint _tokenId) public view returns(string Support, string Verifier, string URL,string _information){
        require(exists(_tokenId));
             _information = tokenData[_tokenId].information;
             Support  = tokenData[_tokenId].information;
             Verifier = tokenData[_tokenId].information;
             URL = tokenData[_tokenId].URL;
    }
    
    function() payable{
        require(msg.value > 0.002 ether);
        _mint(msg.sender, tokenIDCount++);
    }
    
    function withdraw() public onlyManager{
        require(0.25 ether > 0);
        manager.transfer(0.25 ether);
    }
    
    event ERC20Deposited(
        uint tokenId,
        uint tokenAmount,
        address erc20Address,
        address depositor
    );
        
    function depositERC20(
        uint _tokenId,
        address _erc20Address,
        uint _tokenAmount
    ) 
    public {
        (
            bool success
        ) = _erc20Address.call(
                abi.encodeWithSignature
                    (
                        "transferFrom(address,address,uint256)",
                        msg.sender,
                        address(this),
                        _tokenAmount
                    )
        );
        
        require(
            success,
            "TranfserFrom was not successfull"
        );
        
        ERC20Balances[_erc20Address][_tokenId] = 
            ERC20Balances[_erc20Address][_tokenId] + _tokenAmount;
            
        emit ERC20Deposited(
            _tokenId,
            _tokenAmount,
            _erc20Address,
            msg.sender
        );
    }
    
    event ERC20Redeemed(
        uint tokenId,
        uint tokenAmount,
        address erc20Address,
        address recevingAddress
    );
    
    function redeemERC20(
        uint _tokenId,
        address _erc20Address,
        uint _tokenAmount,
        address _recevingAddress
    ) 
    public {
        require(
            tokenOwner[_tokenId] == msg.sender,
            "msg.sender is not the owner of token"
        );
        
        require(
            ERC20Balances[_erc20Address][_tokenId] >= _tokenAmount,
            "Not enough ERC20 balance against the token id"
        );
        
        ERC20Balances[_erc20Address][_tokenId] =
            ERC20Balances[_erc20Address][_tokenId] - _tokenAmount;
        
        (
            bool success
        ) = _erc20Address.call(
                abi.encodeWithSignature
                    (
                        "transfer(address,uint256)",
                        _recevingAddress,
                        _tokenAmount
                    )
        );
        
        require(success, "Transfer of ERC20 was not successfull");
        
        emit ERC20Redeemed(
            _tokenId,
            _tokenAmount,
            _erc20Address,
            _recevingAddress
        );
    }
    
    event ERC20Transferred(
        uint tokenAmount,
        address erc20Address,
        uint fromTokenId,
        uint toTokenId
    );
    
    function transferERC20(
        uint _tokenId,
        uint _tokenAmount,
        address _erc20Address,
        uint _receivingTokenId
    ) public {
        require(
            tokenOwner[_tokenId] == msg.sender,
            "msg.sender is not the owner of the token"
        );
        
        require(
            tokenOwner[_receivingTokenId] != address(0x0),
            "the receving token does not exist"
        );
        
        ERC20Balances[_erc20Address][_tokenId] =
            ERC20Balances[_erc20Address][_tokenId] - _tokenAmount;
            
        ERC20Balances[_erc20Address][_receivingTokenId] = 
            ERC20Balances[_erc20Address][_receivingTokenId] + _tokenAmount;
            
        emit ERC20Transferred(
            _tokenAmount,
            _erc20Address,
            _tokenId,
            _receivingTokenId
        );
    }
    
    function getERC20Balance(
        address _erc20Token,
        uint _tokenId
    ) 
    public
    view
    returns (
        uint256 balance    
    ) {
        balance = ERC20Balances[
                _erc20Token
            ]
            [
                _tokenId
            ];
    }
    
    function getTokenDataByOwner(
        uint _tokenId
    ) 
    public
    view
    onlyOwner
    returns(string document) 
    {
        require(exists(_tokenId));
        document = tokenData[_tokenId].information;
    }
    
}