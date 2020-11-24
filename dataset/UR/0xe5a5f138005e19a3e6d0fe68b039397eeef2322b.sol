 

pragma solidity 0.4.24;

 

 
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

 

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}

 

 
contract OwnableContract is CanReclaimToken, Claimable { }  

 

interface ControllerInterface {
    function mint(address to, uint amount) external returns (bool);
    function burn(uint value) external returns (bool);
    function isCustodian(address addr) external view returns (bool);
    function isMerchant(address addr) external view returns (bool);
    function getWBTC() external view returns (ERC20);
}

 

contract Factory is OwnableContract {

    enum RequestStatus {PENDING, CANCELED, APPROVED, REJECTED}

    struct Request {
        address requester;  
        uint amount;  
        string btcDepositAddress;  
        string btcTxid;  
        uint nonce;  
        uint timestamp;  
        RequestStatus status;  
    }

    ControllerInterface public controller;

     
     
    mapping(address=>string) public custodianBtcDepositAddress;

     
    mapping(address=>string) public merchantBtcDepositAddress;

     
    mapping(bytes32=>uint) public mintRequestNonce;

     
    mapping(bytes32=>uint) public burnRequestNonce;

    Request[] public mintRequests;
    Request[] public burnRequests;

    constructor(ControllerInterface _controller) public {
        require(_controller != address(0), "invalid _controller address");
        controller = _controller;
        owner = _controller;
    }

    modifier onlyMerchant() {
        require(controller.isMerchant(msg.sender), "sender not a merchant.");
        _;
    }

    modifier onlyCustodian() {
        require(controller.isCustodian(msg.sender), "sender not a custodian.");
        _;
    }

    event CustodianBtcDepositAddressSet(address indexed merchant, address indexed sender, string btcDepositAddress);

    function setCustodianBtcDepositAddress(
        address merchant,
        string btcDepositAddress
    )
        external
        onlyCustodian
        returns (bool) 
    {
        require(merchant != 0, "invalid merchant address");
        require(controller.isMerchant(merchant), "merchant address is not a real merchant.");
        require(!isEmptyString(btcDepositAddress), "invalid btc deposit address");

        custodianBtcDepositAddress[merchant] = btcDepositAddress;
        emit CustodianBtcDepositAddressSet(merchant, msg.sender, btcDepositAddress);
        return true;
    }

    event MerchantBtcDepositAddressSet(address indexed merchant, string btcDepositAddress);

    function setMerchantBtcDepositAddress(string btcDepositAddress) external onlyMerchant returns (bool) {
        require(!isEmptyString(btcDepositAddress), "invalid btc deposit address");

        merchantBtcDepositAddress[msg.sender] = btcDepositAddress;
        emit MerchantBtcDepositAddressSet(msg.sender, btcDepositAddress);
        return true; 
    }

    event MintRequestAdd(
        uint indexed nonce,
        address indexed requester,
        uint amount,
        string btcDepositAddress,
        string btcTxid,
        uint timestamp,
        bytes32 requestHash
    );

    function addMintRequest(
        uint amount,
        string btcTxid,
        string btcDepositAddress
    )
        external
        onlyMerchant
        returns (bool)
    {
        require(!isEmptyString(btcDepositAddress), "invalid btc deposit address"); 
        require(compareStrings(btcDepositAddress, custodianBtcDepositAddress[msg.sender]), "wrong btc deposit address");

        uint nonce = mintRequests.length;
        uint timestamp = getTimestamp();

        Request memory request = Request({
            requester: msg.sender,
            amount: amount,
            btcDepositAddress: btcDepositAddress,
            btcTxid: btcTxid,
            nonce: nonce,
            timestamp: timestamp,
            status: RequestStatus.PENDING
        });

        bytes32 requestHash = calcRequestHash(request);
        mintRequestNonce[requestHash] = nonce; 
        mintRequests.push(request);

        emit MintRequestAdd(nonce, msg.sender, amount, btcDepositAddress, btcTxid, timestamp, requestHash);
        return true;
    }

    event MintRequestCancel(uint indexed nonce, address indexed requester, bytes32 requestHash);

    function cancelMintRequest(bytes32 requestHash) external onlyMerchant returns (bool) {
        uint nonce;
        Request memory request;

        (nonce, request) = getPendingMintRequest(requestHash);

        require(msg.sender == request.requester, "cancel sender is different than pending request initiator");
        mintRequests[nonce].status = RequestStatus.CANCELED;

        emit MintRequestCancel(nonce, msg.sender, requestHash);
        return true;
    }

    event MintConfirmed(
        uint indexed nonce,
        address indexed requester,
        uint amount,
        string btcDepositAddress,
        string btcTxid,
        uint timestamp,
        bytes32 requestHash
    );

    function confirmMintRequest(bytes32 requestHash) external onlyCustodian returns (bool) {
        uint nonce;
        Request memory request;

        (nonce, request) = getPendingMintRequest(requestHash);

        mintRequests[nonce].status = RequestStatus.APPROVED;
        require(controller.mint(request.requester, request.amount), "mint failed");

        emit MintConfirmed(
            request.nonce,
            request.requester,
            request.amount,
            request.btcDepositAddress,
            request.btcTxid,
            request.timestamp,
            requestHash
        );
        return true;
    }

    event MintRejected(
        uint indexed nonce,
        address indexed requester,
        uint amount,
        string btcDepositAddress,
        string btcTxid,
        uint timestamp,
        bytes32 requestHash
    );

    function rejectMintRequest(bytes32 requestHash) external onlyCustodian returns (bool) {
        uint nonce;
        Request memory request;

        (nonce, request) = getPendingMintRequest(requestHash);

        mintRequests[nonce].status = RequestStatus.REJECTED;

        emit MintRejected(
            request.nonce,
            request.requester,
            request.amount,
            request.btcDepositAddress,
            request.btcTxid,
            request.timestamp,
            requestHash
        );
        return true;
    }

    event Burned(
        uint indexed nonce,
        address indexed requester,
        uint amount,
        string btcDepositAddress,
        uint timestamp,
        bytes32 requestHash
    );

    function burn(uint amount) external onlyMerchant returns (bool) {
        string memory btcDepositAddress = merchantBtcDepositAddress[msg.sender];
        require(!isEmptyString(btcDepositAddress), "merchant btc deposit address was not set"); 

        uint nonce = burnRequests.length;
        uint timestamp = getTimestamp();

         
        string memory btcTxid = "";

        Request memory request = Request({
            requester: msg.sender,
            amount: amount,
            btcDepositAddress: btcDepositAddress,
            btcTxid: btcTxid,
            nonce: nonce,
            timestamp: timestamp,
            status: RequestStatus.PENDING
        });

        bytes32 requestHash = calcRequestHash(request);
        burnRequestNonce[requestHash] = nonce; 
        burnRequests.push(request);

        require(controller.getWBTC().transferFrom(msg.sender, controller, amount), "trasnfer tokens to burn failed");
        require(controller.burn(amount), "burn failed");

        emit Burned(nonce, msg.sender, amount, btcDepositAddress, timestamp, requestHash);
        return true;
    }

    event BurnConfirmed(
        uint indexed nonce,
        address indexed requester,
        uint amount,
        string btcDepositAddress,
        string btcTxid,
        uint timestamp,
        bytes32 inputRequestHash
    );

    function confirmBurnRequest(bytes32 requestHash, string btcTxid) external onlyCustodian returns (bool) {
        uint nonce;
        Request memory request;

        (nonce, request) = getPendingBurnRequest(requestHash);

        burnRequests[nonce].btcTxid = btcTxid;
        burnRequests[nonce].status = RequestStatus.APPROVED;
        burnRequestNonce[calcRequestHash(burnRequests[nonce])] = nonce;

        emit BurnConfirmed(
            request.nonce,
            request.requester,
            request.amount,
            request.btcDepositAddress,
            btcTxid,
            request.timestamp,
            requestHash
        );
        return true;
    }

    function getMintRequest(uint nonce)
        external
        view
        returns (
            uint requestNonce,
            address requester,
            uint amount,
            string btcDepositAddress,
            string btcTxid,
            uint timestamp,
            string status,
            bytes32 requestHash
        )
    {
        Request memory request = mintRequests[nonce];
        string memory statusString = getStatusString(request.status); 

        requestNonce = request.nonce;
        requester = request.requester;
        amount = request.amount;
        btcDepositAddress = request.btcDepositAddress;
        btcTxid = request.btcTxid;
        timestamp = request.timestamp;
        status = statusString;
        requestHash = calcRequestHash(request);
    }

    function getMintRequestsLength() external view returns (uint length) {
        return mintRequests.length;
    }

    function getBurnRequest(uint nonce)
        external
        view
        returns (
            uint requestNonce,
            address requester,
            uint amount,
            string btcDepositAddress,
            string btcTxid,
            uint timestamp,
            string status,
            bytes32 requestHash
        )
    {
        Request storage request = burnRequests[nonce];
        string memory statusString = getStatusString(request.status); 

        requestNonce = request.nonce;
        requester = request.requester;
        amount = request.amount;
        btcDepositAddress = request.btcDepositAddress;
        btcTxid = request.btcTxid;
        timestamp = request.timestamp;
        status = statusString;
        requestHash = calcRequestHash(request);
    }

    function getBurnRequestsLength() external view returns (uint length) {
        return burnRequests.length;
    }

    function getTimestamp() internal view returns (uint) {
         
        return block.timestamp;  
    }

    function getPendingMintRequest(bytes32 requestHash) internal view returns (uint nonce, Request memory request) {
        require(requestHash != 0, "request hash is 0");
        nonce = mintRequestNonce[requestHash];
        request = mintRequests[nonce];
        validatePendingRequest(request, requestHash);
    }

    function getPendingBurnRequest(bytes32 requestHash) internal view returns (uint nonce, Request memory request) {
        require(requestHash != 0, "request hash is 0");
        nonce = burnRequestNonce[requestHash];
        request = burnRequests[nonce];
        validatePendingRequest(request, requestHash);
    }

    function validatePendingRequest(Request memory request, bytes32 requestHash) internal pure {
        require(request.status == RequestStatus.PENDING, "request is not pending");
        require(requestHash == calcRequestHash(request), "given request hash does not match a pending request");
    }

    function calcRequestHash(Request request) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            request.requester,
            request.amount,
            request.btcDepositAddress,
            request.btcTxid,
            request.nonce,
            request.timestamp
        ));
    }

    function compareStrings (string a, string b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    function isEmptyString (string a) internal pure returns (bool) {
        return (compareStrings(a, ""));
    }

    function getStatusString(RequestStatus status) internal pure returns (string) {
        if (status == RequestStatus.PENDING) {
            return "pending";
        } else if (status == RequestStatus.CANCELED) {
            return "canceled";
        } else if (status == RequestStatus.APPROVED) {
            return "approved";
        } else if (status == RequestStatus.REJECTED) {
            return "rejected";
        } else {
             
            return "unknown";
        }
    }
}