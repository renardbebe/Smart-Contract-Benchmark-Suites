 

pragma solidity ^0.5.0;



 


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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


contract ECRecovery {

   
  function recover(bytes32 hash, bytes memory sig) internal  pure returns (address) {
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
      return ecrecover(hash, v, r, s);
    }
  }

}



contract RelayAuthorityInterface {
    function getRelayAuthority() public returns (address);
}


contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}


contract LavaToken is ECRecovery{

    using SafeMath for uint;

    address constant public masterToken = 0xB6eD7644C69416d67B522e20bC294A9a9B405B31;

    string public name     = "Lava";
    string public symbol   = "LAVA";
    uint8  public decimals = 8;
    uint private _totalSupply;

    event  Approval(address indexed src, address indexed ext, uint amt);
    event  Transfer(address indexed src, address indexed dst, uint amt);
    event  Deposit(address indexed dst, uint amt);
    event  Withdrawal(address indexed src, uint amt);

    mapping (address => uint)                       public  balances;
    mapping (address => mapping (address => uint))  public  allowance;

    mapping (bytes32 => uint256)                    public burnedSignatures;


  struct LavaPacket {
    string methodName;  
    address relayAuthority;  
    address from;  
    address to;  
    address wallet;   
    uint256 tokens;  
    uint256 relayerRewardTokens;  
    uint256 expires;  
    uint256 nonce;  
  }




   bytes32 constant LAVAPACKET_TYPEHASH = keccak256(
      "LavaPacket(string methodName,address relayAuthority,address from,address to,address wallet,uint256 tokens,uint256 relayerRewardTokens,uint256 expires,uint256 nonce)"
  );

   function getLavaPacketTypehash() public pure returns (bytes32) {
      return LAVAPACKET_TYPEHASH;
  }

 function getLavaPacketHash(string memory methodName, address relayAuthority,address from,address to, address wallet,uint256 tokens,uint256 relayerRewardTokens,uint256 expires,uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encode(
            LAVAPACKET_TYPEHASH,
            keccak256(bytes(methodName)),
            relayAuthority,
            from,
            to,
            wallet,
            tokens,
            relayerRewardTokens,
            expires,
            nonce
        ));
    }


    constructor() public {

    }

     
     function() external payable
     {
         revert();
     }


     
    function mutateTokens(address from, uint amount) public returns (bool)
    {

        require( amount >= 0 );

        require( ERC20Interface( masterToken ).transferFrom( from, address(this), amount) );

        balances[from] = balances[from].add(amount);
        _totalSupply = _totalSupply.add(amount);

        return true;
    }



     
    function unmutateTokens( uint amount) public returns (bool)
    {
        address from = msg.sender;
        require( amount >= 0 );

        balances[from] = balances[from].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        require( ERC20Interface( masterToken ).transfer( from, amount) );

        return true;
    }



    
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    
     function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

      
    function getAllowance(address owner, address spender) public view returns (uint)
    {
      return allowance[owner][spender];
    }

    
  function approve(address spender,   uint tokens) public returns (bool success) {
      allowance[msg.sender][spender] = tokens;
      emit Approval(msg.sender, spender, tokens);
      return true;
  }


   
   function transfer(address to,  uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    
   function transferFrom( address from, address to,  uint tokens) public returns (bool success) {
       balances[from] = balances[from].sub(tokens);
       allowance[from][to] = allowance[from][to].sub(tokens);
       balances[to] = balances[to].add(tokens);
       emit Transfer( from, to, tokens);
       return true;
   }

   
   function _giveRelayerReward( address from, address to, uint tokens) internal returns (bool success){
     balances[from] = balances[from].sub(tokens);
     balances[to] = balances[to].add(tokens);
     emit Transfer( from, to, tokens);
     return true;
   }


     

   function getLavaTypedDataHash(string memory methodName, address relayAuthority,address from,address to, address wallet,uint256 tokens,uint256 relayerRewardTokens,uint256 expires,uint256 nonce) public  pure returns (bytes32) {


           
          bytes32 digest = keccak256(abi.encodePacked(
              "\x19\x01",
             
              getLavaPacketHash(methodName,relayAuthority,from,to,wallet,tokens,relayerRewardTokens,expires,nonce)
          ));
          return digest;
      }



     

   function _tokenApprovalWithSignature(  string memory methodName, address relayAuthority,address from,address to, address wallet,uint256 tokens,uint256 relayerRewardTokens,uint256 expires,uint256 nonce, bytes32 sigHash, bytes memory signature) internal returns (bool success)
   {

        


       require( relayAuthority == address(0x0)
         || (!addressContainsContract(relayAuthority) && msg.sender == relayAuthority)
         || (addressContainsContract(relayAuthority) && msg.sender == RelayAuthorityInterface(relayAuthority).getRelayAuthority())  );



       address recoveredSignatureSigner = recover(sigHash,signature);


        
       require(from == recoveredSignatureSigner);

        
       require(address(this) == wallet);

        
       require(block.number < expires);

       uint previousBurnedSignatureValue = burnedSignatures[sigHash];
       burnedSignatures[sigHash] = 0x1;  
       require(previousBurnedSignatureValue == 0x0);

        
       require(_giveRelayerReward(from, msg.sender,   relayerRewardTokens));

        
       allowance[from][to] = tokens;
       emit Approval(from,  to, tokens);


       return true;
   }



   function approveTokensWithSignature(string memory methodName, address relayAuthority,address from,address to, address wallet,uint256 tokens,uint256 relayerRewardTokens,uint256 expires,uint256 nonce, bytes memory signature) public returns (bool success)
   {
       require(bytesEqual('approve',bytes(methodName)));

       bytes32 sigHash = getLavaTypedDataHash(methodName,relayAuthority,from,to,wallet,tokens,relayerRewardTokens,expires,nonce);

       require(_tokenApprovalWithSignature(methodName,relayAuthority,from,to,wallet,tokens,relayerRewardTokens,expires,nonce,sigHash,signature));


       return true;
   }


  function transferTokensWithSignature(string memory methodName, address relayAuthority,address from,address to, address wallet,uint256 tokens,uint256 relayerRewardTokens,uint256 expires,uint256 nonce, bytes memory signature) public returns (bool success)
  {

      require(bytesEqual('transfer',bytes(methodName)));

       
      bytes32 sigHash = getLavaTypedDataHash(methodName,relayAuthority,from,to,wallet,tokens,relayerRewardTokens,expires,nonce);

      require(_tokenApprovalWithSignature(methodName,relayAuthority,from,to,wallet,tokens,relayerRewardTokens,expires,nonce,sigHash,signature));

       
      require(transferFrom( from, to,  tokens));


      return true;

  }


      
     function approveAndCallWithSignature( string memory methodName, address relayAuthority,address from,address to, address wallet,uint256 tokens,uint256 relayerRewardTokens,uint256 expires,uint256 nonce, bytes memory signature ) public returns (bool success)   {

          require(!bytesEqual('approve',bytes(methodName))  && !bytesEqual('transfer',bytes(methodName)));

            
          bytes32 sigHash = getLavaTypedDataHash(methodName,relayAuthority,from,to,wallet,tokens,relayerRewardTokens,expires,nonce);

          require(_tokenApprovalWithSignature(methodName,relayAuthority,from,to,wallet,tokens,relayerRewardTokens,expires,nonce,sigHash,signature));

          _sendApproveAndCall(from,to,tokens,bytes(methodName));

           return true;
     }

     function _sendApproveAndCall(address from, address to, uint tokens, bytes memory methodName) internal
     {
         ApproveAndCallFallBack(to).receiveApproval(from, tokens, address(this), bytes(methodName));
     }




     

     function burnSignature( string memory methodName, address relayAuthority,address from,address to, address wallet,uint256 tokens,uint256 relayerRewardTokens,uint256 expires,uint256 nonce,  bytes memory signature) public returns (bool success)
     {


        bytes32 sigHash = getLavaTypedDataHash(methodName,relayAuthority,from,to,wallet,tokens,relayerRewardTokens,expires,nonce);

         address recoveredSignatureSigner = recover(sigHash,signature);

          
         require(recoveredSignatureSigner == from);

          
         require(from == msg.sender);

          
         uint burnedSignature = burnedSignatures[sigHash];
         burnedSignatures[sigHash] = 0x2;  
         require(burnedSignature == 0x0);

         return true;
     }


     
     function signatureHashBurnStatus(bytes32 digest) public view returns (uint)
     {
       return (burnedSignatures[digest]);
     }




        
     function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public returns (bool success) {

        require(token == masterToken);

        require(mutateTokens(from, tokens));

        return true;

     }




     function addressContainsContract(address _to) view internal returns (bool)
     {
       uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

         return (codeLength>0);
     }


     function bytesEqual(bytes memory b1,bytes memory b2) pure internal returns (bool)
        {
          if(b1.length != b2.length) return false;

          for (uint i=0; i<b1.length; i++) {
            if(b1[i] != b2[i]) return false;
          }

          return true;
        }




}