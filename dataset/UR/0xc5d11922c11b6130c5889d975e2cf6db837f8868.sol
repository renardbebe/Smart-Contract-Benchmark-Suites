 

 

pragma solidity 0.5.6;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity 0.5.6;

 
library SafeMath
{

   
  function mul(
    uint256 _factor1,
    uint256 _factor2
  )
    internal
    pure
    returns (uint256 product)
  {
     
     
     
    if (_factor1 == 0)
    {
      return 0;
    }

    product = _factor1 * _factor2;
    require(product / _factor1 == _factor2);
  }

   
  function div(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 quotient)
  {
     
    require(_divisor > 0);
    quotient = _dividend / _divisor;
     
  }

   
  function sub(
    uint256 _minuend,
    uint256 _subtrahend
  )
    internal
    pure
    returns (uint256 difference)
  {
    require(_subtrahend <= _minuend);
    difference = _minuend - _subtrahend;
  }

   
  function add(
    uint256 _addend1,
    uint256 _addend2
  )
    internal
    pure
    returns (uint256 sum)
  {
    sum = _addend1 + _addend2;
    require(sum >= _addend1);
  }

   
  function mod(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 remainder) 
  {
    require(_divisor != 0);
    remainder = _dividend % _divisor;
  }

}

 

pragma solidity 0.5.6;

 
interface ERC721TokenReceiver
{

   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);

	function onERC721Received(
    address _from, 
    uint256 _tokenId, 
    bytes calldata _data
  ) 
  external 
  returns 
  (bytes4);

}

 

pragma solidity ^0.5.6;

 
library ERC165Checker {
     
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
     

     
    function _supportsERC165(address account) internal view returns (bool) {
         
         
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

     
    function _supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
         
        return _supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

     
    function _supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
         
        if (!_supportsERC165(account)) {
            return false;
        }

         
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

         
        return true;
    }

     
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
         
         
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

     
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool success, bool result)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);

         
        assembly {
            let encodedParams_data := add(0x20, encodedParams)
            let encodedParams_size := mload(encodedParams)

            let output := mload(0x40)     
            mstore(output, 0x0)

            success := staticcall(
                30000,                    
                account,                  
                encodedParams_data,
                encodedParams_size,
                output,
                0x20                      
            )

            result := mload(output)       
        }
    }
}

 

pragma solidity 0.5.6;





 
contract Erc721Interface {
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
}

 
contract KittyInterface {
    mapping (uint256 => address) public kittyIndexToApproved;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
}


