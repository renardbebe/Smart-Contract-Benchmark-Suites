 

pragma solidity ^0.4.16;
 

 
library SafeMath {

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
  }
}

contract ERC20Token {

	function balanceOf(address who) public constant returns (uint);
	function transfer(address to, uint value) public;	
}

 

contract admined {
    address public admin;  
     
    function admined() internal {
        admin = msg.sender;  
        Admined(admin);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }
     
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        require(_newAdmin != address(0));
        admin = _newAdmin;
        TransferAdminship(admin);
    }
     
    event TransferAdminship(address newAdmin);
    event Admined(address administrador);
}


contract ETHBCrowdsale is admined{
	 
    uint256 public startTime = now;  
    uint256 public totalDistributed = 0;
    uint256 public currentBalance = 0;
    ERC20Token public tokenReward;
    address public creator;
    address public ethWallet;
    string public campaignUrl;
    uint256 public constant version = 1;
    uint256 public exchangeRate = 20000000;  
                                                                          

    event TokenWithdrawal(address _to,uint256 _withdraw);
	event PayOut(address _to,uint256 _withdraw);
	event TokenBought(address _buyer, uint256 _amount);

     
    function ETHBCrowdsale(
    	address _ethWallet,
    	string _campaignUrl) public {

    	tokenReward = ERC20Token(0x3a26746Ddb79B1B8e4450e3F4FFE3285A307387E);
    	creator = msg.sender;
    	ethWallet = _ethWallet;
    	campaignUrl = _campaignUrl;
    }
     
    function exchange() public payable {
    	require (tokenReward.balanceOf(this) > 0);
    	require (msg.value > 1 finney);

    	uint256 tokenBought = SafeMath.div(msg.value,exchangeRate);

    	require(tokenReward.balanceOf(this) >= tokenBought );
    	currentBalance = SafeMath.add(currentBalance,msg.value);
    	totalDistributed = SafeMath.add(totalDistributed,tokenBought);
    	tokenReward.transfer(msg.sender,tokenBought);
		TokenBought(msg.sender, tokenBought);

    }
     
    function tokenWithdraw (address _to) onlyAdmin public {
    	require( _to != 0x0 );
    	require(tokenReward.balanceOf(this)>0);
    	uint256 withdraw = tokenReward.balanceOf(this);
    	tokenReward.transfer(_to,withdraw);
    	TokenWithdrawal(_to,withdraw);
    }
     
    function ethWithdraw () onlyAdmin public {
    	require(this.balance > 0);
    	uint256 withdraw = this.balance;
    	currentBalance = 0;
    	require(ethWallet.send(withdraw));
    	PayOut(ethWallet,withdraw);
    }
     
    function () public payable{
        exchange();
    }
}