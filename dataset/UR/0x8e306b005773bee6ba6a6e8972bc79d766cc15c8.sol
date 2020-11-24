 

pragma solidity 0.4.18;

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract MerkleMine {
    using SafeMath for uint256;

     
    ERC20 public token;
     
    bytes32 public genesisRoot;
     
    uint256 public totalGenesisTokens;
     
    uint256 public totalGenesisRecipients;
     
    uint256 public tokensPerAllocation;
     
    uint256 public balanceThreshold;
     
    uint256 public genesisBlock;
     
     
    uint256 public callerAllocationStartBlock;
     
    uint256 public callerAllocationEndBlock;
     
    uint256 public callerAllocationPeriod;

     
    bool public started;

     
    mapping (address => bool) public generated;

     
    modifier notGenerated(address _recipient) {
        require(!generated[_recipient]);
        _;
    }

     
    modifier isStarted() {
        require(started);
        _;
    }

     
    modifier isNotStarted() {
        require(!started);
        _;
    }

    event Generate(address indexed _recipient, address indexed _caller, uint256 _recipientTokenAmount, uint256 _callerTokenAmount, uint256 _block);

     
    function MerkleMine(
        address _token,
        bytes32 _genesisRoot,
        uint256 _totalGenesisTokens,
        uint256 _totalGenesisRecipients,
        uint256 _balanceThreshold,
        uint256 _genesisBlock,
        uint256 _callerAllocationStartBlock,
        uint256 _callerAllocationEndBlock
    )
        public
    {
         
        require(_token != address(0));
         
        require(_totalGenesisRecipients > 0);
         
        require(_genesisBlock <= block.number);
         
        require(_callerAllocationStartBlock > block.number);
         
        require(_callerAllocationEndBlock > _callerAllocationStartBlock);

        token = ERC20(_token);
        genesisRoot = _genesisRoot;
        totalGenesisTokens = _totalGenesisTokens;
        totalGenesisRecipients = _totalGenesisRecipients;
        tokensPerAllocation = _totalGenesisTokens.div(_totalGenesisRecipients);
        balanceThreshold = _balanceThreshold;
        genesisBlock = _genesisBlock;
        callerAllocationStartBlock = _callerAllocationStartBlock;
        callerAllocationEndBlock = _callerAllocationEndBlock;
        callerAllocationPeriod = _callerAllocationEndBlock.sub(_callerAllocationStartBlock);
    }

     
    function start() external isNotStarted {
         
        require(token.balanceOf(this) >= totalGenesisTokens);

        started = true;
    }

     
    function generate(address _recipient, bytes _merkleProof) external isStarted notGenerated(_recipient) {
         
        bytes32 leaf = keccak256(_recipient);
         
        require(MerkleProof.verifyProof(_merkleProof, genesisRoot, leaf));

        generated[_recipient] = true;

        address caller = msg.sender;

        if (caller == _recipient) {
             
            require(token.transfer(_recipient, tokensPerAllocation));

            Generate(_recipient, _recipient, tokensPerAllocation, 0, block.number);
        } else {
             
             
            require(block.number >= callerAllocationStartBlock);

            uint256 callerTokenAmount = callerTokenAmountAtBlock(block.number);
            uint256 recipientTokenAmount = tokensPerAllocation.sub(callerTokenAmount);

            if (callerTokenAmount > 0) {
                require(token.transfer(caller, callerTokenAmount));
            }

            if (recipientTokenAmount > 0) {
                require(token.transfer(_recipient, recipientTokenAmount));
            }

            Generate(_recipient, caller, recipientTokenAmount, callerTokenAmount, block.number);
        }
    }

     
    function callerTokenAmountAtBlock(uint256 _blockNumber) public view returns (uint256) {
        if (_blockNumber < callerAllocationStartBlock) {
             
            return 0;
        } else if (_blockNumber >= callerAllocationEndBlock) {
             
            return tokensPerAllocation;
        } else {
             
             
             
            uint256 blocksSinceCallerAllocationStartBlock = _blockNumber.sub(callerAllocationStartBlock);
            return tokensPerAllocation.mul(blocksSinceCallerAllocationStartBlock).div(callerAllocationPeriod);
        }
    }
}