 

pragma solidity ^0.4.24;

contract TeamDreamHub {
    using SafeMath for uint256;
    
 
 
 
 
	address private owner;
	uint256 maxShareHolder = 100;
    mapping(uint256 => ShareHolder) public shareHolderTable;	

	struct ShareHolder {
        address targetAddr;   
        uint256 ratio; 		  
    }	
 
 
 
 
    constructor()
        public
    {
		owner = msg.sender;
    }
 
 
 
 
     
    modifier isHuman() {
        address _addr = msg.sender;
		require (_addr == tx.origin);
		
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }    
	
	modifier onlyOwner() {
		require (msg.sender == owner);
		_;
	}

	
 
 
 
 

     
    function()      
		isHuman()
        public
        payable
    {
		 
		distribute(msg.value);
    }
	
    function deposit()
        external
        payable
    {
		distribute(msg.value);
    }
	
	function distribute(uint256 _totalInput)
        private
    {		
		uint256 _toBeDistribute = _totalInput;
		
		uint256 fund;
		address targetAddress;
		for (uint i = 0 ; i < maxShareHolder; i++) {			
			targetAddress = shareHolderTable[i].targetAddr;
			if(targetAddress != address(0))
			{
				fund = _totalInput.mul(shareHolderTable[i].ratio) / 100;			
				targetAddress.transfer(fund);
				_toBeDistribute = _toBeDistribute.sub(fund);
			}
			else
				break;
		}		
        
		 
		owner.transfer(_toBeDistribute);	
    }
	
	
	 
    function updateEntry(uint256 tableIdx, address _targetAddress, uint256 _ratio)
        onlyOwner()
        public
    {
		require (tableIdx < maxShareHolder);
		require (_targetAddress != address(0));
		require (_ratio <= 100);
		
		uint256 totalShare = 0;		
		for (uint i = 0 ; i < maxShareHolder; i++) {
			if(i != tableIdx)
				totalShare += shareHolderTable[i].ratio;
			else
				totalShare += _ratio;
			
			if(totalShare > 100)  
				revert('totalShare is larger than 100.');
		}
		
		shareHolderTable[tableIdx] = ShareHolder(_targetAddress,_ratio);        
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