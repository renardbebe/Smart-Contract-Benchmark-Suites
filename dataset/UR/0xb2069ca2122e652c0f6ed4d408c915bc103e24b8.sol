 

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract DailyCoinToken {
     
    string public name;
    string public symbol;
    uint8 public decimals = 8;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function DailyCoinToken(
    ) public {
        totalSupply = 300000000 * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = "Daily Coin";                                    
        symbol = "DLC";                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
}

 
contract DailycoinCrowdsale {
    uint256 public amountRaised = 0;
	uint256 public tokensSold = 0;
    uint256 public totalToSale = 150 * (10**6) * (10**8);
	bool crowdsaleClosed = false;
	
    uint public deadline;
    address public beneficiary;
    DailyCoinToken public tokenReward;

    event SaleEnded(address recipient, uint256 totalAmountRaised);
    event FundTransfer(address backer, uint256 amount, uint256 numOfTokens);

     
    function DailycoinCrowdsale() public {
        beneficiary = 0x17Cb4341eF4d9132f9c86b335f6Dd6010F6AeA9a;
        tokenReward = DailyCoinToken(0xaA33983Acfc48bE1D76e0f8Fe377FFe956ad84AD);
        deadline = 1512997200 + 45 days;  
    }

     
    function () payable public {
		require(!crowdsaleClosed);
        uint256 amount = msg.value;
		uint256 numOfTokens = getNumTokens(amount);
        amountRaised += amount;
		tokensSold += numOfTokens;
        tokenReward.transfer(msg.sender, numOfTokens);
        FundTransfer(msg.sender, amount, numOfTokens);
    }
	
	function getNumTokens(uint256 _value) internal returns (uint256 numTokens) {
		uint256 multiple = 5000;
        if (_value >= 10 * 10**18) {
            if (now <= deadline - 35 days) {  
				multiple = multiple * 130 / 100;
			} else if (now <= deadline - 20 days) {  
				multiple = multiple * 120 / 100;
			} else {  
				multiple = multiple * 115 / 100;
			}
        } else {
			if (now <= deadline - 35 days) {  
				multiple = multiple * 120 / 100;
			} else if (now <= deadline - 20 days) {   
				multiple = multiple * 110 / 100;
			} else {  
				multiple = multiple * 105 / 100;
			}
		}
		return multiple * 10**8 * _value / 10**18;
	}

    modifier afterDeadline() { if (now >= deadline) _; }

     
    function endFunding() afterDeadline public {
		require(beneficiary == msg.sender);
		require(!crowdsaleClosed);
		if (beneficiary.send(amountRaised)) {
			if (totalToSale > tokensSold) {
				tokenReward.burn(totalToSale - tokensSold);
			}
			crowdsaleClosed = true;
			SaleEnded(beneficiary, amountRaised);
		}
    }
	
	function withdraw(uint256 amount) afterDeadline public {
		require(beneficiary == msg.sender);
		amount = amount * 1 ether;
		beneficiary.transfer(amount);
    }
}