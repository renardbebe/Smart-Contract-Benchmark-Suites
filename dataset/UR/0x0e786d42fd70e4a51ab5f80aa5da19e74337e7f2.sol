 

pragma solidity ^0.4.20;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract Ownable {
  address public owner;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() internal {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract tokenInterface {
	function balanceOf(address _owner) public constant returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool);
}

contract Library {
     
     
     
    function createBSMHash(string payload) pure internal returns (bytes32) {
         
        string memory prefix = "\x18Bitcoin Signed Message:\n";
        return sha256(sha256(prefix, bytes1(bytes(payload).length), payload));
    }

    function validateBSM(string payload, address key, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool) {
        return key == ecrecover(createBSMHash(payload), v, r, s);
    }
  
	 
	 

     

	function btcAddrPubKeyUncompr( bytes32 _xPoint, bytes32 _yPoint) internal pure returns( bytes20 hashedPubKey )	{
		bytes1 startingByte = 0x04;
 		return ripemd160(sha256(startingByte, _xPoint, _yPoint));
	}
	
	function btcAddrPubKeyCompr(bytes32 _x, bytes32 _y) internal pure returns( bytes20 hashedPubKey )	{
	    bytes1 _startingByte;
	    if (uint256(_y) % 2 == 0  ) {
            _startingByte = 0x02;
        } else {
            _startingByte = 0x03;
        }
 		return ripemd160(sha256(_startingByte, _x));
	}
	
	function ethAddressPublicKey( bytes32 _xPoint, bytes32 _yPoint) internal pure returns( address ethAddr )	{
 		return address(keccak256(_xPoint, _yPoint) ); 
	}
	 
    function toAsciiString(address x) internal pure returns (string) {
        bytes memory s = new bytes(42);
        s[0] = 0x30;
        s[1] = 0x78;
        for (uint i = 0; i < 20; i++) {
            byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2+2*i] = char(hi);
            s[2+2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    function char(byte b) internal pure returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }
    
     
}

contract Swap is Ownable, Library {
    using SafeMath for uint256;
    tokenInterface public tokenContract;
	Data public dataContract;
    
    mapping(address => bool) claimed;

    function Swap(address _tokenAddress) public {
        tokenContract = tokenInterface(_tokenAddress);
    }

    function claim(address _ethAddrReceiver, bytes32 _x, bytes32 _y, uint8 _v, bytes32 _r, bytes32 _s) public returns(bool) {
        require ( dataContract != address(0) );
        
		 
        address btcAddr0x; 
		btcAddr0x = address( btcAddrPubKeyCompr(_x,_y) ); 
		if( dataContract.CftBalanceOf( btcAddr0x ) == 0 || claimed[ btcAddr0x ] ) {  
			btcAddr0x = address( btcAddrPubKeyUncompr(_x,_y) ); 
		}
		
		require ( dataContract.CftBalanceOf( btcAddr0x ) != 0 );
        require ( !claimed[ btcAddr0x ] );
		
		address checkEthAddr0x = address( ethAddressPublicKey(_x,_y) );  
        require ( validateBSM( toAsciiString(_ethAddrReceiver), checkEthAddr0x, _v, _r, _s) );  
        
         
         
        uint256 tokenAmount = dataContract.CftBalanceOf(btcAddr0x) * 10**10 / 2; 
        
        claimed[btcAddr0x] = true;
        
        tokenContract.transfer(_ethAddrReceiver, tokenAmount);
        
        return true;
    }

    function withdrawTokens(address to, uint256 value) public onlyOwner returns (bool) {
        return tokenContract.transfer(to, value);
    }
    
    function setTokenContract(address _tokenContract) public onlyOwner {
        tokenContract = tokenInterface(_tokenContract);
    }
    
    function setDataContract(address _tokenContract) public onlyOwner {
        dataContract = Data(_tokenContract);
    }

    function () public payable {
        revert();
    }
}


contract Data {
    mapping(address => uint256) public CftBalanceOf;
       function Data() public {
            }
}