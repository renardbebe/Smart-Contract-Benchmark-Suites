 

pragma solidity ^0.4.15;

 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig) constant returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      bytes memory prefix = "\x19Ethereum Signed Message:\n32";
      hash = sha3(prefix, hash);
      return ecrecover(hash, v, r, s);
    }
  }

}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

contract MemeCore is Ownable {
    using SafeMath for uint;
    using ECRecovery for bytes32;

     
    mapping (address => uint) withdrawalsNonce;

    event Withdraw(address receiver, uint weiAmount);
    event WithdrawCanceled(address receiver);

    function() payable {
        require(msg.value != 0);
    }

     
    function _withdraw(address toAddress, uint weiAmount) private {
         
        toAddress.transfer(weiAmount);

        Withdraw(toAddress, weiAmount);
    }


     
    function withdraw(uint weiAmount, bytes signedData) external {
        uint256 nonce = withdrawalsNonce[msg.sender] + 1;

        bytes32 validatingHash = keccak256(msg.sender, weiAmount, nonce);

         
        address addressRecovered = validatingHash.recover(signedData);

        require(addressRecovered == owner);

         
        _withdraw(msg.sender, weiAmount);

        withdrawalsNonce[msg.sender] = nonce;
    }

     
    function cancelWithdraw(){
        withdrawalsNonce[msg.sender]++;

        WithdrawCanceled(msg.sender);
    }

     
    function backendWithdraw(address toAddress, uint weiAmount) external onlyOwner {
        require(toAddress != 0);

         
        _withdraw(toAddress, weiAmount);
    }

}