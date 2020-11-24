 

pragma solidity ^0.4.25;

 
contract EasyInvestV2 {
    using SafeMath              for *;

    string constant public name = "EasyInvest7";
    string constant public symbol = "EasyInvest7";
    
    uint256 _maxInvest = 5e19;
    uint256 _maxBalance = 2e20; 

    address public promoAddr_ = address(0x81eCf0979668D3C6a812B404215B53310f14f451);
    
     
    mapping (address => uint256) public invested;
     
    mapping (address => uint256) public atTime;
    
    uint256 public NowETHINVESTED = 0;
    uint256 public AllINVESTORS = 0;
    uint256 public AllETHINVESTED = 0;

     
    function () external payable {
        
        uint256 realBalance = getBalance().sub(msg.value);
        
        require(msg.value <= _maxInvest  , "invest amount error, please set the exact amount");
        require(realBalance < _maxBalance  , "max balance, can't invest");
        
        uint256 more_ = 0;
        uint256 amount_ = msg.value;
        if (amount_.add(realBalance) > _maxBalance && amount_ > 0) {
            more_ = amount_.add(realBalance).sub(_maxBalance);
            amount_ = amount_.sub(more_);
            
            msg.sender.transfer(more_);
        }
        
        if (amount_.add(invested[msg.sender]) > _maxInvest && amount_ > 0) {
            more_ = amount_.add(invested[msg.sender]).sub(_maxInvest);
            amount_ = amount_.sub(more_);
            
            msg.sender.transfer(more_);
        }

         
        if (invested[msg.sender] != 0) {
             
             
            uint256 amount = invested[msg.sender] * 7 / 100 * (now - atTime[msg.sender]) / 24 hours;

             
            msg.sender.transfer(amount);
        } else {
            if (atTime[msg.sender] == 0) {
                AllINVESTORS += 1;
            }
        }

         
        if (msg.value == 0 && invested[msg.sender] != 0) {
            msg.sender.transfer(invested[msg.sender]);
            NowETHINVESTED = NowETHINVESTED.sub(invested[msg.sender]);
            
            atTime[msg.sender] = now;
            invested[msg.sender] = 0;
            
        } else {
            atTime[msg.sender] = now;
            invested[msg.sender] += amount_;
            NowETHINVESTED = NowETHINVESTED.add(amount_);
            AllETHINVESTED = AllETHINVESTED.add(amount_);
        }
        
        if (amount_ > 1e14) {
            promoAddr_.transfer(amount_.mul(2).div(100));
        }
    }
    
    function getBalance() public view returns (uint256){
        return address(this).balance;
    }
    

}

 
 library SafeMath {
     
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
    
     
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

     
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
     
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
     
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
     
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}