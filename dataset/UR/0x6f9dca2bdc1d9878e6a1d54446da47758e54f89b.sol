 

pragma solidity ^0.4.25;

 


 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
contract ECRecovery {
    function recover(bytes32 hash, bytes sig) public pure returns (address);
}


 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);

        emit OwnershipTransferred(owner, newOwner);

        owner = newOwner;

        newOwner = address(0);
    }
}


 
contract Zer0netDbInterface {
     
    function getAddress(bytes32 _key) external view returns (address);
    function getBool(bytes32 _key)    external view returns (bool);
    function getBytes(bytes32 _key)   external view returns (bytes);
    function getInt(bytes32 _key)     external view returns (int);
    function getString(bytes32 _key)  external view returns (string);
    function getUint(bytes32 _key)    external view returns (uint);

     
    function setAddress(bytes32 _key, address _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setBytes(bytes32 _key, bytes _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setString(bytes32 _key, string _value) external;
    function setUint(bytes32 _key, uint _value) external;

     
    function deleteAddress(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
}


 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
contract InfinityPoolInterface {
    function transfer(address _token, address _to, uint _tokens) external returns (bool success);
}


 
contract InfinityWellInterface {
    function forgeStones(address _owner, uint _tokens) external returns (bool success);
    function destroyStones(address _owner, uint _tokens) external returns (bool success);
    function transferERC20(address _token, address _to, uint _tokens) external returns (bool success);
    function transferERC721(address _token, address _to, uint256 _tokenId) external returns (bool success);
}


 
contract StaekFactoryInterface {
    function balanceOf(bytes32 _staekhouseId) public view returns (uint balance);
    function balanceOf(bytes32 _staekhouseId, address _owner) public view returns (uint balance);
    function getStaekhouse(bytes32 _staekhouseId, address _staeker) external view returns (address factory, address token, address owner, uint ownerLockTime, uint providerLockTime, uint debtLimit, uint lockInterval, uint balance);
}


 
contract Minado is Owned {
    using SafeMath for uint;

     
    address private _predecessor;

     
    address private _successor;
    
     
    uint private _revision;

     
    Zer0netDbInterface private _zer0netDb;

     
    string private _namespace = 'minado';

     
    uint private _MAXIMUM_TARGET = 2**234;

     
    uint private _MINIMUM_TARGET = 2**16;

     
    uint private _BP_MUL = 10000;

     
    uint private _STONE_DECIMALS = 18;

     
    uint private _SINGLE_STONE = 1 * 10**_STONE_DECIMALS;
    
     
    uint private _BLOCKS_PER_STONE_FORGE = 1000;

     
    uint BLOCKS_PER_GENERATION = 40;  
     

     
    uint private _DEFAULT_GENERATIONS_PER_ADJUSTMENT = 144;  

    event Claim(
        address owner, 
        address token, 
        uint amount,
        address collectible,
        uint collectibleId
    );

    event Excavate(
        address indexed token, 
        address indexed miner, 
        uint mintAmount, 
        uint epochCount, 
        bytes32 newChallenge
    );
    
    event Mint(
        address indexed from, 
        uint rewardAmount, 
        uint epochCount, 
        bytes32 newChallenge
    );

    event ReCalculate(
        address token, 
        uint newDifficulty
    );

    event Solution(
        address indexed token, 
        address indexed miner, 
        uint difficulty,
        uint nonce,
        bytes32 challenge, 
        bytes32 newChallenge
    );

     
    constructor() public {
         
         
        _zer0netDb = Zer0netDbInterface(0xE865Fe1A1A3b342bF0E2fcB11fF4E3BCe58263af);
         
         

         
        bytes32 hash = keccak256(abi.encodePacked('aname.', _namespace));

         
        _predecessor = _zer0netDb.getAddress(hash);

         
        if (_predecessor != 0x0) {
             
            uint lastRevision = Minado(_predecessor).getRevision();
            
             
            _revision = lastRevision + 1;
        }
    }
    
     
    modifier onlyAuthBy0Admin() {
         
        require(_zer0netDb.getBool(keccak256(
            abi.encodePacked(msg.sender, '.has.auth.for.', _namespace))) == true);

        _;       
    }

     
    modifier onlyTokenProvider(
        address _token
    ) {
         
        require(_zer0netDb.getBool(keccak256(abi.encodePacked(
            _namespace, '.',
            msg.sender, 
            '.has.auth.for.', 
            _token
        ))) == true);

        _;       
    }

     
    function () public payable {
         
        revert('Oops! Direct payments are NOT permitted here.');
    }


     

     
    function init(
        address _token,
        address _provider
    ) external onlyAuthBy0Admin returns (bool success) {
         
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.last.adjustment'
        ));

         
        _zer0netDb.setUint(hash, block.number);

         
        hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.generations.per.adjustment'
        ));

         
        _zer0netDb.setUint(hash, _DEFAULT_GENERATIONS_PER_ADJUSTMENT);

         
        hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.challenge'
        ));

         
        _zer0netDb.setBytes(
            hash, 
            _bytes32ToBytes(blockhash(block.number - 1))
        );

         
         
        _setMiningTarget(
            _token, 
            _MAXIMUM_TARGET
        );

         
        hash = keccak256(abi.encodePacked(
            _namespace, '.',
            _provider, 
            '.has.auth.for.', 
            _token
        ));

         
        _zer0netDb.setBool(hash, true);

        return true;
    }

     
    function mint(
        address _token,
        bytes32 _digest,
        uint _nonce
    ) public returns (bool success) {
         
        uint challenge = getChallenge(_token);

         
        bytes32 digest = getMintDigest(
            challenge, 
            msg.sender, 
            _nonce
        );

         
        if (digest != _digest) {
            revert('Oops! That solution is NOT valid.');
        }

         
        if (uint(digest) > getTarget(_token)) {
            revert('Oops! That solution is NOT valid.');
        }

         
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            digest, 
            '.solutions'
        ));

         
        uint solution = _zer0netDb.getUint(hash);

         
        if (solution != 0x0) {
            revert('Oops! That solution is a DUPLICATE.');
        }

         
        _zer0netDb.setUint(hash, uint(digest));

         
        hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.generation'
        ));

         
        uint generation = _zer0netDb.getUint(hash);

         
        generation = generation.add(1);

         
        _zer0netDb.setUint(hash, generation);

         
        hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.generations.per.adjustment'
        ));

         
        uint genPerAdjustment = _zer0netDb.getUint(hash);

         
        if (generation % genPerAdjustment == 0) {
            _reAdjustDifficulty(_token);
        }

         
        hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.challenge'
        ));

         
        _zer0netDb.setBytes(
            hash, 
            _bytes32ToBytes(blockhash(block.number - 1))
        );

         
         
        uint rewardAmount = getMintFixed(_token);

         
        _infinityPool().transfer(
            _token, 
            msg.sender, 
            rewardAmount
        );

         
        emit Mint(
            msg.sender, 
            rewardAmount, 
            generation, 
            blockhash(block.number - 1)  
        );

         
        return true;
    }

     
    function testMint(
        bytes32 _digest, 
        uint _challenge, 
        address _minter,
        uint _nonce, 
        uint _target
    ) public pure returns (bool success) {
         
        bytes32 digest = getMintDigest(
            _challenge, 
            _minter,
            _nonce
        );

         
         
        if (uint(digest) > _target) {
             
            success = false;
        } else {
             
            success = (digest == _digest);
        }
    }

     
    function reCalculateDifficulty(
        address _token
    ) external onlyTokenProvider(_token) returns (bool success) {
         
        return _reAdjustDifficulty(_token);
    }

     
    function _reAdjustDifficulty(
        address _token
    ) private returns (bool success) {
         
        bytes32 lastAdjustmentHash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.last.adjustment'
        ));

         
        uint lastAdjustment = _zer0netDb.getUint(lastAdjustmentHash);

         
        uint blocksSinceLastAdjustment = block.number - lastAdjustment;

         
        bytes32 adjustmentHash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.generations.per.adjustment'
        ));

         
        uint genPerAdjustment = _zer0netDb.getUint(adjustmentHash);
        
         
        uint expectedBlocksPerAdjustment = genPerAdjustment.mul(BLOCKS_PER_GENERATION);

         
        uint miningTarget = getTarget(_token);

         
        if (blocksSinceLastAdjustment < expectedBlocksPerAdjustment) {
             
            uint excess_block_pct = expectedBlocksPerAdjustment.mul(10000)
                .div(blocksSinceLastAdjustment);

             
            uint excess_block_pct_extra = excess_block_pct.sub(10000);
            
             
             
            if (excess_block_pct_extra > 5000) {
                excess_block_pct_extra = 5000;
            }

             
            miningTarget = miningTarget.sub(
                 
                miningTarget
                    .mul(excess_block_pct_extra)
                    .div(10000)
            );   
        } else {
             
            uint shortage_block_pct = blocksSinceLastAdjustment.mul(10000)
                .div(expectedBlocksPerAdjustment);

             
            uint shortage_block_pct_extra = shortage_block_pct.sub(10000);

             

             
            miningTarget = miningTarget.add(
                miningTarget
                    .mul(shortage_block_pct_extra)
                    .div(10000)
            );
        }

         
        _zer0netDb.setUint(lastAdjustmentHash, block.number);

         
         
        if (miningTarget < _MINIMUM_TARGET) {
            miningTarget = _MINIMUM_TARGET;
        }

         
         
        if (miningTarget > _MAXIMUM_TARGET) {
            miningTarget = _MAXIMUM_TARGET;
        }

         
        _setMiningTarget(
            _token,
            miningTarget
        );

         
        return true;
    }


     

     
    function getStartingBlock() public view returns (uint startingBlock) {
         
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, 
            '.starting.block'
        ));

         
        startingBlock = _zer0netDb.getUint(hash);
    }
    
     
    function getMinter() external view returns (address minter) {
         
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace,
            '.minter'
        ));

         
        minter = _zer0netDb.getAddress(hash);
    }

     
    function getGeneration(
        address _token
    ) external view returns (
        uint generation,
        uint cycle
    ) {
         
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.generation'
        ));

         
        generation = _zer0netDb.getUint(hash);

         
        hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.generations.per.adjustment'
        ));

         
        cycle = _zer0netDb.getUint(hash);
    }

     
    function getMintFixed(
        address _token
    ) public view returns (uint amount) {
         
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.mint.fixed'
        ));

         
        amount = _zer0netDb.getUint(hash);
    }

     
    function getMintPct(
        address _token
    ) public view returns (uint amount) {
         
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.mint.pct'
        ));

         
        amount = _zer0netDb.getUint(hash);
    }

     
    function getChallenge(
        address _token
    ) public view returns (uint challenge) {
         
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.challenge'
        ));

         
         
        challenge = uint(_bytesToBytes32(
            _zer0netDb.getBytes(hash)
        ));
    }

     
    function getDifficulty(
        address _token
    ) public view returns (uint difficulty) {
         
        difficulty = _MAXIMUM_TARGET.div(getTarget(_token));
    }

     
    function getTarget(
        address _token
    ) public view returns (uint target) {
         
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.target'
        ));

         
        target = _zer0netDb.getUint(hash);
    }

     
    function getMintDigest(
        uint _challenge,
        address _minter,
        uint _nonce 
    ) public pure returns (bytes32 digest) {
         
        digest = keccak256(abi.encodePacked(
            _challenge, 
            _minter, 
            _nonce
        ));
    }

     
    function getRevision() public view returns (uint) {
        return _revision;
    }

    
     

     
    function setGenPerAdjustment(
        address _token,
        uint _numBlocks
    ) external onlyTokenProvider(_token) returns (bool success) {
         
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.generations.per.adjustment'
        ));

         
        _zer0netDb.setUint(hash, _numBlocks);
        
         
        return true;
    }

     
    function setMintFixed(
        address _token,
        uint _amount
    ) external onlyTokenProvider(_token) returns (bool success) {
         
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.mint.fixed'
        ));

         
        _zer0netDb.setUint(hash, _amount);
        
         
        return true;
    }

     
    function setMintPct(
        address _token,
        uint _pct
    ) external onlyTokenProvider(_token) returns (bool success) {
         
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.mint.pct'
        ));

         
        _zer0netDb.setUint(hash, _pct);
        
         
        return true;
    }

     
    function setTokenParents(
        address _token,
        address[] _parents
    ) external onlyTokenProvider(_token) returns (bool success) {
         
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.parents'
        ));
        
         
         
        
         
        bytes memory allParents = abi.encodePacked(
            _parents[0],
            _parents[1],
            _parents[2]
        );

         
        _zer0netDb.setBytes(hash, allParents);
        
         
        return true;
    }
    
     
    function setTokenProvider(
        address _token,
        address _provider,
        bool _auth
    ) external onlyAuthBy0Admin returns (bool success) {
         
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.',
            _provider, 
            '.has.auth.for.', 
            _token
        ));

         
        _zer0netDb.setBool(hash, _auth);
        
         
        return true;
    }

     
    function _setMiningTarget(
        address _token,
        uint _target
    ) private returns (bool success) {
         
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.', 
            _token, 
            '.target'
        ));

         
        _zer0netDb.setUint(hash, _target);
        
         
        return true;
    }


     

     
    function supportsInterface(
        bytes4 _interfaceID
    ) external pure returns (bool) {
         
        bytes4 InvalidId = 0xffffffff;
        bytes4 ERC165Id = 0x01ffc9a7;

         
        if (_interfaceID == InvalidId) {
            return false;
        }

         
        if (_interfaceID == ERC165Id) {
            return true;
        }

         

         
        return false;
    }

     
    function _ecRecovery() private view returns (
        ECRecovery ecrecovery
    ) {
         
        bytes32 hash = keccak256('aname.ecrecovery');

         
        address aname = _zer0netDb.getAddress(hash);

         
        ecrecovery = ECRecovery(aname);
    }

     
    function _infinityPool() private view returns (
        InfinityPoolInterface infinityPool
    ) {
         
        bytes32 hash = keccak256('aname.infinitypool');
        
         
        address aname = _zer0netDb.getAddress(hash);
        
         
        infinityPool = InfinityPoolInterface(aname);
    }

     
    function _infinityWell() private view returns (
        InfinityWellInterface infinityWell
    ) {
         
        bytes32 hash = keccak256('aname.infinitywell');
        
         
        address aname = _zer0netDb.getAddress(hash);
        
         
        infinityWell = InfinityWellInterface(aname);
    }


     

     
    function _bytesToAddress(bytes _address) private pure returns (address) {
        uint160 m = 0;
        uint160 b = 0;

        for (uint8 i = 0; i < 20; i++) {
            m *= 256;
            b = uint160(_address[i]);
            m += (b);
        }

        return address(m);
    }

     
    function _bytesToBytes32(
        bytes _data
    ) private pure returns (bytes32 result) {
         
        for (uint i = 0; i < 32; i++) {
             
            result |= bytes32(_data[i] & 0xFF) >> (i * 8);
        }
    }
    
     
    function _bytes32ToBytes(
        bytes32 _data
    ) private pure returns (bytes result) {
         
        return abi.encodePacked(_data);
    }
}