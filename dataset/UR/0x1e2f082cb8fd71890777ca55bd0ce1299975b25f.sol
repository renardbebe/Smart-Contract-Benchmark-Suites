 

pragma solidity ^0.4.25;


contract Prosperity {
	 
	function withdraw() public;
	
	  
    function myDividends(bool _includeReferralBonus) public view returns(uint256);
}


contract Fund {
    using SafeMath for *;
    
     
     
     
     
     
     
     
     
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrator_ == _customerAddress);
        _;
    }
    
    
     
    address internal administrator_;
    address internal lending_;
    address internal freeFund_;
    address[] public devs_;
	
	 
	Prosperity public tokenContract_;
    
     
    uint8 internal lendingShare_ = 50;
    uint8 internal freeFundShare_ = 20;
    uint8 internal devsShare_ = 30;
    
    
     
    constructor()
        public 
    {
         
        administrator_ = 0x28436C7453EbA01c6EcbC8a9cAa975f0ADE6Fff1;
        lending_ = 0x961FA070Ef41C2b68D1A50905Ea9198EF7Dbfbf8;
        freeFund_ = 0x0cCA1e8Db144d2E4a8F2A80828E780a1DC9C5112;
        
         
        devs_.push(0x28436C7453EbA01c6EcbC8a9cAa975f0ADE6Fff1);  
        devs_.push(0x92be79705F4Fab97894833448Def30377bc7267A);  
        devs_.push(0x000929719742ec6E0bFD0107959384F7Acd8F883);  
        devs_.push(0x5289f0f0E8417c7475Ba33E92b1944279e183B0C);  
    }
	
	function() payable external {
		 
		 
	}
    
     
    function pushEther()
        public
    {
		 
		if (myDividends(true) > 0) {
			tokenContract_.withdraw();
		}
		
		 
        uint256 _balance = getTotalBalance();
        
		 
        if (_balance > 0) {
            uint256 _ethDevs      = _balance.mul(devsShare_).div(100);           
            uint256 _ethFreeFund  = _balance.mul(freeFundShare_).div(100);       
            uint256 _ethLending   = _balance.sub(_ethDevs).sub(_ethFreeFund);    
            
            lending_.transfer(_ethLending);
            freeFund_.transfer(_ethFreeFund);
            
            uint256 _devsCount = devs_.length;
            for (uint8 i = 0; i < _devsCount; i++) {
                uint256 _ethDevPortion = _ethDevs.div(_devsCount);
                address _dev = devs_[i];
                _dev.transfer(_ethDevPortion);
            }
        }
    }
    
     
    function addDev(address _dev)
        onlyAdministrator()
        public
    {
         
        require(!isDev(_dev), "address is already dev");
        
        devs_.push(_dev);
    }
    
     
    function removeDev(address _dev)
        onlyAdministrator()
        public
    {
         
        require(isDev(_dev), "address is not a dev");
        
         
        uint8 index = getDevIndex(_dev);
        
         
        uint256 _devCount = getTotalDevs();
        for (uint8 i = index; i < _devCount - 1; i++) {
            devs_[i] = devs_[i+1];
        }
        delete devs_[devs_.length-1];
        devs_.length--;
    }
    
    
     
    function isDev(address _dealer) 
        public
        view
        returns(bool)
    {
        uint256 _devsCount = devs_.length;
        
        for (uint8 i = 0; i < _devsCount; i++) {
            if (devs_[i] == _dealer) {
                return true;
            }
        }
        
        return false;
    }
    
    
     
    function getTotalBalance() 
        public
        view
        returns(uint256)
    {
        return address(this).balance;
    }
    
    function getTotalDevs()
        public 
        view 
        returns(uint256)
    {
        return devs_.length;
    }
	
	function myDividends(bool _includeReferralBonus)
		public
		view
		returns(uint256)
	{
		return tokenContract_.myDividends(_includeReferralBonus);
	}
    
    
     
     
    function getDevIndex(address _dev)
        internal
        view
        returns(uint8)
    {
        uint256 _devsCount = devs_.length;
        
        for (uint8 i = 0; i < _devsCount; i++) {
            if (devs_[i] == _dev) {
                return i;
            }
        }
    }
	
	 
	 
	function setTokenContract(address _tokenContract)
		onlyAdministrator()
		public
	{
		tokenContract_ = Prosperity(_tokenContract);
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