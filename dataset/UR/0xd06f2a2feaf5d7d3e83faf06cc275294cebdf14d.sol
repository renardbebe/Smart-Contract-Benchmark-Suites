 

pragma solidity ^0.4.7;


 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}



 
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

   
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}



 
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
   

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}



 
contract ERC721Receiver {
   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}



contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


         

contract ivtk is SupportsInterfaceWithLookup, ERC721Basic, Ownable {
    mapping (bytes32 => string) public dbCustomer;
    
    struct invoiceInfo {
        bytes32[] aErc20Tx;
        bytes32 custID;
        bytes32 docDate;
        bytes32 invDate;
        uint qty;
        uint salePrice2dec;
        uint amtExc2dec;
        uint amtInc2dec;
    }
    
    invoiceInfo[] aInvoices;
    mapping (bytes32 => uint) mTxRelateWithTokenID;
    

    string public name;
    string public symbol;
    
    
    
     
     
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;
  
     
    mapping (uint256 => address) internal tokenOwner;

     
    mapping (uint256 => address) internal tokenApprovals;

     
    mapping (address => uint256) internal ownedTokensCount;

     
    mapping (address => mapping (address => bool)) internal operatorApprovals;
  
    
    constructor() public {
        dbCustomer["ET1218"] = "บริษัท กรุงเทพดรักสโตร์ จำกัด";
        
        name = "IV Token";
        symbol = "iv";
        
         
        _registerInterface(InterfaceId_ERC721);
        _registerInterface(InterfaceId_ERC721Exists);
    }
    
    function implementsERC721() public pure returns (bool)
    {
        return true;
    }
    
    function getTokenIDRelateWithTx(bytes32 _tx) public view returns (uint) {
        return mTxRelateWithTokenID[_tx];
    }
    
    function totalSupply() public view returns (uint256) {
        return aInvoices.length;
    }
    
    function getItemByTokenID(uint256 _tokenId) public view returns (
        bytes32[] aErc20Tx,
        bytes32 custID,
        bytes32 docDate,
        bytes32 invDate,
        uint qty,
        uint salePrice2dec,
        uint amtExc2dec,
        uint amtInc2dec
        ) {
        
        require(_tokenId > 0);
        
        invoiceInfo storage ivInfo = aInvoices[_tokenId - 1];
        return (
            ivInfo.aErc20Tx,
            ivInfo.custID,
            ivInfo.docDate,
            ivInfo.invDate,
            ivInfo.qty,
            ivInfo.salePrice2dec,
            ivInfo.amtExc2dec,
            ivInfo.amtInc2dec
        );
    }
    
    
    function addData(
        bytes32[] aErc20Tx,
        bytes32 custID,
        bytes32 docDate,
        bytes32 invDate,
        uint qty,
        uint salePrice2dec,
        uint amtExc2dec,
        uint amtInc2dec
        ) 
        public 
        onlyOwner
        {
        
        
        invoiceInfo memory ivInfo = invoiceInfo({
            aErc20Tx: aErc20Tx,
            custID: custID,
            docDate: docDate,
            invDate: invDate,
            qty: qty,
            salePrice2dec: salePrice2dec,
            amtExc2dec: amtExc2dec,
            amtInc2dec: amtInc2dec
        });
        
        uint256 _tokenID = aInvoices.push(ivInfo);
        for(uint256 i=0; i<aErc20Tx.length; i++) {
            mTxRelateWithTokenID[aErc20Tx[i]] = _tokenID;
        }
        
        addTokenTo(msg.sender, _tokenID);
        emit Transfer(address(0), msg.sender, _tokenID);
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
    
     
    function isApprovedForAll(
        address _owner,
        address _operator
    )
    public
    view
    returns (bool)
    {
        return operatorApprovals[_owner][_operator];
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    public
    {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

     
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    public
    {
         
        safeTransferFrom(_from, _to, _tokenId, "");
    }

     
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
    public
    {
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
    
    
     
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
        tokenApprovals[_tokenId] = address(0);
        }
    }

     
    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to]++;
    }

     
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from]--;
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
        if (!isContract(_to)) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(
        msg.sender, _from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
    
    
     
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
}