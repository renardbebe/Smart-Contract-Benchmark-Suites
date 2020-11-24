 

pragma solidity ^0.5.2;

 
contract IVTUser {

     
    uint256 public required;
     
    address public owner;
     
    mapping (address => bool) public signers;
     
    mapping (uint256 => bool) public transactions;
     
    IVTProxyInterface public proxy;

    event Deposit(address _sender, uint256 _value);
   
  constructor(address[] memory _signers, IVTProxyInterface _proxy, uint8 _required) public {
    require(_required <= _signers.length && _required > 0 && _signers.length > 0);

    for (uint8 i = 0; i < _signers.length; i++){
        require(_signers[i] != address(0));
        signers[_signers[i]] = true;
    }
    required = _required;
    owner = msg.sender;
    proxy = _proxy;
}

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

 
  function() payable external {
      if (msg.value > 0)
          emit Deposit(msg.sender, msg.value);
  }

   
  function callImpl(bytes calldata _data)  external onlyOwner {
    address implAddress = proxy.getImplAddress();
    implAddress.delegatecall(_data); 
  }

 
  function setTransactionId(uint256 _id) public {
    transactions[_id] = true;
  }

 
  function getRequired() public view returns (uint256) {
    return required;
  }

 
  function hasSigner(address _signer) public view  returns (bool) {
    return signers[_signer];
  }

 
  function hasTransactionId(uint256 _transactionId) public view returns (bool) {
    return transactions[_transactionId];
  }

}

 
contract IVTProxyInterface {
  function getImplAddress() external view returns (address);
}