contract Exchange is Ownable, ERC721TokenReceiver {

    using SafeMath for uint256;
    using SafeMath for uint;
    using ERC165Checker for address;

     
    address constant internal  CryptoKittiesAddress = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    
     
    bytes4 internal constant ERC721_RECEIVED_THREE_INPUT = 0xf0b9e5ba;

     
    bytes4 internal constant ERC721_RECEIVED_FOUR_INPUT = 0x150b7a02;

     
    mapping (address => mapping (uint256 => address)) internal TokenToOwner;

     
    mapping (address => mapping (address => uint256[])) internal OwnerToTokens;

     
    mapping (address => mapping(uint256 => uint256)) internal TokenToIndex;

     
    mapping (address => bytes32[]) internal OwnerToOrders;

     
    mapping (bytes32 => address) internal OrderToOwner;

     
    mapping (bytes32 => uint) internal OrderToIndex;

     
    mapping (bytes32 => address) internal MatchOrderToOwner;
   
     
    mapping (bytes32 => bytes32[]) internal OrderToMatchOrders;

     
    mapping (bytes32 => mapping(bytes32 => uint)) internal OrderToMatchOrderIndex;

     
    mapping (bytes32 => bool) internal OrderToExist;


     
    bytes4[] internal SupportNFTInterface;

     
    struct OrderObj {
         
        address owner;

         
        address contractAddress;
        
         
        uint256 tokenId;
    }

     
    mapping (bytes32 => OrderObj) internal HashToOrderObj;

     
    event ReceiveToken(
        address indexed _from, 
        address _contractAddress, 
        uint256 _tokenId
    );


     
    event SendBackToken(
        address indexed _owner, 
        address _contractAddress, 
        uint256 _tokenId
    );

     
    event SendToken(
        address indexed _to, 
        address _contractAddress, 
        uint256 _tokenId
    );

     
    event CreateOrderObj(
        bytes32 indexed _hash,
        address _owner,
        address _contractAddress,
        uint256 _tokenId   
    );

     
    event CreateOrder(
        address indexed _from,
        bytes32 indexed _orderHash,
        address _contractAddress,
        uint256 _tokenId
    );

     
    event CreateMatchOrder(
        address indexed _from,
        bytes32 indexed _orderHash,
        bytes32 indexed _matchOrderHash,
        address _contractAddress,
        uint256 _tokenId
    );

     
    event DeleteOrder(
        address indexed _from,
        bytes32 indexed _orderHash
    );

     
    event DeleteMatchOrder(
        address indexed _from,
        bytes32 indexed _orderHash,
        bytes32 indexed _matchOrderHash
    );


     
    modifier onlySenderIsOriginalOwner(
        address contractAddress, 
        uint256 tokenId
    ) 
    {
        require(TokenToOwner[contractAddress][tokenId] == msg.sender, "original owner should be message sender");
        _;
    }

    constructor () public {
         
        SupportNFTInterface.push(0x80ac58cd);

         
        SupportNFTInterface.push(0x780e9d63);

         
        SupportNFTInterface.push(0x5b5e139f);
    }

    
    function addSupportNFTInterface(
        bytes4 interface_id
    )
    external
    onlyOwner()
    {
        SupportNFTInterface.push(interface_id);
    }

    
    function onERC721Received(
        address _from, 
        uint256 _tokenId, 
        bytes calldata _data
    ) 
    external 
    returns (bytes4)
    {
        return ERC721_RECEIVED_THREE_INPUT;
    }

    
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata data
    )
    external
    returns(bytes4)
    {
        return ERC721_RECEIVED_FOUR_INPUT;
    }

    
    function createOrder(
        address contractAddress, 
        uint256 tokenId
    ) 
    external 
    onlySenderIsOriginalOwner(
        contractAddress, 
        tokenId
    ) 
    {
        bytes32 orderHash = keccak256(abi.encodePacked(contractAddress, tokenId, msg.sender));
        require(OrderToOwner[orderHash] != msg.sender, "Order already exist");
        _addOrder(msg.sender, orderHash);
        emit CreateOrder(msg.sender, orderHash, contractAddress, tokenId);
    }

    
    function _addOrder(
        address sender, 
        bytes32 orderHash
    ) 
    internal 
    {
        uint index = OwnerToOrders[sender].push(orderHash).sub(1);
        OrderToOwner[orderHash] = sender;
        OrderToIndex[orderHash] = index;
        OrderToExist[orderHash] = true;
    }

    
    function deleteOrder(
        bytes32 orderHash
    )
    external
    {
        require(OrderToOwner[orderHash] == msg.sender, "this order hash not belongs to this address");
        _removeOrder(msg.sender, orderHash);
        emit DeleteOrder(msg.sender, orderHash);
    }

    
    function _removeOrder(
        address sender,
        bytes32 orderHash
    )
    internal
    {
        OrderToExist[orderHash] = false;
        delete OrderToOwner[orderHash];
        uint256 orderIndex = OrderToIndex[orderHash];
        uint256 lastOrderIndex = OwnerToOrders[sender].length.sub(1);
        if (lastOrderIndex != orderIndex){
            bytes32 lastOwnerOrder = OwnerToOrders[sender][lastOrderIndex];
            OwnerToOrders[sender][orderIndex] = lastOwnerOrder;
            OrderToIndex[lastOwnerOrder] = orderIndex;
        }
        OwnerToOrders[sender].length--;
    }

    
    function createMatchOrder(
        address contractAddress,
        uint256 tokenId, 
        bytes32 orderHash
    ) 
    external 
    onlySenderIsOriginalOwner(
        contractAddress, 
        tokenId
    ) 
    {
        bytes32 matchOrderHash = keccak256(abi.encodePacked(contractAddress, tokenId, msg.sender));
        require(OrderToOwner[matchOrderHash] != msg.sender, "Order already exist");
        _addMatchOrder(matchOrderHash, orderHash);
        emit CreateMatchOrder(msg.sender, orderHash, matchOrderHash, contractAddress, tokenId);
    }

    
    function _addMatchOrder(
        bytes32 matchOrderHash, 
        bytes32 orderHash
    ) 
    internal 
    {
        uint inOrderIndex = OrderToMatchOrders[orderHash].push(matchOrderHash).sub(1);
        OrderToMatchOrderIndex[orderHash][matchOrderHash] = inOrderIndex;
    }

    
    function deleteMatchOrder(
        bytes32 matchOrderHash,
        bytes32 orderHash
    )
    external
    {
        require(MatchOrderToOwner[matchOrderHash] == msg.sender, "match order doens't belong to this address" );
        require(OrderToExist[orderHash] == true, "this order is not exist");
        _removeMatchOrder(orderHash, matchOrderHash);
        emit DeleteMatchOrder(msg.sender, orderHash, matchOrderHash);
    }

   
    function _removeMatchOrder(
        bytes32 orderHash,
        bytes32 matchOrderHash
    )
    internal
    {
        uint256 matchOrderIndex = OrderToMatchOrderIndex[orderHash][matchOrderHash];
        uint256 lastMatchOrderIndex = OrderToMatchOrders[orderHash].length.sub(1);
        if (lastMatchOrderIndex != matchOrderIndex){
            bytes32 lastMatchOrder = OrderToMatchOrders[orderHash][lastMatchOrderIndex];
            OrderToMatchOrders[orderHash][matchOrderIndex] = lastMatchOrder;
            OrderToMatchOrderIndex[orderHash][lastMatchOrder] = matchOrderIndex;
        }
        OrderToMatchOrders[orderHash].length--;
    }

     
    function exchangeToken(
        bytes32 order,
        bytes32 matchOrder
    ) 
    external 
    {
        require(OrderToOwner[order] == msg.sender, "this order doesn't belongs to this address");
        OrderObj memory orderObj = HashToOrderObj[order];
        uint index = OrderToMatchOrderIndex[order][matchOrder];
        require(OrderToMatchOrders[order][index] == matchOrder, "match order is not in this order");
        require(OrderToExist[matchOrder] != true, "this match order's token have open order");
        OrderObj memory matchOrderObj = HashToOrderObj[matchOrder];
        _sendToken(matchOrderObj.owner, orderObj.contractAddress, orderObj.tokenId);
        _sendToken(orderObj.owner, matchOrderObj.contractAddress, matchOrderObj.tokenId);
        _removeMatchOrder(order, matchOrder);
        _removeOrder(msg.sender, order);
    }

     
    function receiveErc721Token(
        address contractAddress, 
        uint256 tokenId
    ) 
    external  
    {
        bool checkSupportErc165Interface = false;
        if(contractAddress != CryptoKittiesAddress){
            for(uint i = 0; i < SupportNFTInterface.length; i++){
                if(contractAddress._supportsInterface(SupportNFTInterface[i]) == true){
                    checkSupportErc165Interface = true;
                }
            }
            require(checkSupportErc165Interface == true, "not supported Erc165 Interface");
            Erc721Interface erc721Contract = Erc721Interface(contractAddress);
            require(erc721Contract.isApprovedForAll(msg.sender,address(this)) == true, "contract doesn't have power to control this token id");
            erc721Contract.transferFrom(msg.sender, address(this), tokenId);
        }else {
            KittyInterface kittyContract = KittyInterface(contractAddress);
            require(kittyContract.kittyIndexToApproved(tokenId) == address(this), "contract doesn't have power to control this cryptoKitties's id");
            kittyContract.transferFrom(msg.sender, address(this), tokenId);
        }
        _addToken(msg.sender, contractAddress, tokenId);
        emit ReceiveToken(msg.sender, contractAddress, tokenId);

    }

     
    function _addToken(
        address sender, 
        address contractAddress, 
        uint256 tokenId
    ) 
    internal 
    {   
        bytes32 matchOrderHash = keccak256(abi.encodePacked(contractAddress, tokenId, sender));
        MatchOrderToOwner[matchOrderHash] = sender;
        HashToOrderObj[matchOrderHash] = OrderObj(sender,contractAddress,tokenId);
        TokenToOwner[contractAddress][tokenId] = sender;
        uint index = OwnerToTokens[sender][contractAddress].push(tokenId).sub(1);
        TokenToIndex[contractAddress][tokenId] = index;
        emit CreateOrderObj(matchOrderHash, sender, contractAddress, tokenId);
    }


     
    function sendBackToken(
        address contractAddress, 
        uint256 tokenId
    ) 
    external 
    onlySenderIsOriginalOwner(
        contractAddress, 
        tokenId
    ) 
    {
        bytes32 orderHash = keccak256(abi.encodePacked(contractAddress, tokenId, msg.sender));
        if(OrderToExist[orderHash] == true) {
            _removeOrder(msg.sender, orderHash);
        }
        _sendToken(msg.sender, contractAddress, tokenId);
        emit SendBackToken(msg.sender, contractAddress, tokenId);
    }  


     
    function _sendToken(
        address sendAddress,
        address contractAddress, 
        uint256 tokenId
    )
    internal
    {   
        if(contractAddress != CryptoKittiesAddress){
            Erc721Interface erc721Contract = Erc721Interface(contractAddress);
            require(erc721Contract.ownerOf(tokenId) == address(this), "exchange contract should have this token");
            erc721Contract.transferFrom(address(this), sendAddress, tokenId);
        }else{
            KittyInterface kittyContract = KittyInterface(contractAddress);
            require(kittyContract.ownerOf(tokenId) == address(this), "exchange contract should have this token");
            kittyContract.transfer(sendAddress, tokenId);
        }
        _removeToken(contractAddress, tokenId);
        emit SendToken(sendAddress, contractAddress, tokenId);
    }

     
    function _removeToken(
        address contractAddress, 
        uint256 tokenId
    ) 
    internal 
    {
        address owner = TokenToOwner[contractAddress][tokenId];
        bytes32 orderHash = keccak256(abi.encodePacked(contractAddress, tokenId, owner));
        delete HashToOrderObj[orderHash];
        delete MatchOrderToOwner[orderHash];
        delete TokenToOwner[contractAddress][tokenId];
        uint256 tokenIndex = TokenToIndex[contractAddress][tokenId];
        uint256 lastOwnerTokenIndex = OwnerToTokens[owner][contractAddress].length.sub(1);
        if (lastOwnerTokenIndex != tokenIndex){
            uint256 lastOwnerToken = OwnerToTokens[owner][contractAddress][lastOwnerTokenIndex];
            OwnerToTokens[owner][contractAddress][tokenIndex] = lastOwnerToken;
            TokenToIndex[contractAddress][lastOwnerToken] = tokenIndex;
        }
        OwnerToTokens[owner][contractAddress].length--;
    }

     
    function getTokenOwner(
        address contractAddress, 
        uint256 tokenId
    ) 
    external 
    view 
    returns (address)
    {
        return TokenToOwner[contractAddress][tokenId];
    }
    
     
    function getOwnerTokens(
        address ownerAddress, 
        address contractAddress
    ) 
    external 
    view 
    returns (uint256[] memory)
    {
        return OwnerToTokens[ownerAddress][contractAddress];
    }

     
    function getTokenIndex(
        address contractAddress, 
        uint256 tokenId
    ) 
    external 
    view
    returns (uint256)
    {
        return TokenToIndex[contractAddress][tokenId];
    }

     
    function getOwnerOrders(
        address ownerAddress
    ) 
    external 
    view 
    returns (bytes32[] memory){
        return OwnerToOrders[ownerAddress];
    }

     
    function getOrderOwner(
        bytes32 order
    ) 
    external 
    view 
    returns (address)
    {
        return OrderToOwner[order];
    }

     
    function getOrderIndex(
        bytes32 order
    ) 
    external 
    view 
    returns (uint)
    {
        return OrderToIndex[order];
    }

     
    function getOrderExist(
        bytes32 order
    )
    external
    view
    returns (bool){
        return OrderToExist[order];
    }

     
    function getMatchOrderOwner(
        bytes32 matchOrder
    ) 
    external 
    view 
    returns (address)
    {
        return MatchOrderToOwner[matchOrder];
    }

     
    function getOrderMatchOrderIndex(
        bytes32 order,
        bytes32 matchOrder
    ) 
    external 
    view 
    returns (uint)
    {
        return OrderToMatchOrderIndex[order][matchOrder];
    }

     
    function getOrderMatchOrders(
        bytes32 order
    ) 
    external 
    view 
    returns (bytes32[] memory)
    {
        return OrderToMatchOrders[order];
    }

     
    function getHashOrderObj(
        bytes32 hashOrder
    )
    external
    view
    returns(
        address, 
        address, 
        uint256
    )
    {
        OrderObj memory orderObj = HashToOrderObj[hashOrder];
        return(
            orderObj.owner,
            orderObj.contractAddress,
            orderObj.tokenId
        );
    }
}