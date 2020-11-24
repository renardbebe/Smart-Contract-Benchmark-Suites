 

pragma solidity >=0.5.10;

contract SimpleMultiSig {

 
 
bytes32 constant public EIP712DOMAINTYPE_HASH = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;
 
bytes32 constant public NAME_HASH = 0x32f3de0d7fc1cdd909bb4d992a94061e800669c611b9d07f137df1f4bb85f097;
 
bytes32 constant public VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;
 
bytes32 constant public TXTYPE_HASH = 0x3ee892349ae4bbe61dce18f95115b5dc02daf49204cc602458cd4c1f540d56d7;

bytes32 constant public SALT = 0x72dc1dc597006ea524d75bd3377c4663827629e52e27fd2169cca6f90f6d1ef9;

  uint256 public nonce;                  
  uint256 public threshold;              
  mapping (address => bool) public isOwner;  
  address[] public ownersArr;         

  bytes32 public DOMAIN_SEPARATOR;           
  
   
  constructor(uint256 threshold_, address[] memory owners_, uint256 chainId) public {
    require(owners_.length <= 10 && threshold_ <= owners_.length && threshold_ > 0);

    address lastAdd = address(0);
    for (uint256 i = 0; i < owners_.length; i++) {
      require(owners_[i] > lastAdd);
      isOwner[owners_[i]] = true;
      lastAdd = owners_[i];
    }
    ownersArr = owners_;
    threshold = threshold_;

    DOMAIN_SEPARATOR = keccak256(abi.encode(EIP712DOMAINTYPE_HASH,
                                            NAME_HASH,
                                            VERSION_HASH,
                                            chainId,
                                            this,
                                            SALT));
  }


   
  function execute(uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS, address destination, uint256 value, bytes memory data, address executor, uint256 gasLimit) public {
    require(sigR.length == threshold);
    require(sigR.length == sigS.length && sigR.length == sigV.length);
    require(executor == msg.sender || executor == address(0));

     
    bytes32 txInputHash = keccak256(abi.encode(TXTYPE_HASH, destination, value, keccak256(data), nonce, executor, gasLimit));
    bytes32 totalHash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, txInputHash));
    address lastAdd = address(0);  
    for (uint256 i = 0; i < threshold; i++) {
      address recovered = ecrecover(totalHash, sigV[i], sigR[i], sigS[i]);
      require(recovered > lastAdd && isOwner[recovered]);
      lastAdd = recovered;
    }

     
     
     
    nonce = nonce + 1;
    bool success = false;
    assembly { success := call(gasLimit, destination, value, add(data, 0x20), mload(data), 0, 0) }
    require(success);
    emit Execution(msg.sender, destination, value, data);
  }

  function () external payable {
    emit Deposit(msg.sender, msg.value, msg.data);
  }

  event Deposit(address sender, uint256 amount, bytes data);
	event Execution(address executor, address destination, uint256 amount, bytes data);
}