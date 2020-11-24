 

pragma solidity ^0.4.24;

 
contract WaitOrReinvest{
    
    using SafeMath for uint256;

    mapping(address => uint256) investments;
    mapping(address => uint256) joined;
    mapping(address => address) referrer;
	
    uint256 public stepUp = 50;  
    address public ownerWallet;

    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
     
     
    constructor() public {
        ownerWallet = msg.sender;
    }

     
     
    modifier onlyOwner() {
        require(msg.sender == ownerWallet);
        _;
    }

     
    function transferOwnership(address newOwnerWallet) public onlyOwner {
        require(newOwnerWallet != address(0));
        emit OwnershipTransferred(ownerWallet, newOwnerWallet);
        ownerWallet = newOwnerWallet;
    }

     
	 
    function () public payable {
		invest(address(0));
	}
	
    function invest(address _ref) public payable {
        require(msg.value >= 0);
        if (investments[msg.sender] > 0){
            reinvest(); 
        }
        investments[msg.sender] = investments[msg.sender].add(msg.value);
        joined[msg.sender] = now;
		
		uint256 dfFee = msg.value.div(100).mul(5);  
        ownerWallet.transfer(dfFee);
		
		
		if (referrer[msg.sender] == address(0) && address(_ref) > 0 && address(_ref) != msg.sender)
			referrer[msg.sender] = _ref;
		
		address ref = referrer[msg.sender];	
        if (ref > 0 ) 
			ref.transfer(dfFee);  
			
        emit Invest(msg.sender, msg.value);
    }
	
    function reinvest() public {
		require(investments[msg.sender] > 0);
		require((now - joined[msg.sender]) > 5);
		
		uint256 balance = getDivsBalance(msg.sender);
		
		uint256 dfFee = balance.div(100).mul(5);  
		
		if (address(this).balance > dfFee) {
			address ref = referrer[msg.sender];	 
			if (ref != address(0))
				ref.transfer(dfFee);  
			else 
				ownerWallet.transfer(dfFee);  
			balance = balance.sub(dfFee); 
		}
			
		investments[msg.sender] += balance;
		joined[msg.sender] = now;
	}	

     
    function getDivsBalance(address _address) view public returns (uint256) {
        uint256 secondsCount = now.sub(joined[_address]);
        uint256 percentDivs = investments[_address].mul(stepUp).div(100);
        uint256 dividends = percentDivs.mul(secondsCount).div(86400);

        return dividends;
    }

     
    function withdraw() public returns (bool){
        require(joined[msg.sender] > 0);
        uint256 balance = getDivsBalance(msg.sender);
        if (address(this).balance > balance){
            if (balance > 0){
				joined[msg.sender]=now;
                msg.sender.transfer(balance);
				
				if (investments[msg.sender] > balance)
					investments[msg.sender] = SafeMath.sub(investments[msg.sender],balance);
				else 
					investments[msg.sender] = 0;
					
                emit Withdraw(msg.sender, balance);
            }
            return true;
        } else {
            return false;
        }
    }
    

     
    function checkDivsBalance() public view returns (uint256) {
        return getDivsBalance(msg.sender);
    }


     
    function checkInvestments(address _investor) public view returns (uint256) {
        return investments[_investor];
    }

    
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