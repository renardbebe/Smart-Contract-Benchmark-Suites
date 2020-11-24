 

pragma solidity ^0.4.11;

contract owned {
    address public owner;
 
    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract CandyCoin is owned {
     
    string public name = "Unicorn Candy Coin";
    string public symbol = "Candy";
    uint8 public decimals = 18;
     
    uint256 public totalSupply = 12000000000000000000000000;
    address public crowdsaleContract;

    uint sendingBanPeriod = 1519776000;            

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
    
    modifier canSend() {
        require ( msg.sender == owner ||  now > sendingBanPeriod || msg.sender == crowdsaleContract);
        _;
    }
    
     
    function CandyCoin(
    ) public {
        balanceOf[msg.sender] = totalSupply;                 
    }
    
    function setCrowdsaleContract(address contractAddress) onlyOwner {
        crowdsaleContract = contractAddress;
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

     
    function transfer(address _to, uint256 _value) public canSend {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public canSend returns (bool success) {
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


contract CandySale is owned {
    
    address public teamWallet = address(0x7Bd19c5Fa45c5631Aa7EFE2Bf8Aa6c220272694F);

    uint public amountRaised;
     
    uint public beginTime = now;
    uint public endTime = 1520640000;            
    uint public tokenPrice = 1750 szabo;

    CandyCoin public tokenReward;

    event FundTransfer(address backer, uint amount, bool isContribution);

     
    function CandySale(
        CandyCoin addressOfTokenUsedAsReward
    ) {
        tokenReward = addressOfTokenUsedAsReward;
    }
    
     
    function withdrawTokens() onlyOwner {
        tokenReward.transfer(msg.sender, tokenReward.balanceOf(this));
        FundTransfer(msg.sender, tokenReward.balanceOf(this), false);
    }

     
    function buyTokens(address beneficiary) payable {
        require(msg.value > 0);
        uint amount = msg.value;
        amountRaised += amount;
        tokenReward.transfer(beneficiary, amount*1000000000000000000/tokenPrice);
        FundTransfer(beneficiary, amount, true);
        teamWallet.transfer(msg.value);

    }

     
    function () payable onlyCrowdsalePeriod {
        buyTokens(msg.sender);
    }

    modifier onlyCrowdsalePeriod() { 
        require ( now >= beginTime && now <= endTime ) ;
        _; 
    }

    

}