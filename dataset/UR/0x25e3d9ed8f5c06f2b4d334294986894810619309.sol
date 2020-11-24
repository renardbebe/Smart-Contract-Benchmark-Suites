 

pragma solidity 0.4.24;
 
 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Token {
    function transferSoldToken(address _contractAddr, address _to, uint256 _value) public returns(bool);
    function balanceOf(address who) public view returns (uint256);
    function totalSupply() public view returns (uint256);
}
contract WhiteList {
	function register(address _address) public;
	function unregister(address _address) public;
	function isRegistered(address _address) public view returns(bool);	
}
 
contract PriIcoSale2 {
    using SafeMath for uint256;   
    
    address public owner;               
    address public beneficiary;         
    uint public fundingEthGoal;         
    uint public raisedEthAmt;           
    uint public totalSoldTokenCount;    
    uint public pricePerEther;          
    
    Token public tokenReward;           
	WhiteList public whiteListMge;      
	
    bool enableWhiteList = false;       
    bool public icoProceeding = false;  
    
    mapping(address => uint256) public funderEthAmt;
    
    event ResistWhiteList(address funder, bool isRegist);  
    event UnregisteWhiteList(address funder, bool isRegist);  
    event FundTransfer(address backer, uint amount, bool isContribution);  
    event StartICO(address owner, bool isStart);
	event CloseICO(address recipient, uint totalAmountRaised);  
    event ReturnExcessAmount(address funder, uint amount);
    
     
    function PriIcoSale2(address _sendAddress, uint _goalEthers, uint _dividendRate, address _tokenAddress, address _whiteListAddress) public {
        require(_sendAddress != address(0));
        require(_tokenAddress != address(0));
        require(_whiteListAddress != address(0));
        
        owner = msg.sender;  
        beneficiary = _sendAddress;  
        fundingEthGoal = _goalEthers * 1 ether;  
        pricePerEther = _dividendRate;  
        
        tokenReward = Token(_tokenAddress);  
        whiteListMge = WhiteList(_whiteListAddress);  
        
    }
     
    function startIco() public {
        require(msg.sender == owner);
        require(!icoProceeding);
        icoProceeding = true;
		emit StartICO(msg.sender, true);
    }
     
    function endIco() public {
        require(msg.sender == owner);
        require(icoProceeding);
        icoProceeding = false;
        emit CloseICO(beneficiary, raisedEthAmt);
    }
     
    function setEnableWhiteList(bool _flag) public {
        require(msg.sender == owner);
        require(enableWhiteList != _flag);
        enableWhiteList = _flag;
    }
     
    function resistWhiteList(address _funderAddress) public {
        require(msg.sender == owner);
        require(_funderAddress != address(0));		
		require(!whiteListMge.isRegistered(_funderAddress));
		
		whiteListMge.register(_funderAddress);
        emit ResistWhiteList(_funderAddress, true);
    }
    function removeWhiteList(address _funderAddress) public {
        require(msg.sender == owner);
        require(_funderAddress != address(0));
        require(whiteListMge.isRegistered(_funderAddress));
        
        whiteListMge.unregister(_funderAddress);
        emit UnregisteWhiteList(_funderAddress, false);
    }
     
    function () public payable {
        require(icoProceeding);
        require(raisedEthAmt < fundingEthGoal);
        require(msg.value >= 0.1 ether);  
        if (enableWhiteList) {
            require(whiteListMge.isRegistered(msg.sender));
        }
        
        uint amount = msg.value;  
        uint remainToGoal = fundingEthGoal - raisedEthAmt;
        uint returnAmt = 0;  
        if (remainToGoal < amount) {
            returnAmt = msg.value.sub(remainToGoal);
            amount = remainToGoal;
        }
        
         
        uint tokenCount = amount.mul(pricePerEther);
        if (tokenReward.transferSoldToken(address(this), msg.sender, tokenCount)) {
            raisedEthAmt = raisedEthAmt.add(amount);
            totalSoldTokenCount = totalSoldTokenCount.add(tokenCount);
            funderEthAmt[msg.sender] = funderEthAmt[msg.sender].add(amount);
            emit FundTransfer(msg.sender, amount, true);
            
             
            if (returnAmt > 0) {
                msg.sender.transfer(returnAmt);
                icoProceeding = false;  
                emit ReturnExcessAmount(msg.sender, returnAmt);
            }
        }
    }
     
    function checkGoalReached() public {
        require(msg.sender == owner);
        if (raisedEthAmt >= fundingEthGoal){
            safeWithdrawal();
        }
        icoProceeding = false;
    }
     
    function safeWithdrawal() public {
        require(msg.sender == owner);
        beneficiary.transfer(address(this).balance);
        emit FundTransfer(beneficiary, address(this).balance, false);
    }
}