 

pragma solidity ^0.4.0;


library ECVerifyLib {
     
     
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
         
         
         
         
         

         
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)

             
             
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }

        return (ret, addr);
    }

    function ecrecovery(bytes32 hash, bytes sig) returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
          return (false, 0);

         
         
         
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))

             
             
             
            v := byte(0, mload(add(sig, 96)))

             
             
             
             
        }

         
         
         
         
         
        if (v < 27)
          v += 27;

        if (v != 27 && v != 28)
            return (false, 0);

        return safer_ecrecover(hash, v, r, s);
    }

    function ecverify(bytes32 hash, bytes sig, address signer) returns (bool) {
        bool ret;
        address addr;
        (ret, addr) = ecrecovery(hash, sig);
        return ret == true && addr == signer;
    }
}


contract IndividualityTokenInterface {
     
    event Mint(address indexed _owner, bytes32 _tokenID);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     

     
    function totalSupply() constant returns (uint256 supply);

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

     

     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transfer(address _to) public returns (bool success);

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to) public returns (bool success);

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);
    function approve(address _spender) public returns (bool success);

     

     
     
    function isTokenOwner(address _owner) constant returns (bool);

     
     
    function ownerOf(bytes32 _tokenID) constant returns (address owner);

     
     
    function tokenId(address _owner) constant returns (bytes32 tokenID);
}


contract IndividualityTokenRootInterface is IndividualityTokenInterface {
     
    function upgrade() public returns (bool success);

     
     
     
     
    function proxyUpgrade(address _owner,
                          address _newOwner,
                          bytes signature) public returns (bool);

     
    function upgradeCount() constant returns (uint256 amount);

     
     
    function isTokenUpgraded(bytes32 _tokenID) constant returns (bool isUpgraded);
}


library TokenEventLib {
     
    event Transfer(address indexed _from,
                   address indexed _to,
                   bytes32 indexed _tokenID);
    event Approval(address indexed _owner,
                   address indexed _spender,
                   bytes32 indexed _tokenID);

    function _Transfer(address _from, address _to, bytes32 _tokenID) public {
        Transfer(_from, _to, _tokenID);
    }

    function _Approval(address _owner, address _spender, bytes32 _tokenID) public {
        Approval(_owner, _spender, _tokenID);
    }
}


contract TokenInterface {
     
    event Mint(address indexed _to, bytes32 _id);
    event Destroy(bytes32 _id);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event MinterAdded(address who);
    event MinterRemoved(address who);

     
     
     
     
    function mint(address _to, string _identity) returns (bool success);

     
     
    function destroy(bytes32 _id) returns (bool success);

     
     
    function addMinter(address who) returns (bool);

     
     
    function removeMinter(address who) returns (bool);

     

     
    function totalSupply() returns (uint supply);

     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);
    function transfer(address _to, bytes32 _value) returns (bool success);

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, bytes32 _value) returns (bool success);

     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);
    function approve(address _spender, bytes32 _value) returns (bool success);

     
     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

     
     
     
    function isTokenOwner(address _owner) constant returns (bool);

     
     
    function identityOf(bytes32 _id) constant returns (string identity);

     
     
    function ownerOf(bytes32 _id) constant returns (address owner);
}


