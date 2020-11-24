 

pragma solidity >=0.5.0 <0.6.0;

 

contract myEtherDate {
    
    struct Player {
        uint commitBlock;
        uint stake;
    }
    
    mapping(address => Player) public player;
    uint public maxStake;
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
      
    function set() 
        public
        payable
        returns (bool success)
    {
         
         
        require(msg.value > 0 && msg.value <= maxStake);
        
         
         
        player[msg.sender].commitBlock = block.number + 1;
        player[msg.sender].stake = msg.value;
        
        return true;
    }  
    
     
    function getRand() 
        view
        public
        returns (uint[4] memory) 
    {
         
        uint256 randomN = uint256(blockhash(player[msg.sender].commitBlock));
      
         
         
         
         
        require(randomN != 0);

        uint256 offset;
        uint[4] memory randNums;
        
         
         
        for(uint i = 0; i < 4; i++){
            randNums[i] = _sliceNumber(randomN, 16, offset);  
            offset += 32;    
        }
        
         
        return randNums;
    }
    
     
    function claim()
        public
        payable
        returns (bool success)
    {
        uint[4] memory rand = getRand();
        player[msg.sender].commitBlock = 0;
        uint256 stake = player[msg.sender].stake;
        player[msg.sender].stake = 0;
        
        uint256 successfulDate;
        
         
         
         
         
        for (uint i = 0; i < 4; i++) {
            if (rand[i] < 8110) 
                successfulDate++;
        }
        
        if (successfulDate != 0) {
             
             
            uint256 payout = SafeMath.mul(stake, 2);
            payout = SafeMath.mul(payout, successfulDate);
            msg.sender.transfer(payout);
            updateMaxStake();
        }

        return true;
    }
    
     
     
     
     
    function _sliceNumber(uint256 _n, uint256 _nbits, uint256 _offset) 
        private 
        pure 
        returns (uint256) 
    {
         
        uint256 mask = uint256((2**_nbits) - 1) << _offset;
         
        return uint256((_n & mask) >> _offset);
    }
    
    function fundBankroll()
        public
        payable
        returns(bool success)
    {
        updateMaxStake();
        return true;
    }
    
    function updateMaxStake()
        public
        returns (bool success)
    {
        uint256 newMax = SafeMath.div(address(this).balance, 8);
        maxStake = newMax;
        return true;
    }
        
    function collect(uint256 ammount)
        public
        onlyOwner
        returns (bool success)
    {
        msg.sender.transfer(ammount);
        updateMaxStake();
        return true;
    }
    
    function transferOwnership(address newOwner) 
        public
        onlyOwner
    {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
}

     
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}