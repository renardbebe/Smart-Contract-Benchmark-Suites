 

pragma solidity ^0.4.13;

library MerkleProof {
   
  function verifyProof(bytes _proof, bytes32 _root, bytes32 _leaf) public pure returns (bool) {
     
    if (_proof.length % 32 != 0) return false;

    bytes32 proofElement;
    bytes32 computedHash = _leaf;

    for (uint256 i = 32; i <= _proof.length; i += 32) {
      assembly {
         
        proofElement := mload(add(_proof, i))
      }

      if (computedHash < proofElement) {
         
        computedHash = keccak256(computedHash, proofElement);
      } else {
         
        computedHash = keccak256(proofElement, computedHash);
      }
    }

     
    return computedHash == _root;
  }
}

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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

contract DelayedReleaseToken is StandardToken {

     
    address temporaryAdmin;

     
    bool hasBeenReleased = false;

     
    uint numberOfDelayedTokens;

     
    event TokensReleased(address destination, uint numberOfTokens);

     
    function releaseTokens(address destination) public {
        require((msg.sender == temporaryAdmin) && (!hasBeenReleased));
        hasBeenReleased = true;
        balances[destination] = numberOfDelayedTokens;
        Transfer(address(0), destination, numberOfDelayedTokens); 
        TokensReleased(destination, numberOfDelayedTokens);
    }

}

contract UTXORedeemableToken is StandardToken {

     
    bytes32 public rootUTXOMerkleTreeHash;

     
    mapping(bytes32 => bool) redeemedUTXOs;

     
    uint public multiplier;

     
    uint public totalRedeemed = 0;

     
    uint public maximumRedeemable;

     
    event UTXORedeemed(bytes32 txid, uint8 outputIndex, uint satoshis, bytes proof, bytes pubKey, uint8 v, bytes32 r, bytes32 s, address indexed redeemer, uint numberOfTokens);

     
    function extract(bytes data, uint pos) private pure returns (bytes32 result) { 
        for (uint i = 0; i < 32; i++) {
            result ^= (bytes32(0xff00000000000000000000000000000000000000000000000000000000000000) & data[i + pos]) >> (i * 8);
        }
        return result;
    }
    
     
    function validateSignature (bytes32 hash, uint8 v, bytes32 r, bytes32 s, address expected) public pure returns (bool) {
        return ecrecover(hash, v, r, s) == expected;
    }

     
    function ecdsaVerify (address addr, bytes pubKey, uint8 v, bytes32 r, bytes32 s) public pure returns (bool) {
        return validateSignature(sha256(addr), v, r, s, pubKeyToEthereumAddress(pubKey));
    }

     
    function pubKeyToEthereumAddress (bytes pubKey) public pure returns (address) {
        return address(uint(keccak256(pubKey)) & 0x000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }

     
    function pubKeyToBitcoinAddress(bytes pubKey, bool isCompressed) public pure returns (bytes20) {
         

         
        uint x = uint(extract(pubKey, 0));
         
        uint y = uint(extract(pubKey, 32)); 
        uint8 startingByte;
        if (isCompressed) {
             
            startingByte = y % 2 == 0 ? 0x02 : 0x03;
            return ripemd160(sha256(startingByte, x));
        } else {
             
            startingByte = 0x04;
            return ripemd160(sha256(startingByte, x, y));
        }
    }

     
    function verifyProof(bytes proof, bytes32 merkleLeafHash) public constant returns (bool) {
        return MerkleProof.verifyProof(proof, rootUTXOMerkleTreeHash, merkleLeafHash);
    }

     
    function canRedeemUTXO(bytes32 txid, bytes20 originalAddress, uint8 outputIndex, uint satoshis, bytes proof) public constant returns (bool) {
         
        bytes32 merkleLeafHash = keccak256(txid, originalAddress, outputIndex, satoshis);
    
         
        return canRedeemUTXOHash(merkleLeafHash, proof);
    }
      
     
    function canRedeemUTXOHash(bytes32 merkleLeafHash, bytes proof) public constant returns (bool) {
         
        return((redeemedUTXOs[merkleLeafHash] == false) && verifyProof(proof, merkleLeafHash));
    }

     
    function redeemUTXO (bytes32 txid, uint8 outputIndex, uint satoshis, bytes proof, bytes pubKey, bool isCompressed, uint8 v, bytes32 r, bytes32 s) public returns (uint tokensRedeemed) {

         
        bytes20 originalAddress = pubKeyToBitcoinAddress(pubKey, isCompressed);

         
        bytes32 merkleLeafHash = keccak256(txid, originalAddress, outputIndex, satoshis);

         
        require(canRedeemUTXOHash(merkleLeafHash, proof));

         
        require(ecdsaVerify(msg.sender, pubKey, v, r, s));

         
        redeemedUTXOs[merkleLeafHash] = true;

         
        tokensRedeemed = SafeMath.mul(satoshis, multiplier);

         
        totalRedeemed = SafeMath.add(totalRedeemed, tokensRedeemed);

         
        require(totalRedeemed <= maximumRedeemable);

          
        balances[msg.sender] = SafeMath.add(balances[msg.sender], tokensRedeemed);

         
        Transfer(address(0), msg.sender, tokensRedeemed);

         
        UTXORedeemed(txid, outputIndex, satoshis, proof, pubKey, v, r, s, msg.sender, tokensRedeemed);
        
         
        return tokensRedeemed;

    }

}

contract WyvernToken is DelayedReleaseToken, UTXORedeemableToken, BurnableToken {

    uint constant public decimals     = 18;
    string constant public name       = "Project Wyvern Token";
    string constant public symbol     = "WYV";

     
    uint constant public MULTIPLIER       = 1;

     
    uint constant public SATS_TO_TOKENS   = MULTIPLIER * (10 ** decimals) / (10 ** 8);

     
    uint constant public MINT_AMOUNT      = 2000000 * MULTIPLIER * (10 ** decimals);

     
    function WyvernToken (bytes32 merkleRoot, uint totalUtxoAmount) public {
         
        uint utxoTokens = SATS_TO_TOKENS * totalUtxoAmount;

         
        temporaryAdmin = msg.sender;
        numberOfDelayedTokens = MINT_AMOUNT - utxoTokens;

         
        rootUTXOMerkleTreeHash = merkleRoot;
        totalSupply = MINT_AMOUNT;
        maximumRedeemable = utxoTokens;
        multiplier = SATS_TO_TOKENS;
    }

}