 

pragma solidity ^0.4.24;

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

 

 
contract ERC721Basic {
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 _tokenId
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

 

contract TVCrowdsale {
    uint256 public currentRate;
    function buyTokens(address _beneficiary) public payable;
}

contract TVToken {
    function transfer(address _to, uint256 _value) public returns (bool);
    function safeTransfer(address _to, uint256 _value, bytes _data) public;
}

contract MTMarketplace is Ownable {
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;
    address public wallet;
    uint256 public fee_percentage;
    ERC721Basic public token;
    address public manager;
    address internal checkAndBuySender;
    address public TVTokenAddress;
    address public TVCrowdsaleAddress;
    bytes4 constant TOKEN_RECEIVED = bytes4(keccak256("onTokenReceived(address,uint256,bytes)"));

    modifier onlyOwnerOrManager() {
        require(msg.sender == owner || manager == msg.sender);
        _;
    }

    mapping(uint256 => uint256) public priceList;
    mapping(uint256 => address) public holderList;

    event Stored(uint256 indexed id, uint256 price, address seller);
    event Cancelled(uint256 indexed id, address seller);
    event Sold(uint256 indexed id, uint256 price, address seller, address buyer);

    event TokenChanged(address old_token, address new_token);
    event WalletChanged(address old_wallet, address new_wallet);
    event FeeChanged(uint256 old_fee, uint256 new_fee);

    constructor(
        address _TVTokenAddress,
        address _TVCrowdsaleAddress,
        address _token,
        address _wallet,
        address _manager,
        uint _fee_percentage
    ) public {
        TVTokenAddress = _TVTokenAddress;
        TVCrowdsaleAddress = _TVCrowdsaleAddress;
        token = ERC721Basic(_token);
        wallet = _wallet;
        fee_percentage = _fee_percentage;
        manager = _manager;
    }

    function setToken(address _token) public onlyOwnerOrManager {
        address old = token;
        token = ERC721Basic(_token);
        emit TokenChanged(old, token);
    }

    function setWallet(address _wallet) public onlyOwnerOrManager {
        address old = wallet;
        wallet = _wallet;
        emit WalletChanged(old, wallet);
    }

    function changeFeePercentage(uint256 _percentage) public onlyOwnerOrManager {
        uint256 old = fee_percentage;
        fee_percentage = _percentage;
        emit FeeChanged(old, fee_percentage);
    }

    function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4) {
        require(msg.sender == address(token));

        uint256 _price = uint256(convertBytesToBytes32(_data));

        require(_price > 0);

        priceList[_tokenId] = _price;
        holderList[_tokenId] = _from;

        emit Stored(_tokenId, _price, _from);

        return ERC721_RECEIVED;
    }

    function onTokenReceived(address _from, uint256 _value, bytes _data) public returns (bytes4) {
        require(msg.sender == TVTokenAddress);
        uint _id = uint256(convertBytesToBytes32(_data));
        require(priceList[_id] == _value);

        address oldHolder = holderList[_id];
        uint256 price = priceList[_id];

        uint256 toWallet = price / 100 * fee_percentage;
        uint256 toHolder = price - toWallet;

        holderList[_id] = 0x0;
        priceList[_id] = 0;

        _from = this == _from ? checkAndBuySender : _from;
        checkAndBuySender = address(0);
        token.safeTransferFrom(this, _from, _id);

        TVToken(TVTokenAddress).transfer(wallet, toWallet);
        TVToken(TVTokenAddress).transfer(_from, toHolder);

        emit Sold(_id, price, oldHolder, msg.sender);
        return TOKEN_RECEIVED;
    }

    function cancel(uint256 _id) public returns (bool) {
        require(holderList[_id] == msg.sender);

        holderList[_id] = 0x0;
        priceList[_id] = 0;

        token.safeTransferFrom(this, msg.sender, _id);

        emit Cancelled(_id, msg.sender);

        return true;
    }

    function changeAndBuy(uint256 _id) public payable returns (bool) {
        uint rate = TVCrowdsale(TVCrowdsaleAddress).currentRate();
        uint priceWei = priceList[_id] / rate;
        require(priceWei == msg.value);

        TVCrowdsale(TVCrowdsaleAddress).buyTokens.value(msg.value)(this);
        bytes memory data = toBytes(_id);
        checkAndBuySender = msg.sender;
        TVToken(TVTokenAddress).safeTransfer(this, priceList[_id], data);
        return true;
    }

    function changeTVTokenAddress(address newAddress) public onlyOwnerOrManager {
        TVTokenAddress = newAddress;
    }

    function changeTVCrowdsaleAddress(address newAddress) public onlyOwnerOrManager {
        TVCrowdsaleAddress = newAddress;
    }

    function setManager(address _manager) public onlyOwner {
        manager = _manager;
    }

    function convertBytesToBytes32(bytes inBytes) internal pure returns (bytes32 out) {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            out := mload(add(inBytes, 32))
        }
    }

    function toBytes(uint256 x) internal pure returns (bytes b) {
        b = new bytes(32);
        assembly {mstore(add(b, 32), x)}
    }
}