 

pragma solidity ^0.4.16;

 
contract Ownable {


    address owner;

    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    function Ownable() {
        owner = msg.sender;
        OwnershipTransferred (address(0), owner);
    }

    function transferOwnership(address _newOwner)
        public
        onlyOwner
        notZeroAddress(_newOwner)
    {
        owner = _newOwner;
        OwnershipTransferred(msg.sender, _newOwner);
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0));
        _;
    }

}

 
library SafeMath {


     
    function ADD (uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

     
    function SUB (uint256 a, uint256 b) internal returns (uint256) {
        assert(a >= b);
        return a - b;
    }
    
}

 
contract Token {

    function transfer(address _to, uint256 _value) 
        external;

    function burn(uint256 _value) 
        external;

}


contract GEECrowdsale is Ownable {

    using SafeMath for uint256;

     
    uint256 public soldTokens;                                   
    
    uint256 public hardCapInTokens = 67 * (10**6) * (10**8);     
    
    uint256 public constant MIN_ETHER = 0.03 ether;              
    uint256 public constant MAX_ETHER = 1000 ether;              

    
    address fund = 0x48a2909772b049D0eA3A0979eE05eDF37119738d;   

    
    uint256 public constant START_BLOCK_NUMBER = 4506850;        
    
    uint256 public constant TIER2 = 4525700;                       
    uint256 public constant TIER3 = 4569600;                      
    uint256 public constant TIER4 = 4632300;                      
    uint256 public endBlockNumber = 4695000;                         
    uint256 public constant MAX_END_BLOCK_NUMBER = 4890000;          

    uint256 public price;                                        
   
    uint256 public constant TIER1_PRICE = 6000000;               
    uint256 public constant TIER2_PRICE = 6700000;               
    uint256 public constant TIER3_PRICE = 7400000;               
    uint256 public constant TIER4_PRICE = 8200000;               

    Token public gee;                                            

    uint256 public constant SOFT_CAP_IN_ETHER = 4000 ether;     

    uint256 public collected;                                    

    uint256 public constant GEE100 = 100 * (10**8);


     
    mapping (address => uint256) public bought;                  


     
    event Buy    (address indexed _who, uint256 _amount, uint256 indexed _price);    
    event Refund (address indexed _who, uint256 _amount);                            
    event CrowdsaleEndChanged (uint256 _crowdsaleEnd, uint256 _newCrowdsaleEnd);     


     
     
    function GEECrowdsale (Token _geeToken)
        public
        notZeroAddress(_geeToken)
        payable
    {
        gee = _geeToken;
    }


     
    function() 
        external 
        payable 
    {
        if (isCrowdsaleActive()) {
            buy();
        } else { 
            require (msg.sender == fund || msg.sender == owner);     
        }
    }


     
    function finalize() 
        external
        onlyOwner
    {
        require(soldTokens != hardCapInTokens);
        if (soldTokens < (hardCapInTokens - GEE100)) {
            require(block.number > endBlockNumber);
        }
        hardCapInTokens = soldTokens;
        gee.burn(hardCapInTokens.SUB(soldTokens));
    }


     
    function buy()
        public
        payable
    {
        uint256 amountWei = msg.value;
        uint256 blocks = block.number;


        require (isCrowdsaleActive());
        require(amountWei >= MIN_ETHER);                             
        require(amountWei <= MAX_ETHER);

        price = getPrice();
        
        uint256 amount = amountWei / price;                          

        soldTokens = soldTokens.ADD(amount);                         

        require(soldTokens <= hardCapInTokens);

        if (soldTokens >= (hardCapInTokens - GEE100)) {
            endBlockNumber = blocks;
        }
        
        collected = collected.ADD(amountWei);                        
        bought[msg.sender] = bought[msg.sender].ADD(amountWei);

        gee.transfer(msg.sender, amount);                            
        fund.transfer(this.balance);                                 

        Buy(msg.sender, amount, price);
    }


     
    function isCrowdsaleActive() 
        public 
        constant 
        returns (bool) 
    {

        if (endBlockNumber < block.number || START_BLOCK_NUMBER > block.number) {
            return false;
        }
        return true;
    }


     
    function getPrice()
        internal
        constant
        returns (uint256)
    {
        if (block.number < TIER2) {
            return TIER1_PRICE;
        } else if (block.number < TIER3) {
            return TIER2_PRICE;
        } else if (block.number < TIER4) {
            return TIER3_PRICE;
        }

        return TIER4_PRICE;
    }


     
    function refund() 
        external 
    {
        uint256 refund = bought[msg.sender];
        require (!isCrowdsaleActive());
        require (collected < SOFT_CAP_IN_ETHER);
        bought[msg.sender] = 0;
        msg.sender.transfer(refund);
        Refund(msg.sender, refund);
    }


    function drainEther() 
        external 
        onlyOwner 
    {
        fund.transfer(this.balance);
    }

     
    function setEndBlockNumber(uint256 _newEndBlockNumber) external onlyOwner {
        require(isCrowdsaleActive());
        require(_newEndBlockNumber >= block.number);
        require(_newEndBlockNumber <= MAX_END_BLOCK_NUMBER);

        uint256 currentEndBlockNumber = endBlockNumber;
        endBlockNumber = _newEndBlockNumber;
        CrowdsaleEndChanged (currentEndBlockNumber, _newEndBlockNumber);
    }

}