contract IndividualityTokenRoot is IndividualityTokenRootInterface {
    TokenInterface public devcon2Token;

    function IndividualityTokenRoot(address _devcon2Token) {
        devcon2Token = TokenInterface(_devcon2Token);
    }

     
    mapping (address => bytes32) ownerToToken;

     
    mapping (bytes32 => address) tokenToOwner;

     
    mapping (address => mapping (address => bytes32)) approvals;

    uint _upgradeCount;

     
    function isEligibleForUpgrade(address _owner) internal returns (bool) {
        if (ownerToToken[_owner] != 0x0) {
             
            return false;
        } else if (!devcon2Token.isTokenOwner(_owner)) {
             
            return false;
        } else if (isTokenUpgraded(bytes32(devcon2Token.balanceOf(_owner)))) {
             
            return false;
        } else {
            return true;
        }
    }

     
    modifier silentUpgrade {
        if (isEligibleForUpgrade(msg.sender)) {
            upgrade();
        }
        _;
    }


     
    function totalSupply() constant returns (uint256) {
        return devcon2Token.totalSupply();
    }

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        if (_owner == 0x0) {
            return 0;
        } else if (ownerToToken[_owner] == 0x0) {
             
             
            if (devcon2Token.isTokenOwner(_owner)) {
                 
                var tokenID = bytes32(devcon2Token.balanceOf(_owner));

                if (tokenToOwner[tokenID] == 0x0) {
                     
                    return 1;
                }
            }
            return 0;
        } else {
            return 1;
        }
    }

     
     
     
    function allowance(address _owner,
                       address _spender) constant returns (uint256 remaining) {
        var approvedTokenID = approvals[_owner][_spender];

        if (approvedTokenID == 0x0) {
            return 0;
        } else if (_owner == 0x0 || _spender == 0x0) {
            return 0;
        } else if (tokenToOwner[approvedTokenID] == _owner) {
            return 1;
        } else {
            return 0;
        }
    }

     
     
     
    function transfer(address _to,
                      uint256 _value) public silentUpgrade returns (bool success) {
        if (_value != 1) {
             
            return false;
        } else if (_to == 0x0) {
             
            return false;
        } else if (ownerToToken[msg.sender] == 0x0) {
             
            return false;
        } else if (ownerToToken[_to] != 0x0) {
             
            return false;
        } else if (isEligibleForUpgrade(_to)) {
             
             
            return false;
        }

         
        var tokenID = ownerToToken[msg.sender];

         
        ownerToToken[msg.sender] = 0x0;

         
        ownerToToken[_to] = tokenID;
        tokenToOwner[tokenID] = _to;

         
        Transfer(msg.sender, _to, 1);
        TokenEventLib._Transfer(msg.sender, _to, tokenID);

        return true;
    }

     
     
    function transfer(address _to) public returns (bool success) {
        return transfer(_to, 1);
    }

     
     
     
     
    function transferFrom(address _from,
                          address _to,
                          uint256 _value) public returns (bool success) {
        if (_value != 1) {
             
            return false;
        } else if (_to == 0x0) {
             
            return false;
        } else if (ownerToToken[_from] == 0x0) {
             
            return false;
        } else if (ownerToToken[_to] != 0x0) {
             
            return false;
        } else if (approvals[_from][msg.sender] != ownerToToken[_from]) {
             
            return false;
        } else if (isEligibleForUpgrade(_to)) {
             
             
            return false;
        }

         
        var tokenID = ownerToToken[_from];

         
        approvals[_from][msg.sender] = 0x0;

         
        ownerToToken[_from] = 0x0;

         
        ownerToToken[_to] = tokenID;
        tokenToOwner[tokenID] = _to;

         
        Transfer(_from, _to, 1);
        TokenEventLib._Transfer(_from, _to, tokenID);

        return true;
    }

     
     
     
    function transferFrom(address _from, address _to) public returns (bool success) {
        return transferFrom(_from, _to, 1);
    }

     
     
     
    function approve(address _spender,
                     uint256 _value) public silentUpgrade returns (bool success) {
        if (_value != 1) {
             
            return false;
        } else if (_spender == 0x0) {
             
            return false;
        } else if (ownerToToken[msg.sender] == 0x0) {
             
            return false;
        }

        var tokenID = ownerToToken[msg.sender];
        approvals[msg.sender][_spender] = tokenID;

        Approval(msg.sender, _spender, 1);
        TokenEventLib._Approval(msg.sender, _spender, tokenID);

        return true;
    }

     
     
    function approve(address _spender) public returns (bool success) {
        return approve(_spender, 1);
    }

     
     
     
    function isTokenOwner(address _owner) constant returns (bool) {
        if (_owner == 0x0) {
            return false;
        } else if (ownerToToken[_owner] == 0x0) {
             
            if (devcon2Token.isTokenOwner(_owner)) {
                 
                var tokenID = bytes32(devcon2Token.balanceOf(_owner));

                if (tokenToOwner[tokenID] == 0x0) {
                     
                     
                    return true;
                }
            }
            return false;
        } else {
            return true;
        }
    }

     
     
    function ownerOf(bytes32 _tokenID) constant returns (address owner) {
        if (_tokenID == 0x0) {
            return 0x0;
        } else if (tokenToOwner[_tokenID] != 0x0) {
            return tokenToOwner[_tokenID];
        } else {
            return devcon2Token.ownerOf(_tokenID);
        }
    }

     
     
    function tokenId(address _owner) constant returns (bytes32 tokenID) {
        if (_owner == 0x0) {
            return 0x0;
        } else if (ownerToToken[_owner] != 0x0) {
            return ownerToToken[_owner];
        } else {
            tokenID = bytes32(devcon2Token.balanceOf(_owner));
            if (tokenToOwner[tokenID] == 0x0) {
                 
                 
                return tokenID;
            } else {
                 
                 
                return 0x0;
            }
        }
    }

     
    function upgrade() public returns (bool success) {
        if (!devcon2Token.isTokenOwner(msg.sender)) {
             
            return false;
        } else if (ownerToToken[msg.sender] != 0x0) {
             
            return false;
        }
        
         
        var tokenID = bytes32(devcon2Token.balanceOf(msg.sender));

        if (tokenID == 0x0) {
             
             
            return false;
        } else if (tokenToOwner[tokenID] != 0x0) {
             
            return false;
        } else if (devcon2Token.ownerOf(tokenID) != msg.sender) {
             
             
            return false;
        }

         
        ownerToToken[msg.sender] = tokenID;
        tokenToOwner[tokenID] = msg.sender;

         
        _upgradeCount += 1;

         
        Mint(msg.sender, tokenID);
        return true;
    }

     
     
     
     
    function proxyUpgrade(address _owner,
                          address _newOwner,
                          bytes signature) public returns (bool) {
        if (_owner == 0x0 || _newOwner == 0x0) {
             
            return false;
        } else if (!devcon2Token.isTokenOwner(_owner)) {
             
            return false;
        }

        bytes32 tokenID = bytes32(devcon2Token.balanceOf(_owner));

        if (tokenID == 0x0) {
             
             
            return false;
        } else if (isTokenUpgraded(tokenID)) {
             
            return false;
        } else if (ownerToToken[_newOwner] != 0x0) {
             
            return false;
        } else if (_owner != _newOwner && isEligibleForUpgrade(_newOwner)) {
             
             
            return false;
        }

        bytes32 signatureHash = sha3(address(this), _owner, _newOwner);

        if (!ECVerifyLib.ecverify(signatureHash, signature, _owner)) {
            return false;
        }

         
        tokenToOwner[tokenID] = _newOwner;
        ownerToToken[_newOwner] = tokenID;

         
        _upgradeCount += 1;

         
        Mint(_newOwner, tokenID);

        return true;
    }

     
    function upgradeCount() constant returns (uint256 _amount) {
        return _upgradeCount;
    }

     
     
    function isTokenUpgraded(bytes32 _tokenID) constant returns (bool isUpgraded) {
        return (tokenToOwner[_tokenID] != 0x0);
    }
}


contract MainnetIndividualityTokenRoot is 
         IndividualityTokenRoot(0x0a43edfe106d295e7c1e591a4b04b5598af9474c) {
}