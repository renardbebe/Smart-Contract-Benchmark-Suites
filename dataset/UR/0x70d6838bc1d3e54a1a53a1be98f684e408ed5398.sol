 

pragma solidity ^0.5.0;

 
library SafeMathLibrary {
     
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

 
interface IERC20Token {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract DistributionPool {
    
    using SafeMathLibrary for uint256;
    
    event WeiPerBIDL(uint256 value);
    event Activated();
    event Unlock(uint256 amountBIDL, uint256 amountWei);
    
     
    IERC20Token private _bidlToken;
    
     
    address payable private _poolParticipant;
    
     
    address private _blockbidAdmin;  
    
     
    uint256 private _weiPerBidl = (100 * 1e18) / (1000000 * 1e2);
    
     
    uint256 private _maxBalanceWei = 1000 ether;
    
     
    bool private _activated = false;
    
    modifier onlyBlockbidAdmin() {
        require(_blockbidAdmin == msg.sender);
        _;
    }
    
    modifier onlyWhenActivated() {
        require(_activated);
        _;
    }

    function bidlToken() public view returns (IERC20Token) {
        return _bidlToken;
    }

    function poolParticipant() public view returns (address) {
        return _poolParticipant;
    }

    function blockbidAdmin() public view returns (address) {
        return _blockbidAdmin;
    }

    function weiPerBidl() public view returns (uint256) {
        return _weiPerBidl;
    }

    function maxBalanceWei() public view returns (uint256) {
        return _maxBalanceWei;
    }

    function isActivated() public view returns (bool) {
        return _activated;
    }
    
    function setWeiPerBIDL(uint256 value) public onlyBlockbidAdmin {
        _weiPerBidl = value;  
        emit WeiPerBIDL(value);
    }

     
    function admin_getBidlAmountToDeposit() public view returns (uint256) {
        uint256 weiBalance = address(this).balance;
        uint256 bidlAmountSupposedToLock = weiBalance / _weiPerBidl;
        uint256 bidlBalance = _bidlToken.balanceOf(address(this));
        if (bidlAmountSupposedToLock < bidlBalance) {
            return 0;
        }
        return bidlAmountSupposedToLock - bidlBalance;
    }
    
     
    function admin_unlock(uint256 amountBIDL) public onlyBlockbidAdmin onlyWhenActivated {
        _bidlToken.transfer(_poolParticipant, amountBIDL);
        
        uint256 weiToUnlock = _weiPerBidl * amountBIDL;
        _poolParticipant.transfer(weiToUnlock);
        
        emit Unlock(amountBIDL, weiToUnlock);
    }
    
     
    function admin_activate() public onlyBlockbidAdmin {
        require(_poolParticipant != address(0));
        require(!_activated);
        _activated = true;
		emit Activated();
    }
    
     
    function admin_destroy() public onlyBlockbidAdmin {
         
        uint256 bidlBalance = _bidlToken.balanceOf(address(this));
        _bidlToken.transfer(_blockbidAdmin, bidlBalance);

         
        selfdestruct(_poolParticipant);
    }
    
     
    function () external payable {
         
        if (_poolParticipant != address(0) && _poolParticipant != msg.sender) {
            revert();
        }

         
        if (_activated) {
            revert();
        }
		
		uint256 weiBalance = address(this).balance;
		
		 
		if (weiBalance > _maxBalanceWei) {
		    uint256 excessiveWei = weiBalance.sub(_maxBalanceWei);
		    msg.sender.transfer(excessiveWei);
		    weiBalance = _maxBalanceWei;
		}
		
		if (_poolParticipant != msg.sender) 
		    _poolParticipant = msg.sender;
    }
	
	constructor () public
	{
        _blockbidAdmin = 0x2B1c94b5d79a4445fE3BeF9Fd4d9Aae6A65f0F92;
		_bidlToken = IERC20Token(0x5C7Ec304a60ED545518085bb4aBa156E8a7596F6);
	}
}