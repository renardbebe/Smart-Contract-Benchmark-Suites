 

pragma solidity 0.4.25;

 

 

library ECDSA {

   
  function recover(bytes32 hash, bytes signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (signature.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

 

contract Web3Provider {
    
    using ECDSA for bytes32;
    
    uint256 constant public REQUEST_PRICE = 100 wei;
    
    uint256 public clientDeposit;
    uint256 public chargedService;
    address public clientAddress;
    address public web3provider;
    uint256 public timelock;
    bool public charged;
    
    
    constructor() public {
        web3provider = msg.sender;
    }
    
    function() external {}
    
    function subscribeForProvider()
        external
        payable
    {
        require(clientAddress == address(0));
        require(msg.value % REQUEST_PRICE == 0);
        
        clientDeposit = msg.value;
        clientAddress = msg.sender;
        timelock = now + 1 days;
    }
    
    function chargeService(uint256 _amountRequests, bytes _sig) 
        external
    {
        require(charged == false);
        require(now <= timelock);
        require(msg.sender == web3provider);
        
        bytes32 hash = keccak256(abi.encodePacked(_amountRequests));
        require(hash.recover(_sig) == clientAddress);
        chargedService = _amountRequests*REQUEST_PRICE;
        require(chargedService <= clientDeposit);
        charged = true;
        web3provider.transfer(chargedService);
    }
    
    function withdrawDeposit()
        external
    {
        require(msg.sender == clientAddress);
        require(now > timelock);
        clientAddress.transfer(address(this).balance);
    }
}