 

pragma solidity 0.4.15;

 
contract IAccessPolicy {

     
     
     

     
     
     
     
     
     
     
    function allowed(
        address subject,
        bytes32 role,
        address object,
        bytes4 verb
    )
        public
        returns (bool);
}

 
 
contract IAccessControlled {

     
     
     

     
    event LogAccessPolicyChanged(
        address controller,
        IAccessPolicy oldPolicy,
        IAccessPolicy newPolicy
    );

     
     
     

     
     
     
     
     
     
    function setAccessPolicy(IAccessPolicy newPolicy, address newAccessController)
        public;

    function accessPolicy()
        public
        constant
        returns (IAccessPolicy);

}

contract StandardRoles {

     
     
     

     
     
    bytes32 internal constant ROLE_ACCESS_CONTROLLER = 0xac42f8beb17975ed062dcb80c63e6d203ef1c2c335ced149dc5664cc671cb7da;
}

 
 
 
 
 
 
contract AccessControlled is IAccessControlled, StandardRoles {

     
     
     

    IAccessPolicy private _accessPolicy;

     
     
     

     
    modifier only(bytes32 role) {
        require(_accessPolicy.allowed(msg.sender, role, this, msg.sig));
        _;
    }

     
     
     

    function AccessControlled(IAccessPolicy policy) internal {
        require(address(policy) != 0x0);
        _accessPolicy = policy;
    }

     
     
     

     
     
     

    function setAccessPolicy(IAccessPolicy newPolicy, address newAccessController)
        public
        only(ROLE_ACCESS_CONTROLLER)
    {
         
         
         
        require(newPolicy.allowed(newAccessController, ROLE_ACCESS_CONTROLLER, this, msg.sig));

         
        IAccessPolicy oldPolicy = _accessPolicy;
        _accessPolicy = newPolicy;

         
        LogAccessPolicyChanged(msg.sender, oldPolicy, newPolicy);
    }

    function accessPolicy()
        public
        constant
        returns (IAccessPolicy)
    {
        return _accessPolicy;
    }
}

contract AccessRoles {

     
     
     

     
     
     

     
    bytes32 internal constant ROLE_LOCKED_ACCOUNT_ADMIN = 0x4675da546d2d92c5b86c4f726a9e61010dce91cccc2491ce6019e78b09d2572e;

     
    bytes32 internal constant ROLE_WHITELIST_ADMIN = 0xaef456e7c864418e1d2a40d996ca4febf3a7e317fe3af5a7ea4dda59033bbe5c;

     
    bytes32 internal constant ROLE_NEUMARK_ISSUER = 0x921c3afa1f1fff707a785f953a1e197bd28c9c50e300424e015953cbf120c06c;

     
    bytes32 internal constant ROLE_NEUMARK_BURNER = 0x19ce331285f41739cd3362a3ec176edffe014311c0f8075834fdd19d6718e69f;

     
    bytes32 internal constant ROLE_SNAPSHOT_CREATOR = 0x08c1785afc57f933523bc52583a72ce9e19b2241354e04dd86f41f887e3d8174;

     
    bytes32 internal constant ROLE_TRANSFER_ADMIN = 0xb6527e944caca3d151b1f94e49ac5e223142694860743e66164720e034ec9b19;

     
    bytes32 internal constant ROLE_RECLAIMER = 0x0542bbd0c672578966dcc525b30aa16723bb042675554ac5b0362f86b6e97dc5;

     
    bytes32 internal constant ROLE_PLATFORM_OPERATOR_REPRESENTATIVE = 0xb2b321377653f655206f71514ff9f150d0822d062a5abcf220d549e1da7999f0;

     
    bytes32 internal constant ROLE_EURT_DEPOSIT_MANAGER = 0x7c8ecdcba80ce87848d16ad77ef57cc196c208fc95c5638e4a48c681a34d4fe7;
}

