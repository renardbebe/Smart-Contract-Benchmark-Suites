 

pragma solidity ^0.4.4;

 

 

contract Math {

 

    function safeMul(uint a, uint b) internal returns (uint) {

        uint c = a * b;

        assert(a != 0 && b != 0 );

        return c;

    }

 

    function safeSub(uint a, uint b) internal returns (uint) {

        assert(b <= a);

        return a - b;

    }

 

    function safeAdd(uint a, uint b) internal returns (uint) {

        uint c = a + b;

        assert(b <= c && c >= a);

        return c;

   }

 

}

 

contract ERC20 {

 

    function transfer(address to, uint value) returns (bool success) {

        if (tokenOwned[msg.sender] >= value && tokenOwned[to] + value > tokenOwned[to]) {

            tokenOwned[msg.sender] -= value;

            tokenOwned[to] += value;

            Transfer(msg.sender, to, value);

            return true;

        } else { return false; }

    }

 

    function transferFrom(address from, address to, uint value) returns (bool success) {

        if (tokenOwned[from] >= value && allowed[from][msg.sender] >= value && tokenOwned[to] + value > tokenOwned[to]) {

            tokenOwned[to] += value;

            tokenOwned[from] -= value;

            allowed[from][msg.sender] -= value;

            Transfer(from, to, value);

            return true;

        } else { return false; }

    }

 

    function balanceOf(address owner) constant returns (uint balance) {

        return tokenOwned[owner];

    }

 

    function approve(address spender, uint value) returns (bool success) {

        allowed[msg.sender][spender] = value;

        Approval(msg.sender, spender, value);

        return true;

    }

 

    function allowance(address owner, address spender) constant returns (uint remaining) {

        return allowed[owner][spender];

    }

 

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);

 

    mapping(address => uint) internal tokenOwned;  

 

    mapping (address => mapping (address => uint)) allowed;

 

    uint public totalSupply;

 

    string public name = "BitMohar";

 

    string public symbol = "MOH";

 

    uint public decimals = 10;

 

}

 

 

 

 

contract TokenDistribution is Math, ERC20 {

 

     

    function TokenDistribution() {

        owner = msg.sender;

 

        totalSupply = 15000000000000000000;  

        startBlock = 4267514;

        emissionPerblock = 80;  

        blocksPerYear = 10000000;  

        preMined = 9000000000000000000;

        tokensMinted = 0;

        preMineDone = false;

 

    }

 

    function preMine() returns (bool z) {

        if(msg.sender == owner && !preMineDone) {

            tokenOwned[0x60212b87C6e106d3852890FE6e8d00db3D99d002] = 9000000000000000000;

            preMineDone = true;

            return true;

        } else {

            return false;

        }

    }

 

    function mine() returns (bool z) {

        uint blockTime = (((block.number - startBlock) / blocksPerYear) + 1);

        uint currentEmission = emissionPerblock / blockTime;

        uint emittedBlocks = startBlock;

        if(currentEmission != emissionPerblock) {  

            emittedBlocks = startBlock + (blocksPerYear * blockTime);

        }

        uint mined = 0;

        if(blockTime > 1) {  

            uint prevMinted = 0;

            for (uint i = 1; i <= blockTime; i++) {

                prevMinted += (blocksPerYear * (emissionPerblock / i));

            }

            prevMinted += (block.number - emittedBlocks) * currentEmission;

            mined = safeSub(prevMinted, tokensMinted);

        } else {

            mined = safeSub((block.number - emittedBlocks) * currentEmission, tokensMinted);

        }

 

        if(safeAdd(preMined, safeAdd(mined, tokensMinted)) > totalSupply) {

            return false;

        } else {

            tokenOwned[msg.sender] = safeAdd(tokenOwned[msg.sender], mined);

            tokensMinted = safeAdd(tokensMinted, mined);

            return true;

        }

    }

 

    function changeTotalSupply(uint _totalSupply) returns (bool x){

        if(msg.sender == owner){

            totalSupply = _totalSupply;

            return true;

        }else{

            return false;

        }

    }

 

    function additionalPreMine(uint _supply) returns (bool x){

        if(msg.sender == owner){

            tokenOwned[msg.sender] = safeAdd(tokenOwned[msg.sender], _supply);

            return true;

        }else{

            return false;

        }

    }

 

    address owner;

    mapping (address => uint) internal etherSent;  

    uint startBlock;

    uint emissionPerblock;  

    uint blocksPerYear;  

    uint preMined;

    uint tokensMinted;

    bool preMineDone;

}