contract IBasicToken {

     
     
     

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount);

     
     
     

     
     
    function totalSupply()
        public
        constant
        returns (uint256);

     
     
    function balanceOf(address owner)
        public
        constant
        returns (uint256 balance);

     
     
     
     
    function transfer(address to, uint256 amount)
        public
        returns (bool success);

}

 
 
 
 
 
 
 
contract Reclaimable is AccessControlled, AccessRoles {

     
     
     

    IBasicToken constant internal RECLAIM_ETHER = IBasicToken(0x0);

     
     
     

    function reclaim(IBasicToken token)
        public
        only(ROLE_RECLAIMER)
    {
        address reclaimer = msg.sender;
        if(token == RECLAIM_ETHER) {
            reclaimer.transfer(this.balance);
        } else {
            uint256 balance = token.balanceOf(this);
            require(token.transfer(reclaimer, balance));
        }
    }
}

contract IEthereumForkArbiter {

     
     
     

    event LogForkAnnounced(
        string name,
        string url,
        uint256 blockNumber
    );

    event LogForkSigned(
        uint256 blockNumber,
        bytes32 blockHash
    );

     
     
     

    function nextForkName()
        public
        constant
        returns (string);

    function nextForkUrl()
        public
        constant
        returns (string);

    function nextForkBlockNumber()
        public
        constant
        returns (uint256);

    function lastSignedBlockNumber()
        public
        constant
        returns (uint256);

    function lastSignedBlockHash()
        public
        constant
        returns (bytes32);

    function lastSignedTimestamp()
        public
        constant
        returns (uint256);

}

contract EthereumForkArbiter is
    IEthereumForkArbiter,
    AccessControlled,
    AccessRoles,
    Reclaimable
{
     
     
     

    string private _nextForkName;

    string private _nextForkUrl;

    uint256 private _nextForkBlockNumber;

    uint256 private _lastSignedBlockNumber;

    bytes32 private _lastSignedBlockHash;

    uint256 private _lastSignedTimestamp;

     
     
     

    function EthereumForkArbiter(IAccessPolicy accessPolicy)
        AccessControlled(accessPolicy)
        Reclaimable()
        public
    {
    }

     
     
     

     
    function announceFork(
        string name,
        string url,
        uint256 blockNumber
    )
        public
        only(ROLE_PLATFORM_OPERATOR_REPRESENTATIVE)
    {
        require(blockNumber == 0 || blockNumber > block.number);

         
        _nextForkName = name;
        _nextForkUrl = url;
        _nextForkBlockNumber = blockNumber;

         
        LogForkAnnounced(_nextForkName, _nextForkUrl, _nextForkBlockNumber);
    }

     
    function signFork(uint256 number, bytes32 hash)
        public
        only(ROLE_PLATFORM_OPERATOR_REPRESENTATIVE)
    {
        require(block.blockhash(number) == hash);

         
        delete _nextForkName;
        delete _nextForkUrl;
        delete _nextForkBlockNumber;

         
        _lastSignedBlockNumber = number;
        _lastSignedBlockHash = hash;
        _lastSignedTimestamp = block.timestamp;

         
        LogForkSigned(_lastSignedBlockNumber, _lastSignedBlockHash);
    }

    function nextForkName()
        public
        constant
        returns (string)
    {
        return _nextForkName;
    }

    function nextForkUrl()
        public
        constant
        returns (string)
    {
        return _nextForkUrl;
    }

    function nextForkBlockNumber()
        public
        constant
        returns (uint256)
    {
        return _nextForkBlockNumber;
    }

    function lastSignedBlockNumber()
        public
        constant
        returns (uint256)
    {
        return _lastSignedBlockNumber;
    }

    function lastSignedBlockHash()
        public
        constant
        returns (bytes32)
    {
        return _lastSignedBlockHash;
    }

    function lastSignedTimestamp()
        public
        constant
        returns (uint256)
    {
        return _lastSignedTimestamp;
    }
}